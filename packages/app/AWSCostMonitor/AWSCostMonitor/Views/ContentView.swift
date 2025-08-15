//
//  ContentView.swift
//  AWSCostMonitor
//
//  Main settings window content view
//

import SwiftUI
import Charts

struct ContentView: View {
    @EnvironmentObject var awsManager: AWSManager
    @State private var hoveredItem: String? = nil
    @State private var pressedItem: String? = nil
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("AWS MTD Spend")
                .font(.headline)
                .padding(.bottom, 5)

            // Profile Selection Picker (without label)
            Picker("", selection: $awsManager.selectedProfile) {
                if awsManager.profiles.isEmpty {
                    Text("No profiles").tag(nil as AWSProfile?)
                }
                ForEach(awsManager.realProfiles, id: \.self) { profile in
                    Text(profile.name)
                        .tag(Optional(profile))
                }
                if !awsManager.realProfiles.isEmpty && !awsManager.demoProfiles.isEmpty {
                    Divider()
                }
                ForEach(awsManager.demoProfiles, id: \.self) { profile in
                    Text("\(profile.name) (Demo)")
                        .tag(Optional(profile))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .onChange(of: awsManager.selectedProfile) { _, newValue in
                if let newProfile = newValue {
                    // Save the new selection to UserDefaults and fetch cost
                    awsManager.saveSelectedProfile(profile: newProfile)
                    Task { await awsManager.fetchCostForSelectedProfile() }
                }
            }
            
            Divider()
            
            // Display error message if rate limited
            if let errorMessage = awsManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            // Display cost for the selected profile
            if awsManager.isLoading {
                HStack {
                    ProgressView()
                    Text("Fetching costs...")
                }
            } else if awsManager.profiles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No AWS profiles found")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    Text("Configure AWS profiles in ~/.aws/config to get started.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if awsManager.selectedProfile == nil {
                Text("Select an AWS profile above to view costs.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if let cost = awsManager.costData.first {
                VStack(spacing: 12) {
                    // Month comparison section
                    VStack(spacing: 8) {
                        // Current month (MTD)
                        HStack {
                            Text("Current Month (MTD)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(CostDisplayFormatter.format(
                                amount: cost.amount,
                                currency: cost.currency,
                                format: .full,
                                showCurrencySymbol: UserDefaults.standard.bool(forKey: "ShowCurrencySymbol"),
                                decimalPlaces: UserDefaults.standard.integer(forKey: "DecimalPlaces") == 0 ? 2 : UserDefaults.standard.integer(forKey: "DecimalPlaces"),
                                useThousandsSeparator: UserDefaults.standard.bool(forKey: "UseThousandsSeparator")
                            ))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        }
                        
                        // Last month
                        if let lastMonthData = awsManager.lastMonthData[cost.profileName] {
                            HStack {
                                Text("Last Month")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(CostDisplayFormatter.format(
                                    amount: lastMonthData.amount,
                                    currency: lastMonthData.currency,
                                    format: .full,
                                    showCurrencySymbol: UserDefaults.standard.bool(forKey: "ShowCurrencySymbol"),
                                    decimalPlaces: UserDefaults.standard.integer(forKey: "DecimalPlaces") == 0 ? 2 : UserDefaults.standard.integer(forKey: "DecimalPlaces"),
                                    useThousandsSeparator: UserDefaults.standard.bool(forKey: "UseThousandsSeparator")
                                ))
                                .foregroundColor(.secondary)
                                
                                // Month-over-month trend indicator
                                if awsManager.costTrend != .stable {
                                    Image(systemName: awsManager.costTrend.icon)
                                        .foregroundColor(awsManager.costTrend.color)
                                        .font(.caption)
                                        .help("Month-over-month: \(awsManager.costTrend.description)")
                                }
                            }
                            
                            // Show cached date indicator
                            if let fetchDate = awsManager.lastMonthDataFetchDate[cost.profileName] {
                                HStack {
                                    Spacer()
                                    Text("Cached: \(fetchDate, style: .relative)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Button(action: {
                                        Task {
                                            await awsManager.fetchLastMonthData(for: cost.profileName, force: true)
                                        }
                                    }) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.caption2)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Force refresh last month data")
                                }
                            }
                        } else if awsManager.lastMonthDataLoading[cost.profileName] == true {
                            HStack {
                                Text("Last Month")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack {
                                Text("Last Month")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    Task {
                                        await awsManager.fetchLastMonthData(for: cost.profileName, force: true)
                                    }
                                }) {
                                    Text("Load Data")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.plain)
                                .help("Fetch last month data")
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Spending forecast
                    if let projected = awsManager.projectedMonthlyTotal {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text("Projected:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(CostDisplayFormatter.format(
                                amount: projected,
                                currency: cost.currency,
                                format: .full,
                                showCurrencySymbol: UserDefaults.standard.bool(forKey: "ShowCurrencySymbol"),
                                decimalPlaces: 0, // No decimals for projection
                                useThousandsSeparator: UserDefaults.standard.bool(forKey: "UseThousandsSeparator")
                            ))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Budget status indicator
                    if let profile = awsManager.selectedProfile {
                        let budget = awsManager.getBudget(for: profile.name)
                        let status = awsManager.calculateBudgetStatus(cost: cost.amount, budget: budget)
                        
                        HStack {
                            ProgressView(value: status.percentage, total: 1.0)
                                .progressViewStyle(.linear)
                                .tint(status.isOverBudget ? .red : (status.isNearThreshold ? .orange : .green))
                            
                            Text("\(Int(status.percentage * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 40)
                        }
                        
                        if status.isOverBudget {
                            Label("Over budget!", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if status.isNearThreshold {
                            Label("Approaching limit", systemImage: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    // Service breakdown section - moved below month comparison
                    if awsManager.costData.first != nil {
                        Divider()
                        
                        DisclosureGroup("Cost Breakdown by Service") {
                            if awsManager.serviceCosts.isEmpty {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.secondary)
                                    Text("No service data available")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            } else {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(awsManager.serviceCosts.prefix(8)) { service in
                                        VStack(alignment: .leading, spacing: 3) {
                                            // Service name and cost
                                            HStack {
                                                Text(service.serviceName)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                                Spacer()
                                                Text(CostDisplayFormatter.format(
                                                    amount: service.amount,
                                                    currency: service.currency,
                                                    format: .full,
                                                    showCurrencySymbol: true,
                                                    decimalPlaces: 2,
                                                    useThousandsSeparator: true
                                                ))
                                                .font(.caption)
                                                .monospacedDigit()
                                            }
                                            
                                            // 7-day histogram for this service
                                            if let profileName = awsManager.selectedProfile?.name,
                                               let dailyServiceCosts = awsManager.dailyServiceCostsByProfile[profileName],
                                               !dailyServiceCosts.isEmpty {
                                                ServiceHistogramView(
                                                    dailyServiceCosts: dailyServiceCosts,
                                                    serviceName: service.serviceName
                                                )
                                            }
                                        }
                                    }
                                    
                                    if awsManager.serviceCosts.count > 8 {
                                        Text("... and \(awsManager.serviceCosts.count - 8) more services")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            } else {
                Text("No cost data available. Select a profile and refresh.")
                    .foregroundColor(.secondary)
            }

            // Show anomalies if any detected
            if !awsManager.anomalies.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Spending Alerts", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    ForEach(awsManager.anomalies) { anomaly in
                        HStack(spacing: 4) {
                            Image(systemName: anomaly.severity.icon)
                                .foregroundColor(anomaly.severity.color)
                                .font(.caption)
                            Text(anomaly.message)
                                .font(.caption)
                                .foregroundColor(anomaly.severity.color)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Show next refresh time if auto-refresh is active
            if let nextRefresh = awsManager.nextRefreshTime {
                Divider()
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("Next refresh:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(nextRefresh, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            // Enhanced: Show cache status
            if let profile = awsManager.selectedProfile {
                Divider()
                HStack {
                    Image(systemName: "externaldrive.fill")
                        .foregroundColor(.secondary)
                    Text("Cache:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    if let cacheEntry = awsManager.costCache[profile.name] {
                        let age = Date().timeIntervalSince(cacheEntry.fetchDate)
                        let budget = awsManager.getBudget(for: profile.name)
                        let isValid = cacheEntry.isValidForBudget(budget)
                        
                        HStack(spacing: 4) {
                            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isValid ? .green : .orange)
                                .font(.caption2)
                            
                            Text("\(Int(age / 60))m ago")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(isValid ? .secondary : .orange)
                        }
                    } else {
                        Text("No cache")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
            
            Divider()
            
            // Enhanced refresh button with cache bypass option
            MenuButton(
                action: {
                    Task {
                        await awsManager.fetchCostForSelectedProfile()
                    }
                },
                label: "Refresh",
                systemImage: "arrow.clockwise",
                shortcut: "⌘R",
                hoveredItem: $hoveredItem,
                pressedItem: $pressedItem,
                itemId: "refresh"
            )
            .keyboardShortcut("r", modifiers: .command)
            
            // Cache bypass option if cache exists
            if let profile = awsManager.selectedProfile,
               awsManager.costCache[profile.name] != nil {
                MenuButton(
                    action: {
                        Task {
                            await awsManager.fetchCostForSelectedProfile(force: true)
                        }
                    },
                    label: "Force Refresh (Bypass Cache)",
                    systemImage: "arrow.clockwise.circle.fill",
                    shortcut: "⌘⇧R",
                    hoveredItem: $hoveredItem,
                    pressedItem: $pressedItem,
                    itemId: "force-refresh"
                )
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
            
            // Show rate limit warning and override option
            if awsManager.isRateLimited {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("Rate limited (\(awsManager.secondsUntilNextAllowedCall())s)")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            pressedItem = "override"
                        }
                        Task {
                            await awsManager.forceRefresh()
                            withAnimation(.easeInOut(duration: 0.1)) {
                                pressedItem = nil
                            }
                        }
                    }) {
                        Text("Override")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(pressedItem == "override" ? Color.orange.opacity(0.3) :
                                          (hoveredItem == "override" ? Color.orange.opacity(0.2) : Color.clear))
                                    .animation(.easeInOut(duration: 0.1), value: hoveredItem)
                                    .animation(.easeInOut(duration: 0.1), value: pressedItem)
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.orange)
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            hoveredItem = isHovered ? "override" : nil
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // API Request Counter & Cost Tracking
            if let profile = awsManager.selectedProfile {
                Divider()
                HStack {
                    Image(systemName: "network")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("API Requests (24h):")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(awsManager.getRequestCount(for: profile.name, inLast: 24 * 60 * 60))")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
                
                // API Cost Estimate
                let monthlyRequests = awsManager.getRequestCount(for: profile.name, inLast: 30 * 24 * 60 * 60)
                let estimatedMonthlyCost = Double(monthlyRequests) * 0.01 // $0.01 per request
                
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("Est. API Cost (30d):")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("$\(estimatedMonthlyCost, specifier: "%.2f")")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(estimatedMonthlyCost > 1.0 ? .orange : .secondary)
                }
                .padding(.vertical, 2)
            } else {
                // No cost data available - show help message
                VStack(alignment: .leading, spacing: 8) {
                    Text("No cost data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Click the refresh button or check your AWS permissions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Manual refresh button
                    Button(action: {
                        if awsManager.selectedProfile != nil {
                            Task { await awsManager.fetchCostForSelectedProfile() }
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Cost Data")
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.blue)
                    .disabled(awsManager.isLoading)
                }
            }
            
            Divider()
            
            // AWS Console Link
            if let profile = awsManager.selectedProfile {
                MenuButton(
                    action: {
                        let region = profile.region ?? "us-east-1"
                        let urlString = "https://\(region).console.aws.amazon.com/billing/home"
                        if let url = URL(string: urlString) {
                            NSWorkspace.shared.open(url)
                            awsManager.log(.info, category: "UI", "Opened AWS Console for profile \(profile.name)")
                        }
                    },
                    label: "Open AWS Console",
                    systemImage: "globe",
                    shortcut: nil,
                    hoveredItem: $hoveredItem,
                    pressedItem: $pressedItem,
                    itemId: "console"
                )
            }
            
            MenuButton(
                action: {
                    showHelpWindow()
                    awsManager.log(.info, category: "UI", "Opened help window")
                },
                label: "Help",
                systemImage: "questionmark.circle",
                shortcut: "⌘?",
                hoveredItem: $hoveredItem,
                pressedItem: $pressedItem,
                itemId: "help"
            )
            .keyboardShortcut("?", modifiers: .command)
            
            MenuButton(
                action: {
                    showMultiProfileDashboard(awsManager: awsManager)
                    awsManager.log(.info, category: "UI", "Opened multi-profile dashboard")
                },
                label: "Multi-Profile Dashboard",
                systemImage: "rectangle.3.group",
                shortcut: "⌘D",
                hoveredItem: $hoveredItem,
                pressedItem: $pressedItem,
                itemId: "dashboard"
            )
            .keyboardShortcut("d", modifiers: .command)
            
            MenuButton(
                action: {
                    showExportWindow(awsManager: awsManager)
                    awsManager.log(.info, category: "UI", "Opened export window")
                },
                label: "Export Data…",
                systemImage: "square.and.arrow.up",
                shortcut: "⌘E",
                hoveredItem: $hoveredItem,
                pressedItem: $pressedItem,
                itemId: "export"
            )
            .keyboardShortcut("e", modifiers: .command)
            
            MenuButton(
                action: {
                    showSettingsWindowForApp(awsManager: awsManager)
                    awsManager.log(.info, category: "UI", "Opened settings window")
                },
                label: "Settings…",
                systemImage: "gear",
                shortcut: "⌘,",
                hoveredItem: $hoveredItem,
                pressedItem: $pressedItem,
                itemId: "settings"
            )
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()
            
            // Debug options only in DEBUG builds
            #if DEBUG
                MenuButton(
                    action: {
                        UserDefaults.standard.removeObject(forKey: "HasCompletedOnboarding")
                        showOnboardingWindow(awsManager: awsManager)
                    },
                    label: "Reset Onboarding",
                    systemImage: "arrow.counterclockwise",
                    shortcut: nil,
                    hoveredItem: $hoveredItem,
                    pressedItem: $pressedItem,
                    itemId: "resetOnboarding"
                )
                
                Divider()
                
                // Debug Timer Section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Debug Timer Test")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .bold()
                    
                    Text(awsManager.debugTimerMessage)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.vertical, 2)
                    
                    if let lastUpdate = awsManager.debugLastUpdate {
                        Text("Last update: \(lastUpdate, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Button(action: {
                            awsManager.startDebugTimer()
                        }) {
                            Text("Start Debug Timer")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.green.opacity(0.2))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(awsManager.debugTimer != nil)
                        
                        Button(action: {
                            awsManager.stopDebugTimer()
                        }) {
                            Text("Stop Debug Timer")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.red.opacity(0.2))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(awsManager.debugTimer == nil)
                    }
                    
                    // Also show auto-refresh controls for testing
                    HStack {
                        Button(action: {
                            awsManager.startAutomaticRefresh()
                        }) {
                            Text("Start Auto-Refresh")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.blue.opacity(0.2))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(awsManager.isAutoRefreshActive)
                        
                        Button(action: {
                            awsManager.stopAutomaticRefresh()
                        }) {
                            Text("Stop Auto-Refresh")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.red.opacity(0.2))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!awsManager.isAutoRefreshActive)
                    }
                    
                    // Show timer states
                    Text("Debug Timer: \(awsManager.debugTimer != nil ? "Running" : "Stopped")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("Refresh Timer: \(awsManager.isAutoRefreshActive ? "Running" : "Stopped")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                Divider()
            #endif
            
            MenuButton(
                action: {
                    NSApplication.shared.terminate(nil)
                },
                label: "Quit AWS Cost Monitor",
                systemImage: "power",
                shortcut: "⌘Q",
                hoveredItem: $hoveredItem,
                pressedItem: $pressedItem,
                itemId: "quit"
            )
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 300)
        .task {
            // Only fetch once on initial app startup if not already loaded
            if awsManager.costData.isEmpty && awsManager.selectedProfile != nil {
                await awsManager.fetchCostForSelectedProfile()
            }
        }
        // Add keyboard shortcuts for profile switching (1-9)
        .background(
            ForEach(0..<min(awsManager.profiles.count, 9), id: \.self) { index in
                Color.clear
                    .onKeyPress(keys: [.init(Character("\(index + 1)"))]) { _ in
                        if let profile = awsManager.profiles[safe: index] {
                            awsManager.selectedProfile = profile
                            awsManager.saveSelectedProfile(profile: profile)
                            Task { await awsManager.fetchCostForSelectedProfile() }
                        }
                        return .handled
                    }
            }
        )
        .onAppear {
            // Timer removed to prevent threading issues
        }
        .onDisappear {
            // Timer cleanup removed
        }
    }
}

// Helper function to show help window
func showHelpWindow() {
    // Check if help window is already open
    if let existingWindow = NSApplication.shared.windows.first(where: { $0.title == "Help" }) {
        existingWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
    }
    
    // Create new help window
    let helpView = HelpView()
    let hostingController = NSHostingController(rootView: helpView)
    let window = NSWindow(contentViewController: hostingController)
    window.title = "Help"
    window.setContentSize(NSSize(width: 700, height: 500))
    window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
    window.center()
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}

// Store multi-profile dashboard window reference globally
var globalDashboardWindow: NSWindow?
var globalDashboardDelegate: WindowCloseDelegate?

// Helper function to show multi-profile dashboard window
func showMultiProfileDashboard(awsManager: AWSManager) {
    // Check if dashboard window is already open
    if let window = globalDashboardWindow {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
    }
    
    // Create new dashboard window
    let dashboardView = MultiProfileDashboard()
        .environmentObject(awsManager)
    
    let hostingController = NSHostingController(rootView: dashboardView)
    let window = NSWindow(contentViewController: hostingController)
    window.title = "Multi-Profile Dashboard"
    window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
    window.setContentSize(NSSize(width: 800, height: 600))
    window.center()
    
    globalDashboardWindow = window
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    
    // Clear reference when window closes
    globalDashboardDelegate = WindowCloseDelegate {
        globalDashboardWindow = nil
        globalDashboardDelegate = nil
    }
    window.delegate = globalDashboardDelegate
}

// Window close delegate to clear global reference
