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

#Preview {
    SettingsView()
        .environmentObject(AWSManager())
}