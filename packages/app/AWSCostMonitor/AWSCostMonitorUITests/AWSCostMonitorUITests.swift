//
//  AWSCostMonitorUITests.swift
//  AWSCostMonitorUITests
//
//  Created by Jackson Tomlinson on 8/1/25.
//

import XCTest

final class AWSCostMonitorUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app = nil
    }
    
    // MARK: - Helper Methods
    
    private func openMenuBarApp() {
        // Click on the menu bar icon (dollar sign)
        let menuBarExtras = app.menuBarItems
        let dollarIcon = menuBarExtras.firstMatch
        XCTAssertTrue(dollarIcon.waitForExistence(timeout: 5), "Menu bar icon should exist")
        dollarIcon.click()
    }
    
    private func closeMenuBarApp() {
        // Press Escape to close the menu
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
    }
    
    // MARK: - Onboarding Tests
    
    @MainActor
    func testOnboardingFlowAppears() throws {
        // Launch app for first time (clear UserDefaults)
        app.launchArguments.append("--reset-onboarding")
        app.launch()
        
        // Check if onboarding window appears
        let onboardingWindow = app.windows["Welcome to AWS Cost Monitor"]
        XCTAssertTrue(onboardingWindow.waitForExistence(timeout: 5), "Onboarding window should appear")
        
        // Check for key elements
        XCTAssertTrue(app.staticTexts["Welcome to AWS Cost Monitor"].exists, "Welcome title should exist")
        XCTAssertTrue(app.buttons["Grant Access to AWS Config"].exists, "Grant access button should exist")
        XCTAssertTrue(app.buttons["Skip for Now"].exists, "Skip button should exist")
    }
    
    @MainActor
    func testOnboardingGrantAccess() throws {
        app.launchArguments.append("--reset-onboarding")
        app.launch()
        
        let onboardingWindow = app.windows["Welcome to AWS Cost Monitor"]
        XCTAssertTrue(onboardingWindow.waitForExistence(timeout: 5), "Onboarding window should appear")
        
        // Click Grant Access button
        let grantButton = app.buttons["Grant Access to AWS Config"]
        XCTAssertTrue(grantButton.exists, "Grant button should exist")
        grantButton.click()
        
        // Wait for file dialog to appear (system dialog)
        sleep(1) // Give time for system dialog
        
        // Note: We can't interact with system file dialog in UI tests
        // Just verify the button was clickable
    }
    
    @MainActor
    func testOnboardingSkip() throws {
        app.launchArguments.append("--reset-onboarding")
        app.launch()
        
        let onboardingWindow = app.windows["Welcome to AWS Cost Monitor"]
        XCTAssertTrue(onboardingWindow.waitForExistence(timeout: 5), "Onboarding window should appear")
        
        // Click Skip button
        let skipButton = app.buttons["Skip for Now"]
        XCTAssertTrue(skipButton.exists, "Skip button should exist")
        skipButton.click()
        
        // Verify onboarding window closes
        XCTAssertFalse(onboardingWindow.exists, "Onboarding window should close")
    }
    
    // MARK: - Sandbox Access Tests
    
    @MainActor
    func testSandboxAccessPrompt() throws {
        app.launch()
        openMenuBarApp()
        
        // If sandbox access not granted, should show prompt
        if app.staticTexts["AWS Config Access Required"].exists {
            XCTAssertTrue(app.buttons["Grant Access"].exists, "Grant access button should exist in menu")
        }
        
        closeMenuBarApp()
    }
    
    // MARK: - Profile Switching Tests
    
    @MainActor
    func testProfileSwitching() throws {
        app.launch()
        openMenuBarApp()
        
        // Look for profile picker
        let profilePicker = app.popUpButtons.firstMatch
        if profilePicker.waitForExistence(timeout: 3) {
            // Click to open profile list
            profilePicker.click()
            
            // Check if profiles are listed
            let menuItems = app.menuItems
            XCTAssertTrue(menuItems.count > 0, "Should have at least one profile")
            
            // Select first profile if available
            if menuItems.count > 0 {
                menuItems.firstMatch.click()
            }
        }
        
        closeMenuBarApp()
    }
    
    @MainActor
    func testProfilePersistence() throws {
        app.launch()
        openMenuBarApp()
        
        // Select a profile
        let profilePicker = app.popUpButtons.firstMatch
        if profilePicker.waitForExistence(timeout: 3) {
            let initialValue = profilePicker.value as? String ?? ""
            
            // Change profile if multiple available
            profilePicker.click()
            let menuItems = app.menuItems
            if menuItems.count > 1 {
                menuItems.element(boundBy: 1).click()
                let newValue = profilePicker.value as? String ?? ""
                
                // Close and reopen menu
                closeMenuBarApp()
                sleep(1)
                openMenuBarApp()
                
                // Check if profile persisted
                let persistedValue = app.popUpButtons.firstMatch.value as? String ?? ""
                XCTAssertEqual(newValue, persistedValue, "Profile selection should persist")
            }
        }
        
        closeMenuBarApp()
    }
    
    // MARK: - Settings Window Tests
    
    @MainActor
    func testOpenSettingsWindow() throws {
        app.launch()
        openMenuBarApp()
        
        // Click Settings button
        let settingsButton = app.buttons["Settings..."]
        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.click()
            
            // Verify settings window opens
            let settingsWindow = app.windows["Settings"]
            XCTAssertTrue(settingsWindow.waitForExistence(timeout: 3), "Settings window should open")
            
            // Check for tabs
            XCTAssertTrue(app.buttons["General"].exists, "General tab should exist")
            XCTAssertTrue(app.buttons["Budgets"].exists, "Budgets tab should exist")
            XCTAssertTrue(app.buttons["API"].exists, "API tab should exist")
            XCTAssertTrue(app.buttons["Anomalies"].exists, "Anomalies tab should exist")
            
            // Close settings window
            settingsWindow.buttons[XCUIIdentifierCloseWindow].click()
        }
        
        closeMenuBarApp()
    }
    
    @MainActor
    func testSettingsGeneralTab() throws {
        app.launch()
        openMenuBarApp()
        
        let settingsButton = app.buttons["Settings..."]
        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.click()
            
            let settingsWindow = app.windows["Settings"]
            XCTAssertTrue(settingsWindow.waitForExistence(timeout: 3), "Settings window should open")
            
            // Click General tab
            app.buttons["General"].click()
            
            // Check for display format options
            XCTAssertTrue(app.staticTexts["Menu Bar Display"].exists, "Display format section should exist")
            XCTAssertTrue(app.radioButtons["Full ($123.45)"].exists, "Full format option should exist")
            XCTAssertTrue(app.radioButtons["Abbreviated ($123)"].exists, "Abbreviated format option should exist")
            XCTAssertTrue(app.radioButtons["Icon Only"].exists, "Icon only option should exist")
            
            // Check for refresh settings
            XCTAssertTrue(app.staticTexts["Refresh Settings"].exists, "Refresh settings section should exist")
            XCTAssertTrue(app.checkBoxes["Enable auto-refresh"].exists, "Auto-refresh toggle should exist")
            
            settingsWindow.buttons[XCUIIdentifierCloseWindow].click()
        }
        
        closeMenuBarApp()
    }
    
    @MainActor
    func testSettingsBudgetsTab() throws {
        app.launch()
        openMenuBarApp()
        
        let settingsButton = app.buttons["Settings..."]
        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.click()
            
            let settingsWindow = app.windows["Settings"]
            XCTAssertTrue(settingsWindow.waitForExistence(timeout: 3), "Settings window should open")
            
            // Click Budgets tab
            app.buttons["Budgets"].click()
            
            // Check for budget fields
            XCTAssertTrue(app.staticTexts["Monthly Budget"].exists, "Monthly budget label should exist")
            XCTAssertTrue(app.textFields.firstMatch.exists, "Budget input field should exist")
            XCTAssertTrue(app.staticTexts["Alert Threshold"].exists, "Alert threshold label should exist")
            
            settingsWindow.buttons[XCUIIdentifierCloseWindow].click()
        }
        
        closeMenuBarApp()
    }
    
    // MARK: - Help Window Tests
    
    @MainActor
    func testOpenHelpWindow() throws {
        app.launch()
        openMenuBarApp()
        
        // Click Help button
        let helpButton = app.buttons["Help"]
        if helpButton.waitForExistence(timeout: 3) {
            helpButton.click()
            
            // Verify help window opens
            let helpWindow = app.windows["AWS Cost Monitor Help"]
            XCTAssertTrue(helpWindow.waitForExistence(timeout: 3), "Help window should open")
            
            // Check for help content
            XCTAssertTrue(app.staticTexts["AWS Cost Monitor Help"].exists, "Help title should exist")
            XCTAssertTrue(app.staticTexts["Features"].exists, "Features section should exist")
            XCTAssertTrue(app.staticTexts["Keyboard Shortcuts"].exists, "Keyboard shortcuts section should exist")
            
            // Close help window
            helpWindow.buttons[XCUIIdentifierCloseWindow].click()
        }
        
        closeMenuBarApp()
    }
    
    @MainActor
    func testHelpKeyboardShortcuts() throws {
        app.launch()
        openMenuBarApp()
        
        let helpButton = app.buttons["Help"]
        if helpButton.waitForExistence(timeout: 3) {
            helpButton.click()
            
            let helpWindow = app.windows["AWS Cost Monitor Help"]
            XCTAssertTrue(helpWindow.waitForExistence(timeout: 3), "Help window should open")
            
            // Check for keyboard shortcut listings
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '⌘R'")).count > 0, "Refresh shortcut should be documented")
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '⌘,'")).count > 0, "Settings shortcut should be documented")
            
            helpWindow.buttons[XCUIIdentifierCloseWindow].click()
        }
        
        closeMenuBarApp()
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testMenuOpenPerformance() throws {
        app.launch()
        
        measure {
            openMenuBarApp()
            closeMenuBarApp()
        }
    }
}