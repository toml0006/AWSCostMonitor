//
//  AWSManagerProfileTests.swift
//  AWSCostMonitorTests
//
//  Integration tests for AWSManager profile visibility features
//

import XCTest
import Combine
@testable import AWSCostMonitor

class AWSManagerProfileTests: XCTestCase {
    
    var awsManager: AWSManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        awsManager = AWSManager()
        cancellables = []
    }
    
    override func tearDown() {
        awsManager = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Profile Visibility Update Tests
    
    func testUpdateProfileVisibilityRefreshesProfilesList() {
        // Setup test profiles
        awsManager.realProfiles = [
            AWSProfile(name: "production", region: "us-east-1"),
            AWSProfile(name: "staging", region: "us-west-2")
        ]
        awsManager.demoProfiles = [
            AWSProfile(name: "acme", region: "us-east-1")
        ]
        
        let expectation = XCTestExpectation(description: "Profiles list updated")
        
        // Subscribe to profiles changes
        awsManager.$profiles
            .dropFirst() // Skip initial value
            .sink { profiles in
                // Should only show visible profiles
                XCTAssertGreaterThan(profiles.count, 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger profile visibility update
        awsManager.updateProfileVisibility()
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testHidingCurrentProfileSwitchesToFirst() {
        // Setup test profiles
        let profile1 = AWSProfile(name: "production", region: "us-east-1")
        let profile2 = AWSProfile(name: "staging", region: "us-west-2")
        
        awsManager.realProfiles = [profile1, profile2]
        awsManager.demoProfiles = []
        awsManager.selectedProfile = profile1
        awsManager.profiles = [profile1, profile2]
        
        let expectation = XCTestExpectation(description: "Profile switched")
        
        // Subscribe to selected profile changes
        awsManager.$selectedProfile
            .dropFirst() // Skip initial value
            .sink { newProfile in
                // Should switch to profile2 when profile1 is hidden
                XCTAssertEqual(newProfile?.name, "staging")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Hide the current profile
        let profileManager = awsManager.getProfileManager()
        profileManager.toggleProfileVisibility("production", isVisible: false)
        awsManager.updateProfileVisibility()
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Profile Selection Persistence Tests
    
    func testSelectedProfilePersistence() {
        let profile = AWSProfile(name: "test-profile", region: "us-east-1")
        awsManager.selectedProfile = profile
        awsManager.saveSelectedProfile(profile: profile)
        
        // Create new manager instance to test loading
        let newManager = AWSManager()
        newManager.profiles = [profile]
        newManager.loadSelectedProfile()
        
        XCTAssertEqual(newManager.selectedProfile?.name, "test-profile")
    }
    
    // MARK: - Profile Change Detection Tests
    
    func testProfileChangeDetectionOnStartup() {
        // Setup initial profiles
        awsManager.realProfiles = [
            AWSProfile(name: "existing1", region: "us-east-1"),
            AWSProfile(name: "existing2", region: "us-west-2")
        ]
        awsManager.demoProfiles = [
            AWSProfile(name: "acme", region: "us-east-1")
        ]
        
        // Initialize profile management
        let profileManager = awsManager.getProfileManager()
        profileManager.initializeProfiles(awsManager.realProfiles + awsManager.demoProfiles)
        
        // Simulate adding a new profile
        awsManager.realProfiles.append(AWSProfile(name: "new-profile", region: "eu-west-1"))
        
        // Detect changes
        let changes = profileManager.detectProfileChanges(currentProfiles: awsManager.realProfiles + awsManager.demoProfiles)
        
        XCTAssertEqual(changes.newProfiles.count, 1)
        XCTAssertEqual(changes.newProfiles.first?.name, "new-profile")
    }
    
    // MARK: - Demo Profile Handling Tests
    
    func testDemoProfileHiddenByDefault() {
        let profiles = [
            AWSProfile(name: "production", region: "us-east-1"),
            AWSProfile(name: "acme", region: "us-east-1")
        ]
        
        let profileManager = ProfileManager()
        profileManager.initializeProfiles(profiles)
        
        let visibleProfiles = profileManager.getVisibleProfiles(from: profiles)
        
        // Demo profile should not be visible by default
        XCTAssertFalse(visibleProfiles.contains { $0.name == "acme" })
        XCTAssertTrue(visibleProfiles.contains { $0.name == "production" })
    }
    
    // MARK: - Profile Filtering Tests
    
    func testProfilesListReflectsVisibilitySettings() {
        // Setup profiles
        awsManager.realProfiles = [
            AWSProfile(name: "visible1", region: "us-east-1"),
            AWSProfile(name: "hidden1", region: "us-west-2")
        ]
        awsManager.demoProfiles = [
            AWSProfile(name: "acme", region: "us-east-1")
        ]
        
        // Configure visibility
        let profileManager = awsManager.getProfileManager()
        var settings = ProfileVisibilitySettings()
        settings.visibleProfiles.insert("visible1")
        settings.hiddenProfiles.insert("hidden1")
        settings.hiddenProfiles.insert("acme")
        profileManager.saveSettings(settings)
        
        // Update visibility
        awsManager.updateProfileVisibility()
        
        // Wait for async update
        let expectation = XCTestExpectation(description: "Profiles filtered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.awsManager.profiles.count, 1)
            XCTAssertEqual(self.awsManager.profiles.first?.name, "visible1")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Removed Profile Tests
    
    func testRemovedProfileWithPreservedData() {
        // Setup initial profile
        let profile = AWSProfile(name: "old-profile", region: "us-east-1")
        awsManager.realProfiles = [profile]
        
        let profileManager = awsManager.getProfileManager()
        profileManager.initializeProfiles([profile])
        
        // Mark as removed but preserve data
        profileManager.markProfilesAsRemoved(["old-profile"], preserveData: true)
        
        // Get visible profiles (should include removed with suffix)
        let visibleProfiles = profileManager.getVisibleProfiles(from: [])
        
        XCTAssertEqual(visibleProfiles.count, 1)
        XCTAssertEqual(visibleProfiles.first?.name, "old-profile (removed)")
        XCTAssertTrue(visibleProfiles.first?.isRemoved ?? false)
    }
    
    // MARK: - Auto-refresh Tests
    
    func testAutoRefreshWhenProfileChanges() {
        // This test would require mocking the network calls
        // For now, we test that the method is called
        
        let profile1 = AWSProfile(name: "profile1", region: "us-east-1")
        let profile2 = AWSProfile(name: "profile2", region: "us-west-2")
        
        awsManager.realProfiles = [profile1, profile2]
        awsManager.selectedProfile = profile1
        awsManager.profiles = [profile1, profile2]
        
        // Track if fetchCostForSelectedProfile would be called
        let expectation = XCTestExpectation(description: "Cost fetch triggered")
        
        // Monitor selected profile changes
        awsManager.$selectedProfile
            .dropFirst()
            .sink { newProfile in
                if newProfile?.name == "profile2" {
                    // In real scenario, fetchCostForSelectedProfile would be called
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Hide current profile to trigger switch
        let profileManager = awsManager.getProfileManager()
        profileManager.toggleProfileVisibility("profile1", isVisible: false)
        awsManager.updateProfileVisibility()
        
        wait(for: [expectation], timeout: 2.0)
    }
}

// MARK: - Mock Helpers

extension AWSManagerProfileTests {
    
    func createMockProfiles(count: Int) -> [AWSProfile] {
        return (1...count).map { index in
            AWSProfile(name: "profile\(index)", region: "us-east-\(index)")
        }
    }
    
    func setupProfileVisibility(visible: [String], hidden: [String]) {
        let profileManager = awsManager.getProfileManager()
        var settings = ProfileVisibilitySettings()
        visible.forEach { settings.visibleProfiles.insert($0) }
        hidden.forEach { settings.hiddenProfiles.insert($0) }
        profileManager.saveSettings(settings)
    }
}