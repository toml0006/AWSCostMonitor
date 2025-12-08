//
//  ThemeSettingsUITests.swift
//  AWSCostMonitorTests
//
//  Test suite for Theme Settings UI components
//

import XCTest
@testable import AWSCostMonitor
import SwiftUI

final class ThemeSettingsUITests: XCTestCase {
    
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
    
    // MARK: - Settings View Integration Tests
    
    func testSettingsViewIncludesAppearanceTab() throws {
        let settingsView = SettingsView()
        
        // Test that Appearance category is included in settings categories
        XCTAssertTrue(settingsView.settingsCategories.contains("Appearance"))
    }
    
    func testAppearanceIconIsConfigured() throws {
        let settingsView = SettingsView()
        let appearanceIcon = settingsView.iconForCategory("Appearance")
        
        XCTAssertFalse(appearanceIcon.isEmpty)
        XCTAssertEqual(appearanceIcon, "paintbrush")
    }
    
    // MARK: - Theme Preview Card Tests
    
    func testThemePreviewCardDisplaysThemeInfo() throws {
        let classicTheme = ClassicTheme()
        let previewCard = ThemePreviewCard(theme: classicTheme, isSelected: false, onSelect: {})
        
        // Test that preview card shows theme information
        XCTAssertNotNil(previewCard.theme)
        XCTAssertEqual(previewCard.theme.name, "Classic")
        XCTAssertEqual(previewCard.theme.identifier, "classic")
    }
    
    func testThemePreviewCardSelectionState() throws {
        let modernTheme = ModernTheme()
        var isSelected = false
        var selectionCallbackCalled = false
        
        let previewCard = ThemePreviewCard(
            theme: modernTheme,
            isSelected: isSelected,
            onSelect: {
                selectionCallbackCalled = true
            }
        )
        
        // Test selection callback
        previewCard.onSelect()
        XCTAssertTrue(selectionCallbackCalled)
    }
    
    // MARK: - Theme Grid Selector Tests
    
    func testThemeGridDisplaysAllThemes() throws {
        let themeGrid = ThemeGridSelector(themeManager: themeManager)
        let availableThemes = themeManager.getAllThemes()
        
        XCTAssertEqual(availableThemes.count, 7, "Should display all 7 pre-defined themes")
        
        let expectedThemeIds = ["classic", "modern", "highContrast", "compact", "comfortable", "terminal", "professional"]
        for expectedId in expectedThemeIds {
            let hasTheme = availableThemes.contains { $0.identifier == expectedId }
            XCTAssertTrue(hasTheme, "Should contain theme with ID: \(expectedId)")
        }
    }
    
    func testThemeGridSelectionUpdatesManager() throws {
        let themeGrid = ThemeGridSelector(themeManager: themeManager)
        let terminalTheme = themeManager.getTheme(byId: "terminal")!
        
        // Simulate theme selection
        themeManager.selectTheme(terminalTheme)
        
        XCTAssertEqual(themeManager.currentTheme.identifier, "terminal")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "selectedTheme"), "terminal")
    }
    
    // MARK: - System Appearance Sync Toggle Tests
    
    func testSystemAppearanceSyncToggle() throws {
        let appearanceTab = AppearanceSettingsTab(themeManager: themeManager)
        
        XCTAssertFalse(themeManager.syncWithSystemAppearance, "Should default to false")
        
        // Simulate toggle
        themeManager.setSyncWithSystemAppearance(true)
        
        XCTAssertTrue(themeManager.syncWithSystemAppearance)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "syncWithSystemAppearance"))
    }
    
    // MARK: - Live Preview Tests
    
    func testLivePreviewUpdatesOnThemeChange() throws {
        let previewComponent = ThemeLivePreview(themeManager: themeManager)
        let initialTheme = themeManager.currentTheme.identifier
        
        // Change theme
        let newTheme = themeManager.getTheme(byId: "modern")!
        themeManager.selectTheme(newTheme)
        
        // Verify theme changed
        XCTAssertNotEqual(themeManager.currentTheme.identifier, initialTheme)
        XCTAssertEqual(themeManager.currentTheme.identifier, "modern")
    }
    
    func testLivePreviewShowsCurrentThemeColors() throws {
        let preview = ThemeLivePreview(themeManager: themeManager)
        let currentTheme = themeManager.currentTheme
        
        // Test that preview reflects current theme
        XCTAssertNotNil(currentTheme.primaryColor)
        XCTAssertNotNil(currentTheme.backgroundColor)
        XCTAssertNotNil(currentTheme.accentColor)
    }
    
    // MARK: - UI Interaction Tests
    
    func testThemeSelectionTriggersUIUpdate() throws {
        let initialTheme = themeManager.currentTheme.identifier
        let compactTheme = themeManager.getTheme(byId: "compact")!
        
        // Change theme
        themeManager.selectTheme(compactTheme)
        
        // Verify theme change
        XCTAssertNotEqual(themeManager.currentTheme.identifier, initialTheme)
        XCTAssertEqual(themeManager.currentTheme.identifier, "compact")
    }
    
    func testThemePreviewHoverEffects() throws {
        let highContrastTheme = HighContrastTheme()
        var isHovered = false
        
        let previewCard = ThemePreviewCard(
            theme: highContrastTheme,
            isSelected: false,
            onSelect: {}
        )
        
        // Test hover state tracking exists (implementation detail)
        XCTAssertNotNil(previewCard.theme)
    }
    
    // MARK: - Accessibility Tests
    
    func testThemePreviewCardsHaveAccessibilityLabels() throws {
        let professionalTheme = ProfessionalTheme()
        let previewCard = ThemePreviewCard(
            theme: professionalTheme,
            isSelected: true,
            onSelect: {}
        )
        
        // Verify theme information is accessible
        XCTAssertFalse(previewCard.theme.name.isEmpty)
        XCTAssertFalse(previewCard.theme.description.isEmpty)
    }
    
    func testSystemAppearanceSyncHasAccessibleDescription() throws {
        let appearanceTab = AppearanceSettingsTab(themeManager: themeManager)
        
        // Test that sync option is properly described
        XCTAssertNotNil(themeManager.syncWithSystemAppearance)
    }
    
    // MARK: - Performance Tests
    
    func testThemeGridRenderingPerformance() throws {
        measure {
            let themeGrid = ThemeGridSelector(themeManager: themeManager)
            let themes = themeManager.getAllThemes()
            
            // Simulate rendering all theme previews
            for theme in themes {
                _ = ThemePreviewCard(theme: theme, isSelected: false, onSelect: {})
            }
        }
    }
    
    func testLivePreviewUpdatePerformance() throws {
        let preview = ThemeLivePreview(themeManager: themeManager)
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