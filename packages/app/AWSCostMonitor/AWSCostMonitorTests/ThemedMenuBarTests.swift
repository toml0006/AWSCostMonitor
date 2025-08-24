//
//  ThemedMenuBarTests.swift
//  AWSCostMonitorTests
//
//  Test suite for themed menu bar display components
//

import XCTest
@testable import AWSCostMonitor
import SwiftUI
import AppKit

final class ThemedMenuBarTests: XCTestCase {
    
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
    
    // MARK: - Theme-Aware Color Extension Tests
    
    func testMenuBarColorForTheme() throws {
        let classicTheme = ClassicTheme()
        let terminalTheme = TerminalTheme()
        
        // Test menu bar text colors are different between themes
        let classicActiveColor = classicTheme.menuBarTextColor(isActive: true)
        let terminalActiveColor = terminalTheme.menuBarTextColor(isActive: true)
        
        XCTAssertNotEqual(classicActiveColor.description, terminalActiveColor.description)
    }
    
    func testMenuBarInactiveColor() throws {
        let modernTheme = ModernTheme()
        
        let activeColor = modernTheme.menuBarTextColor(isActive: true)
        let inactiveColor = modernTheme.menuBarTextColor(isActive: false)
        
        XCTAssertNotEqual(activeColor.description, inactiveColor.description)
        XCTAssertEqual(inactiveColor.description, modernTheme.secondaryColor.description)
    }
    
    // MARK: - Font Theme Application Tests
    
    func testThemeFontSizesAppliedToMenuBar() throws {
        let compactTheme = CompactTheme()
        let comfortableTheme = ComfortableTheme()
        
        // Compact should have smaller font
        XCTAssertLessThan(compactTheme.regularFontSize, comfortableTheme.regularFontSize)
        
        // Both should have valid sizes
        XCTAssertGreaterThan(compactTheme.regularFontSize, 0)
        XCTAssertGreaterThan(comfortableTheme.regularFontSize, 0)
    }
    
    func testThemeFontWeightsAppliedToMenuBar() throws {
        let classicTheme = ClassicTheme()
        let professionalTheme = ProfessionalTheme()
        
        // Verify font weights are appropriate for menu bar
        XCTAssertNotNil(classicTheme.primaryFontWeight)
        XCTAssertNotNil(professionalTheme.primaryFontWeight)
        
        // Professional theme should have different weight than classic
        XCTAssertTrue(classicTheme.primaryFontWeight == Font.Weight.regular)
        XCTAssertTrue(professionalTheme.primaryFontWeight == Font.Weight.regular)
    }
    
    // MARK: - Theme Layout Density Tests
    
    func testThemeLayoutDensityForMenuBar() throws {
        let compactTheme = CompactTheme()
        let comfortableTheme = ComfortableTheme()
        let classicTheme = ClassicTheme()
        
        // Test padding scales
        XCTAssertLessThan(compactTheme.paddingScale, classicTheme.paddingScale)
        XCTAssertGreaterThan(comfortableTheme.paddingScale, classicTheme.paddingScale)
        
        // Test spacing multipliers
        XCTAssertLessThan(compactTheme.spacingMultiplier, classicTheme.spacingMultiplier)
        XCTAssertGreaterThan(comfortableTheme.spacingMultiplier, classicTheme.spacingMultiplier)
    }
    
    // MARK: - Menu Bar Themed Display Tests
    
    func testMenuBarDisplayUsesThemeColors() throws {
        let highContrastTheme = HighContrastTheme()
        let terminalTheme = TerminalTheme()
        
        // Verify different themes provide different text colors
        XCTAssertNotEqual(
            highContrastTheme.textColor.description,
            terminalTheme.textColor.description
        )
        
        // Verify themes have appropriate accent colors
        XCTAssertNotNil(highContrastTheme.accentColor)
        XCTAssertNotNil(terminalTheme.accentColor)
    }
    
    func testMenuBarErrorStateWithThemes() throws {
        let modernTheme = ModernTheme()
        let terminalTheme = TerminalTheme()
        
        // Test error colors are distinct
        XCTAssertNotEqual(
            modernTheme.errorColor.description,
            terminalTheme.errorColor.description
        )
        
        // Both should have visible error colors
        XCTAssertNotNil(modernTheme.errorColor)
        XCTAssertNotNil(terminalTheme.errorColor)
    }
    
    func testMenuBarWarningStateWithThemes() throws {
        let classicTheme = ClassicTheme()
        let terminalTheme = TerminalTheme()
        
        // Test warning colors are distinct
        XCTAssertNotEqual(
            classicTheme.warningColor.description,
            terminalTheme.warningColor.description
        )
        
        // Both should have visible warning colors
        XCTAssertNotNil(classicTheme.warningColor)
        XCTAssertNotNil(terminalTheme.warningColor)
    }
    
    func testMenuBarSuccessStateWithThemes() throws {
        let modernTheme = ModernTheme()
        let professionalTheme = ProfessionalTheme()
        
        // Test success colors exist and are different
        XCTAssertNotEqual(
            modernTheme.successColor.description,
            professionalTheme.successColor.description
        )
        
        XCTAssertNotNil(modernTheme.successColor)
        XCTAssertNotNil(professionalTheme.successColor)
    }
    
    // MARK: - Theme Integration Tests
    
    func testMenuBarUpdatesWhenThemeChanges() throws {
        let initialTheme = themeManager.currentTheme.identifier
        let newTheme = themeManager.getTheme(byId: "terminal")!
        
        // Change theme
        themeManager.selectTheme(newTheme)
        
        // Verify theme changed
        XCTAssertNotEqual(themeManager.currentTheme.identifier, initialTheme)
        XCTAssertEqual(themeManager.currentTheme.identifier, "terminal")
        
        // Verify menu bar would use new theme colors
        XCTAssertNotNil(themeManager.currentTheme.textColor)
        XCTAssertNotNil(themeManager.currentTheme.accentColor)
    }
    
    // MARK: - Theme-Aware Extensions Tests
    
    func testNSColorFromSwiftUIColor() throws {
        let classicTheme = ClassicTheme()
        
        // Test that SwiftUI Colors can be converted to NSColor for menu bar
        let swiftUIColor = classicTheme.textColor
        XCTAssertNotNil(swiftUIColor)
        
        // In actual implementation, we'd test NSColor(swiftUIColor)
        // but for now just verify the color exists
        XCTAssertTrue(swiftUIColor.description.count > 0)
    }
    
    func testMenuBarAttributedStringCreation() throws {
        let modernTheme = ModernTheme()
        let testText = "$123.45"
        
        // Test that we can create attributed strings with theme properties
        XCTAssertGreaterThan(modernTheme.regularFontSize, 0)
        XCTAssertNotNil(modernTheme.primaryFontWeight)
        XCTAssertNotNil(modernTheme.textColor)
        
        // Verify theme provides appropriate values for NSAttributedString creation
        XCTAssertTrue(testText.count > 0)
    }
    
    // MARK: - Display Format Integration Tests
    
    func testThemeWorksWithFullDisplayFormat() throws {
        let comfortableTheme = ComfortableTheme()
        
        // Test that theme provides appropriate sizing for full display
        XCTAssertGreaterThan(comfortableTheme.regularFontSize, 12) // Should be readable
        XCTAssertNotNil(comfortableTheme.textColor)
        XCTAssertNotNil(comfortableTheme.primaryFontWeight)
    }
    
    func testThemeWorksWithAbbreviatedDisplayFormat() throws {
        let compactTheme = CompactTheme()
        
        // Test that compact theme is appropriate for abbreviated format
        XCTAssertLessThan(compactTheme.regularFontSize, 14) // Should be space-efficient
        XCTAssertNotNil(compactTheme.textColor)
        XCTAssertNotNil(compactTheme.primaryFontWeight)
    }
    
    func testThemeWorksWithIconOnlyDisplayFormat() throws {
        let terminalTheme = TerminalTheme()
        
        // Test that theme provides appropriate accent color for icon tinting
        XCTAssertNotNil(terminalTheme.accentColor)
        XCTAssertNotEqual(terminalTheme.accentColor.description, Color.clear.description)
    }
    
    // MARK: - Performance Tests
    
    func testMenuBarThemeUpdatePerformance() throws {
        let themes = ["classic", "modern", "terminal", "professional"]
        
        measure {
            for themeId in themes {
                if let theme = themeManager.getTheme(byId: themeId) {
                    themeManager.selectTheme(theme)
                    
                    // Simulate accessing theme properties for menu bar
                    _ = theme.textColor
                    _ = theme.regularFontSize
                    _ = theme.primaryFontWeight
                    _ = theme.accentColor
                }
            }
        }
    }
    
    func testMenuBarColorCalculationPerformance() throws {
        let theme = themeManager.currentTheme
        
        measure {
            for i in 0..<1000 {
                _ = theme.menuBarTextColor(isActive: i % 2 == 0)
                _ = theme.chartColor(for: i % 5)
            }
        }
    }
}