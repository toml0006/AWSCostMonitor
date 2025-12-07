//
//  TimerLifecycleTests.swift
//  AWSCostMonitorTests
//
//  Validates auto-refresh timer lifecycle and state detection
//

import Testing
import Foundation
@testable import AWSCostMonitor

struct TimerLifecycleTests {
    @Test func testIsAutoRefreshActiveTracksStartStop() async throws {
        let awsManager = AWSManager()

        // Set up a lightweight test profile to avoid SDK calls
        let testProfile = AWSProfile(name: "test", region: "us-east-1")
        awsManager.profiles = [testProfile]
        awsManager.selectedProfile = testProfile

        // Ensure starting timers marks state as active
        awsManager.startAutomaticRefresh()
        #expect(awsManager.isAutoRefreshActive)

        // Stopping should mark state as inactive
        awsManager.stopAutomaticRefresh()
        // Give the async task a moment to cancel/clear
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(!awsManager.isAutoRefreshActive)
    }

    @Test func testIntervalZeroStopsTimers() async throws {
        let awsManager = AWSManager()

        // Set up test profile and start timers
        let testProfile = AWSProfile(name: "test", region: "us-east-1")
        awsManager.profiles = [testProfile]
        awsManager.selectedProfile = testProfile
        awsManager.startAutomaticRefresh()
        #expect(awsManager.isAutoRefreshActive)

        // Setting interval to 0 should result in timers being stopped
        awsManager.updateAPIBudgetAndRefresh(for: testProfile.name, apiBudget: 5.0, refreshIntervalMinutes: 0)
        // Allow any pending start/stop to settle
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(!awsManager.isAutoRefreshActive)
    }
}

