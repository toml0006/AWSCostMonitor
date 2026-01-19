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
    @AppStorage("ShowCurrencySymbol") private var showCurrencySymbol: Bool = true
    @AppStorage("DecimalPlaces") private var decimalPlaces: Int = 2
    @AppStorage("UseThousandsSeparator") private var useThousandsSeparator: Bool = true
    @AppStorage("ShowMenuBarColors") private var showMenuBarColors: Bool = true
    
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
    
    var menuBarTitle: String {
        // Handle various states with appropriate messages
        if awsManager.isLoading {
            // Show loading state (optionally with profile name)
            if let profile = awsManager.selectedProfile {
                return "Loading \(profile.name)..."
            }
            return "Loading..."
        } else if awsManager.isRateLimited {
            // Show rate limited indicator
            return "Rate Limited"
        } else if awsManager.errorMessage != nil {
            // Show error indicator
            return "Error"
        } else if let cost = awsManager.costData.first {
            // Normal cost display
            let formattedCost = CostDisplayFormatter.format(
                amount: cost.amount,
                currency: cost.currency,
                format: awsManager.displayFormat,
                showCurrencySymbol: showCurrencySymbol,
                decimalPlaces: decimalPlaces,
                useThousandsSeparator: useThousandsSeparator
            )
            return formattedCost
        } else if awsManager.profiles.isEmpty {
            // No profiles configured
            return "No Profiles"
        } else {
            // No data yet
            return "No Data"
        }
    }
    
    var menuBarIcon: String {
        // Priority order for status indicators:
        // 1. Error states (highest priority)
        // 2. Loading state
        // 3. Rate limited state
        // 4. Normal cost display with trend
        
        if awsManager.errorMessage != nil {
            return "exclamationmark.triangle.fill"
        } else if awsManager.isLoading {
            return "arrow.clockwise.circle.fill"
        } else if awsManager.isRateLimited {
            return "clock.badge.exclamationmark.fill"
        } else if awsManager.displayFormat == .iconOnly {
            // In icon-only mode, show dollar sign or trend
            switch awsManager.costTrend {
            case .up:
                return "arrow.up.circle.fill"
            case .down:
                return "arrow.down.circle.fill"
            case .stable:
                return "dollarsign.circle.fill"
            }
        } else if awsManager.costData.isEmpty {
            return "dollarsign.circle.fill"
        } else {
            // Show trend icon when we have cost data and not in icon-only mode
            switch awsManager.costTrend {
            case .up:
                return "arrow.up.circle.fill"
            case .down:
                return "arrow.down.circle.fill"
            case .stable:
                return "minus.circle.fill" // Show minus for stable
            }
        }
    }
    
    var menuBarColor: Color? {
        // Check if user has color option enabled
        guard showMenuBarColors else {
            return nil
        }
        
        // Priority order for color indicators:
        // 1. Error states (yellow/orange)
        // 2. Rate limited (orange)
        // 3. Loading (subtle animation via nil)
        // 4. Budget status (red if over)
        // 5. Cost trend (green/red based on comparison)
        
        if awsManager.errorMessage != nil {
            return .orange
        }
        
        if awsManager.isRateLimited {
            return .orange
        }
        
        if awsManager.isLoading {
            return nil // Use default color while loading
        }
        
        guard let profile = awsManager.selectedProfile,
              let cost = awsManager.costData.first else {
            return nil
        }
        
        let budget = awsManager.getBudget(for: profile.name)
        let status = awsManager.calculateBudgetStatus(cost: cost.amount, budget: budget)
        
        // Check budget status
        if status.isOverBudget {
            return .red
        } else if status.percentage > 0.9 {
            // Over 90% of budget - warning
            return .orange
        } else if status.percentage > 0.75 {
            // Over 75% of budget - caution
            return .yellow
        }
        
        // Then check trend - simple green/red based on last month comparison
        switch awsManager.costTrend {
        case .up:
            // Only show red if increase is significant (>10%)
            if let lastMonth = awsManager.lastMonthData[profile.name],
               lastMonth.amount > 0 {
                let percentChange = ((cost.amount - lastMonth.amount) / lastMonth.amount) * 100
                if percentChange > 10 {
                    return .red
                }
            }
            return nil
        case .down:
            return .green
        case .stable:
            return nil // Default color (white/black based on system theme)
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
    
    // Helper properties
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private func timeSince(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        if minutes < 1 {
            return "just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else {
            let hours = minutes / 60
            return "\(hours)h ago"
        }
    }
}