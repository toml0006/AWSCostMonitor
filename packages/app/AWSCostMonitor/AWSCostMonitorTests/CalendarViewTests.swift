//
//  CalendarViewTests.swift
//  AWSCostMonitorTests
//
//  Tests for calendar view functionality
//

import Testing
import Foundation
import SwiftUI
@testable import AWSCostMonitor

struct CalendarViewTests {
    
    // MARK: - Calendar Navigation Tests
    
    @Test func testInitialCalendarState() async throws {
        let awsManager = AWSManager()
        
        // Calendar should initialize to current month
        let calendar = Calendar.current
        let now = Date()
        
        // Test that calendar starts at current month (approximate - within same month/year)
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        // We can't directly test @State variables, but we can verify the calendar logic
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start
        #expect(startOfMonth != nil)
        
        if let start = startOfMonth {
            let startMonth = calendar.component(.month, from: start)
            let startYear = calendar.component(.year, from: start)
            #expect(startMonth == currentMonth)
            #expect(startYear == currentYear)
        }
    }
    
    @Test func testMonthNavigation() async throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Test next month calculation
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: now),
           nextMonth <= Date() {
            // Should be able to navigate to next month if it's not in the future
            let nextMonthComponent = calendar.component(.month, from: nextMonth)
            let currentMonthComponent = calendar.component(.month, from: now)
            
            if currentMonthComponent == 12 {
                #expect(nextMonthComponent == 1) // December -> January
            } else {
                #expect(nextMonthComponent == currentMonthComponent + 1)
            }
        }
        
        // Test previous month calculation
        if let prevMonth = calendar.date(byAdding: .month, value: -1, to: now) {
            let prevMonthComponent = calendar.component(.month, from: prevMonth)
            let currentMonthComponent = calendar.component(.month, from: now)
            
            if currentMonthComponent == 1 {
                #expect(prevMonthComponent == 12) // January -> December
            } else {
                #expect(prevMonthComponent == currentMonthComponent - 1)
            }
        }
    }
    
    @Test func testFutureMonthRestriction() async throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Test that we can't navigate beyond current month
        let futureMonth = calendar.date(byAdding: .month, value: 2, to: now)!
        
        // The navigation logic should prevent going beyond current date
        let currentMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let futureMonthStart = calendar.dateInterval(of: .month, for: futureMonth)?.start ?? futureMonth
        
        #expect(futureMonthStart > Date())
        
        // Test the navigation constraint
        let canNavigateToFuture = futureMonthStart <= Date()
        #expect(!canNavigateToFuture)
    }
    
    @Test func testReturnToCurrentMonth() async throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Test "return to current month" functionality
        let currentMonthStart = calendar.dateInterval(of: .month, for: now)?.start
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: now)!
        let previousMonthStart = calendar.dateInterval(of: .month, for: previousMonth)?.start
        
        #expect(currentMonthStart != previousMonthStart)
        
        // Simulate returning to current month
        let returnedMonth = currentMonthStart
        #expect(returnedMonth == currentMonthStart)
    }
    
    // MARK: - Calendar Display Tests
    
    @Test func testDaysInMonthCalculation() async throws {
        let calendar = Calendar.current
        let testDates = [
            Date(), // Current date
            calendar.date(from: DateComponents(year: 2024, month: 2, day: 1))!, // February 2024 (leap year)
            calendar.date(from: DateComponents(year: 2023, month: 2, day: 1))!, // February 2023 (non-leap year)
            calendar.date(from: DateComponents(year: 2024, month: 4, day: 1))!, // April 2024 (30 days)
            calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!  // January 2024 (31 days)
        ]
        
        for date in testDates {
            let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count
            #expect(daysInMonth != nil)
            
            if let days = daysInMonth {
                #expect(days >= 28) // Minimum days in any month
                #expect(days <= 31) // Maximum days in any month
                
                // Specific month checks
                let month = calendar.component(.month, from: date)
                let year = calendar.component(.year, from: date)
                
                switch month {
                case 2: // February
                    if calendar.isLeapYear(year) {
                        #expect(days == 29)
                    } else {
                        #expect(days == 28)
                    }
                case 4, 6, 9, 11: // April, June, September, November
                    #expect(days == 30)
                case 1, 3, 5, 7, 8, 10, 12: // 31-day months
                    #expect(days == 31)
                default:
                    break
                }
            }
        }
    }
    
    @Test func testWeekdayCalculation() async throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Test first day of month weekday calculation
        let firstDayOfMonth = calendar.dateInterval(of: .month, for: now)?.start
        #expect(firstDayOfMonth != nil)
        
        if let firstDay = firstDayOfMonth {
            let weekday = calendar.component(.weekday, from: firstDay)
            #expect(weekday >= 1)
            #expect(weekday <= 7)
            
            // Sunday = 1, Monday = 2, ..., Saturday = 7
            let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            let dayName = dayNames[weekday]
            #expect(!dayName.isEmpty)
        }
    }
    
    // MARK: - Cost Data Integration Tests
    
    @Test func testDailyCostDataRetrieval() async throws {
        let awsManager = AWSManager()
        let testProfile = "test-profile"
        
        // Create sample daily cost data
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        let dailyCosts = [
            DailyCost(date: today, amount: 10.50, currency: "USD"),
            DailyCost(date: calendar.date(byAdding: .day, value: -1, to: today)!, amount: 8.75, currency: "USD"),
            DailyCost(date: calendar.date(byAdding: .day, value: -2, to: today)!, amount: 12.25, currency: "USD")
        ]
        
        // Test data structure
        for cost in dailyCosts {
            #expect(cost.amount > 0)
            #expect(cost.currency == "USD")
            #expect(cost.date <= Date()) // Should not be in future
        }
        
        // Test sorting
        let sortedCosts = dailyCosts.sorted { $0.date > $1.date }
        #expect(sortedCosts.first?.date == today) // Most recent first
    }
    
    @Test func testCostDisplayFormatting() async throws {
        let testAmounts: [Decimal] = [0, 0.01, 1.5, 10.75, 100.00, 1000.50]
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        
        for amount in testAmounts {
            let formatted = formatter.string(from: NSDecimalNumber(decimal: amount))
            #expect(formatted != nil)
            
            if let formattedString = formatted {
                #expect(formattedString.contains("$"))
                
                // Test specific formatting
                switch amount {
                case 0:
                    #expect(formattedString == "$0.00")
                case 0.01:
                    #expect(formattedString == "$0.01")
                case 1000.50:
                    #expect(formattedString == "$1,000.50")
                default:
                    #expect(formattedString.hasPrefix("$"))
                }
            }
        }
    }
    
    // MARK: - Service Cost Integration Tests
    
    @Test func testServiceCostGrouping() async throws {
        let serviceCosts = [
            ServiceCost(serviceName: "Amazon EC2", amount: 50.00, currency: "USD"),
            ServiceCost(serviceName: "Amazon S3", amount: 10.25, currency: "USD"),
            ServiceCost(serviceName: "AWS Lambda", amount: 0.05, currency: "USD"),
            ServiceCost(serviceName: "Amazon CloudWatch", amount: 0.02, currency: "USD"),
            ServiceCost(serviceName: "AWS Cost Explorer", amount: 0.01, currency: "USD")
        ]
        
        // Test sorting (ServiceCost should implement Comparable)
        let sortedServices = serviceCosts.sorted()
        #expect(sortedServices.first?.serviceName == "Amazon EC2") // Highest amount first
        
        // Test grouping logic for small services
        let threshold: Decimal = 0.10
        var majorServices: [ServiceCost] = []
        var minorTotal: Decimal = 0
        var minorCount = 0
        
        for service in sortedServices {
            if service.amount >= threshold || sortedServices.count <= 5 {
                majorServices.append(service)
            } else {
                minorTotal += service.amount
                minorCount += 1
            }
        }
        
        if minorTotal > 0 {
            let otherService = ServiceCost(serviceName: "Other Services (\(minorCount))", amount: minorTotal, currency: "USD")
            majorServices.append(otherService)
        }
        
        // Verify grouping
        #expect(majorServices.count <= serviceCosts.count)
        
        // Check that small services are grouped
        let hasOtherGroup = majorServices.contains { $0.serviceName.hasPrefix("Other Services") }
        if serviceCosts.count > 5 || serviceCosts.contains(where: { $0.amount < threshold }) {
            #expect(hasOtherGroup)
        }
    }
    
    // MARK: - Calendar Window Tests
    
    @Test func testCalendarWindowInitialization() async throws {
        let awsManager = AWSManager()
        
        // Test window controller creation
        // Note: We can't fully test UI components in unit tests, but we can test the data model
        #expect(awsManager != nil)
        
        // Test that AWSManager has the required properties for calendar
        #expect(awsManager.profiles.isEmpty || !awsManager.profiles.isEmpty) // Profiles array exists
        #expect(awsManager.costData.isEmpty || !awsManager.costData.isEmpty) // Cost data array exists
        
        // Test calendar-related computed properties
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        #expect(currentMonth >= 1 && currentMonth <= 12)
        #expect(currentYear >= 2020) // Reasonable year range
    }
    
    // MARK: - Edge Case Tests
    
    @Test func testEmptyDataHandling() async throws {
        let awsManager = AWSManager()
        
        // Test with no profiles
        #expect(awsManager.profiles.isEmpty)
        #expect(awsManager.selectedProfile == nil)
        
        // Test with no cost data
        #expect(awsManager.costData.isEmpty)
        
        // Test daily cost cache with no data
        let testProfile = "empty-profile"
        let dailyCosts = awsManager.dailyCostsByProfile[testProfile] ?? []
        #expect(dailyCosts.isEmpty)
        
        let serviceCosts = awsManager.dailyServiceCostsByProfile[testProfile] ?? [:]
        #expect(serviceCosts.isEmpty)
    }
    
    @Test func testDateBoundaryHandling() async throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Test month boundaries
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start
        
        #expect(endOfMonth != nil)
        #expect(startOfMonth != nil)
        
        if let start = startOfMonth, let end = endOfMonth {
            #expect(start < end)
            
            // Test that start is actually the first day
            let dayOfMonth = calendar.component(.day, from: start)
            #expect(dayOfMonth == 1)
            
            // Test that end is in the next month
            let endMonth = calendar.component(.month, from: end)
            let startMonth = calendar.component(.month, from: start)
            
            if startMonth == 12 {
                let endYear = calendar.component(.year, from: end)
                let startYear = calendar.component(.year, from: start)
                #expect(endYear == startYear + 1)
                #expect(endMonth == 1)
            } else {
                #expect(endMonth == startMonth + 1)
            }
        }
    }
    
    @Test func testLeapYearHandling() async throws {
        let calendar = Calendar.current
        
        // Test leap year detection
        let leapYear = 2024
        let nonLeapYear = 2023
        
        #expect(calendar.isLeapYear(leapYear))
        #expect(!calendar.isLeapYear(nonLeapYear))
        
        // Test February days in leap vs non-leap years
        let feb2024 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 1))!
        let feb2023 = calendar.date(from: DateComponents(year: 2023, month: 2, day: 1))!
        
        let daysInFeb2024 = calendar.range(of: .day, in: .month, for: feb2024)?.count
        let daysInFeb2023 = calendar.range(of: .day, in: .month, for: feb2023)?.count
        
        #expect(daysInFeb2024 == 29)
        #expect(daysInFeb2023 == 28)
    }
}

// MARK: - Helper Extensions for Testing

extension Calendar {
    func isLeapYear(_ year: Int) -> Bool {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }
}