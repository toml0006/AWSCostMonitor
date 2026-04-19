//
//  AWSCostMonitorApp.swift
//  AWSCostMonitor
//
//  Main application entry point
//

import SwiftUI
import AppKit
import OSLog
import UserNotifications
import AppIntents
import Darwin

// MARK: - Main App Entry Point

@main
struct AWSCostMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var awsManager = AWSManager.shared
    @StateObject private var configAccessManager = AWSConfigAccessManager.shared
    
    init() {
        // MARK: - Telemetry Opt-Out Configuration
        // Disable AWS SDK telemetry collection for privacy - set this VERY early
        setenv("AWS_SDK_TELEMETRY_ENABLED", "false", 1)
        setenv("AWS_SDK_METRICS_ENABLED", "false", 1)
        setenv("AWS_SDK_TRACING_ENABLED", "false", 1)
        setenv("AWS_TELEMETRY_ENABLED", "false", 1)
        
        // Log telemetry opt-out for transparency
        let logger = Logger(subsystem: "com.middleout.AWSCostMonitor", category: "App")
        logger.info("AWS SDK telemetry collection disabled for privacy")
        
        // Set up AWS SDK environment variables VERY early if we're sandboxed
        if ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil {
            // Get the real home directory by looking up the user record
            let realHome: String
            if let user = getpwuid(getuid()),
               let homeDir = user.pointee.pw_dir {
                realHome = String(cString: homeDir)
            } else {
                // Fallback: try to extract real home from sandbox path
                let sandboxHome = NSString("~").expandingTildeInPath
                if sandboxHome.contains("/Library/Containers/") {
                    let components = sandboxHome.components(separatedBy: "/")
                    if let userIndex = components.firstIndex(of: "Users"),
                       userIndex + 1 < components.count {
                        realHome = "/Users/\(components[userIndex + 1])"
                    } else {
                        realHome = "/Users/\(NSUserName())"
                    }
                } else {
                    realHome = sandboxHome
                }
            }
            
            let configPath = "\(realHome)/.aws/config"
            let credentialsPath = "\(realHome)/.aws/credentials"
            
            setenv("AWS_CONFIG_FILE", configPath, 1)
            setenv("AWS_SHARED_CREDENTIALS_FILE", credentialsPath, 1)
            
            print("AWSCostMonitor: Set AWS_CONFIG_FILE to: \(configPath)")
            print("AWSCostMonitor: Set AWS_SHARED_CREDENTIALS_FILE to: \(credentialsPath)")
        }
        
        // Configure AppIntents shortcuts
        if #available(macOS 13.0, *) {
            AWSCostShortcuts.updateAppShortcutParameters()
        }
        
        // Check if onboarding is needed
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "HasCompletedOnboarding")
        let manager = awsManager
        
        if !hasCompletedOnboarding {
            // Show onboarding after a short delay to ensure app is fully initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showOnboardingWindow(awsManager: manager)
            }
        } else {
            // Request notification permissions if not determined (for existing users)
            Task {
                let notificationCenter = UNUserNotificationCenter.current()
                let settings = await notificationCenter.notificationSettings()
                if settings.authorizationStatus == .notDetermined {
                    do {
                        _ = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
                    } catch {
                        print("Notification permission request failed: \(error)")
                        // Don't try again if the app is blocked at system level
                    }
                }
            }
        }
    }
    
    var body: some Scene {
        // Note: We use WindowGroup with a hidden window to enable keyboard shortcuts
        // and menu commands. The Settings window is shown programmatically when needed.
        // This prevents any window from appearing at launch.

        WindowGroup {
            // Empty view - this window will never be shown
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 0, height: 0)
        .commands {
            // Remove the default menu items we don't need
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .pasteboard) { }
            CommandGroup(replacing: .undoRedo) { }

            // Add custom keyboard shortcuts
            CommandGroup(after: .appInfo) {
                Button("Refresh Cost Data") {
                    Task {
                        await awsManager.fetchCostForSelectedProfile(force: true)
                    }
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Show Calendar View") {
                    CalendarWindowController.showCalendarWindow(awsManager: awsManager)
                }
                .keyboardShortcut("k", modifiers: .command)

                Divider()
            }

            // Add profile switching shortcuts (1-9)
            CommandGroup(after: .toolbar) {
                ForEach(1...9, id: \.self) { index in
                    Button("Switch to Profile \(index)") {
                        if index <= awsManager.profiles.count {
                            let profile = awsManager.profiles[index - 1]
                            awsManager.selectedProfile = profile
                        }
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index)")), modifiers: [])
                }
            }
        }
    }
    
}