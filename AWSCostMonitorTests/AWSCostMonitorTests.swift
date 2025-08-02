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

}
