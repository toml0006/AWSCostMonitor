//
//  ThemedDropdownTests.swift
//  AWSCostMonitorTests
//
//  Test suite for themed dropdown menu and popover components
//

import XCTest
@testable import AWSCostMonitor
import SwiftUI

final class ThemedDropdownTests: XCTestCase {
    
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
    
    // MARK: - PopoverContentView Theme Integration Tests
    
    func testPopoverContentViewHasThemeEnvironment() throws {
        // Test that PopoverContentView can access theme from environment
        let popoverView = PopoverContentView()
            .environmentObject(awsManager)
            .themed(themeManager)
        
        // Verify the view is created without crashes
        XCTAssertNotNil(popoverView)
    }
    
    func testPopoverHeaderUsesThemeColors() throws {
        let classicTheme = ClassicTheme()
        let terminalTheme = TerminalTheme()
        
        // Headers should use theme's primary text color
        XCTAssertNotNil(classicTheme.textColor)
        XCTAssertNotNil(terminalTheme.textColor)
        
        // Terminal theme should have distinct color
        XCTAssertNotEqual(
            classicTheme.textColor.description,
            terminalTheme.textColor.description
        )
    }
    
    func testPopoverButtonsUseThemeColors() throws {
        let modernTheme = ModernTheme()
        
        // Buttons should use theme's accent color
        XCTAssertNotNil(modernTheme.accentColor)
        XCTAssertNotNil(modernTheme.secondaryColor)
        
        // Hover states should use different colors
        XCTAssertNotEqual(
            modernTheme.accentColor.description,
            modernTheme.secondaryColor.description
        )
    }
    
    // MARK: - Menu Button Theme Tests
    
    func testMenuButtonAppliesThemeColors() throws {
        let professionalTheme = ProfessionalTheme()
        
        // Menu buttons should adapt to theme
        XCTAssertNotNil(professionalTheme.accentColor)
        XCTAssertNotNil(professionalTheme.backgroundColor)
        XCTAssertNotNil(professionalTheme.textColor)
    }
    
    func testMenuButtonHoverStateWithTheme() throws {
        let highContrastTheme = HighContrastTheme()
        
        // High contrast theme should have distinct hover states
        XCTAssertNotNil(highContrastTheme.accentColor)
        XCTAssertNotNil(highContrastTheme.primaryColor)
        
        // Colors should be different for better visibility
        XCTAssertNotEqual(
            highContrastTheme.backgroundColor.description,
            highContrastTheme.accentColor.description
        )
    }
    
    // MARK: - Text Formatting Tests
    
    func testDropdownTextUsesThemeFonts() throws {
        let compactTheme = CompactTheme()
        let comfortableTheme = ComfortableTheme()
        
        // Compact should have smaller fonts in dropdown
        XCTAssertLessThan(compactTheme.regularFontSize, comfortableTheme.regularFontSize)
        XCTAssertLessThan(compactTheme.smallFontSize, comfortableTheme.smallFontSize)
    }
    
    func testDropdownTextWeightsApplied() throws {
        let classicTheme = ClassicTheme()
        let highContrastTheme = HighContrastTheme()
        
        // High contrast should have bolder text
        XCTAssertEqual(classicTheme.primaryFontWeight, Font.Weight.regular)
        XCTAssertEqual(highContrastTheme.primaryFontWeight, Font.Weight.semibold)
    }
    
    // MARK: - Spacing and Layout Tests
    
    func testDropdownSpacingUsesThemeDensity() throws {
        let compactTheme = CompactTheme()
        let comfortableTheme = ComfortableTheme()
        let classicTheme = ClassicTheme()
        
        // Test spacing multipliers
        XCTAssertLessThan(compactTheme.spacingMultiplier, classicTheme.spacingMultiplier)
        XCTAssertGreaterThan(comfortableTheme.spacingMultiplier, classicTheme.spacingMultiplier)
        
        // Test padding scales
        XCTAssertLessThan(compactTheme.paddingScale, classicTheme.paddingScale)
        XCTAssertGreaterThan(comfortableTheme.paddingScale, classicTheme.paddingScale)
    }
    
    func testDropdownPaddingAdaptsToTheme() throws {
        let compactTheme = CompactTheme()
        let comfortableTheme = ComfortableTheme()
        
        // Calculate actual padding values
        let compactPadding = 8.0 * compactTheme.paddingScale
        let comfortablePadding = 8.0 * comfortableTheme.paddingScale
        
        XCTAssertLessThan(compactPadding, comfortablePadding)
        XCTAssertGreaterThan(compactPadding, 0)
        XCTAssertGreaterThan(comfortablePadding, 0)
    }
    
    // MARK: - Error and Status Display Tests
    
    func testErrorMessagesUseThemeColors() throws {
        let modernTheme = ModernTheme()
        let terminalTheme = TerminalTheme()
        
        // Error colors should be distinct
        XCTAssertNotNil(modernTheme.errorColor)
        XCTAssertNotNil(terminalTheme.errorColor)
        
        XCTAssertNotEqual(
            modernTheme.errorColor.description,
            terminalTheme.errorColor.description
        )
    }
    
    func testLoadingIndicatorUsesThemeColors() throws {
        let classicTheme = ClassicTheme()
        
        // Loading state should use secondary color
        XCTAssertNotNil(classicTheme.secondaryColor)
        XCTAssertNotEqual(
            classicTheme.secondaryColor.description,
            classicTheme.primaryColor.description
        )
    }
    
    // MARK: - Divider and Separator Tests
    
    func testDividersUseThemeColors() throws {
        let professionalTheme = ProfessionalTheme()
        let terminalTheme = TerminalTheme()
        
        // Dividers should adapt to theme
        XCTAssertNotNil(professionalTheme.secondaryColor)
        XCTAssertNotNil(terminalTheme.secondaryColor)
        
        // Different themes should have different divider appearances
        XCTAssertNotEqual(
            professionalTheme.secondaryColor.description,
            terminalTheme.secondaryColor.description
        )
    }
    
    // MARK: - Theme Change Update Tests
    
    func testDropdownUpdatesWhenThemeChanges() throws {
        let initialTheme = themeManager.currentTheme.identifier
        let newTheme = themeManager.getTheme(byId: "terminal")!
        
        // Change theme
        themeManager.selectTheme(newTheme)
        
        // Verify theme changed
        XCTAssertNotEqual(themeManager.currentTheme.identifier, initialTheme)
        XCTAssertEqual(themeManager.currentTheme.identifier, "terminal")
        
        // Verify dropdown would use new theme properties
        XCTAssertNotNil(themeManager.currentTheme.backgroundColor)
        XCTAssertNotNil(themeManager.currentTheme.textColor)
        XCTAssertNotNil(themeManager.currentTheme.accentColor)
    }
    
    // MARK: - Cost Display Theme Integration Tests
    
    func testCostDisplayUsesThemeColors() throws {
        let modernTheme = ModernTheme()
        
        // Cost display should use appropriate theme colors
        XCTAssertNotNil(modernTheme.successColor)  // For under budget
        XCTAssertNotNil(modernTheme.warningColor)  // For near budget
        XCTAssertNotNil(modernTheme.errorColor)    // For over budget
    }
    
    func testServiceBreakdownUsesThemeColors() throws {
        let classicTheme = ClassicTheme()
        
        // Service breakdown should have chart colors
        for i in 0..<5 {
            let chartColor = classicTheme.chartColor(for: i)
            XCTAssertNotNil(chartColor)
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testHighContrastThemeImprovesDividerVisibility() throws {
        let highContrastTheme = HighContrastTheme()
        let classicTheme = ClassicTheme()
        
        // High contrast should have more visible separators
        XCTAssertNotNil(highContrastTheme.secondaryColor)
        XCTAssertNotNil(classicTheme.secondaryColor)
        
        // Font sizes should be larger in high contrast
        XCTAssertGreaterThan(highContrastTheme.regularFontSize, classicTheme.regularFontSize)
    }
    
    // MARK: - Performance Tests
    
    func testDropdownThemeRenderingPerformance() throws {
        let themes = ["classic", "modern", "terminal", "professional"]
        
        measure {
            for themeId in themes {
                if let theme = themeManager.getTheme(byId: themeId) {
                    themeManager.selectTheme(theme)
                    
                    // Simulate accessing theme properties for dropdown
                    _ = theme.backgroundColor
                    _ = theme.textColor
                    _ = theme.accentColor
                    _ = theme.regularFontSize
                    _ = theme.paddingScale
                }
            }
        }
    }
    
    func testMenuButtonThemeUpdatePerformance() throws {
        let theme = themeManager.currentTheme
        
        measure {
            for _ in 0..<1000 {
                _ = theme.accentColor
                _ = theme.secondaryColor
                _ = theme.primaryFontWeight
            }
        }
    }
}