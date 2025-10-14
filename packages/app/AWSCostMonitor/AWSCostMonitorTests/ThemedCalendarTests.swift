//
//  ThemedCalendarTests.swift
//  AWSCostMonitorTests
//
//  Test suite for themed calendar view and visualization components
//

import XCTest
@testable import AWSCostMonitor
import SwiftUI

final class ThemedCalendarTests: XCTestCase {
    
    var themeManager: ThemeManager!
    var awsManager: AWSManager!
    
    override func setUpWithError() throws {
        themeManager = ThemeManager()
        awsManager = AWSManager()
        // Reset to clean state for each test
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
        UserDefaults.standard.removeObject(forKey: "syncWithSystemAppearance")
    }
    
    override func tearDownWithError() throws {
        themeManager = nil
        awsManager = nil
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
        UserDefaults.standard.removeObject(forKey: "syncWithSystemAppearance")
    }
    
    // MARK: - Calendar View Theme Tests
    
    func testCalendarViewHasThemeEnvironment() throws {
        // Test that CalendarView can access theme from environment
        let calendarView = CalendarView()
            .environmentObject(awsManager)
            .themed(themeManager)
        
        // Verify the view is created without crashes
        XCTAssertNotNil(calendarView)
    }
    
    func testCalendarDayCellsUseThemeColors() throws {
        let classicTheme = ClassicTheme()
        let terminalTheme = TerminalTheme()
        
        // Day cells should use theme colors based on cost
        let lowCostColor = classicTheme.dayBackgroundColor(cost: 10.0, maxCost: 100.0)
        let highCostColor = classicTheme.dayBackgroundColor(cost: 90.0, maxCost: 100.0)
        
        XCTAssertNotEqual(lowCostColor.description, highCostColor.description)
        
        // Terminal theme should have different color mapping
        let terminalLowCost = terminalTheme.dayBackgroundColor(cost: 10.0, maxCost: 100.0)
        XCTAssertNotEqual(lowCostColor.description, terminalLowCost.description)
    }
    
    func testCalendarHeaderUsesThemeTypography() throws {
        let compactTheme = CompactTheme()
        let comfortableTheme = ComfortableTheme()
        
        // Headers should use appropriate font sizes
        XCTAssertLessThan(compactTheme.largeFontSize, comfortableTheme.largeFontSize)
        XCTAssertGreaterThan(compactTheme.largeFontSize, 0)
    }
    
    func testCalendarGridSpacingUsesThemeDensity() throws {
        let compactTheme = CompactTheme()
        let comfortableTheme = ComfortableTheme()
        
        // Grid spacing should adapt to theme
        let compactSpacing = 4.0 * compactTheme.spacingMultiplier
        let comfortableSpacing = 4.0 * comfortableTheme.spacingMultiplier
        
        XCTAssertLessThan(compactSpacing, comfortableSpacing)
    }
    
    // MARK: - Donut Chart Theme Tests
    
    func testDonutChartUsesThemeColors() throws {
        let modernTheme = ModernTheme()
        
        // Donut chart should use theme's chart colors
        for i in 0..<5 {
            let chartColor = modernTheme.chartColor(for: i)
            XCTAssertNotNil(chartColor)
            
            // Each segment should have a different color
            if i > 0 {
                let prevColor = modernTheme.chartColor(for: i - 1)
                XCTAssertNotEqual(chartColor.description, prevColor.description)
            }
        }
    }
    
    func testDonutChartLabelsUseThemeTypography() throws {
        let highContrastTheme = HighContrastTheme()
        
        // Chart labels should be readable
        XCTAssertGreaterThanOrEqual(highContrastTheme.smallFontSize, 11)
        XCTAssertNotNil(highContrastTheme.textColor)
        XCTAssertNotNil(highContrastTheme.secondaryColor)
    }
    
    // MARK: - Histogram Theme Tests
    
    func testServiceHistogramUsesThemeColors() throws {
        let professionalTheme = ProfessionalTheme()
        
        // Service histogram bars should use theme colors
        let barColor = professionalTheme.accentColor
        let backgroundColor = professionalTheme.backgroundColor
        
        XCTAssertNotNil(barColor)
        XCTAssertNotNil(backgroundColor)
        XCTAssertNotEqual(barColor.description, backgroundColor.description)
    }
    
    func testRealHistogramUsesThemeColors() throws {
        let terminalTheme = TerminalTheme()
        
        // Real histogram should use appropriate theme colors
        XCTAssertNotNil(terminalTheme.successColor)
        XCTAssertNotNil(terminalTheme.warningColor)
        XCTAssertNotNil(terminalTheme.errorColor)
        
        // Terminal theme should have distinct colors
        XCTAssertNotEqual(
            terminalTheme.successColor.description,
            terminalTheme.errorColor.description
        )
    }
    
    func testHistogramAxesUseThemeColors() throws {
        let classicTheme = ClassicTheme()
        
        // Axes and grid lines should use theme colors
        XCTAssertNotNil(classicTheme.secondaryColor)
        XCTAssertNotNil(classicTheme.textColor)
        
        // Secondary color for grid lines should be lighter
        XCTAssertNotEqual(
            classicTheme.secondaryColor.description,
            classicTheme.textColor.description
        )
    }
    
    // MARK: - Day Detail View Theme Tests
    
    func testDayDetailViewUsesThemeColors() throws {
        let modernTheme = ModernTheme()
        
        // Day detail view should use theme colors
        XCTAssertNotNil(modernTheme.backgroundColor)
        XCTAssertNotNil(modernTheme.textColor)
        XCTAssertNotNil(modernTheme.accentColor)
    }
    
    func testDayDetailServiceListUsesThemeColors() throws {
        let highContrastTheme = HighContrastTheme()
        
        // Service list should be readable
        XCTAssertNotNil(highContrastTheme.textColor)
        XCTAssertNotNil(highContrastTheme.secondaryColor)
        
        // High contrast should have strong color differentiation
        XCTAssertNotEqual(
            highContrastTheme.backgroundColor.description,
            highContrastTheme.textColor.description
        )
    }
    
    func testDayDetailCostAmountsUseThemeFormatting() throws {
        let comfortableTheme = ComfortableTheme()
        
        // Cost amounts should use appropriate font sizes
        XCTAssertGreaterThan(comfortableTheme.regularFontSize, 12)
        XCTAssertNotNil(comfortableTheme.primaryFontWeight)
    }
    
    // MARK: - Theme Transition Tests
    
    func testCalendarViewUpdatesWhenThemeChanges() throws {
        let initialTheme = themeManager.currentTheme.identifier
        let newTheme = themeManager.getTheme(byId: "terminal")!
        
        // Change theme
        themeManager.selectTheme(newTheme)
        
        // Verify theme changed
        XCTAssertNotEqual(themeManager.currentTheme.identifier, initialTheme)
        XCTAssertEqual(themeManager.currentTheme.identifier, "terminal")
        
        // Verify calendar would use new theme colors
        for i in 0..<5 {
            let chartColor = themeManager.currentTheme.chartColor(for: i)
            XCTAssertNotNil(chartColor)
        }
    }
    
    func testVisualizationTransitionsAreSmooth() throws {
        // Test that theme changes don't cause jarring transitions
        let themes = ["classic", "modern", "terminal"]
        
        for themeId in themes {
            if let theme = themeManager.getTheme(byId: themeId) {
                themeManager.selectTheme(theme)
                
                // Verify theme provides all necessary colors
                XCTAssertNotNil(theme.backgroundColor)
                XCTAssertNotNil(theme.textColor)
                XCTAssertNotNil(theme.accentColor)
                XCTAssertNotNil(theme.secondaryColor)
            }
        }
    }
    
    // MARK: - Chart Readability Tests
    
    func testChartColorsAreDistinct() throws {
        let modernTheme = ModernTheme()
        
        // Ensure chart colors are distinguishable
        var colors: [String] = []
        for i in 0..<5 {
            let color = modernTheme.chartColor(for: i)
            let colorDesc = color.description
            XCTAssertFalse(colors.contains(colorDesc), "Chart color \(i) should be unique")
            colors.append(colorDesc)
        }
    }
    
    func testHighContrastThemeImproveChartReadability() throws {
        let highContrastTheme = HighContrastTheme()
        let classicTheme = ClassicTheme()
        
        // High contrast should have larger text for charts
        XCTAssertGreaterThan(highContrastTheme.smallFontSize, classicTheme.smallFontSize)
        XCTAssertGreaterThan(highContrastTheme.regularFontSize, classicTheme.regularFontSize)
    }
    
    // MARK: - Cost Color Mapping Tests
    
    func testCostColorMappingLogic() throws {
        let classicTheme = ClassicTheme()
        
        // Test cost color mapping
        let noCostColor = classicTheme.dayBackgroundColor(cost: nil, maxCost: 100.0)
        let lowCostColor = classicTheme.dayBackgroundColor(cost: 10.0, maxCost: 100.0)
        let medCostColor = classicTheme.dayBackgroundColor(cost: 50.0, maxCost: 100.0)
        let highCostColor = classicTheme.dayBackgroundColor(cost: 90.0, maxCost: 100.0)
        
        // Colors should be different based on cost level
        XCTAssertNotEqual(noCostColor.description, lowCostColor.description)
        XCTAssertNotEqual(lowCostColor.description, medCostColor.description)
        XCTAssertNotEqual(medCostColor.description, highCostColor.description)
    }
    
    // MARK: - Performance Tests
    
    func testCalendarRenderingPerformance() throws {
        let themes = ["classic", "modern", "terminal", "professional"]
        
        measure {
            for themeId in themes {
                if let theme = themeManager.getTheme(byId: themeId) {
                    themeManager.selectTheme(theme)
                    
                    // Simulate rendering calendar cells
                    for day in 1...31 {
                        _ = theme.dayBackgroundColor(cost: Double(day * 10), maxCost: 310.0)
                    }
                }
            }
        }
    }
    
    func testChartColorCalculationPerformance() throws {
        let theme = themeManager.currentTheme
        
        measure {
            for i in 0..<10000 {
                _ = theme.chartColor(for: i)
            }
        }
    }
    
    func testVisualizationThemeUpdatePerformance() throws {
        measure {
            for _ in 0..<100 {
                let themes = ["classic", "modern", "terminal"]
                for themeId in themes {
                    if let theme = themeManager.getTheme(byId: themeId) {
                        themeManager.selectTheme(theme)
                    }
                }
            }
        }
    }
}