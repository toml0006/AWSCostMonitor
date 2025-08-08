import SwiftUI
import AppKit
import AWSCostExplorer
import AWSClientRuntime
import AWSSTS
import AWSSDKIdentity
import SmithyIdentity
import Foundation
import os.log
import UserNotifications
import AppIntents
import Combine
import Darwin
import AWSSDKHTTPAuth

// MARK: - Logging System

// Custom log categories
extension Logger {
    private static let subsystem = "com.middleout.AWSCostMonitor"
    
    static let api = Logger(subsystem: subsystem, category: "API")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let data = Logger(subsystem: subsystem, category: "Data")
    static let config = Logger(subsystem: subsystem, category: "Config")
}

// Log entry for tracking
struct LogEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let category: String
    let message: String
    let metadata: [String: String]?
    
    enum LogLevel: String, Codable, CaseIterable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        
        var color: Color {
            switch self {
            case .debug: return .gray
            case .info: return .primary
            case .warning: return .orange
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .debug: return "ant.circle"
            case .info: return "info.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            }
        }
    }
}

// API request tracking
struct APIRequestRecord: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let profileName: String
    let endpoint: String
    let success: Bool
    let duration: TimeInterval
    let errorMessage: String?
}

// AWS Credentials structure for manual parsing
struct ParsedAWSCredentials {
    let accessKeyId: String
    let secretAccessKey: String
    let sessionToken: String?
}

// Function to parse AWS credentials from credentials file content
func parseAWSCredentials(content: String, profileName: String) -> ParsedAWSCredentials? {
    let lines = content.components(separatedBy: .newlines)
    var inTargetProfile = false
    var accessKeyId: String?
    var secretAccessKey: String?
    var sessionToken: String?
    
    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Check if we're entering the target profile section
        if trimmed == "[\(profileName)]" {
            inTargetProfile = true
            continue
        }
        
        // Check if we're entering a different profile section
        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") && trimmed != "[\(profileName)]" {
            inTargetProfile = false
            continue
        }
        
        // Only process lines when we're in the target profile
        if inTargetProfile && trimmed.contains("=") {
            let components = trimmed.components(separatedBy: "=")
            if components.count >= 2 {
                let key = components[0].trimmingCharacters(in: .whitespaces)
                let value = components.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespaces)
                
                switch key {
                case "aws_access_key_id":
                    accessKeyId = value
                case "aws_secret_access_key":
                    secretAccessKey = value
                case "aws_session_token":
                    sessionToken = value
                default:
                    break
                }
            }
        }
    }
    
    // Must have at least access key and secret
    guard let accessKey = accessKeyId, let secretKey = secretAccessKey else {
        return nil
    }
    
    return ParsedAWSCredentials(
        accessKeyId: accessKey,
        secretAccessKey: secretKey,
        sessionToken: sessionToken
    )
}

// Custom errors for AWS cost fetching
enum AWSCostFetchError: Error {
    case credentialsNotFound(String)
}

// Helper function to create appropriate credentials provider for sandbox/non-sandbox
func createAWSCredentialsProvider(for profileName: String) throws -> AWSCredentialIdentityResolver {
    if ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil {
        // Sandboxed environment - use manual credential parsing
        let accessManager = AWSConfigAccessManager.shared
        
        guard let credentialsContent = accessManager.readCredentialsFile() else {
            throw AWSCostFetchError.credentialsNotFound("Unable to read credentials file via security-scoped access")
        }
        
        guard let profileCredentials = parseAWSCredentials(content: credentialsContent, profileName: profileName) else {
            throw AWSCostFetchError.credentialsNotFound("No credentials found for profile '\(profileName)' in credentials file")
        }
        
        let awsCredentials = AWSCredentialIdentity(
            accessKey: profileCredentials.accessKeyId,
            secret: profileCredentials.secretAccessKey,
            sessionToken: profileCredentials.sessionToken
        )
        
        return StaticAWSCredentialIdentityResolver(awsCredentials)
    } else {
        // Not sandboxed - use standard ProfileAWSCredentialIdentityResolver
        return try ProfileAWSCredentialIdentityResolver(profileName: profileName)
    }
}

// MARK: - Extensions

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Custom menu button with hover and press effects
struct MenuButton: View {
    let action: () -> Void
    let label: String
    let systemImage: String
    let shortcut: String?
    @Binding var hoveredItem: String?
    @Binding var pressedItem: String?
    let itemId: String
    
    var body: some View {
        Button(action: {
            // Show press animation
            withAnimation(.easeInOut(duration: 0.1)) {
                pressedItem = itemId
            }
            
            // Execute action after brief delay for visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
                withAnimation(.easeInOut(duration: 0.1)) {
                    pressedItem = nil
                }
            }
        }) {
            HStack {
                Label(label, systemImage: systemImage)
                Spacer()
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(pressedItem == itemId ? Color.accentColor.opacity(0.2) :
                          (hoveredItem == itemId ? Color.accentColor.opacity(0.1) : Color.clear))
                    .animation(.easeInOut(duration: 0.1), value: hoveredItem)
                    .animation(.easeInOut(duration: 0.1), value: pressedItem)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.1)) {
                hoveredItem = isHovered ? itemId : nil
            }
        }
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
struct CostData: Identifiable, Equatable, Codable {
    let id: UUID = UUID()
    let profileName: String
    let amount: Decimal
    let currency: String
    
    enum CodingKeys: String, CodingKey {
        case profileName, amount, currency
    }
}

// Budget configuration for each profile
struct ProfileBudget: Codable, Identifiable {
    let id = UUID()
    let profileName: String
    var monthlyBudget: Decimal
    var alertThreshold: Double // Percentage (0.0 - 1.0)
    var apiBudget: Decimal // Cost Explorer API budget per month
    var refreshIntervalMinutes: Int // Auto-refresh interval
    
    enum CodingKeys: String, CodingKey {
        case profileName, monthlyBudget, alertThreshold, apiBudget, refreshIntervalMinutes
    }
    
    init(profileName: String, monthlyBudget: Decimal = 100.0, alertThreshold: Double = 0.8, apiBudget: Decimal = 5.0, refreshIntervalMinutes: Int = 360) {
        self.profileName = profileName
        self.monthlyBudget = monthlyBudget
        self.alertThreshold = alertThreshold
        self.apiBudget = apiBudget
        self.refreshIntervalMinutes = refreshIntervalMinutes
    }
}

// Historical cost data for trend analysis
struct HistoricalCostData: Codable, Identifiable {
    let id = UUID()
    let profileName: String
    let date: Date // First day of the month
    let amount: Decimal
    let currency: String
    let isComplete: Bool // True if this is a complete month
    
    enum CodingKeys: String, CodingKey {
        case profileName, date, amount, currency, isComplete
    }
}

// Service-level cost breakdown
struct ServiceCost: Identifiable, Comparable, Codable {
    let id = UUID()
    let serviceName: String
    let amount: Decimal
    let currency: String
    
    static func < (lhs: ServiceCost, rhs: ServiceCost) -> Bool {
        lhs.amount > rhs.amount // Sort by amount descending
    }
}

// Daily cost data point
struct DailyCost: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let amount: Decimal
    let currency: String
}

// Daily service cost data point for histograms
struct DailyServiceCost: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let serviceName: String
    let amount: Decimal
    let currency: String
}

// Comprehensive cost cache entry
struct CostCacheEntry: Codable {
    let profileName: String
    let fetchDate: Date
    let mtdTotal: Decimal
    let currency: String
    let dailyCosts: [DailyCost]
    let serviceCosts: [ServiceCost]
    let startDate: Date
    let endDate: Date
    
    var isValid: Bool {
        // Cache validity based on age and completeness
        let age = Date().timeIntervalSince(fetchDate)
        let maxAge: TimeInterval = 3600 // 1 hour default max age
        return age < maxAge
    }
    
    func isValidForBudget(_ budget: ProfileBudget) -> Bool {
        // Intelligent cache validity based on budget proximity
        let age = Date().timeIntervalSince(fetchDate)
        let budgetPercentage = NSDecimalNumber(decimal: mtdTotal).dividing(by: NSDecimalNumber(decimal: budget.monthlyBudget)).doubleValue
        
        // Adjust cache duration based on budget usage
        let maxAge: TimeInterval
        if budgetPercentage > 0.95 {
            maxAge = 900 // 15 minutes if over 95% of budget
        } else if budgetPercentage > 0.8 {
            maxAge = 1800 // 30 minutes if over 80%
        } else if budgetPercentage > 0.5 {
            maxAge = 3600 // 1 hour if over 50%
        } else {
            maxAge = 7200 // 2 hours if under 50%
        }
        
        return age < maxAge
    }
}

// Cost trend indicator
enum CostTrend: Equatable {
    case up(percentage: Double)
    case down(percentage: Double)
    case stable
    
    var color: Color {
        switch self {
        case .up(let percentage):
            return percentage > 10 ? .red : .orange
        case .down:
            return .green
        case .stable:
            return .secondary
        }
    }
    
    var icon: String {
        switch self {
        case .up:
            return "arrow.up.circle.fill"
        case .down:
            return "arrow.down.circle.fill"
        case .stable:
            return "minus.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .up(let percentage):
            return String(format: "+%.1f%%", percentage)
        case .down(let percentage):
            return String(format: "-%.1f%%", percentage)
        case .stable:
            return "0%"
        }
    }
}

// Anomaly detection result
struct SpendingAnomaly: Identifiable {
    let id = UUID()
    let type: AnomalyType
    let severity: AnomalySeverity
    let message: String
    let percentage: Double? // Percentage deviation from normal
    
    enum AnomalyType {
        case unusualSpike
        case newService
        case suddenDrop
        case budgetVelocity // Spending too fast relative to budget
    }
    
    enum AnomalySeverity {
        case warning
        case critical
        
        var color: Color {
            switch self {
            case .warning:
                return .orange
            case .critical:
                return .red
            }
        }
        
        var icon: String {
            switch self {
            case .warning:
                return "exclamationmark.triangle"
            case .critical:
                return "exclamationmark.octagon.fill"
            }
        }
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
            formatter.locale = Locale.current
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
            formatter.locale = Locale.current
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
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            return parseString(content)
        } catch {
            print("Error reading INI file: \(error.localizedDescription)")
            return [:]
        }
    }
    
    static func parseString(_ content: String) -> [String: [String: String]] {
        var profiles = [String: [String: String]]()
        var currentProfileName: String?
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
        return profiles
    }
}

// MARK: - AWS Manager
// This class handles all the AWS SDK logic.
class AWSManager: ObservableObject {
    static let shared = AWSManager()
    
    @Published var profiles: [AWSProfile] = []
    @Published var realProfiles: [AWSProfile] = []
    @Published var demoProfiles: [AWSProfile] = []
    @Published var selectedProfile: AWSProfile?
    @Published var costData: [CostData] = [] {
        didSet {
            saveCostData()
        }
    }
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
    @Published var historicalData: [HistoricalCostData] = []
    @Published var serviceCosts: [ServiceCost] = []
    @Published var costTrend: CostTrend = .stable
    @Published var projectedMonthlyTotal: Decimal?
    @Published var isLoadingServices = false
    @Published var lastServiceFetchTime: Date?
    @Published var anomalies: [SpendingAnomaly] = []
    @AppStorage("EnableAnomalyDetection") private var enableAnomalyDetection: Bool = true
    @AppStorage("AnomalyThresholdPercentage") private var anomalyThreshold: Double = 25.0 // 25% deviation triggers anomaly
    
    // Last month data caching
    @Published var lastMonthData: [String: CostData] = [:] // Key is profileName
    @Published var lastMonthDataFetchDate: [String: Date] = [:] // When we fetched last month's data
    @Published var lastMonthServiceCosts: [String: [ServiceCost]] = [:] // Service breakdown by profile
    @Published var lastMonthDataLoading: [String: Bool] = [:] // Loading state per profile
    private let lastMonthDataKey = "LastMonthCostData"
    private let lastMonthFetchDateKey = "LastMonthDataFetchDate"
    private let lastMonthServiceCostsKey = "LastMonthServiceCosts"
    
    // API request tracking per profile
    @Published var apiRequestsPerProfile: [String: [APIRequestRecord]] = [:]
    
    // Enhanced caching system
    @Published var costCache: [String: CostCacheEntry] = [:] // Key is profileName
    @Published var dailyCostsByProfile: [String: [DailyCost]] = [:] // Daily breakdown per profile
    @Published var dailyServiceCostsByProfile: [String: [DailyServiceCost]] = [:] // Daily service breakdown for histograms
    @Published var cacheStatus: [String: Date] = [:] // Last cache update time per profile
    private let costCacheKey = "CostCacheData"
    private let dailyCostsKey = "DailyCostData"
    private let dailyServiceCostsKey = "DailyServiceCostData"
    
    // Circuit breaker for API protection
    @Published var circuitBreakerTripped = false
    @Published var consecutiveAPIFailures = 0
    private let maxConsecutiveFailures = 3
    
    // Logging and debugging
    @Published var logEntries: [LogEntry] = []
    @Published var apiRequestRecords: [APIRequestRecord] = []
    @AppStorage("DebugMode") var debugMode: Bool = false
    @AppStorage("MaxLogEntries") private var maxLogEntries: Int = 1000
    @AppStorage("AutoRefreshEnabled") var autoRefreshEnabled: Bool = false
    
    // Cost alerts
    let alertManager = CostAlertManager()
    
    // Keys for UserDefaults (legacy - will be replaced with @AppStorage)
    private let selectedProfileKey = "SelectedAWSProfileName"
    private let displayFormatKey = "MenuBarDisplayFormat"
    private let historicalDataKey = "HistoricalCostData"
    private let apiRequestRecordsKey = "APIRequestRecords"
    
    // MARK: - Number Formatting
    
    // Localized currency formatter
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.usesGroupingSeparator = true  // ALWAYS use thousands separators
        formatter.groupingSeparator = ","  // FORCE comma
        formatter.groupingSize = 3  // Group by thousands
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
    
    // Localized currency formatter without decimals
    private var wholeCurrencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.usesGroupingSeparator = true  // ALWAYS use thousands separators
        formatter.groupingSeparator = ","  // FORCE comma
        formatter.groupingSize = 3  // Group by thousands
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }
    
    // Localized decimal formatter
    private var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter
    }
    
    // Localized percentage formatter
    private var percentageFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter
    }
    
    // Helper method to format currency with proper localization
    func formatCurrency(_ amount: Decimal, showDecimals: Bool = true) -> String {
        let nsNumber = NSDecimalNumber(decimal: amount)
        let doubleValue = nsNumber.doubleValue
        
        // Manual formatting with FORCED commas
        let wholePart = Int(doubleValue)
        let fractionalPart = Int((doubleValue - Double(wholePart)) * 100)
        
        // Format the whole part with commas
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = ","
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.groupingSize = 3
        
        let formattedWhole = numberFormatter.string(from: NSNumber(value: wholePart)) ?? "\(wholePart)"
        
        if showDecimals {
            return String(format: "$%@.%02d", formattedWhole, fractionalPart)
        } else {
            return "$\(formattedWhole)"
        }
    }
    
    // Helper method to format decimal numbers with proper localization
    private func formatDecimal(_ amount: Decimal) -> String {
        let nsNumber = NSDecimalNumber(decimal: amount)
        return decimalFormatter.string(from: nsNumber) ?? "0.00"
    }
    
    // Helper method to format percentage with proper localization
    private func formatPercentage(_ value: Double) -> String {
        return percentageFormatter.string(from: NSNumber(value: value / 100.0)) ?? "0.0%"
    }
    

    init() {
        log(.info, category: "Config", "AWSManager initialized")
        print("DEBUG: AWSManager init() called at \(Date())")
        
        // Set up AWS SDK environment variables early if we're sandboxed
        if ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil {
            log(.info, category: "Config", "App is sandboxed - configuring AWS SDK environment variables")
            
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
            
            log(.info, category: "Config", "Real home directory: \(realHome)")
            log(.info, category: "Config", "AWS_CONFIG_FILE set to: \(configPath)")
            log(.info, category: "Config", "AWS_SHARED_CREDENTIALS_FILE set to: \(credentialsPath)")
            print("DEBUG: Environment variables configured for sandbox - AWS_CONFIG_FILE=\(configPath)")
        }
        
        // Check AWS config access first
        let accessManager = AWSConfigAccessManager.shared
        if accessManager.needsAccessGrant {
            log(.info, category: "Config", "AWS config access needed, will prompt user")
            // The UI will handle prompting for access
        }
        
        // Listen for AWS config access granted notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(awsConfigAccessGranted),
            name: .awsConfigAccessGranted,
            object: nil
        )
        
        // Load profiles on initialization
        loadProfiles()
        // Load the stored user preference for the selected profile
        loadSelectedProfile()
        // Load the display format preference
        loadDisplayFormat()
        // Load profile budgets
        loadBudgets()
        // Load historical data
        loadHistoricalData()
        // Load API request records
        loadAPIRequestRecords()
        // Load cost data
        loadCostData()
        // Load last month data
        loadLastMonthData()
        // Load cache data
        loadCostCache()
        
        // Check if we need a startup refresh
        checkForStartupRefresh()
        
        // Restore auto-refresh state if it was enabled
        if autoRefreshEnabled {
            startAutomaticRefresh()
        }
    }
    
    // Handle AWS config access granted notification
    @objc func awsConfigAccessGranted() {
        log(.info, category: "Config", "AWS config access granted, reloading profiles")
        // Clear any previous error
        errorMessage = nil
        // Reload profiles
        loadProfiles()
        // Load the selected profile
        loadSelectedProfile()
        // Fetch cost data if we have a selected profile
        if selectedProfile != nil {
            Task {
                await fetchCostForSelectedProfile()
            }
        }
    }
    
    // Function to find the AWS config file and parse profiles.
    func loadProfiles() {
        log(.debug, category: "Config", "Loading AWS profiles")
        
        // Use AWSConfigAccessManager for sandboxed file access
        let accessManager = AWSConfigAccessManager.shared
        
        // Check if we have access
        if !accessManager.hasAccess {
            let error = "AWS config access not granted. Please grant access to your .aws folder."
            errorMessage = error
            log(.error, category: "Config", error)
            return
        }
        
        // Read config file using the access manager
        guard let configContent = accessManager.readConfigFile() else {
            let error = "Failed to read AWS config file. Please ensure ~/.aws/config exists."
            errorMessage = error
            log(.error, category: "Config", error)
            return
        }
        
        // Parse the config content
        let parsedProfiles = INIParser.parseString(configContent)
        log(.info, category: "Config", "Found \(parsedProfiles.count) profiles in AWS config")
        
        // Populate the profiles array from the parsed data.
        self.realProfiles = parsedProfiles.keys.map { profileName in
            let profileConfig = parsedProfiles[profileName]
            let region = profileConfig?["region"]
            return AWSProfile(name: profileName, region: region)
        }.sorted { $0.name < $1.name }
        
        // Add the ACME demo profile
        self.demoProfiles = [AWSProfile(name: "acme", region: "us-east-1")]
        
        // Combine: real profiles first, then demo profiles
        self.profiles = self.realProfiles + self.demoProfiles
        
        log(.info, category: "Config", "Loaded \(self.profiles.count) AWS profiles (including demo)")
        
        if self.profiles.isEmpty {
            let error = "No AWS profiles found in config file."
            errorMessage = error
            log(.warning, category: "Config", error)
        }
    }
    
    // Loads the selected profile name from UserDefaults.
    func loadSelectedProfile() {
        if let storedProfileName = UserDefaults.standard.string(forKey: selectedProfileKey) {
            // Find the profile object corresponding to the stored name
            self.selectedProfile = self.profiles.first { $0.name == storedProfileName }
            
            // Load profile-specific refresh settings
            if self.selectedProfile != nil {
                let budget = getBudget(for: storedProfileName)
                self.refreshInterval = budget.refreshIntervalMinutes
            }
        } else {
            // If no profile is stored, default to the first one if available.
            self.selectedProfile = self.profiles.first
            if let firstProfile = self.profiles.first {
                let budget = getBudget(for: firstProfile.name)
                self.refreshInterval = budget.refreshIntervalMinutes
            }
        }
    }
    
    // Saves the selected profile name to UserDefaults.
    func saveSelectedProfile(profile: AWSProfile) {
        UserDefaults.standard.set(profile.name, forKey: selectedProfileKey)
        
        // Load profile-specific refresh settings
        let budget = getBudget(for: profile.name)
        self.refreshInterval = budget.refreshIntervalMinutes
        
        // Restart refresh timer with new interval if active
        if refreshTimer != nil {
            stopAutomaticRefresh()
            startAutomaticRefresh()
        }
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
            // Migrate old budgets that don't have new fields
            if budget.apiBudget == 0 {
                var updated = budget
                updated.apiBudget = 5.0
                updated.refreshIntervalMinutes = 360
                profileBudgets[profileName] = updated
                saveBudgets()
                return updated
            }
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
    
    // Update API budget and refresh settings for a profile
    func updateAPIBudgetAndRefresh(for profileName: String, apiBudget: Decimal, refreshIntervalMinutes: Int) {
        var budget = getBudget(for: profileName)
        budget.apiBudget = apiBudget
        budget.refreshIntervalMinutes = refreshIntervalMinutes
        profileBudgets[profileName] = budget
        saveBudgets()
        
        // If this is the current profile, update the refresh timer
        if selectedProfile?.name == profileName {
            self.refreshInterval = refreshIntervalMinutes
            if refreshTimer != nil {
                stopAutomaticRefresh()
                startAutomaticRefresh()
            }
        }
    }
    
    // Helper to update full budget object
    func updateBudget(_ budget: ProfileBudget) {
        profileBudgets[budget.profileName] = budget
        saveBudgets()
    }
    
    // Budget status structure
    struct BudgetStatus {
        let percentage: Double
        let isOverBudget: Bool
        let isNearThreshold: Bool
    }
    
    // Calculate budget status for current cost
    func calculateBudgetStatus(cost: Decimal, budget: ProfileBudget) -> BudgetStatus {
        let percentage = NSDecimalNumber(decimal: cost).dividing(by: NSDecimalNumber(decimal: budget.monthlyBudget)).doubleValue
        return BudgetStatus(
            percentage: percentage,
            isOverBudget: percentage >= 1.0,
            isNearThreshold: percentage >= budget.alertThreshold
        )
    }
    
    // MARK: - Historical Data Management
    
    // Load historical data from UserDefaults
    func loadHistoricalData() {
        if let data = UserDefaults.standard.data(forKey: historicalDataKey),
           let historical = try? JSONDecoder().decode([HistoricalCostData].self, from: data) {
            self.historicalData = historical
        }
    }
    
    // Save historical data to UserDefaults
    func saveHistoricalData() {
        if let data = try? JSONEncoder().encode(historicalData) {
            UserDefaults.standard.set(data, forKey: historicalDataKey)
        }
    }
    
    // Save current cost data to UserDefaults
    func saveCostData() {
        if let data = try? JSONEncoder().encode(costData) {
            UserDefaults.standard.set(data, forKey: "CurrentCostData")
        }
    }
    
    // Load cost data from UserDefaults
    func loadCostData() {
        guard let data = UserDefaults.standard.data(forKey: "CurrentCostData"),
              let decoded = try? JSONDecoder().decode([CostData].self, from: data) else {
            return
        }
        costData = decoded
    }
    
    // Save last month data to UserDefaults
    func saveLastMonthData() {
        if let data = try? JSONEncoder().encode(lastMonthData) {
            UserDefaults.standard.set(data, forKey: lastMonthDataKey)
        }
        if let dateData = try? JSONEncoder().encode(lastMonthDataFetchDate) {
            UserDefaults.standard.set(dateData, forKey: lastMonthFetchDateKey)
        }
        if let serviceData = try? JSONEncoder().encode(lastMonthServiceCosts) {
            UserDefaults.standard.set(serviceData, forKey: lastMonthServiceCostsKey)
        }
    }
    
    // Load last month data from UserDefaults
    func loadLastMonthData() {
        if let data = UserDefaults.standard.data(forKey: lastMonthDataKey),
           let decoded = try? JSONDecoder().decode([String: CostData].self, from: data) {
            lastMonthData = decoded
        }
        if let dateData = UserDefaults.standard.data(forKey: lastMonthFetchDateKey),
           let decodedDates = try? JSONDecoder().decode([String: Date].self, from: dateData) {
            lastMonthDataFetchDate = decodedDates
        }
        if let serviceData = UserDefaults.standard.data(forKey: lastMonthServiceCostsKey),
           let decodedServices = try? JSONDecoder().decode([String: [ServiceCost]].self, from: serviceData) {
            lastMonthServiceCosts = decodedServices
        }
    }
    
    // MARK: - Logging Methods
    
    // Log a message with level and category
    func log(_ level: LogEntry.LogLevel, category: String, _ message: String, metadata: [String: String]? = nil) {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message,
            metadata: metadata
        )
        
        // Ensure UI updates happen on main thread
        Task { @MainActor in
            // Add to in-memory log
            logEntries.append(entry)
            
            // Trim logs if exceeding max
            if logEntries.count > maxLogEntries {
                logEntries.removeFirst(logEntries.count - maxLogEntries)
            }
        }
        
        // Also log to system logger
        let logger: Logger
        switch category {
        case "API": logger = Logger.api
        case "UI": logger = Logger.ui
        case "Data": logger = Logger.data
        case "Config": logger = Logger.config
        default: logger = Logger()
        }
        
        switch level {
        case .debug:
            if debugMode {
                logger.debug("\(message)")
            }
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        }
    }
    
    // Load API request records from UserDefaults
    func loadAPIRequestRecords() {
        if let data = UserDefaults.standard.data(forKey: apiRequestRecordsKey),
           let records = try? JSONDecoder().decode([APIRequestRecord].self, from: data) {
            self.apiRequestRecords = records
        }
    }
    
    // Save API request records to UserDefaults
    func saveAPIRequestRecords() {
        // Keep only last 30 days of records
        let cutoffDate = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        apiRequestRecords = apiRequestRecords.filter { $0.timestamp > cutoffDate }
        
        if let data = try? JSONEncoder().encode(apiRequestRecords) {
            UserDefaults.standard.set(data, forKey: apiRequestRecordsKey)
        }
    }
    
    // Record an API request
    func recordAPIRequest(profile: String, endpoint: String, success: Bool, duration: TimeInterval, error: String? = nil) {
        let record = APIRequestRecord(
            timestamp: Date(),
            profileName: profile,
            endpoint: endpoint,
            success: success,
            duration: duration,
            errorMessage: error
        )
        
        apiRequestRecords.append(record)
        
        // Also track per profile
        if apiRequestsPerProfile[profile] == nil {
            apiRequestsPerProfile[profile] = []
        }
        apiRequestsPerProfile[profile]?.append(record)
        
        // Keep only last 100 requests per profile
        if let count = apiRequestsPerProfile[profile]?.count, count > 100 {
            apiRequestsPerProfile[profile]?.removeFirst(count - 100)
        }
        
        saveAPIRequestRecords()
        
        // Log the request
        if success {
            log(.info, category: "API", "API request to \(endpoint) for \(profile) succeeded in \(String(format: "%.2f", duration))s")
        } else {
            log(.error, category: "API", "API request to \(endpoint) for \(profile) failed: \(error ?? "Unknown error")")
        }
    }
    
    // Get request count for a profile in the last period
    func getRequestCount(for profileName: String, inLast timeInterval: TimeInterval) -> Int {
        let cutoffDate = Date().addingTimeInterval(-timeInterval)
        return apiRequestRecords.filter {
            $0.profileName == profileName && $0.timestamp > cutoffDate
        }.count
    }
    
    // Export logs to file
    func exportLogs() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = "AWSCostMonitor_Logs_\(dateFormatter.string(from: Date())).json"
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Create export structure
        struct ExportData: Codable {
            let exportDate: Date
            let appVersion: String
            let logEntries: [LogEntry]
            let apiRequests: [APIRequestRecord]
        }
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            logEntries: logEntries,
            apiRequests: apiRequestRecords
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(exportData)
            try data.write(to: fileURL)
            log(.info, category: "Data", "Logs exported to \(fileURL.path)")
            return fileURL
        } catch {
            log(.error, category: "Data", "Failed to export logs: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Add or update historical data point
    func updateHistoricalData(profile: String, amount: Decimal, currency: String, date: Date = Date()) {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        
        // Check if we already have data for this month and profile
        if let index = historicalData.firstIndex(where: {
            $0.profileName == profile &&
            calendar.isDate($0.date, equalTo: monthStart, toGranularity: .month)
        }) {
            // Update existing data
            historicalData[index] = HistoricalCostData(
                profileName: profile,
                date: monthStart,
                amount: amount,
                currency: currency,
                isComplete: false // Current month is never complete
            )
        } else {
            // Add new data point
            historicalData.append(HistoricalCostData(
                profileName: profile,
                date: monthStart,
                amount: amount,
                currency: currency,
                isComplete: false
            ))
        }
        
        // Mark previous months as complete if needed
        markCompletedMonths()
        
        // Calculate trend
        updateCostTrend(for: profile)
        
        // Save to disk
        saveHistoricalData()
    }
    
    // Mark months as complete if they're in the past
    func markCompletedMonths() {
        let calendar = Calendar.current
        let now = Date()
        
        for index in historicalData.indices {
            if !historicalData[index].isComplete {
                // If the month is in the past, mark it as complete
                if calendar.compare(historicalData[index].date, to: now, toGranularity: .month) == .orderedAscending {
                    historicalData[index] = HistoricalCostData(
                        profileName: historicalData[index].profileName,
                        date: historicalData[index].date,
                        amount: historicalData[index].amount,
                        currency: historicalData[index].currency,
                        isComplete: true
                    )
                }
            }
        }
    }
    
    // Calculate cost trend (month-over-month comparison)
    func updateCostTrend(for profileName: String) {
        // First check if we have cached last month data
        guard let currentCost = costData.first(where: { $0.profileName == profileName }),
              let lastMonth = lastMonthData[profileName] else {
            self.costTrend = .stable
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let currentDay = calendar.component(.day, from: now)
        
        // Project last month's cost to the same day for fair comparison
        guard let daysInLastMonth = calendar.range(of: .day, in: .month, for: calendar.date(byAdding: .month, value: -1, to: now)!)?.count else {
            self.costTrend = .stable
            return
        }
        
        // Calculate daily average for last month
        let lastMonthDailyAverage = NSDecimalNumber(decimal: lastMonth.amount).dividing(by: NSDecimalNumber(integerLiteral: daysInLastMonth))
        
        // Project to current day of month
        let projectedLastMonthAmount = lastMonthDailyAverage.multiplying(by: NSDecimalNumber(integerLiteral: currentDay))
        
        // Calculate percentage change
        if projectedLastMonthAmount.doubleValue == 0 {
            self.costTrend = .stable
            return
        }
        
        let currentAmount = NSDecimalNumber(decimal: currentCost.amount)
        let change = currentAmount.subtracting(projectedLastMonthAmount)
        let percentageChange = change.dividing(by: projectedLastMonthAmount).multiplying(by: 100).doubleValue
        
        if abs(percentageChange) < 2.0 { // Less than 2% change is considered stable
            self.costTrend = .stable
        } else if percentageChange > 0 {
            self.costTrend = .up(percentage: percentageChange)
        } else {
            self.costTrend = .down(percentage: abs(percentageChange))
        }
    }
    
    // Calculate projected monthly total based on current spending rate
    func calculateProjectedMonthlyTotal(currentAmount: Decimal, for date: Date = Date()) -> Decimal? {
        let calendar = Calendar.current
        
        // Get the current day of the month
        let currentDay = calendar.component(.day, from: date)
        
        // Get the total days in the current month
        guard let range = calendar.range(of: .day, in: .month, for: date) else {
            return nil
        }
        let totalDays = range.count
        
        // Don't project if we're on the first day
        if currentDay <= 1 {
            return nil
        }
        
        // Calculate daily average and project
        let dailyAverage = NSDecimalNumber(decimal: currentAmount).dividing(by: NSDecimalNumber(integerLiteral: currentDay - 1))
        let projected = dailyAverage.multiplying(by: NSDecimalNumber(integerLiteral: totalDays))
        
        return projected as Decimal
    }
    
    // MARK: - Anomaly Detection
    
    // Detect spending anomalies based on historical data
    func detectAnomalies(for profileName: String, currentAmount: Decimal, serviceCosts: [ServiceCost] = []) {
        guard enableAnomalyDetection else {
            anomalies = []
            return
        }
        
        var detectedAnomalies: [SpendingAnomaly] = []
        
        // 1. Check for unusual spikes or drops compared to historical average
        if let deviation = calculateDeviationFromHistoricalAverage(profile: profileName, currentAmount: currentAmount) {
            if abs(deviation) > anomalyThreshold {
                let severity: SpendingAnomaly.AnomalySeverity = abs(deviation) > 50 ? .critical : .warning
                let type: SpendingAnomaly.AnomalyType = deviation > 0 ? .unusualSpike : .suddenDrop
                let message = deviation > 0 
                    ? "Spending is \(Int(deviation))% higher than usual"
                    : "Spending is \(Int(abs(deviation)))% lower than usual"
                
                detectedAnomalies.append(SpendingAnomaly(
                    type: type,
                    severity: severity,
                    message: message,
                    percentage: deviation
                ))
            }
        }
        
        // 2. Check budget velocity (spending too fast for the time of month)
        if let velocityAnomaly = checkBudgetVelocity(profile: profileName, currentAmount: currentAmount) {
            detectedAnomalies.append(velocityAnomaly)
        }
        
        // 3. Check for new services with significant costs
        if !serviceCosts.isEmpty {
            let newServiceAnomalies = detectNewServices(profile: profileName, currentServices: serviceCosts)
            detectedAnomalies.append(contentsOf: newServiceAnomalies)
        }
        
        anomalies = detectedAnomalies
    }
    
    // Calculate deviation from historical average for the same day of month
    private func calculateDeviationFromHistoricalAverage(profile: String, currentAmount: Decimal) -> Double? {
        let calendar = Calendar.current
        let now = Date()
        let currentDay = calendar.component(.day, from: now)
        
        // Get historical data for this profile (excluding current month)
        let historicalForProfile = historicalData.filter {
            $0.profileName == profile &&
            !calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        
        guard historicalForProfile.count >= 2 else {
            // Need at least 2 months of history for comparison
            return nil
        }
        
        // Calculate average spending for this day of month across history
        var historicalAmounts: [Decimal] = []
        
        for historical in historicalForProfile {
            // Project what the spending would be at this day of the month
            let daysInMonth = calendar.range(of: .day, in: .month, for: historical.date)?.count ?? 30
            let projectedAmount: Decimal
            
            if historical.isComplete {
                // For complete months, calculate the daily average and multiply by current day
                let dailyAverage = NSDecimalNumber(decimal: historical.amount).dividing(by: NSDecimalNumber(integerLiteral: daysInMonth))
                projectedAmount = dailyAverage.multiplying(by: NSDecimalNumber(integerLiteral: currentDay)) as Decimal
            } else {
                // For incomplete months, use the actual amount
                projectedAmount = historical.amount
            }
            
            historicalAmounts.append(projectedAmount)
        }
        
        // Calculate average
        let sum = historicalAmounts.reduce(Decimal(0), +)
        let average = NSDecimalNumber(decimal: sum).dividing(by: NSDecimalNumber(integerLiteral: historicalAmounts.count))
        
        // Calculate percentage deviation
        if average.doubleValue == 0 {
            return nil
        }
        
        let currentNSDecimal = NSDecimalNumber(decimal: currentAmount)
        let deviation = currentNSDecimal.subtracting(average).dividing(by: average).multiplying(by: 100).doubleValue
        
        return deviation
    }
    
    // Check if spending velocity is too high for the time of month
    private func checkBudgetVelocity(profile: String, currentAmount: Decimal) -> SpendingAnomaly? {
        let calendar = Calendar.current
        let now = Date()
        let currentDay = calendar.component(.day, from: now)
        
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count else {
            return nil
        }
        
        let budget = getBudget(for: profile)
        let monthProgress = Double(currentDay) / Double(daysInMonth)
        let spendingProgress = NSDecimalNumber(decimal: currentAmount).dividing(by: NSDecimalNumber(decimal: budget.monthlyBudget)).doubleValue
        
        // If spending progress is significantly ahead of month progress
        if spendingProgress > monthProgress * 1.5 && spendingProgress > 0.5 {
            let daysRemaining = daysInMonth - currentDay
            let remainingBudget = NSDecimalNumber(decimal: budget.monthlyBudget).subtracting(NSDecimalNumber(decimal: currentAmount))
            
            let message: String
            let severity: SpendingAnomaly.AnomalySeverity
            
            if remainingBudget.doubleValue <= 0 {
                message = "Budget exhausted with \(daysRemaining) days remaining"
                severity = .critical
            } else {
                let percentAhead = ((spendingProgress / monthProgress) - 1.0) * 100
                message = String(format: "Spending %.0f%% faster than expected pace", percentAhead)
                severity = spendingProgress > 0.9 ? .critical : .warning
            }
            
            return SpendingAnomaly(
                type: .budgetVelocity,
                severity: severity,
                message: message,
                percentage: spendingProgress * 100
            )
        }
        
        return nil
    }
    
    // Detect new services that weren't present in previous months
    private func detectNewServices(profile: String, currentServices: [ServiceCost]) -> [SpendingAnomaly] {
        // This would require storing historical service breakdown data
        // For now, we'll detect services with unusually high costs
        var anomalies: [SpendingAnomaly] = []
        
        // Find services that represent more than 30% of total cost
        let totalCost = currentServices.reduce(Decimal(0)) { $0 + $1.amount }
        
        for service in currentServices {
            let percentage = NSDecimalNumber(decimal: service.amount).dividing(by: NSDecimalNumber(decimal: totalCost)).multiplying(by: 100).doubleValue
            
            if percentage > 30 {
                anomalies.append(SpendingAnomaly(
                    type: .newService,
                    severity: percentage > 50 ? .critical : .warning,
                    message: "\(service.serviceName) is \(Int(percentage))% of total cost",
                    percentage: percentage
                ))
            }
        }
        
        return anomalies
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
        autoRefreshEnabled = true // Persist the state
        
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
        autoRefreshEnabled = false // Persist the state
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
    
    // Check if we need to perform a startup refresh
    func checkForStartupRefresh() {
        // Only check if we have a selected profile
        guard let profile = selectedProfile else {
            return
        }
        
        // Get the last API call time for this profile
        let profileRecords = apiRequestRecords.filter { $0.profileName == profile.name && $0.success }
        guard let lastRecord = profileRecords.sorted(by: { $0.timestamp > $1.timestamp }).first else {
            // No previous successful API call, perform refresh
            Task {
                await fetchCostForSelectedProfile()
            }
            return
        }
        
        // Calculate time since last refresh
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRecord.timestamp)
        let refreshIntervalSeconds = TimeInterval(refreshInterval * 60)
        
        // If last refresh was longer than the refresh interval ago, perform one-off refresh
        if timeSinceLastRefresh > refreshIntervalSeconds {
            log(.info, category: "Startup", "Last refresh was \(Int(timeSinceLastRefresh / 60)) minutes ago, performing startup refresh")
            Task {
                await fetchCostForSelectedProfile()
            }
        } else {
            log(.info, category: "Startup", "Last refresh was \(Int(timeSinceLastRefresh / 60)) minutes ago, within refresh interval of \(refreshInterval) minutes")
        }
    }
    
    // Enhanced single-call data strategy with intelligent caching
    func fetchCostForSelectedProfile(force: Bool = false) async {
        guard let profile = selectedProfile else {
            let error = "No profile selected."
            log(.warning, category: "API", error)
            await MainActor.run {
                self.errorMessage = error
            }
            return
        }
        
        // Check if this is the ACME demo profile
        if profile.name.lowercased() == "acme" {
            await loadDemoDataForACME()
            return
        }
        
        // Check cache first (unless forced)
        if !force {
            if let cachedData = costCache[profile.name] {
                let budget = getBudget(for: profile.name)
                if cachedData.isValidForBudget(budget) {
                    log(.info, category: "Cache", "Using cached data for \(profile.name), age: \(Int(Date().timeIntervalSince(cachedData.fetchDate) / 60)) minutes")
                    await loadFromCache(cachedData)
                    return
                }
            }
        }
        
        // Check circuit breaker
        if circuitBreakerTripped {
            if force {
                log(.info, category: "API", "Circuit breaker is active but bypassing due to force refresh")
            } else {
                log(.warning, category: "API", "Circuit breaker tripped. Skipping API call.")
                await MainActor.run {
                    self.errorMessage = "API circuit breaker active. Click 'Retry' to bypass."
                }
                return
            }
        }
        
        // Check rate limit first (unless forced)
        if !force && !canMakeAPICall() {
            let waitTime = secondsUntilNextAllowedCall()
            log(.warning, category: "API", "Rate limited. Need to wait \(waitTime) seconds")
            
            // Only show rate limit error if we don't have cached data for this profile
            if costCache[profile.name] == nil {
                await MainActor.run {
                    self.errorMessage = "Rate limited. Please wait \(waitTime) seconds."
                    self.isRateLimited = true
                }
            } else {
                // We have cached data, so just silently skip the fetch
                await MainActor.run {
                    self.isRateLimited = true
                }
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.isLoadingServices = true
            self.errorMessage = nil
            self.isRateLimited = false
        }
        
        log(.info, category: "API", "Fetching comprehensive cost data for profile: \(profile.name)")
        let startTime = Date()
        
        // Debug: Check AWS config and credentials access
        let accessManager = AWSConfigAccessManager.shared
        log(.debug, category: "API", "AWS config access - Has access: \(accessManager.hasAccess), Needs grant: \(accessManager.needsAccessGrant)")
        
        // Debug: Read and check config file
        if let configContent = accessManager.readConfigFile() {
            log(.debug, category: "API", "Successfully read AWS config file (\(configContent.count) characters)")
            
            // Check if profile exists
            let profilePattern = "\\[(profile )?\\Q\(profile.name)\\E\\]"
            if configContent.range(of: profilePattern, options: .regularExpression) != nil {
                log(.debug, category: "API", "✅ Profile '\(profile.name)' found in AWS config")
                
                // Extract profile configuration
                if let profileRange = configContent.range(of: profilePattern, options: .regularExpression) {
                    let startIndex = profileRange.upperBound
                    let remainingContent = String(configContent[startIndex...])
                    let lines = remainingContent.split(separator: "\n", maxSplits: 10)
                    log(.debug, category: "API", "Profile '\(profile.name)' config excerpt:")
                    for line in lines.prefix(5) {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        if trimmed.isEmpty || trimmed.hasPrefix("[") { break }
                        log(.debug, category: "API", "  \(trimmed)")
                    }
                }
            } else {
                log(.warning, category: "API", "⚠️ Profile '\(profile.name)' NOT found in AWS config")
            }
        } else {
            log(.error, category: "API", "❌ Failed to read AWS config file")
        }
        
        // Debug: Check credentials file
        if let credentialsContent = accessManager.readCredentialsFile() {
            log(.debug, category: "API", "Successfully read AWS credentials file (\(credentialsContent.count) characters)")
            
            // Check if profile has credentials
            if credentialsContent.contains("[\(profile.name)]") {
                log(.debug, category: "API", "✅ Credentials section found for profile '\(profile.name)'")
                
                // Check for credential type (don't log actual values)
                let profileSection = credentialsContent.components(separatedBy: "[\(profile.name)]").last?.components(separatedBy: "[").first ?? ""
                if profileSection.contains("aws_access_key_id") {
                    log(.debug, category: "API", "  Found: aws_access_key_id")
                }
                if profileSection.contains("aws_secret_access_key") {
                    log(.debug, category: "API", "  Found: aws_secret_access_key")
                }
                if profileSection.contains("aws_session_token") {
                    log(.debug, category: "API", "  Found: aws_session_token (temporary credentials)")
                }
            } else {
                log(.warning, category: "API", "⚠️ No credentials section for profile '\(profile.name)' in credentials file")
            }
        } else {
            log(.debug, category: "API", "No AWS credentials file (may be using SSO, IAM roles, or environment variables)")
        }
        
        do {
            // Debug: Check environment variables that AWS SDK uses
            log(.debug, category: "API", "Environment check:")
            log(.debug, category: "API", "  HOME: \(ProcessInfo.processInfo.environment["HOME"] ?? "not set")")
            log(.debug, category: "API", "  AWS_CONFIG_FILE: \(ProcessInfo.processInfo.environment["AWS_CONFIG_FILE"] ?? "not set")")
            log(.debug, category: "API", "  AWS_SHARED_CREDENTIALS_FILE: \(ProcessInfo.processInfo.environment["AWS_SHARED_CREDENTIALS_FILE"] ?? "not set")")
            log(.debug, category: "API", "  AWS_PROFILE: \(ProcessInfo.processInfo.environment["AWS_PROFILE"] ?? "not set")")
            
            // Create credentials provider using helper function
            let credentialsProvider = try createAWSCredentialsProvider(for: profile.name)
            
            if ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil {
                log(.debug, category: "API", "✅ Successfully created StaticAWSCredentialIdentityResolver for sandboxed environment")
            } else {
                log(.debug, category: "API", "✅ Successfully created ProfileAWSCredentialIdentityResolver for non-sandboxed environment")
            }
            
            log(.debug, category: "API", "Creating CostExplorerClient configuration for region: \(profile.region ?? "us-east-1")")
            let config = try await CostExplorerClient.CostExplorerClientConfiguration(
                awsCredentialIdentityResolver: credentialsProvider,
                region: profile.region ?? "us-east-1"
            )
            log(.debug, category: "API", "✅ Successfully created CostExplorerClient configuration")
            let client = CostExplorerClient(config: config)
            
            let calendar = Calendar.current
            let now = Date()
            
            // Start date is the beginning of the current month
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            
            // End date is the beginning of the next day (exclusive, so it includes today)
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: now)!
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            // ENHANCED: Get comprehensive cost data with DAILY granularity + service breakdown
            let input = GetCostAndUsageInput(
                granularity: .daily, // KEY CHANGE: Daily granularity for trend analysis
                groupBy: [.init(key: "SERVICE", type: .dimension)],
                metrics: ["AmortizedCost"], // Use AmortizedCost for better accuracy
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
            
            if let resultsByTime = output.resultsByTime, !resultsByTime.isEmpty {
                var totalAmount = Decimal(0)
                var currency = "USD"
                var dailyCosts: [DailyCost] = []
                var serviceBreakdown: [String: Decimal] = [:] // service -> total cost
                var dailyServiceCosts: [DailyServiceCost] = [] // for histogram data
                
                // Process each day's data
                for result in resultsByTime {
                    guard let timeString = result.timePeriod?.start,
                          let date = dateFormatter.date(from: timeString) else { continue }
                    
                    var dailyTotal = Decimal(0)
                    
                    // Process service breakdown for this day
                    if let groups = result.groups {
                        for group in groups {
                            if let serviceName = group.keys?.first,
                               let metrics = group.metrics,
                               let amortizedCost = metrics["AmortizedCost"],
                               let amountString = amortizedCost.amount,
                               let serviceCurrency = amortizedCost.unit,
                               let amount = Decimal(string: amountString) {
                                
                                currency = serviceCurrency
                                dailyTotal += amount
                                
                                // Accumulate service totals across all days
                                if amount > 0 {
                                    serviceBreakdown[serviceName, default: 0] += amount
                                    
                                    // Store daily service cost for histogram
                                    dailyServiceCosts.append(DailyServiceCost(
                                        date: date,
                                        serviceName: serviceName,
                                        amount: amount,
                                        currency: serviceCurrency
                                    ))
                                }
                            }
                        }
                    }
                    
                    // Create daily cost entry
                    if dailyTotal > 0 {
                        dailyCosts.append(DailyCost(
                            date: date,
                            amount: dailyTotal,
                            currency: currency
                        ))
                        totalAmount += dailyTotal
                    }
                }
                
                // Convert service breakdown to ServiceCost array
                let services = serviceBreakdown.compactMap { serviceName, amount -> ServiceCost? in
                    guard amount > 0 else { return nil }
                    return ServiceCost(
                        serviceName: serviceName,
                        amount: amount,
                        currency: currency
                    )
                }.sorted(by: { $0.amount > $1.amount })
                
                // Create comprehensive cache entry
                let cacheEntry = CostCacheEntry(
                    profileName: profile.name,
                    fetchDate: Date(),
                    mtdTotal: totalAmount,
                    currency: currency,
                    dailyCosts: dailyCosts,
                    serviceCosts: services,
                    startDate: startOfMonth,
                    endDate: endOfToday
                )
                
                await MainActor.run {
                    // Store in cache
                    self.costCache[profile.name] = cacheEntry
                    self.dailyCostsByProfile[profile.name] = dailyCosts
                    self.dailyServiceCostsByProfile[profile.name] = dailyServiceCosts
                    self.cacheStatus[profile.name] = Date()
                    
                    // Update UI data
                    self.costData.removeAll()
                    self.costData.append(CostData(
                        profileName: profile.name,
                        amount: totalAmount,
                        currency: currency
                    ))
                    
                    // Update service costs
                    self.serviceCosts = services
                    
                    // Update historical data
                    self.updateHistoricalData(profile: profile.name, amount: totalAmount, currency: currency)
                    
                    // Calculate enhanced projections using daily data
                    self.projectedMonthlyTotal = self.calculateEnhancedProjection(dailyCosts: dailyCosts)
                    
                    // Update cost trend if we have last month data
                    self.updateCostTrend(for: profile.name)
                    
                    // Detect anomalies with daily and service data
                    self.detectEnhancedAnomalies(for: profile.name, dailyCosts: dailyCosts, serviceCosts: services)
                    
                    // Check for cost alerts
                    let budget = self.getBudget(for: profile.name)
                    let status = self.calculateBudgetStatus(cost: totalAmount, budget: budget)
                    self.alertManager.checkAndSendAlerts(for: profile.name, cost: totalAmount, budget: budget, status: status)
                    
                    // Check for anomaly alerts
                    if !self.anomalies.isEmpty {
                        self.alertManager.checkAndSendAnomalyAlerts(for: profile.name, anomalies: self.anomalies)
                    }
                    
                    // Reset circuit breaker on success
                    if self.circuitBreakerTripped {
                        self.log(.info, category: "API", "Circuit breaker reset after successful API call")
                    }
                    self.consecutiveAPIFailures = 0
                    self.circuitBreakerTripped = false
                    
                    // Record successful API request
                    let duration = Date().timeIntervalSince(startTime)
                    self.recordAPIRequest(profile: profile.name, endpoint: "GetCostAndUsage-Daily", success: true, duration: duration)
                    self.log(.info, category: "API", "Fetched MTD: \(totalAmount), Daily entries: \(dailyCosts.count), Services: \(services.count)")
                    
                    // Save cache to disk
                    self.saveCostCache()
                    
                    // Also fetch last month data (with caching)
                    Task {
                        await self.fetchLastMonthData(for: profile.name)
                    }
                }
            } else {
                // No data returned
                let duration = Date().timeIntervalSince(startTime)
                await MainActor.run {
                    self.handleAPIFailure(duration: duration, profile: profile.name, error: "No data returned")
                }
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let errorMessage = error.localizedDescription
            
            // Enhanced error logging
            log(.error, category: "API", "Failed to fetch cost data for profile '\(profile.name)'")
            log(.error, category: "API", "Error type: \(type(of: error))")
            log(.error, category: "API", "Error description: \(errorMessage)")
            
            // Check for specific error types
            if let awsError = error as? AWSSDKIdentity.AWSCredentialIdentityResolverError {
                log(.error, category: "API", "AWS Credential Identity Resolver Error detected")
                log(.error, category: "API", "This usually means:")
                log(.error, category: "API", "  1. Profile doesn't exist in AWS config")
                log(.error, category: "API", "  2. No credentials configured for the profile")
                log(.error, category: "API", "  3. SSO session expired (need to run 'aws sso login')")
                log(.error, category: "API", "  4. Temporary credentials expired")
                log(.error, category: "API", "  5. AWS SDK can't find config/credentials files")
            }
            
            await MainActor.run {
                self.handleAPIFailure(duration: duration, profile: profile.name, error: errorMessage)
            }
        }
        
        await MainActor.run {
            self.isLoading = false
            self.isLoadingServices = false
        }
    }
    
    // Fetch cost breakdown by service
    func fetchServiceBreakdown() async {
        guard let profile = selectedProfile else { return }
        
        // Check if we can make another API call
        if !canMakeAPICall() {
            log(.warning, category: "API", "Cannot fetch service breakdown - rate limited")
            await MainActor.run {
                self.isRateLimited = true
                self.errorMessage = "Rate limited. Please wait \(secondsUntilNextAllowedCall()) seconds."
            }
            return
        }
        
        log(.info, category: "API", "Fetching service breakdown for profile: \(profile.name)")
        let startTime = Date()
        
        await MainActor.run {
            self.isLoadingServices = true
            self.serviceCosts = []
        }
        
        do {
            let credentialsProvider = try createAWSCredentialsProvider(for: profile.name)
            
            let config = try await CostExplorerClient.CostExplorerClientConfiguration(
                awsCredentialIdentityResolver: credentialsProvider,
                region: profile.region ?? "us-east-1"
            )
            let client = CostExplorerClient(config: config)
            
            let calendar = Calendar.current
            let now = Date()
            
            // Start date is the beginning of the current month
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            
            // End date is today (inclusive)
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: now)!
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let input = GetCostAndUsageInput(
                granularity: .monthly,
                groupBy: [.init(key: "SERVICE", type: .dimension)],
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
               let groups = resultByTime.groups {
                
                var services: [ServiceCost] = []
                
                for group in groups {
                    if let serviceName = group.keys?.first,
                       let metrics = group.metrics,
                       let unblendedCost = metrics["UnblendedCost"],
                       let amountString = unblendedCost.amount,
                       let currency = unblendedCost.unit,
                       let amount = Decimal(string: amountString) {
                        
                        // Only include services with non-zero costs
                        if amount > 0 {
                            services.append(ServiceCost(
                                serviceName: serviceName,
                                amount: amount,
                                currency: currency
                            ))
                        }
                    }
                }
                
                // Sort by amount descending
                services.sort()
                
                // Capture services in a local constant for the closure
                let sortedServices = services
                
                await MainActor.run {
                    self.serviceCosts = sortedServices
                    
                    // Re-run anomaly detection with service data if we have cost data
                    if let cost = self.costData.first {
                        self.detectAnomalies(for: cost.profileName, currentAmount: cost.amount, serviceCosts: sortedServices)
                    }
                    
                    // Record successful API request
                    let duration = Date().timeIntervalSince(startTime)
                    self.recordAPIRequest(profile: profile.name, endpoint: "GetCostAndUsage-ServiceBreakdown", success: true, duration: duration)
                    self.log(.info, category: "API", "Service breakdown loaded: \(sortedServices.count) services")
                }
            } else {
                // No data returned
                let duration = Date().timeIntervalSince(startTime)
                self.recordAPIRequest(profile: profile.name, endpoint: "GetCostAndUsage-ServiceBreakdown", success: false, duration: duration, error: "No data returned")
                self.log(.warning, category: "API", "No service breakdown data returned")
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let errorMessage = error.localizedDescription
            log(.error, category: "API", "Error fetching service breakdown: \(errorMessage)")
            recordAPIRequest(profile: profile.name, endpoint: "GetCostAndUsage-ServiceBreakdown", success: false, duration: duration, error: errorMessage)
        }
        
        await MainActor.run {
            self.isLoadingServices = false
        }
    }
    
    // Fetch cost for a specific profile (used by Multi-Profile Dashboard)
    func fetchCostForProfile(_ profile: AWSProfile) async throws -> Decimal {
        log(.info, category: "API", "Fetching cost data for profile: \(profile.name)")
        let startTime = Date()
        
        do {
            // Configure AWS credentials provider to use the specific profile
            let credentialsProvider = try createAWSCredentialsProvider(for: profile.name)
            
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
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let input = GetCostAndUsageInput(
                granularity: .monthly,
                metrics: ["UnblendedCost"],
                timePeriod: .init(
                    end: dateFormatter.string(from: endOfToday),
                    start: dateFormatter.string(from: startOfMonth)
                )
            )
            
            let output = try await client.getCostAndUsage(input: input)
            
            if let resultByTime = output.resultsByTime?.first,
               let metrics = resultByTime.total,
               let unblendedCost = metrics["UnblendedCost"],
               let amountString = unblendedCost.amount,
               let amount = Decimal(string: amountString) {
                
                // Record successful API request
                let duration = Date().timeIntervalSince(startTime)
                recordAPIRequest(profile: profile.name, endpoint: "GetCostAndUsage", success: true, duration: duration)
                log(.info, category: "API", "Cost data fetched for \(profile.name): \(amount)")
                
                return amount
            } else {
                let duration = Date().timeIntervalSince(startTime)
                recordAPIRequest(profile: profile.name, endpoint: "GetCostAndUsage", success: false, duration: duration, error: "No data returned")
                throw CostFetchError.noData
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let errorMessage = error.localizedDescription
            log(.error, category: "API", "Error fetching cost for \(profile.name): \(errorMessage)")
            recordAPIRequest(profile: profile.name, endpoint: "GetCostAndUsage", success: false, duration: duration, error: errorMessage)
            throw error
        }
    }
    
    // Load demo data for ACME profile
    func loadDemoDataForACME() async {
        log(.info, category: "Demo", "Loading demo data for ACME profile")
        
        await MainActor.run {
            // Clear any existing cache for ACME to ensure fresh data
            self.costCache.removeValue(forKey: "acme")
            self.cacheStatus.removeValue(forKey: "acme")
            self.dailyCostsByProfile.removeValue(forKey: "acme")
            self.dailyServiceCostsByProfile.removeValue(forKey: "acme")
            self.lastMonthData.removeValue(forKey: "acme")
            self.lastMonthDataFetchDate.removeValue(forKey: "acme")
            self.lastMonthServiceCosts.removeValue(forKey: "acme")
            
            self.isLoading = true
            self.isLoadingServices = true
            self.errorMessage = nil
            self.isRateLimited = false
        }
        
        // Simulate a brief loading delay for realism
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let dayOfMonth = calendar.component(.day, from: now)
        
        // Generate impressive but realistic cost data - current month performing better
        let mtdTotal = Decimal(67834.12) // Month-to-date total (14 days worth)
        let lastMonthTotal = Decimal(89456.78) // Last month was higher (current is 24% lower - GREEN!)
        let projectedTotal = Decimal(145123.45) // Projected month-end
        
        // Create daily costs with realistic variation (14 days of history)
        var dailyCosts: [DailyCost] = []
        var dailyServiceCosts: [DailyServiceCost] = []
        // Calculate base daily amount for exactly 14 days
        let baseDaily = mtdTotal / Decimal(14)
        
        // Generate exactly 14 days of historical data 
        let daysToGenerate = 14
        
        // Generate 14 days of comprehensive historical data with realistic mixed patterns
        for dayOffset in (1-daysToGenerate)...0 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            
            // Create realistic daily patterns with mix of higher/lower than trend
            let dayOfWeek = calendar.component(.weekday, from: date)
            let isWeekend = dayOfWeek == 1 || dayOfWeek == 7 // Sunday = 1, Saturday = 7
            
            // Weekend costs are typically 30% lower (less business activity)
            let weekendMultiplier = isWeekend ? Decimal(0.7) : Decimal(1.0)
            
            // Create realistic variation with some days significantly higher/lower
            let dayNumber = dayOffset + daysToGenerate + 1  // 1-14 for the 14 days
            var trendMultiplier: Decimal
            
            // Create a realistic mixed pattern for full 14 days:
            switch dayNumber {
            case 1, 5, 9, 13:  // Some days much higher (deployment days, batch jobs)
                trendMultiplier = Decimal(1.4 + Double.random(in: 0...0.3))  // 40-70% higher
            case 3, 7, 11:     // Some days much lower (maintenance windows, weekends)
                trendMultiplier = Decimal(0.3 + Double.random(in: 0...0.2))  // 30-50% lower
            case 2, 4, 6, 8, 10, 12, 14: // Most days moderately different
                trendMultiplier = Decimal(0.8 + Double.random(in: 0...0.4))  // ±20% variation
            default:           // Fallback (shouldn't hit with 1-14 range)
                trendMultiplier = Decimal(0.95 + Double.random(in: 0...0.1)) // ±5% variation
            }
            
            let dailyAmount = baseDaily * weekendMultiplier * trendMultiplier
            
            dailyCosts.append(DailyCost(
                date: date,
                amount: dailyAmount,
                currency: "USD"
            ))
            
            // Distribute across services with slight daily variations
            let serviceVariation = 0.9 + Double.random(in: 0...0.2) // ±10% service variation
            
            let ec2Amount = dailyAmount * Decimal(0.35 * serviceVariation)
            let rdsAmount = dailyAmount * Decimal(0.25 * serviceVariation)
            let s3Amount = dailyAmount * Decimal(0.15 * serviceVariation)
            let lambdaAmount = dailyAmount * Decimal(0.10 * serviceVariation)
            let cloudFrontAmount = dailyAmount * Decimal(0.08 * serviceVariation)
            let dynamoAmount = dailyAmount * Decimal(0.03 * serviceVariation)
            let apiGatewayAmount = dailyAmount * Decimal(0.02 * serviceVariation)
            let kmsAmount = dailyAmount * Decimal(0.01 * serviceVariation)
            let snsAmount = dailyAmount * Decimal(0.005 * serviceVariation)
            let costExplorerAmount = dailyAmount * Decimal(0.005 * serviceVariation)
            
            dailyServiceCosts.append(contentsOf: [
                DailyServiceCost(date: date, serviceName: "Amazon Elastic Compute Cloud - Compute", amount: ec2Amount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "Amazon Relational Database Service", amount: rdsAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "Amazon Simple Storage Service", amount: s3Amount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "AWS Lambda", amount: lambdaAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "Amazon CloudFront", amount: cloudFrontAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "Amazon DynamoDB", amount: dynamoAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "Amazon API Gateway", amount: apiGatewayAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "AWS Key Management Service", amount: kmsAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "Amazon Simple Notification Service", amount: snsAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "AWS Cost Explorer", amount: costExplorerAmount, currency: "USD")
            ])
        }
        
        // Create service breakdown
        let serviceCosts = [
            ServiceCost(serviceName: "Amazon Elastic Compute Cloud - Compute", amount: mtdTotal * Decimal(0.35), currency: "USD"),
            ServiceCost(serviceName: "Amazon Relational Database Service", amount: mtdTotal * Decimal(0.25), currency: "USD"),
            ServiceCost(serviceName: "Amazon Simple Storage Service", amount: mtdTotal * Decimal(0.15), currency: "USD"),
            ServiceCost(serviceName: "AWS Lambda", amount: mtdTotal * Decimal(0.10), currency: "USD"),
            ServiceCost(serviceName: "Amazon CloudFront", amount: mtdTotal * Decimal(0.08), currency: "USD"),
            ServiceCost(serviceName: "Amazon DynamoDB", amount: mtdTotal * Decimal(0.03), currency: "USD"),
            ServiceCost(serviceName: "Amazon API Gateway", amount: mtdTotal * Decimal(0.02), currency: "USD"),
            ServiceCost(serviceName: "AWS Key Management Service", amount: mtdTotal * Decimal(0.01), currency: "USD"),
            ServiceCost(serviceName: "Amazon Simple Notification Service", amount: mtdTotal * Decimal(0.005), currency: "USD"),
            ServiceCost(serviceName: "AWS Cost Explorer", amount: mtdTotal * Decimal(0.005), currency: "USD")
        ].sorted(by: { $0.amount > $1.amount })
        
        // Create cache entry
        // Set startDate to 14 days ago to include all generated historical data
        let startDate14DaysAgo = calendar.date(byAdding: .day, value: -13, to: now)!
        
        let cacheEntry = CostCacheEntry(
            profileName: "acme",
            fetchDate: Date(),
            mtdTotal: mtdTotal,
            currency: "USD",
            dailyCosts: dailyCosts,
            serviceCosts: serviceCosts,
            startDate: startDate14DaysAgo,
            endDate: Date()
        )
        
        await MainActor.run {
            // Store in cache
            self.costCache["acme"] = cacheEntry
            self.dailyCostsByProfile["acme"] = dailyCosts
            self.dailyServiceCostsByProfile["acme"] = dailyServiceCosts
            self.cacheStatus["acme"] = Date()
            
            // Update UI data
            self.costData.removeAll()
            self.costData.append(CostData(
                profileName: "acme",
                amount: mtdTotal,
                currency: "USD"
            ))
            
            // Update service costs
            self.serviceCosts = serviceCosts
            
            // Calculate analytics
            self.projectedMonthlyTotal = projectedTotal
            
            // Set comparison data
            self.lastMonthData["acme"] = CostData(
                profileName: "acme",
                amount: lastMonthTotal,
                currency: "USD"
            )
            self.lastMonthDataFetchDate["acme"] = Date()
            self.lastMonthServiceCosts["acme"] = serviceCosts.map { service in
                ServiceCost(
                    serviceName: service.serviceName,
                    amount: service.amount * Decimal(1.32), // Last month was 32% higher (current is 24% lower)
                    currency: service.currency
                )
            }
            
            // Clear loading states
            self.isLoading = false
            self.isLoadingServices = false
            self.errorMessage = nil
            
            // Record successful "API" request for demo
            self.recordAPIRequest(profile: "acme", endpoint: "Demo Data", success: true, duration: 0.5)
            
            // Mark API call time
            self.lastAPICallTime = Date()
            
            log(.info, category: "Demo", "Demo data loaded successfully for ACME profile")
        }
    }
    
    // Fetch last month's cost data with aggressive caching
    func fetchLastMonthData(for profileName: String, force: Bool = false) async {
        log(.info, category: "API", "fetchLastMonthData called for \(profileName), force: \(force)")
        
        // Check if we already have cached data for this month
        let calendar = Calendar.current
        let now = Date()
        
        // Check if cached data exists and is from this month
        if !force,
           let lastFetchDate = lastMonthDataFetchDate[profileName],
           calendar.isDate(lastFetchDate, equalTo: now, toGranularity: .month),
           lastMonthData[profileName] != nil {
            // We already fetched last month's data this month, no need to fetch again
            log(.info, category: "Cache", "Using cached last month data for \(profileName)")
            return
        }
        
        guard let profile = profiles.first(where: { $0.name == profileName }) else {
            log(.error, category: "API", "Profile not found: \(profileName)")
            return
        }
        
        // Set loading state
        await MainActor.run {
            self.lastMonthDataLoading[profileName] = true
        }
        
        // Wait a bit if we just made another API call
        if !canMakeAPICall() {
            let waitTime = secondsUntilNextAllowedCall()
            log(.warning, category: "API", "Waiting \(waitTime) seconds before fetching last month data")
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        log(.info, category: "API", "Fetching last month's cost data for profile: \(profileName)")
        let startTime = Date()
        
        do {
            // Configure AWS credentials provider
            let credentialsProvider = try createAWSCredentialsProvider(for: profileName)
            let config = try await CostExplorerClient.CostExplorerClientConfiguration(
                awsCredentialIdentityResolver: credentialsProvider,
                region: profile.region
            )
            let client = CostExplorerClient(config: config)
            
            // Calculate last month's date range
            let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: calendar.startOfDay(for: now))!
            let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonthStart)!.start
            let endOfLastMonth = calendar.dateInterval(of: .month, for: lastMonthStart)!.end
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            // Fetch total cost for last month
            let costInput = GetCostAndUsageInput(
                granularity: .monthly,
                metrics: ["UnblendedCost"],
                timePeriod: .init(
                    end: formatter.string(from: endOfLastMonth),
                    start: formatter.string(from: startOfLastMonth)
                )
            )
            
            // Record API call time BEFORE making the request
            await MainActor.run {
                self.lastAPICallTime = Date()
            }
            
            let costResponse = try await client.getCostAndUsage(input: costInput)
            
            if let resultsByTime = costResponse.resultsByTime,
               let firstResult = resultsByTime.first,
               let costString = firstResult.total?["UnblendedCost"]?.amount,
               let costDecimal = Decimal(string: costString) {
                
                let costData = CostData(
                    profileName: profileName,
                    amount: costDecimal,
                    currency: firstResult.total?["UnblendedCost"]?.unit ?? "USD"
                )
                
                await MainActor.run {
                    self.lastMonthData[profileName] = costData
                    self.lastMonthDataFetchDate[profileName] = Date()
                    self.saveLastMonthData()
                    
                    // Update cost trend now that we have last month data
                    self.updateCostTrend(for: profileName)
                }
                
                log(.info, category: "API", "Successfully fetched last month cost for \(profileName): \(costDecimal)")
                
                // Also fetch service breakdown for last month
                await fetchLastMonthServiceBreakdown(for: profileName, client: client, startDate: startOfLastMonth, endDate: endOfLastMonth)
            }
            
            let duration = Date().timeIntervalSince(startTime)
            recordAPIRequest(profile: profileName, endpoint: "GetCostAndUsage-LastMonth", success: true, duration: duration)
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let errorMessage = error.localizedDescription
            log(.error, category: "API", "Error fetching last month cost for \(profileName): \(errorMessage)")
            recordAPIRequest(profile: profileName, endpoint: "GetCostAndUsage-LastMonth", success: false, duration: duration, error: errorMessage)
        }
        
        // Clear loading state
        await MainActor.run {
            self.lastMonthDataLoading[profileName] = false
        }
    }
    
    // Fetch service breakdown for last month
    private func fetchLastMonthServiceBreakdown(for profileName: String, client: CostExplorerClient, startDate: Date, endDate: Date) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let input = GetCostAndUsageInput(
            granularity: .monthly,
            groupBy: [.init(key: "SERVICE", type: .dimension)],
            metrics: ["UnblendedCost"],
            timePeriod: .init(
                end: formatter.string(from: endDate),
                start: formatter.string(from: startDate)
            )
        )
        
        do {
            let response = try await client.getCostAndUsage(input: input)
            var services: [ServiceCost] = []
            
            if let resultsByTime = response.resultsByTime,
               let firstResult = resultsByTime.first,
               let groups = firstResult.groups {
                
                for group in groups {
                    if let serviceName = group.keys?.first,
                       let costString = group.metrics?["UnblendedCost"]?.amount,
                       let costDecimal = Decimal(string: costString),
                       costDecimal > 0 {
                        
                        let serviceCost = ServiceCost(
                            serviceName: serviceName,
                            amount: costDecimal,
                            currency: group.metrics?["UnblendedCost"]?.unit ?? "USD"
                        )
                        services.append(serviceCost)
                    }
                }
                
                // Sort by cost descending
                services.sort { $0.amount > $1.amount }
                
                await MainActor.run {
                    self.lastMonthServiceCosts[profileName] = services
                    self.saveLastMonthData()
                }
                
                log(.info, category: "API", "Fetched \(services.count) services for last month breakdown")
            }
        } catch {
            log(.error, category: "API", "Error fetching last month service breakdown: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Enhanced Cache Management
    
    // Load data from cache
    private func loadFromCache(_ cacheEntry: CostCacheEntry) async {
        await MainActor.run {
            // Update UI data from cache
            self.costData.removeAll()
            self.costData.append(CostData(
                profileName: cacheEntry.profileName,
                amount: cacheEntry.mtdTotal,
                currency: cacheEntry.currency
            ))
            
            // Update service costs
            self.serviceCosts = cacheEntry.serviceCosts
            
            // Store daily costs
            self.dailyCostsByProfile[cacheEntry.profileName] = cacheEntry.dailyCosts
            
            // Update projections and trends
            self.projectedMonthlyTotal = self.calculateEnhancedProjection(dailyCosts: cacheEntry.dailyCosts)
            self.updateCostTrend(for: cacheEntry.profileName)
            
            // Update loading states
            self.isLoading = false
            self.isLoadingServices = false
        }
    }
    
    // Save cache to disk
    private func saveCostCache() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(costCache)
            UserDefaults.standard.set(data, forKey: costCacheKey)
            
            // Also save daily costs
            let dailyData = try encoder.encode(dailyCostsByProfile)
            UserDefaults.standard.set(dailyData, forKey: dailyCostsKey)
            
            // Save daily service costs for histograms
            let dailyServiceData = try encoder.encode(dailyServiceCostsByProfile)
            UserDefaults.standard.set(dailyServiceData, forKey: dailyServiceCostsKey)
            
            log(.debug, category: "Cache", "Saved cache data for \(costCache.count) profiles")
        } catch {
            log(.error, category: "Cache", "Failed to save cache: \(error.localizedDescription)")
        }
    }
    
    // Load cache from disk
    private func loadCostCache() {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            if let data = UserDefaults.standard.data(forKey: costCacheKey) {
                costCache = try decoder.decode([String: CostCacheEntry].self, from: data)
                log(.debug, category: "Cache", "Loaded cache data for \(costCache.count) profiles")
            }
            
            if let dailyData = UserDefaults.standard.data(forKey: dailyCostsKey) {
                dailyCostsByProfile = try decoder.decode([String: [DailyCost]].self, from: dailyData)
                log(.debug, category: "Cache", "Loaded daily cost data for \(dailyCostsByProfile.count) profiles")
            }
            
            if let dailyServiceData = UserDefaults.standard.data(forKey: dailyServiceCostsKey) {
                dailyServiceCostsByProfile = try decoder.decode([String: [DailyServiceCost]].self, from: dailyServiceData)
                log(.debug, category: "Cache", "Loaded daily service cost data for \(dailyServiceCostsByProfile.count) profiles")
            }
        } catch {
            log(.error, category: "Cache", "Failed to load cache: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Circuit Breaker & Error Handling
    
    // Handle API failures with circuit breaker logic
    private func handleAPIFailure(duration: TimeInterval, profile: String, error: String) {
        consecutiveAPIFailures += 1
        
        if consecutiveAPIFailures >= maxConsecutiveFailures {
            circuitBreakerTripped = true
            log(.error, category: "API", "Circuit breaker tripped after \(consecutiveAPIFailures) failures")
            errorMessage = "Multiple API failures detected. Circuit breaker active."
        } else {
            errorMessage = "API request failed: \(error)"
        }
        
        recordAPIRequest(profile: profile, endpoint: "GetCostAndUsage-Daily", success: false, duration: duration, error: error)
        log(.error, category: "API", "Error fetching cost for profile \(profile): \(error)")
        
        isLoading = false
        isLoadingServices = false
    }
    
    // MARK: - Enhanced Analytics
    
    // Calculate enhanced projection using daily trends
    private func calculateEnhancedProjection(dailyCosts: [DailyCost]) -> Decimal? {
        guard !dailyCosts.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let dayOfMonth = calendar.component(.day, from: now)
        
        // Calculate trend-based projection (last 7 days average)
        let recentCosts = dailyCosts.suffix(7)
        guard !recentCosts.isEmpty else { return nil }
        
        let recentTotal = recentCosts.reduce(Decimal(0)) { $0 + $1.amount }
        let dailyAverage = recentTotal / Decimal(recentCosts.count)
        let remainingDays = daysInMonth - dayOfMonth
        
        let currentTotal = dailyCosts.reduce(Decimal(0)) { $0 + $1.amount }
        return currentTotal + (dailyAverage * Decimal(remainingDays))
    }
    
    // Enhanced anomaly detection using daily and service data
    private func detectEnhancedAnomalies(for profileName: String, dailyCosts: [DailyCost], serviceCosts: [ServiceCost]) {
        guard enableAnomalyDetection else { return }
        
        var detectedAnomalies: [SpendingAnomaly] = []
        
        // Daily cost anomalies
        if dailyCosts.count >= 7 {
            let recentWeek = Array(dailyCosts.suffix(7))
            let average = recentWeek.reduce(Decimal(0)) { $0 + $1.amount } / Decimal(7)
            
            for cost in recentWeek {
                let deviation = abs((cost.amount - average) / average) * 100
                if deviation > Decimal(anomalyThreshold) {
                    detectedAnomalies.append(SpendingAnomaly(
                        type: cost.amount > average ? .unusualSpike : .suddenDrop,
                        severity: NSDecimalNumber(decimal: deviation).doubleValue > 50 ? .critical : .warning,
                        message: "Daily spending \(cost.amount > average ? "spike" : "drop") of \(Int(NSDecimalNumber(decimal: deviation).doubleValue))%",
                        percentage: NSDecimalNumber(decimal: deviation).doubleValue
                    ))
                }
            }
        }
        
        // Service-level anomalies (top 3 services only)
        let topServices = Array(serviceCosts.prefix(3))
        for service in topServices {
            // Compare against historical service costs if available
            if let historical = lastMonthServiceCosts[profileName]?.first(where: { $0.serviceName == service.serviceName }) {
                let change = ((service.amount - historical.amount) / historical.amount) * 100
                if abs(change) > Decimal(anomalyThreshold) {
                    detectedAnomalies.append(SpendingAnomaly(
                        type: change > 0 ? .unusualSpike : .suddenDrop,
                        severity: NSDecimalNumber(decimal: abs(change)).doubleValue > 100 ? .critical : .warning,
                        message: "\(service.serviceName) cost changed by \(Int(NSDecimalNumber(decimal: change).doubleValue))% vs last month",
                        percentage: NSDecimalNumber(decimal: abs(change)).doubleValue
                    ))
                }
            }
        }
        
        anomalies = detectedAnomalies
        log(.info, category: "Analytics", "Detected \(anomalies.count) anomalies for \(profileName)")
    }
}

// Error enum for cost fetching
enum CostFetchError: LocalizedError {
    case noData
    
    var errorDescription: String? {
        switch self {
        case .noData:
            return "No cost data returned from AWS"
        }
    }
}

// MARK: - Custom Status Bar Implementation with Popover

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var awsManager: AWSManager
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    
    init(awsManager: AWSManager) {
        self.awsManager = awsManager
        super.init()
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create popover with SwiftUI content
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 500)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: PopoverContentView()
                .environmentObject(awsManager)
        )
        
        updateStatusItemView()
        
        // Setup click handler
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Subscribe to changes in cost data and settings
        awsManager.$costData
            .sink { [weak self] _ in
                self?.updateStatusItemView()
            }
            .store(in: &cancellables)
        
        awsManager.$isLoading
            .sink { [weak self] _ in
                self?.updateStatusItemView()
            }
            .store(in: &cancellables)
        
        // Listen to UserDefaults changes for display settings
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.updateStatusItemView()
            }
            .store(in: &cancellables)
        
        // Monitor for clicks outside popover
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if self?.popover.isShown == true {
                self?.closePopover()
            }
        }
    }
    
    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
    
    func updateStatusItemView() {
        guard let button = statusItem.button else { return }
        
        // Get display settings with defaults
        let displayFormat = UserDefaults.standard.string(forKey: "MenuBarDisplayFormat") ?? "full"
        let showColors = UserDefaults.standard.object(forKey: "ShowMenuBarColors") as? Bool ?? true
        let showCurrencySymbol = UserDefaults.standard.object(forKey: "ShowCurrencySymbol") as? Bool ?? true
        let decimalPlaces = UserDefaults.standard.object(forKey: "DecimalPlaces") as? Int ?? 2
        
        // Force thousands separator to always be true for now
        let useThousandsSeparator = true
        // Don't set UserDefaults here - it causes infinite recursion!
        
        // Set the cloud icon
        if displayFormat == "iconOnly" {
            // Use colorful cloud icon for icon-only mode
            button.image = MenuBarCloudIcon.createImage(size: 18)
        } else {
            // Use template cloud icon when showing text
            button.image = MenuBarCloudIcon.createTemplateImage(size: 16)
        }
        
        var titleString = ""
        var titleColor: NSColor? = nil
        
        // Setup number formatter
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = useThousandsSeparator
        
        switch displayFormat {
        case "abbreviated":
            if let cost = awsManager.costData.first {
                let amount = NSDecimalNumber(decimal: cost.amount).doubleValue
                formatter.maximumFractionDigits = 0
                let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "0"
                titleString = showCurrencySymbol ? "$\(formattedAmount)" : formattedAmount
                if showColors {
                    titleColor = getColorForCost(cost)
                }
            } else if awsManager.isLoading {
                titleString = "..."
            } else {
                titleString = "$"
            }
            
        case "full":
            if let cost = awsManager.costData.first {
                let amount = NSDecimalNumber(decimal: cost.amount).doubleValue
                formatter.minimumFractionDigits = decimalPlaces
                formatter.maximumFractionDigits = decimalPlaces
                let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "0"
                titleString = showCurrencySymbol ? "$\(formattedAmount)" : formattedAmount
                if showColors {
                    titleColor = getColorForCost(cost)
                }
            } else if awsManager.isLoading {
                titleString = "Loading..."
            } else {
                titleString = "AWS"
            }
            
        case "iconOnly":
            titleString = "" // No text when showing icon only
        
        default:
            titleString = "$"
        }
        
        // Apply the title with optional color
        if showColors && titleColor != nil {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: titleColor!,
                .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            ]
            button.attributedTitle = NSAttributedString(string: titleString, attributes: attributes)
        } else {
            // Use regular title without color
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            ]
            button.attributedTitle = NSAttributedString(string: titleString, attributes: attributes)
        }
    }
    
    private func getColorForCost(_ cost: CostData) -> NSColor? {
        // Prioritize last month comparison over budget for better user feedback
        if let lastMonthCost = awsManager.lastMonthData[cost.profileName],
           lastMonthCost.amount > 0 {
            let currentAmount = NSDecimalNumber(decimal: cost.amount).doubleValue
            let lastAmount = NSDecimalNumber(decimal: lastMonthCost.amount).doubleValue
            let percentChange = ((currentAmount - lastAmount) / lastAmount) * 100
            
            // Green for spending less than last month (good)
            if percentChange < -5 {
                return NSColor.systemGreen
            }
            // Orange/Red for spending significantly more than last month (concerning)
            else if percentChange > 20 {
                return NSColor.systemRed
            }
            else if percentChange > 10 {
                return NSColor.systemOrange
            }
            // White/default for small changes (within normal range)
            else {
                return nil
            }
        }
        
        // Fallback to budget-based coloring if no last month data
        let budget = awsManager.getBudget(for: cost.profileName)
        if budget.monthlyBudget > 0 {
            let amount = NSDecimalNumber(decimal: cost.amount).doubleValue
            let percentUsed = (amount / NSDecimalNumber(decimal: budget.monthlyBudget).doubleValue) * 100
            if percentUsed >= 100 {
                return NSColor.systemRed
            } else if percentUsed >= 80 {
                return NSColor.systemOrange
            } else if percentUsed >= 60 {
                return NSColor.systemYellow
            } else {
                return NSColor.systemGreen
            }
        }
        
        // No color if no comparison data available
        return nil
    }
    
    @objc func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    func closePopover() {
        popover.performClose(nil)
    }
}

// MARK: - Popover Content View with Full Rendering

struct PopoverContentView: View {
    @EnvironmentObject var awsManager: AWSManager
    @State private var showAllServices = false
    @State private var helpButtonHovered = false
    @State private var quitButtonHovered = false
    @State private var refreshButtonHovered = false
    @State private var settingsButtonHovered = false
    @State private var consoleButtonHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("AWS Cost Monitor")
                    .font(.system(size: 16, weight: .semibold))
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
                    Picker("", selection: $awsManager.selectedProfile) {
                        ForEach(awsManager.realProfiles, id: \.self) { profile in
                            Text(profile.name).tag(Optional(profile))
                        }
                        if !awsManager.realProfiles.isEmpty && !awsManager.demoProfiles.isEmpty {
                            Divider()
                        }
                        ForEach(awsManager.demoProfiles, id: \.self) { profile in
                            Text("\(profile.name) (Demo)").tag(Optional(profile))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .labelsHidden()
                    .frame(maxWidth: 150)
                    .onChange(of: awsManager.selectedProfile) { newProfile in
                        if let profile = newProfile {
                            // Check if we have cached data for this profile
                            if let cachedData = awsManager.costCache[profile.name] {
                                // Use cached data and update display
                                let costData = CostData(
                                    profileName: cachedData.profileName,
                                    amount: cachedData.mtdTotal,
                                    currency: cachedData.currency
                                )
                                awsManager.costData = [costData]
                                awsManager.serviceCosts = cachedData.serviceCosts
                                // Clear any error message since we have cached data
                                awsManager.errorMessage = nil
                                awsManager.isRateLimited = false
                                
                                // Only fetch if cache is stale
                                let budget = awsManager.getBudget(for: profile.name)
                                if !cachedData.isValidForBudget(budget) {
                                    Task {
                                        await awsManager.fetchCostForSelectedProfile()
                                    }
                                }
                            } else {
                                // No cache, fetch data
                                Task {
                                    await awsManager.fetchCostForSelectedProfile()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
            
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
                                // Last updated time in header
                                if let selectedProfile = awsManager.selectedProfile,
                                   let cacheEntry = awsManager.costCache[selectedProfile.name] {
                                    Text("Last updated: \(cacheEntry.fetchDate, formatter: lastRefreshFormatter)")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
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
                                                serviceName: service.serviceName
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
            
            Divider()
            
            // Bottom buttons
            HStack {
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
                }
                .buttonStyle(.plain)
                .onHover { isHovered in
                    refreshButtonHovered = isHovered
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
                }
                .buttonStyle(.plain)
                .onHover { isHovered in
                    settingsButtonHovered = isHovered
                }
                
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
                }
                .buttonStyle(.plain)
                .onHover { isHovered in
                    consoleButtonHovered = isHovered
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .frame(width: 360, height: 500)
    }
    
    private var lastRefreshFormatter: DateFormatter {
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
        if budget.monthlyBudget > 0 {
            let amount = NSDecimalNumber(decimal: cost.amount).doubleValue
            let percentUsed = (amount / NSDecimalNumber(decimal: budget.monthlyBudget).doubleValue) * 100
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

// MARK: - Real Histogram View with Full Graphics

struct RealHistogramView: View {
    let dailyServiceCosts: [DailyServiceCost]
    let serviceName: String
    @EnvironmentObject var awsManager: AWSManager
    @State private var hoveredIndex: Int? = nil
    
    private func buildFullData() -> [DailyServiceCost] {
        let last14Days = getLast14DaysData()
        let calendar = Calendar.current
        let today = Date()
        var allDays: [DailyServiceCost] = []
        for i in (0..<14).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                if let existingDay = last14Days.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                    allDays.append(existingDay)
                } else {
                    allDays.append(DailyServiceCost(date: date, serviceName: serviceName, amount: 0, currency: "USD"))
                }
            }
        }
        return allDays
    }
    
    var body: some View {
        let allDays = buildFullData()
        let amounts = allDays.map { NSDecimalNumber(decimal: $0.amount).doubleValue }
        let maxAmount = amounts.max() ?? 1.0
        
        // Debug: Log the actual count
        let _ = print("🔵 RealHistogramView: FORCED to \(allDays.count) bars for service: \(serviceName)")
        
        // Get last month's average daily spend for comparison
        let lastMonthAvg = getLastMonthDailyAverage()
        
        ZStack(alignment: .topLeading) {
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 1) {  // Minimal spacing between bars
                    ForEach(Array(amounts.enumerated()), id: \.offset) { index, amount in
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(barColor(amount: amount, lastMonthAvg: lastMonthAvg))
                                .frame(width: max(10, (geometry.size.width - CGFloat(13 * 1)) / 14), height: max(2, CGFloat(amount / maxAmount) * 30))  // Use almost all available width
                                .cornerRadius(1)
                                .onHover { isHovering in
                                    hoveredIndex = isHovering ? index : nil
                                }
                        }
                        .frame(height: 32)
                    }
                }
            }
            .frame(height: 32)
            
            // Tooltip overlay positioned above the hovered bar
            GeometryReader { geometry in
                if let hoveredIndex = hoveredIndex, hoveredIndex < allDays.count {
                    let day = allDays[hoveredIndex]
                    let barWidth = max(10, (geometry.size.width - CGFloat(13 * 1)) / 14)
                    let xPosition = CGFloat(hoveredIndex) * (barWidth + 1) + barWidth / 2 - 30
                    
                    Text("\(day.date, formatter: dateFormatter): \(awsManager.formatCurrency(day.amount))")
                        .font(.system(size: 9))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                        .shadow(radius: 2)
                        .offset(x: xPosition, y: -8)  // Position above the hovered bar
                        .zIndex(1)
                }
            }
            .frame(height: 32)
        }
        .frame(minWidth: 220, idealWidth: 250, maxWidth: 280)  // Give histogram more space
        .padding(.vertical, 2)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    private func barColor(amount: Double, lastMonthAvg: Double) -> Color {
        if amount == 0 {
            return Color.gray.opacity(0.2)
        }
        
        // Compare to last month's daily average
        if lastMonthAvg > 0 {
            let percentDiff = ((amount - lastMonthAvg) / lastMonthAvg) * 100
            if percentDiff > 10 {
                // More than 10% above last month's average - red
                return Color.red.opacity(0.8)
            } else if percentDiff < -10 {
                // More than 10% below last month's average - green
                return Color.green.opacity(0.8)
            }
        }
        
        // Within normal range - blue
        return Color.blue.opacity(0.8)
    }
    
    private func getLastMonthDailyAverage() -> Double {
        // Get the profile name from the current cost data
        guard let cost = awsManager.costData.first,
              let lastMonthData = awsManager.lastMonthServiceCosts[cost.profileName] else {
            return 0
        }
        
        // Find the same service in last month's data
        let lastMonthService = lastMonthData.first { $0.serviceName == serviceName }
        guard let serviceAmount = lastMonthService?.amount else {
            return 0
        }
        
        // Calculate daily average (assuming 30 days in a month)
        return NSDecimalNumber(decimal: serviceAmount).doubleValue / 30.0
    }
    
    private func getLast14DaysData() -> [DailyServiceCost] {
        let calendar = Calendar.current
        let today = Date()
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -13, to: today)!
        
        var result: [DailyServiceCost] = []
        
        // Check if we have any data for this service first
        let serviceData = dailyServiceCosts.filter { $0.serviceName == serviceName }
        
        // If we have no service data at all, return all zeros
        if serviceData.isEmpty {
            for dayOffset in 0..<14 {
                if let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: fourteenDaysAgo) {
                    result.append(DailyServiceCost(
                        date: targetDate,
                        serviceName: serviceName,
                        amount: 0,
                        currency: "USD"
                    ))
                }
            }
            return result
        }
        
        // We have data, so look for each day
        for dayOffset in 0..<14 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: fourteenDaysAgo) else { continue }
            
            let dayStart = calendar.startOfDay(for: targetDate)
            
            // Use calendar comparison instead of date range for better matching
            let serviceCostForDay = dailyServiceCosts.first { cost in
                cost.serviceName == serviceName &&
                calendar.isDate(cost.date, inSameDayAs: dayStart)
            }
            
            if let dayCost = serviceCostForDay {
                result.append(dayCost)
            } else {
                result.append(DailyServiceCost(
                    date: targetDate,
                    serviceName: serviceName,
                    amount: 0,
                    currency: "USD"
                ))
            }
        }
        
        return result
    }
}

// MARK: - SwiftUI View

struct ServiceHistogramView: View {
    let dailyServiceCosts: [DailyServiceCost]
    let serviceName: String
    
    var body: some View {
        let last14Days = getLast14DaysData()
        
        return VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 1) {
                // Enhanced text-based histogram with better visuals
                let histogramText = generateAdvancedHistogram(last14Days)
                
                HStack(spacing: 0) {
                    Text(histogramText.bars)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    Text(" ")
                        .font(.system(size: 6))
                    
                    Text(histogramText.trend)
                        .font(.system(size: 8))
                        .foregroundColor(histogramText.trendColor)
                }
                
                Spacer()
                
                Text("14d")
                    .font(.system(size: 7))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func getLast14DaysData() -> [DailyServiceCost] {
        let calendar = Calendar.current
        let today = Date()
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -13, to: today)!
        
        var result: [DailyServiceCost] = []
        
        // Check if we have any data for this service first
        let serviceData = dailyServiceCosts.filter { $0.serviceName == serviceName }
        
        // If we have no service data at all, return all zeros
        if serviceData.isEmpty {
            for dayOffset in 0..<14 {
                if let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: fourteenDaysAgo) {
                    result.append(DailyServiceCost(
                        date: targetDate,
                        serviceName: serviceName,
                        amount: 0,
                        currency: "USD"
                    ))
                }
            }
            return result
        }
        
        // We have data, so look for each day
        for dayOffset in 0..<14 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: fourteenDaysAgo) else { continue }
            
            let dayStart = calendar.startOfDay(for: targetDate)
            
            // Use calendar comparison instead of date range for better matching
            let serviceCostForDay = dailyServiceCosts.first { cost in
                cost.serviceName == serviceName &&
                calendar.isDate(cost.date, inSameDayAs: dayStart)
            }
            
            if let dayCost = serviceCostForDay {
                result.append(dayCost)
            } else {
                result.append(DailyServiceCost(
                    date: targetDate,
                    serviceName: serviceName,
                    amount: 0,
                    currency: "USD"
                ))
            }
        }
        
        return result
    }
    
    private func generateAdvancedHistogram(_ dailyData: [DailyServiceCost]) -> (bars: String, trend: String, trendColor: Color) {
        let amounts = dailyData.map { NSDecimalNumber(decimal: $0.amount).doubleValue }
        let maxAmount = amounts.max() ?? 0.0
        
        if maxAmount == 0.0 {
            let emptyBars = String(repeating: "▁", count: dailyData.count)
            return (emptyBars, "—", .secondary) // All zero bars with neutral trend
        }
        
        // Create bars using fine-grained Unicode blocks
        let blocks = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
        let bars = amounts.map { amount in
            let normalized = amount / maxAmount
            let blockIndex = Int(normalized * Double(blocks.count - 1))
            return blocks[max(0, min(blockIndex, blocks.count - 1))]
        }.joined()
        
        // Calculate trend: compare first week vs last week for 14-day data
        let dataCount = amounts.count
        if dataCount >= 14 {
            // For 14 days: compare first 7 vs last 7
            let firstWeek = amounts.prefix(7).reduce(0, +) / 7.0
            let lastWeek = amounts.suffix(7).reduce(0, +) / 7.0
            
            let trend: String
            let trendColor: Color
            
            if lastWeek > firstWeek * 1.2 { // 20% increase
                trend = "↗"
                trendColor = .red
            } else if lastWeek < firstWeek * 0.8 { // 20% decrease
                trend = "↘"
                trendColor = .green
            } else {
                trend = "→"
                trendColor = .secondary
            }
            
            return (bars, trend, trendColor)
        } else {
            // For 7 days or less: compare first half vs last half
            let halfPoint = dataCount / 2
            let firstHalf = amounts.prefix(max(1, halfPoint)).reduce(0, +) / Double(max(1, halfPoint))
            let lastHalf = amounts.suffix(max(1, halfPoint)).reduce(0, +) / Double(max(1, halfPoint))
            
            let trend: String
            let trendColor: Color
            
            if lastHalf > firstHalf * 1.2 { // 20% increase
                trend = "↗"
                trendColor = .red
            } else if lastHalf < firstHalf * 0.8 { // 20% decrease
                trend = "↘"
                trendColor = .green
            } else {
                trend = "→"
                trendColor = .secondary
            }
            
            return (bars, trend, trendColor)
        }
    }
    
    
    private func heightForAmount(_ amount: Decimal) -> CGFloat {
        let maxAmount = dailyServiceCosts
            .filter { $0.serviceName == serviceName }
            .map { NSDecimalNumber(decimal: $0.amount).doubleValue }
            .max() ?? 1.0
        
        let normalizedHeight = (NSDecimalNumber(decimal: amount).doubleValue / maxAmount) * 18.0
        return CGFloat(normalizedHeight)
    }
}

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
            
            // Debug option to reset onboarding
            if awsManager.debugMode {
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
            }
            
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
class WindowCloseDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

// Store export window reference globally
var globalExportWindow: NSWindow?
var globalExportDelegate: WindowCloseDelegate?

// Helper function to show export window
func showExportWindow(awsManager: AWSManager) {
    // Check if export window is already open
    if let window = globalExportWindow {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
    }
    
    // Create new export window
    let exportView = ExportView(awsManager: awsManager)
        .environmentObject(awsManager)
    
    let hostingController = NSHostingController(rootView: exportView)
    let window = NSWindow(contentViewController: hostingController)
    window.title = "Export Cost Data"
    window.styleMask = [.titled, .closable, .miniaturizable]
    window.setContentSize(NSSize(width: 500, height: 600))
    window.center()
    
    globalExportWindow = window
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    
    // Clear reference when window closes
    globalExportDelegate = WindowCloseDelegate {
        globalExportWindow = nil
        globalExportDelegate = nil
    }
    window.delegate = globalExportDelegate
}

// Store settings window reference globally
var globalSettingsWindow: NSWindow?

// Helper function to show settings window
func showSettingsWindowForApp(awsManager: AWSManager) {
    if let window = globalSettingsWindow {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
    }
    
    let settingsView = SettingsView()
        .environmentObject(awsManager)
    
    let controller = NSHostingController(rootView: settingsView)
    
    let window = NSWindow(
        contentViewController: controller
    )
    window.title = "AWS Cost Monitor Settings"
    window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
    window.setContentSize(NSSize(width: 600, height: 450))
    window.center()
    
    globalSettingsWindow = window
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}

// MARK: - App Delegate for NSStatusItem Management

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the status bar controller
        statusBarController = StatusBarController(awsManager: AWSManager.shared)
        
        // Hide the dock icon
        NSApp.setActivationPolicy(.accessory)
    }
}

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
            if awsManager.costTrend != .stable {
                switch awsManager.costTrend {
                case .up:
                    return "arrow.up.circle.fill"
                case .down:
                    return "arrow.down.circle.fill"
                case .stable:
                    return "dollarsign.circle.fill"
                }
            } else {
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
        // Show AWS config access window if needed
        WindowGroup("AWS Configuration Access") {
            if configAccessManager.needsAccessGrant {
                AWSConfigAccessView()
                    .frame(width: 450, height: 400)
            }
        }
        .windowResizability(.contentSize)
        
        // Use Settings scene for the app
        Settings {
            SettingsView()
                .environmentObject(awsManager)
        }
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
