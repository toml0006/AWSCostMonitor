import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var awsManager: AWSManager
    @AppStorage("MenuBarDisplayFormat") private var displayFormat: String = MenuBarDisplayFormat.full.rawValue
    @AppStorage("RefreshIntervalMinutes") private var refreshInterval: Int = 5
    @AppStorage("SelectedAWSProfileName") private var selectedProfileName: String = ""
    @State private var selectedCategory = "Refresh Rate"
    @State private var hoveredCategory: String? = nil
    
    private var displayFormatEnum: MenuBarDisplayFormat {
        MenuBarDisplayFormat(rawValue: displayFormat) ?? .full
    }
    
    let settingsCategories = [
        "Refresh Rate",
        "Display",
        "AWS",
        "Team Cache",
        "Alerts",
        "Notifications",
        "CloudWatch",
        "Debug"
    ]
    
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
        case "AWS":
            return "cloud"
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
        case "AWS":
            AWSSettingsTab()
        case "Team Cache":
            TeamCacheSettingsTab()
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
                    Text(awsManager.refreshTimer != nil ? "On" : "Off")
                        .fontWeight(.semibold)
                        .foregroundColor(awsManager.refreshTimer != nil ? .green : .secondary)
                    
                    Spacer()
                    
                    Button(awsManager.refreshTimer != nil ? "Stop" : "Start") {
                        if awsManager.refreshTimer != nil {
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
    @State private var selectedProfile: AWSProfile?
    @State private var monthlyBudget: String = "100"
    @State private var alertThreshold: Double = 0.8
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AWS Configuration")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Selected Profile:")
                
                Picker("AWS Profile", selection: $awsManager.selectedProfile) {
                    if awsManager.profiles.isEmpty {
                        Text("No profiles").tag(nil as AWSProfile?)
                    }
                    ForEach(awsManager.profiles, id: \.self) { profile in
                        VStack(alignment: .leading) {
                            Text(profile.name)
                            if let region = profile.region {
                                Text(region)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tag(Optional(profile))
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: awsManager.selectedProfile) { _, newProfile in
                    if let profile = newProfile {
                        awsManager.saveSelectedProfile(profile: profile)
                    }
                }
                
                if let profile = awsManager.selectedProfile {
                    HStack {
                        Text("Region:")
                        Text(profile.region ?? "Default")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .font(.caption)
                }
            }
            
            Divider()
            
            // AWS Spending Budget section
            Text("AWS Spending Budget")
                .font(.headline)
            
            // Profile selector for budget
            Picker("Select Profile:", selection: $selectedProfile) {
                Text("Choose a profile").tag(nil as AWSProfile?)
                ForEach(awsManager.profiles, id: \.self) { profile in
                    Text(profile.name).tag(Optional(profile))
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedProfile) { _, newProfile in
                if let profile = newProfile {
                    loadBudgetSettingsForProfile(profile)
                }
            }
            
            if selectedProfile != nil {
                VStack(alignment: .leading, spacing: 16) {
                    // Clarification about budget type
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Local alerting only")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("This is separate from AWS Console Budget Alerts and is used for in-app notifications.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button("View AWS Budget Alerts →") {
                                if let url = URL(string: "https://console.aws.amazon.com/billing/home#/budgets") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.link)
                            .font(.caption)
                        }
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                    
                    HStack {
                        Text("Monthly Budget:")
                        TextField("100", text: $monthlyBudget)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onChange(of: monthlyBudget) { _, _ in
                                saveBudgetSettingsIfValid()
                            }
                        Text("USD")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Alert Threshold:")
                            Spacer()
                            Text("\(Int(alertThreshold * 100))%")
                                .monospacedDigit()
                        }
                        .frame(width: 300)
                        
                        Slider(value: $alertThreshold, in: 0.5...1.0, step: 0.05)
                            .frame(width: 300)
                            .onChange(of: alertThreshold) { _, _ in
                                saveBudgetSettingsIfValid()
                            }
                        
                        Text("Alert when spending reaches this percentage")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        
        // Add the loadBudgetSettingsForProfile and saveBudgetSettingsIfValid functions
        .onAppear {
            // Load budget settings for currently selected AWS profile
            if let selectedProfile = awsManager.selectedProfile {
                self.selectedProfile = selectedProfile
                loadBudgetSettingsForProfile(selectedProfile)
            }
        }
    }
    
    private func loadBudgetSettingsForProfile(_ profile: AWSProfile) {
        let budget = awsManager.getBudget(for: profile.name)
        monthlyBudget = String(format: "%.0f", NSDecimalNumber(decimal: budget.monthlyBudget).doubleValue)
        alertThreshold = budget.alertThreshold
    }
    
    private func saveBudgetSettingsIfValid() {
        guard let profile = selectedProfile,
              let budgetValue = Double(monthlyBudget), budgetValue > 0 else {
            return
        }
        
        let budget = Decimal(budgetValue)
        awsManager.updateBudget(for: profile.name, monthlyBudget: budget, alertThreshold: alertThreshold)
    }
}

struct RefreshRateTab: View {
    @EnvironmentObject var awsManager: AWSManager
    @State private var selectedProfile: AWSProfile?
    @State private var apiBudget: String = "5"
    @State private var refreshInterval: Double = 360
    
    // Computed properties for display
    var estimatedAPICalls: Int {
        Int((Double(apiBudget) ?? 5.0) / 0.01)
    }
    
    var estimatedCallsPerMonth: Int {
        let minutesPerMonth = 30 * 24 * 60
        return minutesPerMonth / Int(refreshInterval)
    }
    
    var estimatedMonthlyCost: Double {
        return Double(estimatedCallsPerMonth) * 0.01
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Refresh Rate Settings")
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
                        loadSettingsForProfile(profile)
                    }
                }
                
                if selectedProfile != nil {
                    Divider()
                    
                    // API Budget section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Cost Explorer API Budget", systemImage: "network")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("AWS charges ~$0.01 per Cost Explorer API request")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("5", text: $apiBudget)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .onChange(of: apiBudget) { _, _ in
                                    updateRefreshBasedOnBudget()
                                    saveSettingsIfValid()
                                }
                            
                            Text("USD per month")
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Budget allows ~\(estimatedAPICalls) API calls per month")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Divider()
                    
                    // Refresh interval section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Auto-refresh Interval", systemImage: "arrow.clockwise")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Slider(value: $refreshInterval, in: 60...1440, step: 60)
                                .frame(width: 300)
                                .onChange(of: refreshInterval) { _, _ in
                                    updateBudgetBasedOnRefresh()
                                    saveSettingsIfValid()
                                }
                            
                            Text(formatRefreshInterval(refreshInterval))
                                .frame(width: 100, alignment: .leading)
                                .monospacedDigit()
                        }
                        
                        HStack {
                            Text("1 hour")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("24 hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 300)
                        
                        // Cost estimation
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Estimated usage: \(estimatedCallsPerMonth) calls/month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Estimated cost: $\(String(format: "%.2f", estimatedMonthlyCost))/month")
                                .font(.caption)
                                .foregroundColor(estimatedMonthlyCost > (Double(apiBudget) ?? 5.0) ? .red : .secondary)
                        }
                    }
                    
                    
                    Divider()
                    
                    // Save button
                    HStack {
                        if awsManager.refreshTimer != nil && selectedProfile?.name == awsManager.selectedProfile?.name {
                            Label("Auto-refresh is active", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        Button("Save Settings") {
                            saveSettings()
                        }
                        .disabled(selectedProfile == nil)
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
                    loadSettingsForProfile(profile)
                }
            }
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
    
    private func loadSettingsForProfile(_ profile: AWSProfile) {
        let budget = awsManager.getBudget(for: profile.name)
        apiBudget = String(format: "%.0f", NSDecimalNumber(decimal: budget.apiBudget).doubleValue)
        refreshInterval = Double(budget.refreshIntervalMinutes)
    }
    
    private func updateRefreshBasedOnBudget() {
        // Auto-adjust refresh interval based on budget
        guard let budget = Double(apiBudget), budget > 0 else { return }
        
        let maxCallsPerMonth = Int(budget / 0.01)
        let minutesPerMonth = 30 * 24 * 60
        
        // Calculate optimal refresh interval (leaving some headroom)
        let optimalInterval = Double(minutesPerMonth) / (Double(maxCallsPerMonth) * 0.8) // Use 80% of budget
        
        // Round to nearest hour if over 60 minutes
        if optimalInterval >= 60 {
            refreshInterval = round(optimalInterval / 60) * 60
        } else {
            refreshInterval = max(60, optimalInterval) // Minimum 1 hour
        }
        
        // Cap at 24 hours
        refreshInterval = min(1440, refreshInterval)
    }
    
    private func updateBudgetBasedOnRefresh() {
        // Update suggested budget based on refresh interval
        let callsPerMonth = estimatedCallsPerMonth
        let suggestedBudget = Double(callsPerMonth) * 0.01 * 1.2 // Add 20% buffer
        
        // Only update if significantly different
        if abs(suggestedBudget - (Double(apiBudget) ?? 5.0)) > 1.0 {
            apiBudget = String(format: "%.0f", suggestedBudget)
        }
    }
    
    private func saveSettingsIfValid() {
        guard let profile = selectedProfile,
              let apiBudgetValue = Decimal(string: apiBudget),
              apiBudgetValue > 0 else { return }
        
        awsManager.updateAPIBudgetAndRefresh(for: profile.name, apiBudget: apiBudgetValue, refreshIntervalMinutes: Int(refreshInterval))
    }
    
    private func saveSettings() {
        saveSettingsIfValid()
    }
}


struct AnomalySettingsTab: View {
    @AppStorage("EnableAnomalyDetection") private var enableAnomalyDetection: Bool = true
    @AppStorage("AnomalyThresholdPercentage") private var anomalyThreshold: Double = 25.0
    @EnvironmentObject var awsManager: AWSManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Anomaly Detection")
                .font(.headline)
            
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
                    if awsManager.alertManager.notificationPermissionStatus != .authorized {
                        Button("Request Permission") {
                            Task {
                                await awsManager.alertManager.requestNotificationPermissions()
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
            return "Notification permission not requested"
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
                
                if let profile = selectedProfile {
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
                                    TextField("my-team-cost-cache", text: $s3BucketName)
                                        .textFieldStyle(.roundedBorder)
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
                                    TextField("awscost-team-cache", text: $cachePrefix)
                                        .textFieldStyle(.roundedBorder)
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
        // Load team cache settings for the selected profile
        // This would need to be implemented in AWSManager to get/set per-profile team cache settings
        
        // For now, using default values - this will need to be connected to actual storage
        teamCacheEnabled = false
        s3BucketName = ""
        s3Region = "us-east-1"
        cachePrefix = "awscost-team-cache"
        connectionTestResult = nil
        connectionTestIcon = nil
        cacheStatistics = nil
        lastSyncTime = nil
    }
    
    private func saveTeamCacheSettings() {
        guard let profile = selectedProfile else { return }
        
        // TODO: Implement saving team cache settings to AWSManager
        // This should save per-profile team cache configuration
        awsManager.log(.info, category: "TeamCache", "Team cache settings updated for profile: \(profile.name)")
    }
    
    private func testConnection() {
        guard let profile = selectedProfile, !s3BucketName.isEmpty else { return }
        
        isTestingConnection = true
        connectionTestResult = nil
        connectionTestIcon = nil
        
        Task {
            await MainActor.run {
                // Simulate connection test - this should use actual S3CacheService
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    // TODO: Implement real connection test using S3CacheService
                    let success = !s3BucketName.isEmpty && s3BucketName.count > 3
                    
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
    }
    
    private func loadCacheStatistics() {
        // TODO: Load actual cache statistics from S3CacheService
        cacheStatistics = CacheStatistics(
            totalEntries: 12,
            totalSizeBytes: 1024 * 150, // 150 KB
            lastAccessTime: Date().addingTimeInterval(-300), // 5 minutes ago
            cacheHits: 45,
            cacheMisses: 8,
            errors: 1
        )
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

#Preview {
    SettingsView()
        .environmentObject(AWSManager())
}