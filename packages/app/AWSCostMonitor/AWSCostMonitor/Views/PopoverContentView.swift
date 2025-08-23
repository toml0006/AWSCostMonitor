//
//  PopoverContentView.swift
//  AWSCostMonitor
//
//  Main popover content view
//

import SwiftUI
import Charts

struct PopoverContentView: View {
    @EnvironmentObject var awsManager: AWSManager
    @State private var showAllServices = false
    @State private var helpButtonHovered = false
    @State private var quitButtonHovered = false
    @State private var refreshButtonHovered = false
    @State private var settingsButtonHovered = false
    @State private var consoleButtonHovered = false
    @State private var calendarButtonHovered = false
    @State private var selectedDayDetail: DayDetailData? = nil
    @State private var currentTime = Date()
    
    // Timer to update the "minutes ago" display every minute
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AWSCostMonitor")
                        .font(.system(size: 16, weight: .semibold))
                    #if DEBUG
                    Text("DEBUG BUILD")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                    #endif
                }
                Spacer()
                
                // Help button
                Button(action: {
                    showHelpWindow()
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 14))
                        .foregroundColor(helpButtonHovered ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .onHover { isHovered in
                    helpButtonHovered = isHovered
                    if isHovered {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
                
                // Quit button
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14))
                        .foregroundColor(quitButtonHovered ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .onHover { isHovered in
                    quitButtonHovered = isHovered
                    if isHovered {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            Divider()
            
            // Profile Selection
            if !awsManager.profiles.isEmpty {
                HStack {
                    Text("Profile:")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    // Team Cache Status Indicator
                    #if !OPENSOURCE
                    if let profile = awsManager.selectedProfile {
                        let settings = awsManager.getTeamCacheSettings(for: profile.name)
                        
                        if settings.teamCacheEnabled {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                                Text("Team")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            .help("Team cache enabled")
                        }
                    }
                    #endif
                    
                    Picker("", selection: $awsManager.selectedProfile) {
                        ForEach(awsManager.profiles, id: \.self) { profile in
                            if profile.name == "acme" {
                                Text("\(profile.name) (Demo)").tag(Optional(profile))
                            } else {
                                Text(profile.name).tag(Optional(profile))
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .labelsHidden()
                    .frame(maxWidth: 150)
                    .onChange(of: awsManager.selectedProfile) { oldProfile, newProfile in
                        if let profile = newProfile {
                            // Save the selected profile, which will handle everything:
                            // - Clear previous data
                            // - Load cache if available
                            // - Fetch new data if needed
                            // - Update refresh timer
                            awsManager.saveSelectedProfile(profile: profile)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // DEBUG: Force Refresh Button (only in debug builds)
            #if DEBUG
            if let profile = awsManager.selectedProfile,
               let cachedData = awsManager.costCache[profile.name] {
                let cacheAge = Date().timeIntervalSince(cachedData.fetchDate)
                if Int(cacheAge/60) > 30 {
                    Button(action: {
                        print("DEBUG: Manual force refresh button clicked")
                        Task {
                            await awsManager.fetchCostForSelectedProfile(force: true)
                        }
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Data is \(Int(cacheAge/60)) min old - Click to Force Refresh")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding(.horizontal)
                    
                    Divider()
                }
            }
            #endif
            
            // Cost Display with Proper Histograms
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if awsManager.isLoading {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading...")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else if let errorMessage = awsManager.errorMessage {
                        // Error state
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                            Text("Error Loading Profile")
                                .font(.system(size: 12, weight: .semibold))
                            Text(errorMessage)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                            
                            // Add permissions guidance for common errors
                            if errorMessage.contains("AccessDenied") || errorMessage.contains("UnauthorizedOperation") || errorMessage.contains("InvalidUserID.NotFound") {
                                VStack(spacing: 4) {
                                    Text("This profile may be missing Cost Explorer permissions.")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.orange)
                                        .multilineTextAlignment(.center)
                                    Text("Required: ce:GetCostAndUsage, ce:GetUsageReport")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 4)
                            }
                            
                            Button("Retry") {
                                Task {
                                    await awsManager.fetchCostForSelectedProfile(force: true)
                                }
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.blue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    } else if let cost = awsManager.costData.first {
                        // Main cost display
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Month-to-Date")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Spacer()
                                // Update time display - clickable to open refresh settings
                                if let selectedProfile = awsManager.selectedProfile,
                                   let cacheEntry = awsManager.costCache[selectedProfile.name] {
                                    let budget = awsManager.getBudget(for: selectedProfile.name)
                                    let nextUpdateTime = cacheEntry.fetchDate.addingTimeInterval(TimeInterval(budget.refreshIntervalMinutes * 60))
                                    
                                    Button(action: {
                                        showRefreshSettingsForApp(awsManager: awsManager)
                                    }) {
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("Updated \(cacheEntry.fetchDate, formatter: timeOnlyFormatter)")
                                                .font(.system(size: 9))
                                                .foregroundColor(.secondary)
                                            Text("Next Update \(nextUpdateTime, formatter: timeOnlyFormatter)")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.blue)
                                            
                                            // Team cache sync status
                                            // TODO: Check if team cache is enabled and show last sync
                                            let teamCacheEnabled = false // This should be loaded from profile settings
                                            if teamCacheEnabled {
                                                HStack(spacing: 3) {
                                                    Circle()
                                                        .fill(Color.blue)
                                                        .frame(width: 4, height: 4)
                                                    Text("Team synced")
                                                        .font(.system(size: 8))
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            HStack(alignment: .top) {
                                Text(awsManager.formatCurrency(cost.amount))
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(budgetColor(for: cost))
                                    .textSelection(.enabled)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    // Percentage comparison to last month
                                    if let lastMonthCost = awsManager.lastMonthData[cost.profileName],
                                       lastMonthCost.amount > 0 {
                                        let currentAmount = NSDecimalNumber(decimal: cost.amount).doubleValue
                                        let lastAmount = NSDecimalNumber(decimal: lastMonthCost.amount).doubleValue
                                        let percentChange = ((currentAmount - lastAmount) / lastAmount) * 100
                                        let isPositive = percentChange > 0
                                        let textColor = isPositive ? Color.red : Color.green
                                        let iconName = isPositive ? "arrow.up" : "arrow.down"
                                        
                                        HStack(spacing: 2) {
                                            Image(systemName: iconName)
                                                .foregroundColor(textColor)
                                                .font(.system(size: 10))
                                            Text(String(format: "%+.1f%% vs last month", percentChange))
                                                .font(.system(size: 10))
                                                .foregroundColor(textColor)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            // Month-end projection
                            let calendar = Calendar.current
                            let now = Date()
                            let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
                            let dayOfMonth = calendar.component(.day, from: now)
                            let dailyAverage = NSDecimalNumber(decimal: cost.amount).doubleValue / Double(dayOfMonth)
                            let projection = dailyAverage * Double(daysInMonth)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Projected Month-End")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                HStack {
                                    Text(awsManager.formatCurrency(Decimal(projection)))
                                        .font(.system(size: 14, weight: .medium))
                                        .textSelection(.enabled)
                                    Text("(at current rate)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Last month comparison
                            if let lastMonthCost = awsManager.lastMonthData[cost.profileName] {
                                HStack {
                                    Text("Last Month Total:")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                    Text(awsManager.formatCurrency(lastMonthCost.amount))
                                        .font(.system(size: 10, weight: .medium))
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Service breakdown with REAL histograms
                        if let cacheEntry = awsManager.costCache[cost.profileName],
                           !cacheEntry.serviceCosts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Services")
                                        .font(.system(size: 12, weight: .semibold))
                                    Spacer()
                                    if cacheEntry.serviceCosts.count > 5 {
                                        Button(showAllServices ? "Show Top 5" : "Show All (\(cacheEntry.serviceCosts.count))") {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                showAllServices.toggle()
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .font(.system(size: 10))
                                        .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal)
                                
                                let servicesToShow = showAllServices ? cacheEntry.serviceCosts : Array(cacheEntry.serviceCosts.prefix(5))
                                
                                ForEach(servicesToShow, id: \.serviceName) { service in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(service.serviceName)
                                                .font(.system(size: 11))
                                                .textSelection(.enabled)
                                            Spacer()
                                            Text(awsManager.formatCurrency(service.amount))
                                                .font(.system(size: 11, weight: .medium))
                                                .textSelection(.enabled)
                                        }
                                        
                                        // REAL HISTOGRAM with Rectangles!
                                        if let dailyServiceCosts = awsManager.dailyServiceCostsByProfile[cost.profileName],
                                           !dailyServiceCosts.isEmpty {
                                            RealHistogramView(
                                                dailyServiceCosts: dailyServiceCosts,
                                                serviceName: service.serviceName,
                                                selectedDayDetail: $selectedDayDetail
                                            )
                                            .environmentObject(awsManager)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(4)
                                }
                            }
                        }
                    } else {
                        Text("No cost data available")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            
            // Team Cache Status (if enabled)
            if let profile = awsManager.selectedProfile,
               let controller = awsManager.teamCacheController {
                let settings = awsManager.getTeamCacheSettings(for: profile.name)
                if settings.teamCacheEnabled {
                    Divider()
                    
                    TeamCacheStatusView(
                        teamCacheController: controller,
                        profileName: profile.name
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
            
            Divider()
            
            // Bottom buttons - arranged in two rows to fit better
            VStack(spacing: 8) {
                // Top row: Refresh and Settings
                HStack {
                    // Regular refresh button
                    Button(action: {
                        Task {
                            await awsManager.fetchCostForSelectedProfile(force: true)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                                .foregroundColor(refreshButtonHovered ? .blue : .primary)
                            Text("Refresh")
                                .foregroundColor(refreshButtonHovered ? .blue : .primary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(refreshButtonHovered ? Color.blue.opacity(0.1) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovered in
                        refreshButtonHovered = isHovered
                        if isHovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                    
                    // Team cache force refresh (when enabled)
                    if let profile = awsManager.selectedProfile {
                        // TODO: Check if team cache is enabled for this profile
                        let teamCacheEnabled = false // This should be loaded from profile settings
                        
                        if teamCacheEnabled {
                            Button(action: {
                                Task {
                                    // TODO: Implement team cache force refresh
                                    await awsManager.fetchCostForSelectedProfile(force: true)
                                    awsManager.log(.info, category: "TeamCache", "Team cache force refresh initiated from menu")
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "externaldrive.connected.to.line.below")
                                        .font(.system(size: 10))
                                        .foregroundColor(.blue)
                                    Text("Team")
                                        .font(.system(size: 10))
                                        .foregroundColor(.blue)
                                }
                            }
                            .buttonStyle(.plain)
                            .help("Force refresh team cache")
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showSettingsWindowForApp(awsManager: awsManager)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "gear")
                                .font(.system(size: 11))
                                .foregroundColor(settingsButtonHovered ? .blue : .primary)
                            Text("Settings")
                                .foregroundColor(settingsButtonHovered ? .blue : .primary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(settingsButtonHovered ? Color.blue.opacity(0.1) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovered in
                        settingsButtonHovered = isHovered
                        if isHovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                }
                // Bottom row: Calendar and AWS Console
                HStack {
                    Button(action: {
                        CalendarWindowController.showCalendarWindow(awsManager: awsManager)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                                .foregroundColor(calendarButtonHovered ? .blue : .primary)
                            Text("Calendar")
                                .foregroundColor(calendarButtonHovered ? .blue : .primary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(calendarButtonHovered ? Color.blue.opacity(0.1) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovered in
                        calendarButtonHovered = isHovered
                        if isHovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if let profile = awsManager.selectedProfile {
                            let region = profile.region ?? "us-east-1"
                            let urlString = "https://\(region).console.aws.amazon.com/billing/home"
                            if let url = URL(string: urlString) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.system(size: 11))
                                .foregroundColor(consoleButtonHovered ? .blue : .primary)
                            Text("AWS Console")
                                .foregroundColor(consoleButtonHovered ? .blue : .primary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(consoleButtonHovered ? Color.blue.opacity(0.1) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovered in
                        consoleButtonHovered = isHovered
                        if isHovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                }
                
                // Debug controls only in DEBUG builds
                #if DEBUG
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Debug Timer Test")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text(awsManager.debugTimerMessage)
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        
                        if let lastUpdate = awsManager.debugLastUpdate {
                            Text("Last: \(lastUpdate, style: .relative)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 8) {
                            Button(action: {
                                awsManager.startDebugTimer()
                            }) {
                                Text("Start Debug")
                                    .font(.system(size: 10))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .disabled(awsManager.debugTimer != nil)
                            
                            Button(action: {
                                awsManager.stopDebugTimer()
                            }) {
                                Text("Stop Debug")
                                    .font(.system(size: 10))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .disabled(awsManager.debugTimer == nil)
                        }
                        
                        HStack(spacing: 8) {
                            Button(action: {
                                awsManager.startAutomaticRefresh()
                            }) {
                                Text("Start Auto")
                                    .font(.system(size: 10))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .disabled(awsManager.isAutoRefreshActive)
                            
                            Button(action: {
                                awsManager.stopAutomaticRefresh()
                            }) {
                                Text("Stop Auto")
                                    .font(.system(size: 10))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .disabled(!awsManager.isAutoRefreshActive)
                        }
                        
                        Text("Debug: \(awsManager.debugTimer != nil ? "✓" : "✗") | Auto: \(awsManager.isAutoRefreshActive ? "✓" : "✗")")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                #endif
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .frame(width: 360, height: {
            #if DEBUG
                return 600
            #else
                return 500
            #endif
        }())
        .sheet(item: $selectedDayDetail) { detail in
            DayDetailView(
                date: detail.date,
                dailyCost: detail.dailyCost,
                services: detail.services,
                currencyFormatter: detail.currencyFormatter,
                apiCalls: detail.apiCalls,
                highlightedService: detail.highlightedService,
                onNavigateToDate: nil  // No navigation in popover
            )
        }
        .onAppear {
            // SUPER AGGRESSIVE DEBUG CHECK - Force refresh if > 30 minutes old
            if let profile = awsManager.selectedProfile {
                if let cachedData = awsManager.costCache[profile.name] {
                    let cacheAge = Date().timeIntervalSince(cachedData.fetchDate)
                    let cacheAgeMinutes = Int(cacheAge/60)
                    
                    print("DEBUG: PopoverContentView.onAppear - Cache is \(cacheAgeMinutes) minutes old")
                    awsManager.log(.warning, category: "UI", "DEBUG: Popover opened - Cache age: \(cacheAgeMinutes) min")
                    
                    // FORCE REFRESH if older than 30 minutes
                    if cacheAgeMinutes > 30 && !awsManager.isLoading {
                        print("DEBUG: FORCING REFRESH - Cache is \(cacheAgeMinutes) minutes old (> 30 min threshold)")
                        awsManager.log(.error, category: "UI", "FORCING REFRESH - Cache is \(cacheAgeMinutes) min old")
                        
                        // Single async call to prevent race conditions
                        Task { @MainActor in
                            await awsManager.fetchCostForSelectedProfile(force: true)
                        }
                    }
                } else if !awsManager.isLoading {
                    // No cache data at all, fetch immediately
                    print("DEBUG: NO CACHE - Fetching immediately")
                    awsManager.log(.error, category: "UI", "NO CACHE - Fetching immediately")
                    Task { @MainActor in
                        await awsManager.fetchCostForSelectedProfile(force: true)
                    }
                }
            } else {
                print("DEBUG: No selected profile in onAppear")
            }
        }
        .onDisappear {
            // Dismiss any open day detail sheet when popover disappears
            selectedDayDetail = nil
        }
        .onReceive(timer) { _ in
            // Update current time every minute to refresh "minutes ago" display
            currentTime = Date()
        }
    }
    
    private var timeOnlyFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    private func budgetColor(for cost: CostData) -> Color {
        // First check if costs are trending better than last month
        if let lastMonthCost = awsManager.lastMonthData[cost.profileName],
           lastMonthCost.amount > 0 {
            let currentAmount = NSDecimalNumber(decimal: cost.amount).doubleValue
            let lastAmount = NSDecimalNumber(decimal: lastMonthCost.amount).doubleValue
            let percentChange = ((currentAmount - lastAmount) / lastAmount) * 100
            
            // If significantly lower than last month, show green regardless of budget
            if percentChange < -20 {
                return .green
            }
        }
        
        // Otherwise use budget-based coloring
        let budget = awsManager.getBudget(for: cost.profileName)
        if let monthlyBudget = budget.monthlyBudget {
            let amount = NSDecimalNumber(decimal: cost.amount).doubleValue
            let percentUsed = (amount / NSDecimalNumber(decimal: monthlyBudget).doubleValue) * 100
            if percentUsed >= 100 {
                return .red
            } else if percentUsed >= 80 {
                return .orange
            } else {
                return .green
            }
        }
        return .primary
    }
}

// MARK: - Day Detail Data Structure

struct DayDetailData: Identifiable {
    let id = UUID()
    let date: Date
    let dailyCost: DailyCost
    let services: [ServiceCost]
    let currencyFormatter: NumberFormatter
    let apiCalls: [APIRequestRecord]
    let highlightedService: String
}

// MARK: - Real Histogram View with Full Graphics

