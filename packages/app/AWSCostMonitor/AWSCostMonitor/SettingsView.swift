import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var awsManager: AWSManager
    @AppStorage("MenuBarDisplayFormat") private var displayFormat: String = MenuBarDisplayFormat.full.rawValue
    @AppStorage("RefreshIntervalMinutes") private var refreshInterval: Int = 5
    @AppStorage("SelectedAWSProfileName") private var selectedProfileName: String = ""
    @State private var selectedCategory: String
    @State private var hoveredCategory: String? = nil
    
    init(initialSelectedCategory: String = "Profiles") {
        _selectedCategory = State(initialValue: initialSelectedCategory)
    }
    
    private var displayFormatEnum: MenuBarDisplayFormat {
        MenuBarDisplayFormat(rawValue: displayFormat) ?? .full
    }
    
    var settingsCategories: [String] {
        var categories = [
            "Profiles",
        ]
        
        // Only include Team Cache in non-open source builds
        #if !OPENSOURCE
        categories.append("Team Cache")
        #endif
        
        categories.append(contentsOf: [
            "Refresh Rate",
            "Display",
            "Alerts",
            "Notifications",
            "CloudWatch",
            "Debug"
        ])
        
        return categories
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                Text("Settings")
                    .font(.headline)
                    .padding()
                
                ForEach(settingsCategories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: iconForCategory(category))
                                .frame(width: 20)
                                .foregroundColor(selectedCategory == category ? .white : (hoveredCategory == category ? .accentColor : .primary))
                            Text(category)
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .lineLimit(1)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Add Pro badge for Team Cache (non-open source only)
                            #if !OPENSOURCE
                            if category == "Team Cache" {
                                Text("Pro")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            #endif
                            
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedCategory == category ? Color.accentColor : 
                                   (hoveredCategory == category ? Color.accentColor.opacity(0.1) : Color.clear))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .onHover { isHovered in
                        hoveredCategory = isHovered ? category : nil
                    }
                }
                
                Spacer()
                
                // Marketing website link at bottom
                VStack(spacing: 8) {
                    Divider()
                        .padding(.horizontal, 8)
                    
                    Button(action: {
                        if let url = URL(string: "https://toml0006.github.io/AWSCostMonitor/") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text("toml0006.github.io/AWSCostMonitor")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                }
                .padding(.bottom, 8)
            }
            .frame(width: 220)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    settingsContent(for: selectedCategory)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 750, height: 450)
        .onAppear {
            // Sync @AppStorage values with AWSManager on appear
            syncSettingsWithManager()
        }
    }
    
    func iconForCategory(_ category: String) -> String {
        switch category {
        case "Refresh Rate":
            return "arrow.clockwise"
        case "Display":
            return "textformat"
        case "Profiles":
            return "person.2"
        case "Team Cache":
            return "externaldrive.connected.to.line.below"
        case "Alerts":
            return "exclamationmark.triangle"
        case "Notifications":
            return "bell.badge"
        case "CloudWatch":
            return "chart.line.uptrend.xyaxis"
        case "Debug":
            return "ant.circle"
        default:
            return "gear"
        }
    }
    
    @ViewBuilder
    func settingsContent(for category: String) -> some View {
        switch category {
        case "Refresh Rate":
            RefreshRateTab()
        case "Display":
            DisplaySettingsTab(
                displayFormat: Binding(
                    get: { displayFormatEnum },
                    set: { newFormat in
                        displayFormat = newFormat.rawValue
                        awsManager.saveDisplayFormat(newFormat)
                    }
                )
            )
        case "Profiles":
            AWSSettingsTab()
        #if !OPENSOURCE
        case "Team Cache":
            TeamCacheSettingsTab()
        #endif
        case "Alerts":
            AnomalySettingsTab()
        case "Notifications":
            NotificationSettingsTab()
        case "CloudWatch":
            CloudWatchSettingsTab()
        case "Debug":
            DebugSettingsTab()
        default:
            Text("Select a setting category")
        }
    }
    
    private func syncSettingsWithManager() {
        // Sync display format
        if let format = MenuBarDisplayFormat(rawValue: displayFormat) {
            awsManager.displayFormat = format
        }
        
        // Sync refresh interval
        awsManager.refreshInterval = refreshInterval
        
        // Sync selected profile if available
        if !selectedProfileName.isEmpty {
            awsManager.selectedProfile = awsManager.profiles.first { $0.name == selectedProfileName }
        }
    }
}

struct DisplaySettingsTab: View {
    @Binding var displayFormat: MenuBarDisplayFormat
    @AppStorage("ShowCurrencySymbol") private var showCurrencySymbol: Bool = true
    @AppStorage("DecimalPlaces") private var decimalPlaces: Int = 2
    @AppStorage("UseThousandsSeparator") private var useThousandsSeparator: Bool = true
    @AppStorage("ShowMenuBarColors") private var showMenuBarColors: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Menu Bar Display Format")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(MenuBarDisplayFormat.allCases, id: \.self) { format in
                    HStack {
                        Button(action: {
                            displayFormat = format
                        }) {
                            HStack {
                                Image(systemName: displayFormat == format ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading) {
                                    Text(format.displayName)
                                        .foregroundColor(.primary)
                                    Text("Preview: \(CostDisplayFormatter.previewText(for: format))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()
            
            // Additional Format Options
            Text("Format Options")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Show currency symbol", isOn: $showCurrencySymbol)
                
                Toggle("Use thousands separator", isOn: $useThousandsSeparator)
                
                Toggle("Show trend colors in menu bar", isOn: $showMenuBarColors)
                    .help("Green when lower than last month, red when higher")
                
                if displayFormat != .abbreviated {
                    HStack {
                        Text("Decimal places:")
                        Picker("", selection: $decimalPlaces) {
                            Text("0").tag(0)
                            Text("1").tag(1)
                            Text("2").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct RefreshSettingsTab: View {
    @Binding var refreshInterval: Int
    @EnvironmentObject var awsManager: AWSManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Automatic Refresh")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Refresh cost data automatically every:")
                
                HStack {
                    Slider(value: Binding(
                        get: { Double(refreshInterval) },
                        set: { refreshInterval = Int($0) }
                    ), in: 1...60, step: 1) {
                        Text("Refresh Interval")
                    }
                    .frame(maxWidth: 200)
                    
                    Text("\(refreshInterval) minute\(refreshInterval == 1 ? "" : "s")")
                        .frame(minWidth: 80, alignment: .leading)
                }
                
                Divider()
                
                HStack {
                    Text("Auto-refresh is currently:")
                    Text(awsManager.isAutoRefreshActive ? "On" : "Off")
                        .fontWeight(.semibold)
                        .foregroundColor(awsManager.isAutoRefreshActive ? .green : .secondary)
                    
                    Spacer()
                    
                    Button(awsManager.isAutoRefreshActive ? "Stop" : "Start") {
                        if awsManager.isAutoRefreshActive {
                            awsManager.stopAutomaticRefresh()
                        } else {
                            awsManager.startAutomaticRefresh()
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct AWSSettingsTab: View {
    @EnvironmentObject var awsManager: AWSManager
    @AppStorage("HasDismissedConfigAccess") private var hasDismissedConfigAccess: Bool = false
    @ObservedObject private var accessManager = AWSConfigAccessManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Show AWS folder selection if in demo mode
                if awsManager.isDemoMode || (awsManager.realProfiles.isEmpty && !awsManager.demoProfiles.isEmpty) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                            Text("AWS Configuration")
                                .font(.headline)
                        }
                        
                        Text("You're currently using demo data. Grant access to your AWS configuration folder to see your real AWS profiles and costs.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack {
                            Button("Select AWS Folder") {
                                // Request AWS config access
                                accessManager.requestAccess()
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Text("Select your ~/.aws folder")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        // Show current status
                        if accessManager.hasAccess {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.green)
                                Text("AWS folder access granted")
                                    .font(.system(size: 11))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    
                    Divider()
                }
                
                // Profile Visibility section
                Text("Profile Visibility")
                    .font(.headline)
            
                ProfileVisibilitySection()
            }
            .padding()
        }
        .onReceive(NotificationCenter.default.publisher(for: .awsConfigAccessGranted)) { _ in
            // Clear the dismissed flag when access is granted
            hasDismissedConfigAccess = false
            // The AWSManager will automatically reload profiles
        }
        .onAppear {
            // AWS profiles settings loaded automatically
        }
    }
}

struct RefreshRateTab: View {
    @EnvironmentObject var awsManager: AWSManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Refresh Rate Settings")
                .font(.headline)
            
            // AWS Update Info - prominent at the top
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AWS billing data updates ~3 times daily")
                        .font(.system(size: 12, weight: .medium))
                    Text("Updates occur approximately every 8-12 hours. More frequent refreshes won't show new data.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            Text("Configure how often each AWS profile fetches new cost data")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !awsManager.profiles.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(awsManager.profiles, id: \.self) { profile in
                            RefreshProfileRow(profile: profile)
                                .environmentObject(awsManager)
                        }
                    }
                }
            } else {
                Text("No AWS profiles available")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct RefreshProfileRow: View {
    let profile: AWSProfile
    @EnvironmentObject var awsManager: AWSManager
    @State private var refreshInterval: Double = 480  // 8 hours default
    
    // Computed properties for display
    var estimatedCallsPerMonth: Int {
        let minutesPerMonth = 30 * 24 * 60
        return minutesPerMonth / Int(refreshInterval)
    }
    
    var estimatedMonthlyCost: Double {
        return Double(estimatedCallsPerMonth) * 0.01
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Profile header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(profile.name)
                            .font(.system(size: 14, weight: .medium))
                        
                        if profile.name == "acme" {
                            Text("Demo")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        
                        if profile.name == awsManager.selectedProfile?.name {
                            Text("Active")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    }
                    
                    if let region = profile.region {
                        Text(region)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Auto-refresh status
                if awsManager.isAutoRefreshActive && profile.name == awsManager.selectedProfile?.name {
                    Label("Auto-refresh active", systemImage: "checkmark.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            // Refresh interval slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Refresh Interval:")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatRefreshInterval(refreshInterval))
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                }
                
                Slider(value: $refreshInterval, in: 480...1440, step: 60)
                    .onChange(of: refreshInterval) { _, newValue in
                        saveRefreshInterval(Int(newValue))
                    }
                
                HStack {
                    Text("8 hours")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("24 hours")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                // Quick preset buttons
                HStack(spacing: 8) {
                    Text("Quick Set:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Button("8h") {
                        refreshInterval = 480
                        saveRefreshInterval(480)
                    }
                    .buttonStyle(.accessoryBar)
                    .help("Refresh 3x daily (matches AWS update frequency)")
                    
                    Button("12h") {
                        refreshInterval = 720
                        saveRefreshInterval(720)
                    }
                    .buttonStyle(.accessoryBar)
                    .help("Refresh 2x daily")
                    
                    Button("24h") {
                        refreshInterval = 1440
                        saveRefreshInterval(1440)
                    }
                    .buttonStyle(.accessoryBar)
                    .help("Refresh once daily")
                    
                    Spacer()
                }
                
                // Cost estimation
                Text("Estimated monthly cost: $\(String(format: "%.2f", estimatedMonthlyCost)) (\(estimatedCallsPerMonth) API calls)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            loadBudgetSettings()
        }
    }
    
    private func formatRefreshInterval(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        
        if hours >= 24 {
            return "24 hours"
        } else if hours > 0 && mins == 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins) minutes"
        }
    }
    
    private func loadBudgetSettings() {
        let budget = awsManager.getBudget(for: profile.name)
        refreshInterval = Double(budget.refreshIntervalMinutes)
    }
    
    private func saveRefreshInterval(_ minutes: Int) {
        let budget = awsManager.getBudget(for: profile.name)
        awsManager.updateAPIBudgetAndRefresh(for: profile.name, apiBudget: budget.apiBudget, refreshIntervalMinutes: minutes)
    }
}

struct BudgetProfileRow: View {
    let profile: AWSProfile
    @EnvironmentObject var awsManager: AWSManager
    @State private var apiBudget: String = "5"
    
    // Computed properties for display
    var estimatedAPICalls: Int {
        Int((Double(apiBudget) ?? 5.0) / 0.01)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Profile header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(profile.name)
                            .font(.system(size: 14, weight: .medium))
                        
                        if profile.name == "acme" {
                            Text("Demo")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    
                    if let region = profile.region {
                        Text(region)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // API Budget controls
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("API Budget:")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    TextField("5", text: $apiBudget)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .onChange(of: apiBudget) { _, _ in
                            saveBudgetSettings()
                        }
                    
                    Text("USD/month")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("~\(estimatedAPICalls) calls")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                }
                
                Text("AWS charges ~$0.01 per Cost Explorer API request")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            loadBudget()
        }
    }
    
    private func loadBudget() {
        let budget = awsManager.getBudget(for: profile.name)
        apiBudget = String(format: "%.0f", NSDecimalNumber(decimal: budget.apiBudget).doubleValue)
    }
    
    private func saveBudgetSettings() {
        guard let apiBudgetValue = Decimal(string: apiBudget),
              apiBudgetValue > 0 else { return }
        
        let budget = awsManager.getBudget(for: profile.name)
        awsManager.updateAPIBudgetAndRefresh(for: profile.name, apiBudget: apiBudgetValue, refreshIntervalMinutes: budget.refreshIntervalMinutes)
    }
}

struct AnomalySettingsTab: View {
    @AppStorage("EnableAnomalyDetection") private var enableAnomalyDetection: Bool = true
    @AppStorage("AnomalyThresholdPercentage") private var anomalyThreshold: Double = 25.0
    @EnvironmentObject var awsManager: AWSManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Alerts")
                .font(.headline)
            
            Text("Anomaly Detection")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Toggle("Enable spending alerts", isOn: $enableAnomalyDetection)
                .onChange(of: enableAnomalyDetection) { _, _ in
                    // Re-run anomaly detection when enabled/disabled
                    if let cost = awsManager.costData.first,
                       let profile = awsManager.selectedProfile {
                        awsManager.detectAnomalies(
                            for: profile.name,
                            currentAmount: cost.amount,
                            serviceCosts: awsManager.serviceCosts
                        )
                    }
                }
            
            if enableAnomalyDetection {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Alert Sensitivity")
                        .font(.subheadline)
                    
                    HStack {
                        Text("Threshold:")
                        Slider(value: $anomalyThreshold, in: 10...50, step: 5)
                            .frame(width: 200)
                        Text("\(Int(anomalyThreshold))%")
                            .frame(width: 40, alignment: .leading)
                    }
                    
                    Text("Alert when spending deviates by more than \(Int(anomalyThreshold))% from historical average")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alert Types")
                        .font(.subheadline)
                    
                    Label("Unusual spending spikes or drops", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                    Label("Spending velocity warnings", systemImage: "speedometer")
                        .font(.caption)
                    Label("High-cost service detection", systemImage: "exclamationmark.bubble")
                        .font(.caption)
                }
                
                if awsManager.historicalData.count < 2 {
                    Divider()
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Limited Historical Data")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("Anomaly detection improves with more historical data. Currently have data for \(awsManager.historicalData.count) month(s).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            
            Spacer()
        }
    }
}

struct DebugSettingsTab: View {
    @EnvironmentObject var awsManager: AWSManager
    @AppStorage("DebugMode") private var debugMode: Bool = false
    @AppStorage("MaxLogEntries") private var maxLogEntries: Int = 1000
    @State private var showingExportSuccess = false
    @State private var exportedFileURL: URL?
    @State private var showingResetConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Debug & Logging")
                .font(.headline)
            
            Toggle("Enable debug mode", isOn: $debugMode)
                .onChange(of: debugMode) { _, newValue in
                    awsManager.debugMode = newValue
                    awsManager.log(.info, category: "Config", "Debug mode \(newValue ? "enabled" : "disabled")")
                }
            
            if debugMode {
                Text("Debug mode enables verbose logging for troubleshooting")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Log Settings")
                    .font(.subheadline)
                
                HStack {
                    Text("Max log entries:")
                    Picker("", selection: $maxLogEntries) {
                        Text("100").tag(100)
                        Text("500").tag(500)
                        Text("1000").tag(1000)
                        Text("5000").tag(5000)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                Text("Older entries are automatically removed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Log Statistics")
                    .font(.subheadline)
                
                HStack {
                    Text("Current log entries:")
                    Spacer()
                    Text("\(awsManager.logEntries.count)")
                        .monospacedDigit()
                }
                
                HStack {
                    Text("API requests tracked:")
                    Spacer()
                    Text("\(awsManager.apiRequestRecords.count)")
                        .monospacedDigit()
                }
                
                // Show API requests per profile
                if !awsManager.apiRequestsPerProfile.isEmpty {
                    Divider()
                    
                    Text("API Requests by Profile")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(awsManager.apiRequestsPerProfile.keys.sorted()), id: \.self) { profileName in
                        if let requests = awsManager.apiRequestsPerProfile[profileName] {
                            HStack {
                                Text(profileName)
                                    .font(.caption)
                                Spacer()
                                Text("\(requests.count) requests")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Show recent requests
                            if let recentRequest = requests.last {
                                Text("\(recentRequest.endpoint) - \(recentRequest.timestamp, style: .relative)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.leading)
                            }
                        }
                    }
                }
                
                // Show recent errors
                let recentErrors = awsManager.logEntries.filter { $0.level == .error }.suffix(3)
                if !recentErrors.isEmpty {
                    Divider()
                    
                    Text("Recent Errors")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    
                    ForEach(Array(recentErrors), id: \.id) { error in
                        HStack {
                            Image(systemName: error.level.icon)
                                .foregroundColor(error.level.color)
                                .font(.caption)
                            Text(error.message)
                                .font(.caption)
                                .lineLimit(2)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack {
                Button("Export Logs") {
                    if let url = awsManager.exportLogs() {
                        exportedFileURL = url
                        showingExportSuccess = true
                    }
                }
                
                if awsManager.logEntries.count > 100 {
                    Button("Clear Logs") {
                        awsManager.logEntries.removeAll()
                        awsManager.log(.info, category: "Config", "Logs cleared by user")
                    }
                    .foregroundColor(.red)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Reset All Settings Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Reset Application")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                Text("This will clear all settings and data, including profile configurations, preferences, and onboarding status. The app will restart as if freshly installed.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Reset All Settings") {
                    showingResetConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
            .background(Color.red.opacity(0.05))
            .cornerRadius(8)
            
            Spacer()
        }
        .alert("Logs Exported", isPresented: $showingExportSuccess) {
            Button("Show in Finder") {
                if let url = exportedFileURL {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            if let url = exportedFileURL {
                Text("Logs saved to: \(url.lastPathComponent)")
            }
        }
        .alert("Reset All Settings?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset Everything", role: .destructive) {
                resetAllSettings()
            }
        } message: {
            Text("This action cannot be undone. All your settings, preferences, and cached data will be permanently deleted. The app will quit and you'll need to restart it.")
        }
    }
    
    private func resetAllSettings() {
        // Log the reset action
        awsManager.log(.warning, category: "Config", "User initiated full settings reset")
        
        // Get all UserDefaults keys and remove them
        let domain = Bundle.main.bundleIdentifier ?? "middleout.AWSCostMonitor"
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        // Clear specific keys that might be stored outside the app's domain
        let keysToReset = [
            "HasCompletedOnboarding",
            "HasDismissedConfigAccess",
            "SelectedAWSProfileName",
            "MenuBarDisplayFormat",
            "RefreshIntervalMinutes",
            "ShowCurrencySymbol",
            "DecimalPlaces",
            "UseThousandsSeparator",
            "ShowMenuBarColors",
            "DebugMode",
            "MaxLogEntries",
            "EnableAnomalyDetection",
            "AnomalyThresholdPercentage",
            "ProfileVisibilitySettings",
            "ProfileBudgets",
            "ProfileRemovedList",
            "SeenProfiles",
            "HiddenProfiles",
            "VisibleProfiles"
        ]
        
        for key in keysToReset {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Clear any Team Cache settings
        let profiles = awsManager.profiles
        for profile in profiles {
            UserDefaults.standard.removeObject(forKey: "TeamCacheConfig_\(profile.name)")
            UserDefaults.standard.removeObject(forKey: "ProfileBudget_\(profile.name)")
        }
        
        // Synchronize to ensure all changes are written
        UserDefaults.standard.synchronize()
        
        // Log completion
        awsManager.log(.info, category: "Config", "Settings reset complete. Quitting application.")
        
        // Quit the application after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
        }
    }
}

struct NotificationSettingsTab: View {
    @EnvironmentObject var awsManager: AWSManager
    @State private var selectedProfile: AWSProfile?
    @State private var alertConfig = AlertConfiguration()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Notification Settings")
                .font(.headline)
            
            // Check notification permissions
            HStack {
                Image(systemName: permissionIcon)
                    .foregroundColor(permissionColor)
                VStack(alignment: .leading) {
                    Text(permissionText)
                        .font(.subheadline)
                    if awsManager.alertManager.notificationPermissionStatus == .notDetermined {
                        Button("Request Permission") {
                            Task {
                                await awsManager.alertManager.requestNotificationPermissions()
                            }
                        }
                        .buttonStyle(.link)
                    } else if awsManager.alertManager.notificationPermissionStatus == .denied {
                        Button("Open System Settings") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Divider()
            
            if !awsManager.profiles.isEmpty {
                // Profile selector
                Picker("Select Profile:", selection: $selectedProfile) {
                    Text("Choose a profile").tag(nil as AWSProfile?)
                    ForEach(awsManager.profiles, id: \.self) { profile in
                        Text(profile.name).tag(Optional(profile))
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedProfile) { _, newProfile in
                    if let profile = newProfile {
                        loadAlertConfig(for: profile)
                    }
                }
                
                if selectedProfile != nil {
                    Divider()
                    
                    // Alert settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Alert Types")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Toggle("Budget threshold alerts", isOn: $alertConfig.enableThresholdAlerts)
                            .help("Notify when spending approaches budget threshold")
                        
                        Toggle("Budget exceeded alerts", isOn: $alertConfig.enableBudgetExceededAlerts)
                            .help("Notify when spending exceeds monthly budget")
                        
                        Toggle("Anomaly alerts", isOn: $alertConfig.enableAnomalyAlerts)
                            .help("Notify about unusual spending patterns")
                        
                        Divider()
                        
                        Toggle("Play sound", isOn: $alertConfig.soundEnabled)
                        
                        HStack {
                            Text("Alert cooldown:")
                            Picker("", selection: $alertConfig.cooldownMinutes) {
                                Text("15 minutes").tag(15)
                                Text("30 minutes").tag(30)
                                Text("1 hour").tag(60)
                                Text("2 hours").tag(120)
                                Text("6 hours").tag(360)
                            }
                            .pickerStyle(.menu)
                            .frame(width: 120)
                        }
                        .help("Minimum time between alerts of the same type")
                        
                        Divider()
                        
                        HStack {
                            Spacer()
                            Button("Save Settings") {
                                saveAlertConfig()
                            }
                            .disabled(selectedProfile == nil)
                        }
                    }
                }
                
                // Recent alerts section
                if let profile = selectedProfile {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Alerts")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        let recentAlerts = awsManager.alertManager.getRecentAlerts(for: profile.name, limit: 5)
                        
                        if recentAlerts.isEmpty {
                            Text("No recent alerts")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        } else {
                            ForEach(recentAlerts, id: \.timestamp) { alert in
                                HStack {
                                    Image(systemName: iconForAlertType(alert.alertType))
                                        .foregroundColor(colorForAlertType(alert.alertType))
                                        .font(.caption)
                                    Text(alert.alertType.rawValue.capitalized)
                                        .font(.caption)
                                    Spacer()
                                    Text(alert.timestamp, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            } else {
                Text("No AWS profiles available")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .onAppear {
            if selectedProfile == nil && !awsManager.profiles.isEmpty {
                selectedProfile = awsManager.selectedProfile ?? awsManager.profiles.first
                if let profile = selectedProfile {
                    loadAlertConfig(for: profile)
                }
            }
        }
    }
    
    private var permissionIcon: String {
        switch awsManager.alertManager.notificationPermissionStatus {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .provisional:
            return "exclamationmark.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private var permissionColor: Color {
        switch awsManager.alertManager.notificationPermissionStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .provisional:
            return .orange
        default:
            return .secondary
        }
    }
    
    private var permissionText: String {
        switch awsManager.alertManager.notificationPermissionStatus {
        case .authorized:
            return "Notifications are enabled"
        case .denied:
            return "Notifications are disabled. Enable in System Settings."
        case .provisional:
            return "Provisional notifications enabled"
        case .notDetermined:
            return "Notification permission not yet requested"
        @unknown default:
            return "Unknown notification status"
        }
    }
    
    private func loadAlertConfig(for profile: AWSProfile) {
        alertConfig = awsManager.alertManager.getAlertConfiguration(for: profile.name)
    }
    
    private func saveAlertConfig() {
        guard let profile = selectedProfile else { return }
        awsManager.alertManager.updateAlertConfiguration(for: profile.name, configuration: alertConfig)
    }
    
    private func iconForAlertType(_ type: SentAlert.AlertType) -> String {
        switch type {
        case .threshold:
            return "exclamationmark.circle"
        case .budgetExceeded:
            return "exclamationmark.octagon"
        case .anomaly:
            return "exclamationmark.triangle"
        }
    }
    
    private func colorForAlertType(_ type: SentAlert.AlertType) -> Color {
        switch type {
        case .threshold:
            return .orange
        case .budgetExceeded:
            return .red
        case .anomaly:
            return .yellow
        }
    }
}

struct CloudWatchSettingsTab: View {
    @EnvironmentObject var awsManager: AWSManager
    @StateObject private var cloudWatchManager = CloudWatchManager()
    @State private var showingAddMetric = false
    @State private var selectedMetric: CloudWatchMetric?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("CloudWatch Metrics")
                .font(.headline)
            
            if cloudWatchManager.metrics.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No CloudWatch metrics configured")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Add custom metrics to monitor AWS services beyond just costs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Add Your First Metric") {
                        showingAddMetric = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                // Metrics list
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Configured Metrics")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Add Metric") {
                            showingAddMetric = true
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(cloudWatchManager.metrics) { metric in
                                CloudWatchMetricRow(
                                    metric: metric,
                                    latestData: cloudWatchManager.getLatestValue(for: metric),
                                    onEdit: { selectedMetric = metric },
                                    onDelete: { cloudWatchManager.removeMetric(metric) }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                
                Divider()
                
                // Refresh controls
                HStack {
                    Button("Refresh All Metrics") {
                        Task {
                            if let profile = awsManager.selectedProfile {
                                await cloudWatchManager.configureClient(for: profile)
                                await cloudWatchManager.fetchAllMetrics()
                            }
                        }
                    }
                    .disabled(awsManager.selectedProfile == nil || cloudWatchManager.isLoading)
                    
                    if cloudWatchManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    
                    Spacer()
                    
                    if let errorMessage = cloudWatchManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(2)
                    }
                }
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingAddMetric) {
            AddMetricSheet(cloudWatchManager: cloudWatchManager)
        }
        .sheet(item: $selectedMetric) { metric in
            EditMetricSheet(metric: metric, cloudWatchManager: cloudWatchManager)
        }
        .onAppear {
            if let profile = awsManager.selectedProfile {
                Task {
                    await cloudWatchManager.configureClient(for: profile)
                }
            }
        }
    }
}

struct CloudWatchMetricRow: View {
    let metric: CloudWatchMetric
    let latestData: CloudWatchMetricData?
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(metric.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(metric.namespace)/\(metric.metricName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !metric.dimensions.isEmpty {
                    Text("Dimensions: \(metric.dimensions.map { "\($0.name)=\($0.value)" }.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                if let data = latestData {
                    Text(formattedValue(data.value))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(data.unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(data.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("No data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Menu {
                Button("Edit") { onEdit() }
                Button("Delete", role: .destructive) { onDelete() }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func formattedValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

struct AddMetricSheet: View {
    @ObservedObject var cloudWatchManager: CloudWatchManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPreset: CloudWatchMetric?
    @State private var namespace = ""
    @State private var metricName = ""
    @State private var displayName = ""
    @State private var unit = "Count"
    @State private var statistic: CloudWatchMetric.MetricStatistic = .average
    @State private var dimensions: [CloudWatchMetric.MetricDimension] = []
    @State private var showingCustomForm = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add CloudWatch Metric")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !showingCustomForm {
                        // Preset metrics
                        Text("Common Metrics")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
                            ForEach(CloudWatchManager.commonMetrics, id: \.id) { metric in
                                Button(action: {
                                    selectedPreset = metric
                                    populateFromPreset(metric)
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(metric.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text("\(metric.namespace)/\(metric.metricName)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text(metric.statistic.displayName)
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(selectedPreset?.id == metric.id ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedPreset?.id == metric.id ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Divider()
                        
                        Button("Create Custom Metric") {
                            showingCustomForm = true
                        }
                        .buttonStyle(.bordered)
                    } else {
                        // Custom metric form
                        Text("Custom Metric")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Display Name")
                                    .font(.caption)
                                TextField("Display Name", text: $displayName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Namespace")
                                        .font(.caption)
                                    TextField("AWS/EC2", text: $namespace)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Metric Name")
                                        .font(.caption)
                                    TextField("CPUUtilization", text: $metricName)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Statistic")
                                        .font(.caption)
                                    Picker("Statistic", selection: $statistic) {
                                        ForEach(CloudWatchMetric.MetricStatistic.allCases, id: \.self) { stat in
                                            Text(stat.displayName).tag(stat)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Unit")
                                        .font(.caption)
                                    TextField("Count", text: $unit)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                        
                        Button("Use Common Metrics Instead") {
                            showingCustomForm = false
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Actions
            HStack {
                Spacer()
                
                Button("Add Metric") {
                    let metric = CloudWatchMetric(
                        namespace: namespace,
                        metricName: metricName,
                        dimensions: dimensions,
                        statistic: statistic,
                        displayName: displayName.isEmpty ? "\(namespace)/\(metricName)" : displayName,
                        unit: unit
                    )
                    cloudWatchManager.addMetric(metric)
                    dismiss()
                }
                .disabled(namespace.isEmpty || metricName.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }
    
    private func populateFromPreset(_ preset: CloudWatchMetric) {
        namespace = preset.namespace
        metricName = preset.metricName
        displayName = preset.displayName
        unit = preset.unit
        statistic = preset.statistic
        dimensions = preset.dimensions
    }
}

struct EditMetricSheet: View {
    let metric: CloudWatchMetric
    @ObservedObject var cloudWatchManager: CloudWatchManager
    @Environment(\.dismiss) var dismiss
    
    @State private var displayName: String
    @State private var unit: String
    @State private var statistic: CloudWatchMetric.MetricStatistic
    
    init(metric: CloudWatchMetric, cloudWatchManager: CloudWatchManager) {
        self.metric = metric
        self.cloudWatchManager = cloudWatchManager
        self._displayName = State(initialValue: metric.displayName)
        self._unit = State(initialValue: metric.unit)
        self._statistic = State(initialValue: metric.statistic)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Metric")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Metric Details")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("\(metric.namespace)/\(metric.metricName)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.caption)
                        TextField("Display Name", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Statistic")
                                .font(.caption)
                            Picker("Statistic", selection: $statistic) {
                                ForEach(CloudWatchMetric.MetricStatistic.allCases, id: \.self) { stat in
                                    Text(stat.displayName).tag(stat)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Unit")
                                .font(.caption)
                            TextField("Unit", text: $unit)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Actions
            HStack {
                Button("Delete Metric", role: .destructive) {
                    cloudWatchManager.removeMetric(metric)
                    dismiss()
                }
                
                Spacer()
                
                Button("Save Changes") {
                    let updatedMetric = CloudWatchMetric(
                        namespace: metric.namespace,
                        metricName: metric.metricName,
                        dimensions: metric.dimensions,
                        statistic: statistic,
                        displayName: displayName,
                        unit: unit
                    )
                    cloudWatchManager.updateMetric(updatedMetric)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
    }
}

struct TeamCacheSettingsTab: View {
    @EnvironmentObject var awsManager: AWSManager
    @StateObject private var storeManager = StoreManager.shared
    @State private var selectedProfile: AWSProfile?
    @State private var teamCacheEnabled: Bool = false
    @State private var s3BucketName: String = ""
    @State private var s3Region: String = "us-east-1"
    @State private var cachePrefix: String = "awscost-team-cache"
    @State private var isTestingConnection: Bool = false
    @State private var connectionTestResult: String?
    @State private var connectionTestIcon: String?
    @State private var connectionTestColor: Color = .secondary
    @State private var showingStats: Bool = false
    @State private var cacheStatistics: CacheStatistics?
    @State private var lastSyncTime: Date?
    
    // Available AWS regions for S3
    let availableRegions = [
        "us-east-1": "US East (N. Virginia)",
        "us-east-2": "US East (Ohio)",
        "us-west-1": "US West (N. California)",
        "us-west-2": "US West (Oregon)",
        "ap-south-1": "Asia Pacific (Mumbai)",
        "ap-northeast-1": "Asia Pacific (Tokyo)",
        "ap-northeast-2": "Asia Pacific (Seoul)",
        "ap-southeast-1": "Asia Pacific (Singapore)",
        "ap-southeast-2": "Asia Pacific (Sydney)",
        "ca-central-1": "Canada (Central)",
        "eu-central-1": "Europe (Frankfurt)",
        "eu-west-1": "Europe (Ireland)",
        "eu-west-2": "Europe (London)",
        "eu-west-3": "Europe (Paris)",
        "eu-north-1": "Europe (Stockholm)",
        "sa-east-1": "South America (São Paulo)"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            #if !OPENSOURCE
            // Debug toggle for testing purchase state
            #if DEBUG
            HStack {
                Text("DEBUG: Simulate Purchase")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { storeManager.hasTeamCache },
                    set: { newValue in
                        if newValue {
                            storeManager.simulateSuccessfulPurchase()
                        } else {
                            storeManager.clearPurchase()
                        }
                    }
                ))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(4)
            
            Divider()
            #endif
            
            // Check if user has Team Cache access
            if !storeManager.hasTeamCache {
                // Show purchase UI
                TeamCachePurchaseView()
                    .environmentObject(storeManager)
            } else {
                // Show Team Cache settings for users who purchased - fall through to show config
            }
            #endif  // !OPENSOURCE
            
            // Team Cache configuration (available in both versions)
                Text("Team Cache Configuration")
                    .font(.headline)
            
                if !awsManager.profiles.isEmpty {
                // Profile selector
                Picker("Select Profile:", selection: $selectedProfile) {
                    Text("Choose a profile").tag(nil as AWSProfile?)
                    ForEach(awsManager.profiles, id: \.self) { profile in
                        Text(profile.name).tag(Optional(profile))
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedProfile) { _, newProfile in
                    if let profile = newProfile {
                        loadTeamCacheSettings(for: profile)
                    }
                }
                
                if selectedProfile != nil {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Enable/Disable toggle
                        HStack {
                            Toggle("Enable team cache for this profile", isOn: $teamCacheEnabled)
                                .onChange(of: teamCacheEnabled) { _, _ in
                                    saveTeamCacheSettings()
                                }
                            
                            Spacer()
                            
                            // Status indicator
                            if teamCacheEnabled {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("Enabled")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            } else {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 8, height: 8)
                                    Text("Disabled")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        if teamCacheEnabled {
                            // S3 Configuration Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("S3 Bucket Configuration")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                // Bucket name
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("S3 Bucket Name")
                                        .font(.caption)
                                    MacTextField(
                                        placeholder: "my-team-cost-cache",
                                        text: $s3BucketName,
                                        onCommit: saveTeamCacheSettings
                                    )
                                    .frame(height: 22)
                                    .onChange(of: s3BucketName) { _, _ in
                                        saveTeamCacheSettings()
                                    }
                                    Text("Must be globally unique and accessible by all team members")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Region
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("S3 Region")
                                        .font(.caption)
                                    Picker("Region", selection: $s3Region) {
                                        ForEach(Array(availableRegions.keys.sorted()), id: \.self) { region in
                                            if let displayName = availableRegions[region] {
                                                Text("\(region) - \(displayName)").tag(region)
                                            }
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .onChange(of: s3Region) { _, _ in
                                        saveTeamCacheSettings()
                                    }
                                    Text("Choose region closest to your team")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Cache prefix
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Cache Prefix")
                                        .font(.caption)
                                    MacTextField(
                                        placeholder: "awscost-team-cache",
                                        text: $cachePrefix,
                                        onCommit: saveTeamCacheSettings
                                    )
                                    .frame(height: 22)
                                    .onChange(of: cachePrefix) { _, _ in
                                        saveTeamCacheSettings()
                                    }
                                    Text("Used to organize cache entries in the S3 bucket")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Connection test
                                HStack {
                                    Button(action: testConnection) {
                                        HStack(spacing: 6) {
                                            if isTestingConnection {
                                                ProgressView()
                                                    .scaleEffect(0.7)
                                                    .controlSize(.small)
                                            } else if let icon = connectionTestIcon {
                                                Image(systemName: icon)
                                                    .foregroundColor(connectionTestColor)
                                            }
                                            Text("Test Connection")
                                        }
                                    }
                                    .disabled(s3BucketName.isEmpty || isTestingConnection)
                                    .buttonStyle(.bordered)
                                    
                                    if let result = connectionTestResult {
                                        Text(result)
                                            .font(.caption)
                                            .foregroundColor(connectionTestColor)
                                            .lineLimit(2)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                            
                            // Cache Statistics Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Cache Statistics")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Button(showingStats ? "Hide Stats" : "Show Stats") {
                                        showingStats.toggle()
                                        if showingStats {
                                            loadCacheStatistics()
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                
                                if showingStats {
                                    if let stats = cacheStatistics {
                                        VStack(spacing: 8) {
                                            HStack {
                                                Text("Cache Entries:")
                                                Spacer()
                                                Text("\(stats.totalEntries)")
                                                    .monospacedDigit()
                                            }
                                            .font(.caption)
                                            
                                            HStack {
                                                Text("Cache Size:")
                                                Spacer()
                                                Text(formatBytes(stats.totalSizeBytes))
                                                    .monospacedDigit()
                                            }
                                            .font(.caption)
                                            
                                            HStack {
                                                Text("Hit Ratio:")
                                                Spacer()
                                                Text(String(format: "%.1f%%", stats.hitRatio * 100))
                                                    .monospacedDigit()
                                                    .foregroundColor(stats.hitRatio > 0.5 ? .green : .orange)
                                            }
                                            .font(.caption)
                                            
                                            HStack {
                                                Text("Hits/Misses:")
                                                Spacer()
                                                Text("\(stats.cacheHits)/\(stats.cacheMisses)")
                                                    .monospacedDigit()
                                            }
                                            .font(.caption)
                                            
                                            if stats.errors > 0 {
                                                HStack {
                                                    Text("Errors:")
                                                    Spacer()
                                                    Text("\(stats.errors)")
                                                        .monospacedDigit()
                                                        .foregroundColor(.red)
                                                }
                                                .font(.caption)
                                            }
                                            
                                            if let lastAccess = stats.lastAccessTime {
                                                HStack {
                                                    Text("Last Access:")
                                                    Spacer()
                                                    Text(lastAccess, style: .relative)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                .font(.caption)
                                            }
                                        }
                                    } else {
                                        HStack {
                                            ProgressView()
                                                .controlSize(.small)
                                            Text("Loading statistics...")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                            
                            // Force Refresh Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cache Management")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                HStack {
                                    Button("Force Refresh Cache") {
                                        forceRefreshCache()
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(!teamCacheEnabled || s3BucketName.isEmpty)
                                    
                                    Spacer()
                                    
                                    if let syncTime = lastSyncTime {
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("Last Sync:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(syncTime, style: .relative)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Text("Forces a fresh fetch from AWS API and updates the team cache")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Help and Setup Instructions
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                    Text("Setup Requirements")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• S3 bucket with read/write permissions for all team members")
                                        .font(.caption)
                                    Text("• IAM policy allowing s3:GetObject, s3:PutObject, s3:DeleteObject, s3:ListBucket")
                                        .font(.caption)
                                    Text("• All team members must use the same bucket name and region")
                                        .font(.caption)
                                    Text("• Cache entries are compressed and encrypted at rest")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                                
                                Button("View Setup Guide") {
                                    if let url = URL(string: "https://toml0006.github.io/AWSCostMonitor/team-cache-setup") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                                .buttonStyle(.link)
                                .font(.caption)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                } else {
                    Text("No AWS profiles available")
                        .foregroundColor(.secondary)
                }
            #if !OPENSOURCE
                // Pro access check was here
            #endif
            
            Spacer()
        }
        .onAppear {
            if selectedProfile == nil && !awsManager.profiles.isEmpty {
                selectedProfile = awsManager.selectedProfile ?? awsManager.profiles.first
                if let profile = selectedProfile {
                    loadTeamCacheSettings(for: profile)
                }
            }
        }
    }
    
    private func loadTeamCacheSettings(for profile: AWSProfile) {
        // Load team cache settings for the selected profile from UserDefaults
        let key = "TeamCacheConfig_\(profile.name)"
        
        if let data = UserDefaults.standard.data(forKey: key),
           let config = try? JSONDecoder().decode(TeamCacheConfig.self, from: data) {
            teamCacheEnabled = config.enabled
            s3BucketName = config.s3BucketName
            s3Region = config.s3Region
            cachePrefix = config.cachePrefix
        } else {
            // Use default values if no saved settings
            teamCacheEnabled = false
            s3BucketName = ""
            s3Region = "us-east-1"
            cachePrefix = "awscost-team-cache"
        }
        
        // Reset UI state
        connectionTestResult = nil
        connectionTestIcon = nil
        cacheStatistics = nil
        lastSyncTime = nil
    }
    
    private func saveTeamCacheSettings() {
        guard let profile = selectedProfile else { 
            awsManager.log(.warning, category: "TeamCache", "No profile selected when saving team cache settings")
            return 
        }
        
        // Create configuration object
        let config = TeamCacheConfig(
            enabled: teamCacheEnabled,
            s3BucketName: s3BucketName,
            s3Region: s3Region,
            cachePrefix: cachePrefix
        )
        
        // Create profile settings
        let profileSettings = ProfileTeamCacheSettings(
            teamCacheEnabled: teamCacheEnabled,
            teamCacheConfig: teamCacheEnabled ? config : nil
        )
        
        // Update AWSManager's settings
        awsManager.updateTeamCacheSettings(for: profile.name, settings: profileSettings)
        
        // Save to UserDefaults for persistence
        let key = "TeamCacheConfig_\(profile.name)"
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: key)
            awsManager.log(.info, category: "TeamCache", "Team cache settings saved for profile: \(profile.name) - Enabled: \(teamCacheEnabled), Bucket: \(s3BucketName), Prefix: \(cachePrefix)")
            
            // Re-initialize team cache services after settings change
            awsManager.initializeTeamCacheServices()
        } else {
            awsManager.log(.error, category: "TeamCache", "Failed to save team cache settings for profile: \(profile.name)")
        }
    }
    
    private func testConnection() {
        guard let profile = selectedProfile, !s3BucketName.isEmpty else { 
            connectionTestResult = "Please enter a bucket name"
            connectionTestIcon = "exclamationmark.circle.fill"
            connectionTestColor = .orange
            return 
        }
        
        isTestingConnection = true
        connectionTestResult = nil
        connectionTestIcon = nil
        
        Task {
            // First ensure settings are saved
            saveTeamCacheSettings()
            
            // Test the actual connection
            let success = await awsManager.testTeamCacheConnection(for: profile.name)
            
            await MainActor.run {
                if success {
                    connectionTestResult = "Connection successful!"
                    connectionTestIcon = "checkmark.circle.fill"
                    connectionTestColor = .green
                } else {
                    connectionTestResult = "Connection failed. Check bucket name and permissions."
                    connectionTestIcon = "xmark.circle.fill"
                    connectionTestColor = .red
                }
                
                isTestingConnection = false
            }
        }
    }
    
    private func loadCacheStatistics() {
        guard let profile = selectedProfile else { return }
        
        // Get real statistics from the team cache service if it exists
        if let cacheService = awsManager.teamCacheServices[profile.name] {
            let status = cacheService.getStatus()
            cacheStatistics = status.statistics
            
            // Get last sync time from the cache status
            if let cacheEntry = awsManager.costCache[profile.name] {
                lastSyncTime = cacheEntry.fetchDate
            }
            
            awsManager.log(.debug, category: "TeamCache", "Loaded cache statistics for profile \(profile.name): Hits=\(status.statistics.cacheHits), Misses=\(status.statistics.cacheMisses)")
        } else {
            // No cache service for this profile, show empty stats
            cacheStatistics = CacheStatistics()
            lastSyncTime = nil
            awsManager.log(.debug, category: "TeamCache", "No cache service found for profile \(profile.name)")
        }
    }
    
    private func forceRefreshCache() {
        guard let profile = selectedProfile, teamCacheEnabled else { return }
        
        lastSyncTime = Date()
        
        Task {
            // TODO: Implement force refresh with team cache
            await awsManager.fetchCostForSelectedProfile(force: true)
            awsManager.log(.info, category: "TeamCache", "Force refresh completed for profile: \(profile.name)")
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct ProfileVisibilitySection: View {
    @EnvironmentObject var awsManager: AWSManager
    @State private var profileVisibilitySettings: [String: Bool] = [:]
    @State private var showingRemovedProfiles = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose which AWS profiles appear in the dropdown menus.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Show all profiles including demo
            let allProfiles = awsManager.realProfiles + awsManager.demoProfiles
            
            if !allProfiles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Profiles")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    // Single column with regions in second column
                    VStack(spacing: 8) {
                        ForEach(allProfiles, id: \.name) { profile in
                            HStack {
                                Toggle(isOn: Binding(
                                    get: { 
                                        // Demo profile (acme) is disabled by default
                                        if profile.name == "acme" {
                                            return profileVisibilitySettings[profile.name] ?? false
                                        }
                                        return profileVisibilitySettings[profile.name] ?? true
                                    },
                                    set: { isVisible in
                                        profileVisibilitySettings[profile.name] = isVisible
                                        updateProfileVisibility(profile.name, isVisible: isVisible)
                                    }
                                )) {
                                    HStack(spacing: 4) {
                                        Text(profile.name)
                                            .font(.body)
                                            .frame(minWidth: 150, alignment: .leading)
                                        if profile.name == "acme" {
                                            Text("(demo)")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                // Region in second column
                                if let region = profile.region {
                                    Text(region)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(minWidth: 100, alignment: .trailing)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.05))
                            )
                        }
                    }
                }
            }
            
            // Show removed profiles section if any exist
            let profileManager = awsManager.getProfileManager()
            let settings = profileManager.loadSettings()
            if !settings.removedProfiles.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Removed Profiles")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(showingRemovedProfiles ? "Hide" : "Show") {
                            showingRemovedProfiles.toggle()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    if showingRemovedProfiles {
                        Text("These profiles are no longer in your AWS configuration but data is preserved.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(Array(settings.removedProfiles.keys.sorted()), id: \.self) { profileName in
                            if let info = settings.removedProfiles[profileName] {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(profileName) (removed)")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                        Text("Last seen: \(info.lastSeenDate, style: .date)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("Show in dropdown", isOn: Binding(
                                        get: { info.preserveData },
                                        set: { shouldShow in
                                            // Update the removed profile visibility
                                            toggleRemovedProfileVisibility(profileName, shouldShow: shouldShow)
                                        }
                                    ))
                                    .controlSize(.mini)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            
            // Information about profile management
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Profile Management")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("New profiles are automatically detected and you'll be prompted to add them. Hidden profiles can be re-enabled here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
        }
        .onAppear {
            loadProfileVisibilitySettings()
        }
    }
    
    private func loadProfileVisibilitySettings() {
        let profileManager = awsManager.getProfileManager()
        let settings = profileManager.loadSettings()
        
        // Initialize visibility settings for all profiles including demo
        let allProfiles = awsManager.realProfiles + awsManager.demoProfiles
        
        for profile in allProfiles {
            // Demo profile (acme) is disabled by default
            if profile.name == "acme" {
                if settings.visibleProfiles.isEmpty && settings.hiddenProfiles.isEmpty {
                    profileVisibilitySettings[profile.name] = false
                } else {
                    profileVisibilitySettings[profile.name] = settings.visibleProfiles.contains(profile.name)
                }
            } else {
                // Regular profiles - default to visible
                if settings.visibleProfiles.isEmpty && settings.hiddenProfiles.isEmpty {
                    profileVisibilitySettings[profile.name] = true
                } else {
                    profileVisibilitySettings[profile.name] = settings.visibleProfiles.contains(profile.name)
                }
            }
        }
    }
    
    private func updateProfileVisibility(_ profileName: String, isVisible: Bool) {
        let profileManager = awsManager.getProfileManager()
        profileManager.toggleProfileVisibility(profileName, isVisible: isVisible)
        awsManager.updateProfileVisibility()
    }
    
    private func toggleRemovedProfileVisibility(_ profileName: String, shouldShow: Bool) {
        let profileManager = awsManager.getProfileManager()
        profileManager.markProfilesAsRemoved([profileName], preserveData: shouldShow)
        awsManager.updateProfileVisibility()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AWSManager())
}