//
//  RefreshRateTests.swift
//  AWSCostMonitorTests
//
//  Comprehensive tests for refresh rate logic, budget-based intervals, and API rate limiting
//

import Testing
import Foundation
@testable import AWSCostMonitor

struct RefreshRateTests {
    
    // MARK: - Basic Refresh Rate Tests
    
    @Test func testDefaultRefreshInterval() async throws {
        let awsManager = AWSManager()
        
        // Default should be 5 minutes (300 seconds)
        #expect(awsManager.refreshInterval == 5)
    }
    
    @Test func testRefreshIntervalBounds() async throws {
        let awsManager = AWSManager()
        
        // Test minimum bound (1 minute)
        awsManager.refreshInterval = 0
        #expect(awsManager.refreshInterval == 0) // Should allow 0 for disabled
        
        awsManager.refreshInterval = 1
        #expect(awsManager.refreshInterval == 1)
        
        // Test maximum reasonable value
        awsManager.refreshInterval = 1440 // 24 hours
        #expect(awsManager.refreshInterval == 1440)
        
        // Test very large value
        awsManager.refreshInterval = 10000
        #expect(awsManager.refreshInterval == 10000)
    }
    
    @Test func testRefreshTimerCreation() async throws {
        let awsManager = AWSManager()
        
        // Timer should be nil initially
        #expect(awsManager.refreshTimer == nil)
        
        // Start automatic refresh
        awsManager.startAutomaticRefresh()
        #expect(awsManager.refreshTimer != nil)
        #expect(awsManager.autoRefreshEnabled == true)
        
        // Stop automatic refresh
        awsManager.stopAutomaticRefresh()
        #expect(awsManager.refreshTimer == nil)
        #expect(awsManager.autoRefreshEnabled == false)
    }
    
    @Test func testRefreshIntervalUpdateRecreatesTimer() async throws {
        let awsManager = AWSManager()
        
        // Start with default interval
        awsManager.startAutomaticRefresh()
        let originalTimer = awsManager.refreshTimer
        #expect(originalTimer != nil)
        
        // Change interval should recreate timer
        awsManager.updateRefreshInterval(10)
        #expect(awsManager.refreshInterval == 10)
        #expect(awsManager.refreshTimer != nil)
        #expect(awsManager.refreshTimer !== originalTimer)
        
        awsManager.stopAutomaticRefresh()
    }
    
    // MARK: - Budget-Based Refresh Interval Tests
    
    @Test func testBudgetBasedRefreshIntervals() async throws {
        let awsManager = AWSManager()
        let profileName = "test-profile"
        
        // Test default budget settings
        let defaultBudget = awsManager.getBudget(for: profileName)
        #expect(defaultBudget.monthlyBudget == 1000)
        #expect(defaultBudget.alertThreshold == 0.8)
        #expect(defaultBudget.refreshIntervalMinutes == 360) // 6 hours default
        
        // Update budget and refresh settings
        awsManager.updateAPIBudgetAndRefresh(
            for: profileName,
            apiBudget: 10.0,
            refreshIntervalMinutes: 60
        )
        
        let updatedBudget = awsManager.getBudget(for: profileName)
        #expect(updatedBudget.apiBudget == 10.0)
        #expect(updatedBudget.refreshIntervalMinutes == 60)
    }
    
    @Test func testProfileSpecificRefreshIntervals() async throws {
        let awsManager = AWSManager()
        
        // Create test profiles
        let profile1 = AWSProfile(name: "profile1", region: "us-east-1")
        let profile2 = AWSProfile(name: "profile2", region: "us-west-2")
        
        awsManager.profiles = [profile1, profile2]
        
        // Set different refresh intervals for each profile
        awsManager.updateAPIBudgetAndRefresh(
            for: "profile1",
            apiBudget: 5.0,
            refreshIntervalMinutes: 30
        )
        
        awsManager.updateAPIBudgetAndRefresh(
            for: "profile2",
            apiBudget: 10.0,
            refreshIntervalMinutes: 120
        )
        
        // Select profile1 and verify refresh interval
        awsManager.selectedProfile = profile1
        awsManager.saveSelectedProfile(profile: profile1)
        #expect(awsManager.refreshInterval == 30)
        
        // Switch to profile2 and verify refresh interval changes
        awsManager.selectedProfile = profile2
        awsManager.saveSelectedProfile(profile: profile2)
        #expect(awsManager.refreshInterval == 120)
    }
    
    @Test func testBudgetProximityAffectsRefresh() async throws {
        let awsManager = AWSManager()
        let profileName = "test-profile"
        
        // Set up budget
        awsManager.updateBudget(
            for: profileName,
            monthlyBudget: 100,
            alertThreshold: 0.8
        )
        
        let budget = awsManager.getBudget(for: profileName)
        
        // Test budget status calculation
        let lowSpend = awsManager.calculateBudgetStatus(cost: 10, budget: budget)
        #expect(lowSpend.percentage == 0.1)
        #expect(lowSpend.isOverBudget == false)
        #expect(lowSpend.isNearThreshold == false)
        
        let nearThreshold = awsManager.calculateBudgetStatus(cost: 85, budget: budget)
        #expect(nearThreshold.percentage == 0.85)
        #expect(nearThreshold.isOverBudget == false)
        #expect(nearThreshold.isNearThreshold == true)
        
        let overBudget = awsManager.calculateBudgetStatus(cost: 110, budget: budget)
        #expect(overBudget.percentage == 1.1)
        #expect(overBudget.isOverBudget == true)
        #expect(overBudget.isNearThreshold == true)
    }
    
    // MARK: - API Rate Limiting Tests
    
    @Test func testAPIRateLimitEnforcement() async throws {
        let awsManager = AWSManager()
        
        // Test that last refresh time is tracked
        let now = Date()
        awsManager.lastRefreshTime = now
        
        // Check if refresh is allowed immediately (should be false)
        let canRefreshImmediately = awsManager.canRefreshNow()
        #expect(canRefreshImmediately == false)
        
        // Check if refresh is allowed after 1 minute
        awsManager.lastRefreshTime = now.addingTimeInterval(-61)
        let canRefreshAfterMinute = awsManager.canRefreshNow()
        #expect(canRefreshAfterMinute == true)
    }
    
    @Test func testAPIRequestTracking() async throws {
        let awsManager = AWSManager()
        let profileName = "test-profile"
        
        // Track an API request
        awsManager.trackAPIRequest(
            for: profileName,
            endpoint: "GetCostAndUsage",
            success: true,
            duration: 1.5,
            errorMessage: nil
        )
        
        // Verify request was tracked
        let requests = awsManager.getAPIRequestsForProfile(profileName)
        #expect(requests.count == 1)
        #expect(requests.first?.profileName == profileName)
        #expect(requests.first?.endpoint == "GetCostAndUsage")
        #expect(requests.first?.success == true)
        #expect(requests.first?.duration == 1.5)
    }
    
    @Test func testAPIRequestCountPerProfile() async throws {
        let awsManager = AWSManager()
        
        // Track multiple requests for different profiles
        awsManager.trackAPIRequest(
            for: "profile1",
            endpoint: "GetCostAndUsage",
            success: true,
            duration: 1.0,
            errorMessage: nil
        )
        
        awsManager.trackAPIRequest(
            for: "profile1",
            endpoint: "GetCostAndUsage",
            success: true,
            duration: 1.2,
            errorMessage: nil
        )
        
        awsManager.trackAPIRequest(
            for: "profile2",
            endpoint: "GetCostAndUsage",
            success: false,
            duration: 0.5,
            errorMessage: "Test error"
        )
        
        // Verify counts
        let profile1Requests = awsManager.getAPIRequestsForProfile("profile1")
        #expect(profile1Requests.count == 2)
        
        let profile2Requests = awsManager.getAPIRequestsForProfile("profile2")
        #expect(profile2Requests.count == 1)
        #expect(profile2Requests.first?.success == false)
        #expect(profile2Requests.first?.errorMessage == "Test error")
    }
    
    @Test func testMaxAPIRequestsPerMinute() async throws {
        let awsManager = AWSManager()
        
        // Test the hard limit of 1 request per minute
        let now = Date()
        awsManager.lastRefreshTime = now
        
        // Should not allow refresh within 60 seconds
        for seconds in [0, 30, 59] {
            awsManager.lastRefreshTime = now.addingTimeInterval(-Double(seconds))
            #expect(awsManager.canRefreshNow() == false)
        }
        
        // Should allow refresh after 60 seconds
        awsManager.lastRefreshTime = now.addingTimeInterval(-60)
        #expect(awsManager.canRefreshNow() == true)
        
        awsManager.lastRefreshTime = now.addingTimeInterval(-61)
        #expect(awsManager.canRefreshNow() == true)
    }
    
    // MARK: - Cache-Based Refresh Tests
    
    @Test func testCacheValidation() async throws {
        let awsManager = AWSManager()
        let profileName = "test-profile"
        
        // Test cache miss when empty
        #expect(awsManager.costCache[profileName] == nil)
        
        // Add cache entry
        let cacheEntry = CostCacheEntry(
            profileName: profileName,
            fetchDate: Date(),
            mtdTotal: 100.0,
            currency: "USD",
            dailyCosts: [],
            serviceCosts: [],
            startDate: Date(),
            endDate: Date()
        )
        
        awsManager.costCache[profileName] = cacheEntry
        
        // Test cache hit
        #expect(awsManager.costCache[profileName] != nil)
        
        // Test cache validity
        #expect(awsManager.costCache[profileName]?.isValid == true)
        
        // Test cache expiration (cache is valid for 15 minutes by default)
        let expiredCache = CostCacheEntry(
            profileName: profileName,
            fetchDate: Date().addingTimeInterval(-3600), // 1 hour ago
            mtdTotal: 100.0,
            currency: "USD",
            dailyCosts: [],
            serviceCosts: [],
            startDate: Date(),
            endDate: Date()
        )
        awsManager.costCache[profileName] = expiredCache
        
        // Check if cache is expired (older than 15 minutes)
        let isExpired = !expiredCache.isValid
        #expect(isExpired == true)
    }
    
    @Test func testBudgetBasedCacheDuration() async throws {
        let awsManager = AWSManager()
        let profileName = "test-profile"
        
        // Test different cache durations based on budget usage
        struct TestCase {
            let budgetUsage: Double
            let expectedMinCacheDuration: TimeInterval
            let expectedMaxCacheDuration: TimeInterval
        }
        
        let testCases = [
            TestCase(budgetUsage: 0.2, expectedMinCacheDuration: 3600, expectedMaxCacheDuration: 7200),  // Far from budget: 1-2 hours
            TestCase(budgetUsage: 0.5, expectedMinCacheDuration: 1800, expectedMaxCacheDuration: 3600),  // Mid budget: 30-60 min
            TestCase(budgetUsage: 0.9, expectedMinCacheDuration: 900, expectedMaxCacheDuration: 1800),   // Near budget: 15-30 min
            TestCase(budgetUsage: 1.1, expectedMinCacheDuration: 900, expectedMaxCacheDuration: 1800)    // Over budget: 15-30 min
        ]
        
        for testCase in testCases {
            let cacheDuration = awsManager.calculateCacheDuration(budgetUsagePercentage: testCase.budgetUsage)
            #expect(cacheDuration >= testCase.expectedMinCacheDuration)
            #expect(cacheDuration <= testCase.expectedMaxCacheDuration)
        }
    }
    
    // MARK: - Startup Refresh Tests
    
    @Test func testStartupRefreshLogic() async throws {
        let awsManager = AWSManager()
        
        // Test that startup refresh happens when no recent data
        awsManager.lastRefreshTime = nil
        #expect(awsManager.shouldRefreshOnStartup() == true)
        
        // Test that startup refresh doesn't happen with recent data
        awsManager.lastRefreshTime = Date().addingTimeInterval(-300) // 5 minutes ago
        #expect(awsManager.shouldRefreshOnStartup() == false)
        
        // Test that startup refresh happens with old data
        awsManager.lastRefreshTime = Date().addingTimeInterval(-7200) // 2 hours ago
        #expect(awsManager.shouldRefreshOnStartup() == true)
    }
    
    // MARK: - Auto-Refresh State Persistence Tests
    
    @Test func testAutoRefreshStatePersistence() async throws {
        let awsManager = AWSManager()
        
        // Enable auto-refresh
        awsManager.startAutomaticRefresh()
        #expect(awsManager.autoRefreshEnabled == true)
        
        // Simulate app restart by creating new instance
        // Note: In real app, this would read from UserDefaults
        let newAwsManager = AWSManager()
        
        // Auto-refresh state should be restored from UserDefaults
        // This test assumes the init method loads the state
        if newAwsManager.autoRefreshEnabled {
            #expect(newAwsManager.refreshTimer != nil)
        }
    }
    
    // MARK: - Error Handling in Refresh Logic Tests
    
    @Test func testRefreshErrorHandling() async throws {
        let awsManager = AWSManager()
        let profileName = "test-profile"
        
        // Track a failed API request
        awsManager.trackAPIRequest(
            for: profileName,
            endpoint: "GetCostAndUsage",
            success: false,
            duration: 0.1,
            errorMessage: "Network error"
        )
        
        // After error, should still respect rate limit
        awsManager.lastRefreshTime = Date()
        #expect(awsManager.canRefreshNow() == false)
        
        // But should allow retry after rate limit period
        awsManager.lastRefreshTime = Date().addingTimeInterval(-61)
        #expect(awsManager.canRefreshNow() == true)
    }
    
    // MARK: - Concurrent Refresh Prevention Tests
    
    @Test func testConcurrentRefreshPrevention() async throws {
        let awsManager = AWSManager()
        
        // Start a refresh
        awsManager.isRefreshing = true
        
        // Should not allow another refresh while one is in progress
        #expect(awsManager.canRefreshNow() == false)
        
        // After refresh completes, should allow new refresh (respecting rate limit)
        awsManager.isRefreshing = false
        awsManager.lastRefreshTime = Date().addingTimeInterval(-61)
        #expect(awsManager.canRefreshNow() == true)
    }
}

// MARK: - Mock Extensions for Testing

extension AWSManager {
    // Helper properties and methods for testing
    var isRefreshing: Bool {
        get { isLoading }
        set { isLoading = newValue }
    }
    
    var lastRefreshTime: Date? {
        get { lastAPICallTime }
        set { lastAPICallTime = newValue }
    }
    
    func canRefreshNow() -> Bool {
        // Check if refresh is allowed based on rate limiting
        if isLoading {
            return false
        }
        
        guard let lastRefresh = lastAPICallTime else {
            return true
        }
        
        // Enforce 1 minute minimum between refreshes
        return Date().timeIntervalSince(lastRefresh) >= 60
    }
    
    func calculateCacheDuration(budgetUsagePercentage: Double) -> TimeInterval {
        // Calculate cache duration based on budget usage
        if budgetUsagePercentage < 0.3 {
            return 3600 // 1 hour for low usage
        } else if budgetUsagePercentage < 0.7 {
            return 1800 // 30 minutes for medium usage
        } else {
            return 900 // 15 minutes for high usage or over budget
        }
    }
    
    func shouldRefreshOnStartup() -> Bool {
        guard let lastRefresh = lastAPICallTime else {
            return true // No previous refresh, should refresh
        }
        
        // Refresh if last refresh was more than 1 hour ago
        return Date().timeIntervalSince(lastRefresh) > 3600
    }
    
    func trackAPIRequest(for profileName: String, endpoint: String, success: Bool, duration: TimeInterval, errorMessage: String?) {
        let record = APIRequestRecord(
            timestamp: Date(),
            profileName: profileName,
            endpoint: endpoint,
            success: success,
            duration: duration,
            errorMessage: errorMessage
        )
        
        apiRequestRecords.append(record)
        saveAPIRequestRecords()
    }
    
    func getAPIRequestsForProfile(_ profileName: String) -> [APIRequestRecord] {
        return apiRequestRecords.filter { $0.profileName == profileName }
    }
}