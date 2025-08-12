//
//  FeatureFlags.swift
//  AWSCostMonitor
//
//  Central feature flag management for free vs premium features
//

import Foundation
import os.log

/// Central feature flag management for controlling premium features
struct FeatureFlags {
    private static let logger = Logger(subsystem: "middleout.AWSCostMonitor", category: "FeatureFlags")
    
    // MARK: - Build Configuration Flags
    
    /// Whether this is an App Store build with StoreKit support
    static var isAppStoreBuild: Bool {
        #if APPSTORE_BUILD
        return true
        #else
        return false
        #endif
    }
    
    /// Whether premium features are compiled into this build
    static var hasPremiumFeaturesCompiled: Bool {
        #if PREMIUM_FEATURES
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Feature Access Control
    
    /// Whether team cache features are available to the current user
    static var hasTeamCacheFeatures: Bool {
        #if PREMIUM_FEATURES
        let remoteEnabled = RemoteConfig.shared.isFeatureEnabled("teamCache")
        
        #if APPSTORE_BUILD
        // App Store build: requires purchase or active trial
        let hasAccess = PurchaseManager.shared.hasAccessToProFeatures
        let result = remoteEnabled && hasAccess
        logger.info("Team cache access: remote=\(remoteEnabled), hasAccess=\(hasAccess), result=\(result)")
        return result
        #else
        // Development build: only needs remote flag
        logger.info("Team cache access (dev build): remote=\(remoteEnabled)")
        return remoteEnabled
        #endif
        #else
        // Open source build: always disabled
        return false
        #endif
    }
    
    /// Whether unlimited AWS profiles are available
    static var hasUnlimitedProfiles: Bool {
        #if PREMIUM_FEATURES
        let remoteEnabled = RemoteConfig.shared.isFeatureEnabled("unlimitedProfiles") 
        
        #if APPSTORE_BUILD
        return remoteEnabled && PurchaseManager.shared.hasAccessToProFeatures
        #else
        return remoteEnabled
        #endif
        #else
        return false
        #endif
    }
    
    /// Whether advanced forecasting features are available
    static var hasAdvancedForecasting: Bool {
        #if PREMIUM_FEATURES
        let remoteEnabled = RemoteConfig.shared.isFeatureEnabled("advancedForecasting")
        
        #if APPSTORE_BUILD
        return remoteEnabled && PurchaseManager.shared.hasAccessToProFeatures
        #else
        return remoteEnabled
        #endif
        #else
        return false
        #endif
    }
    
    /// Whether data export features are available
    static var hasDataExport: Bool {
        #if PREMIUM_FEATURES
        let remoteEnabled = RemoteConfig.shared.isFeatureEnabled("dataExport")
        
        #if APPSTORE_BUILD
        return remoteEnabled && PurchaseManager.shared.hasAccessToProFeatures
        #else
        return remoteEnabled
        #endif
        #else
        return false
        #endif
    }
    
    // MARK: - Profile Limits
    
    /// Maximum number of AWS profiles allowed in this build
    static var maxProfiles: Int {
        if hasUnlimitedProfiles {
            return Int.max
        } else {
            return 1 // Free tier: single profile only
        }
    }
    
    // MARK: - Debug Information
    
    static func logFeatureStatus() {
        logger.info("=== Feature Flags Status ===")
        logger.info("App Store Build: \(isAppStoreBuild)")
        logger.info("Premium Features Compiled: \(hasPremiumFeaturesCompiled)")
        logger.info("Team Cache: \(hasTeamCacheFeatures)")
        logger.info("Unlimited Profiles: \(hasUnlimitedProfiles)")
        logger.info("Advanced Forecasting: \(hasAdvancedForecasting)")
        logger.info("Data Export: \(hasDataExport)")
        logger.info("Max Profiles: \(maxProfiles == Int.max ? "Unlimited" : String(maxProfiles))")
        logger.info("=============================")
    }
}

// MARK: - Premium Feature Definitions

/// Enumeration of all premium features for easy reference
enum PremiumFeature: String, CaseIterable {
    case teamCache = "teamCache"
    case unlimitedProfiles = "unlimitedProfiles"
    case advancedForecasting = "advancedForecasting"
    case dataExport = "dataExport"
    
    var displayName: String {
        switch self {
        case .teamCache:
            return "Team Cache"
        case .unlimitedProfiles:
            return "Unlimited AWS Profiles"
        case .advancedForecasting:
            return "Advanced Cost Forecasting"
        case .dataExport:
            return "Data Export"
        }
    }
    
    var description: String {
        switch self {
        case .teamCache:
            return "Share cost data across your team with S3-based caching"
        case .unlimitedProfiles:
            return "Monitor costs across unlimited AWS profiles"
        case .advancedForecasting:
            return "Machine learning-powered cost predictions and anomaly detection"
        case .dataExport:
            return "Export cost data to CSV, JSON, and other formats"
        }
    }
    
    /// Whether this feature is available in the current build configuration
    var isAvailable: Bool {
        switch self {
        case .teamCache:
            return FeatureFlags.hasTeamCacheFeatures
        case .unlimitedProfiles:
            return FeatureFlags.hasUnlimitedProfiles
        case .advancedForecasting:
            return FeatureFlags.hasAdvancedForecasting
        case .dataExport:
            return FeatureFlags.hasDataExport
        }
    }
}