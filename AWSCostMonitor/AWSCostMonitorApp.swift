import SwiftUI
import AWSCostExplorer
import AWSClientRuntime
import AWSSTS
import AWSSDKIdentity
import Foundation

// MARK: - AWS Configuration & Data Models

// A simple structure to hold the parsed AWS profile data.
struct AWSProfile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let region: String?
}

// A structure to hold the cost data for a single profile.
struct CostData: Identifiable, Equatable {
    let id = UUID()
    let profileName: String
    let amount: Decimal
    let currency: String
}

// MARK: - Display Format Configuration

// Enum defining the different menu bar display formats
enum MenuBarDisplayFormat: String, CaseIterable {
    case full = "full"
    case abbreviated = "abbreviated"
    case iconOnly = "iconOnly"
    
    var displayName: String {
        switch self {
        case .full:
            return "Full ($123.45)"
        case .abbreviated:
            return "Abbreviated ($123)"
        case .iconOnly:
            return "Icon Only"
        }
    }
}

// Service to handle cost display formatting
class CostDisplayFormatter {
    static func format(amount: Decimal, currency: String, format: MenuBarDisplayFormat) -> String {
        switch format {
        case .full:
            // Full format: $123.45
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currency
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
            
        case .abbreviated:
            // Abbreviated format: $123 (rounded to nearest dollar)
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currency
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
            return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0"
            
        case .iconOnly:
            // Icon only: empty string (the icon is shown by the MenuBarExtra)
            return ""
        }
    }
    
    // Preview helper for settings UI
    static func previewText(for format: MenuBarDisplayFormat) -> String {
        switch format {
        case .full:
            return "$123.45"
        case .abbreviated:
            return "$123"
        case .iconOnly:
            return "(icon only)"
        }
    }
}

// MARK: - INI File Parser
// A simple, self-contained parser for INI-formatted files like ~/.aws/config
// This is necessary to list all available profiles.
class INIParser {
    static func parse(filePath: String) -> [String: [String: String]] {
        var profiles = [String: [String: String]]()
        var currentProfileName: String?
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            let lines = content.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            for line in lines {
                if line.isEmpty || line.hasPrefix("#") {
                    continue
                }

                if line.hasPrefix("[profile ") && line.hasSuffix("]") {
                    let name = String(line.dropFirst(9).dropLast(1))
                    currentProfileName = name
                    profiles[name] = [String: String]()
                } else if line.hasPrefix("[") && line.hasSuffix("]") {
                    let name = String(line.dropFirst().dropLast())
                    currentProfileName = name
                    profiles[name] = [String: String]()
                } else if let currentName = currentProfileName {
                    let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                    if parts.count == 2 {
                        profiles[currentName]?[String(parts[0])] = String(parts[1])
                    }
                }
            }
        } catch {
            print("Error reading or parsing INI file: \(error.localizedDescription)")
        }
        return profiles
    }
}

// MARK: - AWS Manager
// This class handles all the AWS SDK logic.
class AWSManager: ObservableObject {
    @Published var profiles: [AWSProfile] = []
    @Published var selectedProfile: AWSProfile?
    @Published var costData: [CostData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var displayFormat: MenuBarDisplayFormat = .full
    
    // Keys for UserDefaults
    private let selectedProfileKey = "SelectedAWSProfileName"
    private let displayFormatKey = "MenuBarDisplayFormat"

    init() {
        print("DEBUG: AWSManager init called")
        // Load profiles on initialization
        loadProfiles()
        print("DEBUG: After loadProfiles, count: \(profiles.count)")
        // Load the stored user preference for the selected profile
        loadSelectedProfile()
        print("DEBUG: After loadSelectedProfile, selected: \(selectedProfile?.name ?? "none")")
        // Load the display format preference
        loadDisplayFormat()
        print("DEBUG: Display format loaded: \(displayFormat.rawValue)")
    }
    
    // Function to find the AWS config file and parse profiles.
    func loadProfiles() {
        print("DEBUG: loadProfiles() called")
        // Construct the path to the AWS config file
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let awsConfigPath = (homeDir as NSString).appendingPathComponent(".aws/config")
        print("DEBUG: Looking for config at: \(awsConfigPath)")
        
        guard FileManager.default.fileExists(atPath: awsConfigPath) else {
            errorMessage = "AWS config file not found at \(awsConfigPath)"
            return
        }
        
        let parsedProfiles = INIParser.parse(filePath: awsConfigPath)
        print("DEBUG: Parsed profiles from config: \(parsedProfiles.keys.sorted())")
        print("DEBUG: Full parsed data: \(parsedProfiles)")
        
        // Populate the profiles array from the parsed data.
        self.profiles = parsedProfiles.keys.map { profileName in
            let profileConfig = parsedProfiles[profileName]
            let region = profileConfig?["region"]
            return AWSProfile(name: profileName, region: region)
        }.sorted { $0.name < $1.name }
        
        print("DEBUG: Created \(self.profiles.count) profile objects")
        for profile in self.profiles {
            print("DEBUG: Profile: \(profile.name), Region: \(profile.region ?? "none")")
        }
        
        if self.profiles.isEmpty {
            errorMessage = "No AWS profiles found in config file."
        }
    }
    
    // Loads the selected profile name from UserDefaults.
    func loadSelectedProfile() {
        if let storedProfileName = UserDefaults.standard.string(forKey: selectedProfileKey) {
            // Find the profile object corresponding to the stored name
            self.selectedProfile = self.profiles.first { $0.name == storedProfileName }
        } else {
            // If no profile is stored, default to the first one if available.
            self.selectedProfile = self.profiles.first
        }
    }
    
    // Saves the selected profile name to UserDefaults.
    func saveSelectedProfile(profile: AWSProfile) {
        UserDefaults.standard.set(profile.name, forKey: selectedProfileKey)
    }
    
    // Loads the display format preference from UserDefaults.
    func loadDisplayFormat() {
        if let storedFormat = UserDefaults.standard.string(forKey: displayFormatKey),
           let format = MenuBarDisplayFormat(rawValue: storedFormat) {
            self.displayFormat = format
        } else {
            // Default to full format if not set
            self.displayFormat = .full
        }
    }
    
    // Saves the display format preference to UserDefaults.
    func saveDisplayFormat(_ format: MenuBarDisplayFormat) {
        UserDefaults.standard.set(format.rawValue, forKey: displayFormatKey)
        self.displayFormat = format
    }
    
    // Asynchronously fetches MTD cost for the selected profile.
    func fetchCostForSelectedProfile() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.costData = []
        }
        
        guard let profile = selectedProfile else {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "No profile selected."
            }
            return
        }
        
        do {
            // Configure AWS credentials provider to use the specific profile
            let credentialsProvider = try ProfileAWSCredentialIdentityResolver(
                profileName: profile.name
            )
            
            let config = try await CostExplorerClient.CostExplorerClientConfiguration(
                awsCredentialIdentityResolver: credentialsProvider,
                region: profile.region ?? "us-east-1"
            )
            let client = CostExplorerClient(config: config)
            
            let calendar = Calendar.current
            let now = Date()
            
            // Start date is the beginning of the current month
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            
            // End date is the beginning of the next day (exclusive, so it includes today)
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: now)!
            
            // Corrected: Use a simple DateFormatter for the API call
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let input = GetCostAndUsageInput(
                granularity: .monthly,
                // Corrected: Use string value for metrics
                metrics: ["UnblendedCost"],
                timePeriod: .init(
                    end: dateFormatter.string(from: endOfToday),
                    start: dateFormatter.string(from: startOfMonth)
                )
            )
            
            let output = try await client.getCostAndUsage(input: input)
            
            if let resultByTime = output.resultsByTime?.first,
               let total = resultByTime.total,
               let unblendedCost = total["UnblendedCost"],
               let amountString = unblendedCost.amount,
               let currency = unblendedCost.unit,
               let amount = Decimal(string: amountString) {
                
                await MainActor.run {
                    self.costData.append(CostData(
                        profileName: profile.name,
                        amount: amount,
                        currency: currency
                    ))
                }
            }
        } catch {
            await MainActor.run {
                print("Error fetching cost for profile \(profile.name): \(error.localizedDescription)")
                self.errorMessage = "Failed to fetch cost for profile \(profile.name)."
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
}

// MARK: - SwiftUI View

struct ContentView: View {
    @EnvironmentObject var awsManager: AWSManager
    
    var body: some View {
        let _ = print("DEBUG: ContentView body called, profiles count: \(awsManager.profiles.count)")
        VStack(alignment: .leading, spacing: 10) {
            Text("AWS MTD Spend")
                .font(.headline)
                .padding(.bottom, 5)

            // Profile Selection Picker
            Picker("Profile", selection: $awsManager.selectedProfile) {
                if awsManager.profiles.isEmpty {
                    Text("No profiles").tag(nil as AWSProfile?)
                }
                ForEach(awsManager.profiles, id: \.self) { profile in
                    Text(profile.name)
                        .tag(Optional(profile))
                }
            }
            .pickerStyle(.menu)
            .onChange(of: awsManager.selectedProfile) { _, newValue in
                if let newProfile = newValue {
                    // Save the new selection to UserDefaults and fetch cost
                    awsManager.saveSelectedProfile(profile: newProfile)
                    Task { await awsManager.fetchCostForSelectedProfile() }
                }
            }
            .padding(.horizontal, -8) // Adjust padding to align with other content
            
            Divider()
            
            // Display cost for the selected profile
            if awsManager.isLoading {
                HStack {
                    ProgressView()
                    Text("Fetching costs...")
                }
            } else if let errorMessage = awsManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else if let cost = awsManager.costData.first {
                HStack {
                    Text(cost.profileName)
                        .font(.system(.body, design: .monospaced))
                    Spacer()
                    // Fixed: Convert Decimal to Double for string formatting
                    Text(String(format: "%.2f", NSDecimalNumber(decimal: cost.amount).doubleValue))
                        .fontWeight(.bold)
                    Text(cost.currency)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No cost data available. Select a profile and refresh.")
                    .foregroundColor(.secondary)
            }

            Divider()
            
            Button("Refresh") {
                Task {
                    await awsManager.fetchCostForSelectedProfile()
                }
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            // Settings Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Format")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                ForEach(MenuBarDisplayFormat.allCases, id: \.self) { format in
                    HStack {
                        Image(systemName: awsManager.displayFormat == format ? "circle.inset.filled" : "circle")
                            .foregroundColor(awsManager.displayFormat == format ? .accentColor : .secondary)
                            .onTapGesture {
                                awsManager.saveDisplayFormat(format)
                            }
                        
                        Text(format.displayName)
                            .onTapGesture {
                                awsManager.saveDisplayFormat(format)
                            }
                        
                        Spacer()
                        
                        Text(CostDisplayFormatter.previewText(for: format))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        awsManager.saveDisplayFormat(format)
                    }
                }
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            // Initial cost fetch for the loaded/default profile
            Task {
                await awsManager.fetchCostForSelectedProfile()
            }
        }
    }
}

// MARK: - Main App Entry Point

@main
struct AWSCostMonitorApp: App {
    @StateObject private var awsManager = AWSManager()
    
    var menuBarTitle: String {
        if let cost = awsManager.costData.first {
            let formattedCost = CostDisplayFormatter.format(
                amount: cost.amount,
                currency: cost.currency,
                format: awsManager.displayFormat
            )
            return awsManager.displayFormat == .iconOnly ? "" : formattedCost
        } else if awsManager.isLoading {
            return "Loading..."
        } else {
            return awsManager.displayFormat == .iconOnly ? "" : "AWS"
        }
    }
    
    var body: some Scene {
        MenuBarExtra(menuBarTitle, systemImage: "dollarsign.circle.fill") {
            ContentView()
                .environmentObject(awsManager)
        }
        .onChange(of: awsManager.costData) { _, _ in
            // Force menu bar update when cost data changes
        }
        .onChange(of: awsManager.displayFormat) { _, _ in
            // Force menu bar update when display format changes
        }
    }
}
