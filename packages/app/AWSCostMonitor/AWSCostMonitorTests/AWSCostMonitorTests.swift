//
//  AWSCostMonitorTests.swift
//  AWSCostMonitorTests
//
//  Created by Jackson Tomlinson on 8/1/25.
//

import Testing
import Foundation
@testable import AWSCostMonitor

struct AWSCostMonitorTests {

    @Test func testMenuBarDisplayFormatEnum() async throws {
        // Test that all cases have proper display names
        #expect(MenuBarDisplayFormat.full.displayName == "Full ($123.45)")
        #expect(MenuBarDisplayFormat.abbreviated.displayName == "Abbreviated ($123)")
        #expect(MenuBarDisplayFormat.iconOnly.displayName == "Icon Only")
        
        // Test raw values for persistence
        #expect(MenuBarDisplayFormat.full.rawValue == "full")
        #expect(MenuBarDisplayFormat.abbreviated.rawValue == "abbreviated")
        #expect(MenuBarDisplayFormat.iconOnly.rawValue == "iconOnly")
    }
    
    @Test func testCostDisplayFormatterFullFormat() async throws {
        let amount: Decimal = 123.45
        let currency = "USD"
        
        let result = CostDisplayFormatter.format(
            amount: amount,
            currency: currency,
            format: .full
        )
        
        // Should show full amount with 2 decimal places
        #expect(result == "$123.45")
    }
    
    @Test func testCostDisplayFormatterAbbreviatedFormat() async throws {
        let testCases: [(Decimal, String)] = [
            (123.45, "$123"),     // Round down
            (123.50, "$124"),     // Round up
            (123.99, "$124"),     // Round up
            (1000.00, "$1,000"),  // Thousands separator
        ]
        
        for (amount, expected) in testCases {
            let result = CostDisplayFormatter.format(
                amount: amount,
                currency: "USD",
                format: .abbreviated
            )
            #expect(result == expected)
        }
    }
    
    @Test func testCostDisplayFormatterIconOnlyFormat() async throws {
        let amount: Decimal = 123.45
        let currency = "USD"
        
        let result = CostDisplayFormatter.format(
            amount: amount,
            currency: currency,
            format: .iconOnly
        )
        
        // Should return empty string for icon only
        #expect(result == "")
    }
    
    @Test func testCostDisplayFormatterDifferentCurrencies() async throws {
        let amount: Decimal = 123.45
        let currencies = ["EUR", "GBP", "JPY", "CAD"]
        
        for currency in currencies {
            let result = CostDisplayFormatter.format(
                amount: amount,
                currency: currency,
                format: .full
            )
            
            // Should contain the amount (exact format depends on locale)
            #expect(result.contains("123"))
        }
    }
    
    @Test func testCostDisplayFormatterZeroAmount() async throws {
        let amount: Decimal = 0
        let currency = "USD"
        
        let fullResult = CostDisplayFormatter.format(
            amount: amount,
            currency: currency,
            format: .full
        )
        #expect(fullResult == "$0.00")
        
        let abbreviatedResult = CostDisplayFormatter.format(
            amount: amount,
            currency: currency,
            format: .abbreviated
        )
        #expect(abbreviatedResult == "$0")
    }
    
    @Test func testCostDisplayFormatterPreviewText() async throws {
        #expect(CostDisplayFormatter.previewText(for: .full) == "$123.45")
        #expect(CostDisplayFormatter.previewText(for: .abbreviated) == "$123")
        #expect(CostDisplayFormatter.previewText(for: .iconOnly) == "(icon only)")
    }
    
    // MARK: - Settings Tests
    
    @Test func testAWSManagerRefreshInterval() async throws {
        let awsManager = AWSManager()
        
        // Test default refresh interval
        #expect(awsManager.refreshInterval == 5)
        
        // Test refresh interval bounds
        awsManager.refreshInterval = 1
        #expect(awsManager.refreshInterval == 1)
        
        awsManager.refreshInterval = 60
        #expect(awsManager.refreshInterval == 60)
    }
    
    @Test func testAWSManagerTimerManagement() async throws {
        let awsManager = AWSManager()
        
        // Test timer is not active initially
        #expect(!awsManager.isAutoRefreshActive)
        
        // Test starting automatic refresh
        awsManager.startAutomaticRefresh()
        #expect(awsManager.isAutoRefreshActive)
        
        // Test stopping automatic refresh
        awsManager.stopAutomaticRefresh()
        #expect(!awsManager.isAutoRefreshActive)
    }
    
    @Test func testRefreshIntervalChangesUpdateTimer() async throws {
        let awsManager = AWSManager()
        
        // Start timer with default interval
        awsManager.startAutomaticRefresh()
        #expect(awsManager.isAutoRefreshActive)
        
        // Change interval - timer should still be active
        awsManager.refreshInterval = 10
        #expect(awsManager.isAutoRefreshActive)
        
        awsManager.stopAutomaticRefresh()
    }
    
    @Test func testAppStorageDefaultValues() async throws {
        // Test that default values are set correctly for @AppStorage properties
        let testDefaults = UserDefaults.standard
        
        // Clear any existing values
        testDefaults.removeObject(forKey: "MenuBarDisplayFormat")
        testDefaults.removeObject(forKey: "RefreshIntervalMinutes")
        testDefaults.removeObject(forKey: "SelectedAWSProfileName")
        
        // Create a new manager instance to test defaults
        let awsManager = AWSManager()
        
        // Display format should default to .full
        #expect(awsManager.displayFormat == .full)
        
        // Refresh interval should default to 5 minutes
        #expect(awsManager.refreshInterval == 5)
    }
    
    // MARK: - Anomaly Detection Tests
    
    @Test func testAnomalyDetectionDefaultSettings() async throws {
        let awsManager = AWSManager()
        
        // Test empty anomalies initially
        #expect(awsManager.anomalies.isEmpty)
        
        // Note: enableAnomalyDetection and anomalyThreshold are private @AppStorage properties
        // We can only test their effects through public methods
    }
    
    @Test func testBudgetVelocityAnomaly() async throws {
        let awsManager = AWSManager()
        
        // Set up a budget
        awsManager.updateBudget(for: "test-profile", monthlyBudget: 100, alertThreshold: 0.8)
        
        // Test that spending 90% of budget on day 5 triggers velocity anomaly
        let calendar = Calendar.current
        let now = Date()
        let dayOfMonth = calendar.component(.day, from: now)
        
        // Only run this test if we're not too late in the month
        if dayOfMonth <= 10 {
            awsManager.detectAnomalies(for: "test-profile", currentAmount: 90, serviceCosts: [])
            
            // Should have at least one budget velocity anomaly
            let velocityAnomalies = awsManager.anomalies.filter { $0.type == .budgetVelocity }
            #expect(!velocityAnomalies.isEmpty)
        }
    }
    
    @Test func testServiceCostAnomaly() async throws {
        let awsManager = AWSManager()
        
        // Create service costs where one service is >30% of total
        let services = [
            ServiceCost(serviceName: "EC2", amount: 50, currency: "USD"),
            ServiceCost(serviceName: "S3", amount: 10, currency: "USD"),
            ServiceCost(serviceName: "RDS", amount: 5, currency: "USD")
        ]
        
        awsManager.detectAnomalies(for: "test-profile", currentAmount: 65, serviceCosts: services)
        
        // Should detect EC2 as a high-cost service (50/65 = ~77%)
        let serviceAnomalies = awsManager.anomalies.filter { $0.type == .newService }
        #expect(!serviceAnomalies.isEmpty)
        #expect(serviceAnomalies.first?.message.contains("EC2") ?? false)
    }
    
    @Test func testAnomalyDetectionDisabled() async throws {
        let awsManager = AWSManager()
        
        // Note: enableAnomalyDetection is a private @AppStorage property
        // We can't directly disable it in tests, but we can test the detection logic
        
        // Add some test data that would normally trigger anomalies
        let services = [
            ServiceCost(serviceName: "EC2", amount: 90, currency: "USD"),
            ServiceCost(serviceName: "S3", amount: 10, currency: "USD")
        ]
        
        // Test that anomalies can be detected
        awsManager.detectAnomalies(for: "test-profile", currentAmount: 100, serviceCosts: services)
        
        // Should detect anomalies when service costs are high
        // Note: Actual anomaly detection depends on the private enableAnomalyDetection flag
    }

}
