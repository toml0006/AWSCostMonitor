import SwiftUI
import AWSCostExplorer
import AWSClientRuntime
import AWSSTS
import AWSSDKIdentity
import Foundation

// MARK: - Extensions

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - AWS Configuration & Data Models

// A simple structure to hold the parsed AWS profile data.
struct AWSProfile: Identifiable, Hashable, Codable {
    let id = UUID()
    let name: String
    let region: String?
    
    // Make it Codable for storage
    enum CodingKeys: String, CodingKey {
        case name, region
    }
}

// A structure to hold the cost data for a single profile.
struct CostData: Identifiable, Equatable {
    let id = UUID()
    let profileName: String
    let amount: Decimal
    let currency: String
}

// Budget configuration for each profile
struct ProfileBudget: Codable, Identifiable {
    let id = UUID()
    let profileName: String
    var monthlyBudget: Decimal
    var alertThreshold: Double // Percentage (0.0 - 1.0)
    
    enum CodingKeys: String, CodingKey {
        case profileName, monthlyBudget, alertThreshold
    }
    
    init(profileName: String, monthlyBudget: Decimal = 100.0, alertThreshold: Double = 0.8) {
        self.profileName = profileName
        self.monthlyBudget = monthlyBudget
        self.alertThreshold = alertThreshold
    }
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
    static func format(
        amount: Decimal,
        currency: String,
        format: MenuBarDisplayFormat,
        showCurrencySymbol: Bool = true,
        decimalPlaces: Int = 2,
        useThousandsSeparator: Bool = true
    ) -> String {
        switch format {
        case .full:
            // Full format with customizable options
            let formatter = NumberFormatter()
            formatter.numberStyle = showCurrencySymbol ? .currency : .decimal
            formatter.currencyCode = currency
            formatter.maximumFractionDigits = decimalPlaces
            formatter.minimumFractionDigits = decimalPlaces
            formatter.usesGroupingSeparator = useThousandsSeparator
            
            let formattedAmount = formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0"
            
            // If not showing currency symbol but we used decimal style, prepend the symbol manually if needed
            if !showCurrencySymbol && formatter.numberStyle == .decimal {
                return formattedAmount
            }
            
            return formattedAmount
            
        case .abbreviated:
            // Abbreviated format: always round to nearest dollar
            let formatter = NumberFormatter()
            formatter.numberStyle = showCurrencySymbol ? .currency : .decimal
            formatter.currencyCode = currency
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
            formatter.usesGroupingSeparator = useThousandsSeparator
            
            return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0"
            
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
    @Published var profileBudgets: [String: ProfileBudget] = [:]
    @Published var lastAPICallTime: Date?
    @Published var isRateLimited: Bool = false
    @Published var nextRefreshTime: Date?
    @Published var refreshInterval: Int = 5 { // minutes
        didSet {
            // Automatically recreate timer when interval changes
            let wasRunning = refreshTimer != nil
            if wasRunning {
                stopAutomaticRefresh()
                startAutomaticRefresh()
            }
        }
    }
    @Published var refreshTimer: Timer?
    
    // Keys for UserDefaults (legacy - will be replaced with @AppStorage)
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
        // Load profile budgets
        loadBudgets()
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
    
    // MARK: - Budget Management
    
    // Load budgets from UserDefaults
    func loadBudgets() {
        if let data = UserDefaults.standard.data(forKey: "ProfileBudgets"),
           let budgets = try? JSONDecoder().decode([String: ProfileBudget].self, from: data) {
            self.profileBudgets = budgets
        }
    }
    
    // Save budgets to UserDefaults
    func saveBudgets() {
        if let data = try? JSONEncoder().encode(profileBudgets) {
            UserDefaults.standard.set(data, forKey: "ProfileBudgets")
        }
    }
    
    // Get or create budget for a profile
    func getBudget(for profileName: String) -> ProfileBudget {
        if let budget = profileBudgets[profileName] {
            return budget
        } else {
            let newBudget = ProfileBudget(profileName: profileName)
            profileBudgets[profileName] = newBudget
            saveBudgets()
            return newBudget
        }
    }
    
    // Update budget for a profile
    func updateBudget(for profileName: String, monthlyBudget: Decimal, alertThreshold: Double) {
        var budget = getBudget(for: profileName)
        budget.monthlyBudget = monthlyBudget
        budget.alertThreshold = alertThreshold
        profileBudgets[profileName] = budget
        saveBudgets()
    }
    
    // Calculate budget status for current cost
    func calculateBudgetStatus(cost: Decimal, budget: ProfileBudget) -> (percentage: Double, isOverBudget: Bool, isNearThreshold: Bool) {
        let percentage = NSDecimalNumber(decimal: cost).dividing(by: NSDecimalNumber(decimal: budget.monthlyBudget)).doubleValue
        let isOverBudget = cost > budget.monthlyBudget
        let isNearThreshold = percentage >= budget.alertThreshold
        return (percentage, isOverBudget, isNearThreshold)
    }
    
    // MARK: - Timer Management
    
    // Calculate smart refresh interval based on budget usage
    func calculateSmartRefreshInterval() -> Int {
        guard let profile = selectedProfile,
              let cost = costData.first else {
            return refreshInterval // Use default if no data
        }
        
        let budget = getBudget(for: profile.name)
        let status = calculateBudgetStatus(cost: cost.amount, budget: budget)
        
        // Adjust refresh interval based on budget usage
        if status.isOverBudget {
            // Over budget: refresh every 5 minutes (minimum)
            return 5
        } else if status.percentage >= 0.9 {
            // 90%+ of budget: refresh every 10 minutes
            return 10
        } else if status.percentage >= 0.8 {
            // 80-90% of budget: refresh every 15 minutes
            return 15
        } else if status.percentage >= 0.7 {
            // 70-80% of budget: refresh every 30 minutes
            return 30
        } else {
            // Under 70%: use configured interval (max 60 minutes)
            return min(refreshInterval, 60)
        }
    }
    
    // Starts automatic refresh based on the current refresh interval
    func startAutomaticRefresh() {
        stopAutomaticRefresh() // Stop any existing timer
        
        let smartInterval = calculateSmartRefreshInterval()
        let interval = TimeInterval(smartInterval * 60) // Convert minutes to seconds
        
        print("Smart refresh: Using \(smartInterval) minute interval based on budget usage")
        
        // Calculate and store next refresh time
        nextRefreshTime = Date().addingTimeInterval(interval)
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task {
                await self?.fetchCostForSelectedProfile()
                // After fetch, recalculate interval and restart timer
                await MainActor.run {
                    self?.startAutomaticRefresh()
                }
            }
        }
    }
    
    // Stops automatic refresh
    func stopAutomaticRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        nextRefreshTime = nil
    }
    
    // Updates refresh interval and recreates timer if running
    func updateRefreshInterval(_ newInterval: Int) {
        let wasRunning = refreshTimer != nil
        stopAutomaticRefresh() // Always stop first
        refreshInterval = newInterval
        
        if wasRunning {
            startAutomaticRefresh() // Restart with new interval
        }
    }
    
    // Check if API call is allowed based on rate limit
    func canMakeAPICall() -> Bool {
        guard let lastCall = lastAPICallTime else {
            return true // No previous call
        }
        
        let timeSinceLastCall = Date().timeIntervalSince(lastCall)
        return timeSinceLastCall >= 60.0 // 1 minute = 60 seconds
    }
    
    // Get seconds until next API call is allowed
    func secondsUntilNextAllowedCall() -> Int {
        guard let lastCall = lastAPICallTime else {
            return 0
        }
        
        let timeSinceLastCall = Date().timeIntervalSince(lastCall)
        let remainingTime = 60.0 - timeSinceLastCall
        return max(0, Int(ceil(remainingTime)))
    }
    
    // Force refresh, bypassing rate limit (with warning)
    func forceRefresh() async {
        print("WARNING: Force refresh invoked, bypassing rate limit!")
        await fetchCostForSelectedProfile(force: true)
    }
    
    // Asynchronously fetches MTD cost for the selected profile.
    func fetchCostForSelectedProfile(force: Bool = false) async {
        // Check rate limit first (unless forced)
        if !force && !canMakeAPICall() {
            await MainActor.run {
                self.errorMessage = "Rate limited. Please wait \(secondsUntilNextAllowedCall()) seconds."
                self.isRateLimited = true
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.costData = []
            self.isRateLimited = false
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
            
            // Record API call time BEFORE making the request
            await MainActor.run {
                self.lastAPICallTime = Date()
            }
            
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
                VStack(spacing: 8) {
                    HStack {
                        Text(cost.profileName)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        // Use the same formatter settings as menu bar
                        Text(CostDisplayFormatter.format(
                            amount: cost.amount,
                            currency: cost.currency,
                            format: .full,
                            showCurrencySymbol: UserDefaults.standard.bool(forKey: "ShowCurrencySymbol"),
                            decimalPlaces: UserDefaults.standard.integer(forKey: "DecimalPlaces") == 0 ? 2 : UserDefaults.standard.integer(forKey: "DecimalPlaces"),
                            useThousandsSeparator: UserDefaults.standard.bool(forKey: "UseThousandsSeparator")
                        ))
                        .fontWeight(.bold)
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
                }
            } else {
                Text("No cost data available. Select a profile and refresh.")
                    .foregroundColor(.secondary)
            }

            Divider()
            
            // Show next refresh time if auto-refresh is active
            if let nextRefresh = awsManager.nextRefreshTime {
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
            
            Button("Refresh") {
                Task {
                    await awsManager.fetchCostForSelectedProfile()
                }
            }
            .keyboardShortcut("r", modifiers: .command)
            .frame(maxWidth: .infinity)
            
            // Show rate limit warning and override option
            if awsManager.isRateLimited {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("Rate limited (\(awsManager.secondsUntilNextAllowedCall())s)")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                    Button("Override") {
                        Task {
                            await awsManager.forceRefresh()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
                .padding(.vertical, 4)
            }
            
            Divider()
            
            Button("Settings...") {
                // Open Settings window using the Preferences action
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",", modifiers: .command)
            .frame(maxWidth: .infinity)
            
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
    }
}

// MARK: - Main App Entry Point

@main
struct AWSCostMonitorApp: App {
    @StateObject private var awsManager = AWSManager()
    @AppStorage("ShowCurrencySymbol") private var showCurrencySymbol: Bool = true
    @AppStorage("DecimalPlaces") private var decimalPlaces: Int = 2
    @AppStorage("UseThousandsSeparator") private var useThousandsSeparator: Bool = true
    
    var menuBarTitle: String {
        if let cost = awsManager.costData.first {
            let formattedCost = CostDisplayFormatter.format(
                amount: cost.amount,
                currency: cost.currency,
                format: awsManager.displayFormat,
                showCurrencySymbol: showCurrencySymbol,
                decimalPlaces: decimalPlaces,
                useThousandsSeparator: useThousandsSeparator
            )
            return formattedCost
        } else if awsManager.isLoading {
            return "Loading..."
        } else {
            return ""
        }
    }
    
    var menuBarIcon: String {
        if awsManager.errorMessage != nil {
            return "exclamationmark.triangle.fill"
        } else if awsManager.displayFormat == .iconOnly || awsManager.costData.isEmpty {
            return "dollarsign.circle.fill"
        } else {
            return "" // No icon when showing dollar amount
        }
    }
    
    var menuBarColor: Color? {
        // Determine color based on budget status
        if awsManager.errorMessage != nil {
            return .yellow
        }
        
        guard let profile = awsManager.selectedProfile,
              let cost = awsManager.costData.first else {
            return nil
        }
        
        let budget = awsManager.getBudget(for: profile.name)
        let status = awsManager.calculateBudgetStatus(cost: cost.amount, budget: budget)
        
        if status.isOverBudget {
            return .red
        } else if status.isNearThreshold {
            return .orange
        } else {
            return nil // Default color
        }
    }
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(awsManager)
        } label: {
            HStack(spacing: 4) {
                if !menuBarIcon.isEmpty {
                    Image(systemName: menuBarIcon)
                        .foregroundColor(menuBarColor)
                }
                if !menuBarTitle.isEmpty && awsManager.displayFormat != .iconOnly {
                    Text(menuBarTitle)
                        .foregroundColor(menuBarColor)
                }
            }
        }
        .onChange(of: awsManager.costData) { _, _ in
            // Force menu bar update when cost data changes
        }
        .onChange(of: awsManager.displayFormat) { _, _ in
            // Force menu bar update when display format changes
        }
        
        Settings {
            SettingsView()
                .environmentObject(awsManager)
        }
    }
}
