//
//  ProfileManagementTests.swift
//  AWSCostMonitorTests
//
//  Tests for v1.3.0 Profile Management Features
//

import XCTest
@testable import AWSCostMonitor

class ProfileManagementTests: XCTestCase {
    
    var profileManager: ProfileManager!
    var userDefaults: UserDefaults!
    let testKey = "TestProfileVisibilitySettings"
    
    override func setUp() {
        super.setUp()
        // Use a test UserDefaults suite to avoid polluting real settings
        userDefaults = UserDefaults(suiteName: "com.awscostmonitor.tests")!
        userDefaults.removePersistentDomain(forName: "com.awscostmonitor.tests")
        
        profileManager = ProfileManager()
    }
    
    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "com.awscostmonitor.tests")
        profileManager = nil
        super.tearDown()
    }
    
    // MARK: - Profile Visibility Settings Tests
    
    func testInitialSettingsAreEmpty() {
        let settings = ProfileVisibilitySettings()
        XCTAssertTrue(settings.visibleProfiles.isEmpty)
        XCTAssertTrue(settings.hiddenProfiles.isEmpty)
        XCTAssertTrue(settings.removedProfiles.isEmpty)
        XCTAssertNotNil(settings.lastScanDate)
    }
    
    func testSaveAndLoadSettings() {
        var settings = ProfileVisibilitySettings()
        settings.visibleProfiles.insert("profile1")
        settings.visibleProfiles.insert("profile2")
        settings.hiddenProfiles.insert("profile3")
        settings.lastScanDate = Date()
        
        profileManager.saveSettings(settings)
        let loadedSettings = profileManager.loadSettings()
        
        XCTAssertEqual(loadedSettings.visibleProfiles.count, 2)
        XCTAssertTrue(loadedSettings.visibleProfiles.contains("profile1"))
        XCTAssertTrue(loadedSettings.visibleProfiles.contains("profile2"))
        XCTAssertTrue(loadedSettings.hiddenProfiles.contains("profile3"))
    }
    
    // MARK: - Profile Initialization Tests
    
    func testInitializeProfilesWithDemoHidden() {
        let profiles = [
            AWSProfile(name: "production", region: "us-east-1"),
            AWSProfile(name: "staging", region: "us-west-2"),
            AWSProfile(name: "acme", region: "us-east-1") // Demo profile
        ]
        
        profileManager.initializeProfiles(profiles)
        let settings = profileManager.loadSettings()
        
        // Regular profiles should be visible
        XCTAssertTrue(settings.visibleProfiles.contains("production"))
        XCTAssertTrue(settings.visibleProfiles.contains("staging"))
        
        // Demo profile should be hidden by default
        XCTAssertFalse(settings.visibleProfiles.contains("acme"))
        XCTAssertTrue(settings.hiddenProfiles.contains("acme"))
    }
    
    // MARK: - Profile Change Detection Tests
    
    func testDetectNewProfiles() {
        // Initialize with two profiles
        let initialProfiles = [
            AWSProfile(name: "profile1", region: "us-east-1"),
            AWSProfile(name: "profile2", region: "us-west-2")
        ]
        profileManager.initializeProfiles(initialProfiles)
        
        // Add a new profile
        let currentProfiles = [
            AWSProfile(name: "profile1", region: "us-east-1"),
            AWSProfile(name: "profile2", region: "us-west-2"),
            AWSProfile(name: "profile3", region: "eu-west-1") // New profile
        ]
        
        let changes = profileManager.detectProfileChanges(currentProfiles: currentProfiles)
        
        XCTAssertEqual(changes.newProfiles.count, 1)
        XCTAssertEqual(changes.newProfiles.first?.name, "profile3")
        XCTAssertEqual(changes.removedProfiles.count, 0)
    }
    
    func testDetectRemovedProfiles() {
        // Initialize with three profiles
        let initialProfiles = [
            AWSProfile(name: "profile1", region: "us-east-1"),
            AWSProfile(name: "profile2", region: "us-west-2"),
            AWSProfile(name: "profile3", region: "eu-west-1")
        ]
        profileManager.initializeProfiles(initialProfiles)
        
        // Remove one profile
        let currentProfiles = [
            AWSProfile(name: "profile1", region: "us-east-1"),
            AWSProfile(name: "profile3", region: "eu-west-1")
        ]
        
        let changes = profileManager.detectProfileChanges(currentProfiles: currentProfiles)
        
        XCTAssertEqual(changes.newProfiles.count, 0)
        XCTAssertEqual(changes.removedProfiles.count, 1)
        XCTAssertTrue(changes.removedProfiles.contains("profile2"))
    }
    
    // MARK: - Profile Visibility Toggle Tests
    
    func testToggleProfileVisibility() {
        let profiles = [
            AWSProfile(name: "profile1", region: "us-east-1"),
            AWSProfile(name: "profile2", region: "us-west-2")
        ]
        profileManager.initializeProfiles(profiles)
        
        // Hide profile1
        profileManager.toggleProfileVisibility("profile1", isVisible: false)
        let settings = profileManager.loadSettings()
        
        XCTAssertFalse(settings.visibleProfiles.contains("profile1"))
        XCTAssertTrue(settings.hiddenProfiles.contains("profile1"))
        XCTAssertTrue(settings.visibleProfiles.contains("profile2"))
        
        // Show profile1 again
        profileManager.toggleProfileVisibility("profile1", isVisible: true)
        let updatedSettings = profileManager.loadSettings()
        
        XCTAssertTrue(updatedSettings.visibleProfiles.contains("profile1"))
        XCTAssertFalse(updatedSettings.hiddenProfiles.contains("profile1"))
    }
    
    // MARK: - Removed Profile Management Tests
    
    func testMarkProfilesAsRemoved() {
        let profiles = [
            AWSProfile(name: "profile1", region: "us-east-1"),
            AWSProfile(name: "profile2", region: "us-west-2")
        ]
        profileManager.initializeProfiles(profiles)
        
        // Mark profile1 as removed but preserve data
        profileManager.markProfilesAsRemoved(["profile1"], preserveData: true)
        let settings = profileManager.loadSettings()
        
        XCTAssertNotNil(settings.removedProfiles["profile1"])
        XCTAssertTrue(settings.removedProfiles["profile1"]?.preserveData ?? false)
        XCTAssertFalse(settings.visibleProfiles.contains("profile1"))
        XCTAssertFalse(settings.hiddenProfiles.contains("profile1"))
    }
    
    func testRemovedProfileAppearsInVisibleList() {
        let profiles = [
            AWSProfile(name: "profile1", region: "us-east-1"),
            AWSProfile(name: "profile2", region: "us-west-2")
        ]
        profileManager.initializeProfiles(profiles)
        
        // Mark profile1 as removed but preserve data
        profileManager.markProfilesAsRemoved(["profile1"], preserveData: true)
        
        // Get visible profiles - should include removed profile with suffix
        let visibleProfiles = profileManager.getVisibleProfiles(from: [
            AWSProfile(name: "profile2", region: "us-west-2")
        ])
        
        XCTAssertEqual(visibleProfiles.count, 2)
        XCTAssertTrue(visibleProfiles.contains { $0.name == "profile2" })
        XCTAssertTrue(visibleProfiles.contains { $0.name == "profile1 (removed)" })
        
        // Check that removed profile has correct properties
        let removedProfile = visibleProfiles.first { $0.name == "profile1 (removed)" }
        XCTAssertNotNil(removedProfile)
        XCTAssertTrue(removedProfile?.isRemoved ?? false)
    }
    
    // MARK: - First Launch Detection Tests
    
    func testShouldScanForChangesOnFirstLaunch() {
        // Clean state - no settings exist
        let shouldScan = profileManager.shouldScanForChanges()
        XCTAssertTrue(shouldScan, "Should scan on first launch when no settings exist")
    }
    
    func testShouldNotScanWithRecentSettings() {
        let profiles = [
            AWSProfile(name: "profile1", region: "us-east-1")
        ]
        profileManager.initializeProfiles(profiles)
        
        // Should not scan if we just initialized
        let shouldScan = profileManager.shouldScanForChanges()
        XCTAssertFalse(shouldScan, "Should not scan when settings were just created")
    }
    
    func testShouldScanAfter24Hours() {
        var settings = ProfileVisibilitySettings()
        settings.visibleProfiles.insert("profile1")
        // Set last scan to 25 hours ago
        settings.lastScanDate = Date().addingTimeInterval(-25 * 3600)
        profileManager.saveSettings(settings)
        
        let shouldScan = profileManager.shouldScanForChanges()
        XCTAssertTrue(shouldScan, "Should scan when more than 24 hours have passed")
    }
    
    // MARK: - Visible Profiles Filtering Tests
    
    func testGetVisibleProfilesFiltersCorrectly() {
        let allProfiles = [
            AWSProfile(name: "visible1", region: "us-east-1"),
            AWSProfile(name: "visible2", region: "us-west-2"),
            AWSProfile(name: "hidden1", region: "eu-west-1"),
            AWSProfile(name: "acme", region: "us-east-1")
        ]
        
        // Set up visibility settings
        var settings = ProfileVisibilitySettings()
        settings.visibleProfiles.insert("visible1")
        settings.visibleProfiles.insert("visible2")
        settings.hiddenProfiles.insert("hidden1")
        settings.hiddenProfiles.insert("acme")
        profileManager.saveSettings(settings)
        
        let visibleProfiles = profileManager.getVisibleProfiles(from: allProfiles)
        
        XCTAssertEqual(visibleProfiles.count, 2)
        XCTAssertTrue(visibleProfiles.contains { $0.name == "visible1" })
        XCTAssertTrue(visibleProfiles.contains { $0.name == "visible2" })
        XCTAssertFalse(visibleProfiles.contains { $0.name == "hidden1" })
        XCTAssertFalse(visibleProfiles.contains { $0.name == "acme" })
    }
    
    // MARK: - Add New Profiles Tests
    
    func testAddNewProfiles() {
        // Start with one profile
        let initialProfiles = [
            AWSProfile(name: "profile1", region: "us-east-1")
        ]
        profileManager.initializeProfiles(initialProfiles)
        
        // Add new profiles
        profileManager.addNewProfiles(["profile2", "profile3"])
        let settings = profileManager.loadSettings()
        
        XCTAssertTrue(settings.visibleProfiles.contains("profile2"))
        XCTAssertTrue(settings.visibleProfiles.contains("profile3"))
        XCTAssertFalse(settings.hiddenProfiles.contains("profile2"))
        XCTAssertFalse(settings.hiddenProfiles.contains("profile3"))
    }
}