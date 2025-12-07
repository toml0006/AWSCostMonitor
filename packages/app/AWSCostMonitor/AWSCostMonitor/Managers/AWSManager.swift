//
//  AWSManager.swift
//  AWSCostMonitor
//
//  AWS SDK and cost management logic
//

import Foundation
import SwiftUI
import OSLog
import ObjectiveC
import AWSCostExplorer
import AWSSTS
import AWSSDKIdentity
import AWSClientRuntime

// MARK: - AWS Manager
// This class handles all the AWS SDK logic.
class AWSManager: ObservableObject {
    static let shared = AWSManager()
    
    @Published var profiles: [AWSProfile] = []
    @Published var realProfiles: [AWSProfile] = []
    @Published var demoProfiles: [AWSProfile] = []
    @Published var isDemoMode: Bool = false
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
            // Automatically recreate timers when interval changes if any timer was active
            let wasRunning = isAutoRefreshActive
            if wasRunning {
                // Preserve autoRefreshEnabled state across restart
                let shouldBeEnabled = autoRefreshEnabled
                stopAutomaticRefresh()
                if shouldBeEnabled {
                    startAutomaticRefresh()
                }
            }
        }
    }
    private var refreshTimer: DispatchSourceTimer?
    private var timerValidationTimer: DispatchSourceTimer? // Periodic timer to validate main refresh timer
    private let timerQueue = DispatchQueue(label: "com.awscostmonitor.refresh", qos: .utility)
    
    // Modern async timer task for more reliability
    private var refreshTask: Task<Void, Never>?
    private var timerValidationTask: Task<Void, Never>?
    
    // Computed property to check if auto-refresh is active
    var isAutoRefreshActive: Bool {
        // Consider Dispatch timer presence OR an async Task that hasn't been cancelled
        let asyncActive = (refreshTask != nil) && (!(refreshTask?.isCancelled ?? true))
        return (refreshTimer != nil) || asyncActive
    }
    
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
    
    // Team cache system
    @Published var profileTeamCacheSettings: [String: ProfileTeamCacheSettings] = [:]
    @Published var teamCacheServices: [String: S3CacheService] = [:]
    private let teamCacheSettingsKey = "ProfileTeamCacheSettings"
    private var backgroundSyncTimer: DispatchSourceTimer?
    @Published var teamCacheController: TeamCacheController?
    
    // Circuit breaker for API protection
    @Published var circuitBreakerTripped = false
    @Published var consecutiveAPIFailures = 0
    private let maxConsecutiveFailures = 3
    
    // Logging and debugging
    @Published var logEntries: [LogEntry] = []
    @Published var apiRequestRecords: [APIRequestRecord] = []
    @AppStorage("DebugMode") var debugMode: Bool = false
    @AppStorage("MaxLogEntries") private var maxLogEntries: Int = 1000
    // Default to true so new installs auto-refresh without manual toggling.
    @AppStorage("AutoRefreshEnabled") var autoRefreshEnabled: Bool = true
    
    // Cost alerts
    let alertManager = CostAlertManager()
    
    // Debug timer properties (only in DEBUG builds)
    #if DEBUG
    @Published var debugTimerMessage: String = "Debug timer not started"
    @Published var debugTimerCount: Int = 0
    @Published var debugTimer: DispatchSourceTimer?
    @Published var debugLastUpdate: Date?
    #endif
    
    // Keys for UserDefaults (legacy - will be replaced with @AppStorage)
    private let selectedProfileKey = "SelectedAWSProfileName"
    private let displayFormatKey = "MenuBarDisplayFormat"
    private let historicalDataKey = "HistoricalCostData"
    private let apiRequestRecordsKey = "APIRequestRecords"
    
    // UserDefaults - use app-specific suite where data is actually stored
    private let userDefaults = UserDefaults(suiteName: "middleout.AWSCostMonitor") ?? UserDefaults.standard
    
    // Profile Management
    private let profileManager = ProfileManager()
    
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
        // Disable AWS SDK telemetry collection for privacy
        setenv("AWS_SDK_TELEMETRY_ENABLED", "false", 1)
        setenv("AWS_SDK_METRICS_ENABLED", "false", 1)
        setenv("AWS_SDK_TRACING_ENABLED", "false", 1)
        setenv("AWS_TELEMETRY_ENABLED", "false", 1)
        
        log(.info, category: "Config", "AWSManager initialized - telemetry disabled")
        print("DEBUG: AWSManager init() called at \(Date())")
        
        // Initialize team cache controller
        self.teamCacheController = TeamCacheController(awsManager: self)
        
        // Initialize team cache services for all profiles
        initializeTeamCacheServices()
        
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
        print("[DEBUG] AWS Config Access Manager Status:")
        print("[DEBUG] - hasAccess: \(accessManager.hasAccess)")
        print("[DEBUG] - needsAccessGrant: \(accessManager.needsAccessGrant)")
        print("[DEBUG] - isSandboxed: \(ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil)")
        
        if accessManager.needsAccessGrant {
            log(.info, category: "Config", "AWS config access needed, will prompt user")
            print("[DEBUG] AWS config access needed - this is why profiles are not loading!")
            print("[DEBUG] Attempting to request AWS config access...")
            
            // Create a persistent window that won't disappear
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("[DEBUG] Creating persistent AWS config access window...")
                self.createPersistentAWSConfigWindow()
            }
        } else {
            print("[DEBUG] AWS config access is available")
        }
        
        // Listen for AWS config access granted notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(awsConfigAccessGranted),
            name: .awsConfigAccessGranted,
            object: nil
        )
        
        // Also listen for when profiles are loaded after config access is granted
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(profilesLoadedAfterConfigAccess),
            name: .profilesLoadedAfterConfigAccess,
            object: nil
        )
        
        // Listen for demo mode selection
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enableDemoMode),
            name: .awsConfigDemoMode,
            object: nil
        )
        
        // Load profiles on initialization
        loadProfiles()
        // Note: loadSelectedProfile() is now called after profiles are loaded in loadProfiles()
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
        // Load team cache settings
        loadTeamCacheSettings()
        
        // Initialize screen state monitoring
        _ = ScreenStateMonitor.shared // Initialize the singleton
        setupScreenStateMonitoring()
        
        // Note: Startup refresh logic moved to after profiles are loaded in loadProfiles()
        
        // Also schedule a secondary check after a delay to catch any edge cases
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            // Final failsafe: if still no profile selected, select the first one
            if self.selectedProfile == nil && !self.profiles.isEmpty {
                print("[DEBUG] FAILSAFE: No profile selected after 2 seconds, selecting first profile")
                self.selectedProfile = self.profiles.first
                if let firstProfile = self.profiles.first {
                    self.log(.warning, category: "Startup", "FAILSAFE: Auto-selected first profile: \(firstProfile.name)")
                    self.saveSelectedProfile(profile: firstProfile)
                    
                    // Trigger immediate refresh
                    Task {
                        await self.fetchCostForSelectedProfile()
                    }
                }
            }
            
            // REMOVED: checkForStartupRefresh() - conflicts with performStartupRefreshCheck()
            // The performStartupRefreshCheck() method is called after profiles are loaded
            
            // Start auto-refresh after profiles are loaded and startup is complete
            if self.autoRefreshEnabled {
                self.log(.info, category: "Startup", "Starting automatic refresh after startup complete")
                self.startAutomaticRefresh()
            }
        }
        
        #if DEBUG
        // Start debug timer automatically to monitor timer execution
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.startDebugTimer()
        }
        #endif
    }
    
    deinit {
        // Clean up observers
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        
        // Stop any running timers (both legacy and modern)
        stopAutomaticRefresh()
        stopBackgroundSyncTimer()
        stopAsyncRefreshTimer()
        
        #if DEBUG
        stopDebugTimer()
        #endif
        
        log(.info, category: "Cleanup", "AWSManager deinitialized - all timers and observers cleaned up")
    }
    
    // Setup screen state monitoring for automatic refresh control
    private func setupScreenStateMonitoring() {
        // Subscribe to screen state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenStateChange),
            name: Notification.Name("ScreenStateChanged"),
            object: nil
        )
        
        // Subscribe to system wake notification to handle refresh after sleep
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSystemWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        
        log(.info, category: "Config", "Screen state monitoring initialized")
    }
    
    @objc private func handleScreenStateChange() {
        let screenMonitor = ScreenStateMonitor.shared
        if screenMonitor.canRefresh {
            // Screen is on and unlocked - resume refresh if needed
            let timersActive = isAutoRefreshActive
            if autoRefreshEnabled && !timersActive {
                log(.info, category: "Refresh", "Resuming automatic refresh - timers were inactive and screen is on/unlocked")
                startAutomaticRefresh()
            }

            // Catch-up: if auto-refresh is enabled and data appears stale, trigger an immediate refresh
            if autoRefreshEnabled {
                // Use existing staleness logic
                if checkIfRefreshNeeded() {
                    log(.info, category: "Refresh", "Catch-up refresh after becoming active/unlocked")
                    Task { @MainActor in
                        await self.fetchCostForSelectedProfile()
                    }
                }
            }
        } else {
            // Screen is off or locked - don't stop the timer, just skip refreshes
            // The timer will continue running but fetchCostForSelectedProfile will be skipped
            log(.info, category: "Refresh", "Screen is off or locked - refreshes will be skipped but timer continues")
        }
    }
    
    // Handle system wake notification
    @objc private func handleSystemWake() {
        log(.info, category: "Refresh", "System woke from sleep")
        
        // If auto-refresh is enabled, check if we need to refresh
        if autoRefreshEnabled {
            // Give the system a moment to fully wake up
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                guard let self = self else { return }
                
                // Check if both timer types are still valid
                let hasDispatchTimer = self.refreshTimer != nil
                let hasAsyncTimer = self.refreshTask != nil && !self.refreshTask!.isCancelled
                
                self.log(.info, category: "Refresh", "After system wake - DispatchTimer: \(hasDispatchTimer), AsyncTimer: \(hasAsyncTimer)")
                
                if hasDispatchTimer || hasAsyncTimer {
                    // At least one timer is still running, trigger an immediate refresh
                    self.log(.info, category: "Refresh", "At least one timer is still valid after system wake")
                    Task {
                        await self.fetchCostForSelectedProfile()
                    }
                } else {
                    // Both timers are invalid, restart them
                    self.log(.warning, category: "Refresh", "Both timers invalid after system wake - restarting automatic refresh")
                    self.startAutomaticRefresh()
                }
                
                // Also force validation of next refresh time
                if let nextTime = self.nextRefreshTime {
                    let timeUntilNext = nextTime.timeIntervalSinceNow
                    if timeUntilNext < -300 { // More than 5 minutes overdue
                        self.log(.warning, category: "Refresh", "Next refresh time is very stale (\(Int(-timeUntilNext)) seconds overdue) - restarting timers")
                        self.startAutomaticRefresh()
                    }
                }
            }
        }
    }
    
    // Handle AWS config access granted notification
    @objc func awsConfigAccessGranted() {
        log(.info, category: "Config", "AWS config access granted, transitioning from demo mode")
        
        // Clear demo mode flag
        isDemoMode = false
        
        // Clear any previous error
        errorMessage = nil
        
        // Clear all demo data and caches
        costData = []
        serviceCosts = []
        dailyCostsByProfile.removeAll()
        dailyServiceCostsByProfile.removeAll()
        costCache.removeAll()
        cacheStatus.removeAll()
        lastMonthData.removeAll()
        
        // Clear the selected profile if it was a demo profile
        if let currentProfile = selectedProfile,
           demoProfiles.contains(where: { $0.name == currentProfile.name }) {
            selectedProfile = nil
            userDefaults.removeObject(forKey: "SelectedAWSProfileName")
        }
        
        // Reload profiles from AWS config
        loadProfiles()
        
        // If we now have real profiles but no selection, select the first one
        if selectedProfile == nil && !realProfiles.isEmpty {
            selectedProfile = realProfiles.first
            if let profile = selectedProfile {
                log(.info, category: "Config", "Auto-selected first real profile: \(profile.name)")
                saveSelectedProfile(profile: profile)
            }
        }
        
        // Fetch cost data for the selected profile
        if selectedProfile != nil {
            Task {
                await fetchCostForSelectedProfile()
            }
        }
        
        // Post notification that profiles are loaded after config access
        NotificationCenter.default.post(name: .profilesLoadedAfterConfigAccess, object: nil)
    }
    
    // Handle profiles loaded after config access is granted
    @objc func profilesLoadedAfterConfigAccess() {
        log(.info, category: "Config", "Profiles loaded after config access granted - performing delayed startup refresh")
        print("[DEBUG] PROFILES LOADED AFTER CONFIG ACCESS - Performing delayed startup refresh")
        
        // Add a small delay to ensure AWS config access is fully processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.log(.info, category: "Config", "Delayed startup refresh check starting...")
            print("[DEBUG] DELAYED STARTUP REFRESH CHECK STARTING...")
            self.performStartupRefreshCheck()
        }
    }
    
    @objc func enableDemoMode() {
        log(.info, category: "Config", "User selected demo mode - loading demo profiles only")
        
        // Set demo mode flag
        isDemoMode = true
        
        // Clear any previous error
        errorMessage = nil
        
        // Clear any existing real profile data
        costData = []
        serviceCosts = []
        dailyCostsByProfile.removeAll()
        dailyServiceCostsByProfile.removeAll()
        costCache.removeAll()
        cacheStatus.removeAll()
        lastMonthData.removeAll()
        
        // Set profiles to only demo profiles
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.profiles = self.demoProfiles
            self.realProfiles = []
        }
        
        // Select the demo profile if no profile is selected
        if selectedProfile == nil && !demoProfiles.isEmpty {
            selectedProfile = demoProfiles.first
            if let profile = selectedProfile {
                log(.info, category: "Demo", "Auto-selected demo profile: \(profile.name)")
                // Save the selection
                saveSelectedProfile(profile: profile)
                // Fetch demo data
                Task {
                    await fetchCostForSelectedProfile()
                }
            }
        }
    }
    
    // Function to find the AWS config file and parse profiles.
    func loadProfiles() {
        log(.debug, category: "Config", "Loading AWS profiles")
        
        // Add demo profiles for App Store review
        #if !OPENSOURCE
        self.demoProfiles = DemoDataProvider.demoProfiles
        #endif
        
        // Use AWSConfigAccessManager for sandboxed file access
        let accessManager = AWSConfigAccessManager.shared
        
        // Check if we have access
        if !accessManager.hasAccess {
            let error = "AWS config access not granted. Please grant access to your .aws folder."
            errorMessage = error
            log(.error, category: "Config", error)
            
            // If no AWS access, enable demo mode for App Store review
            #if !OPENSOURCE
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isDemoMode = true
                self.profiles = self.demoProfiles
                // Auto-select first demo profile or restore saved selection
                self.loadSelectedProfile()
                if self.selectedProfile == nil && !self.demoProfiles.isEmpty {
                    self.selectedProfile = self.demoProfiles[0]
                }
                // Load demo data if we have a profile
                if self.selectedProfile != nil {
                    Task {
                        await self.loadDemoData()
                    }
                }
            }
            #endif
            return
        }
        
        // Read config file using the access manager
        guard let configContent = accessManager.readConfigFile() else {
            let error = "Failed to read AWS config file. Please ensure ~/.aws/config exists."
            errorMessage = error
            log(.error, category: "Config", error)
            
            // If config read fails, enable demo mode for App Store review
            #if !OPENSOURCE
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isDemoMode = true
                self.profiles = self.demoProfiles
                // Auto-select first demo profile or restore saved selection
                self.loadSelectedProfile()
                if self.selectedProfile == nil && !self.demoProfiles.isEmpty {
                    self.selectedProfile = self.demoProfiles[0]
                }
                // Load demo data if we have a profile
                if self.selectedProfile != nil {
                    Task {
                        await self.loadDemoData()
                    }
                }
            }
            #endif
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
        let allProfiles = self.realProfiles + self.demoProfiles
        
        // Check for profile changes and handle them
        checkForProfileChanges(currentProfiles: allProfiles)
        
        log(.info, category: "Config", "Loaded \(allProfiles.count) AWS profiles (including demo)")
        
        if allProfiles.isEmpty {
            let error = "No AWS profiles found in config file."
            errorMessage = error
            log(.warning, category: "Config", error)
        }
    }
    
    // CRITICAL FIX: Perform startup refresh check after profiles are loaded
    private func performStartupRefreshCheck() {
        log(.info, category: "Startup", "=== STARTUP REFRESH CHECK BEGIN ===")
        log(.info, category: "Startup", "Selected profile: \(selectedProfile?.name ?? "nil")")
        log(.info, category: "Startup", "Auto refresh enabled: \(autoRefreshEnabled)")
        log(.info, category: "Startup", "Cost cache keys: \(Array(costCache.keys))")
        log(.info, category: "Startup", "Profile count: \(profiles.count)")
        
        // Check team cache settings
        let teamCacheSettings = loadTeamCacheSettings()
        log(.info, category: "Startup", "Team cache settings: \(teamCacheSettings)")
        
        // DEBUG: AGGRESSIVE REFRESH - Always refresh if data is older than 30 minutes
        if let profile = selectedProfile {
            log(.info, category: "Startup", "Profile found: \(profile.name), region: \(profile.region ?? "nil")")
            
            if let cachedData = costCache[profile.name] {
                let cacheAge = Date().timeIntervalSince(cachedData.fetchDate)
                let budget = getBudget(for: profile.name)
                let refreshIntervalSeconds = TimeInterval(budget.refreshIntervalMinutes * 60)
                
                // DEBUG: Force refresh if older than 30 minutes
                let debugRefreshThreshold: TimeInterval = 30 * 60 // 30 minutes
                
                log(.warning, category: "Startup", "DEBUG MODE - Cache age: \(Int(cacheAge/60)) min, Debug threshold: 30 min, Normal interval: \(budget.refreshIntervalMinutes) min")
                log(.info, category: "Startup", "Cache fetch date: \(cachedData.fetchDate)")
                log(.info, category: "Startup", "Cache MTD total: \(cachedData.mtdTotal)")
                
                if cacheAge > debugRefreshThreshold {
                    log(.warning, category: "Startup", "DEBUG: Cache is older than 30 min (\(Int(cacheAge/60)) min old) - FORCING IMMEDIATE REFRESH")
                    print("DEBUG: FORCING STARTUP REFRESH - Cache is \(Int(cacheAge/60)) minutes old")
                    Task { @MainActor in
                        log(.warning, category: "Startup", "STARTING STARTUP REFRESH TASK")
                        await fetchCostForSelectedProfile(force: true, bypassTeamCache: true)
                        log(.warning, category: "Startup", "STARTUP REFRESH TASK COMPLETED")
                    }
                } else if cacheAge > refreshIntervalSeconds {
                    log(.warning, category: "Startup", "Cache is stale per normal interval (\(Int(cacheAge/60)) min old vs \(budget.refreshIntervalMinutes) min interval) - triggering refresh")
                    Task { @MainActor in
                        await fetchCostForSelectedProfile(force: true, bypassTeamCache: true)
                    }
                } else {
                    log(.info, category: "Startup", "Cache is fresh (\(Int(cacheAge/60)) min old) - no refresh needed")
                }
            } else {
                // No cache for selected profile, fetch immediately
                log(.warning, category: "Startup", "No cache for selected profile '\(profile.name)' - fetching data immediately")
                print("DEBUG: NO CACHE - FORCING STARTUP REFRESH")
                Task { @MainActor in
                    log(.warning, category: "Startup", "STARTING NO-CACHE STARTUP REFRESH TASK")
                    await fetchCostForSelectedProfile(force: true, bypassTeamCache: true)
                    log(.warning, category: "Startup", "NO-CACHE STARTUP REFRESH TASK COMPLETED")
                }
            }
        } else {
            log(.error, category: "Startup", "No selected profile at all - cannot refresh")
            print("DEBUG: NO SELECTED PROFILE - Cannot refresh")
        }
        
        log(.info, category: "Startup", "=== STARTUP REFRESH CHECK END ===")
    }
    
    // Check for profile changes and handle new/removed profiles
    private func checkForProfileChanges(currentProfiles: [AWSProfile]) {
        log(.warning, category: "Startup", "=== CHECK FOR PROFILE CHANGES CALLED ===")
        log(.warning, category: "Startup", "Current profiles count: \(currentProfiles.count)")
        log(.warning, category: "Startup", "Current profiles: \(currentProfiles.map { $0.name })")
        // Check if we should scan for changes
        let shouldScan = profileManager.shouldScanForChanges()
        log(.info, category: "ProfileManagement", "Should scan for changes: \(shouldScan)")
        
        if !shouldScan {
            // No need to scan - just apply existing visibility settings
            log(.info, category: "ProfileManagement", "Not scanning - applying existing visibility settings")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.profiles = self.profileManager.getVisibleProfiles(from: currentProfiles)
            }
            return
        }
        
        // Check if this is first launch (no settings exist)
        let settings = profileManager.loadSettings()
        log(.info, category: "ProfileManagement", "Current settings - visible: \(settings.visibleProfiles.count), hidden: \(settings.hiddenProfiles.count), removed: \(settings.removedProfiles.count), initialized: \(settings.hasCompletedInitialSetup)")
        
        if !settings.hasCompletedInitialSetup {
            // First launch or incomplete setup - initialize profiles without showing alerts
            log(.info, category: "ProfileManagement", "First launch or incomplete setup detected, initializing profiles without alerts")
            profileManager.initializeProfiles(currentProfiles)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.profiles = self.profileManager.getVisibleProfiles(from: currentProfiles)
            }
            return
        }
        
        // Detect changes for existing installation
        log(.info, category: "ProfileManagement", "Detecting changes for existing installation")
        let changes = profileManager.detectProfileChanges(currentProfiles: currentProfiles)
        
        log(.info, category: "ProfileManagement", "Changes detected - new: \(changes.newProfiles.count), removed: \(changes.removedProfiles.count)")
        
        // Set profiles to filtered visible profiles
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let visibleProfiles = self.profileManager.getVisibleProfiles(from: currentProfiles)
            self.profiles = visibleProfiles
            
            print("[DEBUG] Profiles loaded: \(visibleProfiles.map { $0.name })")
            print("[DEBUG] Current selectedProfile: \(self.selectedProfile?.name ?? "nil")")
            
            // After profiles are loaded, restore the selected profile
            self.loadSelectedProfile()
            
            print("[DEBUG] After loadSelectedProfile: \(self.selectedProfile?.name ?? "nil")")
            
            // If still no profile selected and we have profiles, select the first one
            if self.selectedProfile == nil && !self.profiles.isEmpty {
                print("[DEBUG] No profile selected, auto-selecting first from \(self.profiles.count) profiles")
                self.selectedProfile = self.profiles.first
                if let firstProfile = self.profiles.first {
                    print("[DEBUG] Auto-selected profile: \(firstProfile.name)")
                    self.log(.info, category: "Startup", "No saved profile found, auto-selected first profile: \(firstProfile.name)")
                    self.saveSelectedProfile(profile: firstProfile)
                    
                    // Load budget and start refresh for the selected profile
                    let budget = self.getBudget(for: firstProfile.name)
                    self.refreshInterval = budget.refreshIntervalMinutes
                    
                    // Start automatic refresh if enabled and not already running
                    if self.autoRefreshEnabled && !self.isAutoRefreshActive {
                         self.log(.info, category: "Startup", "Starting automatic refresh for auto-selected profile: \(firstProfile.name)")
                         self.startAutomaticRefresh()
                     }
                    
                    // Trigger immediate refresh to load data
                    Task {
                        await self.fetchCostForSelectedProfile()
                    }
                }
            } else if self.selectedProfile != nil {
                print("[DEBUG] Profile already selected: \(self.selectedProfile!.name)")
            }
        }
        
        // CRITICAL FIX: Perform startup refresh check AFTER profile selection is complete
        // This ensures selectedProfile is set before checking for startup refresh
        log(.warning, category: "Startup", "=== STARTUP SEQUENCE DEBUG ===")
        log(.warning, category: "Startup", "Profile selection complete - selectedProfile: \(selectedProfile?.name ?? "nil")")
        log(.warning, category: "Startup", "Total profiles loaded: \(profiles.count)")
        log(.warning, category: "Startup", "Profiles: \(profiles.map { $0.name })")
        
        if self.selectedProfile != nil {
            log(.warning, category: "Startup", "Profile selected successfully - calling performStartupRefreshCheck()")
            performStartupRefreshCheck()
            
            // Also post notification for delayed startup refresh
            NotificationCenter.default.post(name: .profilesLoadedAfterConfigAccess, object: nil)
        } else {
            log(.warning, category: "Startup", "No profile selected after profile loading - skipping startup refresh check")
            print("DEBUG: NO PROFILE SELECTED - Cannot perform startup refresh check")
        }
        
        // Handle new profiles (only show alerts after first launch)
        if !changes.newProfiles.isEmpty {
            log(.info, category: "ProfileManagement", "Showing alert for \(changes.newProfiles.count) new profiles: \(changes.newProfiles.map { $0.name })")
            
            DispatchQueue.main.async {
                ProfileChangeWindowController.showNewProfilesAlert(
                    newProfiles: changes.newProfiles,
                    onAdd: { [weak self] selectedProfileNames in
                        self?.profileManager.addNewProfiles(selectedProfileNames)
                        // Refresh the visible profiles list
                        self?.profiles = self?.profileManager.getVisibleProfiles(from: currentProfiles) ?? currentProfiles
                        self?.log(.info, category: "ProfileManagement", "Added \(selectedProfileNames.count) new profiles")
                    },
                    onDismiss: {
                        // User skipped adding new profiles - they remain hidden
                    }
                )
            }
        }
        
        // Handle removed profiles
        if !changes.removedProfiles.isEmpty {
            log(.info, category: "ProfileManagement", "Showing alert for \(changes.removedProfiles.count) removed profiles: \(changes.removedProfiles)")
            
            DispatchQueue.main.async {
                ProfileChangeWindowController.showRemovedProfilesAlert(
                    removedProfiles: changes.removedProfiles,
                    onRemove: { [weak self] profilesToRemove in
                        self?.profileManager.markProfilesAsRemoved(profilesToRemove, preserveData: false)
                        // Refresh the visible profiles list
                        self?.profiles = self?.profileManager.getVisibleProfiles(from: currentProfiles) ?? currentProfiles
                        self?.log(.info, category: "ProfileManagement", "Removed \(profilesToRemove.count) profiles")
                    },
                    onKeep: { [weak self] profilesToKeep in
                        self?.profileManager.markProfilesAsRemoved(profilesToKeep, preserveData: true)
                        // Refresh the visible profiles list 
                        self?.profiles = self?.profileManager.getVisibleProfiles(from: currentProfiles) ?? currentProfiles
                        self?.log(.info, category: "ProfileManagement", "Kept \(profilesToKeep.count) profiles as view-only")
                    },
                    onDismiss: {
                        // User cancelled - no changes made
                    }
                )
            }
        }
    }
    
    // Loads the selected profile name from UserDefaults.
    func loadSelectedProfile() {
        print("[DEBUG] === LOAD SELECTED PROFILE DEBUG ===")
        print("[DEBUG] Available profiles count: \(profiles.count)")
        print("[DEBUG] Available profiles: \(profiles.map { $0.name })")
        
        if let storedProfileName = userDefaults.string(forKey: selectedProfileKey) {
            print("[DEBUG] Stored profile name: \(storedProfileName)")
            
            // Find the profile object corresponding to the stored name
            self.selectedProfile = self.profiles.first { $0.name == storedProfileName }
            
            if self.selectedProfile != nil {
                print("[DEBUG] Restored saved profile: \(storedProfileName)")
                log(.info, category: "Startup", "Restored saved profile: \(storedProfileName)")
                
                // Load profile-specific refresh settings
                let budget = getBudget(for: storedProfileName)
                self.refreshInterval = budget.refreshIntervalMinutes
                
                // Start automatic refresh if enabled but timers are not active
                if autoRefreshEnabled && !isAutoRefreshActive {
                    log(.info, category: "Startup", "Starting automatic refresh for loaded profile: \(storedProfileName)")
                    startAutomaticRefresh()
                }
            } else {
                print("[DEBUG] Saved profile '\(storedProfileName)' not found in current profiles")
                print("[DEBUG] Available profiles: \(profiles.map { $0.name })")
                log(.warning, category: "Startup", "Saved profile '\(storedProfileName)' not found in current profiles")
                log(.warning, category: "Startup", "Available profiles: \(profiles.map { $0.name })")
            }
        } else {
            print("[DEBUG] No saved profile preference found")
            log(.info, category: "Startup", "No saved profile preference found")
        }
        print("[DEBUG] Final selectedProfile after loadSelectedProfile: \(selectedProfile?.name ?? "nil")")
        // Note: Fallback to first profile is handled in loadProfiles() after this function is called
    }
    
    // Saves the selected profile name to UserDefaults.
    func saveSelectedProfile(profile: AWSProfile) {
        userDefaults.set(profile.name, forKey: selectedProfileKey)
        
        // Clear ALL previous data when switching profiles
        self.costData = []
        self.serviceCosts = []
        self.errorMessage = nil
        self.isRateLimited = false
        self.isLoading = false
        
        // Load profile-specific refresh settings
        let budget = getBudget(for: profile.name)
        self.refreshInterval = budget.refreshIntervalMinutes
        
        // Restart refresh timers if they are active, or start them if auto-refresh is enabled
        let timersActive = isAutoRefreshActive
        if timersActive {
            stopAutomaticRefresh()
            startAutomaticRefresh()
        } else if autoRefreshEnabled {
            startAutomaticRefresh()
        }
        
        // Check if we have cached data for this profile
        if let cachedData = costCache[profile.name] {
            // Load cached data immediately
            let costDataItem = CostData(
                profileName: cachedData.profileName,
                amount: cachedData.mtdTotal,
                currency: cachedData.currency
            )
            self.costData = [costDataItem]
            self.serviceCosts = cachedData.serviceCosts
            
            // Check if cache is stale
            let cacheAge = Date().timeIntervalSince(cachedData.fetchDate)
            let refreshIntervalSeconds = TimeInterval(budget.refreshIntervalMinutes * 60)
            
            if cacheAge > refreshIntervalSeconds {
                // Cache is stale, fetch new data
                Task {
                    await fetchCostForSelectedProfile()
                }
            }
        } else {
            // No cache, fetch data immediately
            Task {
                await fetchCostForSelectedProfile()
            }
        }
    }
    
    // Public access to ProfileManager for settings integration
    func getProfileManager() -> ProfileManager {
        return profileManager
    }
    
    // Update profile visibility and refresh the profiles list
    func updateProfileVisibility() {
        let allProfiles = self.realProfiles + self.demoProfiles
        let visibleProfiles = profileManager.getVisibleProfiles(from: allProfiles)
        
        // Ensure UI updates happen on main thread
        DispatchQueue.main.async { [weak self] in
            self?.profiles = visibleProfiles
            
            // If the current profile is no longer visible, switch to first available
            if let currentProfile = self?.selectedProfile,
               !visibleProfiles.contains(where: { $0.name == currentProfile.name }) {
                if let firstProfile = visibleProfiles.first {
                    self?.selectedProfile = firstProfile
                    self?.saveSelectedProfile(profile: firstProfile)
                    
                    // Fetch data for the newly selected profile
                    Task { [weak self] in
                        await self?.fetchCostForSelectedProfile(force: true)
                    }
                }
            }
        }
    }
    
    // Loads the display format preference from UserDefaults.
    func loadDisplayFormat() {
        if let storedFormat = userDefaults.string(forKey: displayFormatKey),
           let format = MenuBarDisplayFormat(rawValue: storedFormat) {
            self.displayFormat = format
        } else {
            // Default to full format if not set
            self.displayFormat = .full
        }
    }
    
    // Saves the display format preference to UserDefaults.
    func saveDisplayFormat(_ format: MenuBarDisplayFormat) {
        userDefaults.set(format.rawValue, forKey: displayFormatKey)
        self.displayFormat = format
    }
    
    // MARK: - Budget Management
    
    // Load budgets from UserDefaults
    func loadBudgets() {
        if let data = userDefaults.data(forKey: "ProfileBudgets"),
           let budgets = try? JSONDecoder().decode([String: ProfileBudget].self, from: data) {
            self.profileBudgets = budgets
        }
    }
    
    // Save budgets to UserDefaults
    func saveBudgets() {
        if let data = try? JSONEncoder().encode(profileBudgets) {
            userDefaults.set(data, forKey: "ProfileBudgets")
        }
    }
    
    // Get or create budget for a profile
    func getBudget(for profileName: String) -> ProfileBudget {
        if let budget = profileBudgets[profileName] {
            // Migrate old budgets that don't have new fields
            if budget.apiBudget == 0 {
                var updated = budget
                updated.apiBudget = 5.0
                updated.refreshIntervalMinutes = 480  // 8 hours - matches AWS update frequency
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
    func updateBudget(for profileName: String, monthlyBudget: Decimal?, alertThreshold: Double) {
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
            
            // Enable auto-refresh when a valid interval is set
            if refreshIntervalMinutes > 0 {
                // If timer is already running, restart it with new interval
                // Otherwise, start it for the first time
                if isAutoRefreshActive {
                    stopAutomaticRefresh()
                }
                startAutomaticRefresh()
            } else if isAutoRefreshActive {
                // If interval is 0 or negative, stop the timer
                stopAutomaticRefresh()
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
        // If no monthly budget is set, return default status
        guard let monthlyBudget = budget.monthlyBudget else {
            return BudgetStatus(
                percentage: 0.0,
                isOverBudget: false,
                isNearThreshold: false
            )
        }

        let percentage = NSDecimalNumber(decimal: cost).dividing(by: NSDecimalNumber(decimal: monthlyBudget)).doubleValue
        return BudgetStatus(
            percentage: percentage,
            isOverBudget: percentage >= 1.0,
            isNearThreshold: percentage >= budget.alertThreshold
        )
    }
    
    // MARK: - Historical Data Management
    
    // Load historical data from UserDefaults
    func loadHistoricalData() {
        if let data = userDefaults.data(forKey: historicalDataKey),
           let historical = try? JSONDecoder().decode([HistoricalCostData].self, from: data) {
            self.historicalData = historical
        }
    }
    
    // Save historical data to UserDefaults
    func saveHistoricalData() {
        if let data = try? JSONEncoder().encode(historicalData) {
            userDefaults.set(data, forKey: historicalDataKey)
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
        case "Data": logger = Logger.app
        case "Config": logger = Logger.app
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

        // Skip budget velocity check if no monthly budget is set
        guard let monthlyBudget = budget.monthlyBudget else {
            return nil
        }

        let monthProgress = Double(currentDay) / Double(daysInMonth)
        let spendingProgress = NSDecimalNumber(decimal: currentAmount).dividing(by: NSDecimalNumber(decimal: monthlyBudget)).doubleValue

        // If spending progress is significantly ahead of month progress
        if spendingProgress > monthProgress * 1.5 && spendingProgress > 0.5 {
            let daysRemaining = daysInMonth - currentDay
            let remainingBudget = NSDecimalNumber(decimal: monthlyBudget).subtracting(NSDecimalNumber(decimal: currentAmount))
            
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
        #if DEBUG
        log(.debug, category: "RefreshTimer", "startAutomaticRefresh() called")
        #endif
        
        // Cancel existing timers if present
        if refreshTimer != nil {
            refreshTimer?.cancel()
            refreshTimer = nil
        }
        stopAsyncRefreshTimer() // Stop any async tasks
        nextRefreshTime = nil
        
        autoRefreshEnabled = true // Persist the state
        
        // Get the profile-specific refresh interval
        let intervalMinutes: Int
        if let profile = selectedProfile {
            let budget = getBudget(for: profile.name)
            intervalMinutes = budget.refreshIntervalMinutes
        } else {
            intervalMinutes = refreshInterval // Fallback to global interval
        }
        
        // Validate interval before scheduling
        guard intervalMinutes > 0 else {
            log(.warning, category: "Refresh", "Invalid refresh interval (\(intervalMinutes) minutes). Timers will not start.")
            return
        }
        
        log(.info, category: "Refresh", "Starting automatic refresh timer for profile: \(selectedProfile?.name ?? "none"), interval: \(intervalMinutes) minutes")
        
        // Check if we need to refresh immediately due to stale data
        let shouldRefreshImmediately = checkIfRefreshNeeded()
        
        if shouldRefreshImmediately {
            log(.info, category: "Refresh", "Data is stale, refreshing immediately before scheduling next refresh")
            Task {
                await fetchCostForSelectedProfile()
                await MainActor.run {
                    // Start both timer implementations for redundancy
                    self.scheduleNextRefresh() // Legacy DispatchSource timer
                    self.startAsyncRefreshTimer() // Modern async timer
                }
            }
        } else {
            // Start both timer implementations for redundancy
            scheduleNextRefresh() // Legacy DispatchSource timer
            startAsyncRefreshTimer() // Modern async timer
        }
    }
    
    // Helper to check if immediate refresh is needed
    private func checkIfRefreshNeeded() -> Bool {
        // If we don't have a next refresh time, we need to refresh
        guard let scheduledTime = nextRefreshTime else {
            log(.info, category: "Refresh", "No next refresh time scheduled, refresh needed")
            return true
        }
        
        // If the scheduled time has already passed (e.g., due to sleep), refresh immediately
        if Date() >= scheduledTime {
            log(.info, category: "Refresh", "Scheduled refresh time has passed (was: \(scheduledTime), now: \(Date()))")
            return true
        }
        
        // Check if data is too old based on last API call time
        if let lastCall = lastAPICallTime {
            let timeSinceLastCall = Date().timeIntervalSince(lastCall)
            // Use profile-specific interval if available
            let intervalMinutes: Int
            if let profile = selectedProfile {
                let budget = getBudget(for: profile.name)
                intervalMinutes = budget.refreshIntervalMinutes
            } else {
                intervalMinutes = refreshInterval
            }
            let maxAge = TimeInterval(intervalMinutes * 60)
            if timeSinceLastCall > maxAge {
                log(.info, category: "Refresh", "Data is stale (last fetch: \(Int(timeSinceLastCall/60)) minutes ago, max age: \(intervalMinutes) minutes)")
                return true
            }
        } else {
            // CRITICAL FIX: If lastAPICallTime is null, check cache data age directly
            if let profile = selectedProfile,
               let cachedData = costCache[profile.name] {
                let cacheAge = Date().timeIntervalSince(cachedData.fetchDate)
                let intervalMinutes = getBudget(for: profile.name).refreshIntervalMinutes
                let maxAge = TimeInterval(intervalMinutes * 60)
                
                if cacheAge > maxAge {
                    log(.info, category: "Refresh", "Cache data is stale (age: \(Int(cacheAge/60)) minutes, max age: \(intervalMinutes) minutes) - lastAPICallTime was null")
                    return true
                }
            } else if lastAPICallTime == nil {
                // No API call time and no cache data - definitely need refresh
                log(.info, category: "Refresh", "No lastAPICallTime and no cache data - refresh needed")
                return true
            }
        }
        
        return false
    }
    
    // Helper to schedule the next refresh
    private func scheduleNextRefresh() {
        // Use the profile's configured refresh interval, not the smart interval
        guard let profile = selectedProfile else {
            log(.warning, category: "Refresh", "No profile selected, cannot schedule refresh")
            return
        }
        
        let budget = getBudget(for: profile.name)
        let intervalMinutes = budget.refreshIntervalMinutes
        let interval = TimeInterval(intervalMinutes * 60) // Convert minutes to seconds
        
        log(.info, category: "Refresh", "Scheduling next refresh in \(intervalMinutes) minutes for profile: \(profile.name)")
        
        // Calculate and store next refresh time
        nextRefreshTime = Date().addingTimeInterval(interval)
        
        // Create a DispatchSourceTimer for more precise timing
        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        refreshTimer = timer
        
        // Configure the timer to fire at the specified interval
        timer.schedule(deadline: .now() + interval, repeating: interval)
        
        // Set the event handler for when the timer fires
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            self.log(.warning, category: "RefreshTimer", "🔄 Refresh timer FIRED at \(Date())")
            
            #if DEBUG
            self.log(.debug, category: "RefreshTimer", "Refresh timer fired at \(Date())")
            #endif
            
            // Update next refresh time for display on main queue
            DispatchQueue.main.async {
                self.nextRefreshTime = Date().addingTimeInterval(interval)
            }
            
            Task { @MainActor in
                // AGGRESSIVE STALENESS CHECK: Force refresh if cache data is older than 2 hours
                var forceRefreshDueToStaleCache = false
                if let profile = self.selectedProfile,
                   let cachedData = self.costCache[profile.name] {
                    let cacheAge = Date().timeIntervalSince(cachedData.fetchDate)
                    let twoHours: TimeInterval = 2 * 60 * 60 // 2 hours
                    if cacheAge > twoHours {
                        forceRefreshDueToStaleCache = true
                        self.log(.warning, category: "Refresh", "AGGRESSIVE: Cache is \(Int(cacheAge/3600)) hours old, forcing refresh")
                    }
                }
                
                // Check if data is stale and force refresh if needed
                if self.checkIfRefreshNeeded() || forceRefreshDueToStaleCache {
                    let reason = forceRefreshDueToStaleCache ? "AGGRESSIVE cache staleness check" : "Standard staleness check"
                    self.log(.info, category: "Refresh", "Data is stale (\(reason)), forcing refresh regardless of screen state")
                    await self.fetchCostForSelectedProfile(force: true)
                } else if ScreenStateMonitor.shared.shouldAllowRefresh() {
                    self.log(.info, category: "Refresh", "Screen is active, performing refresh")
                    await self.fetchCostForSelectedProfile()
                } else {
                    self.log(.info, category: "Refresh", "Skipped scheduled refresh: screen off or locked")
                }
            }
        }
        
        // Set cancellation handler for cleanup
        timer.setCancelHandler { [weak self] in
            self?.log(.info, category: "Refresh", "Refresh timer cancelled")
        }
        
        // Start the timer
        timer.resume()
        
        // Validate timer was created successfully
        if refreshTimer != nil {
            log(.info, category: "Refresh", "DispatchSourceTimer scheduled successfully. Next refresh at: \(nextRefreshTime!)")
            
            // Start validation timer if not already running
            if timerValidationTimer == nil {
                startTimerValidation()
            }
        } else {
            log(.error, category: "Refresh", "⚠️ Failed to create refresh timer!")
        }
    }
    
    // Start a periodic timer to validate the main refresh timer (failsafe)
    private func startTimerValidation() {
        // Cancel any existing validation timer
        if let existingTimer = timerValidationTimer {
            existingTimer.cancel()
            timerValidationTimer = nil
        }
        
        // Create a DispatchSourceTimer for validation
        let validationTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        timerValidationTimer = validationTimer
        
        // Configure to run every 30 seconds
        validationTimer.schedule(deadline: .now() + 30, repeating: 30.0)
        
        // Set the event handler
        validationTimer.setEventHandler { [weak self] in
            self?.validateRefreshTimer()
        }
        
        // Start the validation timer
        validationTimer.resume()
        
        log(.debug, category: "Refresh", "Started timer validation checker (runs every 30 seconds)")
    }
    
    // Stops automatic refresh
    func stopAutomaticRefresh() {
        // Stop legacy DispatchSource timers
        if refreshTimer != nil {
            refreshTimer?.cancel()
            refreshTimer = nil
        }
        if let validationTimer = timerValidationTimer {
            validationTimer.cancel()
            timerValidationTimer = nil
        }
        
        // Stop modern async timers
        stopAsyncRefreshTimer()
        
        nextRefreshTime = nil
        autoRefreshEnabled = false // Persist the state
        
        log(.info, category: "Refresh", "All refresh timers stopped")
    }
    
    // Validates that the timer is still running (failsafe)
    func validateRefreshTimer() {
        guard autoRefreshEnabled else { return }
        
        if refreshTimer != nil {
            // Timer is valid, check if next refresh time makes sense
            if let nextTime = nextRefreshTime {
                let timeUntilNext = nextTime.timeIntervalSinceNow
                if timeUntilNext < -60 { // More than 1 minute overdue
                    log(.warning, category: "Refresh", "Timer is overdue by \(Int(-timeUntilNext)) seconds, restarting")
                    startAutomaticRefresh()
                }
            }
        } else {
            // Timer is invalid or nil but should be running
            log(.warning, category: "Refresh", "Timer validation failed - restarting automatic refresh")
            startAutomaticRefresh()
        }
    }
    
    // Updates refresh interval and recreates timer if running
    func updateRefreshInterval(_ newInterval: Int) {
        let wasRunning = isAutoRefreshActive
        stopAutomaticRefresh() // Always stop first
        refreshInterval = newInterval
        
        if wasRunning {
            startAutomaticRefresh() // Restart with new interval
        }
    }
    
    // MARK: - Modern Async Timer Implementation (More Robust)
    
    // Start modern async timer using Task for better reliability
    private func startAsyncRefreshTimer() {
        // Cancel existing async tasks
        refreshTask?.cancel()
        timerValidationTask?.cancel()
        
        // Get interval - use profile-specific or fallback to global
        let intervalMinutes: Int
        if let profile = selectedProfile {
            let budget = getBudget(for: profile.name)
            intervalMinutes = budget.refreshIntervalMinutes
        } else {
            intervalMinutes = refreshInterval
            log(.warning, category: "AsyncRefresh", "No profile selected, using global interval: \(intervalMinutes) minutes")
        }
        
        let interval = TimeInterval(intervalMinutes * 60)
        
        log(.info, category: "AsyncRefresh", "Starting modern async refresh timer for profile: \(selectedProfile?.name ?? "none"), interval: \(intervalMinutes) minutes")
        
        // Set next refresh time
        nextRefreshTime = Date().addingTimeInterval(interval)
        
        // Create the main refresh task
        refreshTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled && self.autoRefreshEnabled {
                do {
                    // Sleep for the interval duration
                    try await Task.sleep(for: .seconds(interval))
                    
                    // Check if we're still supposed to be running
                    guard !Task.isCancelled && self.autoRefreshEnabled else { break }
                    
                    await MainActor.run {
                        // Update next refresh time
                        self.nextRefreshTime = Date().addingTimeInterval(interval)
                        self.log(.info, category: "AsyncRefresh", "🔄 Async refresh timer FIRED at \(Date())")
                    }
                    
                    // AGGRESSIVE STALENESS CHECK: Force refresh if cache data is older than 2 hours
                    var forceRefreshDueToStaleCache = false
                    if let profile = self.selectedProfile,
                       let cachedData = self.costCache[profile.name] {
                        let cacheAge = Date().timeIntervalSince(cachedData.fetchDate)
                        let twoHours: TimeInterval = 2 * 60 * 60 // 2 hours
                        if cacheAge > twoHours {
                            forceRefreshDueToStaleCache = true
                            self.log(.warning, category: "AsyncRefresh", "AGGRESSIVE: Cache is \(Int(cacheAge/3600)) hours old, forcing refresh")
                        }
                    }
                    
                    // Check if data is stale and force refresh if needed
                    if self.checkIfRefreshNeeded() || forceRefreshDueToStaleCache {
                        let reason = forceRefreshDueToStaleCache ? "AGGRESSIVE cache staleness check" : "Standard staleness check"
                        self.log(.info, category: "AsyncRefresh", "Data is stale (\(reason)), forcing refresh regardless of screen state")
                        await self.fetchCostForSelectedProfile(force: true)
                    } else if ScreenStateMonitor.shared.shouldAllowRefresh() {
                        self.log(.info, category: "AsyncRefresh", "Screen is active, performing refresh")
                        await self.fetchCostForSelectedProfile()
                    } else {
                        self.log(.info, category: "AsyncRefresh", "Skipped scheduled refresh: screen off or locked")
                    }
                } catch {
                    // Handle cancellation gracefully
                    if error is CancellationError {
                        self.log(.info, category: "AsyncRefresh", "Async refresh timer was cancelled")
                        break
                    } else {
                        self.log(.error, category: "AsyncRefresh", "Async refresh timer error: \(error)")
                        // Wait a bit before retrying to avoid tight loops
                        try? await Task.sleep(for: .seconds(30))
                    }
                }
            }
            // Ensure the task handle is cleared when the task ends so state checks are accurate
            await MainActor.run {
                self.refreshTask = nil
            }
            self.log(.info, category: "AsyncRefresh", "Async refresh timer task ended")
        }
        
        // Create a validation task that checks every 60 seconds
        timerValidationTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled && self.autoRefreshEnabled {
                do {
                    try await Task.sleep(for: .seconds(60))
                    
                    guard !Task.isCancelled && self.autoRefreshEnabled else { break }
                    
                    // Validate timer is still working
                    if let nextTime = await MainActor.run(body: { self.nextRefreshTime }) {
                        let timeUntilNext = nextTime.timeIntervalSinceNow
                        if timeUntilNext < -120 { // More than 2 minutes overdue
                            self.log(.warning, category: "AsyncRefresh", "Async timer is overdue by \(Int(-timeUntilNext)) seconds, restarting")
                            await MainActor.run {
                                self.startAutomaticRefresh()
                            }
                            break
                        }
                    }
                } catch {
                    if error is CancellationError {
                        break
                    }
                    // Continue validation loop even on errors
                }
            }
        }
    }
    
    // Stop all async timer tasks
    private func stopAsyncRefreshTimer() {
        refreshTask?.cancel()
        refreshTask = nil
        timerValidationTask?.cancel()
        timerValidationTask = nil
        log(.info, category: "AsyncRefresh", "Stopped async refresh timer tasks")
    }
    
    // MARK: - Debug Timer Functions (only in DEBUG builds)
    
    #if DEBUG
    @Published var debugTimerFlash: Bool = false
    
    // Start debug timer with 1-minute intervals
    func startDebugTimer() {
        stopDebugTimer() // Stop any existing debug timer
        
        debugTimerCount = 0
        debugLastUpdate = Date()
        debugTimerMessage = "Debug timer started at \(Date().formatted(date: .omitted, time: .standard))"
        
        log(.info, category: "Debug", "Starting debug timer with 1-minute intervals")
        
        // Create a DispatchSourceTimer for debug
        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        debugTimer = timer
        
        // Configure for 1-minute intervals
        timer.schedule(deadline: .now(), repeating: 60.0)
        
        // Set the event handler
        timer.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.handleDebugTimerTick()
            }
        }
        
        // Start the timer
        timer.resume()
        
        // Also fire immediately for testing
        handleDebugTimerTick()
    }
    
    // Handle debug timer tick
    private func handleDebugTimerTick() {
        debugTimerCount += 1
        debugLastUpdate = Date()
        
        let timeString = Date().formatted(date: .omitted, time: .standard)
        debugTimerMessage = "Debug tick #\(debugTimerCount) at \(timeString)"
        
        log(.warning, category: "Debug", "🔥 DEBUG TIMER TICK #\(debugTimerCount) at \(timeString) - FLASHING MENU BAR")
        
        // Flash the menu bar by toggling a flag
        debugTimerFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.debugTimerFlash = false
        }
        
        // Also log the state of the refresh timer
        if refreshTimer != nil {
            log(.info, category: "Debug", "Refresh timer is active")
        } else {
            log(.warning, category: "Debug", "⚠️ Refresh timer is nil - auto-refresh not running!")
        }
        
        if let nextRefresh = nextRefreshTime {
            let timeUntilRefresh = nextRefresh.timeIntervalSince(Date())
            log(.info, category: "Debug", "Next refresh scheduled for: \(nextRefresh), in \(Int(timeUntilRefresh)) seconds")
        } else {
            log(.info, category: "Debug", "No next refresh time scheduled")
        }
    }
    
    // Stop debug timer
    func stopDebugTimer() {
        if let timer = debugTimer {
            timer.cancel()
            debugTimer = nil
        }
        debugTimerMessage = "Debug timer stopped"
        log(.info, category: "Debug", "Debug timer stopped")
    }
    #endif
    
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
            log(.debug, category: "Startup", "No selected profile, skipping startup refresh check")
            return
        }
        
        // Get the budget-specific refresh interval for this profile
        let budget = getBudget(for: profile.name)
        let profileRefreshInterval = budget.refreshIntervalMinutes
        let refreshIntervalSeconds = TimeInterval(profileRefreshInterval * 60)
        
        // First check if we have cached data and if it's stale
        var shouldRefresh = false
        var reason = ""
        
        if let cacheEntry = costCache[profile.name] {
            // We have cached data - check if it's stale based on refresh interval
            let cacheAge = Date().timeIntervalSince(cacheEntry.fetchDate)
            
            if cacheAge > refreshIntervalSeconds {
                shouldRefresh = true
                reason = "Cache is \(Int(cacheAge / 60)) minutes old (older than refresh interval of \(profileRefreshInterval) minutes)"
            } else {
                // Cache is fresh, but let's also check if it's valid for the current budget
                if !cacheEntry.isValidForBudget(budget) {
                    shouldRefresh = true
                    reason = "Cache is invalid for current budget settings"
                } else {
                    log(.info, category: "Startup", "Cache is fresh (\(Int(cacheAge / 60)) minutes old) and valid for budget (interval: \(profileRefreshInterval) min), skipping startup refresh")
                }
            }
        } else {
            // No cache exists, check API call records as fallback
            let profileRecords = apiRequestRecords.filter { $0.profileName == profile.name && $0.success }
            if let lastRecord = profileRecords.sorted(by: { $0.timestamp > $1.timestamp }).first {
                let timeSinceLastRefresh = Date().timeIntervalSince(lastRecord.timestamp)
                
                if timeSinceLastRefresh > refreshIntervalSeconds {
                    shouldRefresh = true
                    reason = "Last API call was \(Int(timeSinceLastRefresh / 60)) minutes ago (older than refresh interval of \(profileRefreshInterval) minutes)"
                } else {
                    log(.info, category: "Startup", "Last API call was \(Int(timeSinceLastRefresh / 60)) minutes ago, within interval of \(profileRefreshInterval) minutes")
                }
            } else {
                // No previous API calls at all
                shouldRefresh = true
                reason = "No previous data found for this profile"
            }
        }
        
        // Perform refresh if needed
        if shouldRefresh {
            log(.info, category: "Startup", "Performing startup refresh for \(profile.name): \(reason)")
            // Directly call the refresh
            Task { @MainActor in
                await fetchCostForSelectedProfile()
            }
        } else {
            log(.info, category: "Startup", "No startup refresh needed for \(profile.name)")
        }
    }
    
    // Enhanced single-call data strategy with intelligent caching
    func fetchCostForSelectedProfile(force: Bool = false, bypassTeamCache: Bool = false) async {
        guard let profile = selectedProfile else {
            let error = "No profile selected."
            log(.warning, category: "API", error)
            await MainActor.run {
                self.errorMessage = error
            }
            return
        }
        
        // Check if we're in demo mode
        #if !OPENSOURCE
        if isDemoMode || profile.name.hasPrefix("demo-") {
            await loadDemoData()
            return
        }
        #endif
        
        // Check screen state before making API call (unless forced)
        if !force && !ScreenStateMonitor.shared.shouldAllowRefresh() {
            log(.info, category: "API", "Skipping refresh: screen is off or system is locked")
            // Use cached data if available
            if let cachedData = costCache[profile.name] {
                log(.info, category: "Cache", "Using cached data while screen is off/locked")
                await loadFromCache(cachedData)
            }
            return
        }
        
        // Check if this is the ACME demo profile
        if profile.name.lowercased() == "acme" {
            await loadDemoDataForACME()
            return
        }
        
        log(.info, category: "API", "=== FETCH COST DATA START ===")
        log(.info, category: "API", "Profile: \(profile.name), Force: \(force), BypassTeamCache: \(bypassTeamCache)")
        
        // Cache-first lookup strategy: team cache → local cache → API (unless forced or bypassing team cache)
        if !force && !bypassTeamCache {
            log(.info, category: "API", "Checking team cache first for profile: \(profile.name)")
            if await checkTeamCacheFirst(for: profile) {
                log(.info, category: "API", "Team cache hit - data loaded from team cache")
                return // Team cache hit, data loaded
            }
            log(.info, category: "API", "Team cache miss - falling back to local cache")
            
            // Fallback to local cache if team cache miss/disabled
            if let cachedData = costCache[profile.name] {
                let budget = getBudget(for: profile.name)
                if cachedData.isValidForBudget(budget) {
                    log(.info, category: "Cache", "Using local cached data for \(profile.name), age: \(Int(Date().timeIntervalSince(cachedData.fetchDate) / 60)) minutes")
                    await loadFromCache(cachedData)
                    return
                } else {
                    log(.info, category: "Cache", "Local cache is stale for \(profile.name), age: \(Int(Date().timeIntervalSince(cachedData.fetchDate) / 60)) minutes")
                }
            } else {
                log(.info, category: "Cache", "No local cache found for \(profile.name)")
            }
        } else {
            if bypassTeamCache {
                log(.warning, category: "API", "BYPASSING TEAM CACHE - Fetching directly from Cost Explorer API")
            }
            if force {
                log(.warning, category: "API", "FORCE REFRESH - Bypassing all caches")
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
                
                await MainActor.run { [cacheEntry, dailyCosts, dailyServiceCosts] in
                    // Store in cache
                    self.costCache[profile.name] = cacheEntry
                    self.dailyCostsByProfile[profile.name] = dailyCosts
                    self.dailyServiceCostsByProfile[profile.name] = dailyServiceCosts
                    self.cacheStatus[profile.name] = Date()
                }
                
                // Update team cache after successful API call
                await updateTeamCacheAfterAPICall()
                
                await MainActor.run { [totalAmount, currency, services, dailyCosts] in
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
            if error is AWSSDKIdentity.AWSCredentialIdentityResolverError {
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
        
        log(.info, category: "API", "=== FETCH COST DATA END ===")
        log(.info, category: "API", "Final cost data count: \(self.costData.count)")
        if let firstCost = self.costData.first {
            log(.info, category: "API", "Final cost amount: \(firstCost.amount)")
        }
        if let error = self.errorMessage {
            log(.error, category: "API", "Final error message: \(error)")
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
        _ = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        _ = calendar.component(.day, from: now)
        
        // Generate impressive but realistic cost data - current month performing better
        let mtdTotal = Decimal(67834.12) // Month-to-date total (14 days worth)
        let lastMonthTotal = Decimal(74257.33) // Last month was higher (current is 8.6% lower - modest GREEN!)
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
            
            // Distribute across services with independent daily variations for realistic patterns
            // Each service gets its own random variation to create realistic looking bar charts
            
            // EC2 - high variation (instances spin up/down)
            let ec2Variation = 0.7 + Double.random(in: 0...0.6) // 70-130% variation
            let ec2Amount = dailyAmount * Decimal(0.42 * ec2Variation)
            
            // RDS - moderate variation (databases are more stable)
            let rdsVariation = 0.85 + Double.random(in: 0...0.3) // 85-115% variation
            let rdsAmount = dailyAmount * Decimal(0.18 * rdsVariation)
            
            // S3 - low variation (storage grows slowly)
            let s3Variation = 0.95 + Double.random(in: 0...0.1) // 95-105% variation
            let s3Amount = dailyAmount * Decimal(0.08 * s3Variation)
            
            // CloudFront - high variation (traffic spikes)
            let cloudFrontVariation = 0.6 + Double.random(in: 0...0.8) // 60-140% variation
            let cloudFrontAmount = dailyAmount * Decimal(0.07 * cloudFrontVariation)
            
            // ELB - moderate variation
            let elbVariation = 0.8 + Double.random(in: 0...0.4) // 80-120% variation
            let elasticLoadBalancingAmount = dailyAmount * Decimal(0.06 * elbVariation)
            
            // Lambda - very high variation (event-driven)
            let lambdaVariation = 0.3 + Double.random(in: 0...1.4) // 30-170% variation
            let lambdaAmount = dailyAmount * Decimal(0.05 * lambdaVariation)
            
            // ECS - moderate variation
            let ecsVariation = 0.75 + Double.random(in: 0...0.5) // 75-125% variation
            let ecsAmount = dailyAmount * Decimal(0.04 * ecsVariation)
            
            // Route53 - very low variation (DNS is stable)
            let route53Variation = 0.98 + Double.random(in: 0...0.04) // 98-102% variation
            let route53Amount = dailyAmount * Decimal(0.03 * route53Variation)
            
            // DynamoDB - moderate to high variation
            let dynamoVariation = 0.7 + Double.random(in: 0...0.6) // 70-130% variation
            let dynamoAmount = dailyAmount * Decimal(0.025 * dynamoVariation)
            
            // Backup - low variation (scheduled jobs)
            let backupVariation = 0.9 + Double.random(in: 0...0.2) // 90-110% variation
            let backupAmount = dailyAmount * Decimal(0.02 * backupVariation)
            
            // API Gateway - high variation (API usage varies)
            let apiGatewayVariation = 0.5 + Double.random(in: 0...1.0) // 50-150% variation
            let apiGatewayAmount = dailyAmount * Decimal(0.015 * apiGatewayVariation)
            
            // KMS - very low variation (encryption is consistent)
            let kmsVariation = 0.97 + Double.random(in: 0...0.06) // 97-103% variation
            let kmsAmount = dailyAmount * Decimal(0.01 * kmsVariation)
            
            dailyServiceCosts.append(contentsOf: [
                DailyServiceCost(date: date, serviceName: "Amazon Elastic Compute Cloud - Compute", amount: ec2Amount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "Amazon Relational Database Service", amount: rdsAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "Amazon Simple Storage Service", amount: s3Amount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "Amazon CloudFront", amount: cloudFrontAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "Elastic Load Balancing", amount: elasticLoadBalancingAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "AWS Lambda", amount: lambdaAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "Amazon Elastic Container Service", amount: ecsAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "Amazon Route 53", amount: route53Amount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "Amazon DynamoDB", amount: dynamoAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "AWS Backup", amount: backupAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "Amazon API Gateway", amount: apiGatewayAmount, currency: "USD"),
                DailyServiceCost(date: date, serviceName: "AWS Key Management Service", amount: kmsAmount, currency: "USD")
            ])
        }
        
        // Create service breakdown - more realistic distribution
        let serviceCosts = [
            ServiceCost(serviceName: "Amazon Elastic Compute Cloud - Compute", amount: mtdTotal * Decimal(0.42), currency: "USD"),
            ServiceCost(serviceName: "Amazon Relational Database Service", amount: mtdTotal * Decimal(0.18), currency: "USD"),
            ServiceCost(serviceName: "Amazon Simple Storage Service", amount: mtdTotal * Decimal(0.08), currency: "USD"),
            ServiceCost(serviceName: "Amazon CloudFront", amount: mtdTotal * Decimal(0.07), currency: "USD"),
            ServiceCost(serviceName: "Elastic Load Balancing", amount: mtdTotal * Decimal(0.06), currency: "USD"),
            ServiceCost(serviceName: "AWS Lambda", amount: mtdTotal * Decimal(0.05), currency: "USD"),
            ServiceCost(serviceName: "Amazon Elastic Container Service", amount: mtdTotal * Decimal(0.04), currency: "USD"),
            ServiceCost(serviceName: "Amazon Route 53", amount: mtdTotal * Decimal(0.03), currency: "USD"),
            ServiceCost(serviceName: "Amazon DynamoDB", amount: mtdTotal * Decimal(0.025), currency: "USD"),
            ServiceCost(serviceName: "AWS Backup", amount: mtdTotal * Decimal(0.02), currency: "USD"),
            ServiceCost(serviceName: "Amazon API Gateway", amount: mtdTotal * Decimal(0.015), currency: "USD"),
            ServiceCost(serviceName: "AWS Key Management Service", amount: mtdTotal * Decimal(0.01), currency: "USD")
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
        
        await MainActor.run { [cacheEntry, dailyCosts, dailyServiceCosts] in
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
                    amount: service.amount * Decimal(1.094), // Last month was 9.4% higher (current is 8.6% lower)
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
                
                await MainActor.run { [services] in
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
    
    // Save cache to disk and update team cache
    private func saveCostCache() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(costCache)
            userDefaults.set(data, forKey: costCacheKey)
            
            // Also save daily costs
            let dailyData = try encoder.encode(dailyCostsByProfile)
            userDefaults.set(dailyData, forKey: dailyCostsKey)
            
            // Save daily service costs for histograms
            let dailyServiceData = try encoder.encode(dailyServiceCostsByProfile)
            userDefaults.set(dailyServiceData, forKey: dailyServiceCostsKey)
            
            log(.debug, category: "Cache", "Saved cache data for \(costCache.count) profiles")
            
            // Update team cache for enabled profiles
            Task {
                await updateTeamCacheAfterAPICall()
            }
        } catch {
            log(.error, category: "Cache", "Failed to save cache: \(error.localizedDescription)")
        }
    }
    
    // Load cache from disk
    private func loadCostCache() {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            if let data = userDefaults.data(forKey: costCacheKey) {
                costCache = try decoder.decode([String: CostCacheEntry].self, from: data)
                log(.debug, category: "Cache", "Loaded cache data for \(costCache.count) profiles")
                
                // If we have a selected profile and cached data for it, populate the display immediately
                if let profile = selectedProfile,
                   let cachedData = costCache[profile.name] {
                    // Populate cost data from cache for immediate display
                    let costData = CostData(
                        profileName: cachedData.profileName,
                        amount: cachedData.mtdTotal,
                        currency: cachedData.currency
                    )
                    self.costData = [costData]
                    self.serviceCosts = cachedData.serviceCosts
                    
                    let cacheAge = Date().timeIntervalSince(cachedData.fetchDate)
                    log(.info, category: "Cache", "Loaded cached data for \(profile.name) (\(Int(cacheAge/60)) minutes old)")
                }
            }
            
            if let dailyData = userDefaults.data(forKey: dailyCostsKey) {
                dailyCostsByProfile = try decoder.decode([String: [DailyCost]].self, from: dailyData)
                log(.debug, category: "Cache", "Loaded daily cost data for \(dailyCostsByProfile.count) profiles")
            }
            
            if let dailyServiceData = userDefaults.data(forKey: dailyServiceCostsKey) {
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
    
    // MARK: - Team Cache Management
    
    // Load team cache settings from UserDefaults
    private func loadTeamCacheSettings() {
        if let data = UserDefaults.standard.data(forKey: teamCacheSettingsKey),
           let settings = try? JSONDecoder().decode([String: ProfileTeamCacheSettings].self, from: data) {
            self.profileTeamCacheSettings = settings
            log(.debug, category: "TeamCache", "Loaded team cache settings for \(settings.count) profiles")
            
            // Initialize S3 cache services for enabled profiles
            initializeTeamCacheServices()
        }
    }
    
    // Save team cache settings to UserDefaults
    private func saveTeamCacheSettings() {
        do {
            let data = try JSONEncoder().encode(profileTeamCacheSettings)
            UserDefaults.standard.set(data, forKey: teamCacheSettingsKey)
            log(.debug, category: "TeamCache", "Saved team cache settings for \(profileTeamCacheSettings.count) profiles")
        } catch {
            log(.error, category: "TeamCache", "Failed to save team cache settings: \(error.localizedDescription)")
        }
    }
    
    // Initialize S3 cache services for enabled profiles
    func initializeTeamCacheServices() {
        print("[TeamCache] Initializing team cache services...")
        teamCacheServices.removeAll()
        
        Task { @MainActor in
            print("[TeamCache] Found \(profileTeamCacheSettings.count) profiles with team cache settings")
            for (profileName, settings) in profileTeamCacheSettings {
                if settings.teamCacheEnabled, let config = settings.teamCacheConfig, config.isValid {
                    do {
                        // Create credentials provider for this profile
                        let credentialsProvider = try createAWSCredentialsProvider(for: profileName)
                        
                        // Initialize S3 service with profile-specific credentials
                        let s3Service = try await S3CacheService(config: config, profileName: profileName, credentialsProvider: credentialsProvider)
                        teamCacheServices[profileName] = s3Service
                        print("[TeamCache] ✅ Initialized S3 cache service for profile: \(profileName)")
                        log(.info, category: "TeamCache", "Initialized S3 cache service for profile: \(profileName)")
                    } catch {
                        log(.error, category: "TeamCache", "Failed to initialize S3 cache service for \(profileName): \(error.localizedDescription)")
                    }
                }
            }
            
            // Start background sync timer if we have any team cache services
            if !teamCacheServices.isEmpty {
                startBackgroundSyncTimer()
            }
        }
    }
    
    // Get team cache settings for a profile
    func getTeamCacheSettings(for profileName: String) -> ProfileTeamCacheSettings {
        return profileTeamCacheSettings[profileName] ?? ProfileTeamCacheSettings()
    }
    
    // Update team cache settings for a profile
    func updateTeamCacheSettings(for profileName: String, settings: ProfileTeamCacheSettings) {
        profileTeamCacheSettings[profileName] = settings
        saveTeamCacheSettings()
        
        // Reinitialize cache services to reflect changes
        initializeTeamCacheServices()
    }
    
    // Start background synchronization timer
    private func startBackgroundSyncTimer() {
        // Cancel any existing timer
        if let existingTimer = backgroundSyncTimer {
            existingTimer.cancel()
            backgroundSyncTimer = nil
        }
        
        // Create a DispatchSourceTimer for background sync
        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        backgroundSyncTimer = timer
        
        // Configure for 5-minute intervals
        timer.schedule(deadline: .now() + 300, repeating: 300.0)
        
        // Set the event handler
        timer.setEventHandler { [weak self] in
            Task {
                await self?.performBackgroundCacheSync()
            }
        }
        
        // Start the timer
        timer.resume()
        
        log(.debug, category: "TeamCache", "Started background sync timer")
    }
    
    // Stop background synchronization timer
    private func stopBackgroundSyncTimer() {
        if let timer = backgroundSyncTimer {
            timer.cancel()
            backgroundSyncTimer = nil
        }
        log(.debug, category: "TeamCache", "Stopped background sync timer")
    }
    
    // Perform background cache synchronization
    private func performBackgroundCacheSync() async {
        log(.debug, category: "TeamCache", "Starting background cache sync")
        
        for (profileName, cacheService) in teamCacheServices {
            guard let accountId = await resolveAccountId(for: profileName),
                  let cacheEntry = costCache[profileName] else {
                continue
            }
            
            do {
                let cacheKey = generateCacheKey(accountId: accountId)
                let remoteCacheEntry = convertToRemoteCacheEntry(cacheEntry, accountId: accountId)
                
                try await cacheService.putObject(key: cacheKey, entry: remoteCacheEntry)
                log(.debug, category: "TeamCache", "Background sync completed for profile: \(profileName)")
            } catch {
                log(.error, category: "TeamCache", "Background sync failed for profile \(profileName): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Team Cache Helper Methods
    
    // Check team cache first for the given profile
    private func checkTeamCacheFirst(for profile: AWSProfile) async -> Bool {
        // Check if team cache is enabled for this profile
        let settings = getTeamCacheSettings(for: profile.name)
        guard settings.teamCacheEnabled,
              let cacheService = teamCacheServices[profile.name] else {
            log(.info, category: "TeamCache", "Team cache not enabled for profile: \(profile.name)")
            return false
        }
        
        log(.info, category: "TeamCache", "📥 Team cache service found for profile: \(profile.name)")
        
        // Resolve account ID and generate cache key
        guard let accountId = await resolveAccountId(for: profile.name) else {
            log(.warning, category: "TeamCache", "Could not resolve account ID for team cache lookup: \(profile.name)")
            return false
        }
        
        let cacheKey = generateCacheKey(accountId: accountId)
        
        do {
            // Try to get data from team cache
            let result = try await cacheService.getObject(key: cacheKey)
            
            switch result {
            case .success(let remoteEntry):
                // Check if the remote cache data is still valid
                let budget = getBudget(for: profile.name)
                let localEntry = convertToLocalCacheEntry(remoteEntry)
                
                if localEntry.isValidForBudget(budget) {
                    log(.info, category: "TeamCache", "Using team cache data for \(profile.name), age: \(Int(Date().timeIntervalSince(remoteEntry.fetchDate) / 60)) minutes")
                    
                    // Update local cache with team cache data
                    await MainActor.run {
                        self.costCache[profile.name] = localEntry
                        self.cacheStatus[profile.name] = remoteEntry.fetchDate
                    }
                    
                    // Load the data into UI
                    await loadFromCache(localEntry)
                    return true
                } else {
                    log(.debug, category: "TeamCache", "Team cache data for \(profile.name) is stale")
                }
                
            case .expired(_):
                log(.debug, category: "TeamCache", "Team cache data for \(profile.name) has expired")
                
            case .notFound:
                log(.debug, category: "TeamCache", "No team cache data found for \(profile.name)")
                
            case .error(let error):
                log(.error, category: "TeamCache", "Team cache lookup failed for \(profile.name): \(error.localizedDescription)")
            }
            
        } catch {
            log(.error, category: "TeamCache", "Team cache error for \(profile.name): \(error.localizedDescription)")
        }
        
        return false
    }
    
    // Update team cache after successful API call
    private func updateTeamCacheAfterAPICall() async {
        print("[TeamCache] 📤 Starting team cache update after API call")
        log(.info, category: "TeamCache", "📤 Starting team cache update after API call")
        
        for (profileName, cacheEntry) in costCache {
            print("[TeamCache] Checking team cache for profile: \(profileName)")
            log(.debug, category: "TeamCache", "Checking team cache for profile: \(profileName)")
            
            // Check if team cache is enabled for this profile
            let settings = getTeamCacheSettings(for: profileName)
            guard settings.teamCacheEnabled else {
                log(.debug, category: "TeamCache", "Team cache not enabled for profile: \(profileName)")
                continue
            }
            
            guard let cacheService = teamCacheServices[profileName] else {
                log(.warning, category: "TeamCache", "Team cache service not initialized for profile: \(profileName)")
                continue
            }
            
            // Resolve account ID
            guard let accountId = await resolveAccountId(for: profileName) else {
                log(.warning, category: "TeamCache", "Could not resolve account ID for team cache update: \(profileName)")
                continue
            }
            
            do {
                let cacheKey = generateCacheKey(accountId: accountId)
                let remoteCacheEntry = convertToRemoteCacheEntry(cacheEntry, accountId: accountId)
                
                try await cacheService.putObject(key: cacheKey, entry: remoteCacheEntry)
                print("[TeamCache] ✅ Successfully stored cache in S3 for profile: \(profileName), key: \(cacheKey)")
                log(.info, category: "TeamCache", "✅ Successfully stored cache in S3 for profile: \(profileName), key: \(cacheKey)")
            } catch {
                log(.error, category: "TeamCache", "Failed to update team cache for \(profileName): \(error.localizedDescription)")
            }
        }
    }
    
    // Generate cache key for current month
    private func generateCacheKey(accountId: String) -> String {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        
        return CacheKeyGenerator.generateKey(
            accountId: accountId,
            year: year,
            month: month,
            dataType: .fullData
        )
    }
    
    // Resolve AWS account ID for a profile
    private func resolveAccountId(for profileName: String) async -> String? {
        do {
            // Create credentials provider for the specific profile
            let credentialsProvider = try createAWSCredentialsProvider(for: profileName)
            
            // Use AWS STS to get account ID with profile-specific credentials
            let stsConfig = try await STSClient.STSClientConfiguration(
                awsCredentialIdentityResolver: credentialsProvider,
                region: "us-east-1" // STS is available in all regions
            )
            let stsClient = STSClient(config: stsConfig)
            
            let input = GetCallerIdentityInput()
            let output = try await stsClient.getCallerIdentity(input: input)
            
            if let accountId = output.account {
                log(.debug, category: "TeamCache", "Resolved account ID for \(profileName): \(accountId)")
                return accountId
            } else {
                log(.warning, category: "TeamCache", "Could not resolve account ID for profile: \(profileName)")
                return nil
            }
        } catch {
            log(.error, category: "TeamCache", "Failed to resolve account ID for \(profileName): \(error.localizedDescription)")
            return nil
        }
    }
    
    // Convert local cache entry to remote cache entry
    private func convertToRemoteCacheEntry(_ localEntry: CostCacheEntry, accountId: String) -> RemoteCacheEntry {
        let cacheKey = generateCacheKey(accountId: accountId)
        let metadata = CacheMetadata(
            createdBy: "AWSCostMonitor",
            createdAt: Date(),
            ttl: 3600, // 1 hour TTL
            cacheKey: cacheKey
        )
        
        return RemoteCacheEntry(
            profileName: localEntry.profileName,
            accountId: accountId,
            fetchDate: localEntry.fetchDate,
            mtdTotal: localEntry.mtdTotal,
            currency: localEntry.currency,
            dailyCosts: localEntry.dailyCosts,
            serviceCosts: localEntry.serviceCosts,
            startDate: localEntry.startDate,
            endDate: localEntry.endDate,
            metadata: metadata
        )
    }
    
    // Convert remote cache entry to local cache entry
    private func convertToLocalCacheEntry(_ remoteEntry: RemoteCacheEntry) -> CostCacheEntry {
        return CostCacheEntry(
            profileName: remoteEntry.profileName,
            fetchDate: remoteEntry.fetchDate,
            mtdTotal: remoteEntry.mtdTotal,
            currency: remoteEntry.currency,
            dailyCosts: remoteEntry.dailyCosts,
            serviceCosts: remoteEntry.serviceCosts,
            startDate: remoteEntry.startDate,
            endDate: remoteEntry.endDate
        )
    }
    
    // MARK: - Team Cache Cleanup and Maintenance
    
    // Clean up old cache entries for a profile
    func cleanupTeamCache(for profileName: String) async {
        let settings = getTeamCacheSettings(for: profileName)
        guard settings.teamCacheEnabled,
              let cacheService = teamCacheServices[profileName] else {
            return
        }
        
        guard let accountId = await resolveAccountId(for: profileName) else {
            log(.warning, category: "TeamCache", "Could not resolve account ID for cache cleanup: \(profileName)")
            return
        }
        
        do {
            // List all cache entries for this account
            let prefix = "cache-v1/\(accountId)/"
            let keys = try await cacheService.listObjects(prefix: prefix)
            
            let calendar = Calendar.current
            let now = Date()
            _ = calendar.component(.month, from: now)
            _ = calendar.component(.year, from: now)
            
            // Delete entries older than 3 months
            for key in keys {
                if let parsed = CacheKeyGenerator.parseKey(key) {
                    let entryDate = calendar.date(from: DateComponents(year: parsed.year, month: parsed.month))
                    let monthsOld = calendar.dateComponents([.month], from: entryDate ?? now, to: now).month ?? 0
                    
                    if monthsOld > 3 {
                        try await cacheService.deleteObject(key: key)
                        log(.info, category: "TeamCache", "Deleted old cache entry: \(key)")
                    }
                }
            }
            
            log(.info, category: "TeamCache", "Cache cleanup completed for profile: \(profileName)")
        } catch {
            log(.error, category: "TeamCache", "Cache cleanup failed for \(profileName): \(error.localizedDescription)")
        }
    }
    
    // Force refresh cache (bypass all cache layers)
    func forceRefreshWithTeamCacheUpdate() async {
        guard let profile = selectedProfile else {
            log(.warning, category: "TeamCache", "No profile selected for force refresh")
            return
        }
        
        // Clear local cache first
        costCache.removeValue(forKey: profile.name)
        cacheStatus.removeValue(forKey: profile.name)
        
        // Clear team cache if enabled
        let settings = getTeamCacheSettings(for: profile.name)
        if settings.teamCacheEnabled,
           let cacheService = teamCacheServices[profile.name],
           let accountId = await resolveAccountId(for: profile.name) {
            
            let cacheKey = generateCacheKey(accountId: accountId)
            
            do {
                try await cacheService.deleteObject(key: cacheKey)
                log(.info, category: "TeamCache", "Cleared team cache for profile: \(profile.name)")
            } catch {
                log(.error, category: "TeamCache", "Failed to clear team cache for \(profile.name): \(error.localizedDescription)")
            }
        }
        
        // Now fetch fresh data from API
        await fetchCostForSelectedProfile(force: true)
    }
    
    // Test team cache connection for a profile
    func testTeamCacheConnection(for profileName: String) async -> Bool {
        let settings = getTeamCacheSettings(for: profileName)
        guard settings.teamCacheEnabled else {
            log(.warning, category: "TeamCache", "Team cache not enabled for profile: \(profileName)")
            return false
        }
        
        // Check if service exists, if not try to create it
        var cacheService = teamCacheServices[profileName]
        if cacheService == nil {
            log(.info, category: "TeamCache", "Cache service not found, initializing for test...")
            
            // Try to initialize the service
            if let config = settings.teamCacheConfig, config.isValid {
                do {
                    let credentialsProvider = try createAWSCredentialsProvider(for: profileName)
                    cacheService = try await S3CacheService(config: config, profileName: profileName, credentialsProvider: credentialsProvider)
                    teamCacheServices[profileName] = cacheService
                    log(.info, category: "TeamCache", "Initialized cache service for test")
                } catch {
                    log(.error, category: "TeamCache", "Failed to initialize cache service for test: \(error.localizedDescription)")
                    return false
                }
            } else {
                log(.error, category: "TeamCache", "Invalid team cache configuration for profile: \(profileName)")
                return false
            }
        }
        
        guard let service = cacheService else {
            log(.error, category: "TeamCache", "Could not get cache service for profile: \(profileName)")
            return false
        }
        
        do {
            try await service.testConnection()
            log(.info, category: "TeamCache", "✅ Team cache connection test successful for: \(profileName)")
            return true
        } catch {
            log(.error, category: "TeamCache", "❌ Team cache connection test failed for \(profileName): \(error.localizedDescription)")
            return false
        }
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
    
    // MARK: - AWS Config Access Window
    
    /// Create a persistent window for AWS config access that won't disappear
    private func createPersistentAWSConfigWindow() {
        let awsConfigView = AWSConfigAccessView()
        
        let hostingController = NSHostingController(rootView: awsConfigView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "AWS Configuration Access Required"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.hidesOnDeactivate = false
        
        // Make it modal so it stays on top and doesn't disappear
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        
        // Keep the window alive
        var windowRef = window
        objc_setAssociatedObject(self, "awsConfigWindow", windowRef, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        print("[DEBUG] PERSISTENT AWS Config Access window created and displayed")
        print("[DEBUG] Window size: \(window.frame.size)")
        print("[DEBUG] Window level: \(window.level.rawValue)")
        
        // Also try to show the file picker using the existing method
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("[DEBUG] Attempting to show file picker using existing requestAccess method...")
            AWSConfigAccessManager.shared.requestAccess(from: window)
        }
    }
    
    
    /// Show a modal window for AWS config access request
    private func showAWSConfigAccessWindow() {
        let awsConfigView = AWSConfigAccessView()
        
        let hostingController = NSHostingController(rootView: awsConfigView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "AWS Configuration Access Required"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        // Make it visible and persistent
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        
        print("[DEBUG] AWS Config Access modal window displayed and waiting for user interaction")
    }
    
    // MARK: - Demo Mode Support
    
    #if !OPENSOURCE
    // Load demo data for App Store review
    func loadDemoData() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // Generate realistic demo data
        let demoData = DemoDataProvider.generateDemoCostData()
        
        await MainActor.run {
            // Clear any existing data
            self.costData = []
            self.serviceCosts = []
            
            // Use consistent profile name for demo data
            let demoProfileName = DemoDataProvider.demoProfileName
            
            // Set the MTD cost
            self.costData = [CostData(
                profileName: demoProfileName,
                amount: Decimal(demoData.mtdSpend),
                currency: "USD"
            )]
            
            // Set service breakdown
            self.serviceCosts = demoData.services
            
            // Create and populate cost cache entry for demo data
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
            
            let cacheEntry = CostCacheEntry(
                profileName: demoProfileName,
                fetchDate: Date(),
                mtdTotal: Decimal(demoData.mtdSpend),
                currency: "USD",
                dailyCosts: demoData.dailyCosts.map { dailyCost in
                    DailyCost(
                        date: dailyCost.date,
                        amount: Decimal(dailyCost.amount),
                        currency: "USD"
                    )
                },
                serviceCosts: demoData.services,
                startDate: startOfMonth,
                endDate: endOfMonth
            )
            self.costCache[demoProfileName] = cacheEntry
            
            // Set daily costs for calendar view - use the same profile name as CostData
            if true {  // Always set for demo data
                let profileName = demoProfileName
                self.dailyCostsByProfile[profileName] = demoData.dailyCosts.map { dailyCost in
                    DailyCost(
                        date: dailyCost.date,
                        amount: Decimal(dailyCost.amount),
                        currency: "USD"
                    )
                }
                
                // Convert to daily service costs for histogram
                var dailyServiceCosts: [DailyServiceCost] = []
                for dailyCost in demoData.dailyCosts {
                    for service in dailyCost.services {
                        dailyServiceCosts.append(DailyServiceCost(
                            date: dailyCost.date,
                            serviceName: service.serviceName,
                            amount: service.amount,
                            currency: service.currency
                        ))
                    }
                }
                self.dailyServiceCostsByProfile[profileName] = dailyServiceCosts
                
                // Set cache status
                self.cacheStatus[profileName] = Date()
                
                // Set forecast
                self.projectedMonthlyTotal = Decimal(demoData.forecast)
                
                // Determine trend
                let percentageChange = ((demoData.mtdSpend - demoData.previousMonthSpend) / demoData.previousMonthSpend) * 100
                if demoData.mtdSpend > demoData.previousMonthSpend * 1.1 {
                    self.costTrend = .up(percentage: percentageChange)
                } else if demoData.mtdSpend < demoData.previousMonthSpend * 0.9 {
                    self.costTrend = .down(percentage: abs(percentageChange))
                } else {
                    self.costTrend = .stable
                }
            }
            
            self.isLoading = false
            self.lastAPICallTime = Date()
            self.nextRefreshTime = Date().addingTimeInterval(TimeInterval(self.refreshInterval * 60))
            
            // Log demo data load
            log(.info, category: "Demo", "Loaded demo data for profile: \(self.selectedProfile?.name ?? "unknown")")
        }
    }
    #endif
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
