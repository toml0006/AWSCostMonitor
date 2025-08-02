import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var awsManager: AWSManager
    @AppStorage("MenuBarDisplayFormat") private var displayFormat: String = MenuBarDisplayFormat.full.rawValue
    @AppStorage("RefreshIntervalMinutes") private var refreshInterval: Int = 5
    @AppStorage("SelectedAWSProfileName") private var selectedProfileName: String = ""
    
    private var displayFormatEnum: MenuBarDisplayFormat {
        MenuBarDisplayFormat(rawValue: displayFormat) ?? .full
    }
    
    var body: some View {
        TabView {
            DisplaySettingsTab(
                displayFormat: Binding(
                    get: { displayFormatEnum },
                    set: { newFormat in
                        displayFormat = newFormat.rawValue
                        awsManager.saveDisplayFormat(newFormat)
                    }
                )
            )
            .tabItem {
                Label("Display", systemImage: "textformat")
            }
            
            RefreshSettingsTab(
                refreshInterval: Binding(
                    get: { refreshInterval },
                    set: { newInterval in
                        refreshInterval = newInterval
                        awsManager.updateRefreshInterval(newInterval)
                    }
                )
            )
            .tabItem {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            
            AWSSettingsTab()
            .tabItem {
                Label("AWS", systemImage: "cloud")
            }
            
            BudgetSettingsTab()
            .tabItem {
                Label("Budget", systemImage: "dollarsign.circle")
            }
        }
        .frame(width: 400, height: 300)
        .onAppear {
            // Sync @AppStorage values with AWSManager on appear
            syncSettingsWithManager()
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
        .padding()
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
        .padding()
    }
}

struct AWSSettingsTab: View {
    @EnvironmentObject var awsManager: AWSManager
    
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
            
            Spacer()
        }
        .padding()
    }
}

struct BudgetSettingsTab: View {
    @EnvironmentObject var awsManager: AWSManager
    @State private var selectedProfile: AWSProfile?
    @State private var monthlyBudget: String = "100"
    @State private var alertThreshold: Double = 0.8
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Budget Configuration")
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
                        loadBudgetForProfile(profile)
                    }
                }
                
                if selectedProfile != nil {
                    Divider()
                    
                    // Budget amount
                    HStack {
                        Text("Monthly Budget:")
                        TextField("Budget", text: $monthlyBudget)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text("USD")
                    }
                    
                    // Alert threshold
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Alert Threshold:")
                        HStack {
                            Slider(value: $alertThreshold, in: 0.5...1.0, step: 0.05)
                                .frame(width: 200)
                            Text("\(Int(alertThreshold * 100))%")
                                .frame(width: 50, alignment: .leading)
                        }
                        Text("Alert when spending reaches this percentage of budget")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Save button
                    HStack {
                        Spacer()
                        Button("Save Budget") {
                            saveBudget()
                        }
                        .disabled(selectedProfile == nil)
                    }
                    
                    // Current status if data available
                    if let profile = selectedProfile,
                       let cost = awsManager.costData.first(where: { $0.profileName == profile.name }) {
                        Divider()
                        
                        let budget = awsManager.getBudget(for: profile.name)
                        let status = awsManager.calculateBudgetStatus(cost: cost.amount, budget: budget)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Status")
                                .font(.headline)
                            
                            HStack {
                                Text("Spending:")
                                Text(String(format: "%.1f%% of budget", status.percentage * 100))
                                    .foregroundColor(status.isOverBudget ? .red : (status.isNearThreshold ? .orange : .green))
                                    .fontWeight(.semibold)
                            }
                            
                            if status.isOverBudget {
                                Label("Over budget!", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                            } else if status.isNearThreshold {
                                Label("Approaching budget limit", systemImage: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
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
        .padding()
        .onAppear {
            if selectedProfile == nil && !awsManager.profiles.isEmpty {
                selectedProfile = awsManager.selectedProfile ?? awsManager.profiles.first
                if let profile = selectedProfile {
                    loadBudgetForProfile(profile)
                }
            }
        }
    }
    
    private func loadBudgetForProfile(_ profile: AWSProfile) {
        let budget = awsManager.getBudget(for: profile.name)
        monthlyBudget = String(format: "%.0f", NSDecimalNumber(decimal: budget.monthlyBudget).doubleValue)
        alertThreshold = budget.alertThreshold
    }
    
    private func saveBudget() {
        guard let profile = selectedProfile,
              let budgetValue = Decimal(string: monthlyBudget) else { return }
        
        awsManager.updateBudget(for: profile.name, monthlyBudget: budgetValue, alertThreshold: alertThreshold)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AWSManager())
}