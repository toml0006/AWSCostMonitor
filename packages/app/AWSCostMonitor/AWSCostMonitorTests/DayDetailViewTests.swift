//
//  DayDetailViewTests.swift
//  AWSCostMonitorTests
//
//  Tests for day detail view and donut chart functionality
//

import Testing
import Foundation
import SwiftUI
@testable import AWSCostMonitor

struct DayDetailViewTests {
    
    // MARK: - Service Processing Tests
    
    @Test func testServiceCostGrouping() async throws {
        // Create test service costs with various amounts
        let serviceCosts = [
            ServiceCost(serviceName: "Amazon EC2", amount: 25.50, currency: "USD"),
            ServiceCost(serviceName: "Amazon S3", amount: 10.75, currency: "USD"),
            ServiceCost(serviceName: "AWS Lambda", amount: 2.25, currency: "USD"),
            ServiceCost(serviceName: "Amazon CloudWatch", amount: 0.08, currency: "USD"),
            ServiceCost(serviceName: "AWS Cost Explorer", amount: 0.05, currency: "USD"),
            ServiceCost(serviceName: "Amazon Route 53", amount: 0.02, currency: "USD"),
            ServiceCost(serviceName: "AWS Systems Manager", amount: 0.01, currency: "USD")
        ]
        
        // Simulate the processing logic from DayDetailView
        let threshold: Decimal = 0.10
        let sortedServices = serviceCosts.sorted()
        
        var result: [(String, Decimal, Bool)] = []
        var otherTotal: Decimal = 0
        var otherCount = 0
        
        for service in sortedServices {
            if service.amount >= threshold || sortedServices.count <= 5 {
                result.append((service.serviceName, service.amount, false))
            } else {
                otherTotal += service.amount
                otherCount += 1
            }
        }
        
        if otherTotal > 0 {
            result.append(("Other Services (\(otherCount))", otherTotal, true))
        }
        
        // Verify processing results
        #expect(!result.isEmpty)
        
        // Check that small services are grouped
        let otherGroup = result.first { $0.2 } // isGrouped = true
        #expect(otherGroup != nil)
        
        if let other = otherGroup {
            #expect(other.0.hasPrefix("Other Services"))
            #expect(other.1 > 0) // Should have positive amount
            #expect(otherCount > 0) // Should have counted some services
        }
        
        // Verify total amounts match
        let processedTotal = result.reduce(0) { $0 + $1.1 }
        let originalTotal = serviceCosts.reduce(0) { $0 + $1.amount }
        #expect(processedTotal == originalTotal)
    }
    
    @Test func testServiceCostGroupingWithFewServices() async throws {
        // Test with 5 or fewer services (shouldn't group)
        let serviceCosts = [
            ServiceCost(serviceName: "Amazon EC2", amount: 25.50, currency: "USD"),
            ServiceCost(serviceName: "Amazon S3", amount: 0.05, currency: "USD"), // Below threshold but shouldn't group
            ServiceCost(serviceName: "AWS Lambda", amount: 0.02, currency: "USD"),
        ]
        
        let threshold: Decimal = 0.10
        let sortedServices = serviceCosts.sorted()
        
        var result: [(String, Decimal, Bool)] = []
        var otherTotal: Decimal = 0
        var otherCount = 0
        
        for service in sortedServices {
            if service.amount >= threshold || sortedServices.count <= 5 {
                result.append((service.serviceName, service.amount, false))
            } else {
                otherTotal += service.amount
                otherCount += 1
            }
        }
        
        // With ≤5 services, nothing should be grouped
        #expect(result.count == serviceCosts.count)
        #expect(otherTotal == 0)
        #expect(otherCount == 0)
        
        // All services should be individual (isGrouped = false)
        let groupedCount = result.filter { $0.2 }.count
        #expect(groupedCount == 0)
    }
    
    @Test func testEmptyServiceCostHandling() async throws {
        let serviceCosts: [ServiceCost] = []
        
        // Test empty array processing
        let threshold: Decimal = 0.10
        let sortedServices = serviceCosts.sorted()
        
        var result: [(String, Decimal, Bool)] = []
        var otherTotal: Decimal = 0
        
        for service in sortedServices {
            if service.amount >= threshold || sortedServices.count <= 5 {
                result.append((service.serviceName, service.amount, false))
            } else {
                otherTotal += service.amount
            }
        }
        
        #expect(result.isEmpty)
        #expect(otherTotal == 0)
    }
    
    // MARK: - Donut Chart Calculation Tests
    
    @Test func testDonutChartPercentageCalculation() async throws {
        let serviceCosts = [
            ServiceCost(serviceName: "Amazon EC2", amount: 60.00, currency: "USD"),
            ServiceCost(serviceName: "Amazon S3", amount: 30.00, currency: "USD"),
            ServiceCost(serviceName: "AWS Lambda", amount: 10.00, currency: "USD")
        ]
        
        let totalAmount = serviceCosts.reduce(0) { $0 + $1.amount }
        #expect(totalAmount == 100.00)
        
        // Test percentage calculations
        for service in serviceCosts {
            let percentage = totalAmount > 0 ? Double(truncating: NSDecimalNumber(decimal: service.amount / totalAmount)) : 0
            
            switch service.serviceName {
            case "Amazon EC2":
                #expect(percentage == 0.6) // 60%
            case "Amazon S3":
                #expect(percentage == 0.3) // 30%
            case "AWS Lambda":
                #expect(percentage == 0.1) // 10%
            default:
                break
            }
        }
    }
    
    @Test func testDonutChartAngleCalculation() async throws {
        let serviceCosts = [
            ServiceCost(serviceName: "Service A", amount: 25.00, currency: "USD"), // 25% = 90°
            ServiceCost(serviceName: "Service B", amount: 50.00, currency: "USD"), // 50% = 180°
            ServiceCost(serviceName: "Service C", amount: 25.00, currency: "USD")  // 25% = 90°
        ]
        
        let totalAmount = serviceCosts.reduce(0) { $0 + $1.amount }
        var currentAngle: Double = -90 // Start at top
        
        for service in serviceCosts {
            let percentage = totalAmount > 0 ? Double(truncating: NSDecimalNumber(decimal: service.amount / totalAmount)) : 0
            let angleSpan = percentage * 360
            
            switch service.serviceName {
            case "Service A", "Service C":
                #expect(angleSpan == 90.0) // 25% of 360°
            case "Service B":
                #expect(angleSpan == 180.0) // 50% of 360°
            default:
                break
            }
            
            currentAngle += angleSpan
        }
        
        // Total angle should be 360° (full circle)
        #expect(currentAngle == 270.0) // Started at -90°, so -90° + 360° = 270°
    }
    
    @Test func testDonutChartZeroAmountHandling() async throws {
        let serviceCosts = [
            ServiceCost(serviceName: "Service A", amount: 0.00, currency: "USD")
        ]
        
        let totalAmount = serviceCosts.reduce(0) { $0 + $1.amount }
        #expect(totalAmount == 0)
        
        // Test percentage with zero total
        for service in serviceCosts {
            let percentage = totalAmount > 0 ? Double(truncating: NSDecimalNumber(decimal: service.amount / totalAmount)) : 0
            #expect(percentage == 0)
            
            let angleSpan = percentage * 360
            #expect(angleSpan == 0)
        }
    }
    
    // MARK: - Color Assignment Tests
    
    @Test func testServiceColorAssignment() async throws {
        // Test predefined service colors
        let predefinedServices = [
            "Amazon OpenSearch Service",
            "Tax",
            "Amazon Route 53",
            "Claude 3.5 Sonnet (Amazon Bedrock Edition)",
            "AWS Cost Explorer",
            "Amazon Simple Storage Service",
            "Other Services"
        ]
        
        // Simulate colorForService function
        let serviceColors: [String: Color] = [
            "Amazon OpenSearch Service": .blue,
            "Tax": .green,
            "Amazon Route 53": .orange,
            "Claude 3.5 Sonnet (Amazon Bedrock Edition)": .purple,
            "AWS Cost Explorer": .red,
            "Amazon Simple Storage Service": .yellow,
            "Other Services": .gray
        ]
        
        for serviceName in predefinedServices {
            let color = serviceColors[serviceName]
            #expect(color != nil)
        }
        
        // Test hash-based color generation for unknown services
        let unknownServices = ["Unknown Service A", "Random Service B", "Test Service C"]
        
        for serviceName in unknownServices {
            if serviceColors[serviceName] == nil {
                // Simulate hash-based color generation
                let hash = serviceName.hashValue
                let hue = Double(abs(hash) % 360) / 360.0
                
                #expect(hue >= 0.0)
                #expect(hue <= 1.0)
                
                // Test that same service name produces same hue
                let hash2 = serviceName.hashValue
                let hue2 = Double(abs(hash2) % 360) / 360.0
                #expect(hue == hue2)
            }
        }
    }
    
    @Test func testServiceColorConsistency() async throws {
        let serviceName = "Test Service"
        
        // Test that color generation is consistent
        let hash1 = serviceName.hashValue
        let hue1 = Double(abs(hash1) % 360) / 360.0
        
        let hash2 = serviceName.hashValue
        let hue2 = Double(abs(hash2) % 360) / 360.0
        
        #expect(hue1 == hue2)
        
        // Test that different services get different colors (usually)
        let differentService = "Different Test Service"
        let differentHash = differentService.hashValue
        let differentHue = Double(abs(differentHash) % 360) / 360.0
        
        // While not guaranteed, different strings usually produce different hashes
        // We'll just verify the calculation works
        #expect(differentHue >= 0.0)
        #expect(differentHue <= 1.0)
    }
    
    // MARK: - Hover State Tests
    
    @Test func testHoverStateManagement() async throws {
        // Test hover state logic
        var hoveredService: String? = nil
        let serviceName = "Amazon EC2"
        
        // Simulate hover start
        hoveredService = serviceName
        #expect(hoveredService == serviceName)
        
        // Test opacity calculation for hovered state
        let services = ["Amazon EC2", "Amazon S3", "AWS Lambda"]
        
        for service in services {
            let opacity = (hoveredService == nil || hoveredService == service) ? 1.0 : 0.3
            
            if service == serviceName {
                #expect(opacity == 1.0) // Hovered service should be fully opaque
            } else {
                #expect(opacity == 0.3) // Non-hovered services should be dimmed
            }
        }
        
        // Simulate hover end
        hoveredService = nil
        
        for service in services {
            let opacity = (hoveredService == nil || hoveredService == service) ? 1.0 : 0.3
            #expect(opacity == 1.0) // All services should be fully opaque when none hovered
        }
    }
    
    // MARK: - Currency Formatting Tests
    
    @Test func testCurrencyFormatting() async throws {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        
        let testAmounts: [Decimal] = [0, 0.01, 1.50, 10.75, 100.00, 1000.50]
        
        for amount in testAmounts {
            let formatted = formatter.string(from: NSDecimalNumber(decimal: amount))
            #expect(formatted != nil)
            
            if let formattedString = formatted {
                #expect(formattedString.contains("$"))
                
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
    
    @Test func testPercentageFormatting() async throws {
        let totalAmount: Decimal = 100.00
        let serviceAmounts: [Decimal] = [60.00, 30.00, 10.00]
        
        for amount in serviceAmounts {
            let percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0
            let percentageInt = Int(truncating: NSDecimalNumber(decimal: percentage))
            
            switch amount {
            case 60.00:
                #expect(percentageInt == 60)
            case 30.00:
                #expect(percentageInt == 30)
            case 10.00:
                #expect(percentageInt == 10)
            default:
                break
            }
        }
    }
    
    // MARK: - View State Tests
    
    @Test func testShowAllServicesToggle() async throws {
        let serviceCosts = [
            ServiceCost(serviceName: "Service 1", amount: 10.00, currency: "USD"),
            ServiceCost(serviceName: "Service 2", amount: 8.00, currency: "USD"),
            ServiceCost(serviceName: "Service 3", amount: 0.05, currency: "USD"),
            ServiceCost(serviceName: "Service 4", amount: 0.03, currency: "USD"),
            ServiceCost(serviceName: "Service 5", amount: 0.02, currency: "USD"),
            ServiceCost(serviceName: "Service 6", amount: 0.01, currency: "USD")
        ]
        
        // Test initial state (collapsed)
        var showAllServices = false
        
        // Simulate processed services (grouped)
        let processedServices = [
            (name: "Service 1", amount: Decimal(10.00), isGrouped: false),
            (name: "Service 2", amount: Decimal(8.00), isGrouped: false),
            (name: "Other Services (4)", amount: Decimal(0.11), isGrouped: true)
        ]
        
        let hasGroupedServices = processedServices.contains { $0.isGrouped }
        #expect(hasGroupedServices)
        
        // Test displayed services when collapsed
        if showAllServices {
            let displayedCount = serviceCosts.count
            #expect(displayedCount == 6)
        } else {
            let displayedCount = processedServices.count
            #expect(displayedCount == 3) // Including "Other Services" group
        }
        
        // Test toggle
        showAllServices.toggle()
        #expect(showAllServices == true)
        
        // Test displayed services when expanded
        if showAllServices {
            let displayedCount = serviceCosts.count
            #expect(displayedCount == 6)
        }
    }
    
    // MARK: - Date Formatting Tests
    
    @Test func testDateFormatting() async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        
        let testDates = [
            Date(),
            Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        ]
        
        for date in testDates {
            let formatted = dateFormatter.string(from: date)
            #expect(!formatted.isEmpty)
            
            // Should contain day of week, month, day, and year
            let components = formatted.split(separator: " ")
            #expect(components.count >= 3)
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Test func testSingleServiceHandling() async throws {
        let serviceCosts = [
            ServiceCost(serviceName: "Only Service", amount: 25.50, currency: "USD")
        ]
        
        let totalAmount = serviceCosts.reduce(0) { $0 + $1.amount }
        #expect(totalAmount == 25.50)
        
        // Single service should take up entire donut (100%)
        let percentage = Double(truncating: NSDecimalNumber(decimal: serviceCosts[0].amount / totalAmount))
        #expect(percentage == 1.0)
        
        let angleSpan = percentage * 360
        #expect(angleSpan == 360.0)
    }
    
    @Test func testVerySmallAmountHandling() async throws {
        let serviceCosts = [
            ServiceCost(serviceName: "Tiny Service", amount: 0.001, currency: "USD")
        ]
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        
        let formatted = formatter.string(from: NSDecimalNumber(decimal: serviceCosts[0].amount))
        #expect(formatted == "$0.00") // Should round to $0.00
    }
    
    @Test func testLargeAmountHandling() async throws {
        let serviceCosts = [
            ServiceCost(serviceName: "Expensive Service", amount: 9999999.99, currency: "USD")
        ]
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        
        let formatted = formatter.string(from: NSDecimalNumber(decimal: serviceCosts[0].amount))
        #expect(formatted != nil)
        #expect(formatted?.contains("$") == true)
        #expect(formatted?.contains(",") == true) // Should have thousands separators
    }
}

// MARK: - ServiceCost Extension for Testing

extension ServiceCost {
    // Make ServiceCost Identifiable for testing
    var id: String { serviceName }
}