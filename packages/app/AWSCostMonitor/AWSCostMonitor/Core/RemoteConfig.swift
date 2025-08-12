//
//  RemoteConfig.swift
//  AWSCostMonitor
//
//  Remote configuration system for flexible feature and trial management
//

import Foundation
import OSLog

/// Remote configuration manager for dynamic feature control
@MainActor
class RemoteConfig: ObservableObject {
    static let shared = RemoteConfig()
    
    private let logger = Logger(subsystem: "middleout.AWSCostMonitor", category: "RemoteConfig")
    
    // MARK: - Configuration Structure
    
    struct Config: Codable {
        let trialDurationDays: Int
        let promoCodesEnabled: Bool
        let minimumVersion: String
        let features: [String: Bool]
        let marketing: MarketingConfig?
        let lastUpdated: String
        
        struct MarketingConfig: Codable {
            let showTrialExtension: Bool
            let campaignMessage: String?
            let specialOfferActive: Bool
        }
        
        // Default configuration for fallback
        static let `default` = Config(
            trialDurationDays: 3,
            promoCodesEnabled: true,
            minimumVersion: "1.3.0",
            features: [
                "teamCache": true,
                "unlimitedProfiles": true,
                "advancedForecasting": true,
                "dataExport": true
            ],
            marketing: MarketingConfig(
                showTrialExtension: false,
                campaignMessage: nil,
                specialOfferActive: false
            ),
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    // MARK: - Published State
    
    @Published private(set) var config: Config = Config.default
    @Published private(set) var lastFetchDate: Date?
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: Error?
    
    // MARK: - Configuration URL
    
    private var configURL: URL {
        // In production, this would be your actual API endpoint
        // For now, using a placeholder that can be updated via build settings
        #if DEBUG
        return URL(string: "https://api.awscostmonitor.dev/config.json")!
        #else
        return URL(string: "https://api.awscostmonitor.app/config.json")!
        #endif
    }
    
    private let userDefaults = UserDefaults.standard
    private let configCacheKey = "CachedRemoteConfig"
    private let lastFetchKey = "RemoteConfigLastFetch"
    
    // MARK: - Initialization
    
    private init() {
        loadCachedConfig()
        Task {
            await fetchConfigIfNeeded()
        }
    }
    
    // MARK: - Public API
    
    /// Trial duration in days (remotely configurable)
    var trialDurationDays: Int {
        config.trialDurationDays
    }
    
    /// Whether promotional codes are enabled
    var promoCodesEnabled: Bool {
        config.promoCodesEnabled
    }
    
    /// Check if a specific feature is enabled remotely
    func isFeatureEnabled(_ feature: String) -> Bool {
        return config.features[feature] ?? false
    }
    
    /// Check if a specific premium feature is enabled
    func isFeatureEnabled(_ feature: PremiumFeature) -> Bool {
        return isFeatureEnabled(feature.rawValue)
    }
    
    /// Current marketing message (if any)
    var marketingMessage: String? {
        config.marketing?.campaignMessage
    }
    
    /// Whether a special offer is currently active
    var isSpecialOfferActive: Bool {
        config.marketing?.specialOfferActive ?? false
    }
    
    /// Force refresh configuration from remote
    func refreshConfig() async {
        await fetchConfig(forced: true)
    }
    
    // MARK: - Configuration Fetching
    
    private func fetchConfigIfNeeded() async {
        // Fetch if we haven't fetched in the last 24 hours or if we have no cached config
        let shouldFetch = lastFetchDate == nil || 
                         (Date().timeIntervalSince(lastFetchDate!) > 24 * 60 * 60)
        
        if shouldFetch {
            await fetchConfig()
        }
    }
    
    private func fetchConfig(forced: Bool = false) async {
        if isLoading && !forced {
            return
        }
        
        isLoading = true
        lastError = nil
        
        logger.info("Fetching remote configuration from \(self.configURL.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: configURL)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw RemoteConfigError.httpError((response as? HTTPURLResponse)?.statusCode ?? -1)
            }
            
            let decoder = JSONDecoder()
            let newConfig = try decoder.decode(Config.self, from: data)
            
            // Validate configuration
            try validateConfig(newConfig)
            
            // Update configuration
            config = newConfig
            lastFetchDate = Date()
            
            // Cache the configuration
            cacheConfig(newConfig)
            
            logger.info("Successfully updated remote configuration")
            logger.info("Trial duration: \(newConfig.trialDurationDays) days")
            logger.info("Features enabled: \(newConfig.features)")
            
        } catch {
            logger.error("Failed to fetch remote configuration: \(error.localizedDescription)")
            lastError = error
            
            // If we have no cached config, ensure we have defaults
            if lastFetchDate == nil {
                logger.info("Using default configuration as fallback")
                config = Config.default
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Configuration Validation
    
    private func validateConfig(_ config: Config) throws {
        // Validate trial duration is reasonable (1-30 days)
        guard config.trialDurationDays >= 1 && config.trialDurationDays <= 30 else {
            throw RemoteConfigError.invalidTrialDuration(config.trialDurationDays)
        }
        
        // Validate minimum version format
        let versionComponents = config.minimumVersion.components(separatedBy: ".")
        guard versionComponents.count >= 2,
              versionComponents.allSatisfy({ Int($0) != nil }) else {
            throw RemoteConfigError.invalidVersion(config.minimumVersion)
        }
        
        logger.info("Configuration validation passed")
    }
    
    // MARK: - Caching
    
    private func cacheConfig(_ config: Config) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(config)
            userDefaults.set(data, forKey: configCacheKey)
            userDefaults.set(Date(), forKey: lastFetchKey)
            logger.info("Cached remote configuration")
        } catch {
            logger.error("Failed to cache configuration: \(error.localizedDescription)")
        }
    }
    
    private func loadCachedConfig() {
        guard let data = userDefaults.data(forKey: configCacheKey) else {
            logger.info("No cached configuration found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            config = try decoder.decode(Config.self, from: data)
            lastFetchDate = userDefaults.object(forKey: lastFetchKey) as? Date
            logger.info("Loaded cached configuration from \(self.lastFetchDate?.description ?? "unknown date")")
        } catch {
            logger.error("Failed to load cached configuration: \(error.localizedDescription)")
            config = Config.default
        }
    }
    
    // MARK: - Version Checking
    
    /// Check if the current app version meets the minimum required version
    func isVersionSupported() -> Bool {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return false
        }
        
        return compareVersions(currentVersion, config.minimumVersion) != .orderedAscending
    }
    
    private func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        let v1Components = version1.components(separatedBy: ".").compactMap { Int($0) }
        let v2Components = version2.components(separatedBy: ".").compactMap { Int($0) }
        
        let maxCount = max(v1Components.count, v2Components.count)
        
        for i in 0..<maxCount {
            let v1Value = i < v1Components.count ? v1Components[i] : 0
            let v2Value = i < v2Components.count ? v2Components[i] : 0
            
            if v1Value < v2Value {
                return .orderedAscending
            } else if v1Value > v2Value {
                return .orderedDescending
            }
        }
        
        return .orderedSame
    }
}

// MARK: - Error Types

enum RemoteConfigError: Error, LocalizedError {
    case httpError(Int)
    case invalidTrialDuration(Int)
    case invalidVersion(String)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .invalidTrialDuration(let days):
            return "Invalid trial duration: \(days) days"
        case .invalidVersion(let version):
            return "Invalid version format: \(version)"
        case .decodingError(let error):
            return "Failed to decode configuration: \(error.localizedDescription)"
        }
    }
}

// MARK: - Development Helpers

#if DEBUG
extension RemoteConfig {
    /// Set a custom configuration for testing (Debug builds only)
    func setTestConfig(_ config: Config) {
        self.config = config
        cacheConfig(config)
        logger.info("Set test configuration")
    }
    
    /// Reset to default configuration (Debug builds only)  
    func resetToDefaults() {
        config = Config.default
        lastFetchDate = nil
        userDefaults.removeObject(forKey: configCacheKey)
        userDefaults.removeObject(forKey: lastFetchKey)
        logger.info("Reset to default configuration")
    }
}
#endif