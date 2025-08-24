//
//  ThemeTests.swift
//  AWSCostMonitorTests
//
//  Test suite for Theme system infrastructure
//

import XCTest
@testable import AWSCostMonitor
import SwiftUI

final class ThemeTests: XCTestCase {
    
    var themeManager: ThemeManager!
    
    override func setUpWithError() throws {
        themeManager = ThemeManager()
        // Reset to clean state for each test
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
        UserDefaults.standard.removeObject(forKey: "syncWithSystemAppearance")
    }
    
    override func tearDownWithError() throws {
        themeManager = nil
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
        UserDefaults.standard.removeObject(forKey: "syncWithSystemAppearance")
    }
    
    // MARK: - Theme Protocol Tests
    
    func testThemeProtocolProperties() throws {
        let classicTheme = ClassicTheme()
        
        // Test color properties exist
        XCTAssertNotNil(classicTheme.primaryColor)
        XCTAssertNotNil(classicTheme.secondaryColor)
        XCTAssertNotNil(classicTheme.accentColor)
        XCTAssertNotNil(classicTheme.backgroundColor)
        XCTAssertNotNil(classicTheme.textColor)
        
        // Test text formatting properties exist
        XCTAssertGreaterThan(classicTheme.smallFontSize, 0)
        XCTAssertGreaterThan(classicTheme.regularFontSize, 0)
        XCTAssertGreaterThan(classicTheme.largeFontSize, 0)
        XCTAssertNotNil(classicTheme.primaryFontWeight)
        XCTAssertNotNil(classicTheme.secondaryFontWeight)
        
        // Test layout density properties exist
        XCTAssertGreaterThan(classicTheme.paddingScale, 0)
        XCTAssertGreaterThan(classicTheme.spacingMultiplier, 0)
        
        // Test metadata
        XCTAssertFalse(classicTheme.name.isEmpty)
        XCTAssertFalse(classicTheme.description.isEmpty)
        XCTAssertFalse(classicTheme.identifier.isEmpty)
    }
    
    func testAllPredefinedThemesExist() throws {
        let expectedThemes: [String] = [
            "classic",
            "modern", 
            "highContrast",
            "compact",
            "comfortable",
            "terminal",
            "professional"
        ]
        
        for themeId in expectedThemes {
            let theme = themeManager.getTheme(byId: themeId)
            XCTAssertNotNil(theme, "Theme with ID '\(themeId)' should exist")
        }
    }
    
    // MARK: - ThemeManager Tests
    
    func testThemeManagerInitialization() throws {
        XCTAssertNotNil(themeManager.currentTheme)
        XCTAssertEqual(themeManager.currentTheme.identifier, "classic", "Should default to classic theme")
        XCTAssertFalse(themeManager.syncWithSystemAppearance, "Should default to false")
    }
    
    func testThemeSelection() throws {
        let modernTheme = themeManager.getTheme(byId: "modern")!
        
        themeManager.selectTheme(modernTheme)
        
        XCTAssertEqual(themeManager.currentTheme.identifier, "modern")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "selectedTheme"), "modern")
    }
    
    func testThemePersistence() throws {
        // Set a theme
        let terminalTheme = themeManager.getTheme(byId: "terminal")!
        themeManager.selectTheme(terminalTheme)
        
        // Create new manager instance (simulates app restart)
        let newThemeManager = ThemeManager()
        
        XCTAssertEqual(newThemeManager.currentTheme.identifier, "terminal")
    }
    
    func testSystemAppearanceSyncToggle() throws {
        XCTAssertFalse(themeManager.syncWithSystemAppearance)
        
        themeManager.setSyncWithSystemAppearance(true)
        
        XCTAssertTrue(themeManager.syncWithSystemAppearance)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "syncWithSystemAppearance"))
    }
    
    func testSystemAppearanceSyncPersistence() throws {
        themeManager.setSyncWithSystemAppearance(true)
        
        // Create new manager instance
        let newThemeManager = ThemeManager()
        
        XCTAssertTrue(newThemeManager.syncWithSystemAppearance)
    }
    
    // MARK: - Theme Variants Tests
    
    func testThemeColorVariants() throws {
        let classicTheme = ClassicTheme()
        let modernTheme = ModernTheme()
        
        // Colors should be different between themes
        XCTAssertNotEqual(classicTheme.accentColor.description, modernTheme.accentColor.description)
    }
    
    func testHighContrastTheme() throws {
        let highContrastTheme = themeManager.getTheme(byId: "highContrast")
        XCTAssertNotNil(highContrastTheme)
        XCTAssertEqual(highContrastTheme?.identifier, "highContrast")
        
        // High contrast theme should have larger text
        let classicTheme = ClassicTheme()
        XCTAssertGreaterThan(highContrastTheme!.regularFontSize, classicTheme.regularFontSize)
        
        // Should have higher contrast design characteristics (bolder text)
        XCTAssertTrue(highContrastTheme!.primaryFontWeight == Font.Weight.semibold)
        XCTAssertTrue(classicTheme.primaryFontWeight == Font.Weight.regular)
    }
    
    func testCompactTheme() throws {
        let compactTheme = themeManager.getTheme(byId: "compact")
        XCTAssertNotNil(compactTheme)
        XCTAssertEqual(compactTheme?.identifier, "compact")
        
        let classicTheme = ClassicTheme()
        
        // Compact theme should have smaller padding and spacing
        XCTAssertLessThan(compactTheme!.paddingScale, classicTheme.paddingScale)
        XCTAssertLessThan(compactTheme!.spacingMultiplier, classicTheme.spacingMultiplier)
    }
    
    func testComfortableTheme() throws {
        let comfortableTheme = themeManager.getTheme(byId: "comfortable")
        XCTAssertNotNil(comfortableTheme)
        XCTAssertEqual(comfortableTheme?.identifier, "comfortable")
        
        let classicTheme = ClassicTheme()
        
        // Comfortable theme should have larger padding and spacing
        XCTAssertGreaterThan(comfortableTheme!.paddingScale, classicTheme.paddingScale)
        XCTAssertGreaterThan(comfortableTheme!.spacingMultiplier, classicTheme.spacingMultiplier)
    }
    
    // MARK: - Performance Tests
    
    func testThemeManagerPerformance() throws {
        measure {
            for _ in 0..<1000 {
                _ = themeManager.currentTheme.primaryColor
            }
        }
    }
    
    func testThemeSwitchingPerformance() throws {
        let themes = ["classic", "modern", "terminal", "professional"]
        
        measure {
            for themeId in themes {
                if let theme = themeManager.getTheme(byId: themeId) {
                    themeManager.selectTheme(theme)
                }
            }
        }
    }
}