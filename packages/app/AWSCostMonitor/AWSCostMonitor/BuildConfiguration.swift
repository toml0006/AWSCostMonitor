//
//  BuildConfiguration.swift
//  AWSCostMonitor
//
//  Build configuration flags for different versions
//

import Foundation

/// Build configuration for different app versions
struct BuildConfiguration {
    /// Whether this is an open source build (without Team Cache features)
    #if OPENSOURCE
    static let isOpenSource = true
    #else
    static let isOpenSource = false
    #endif
    
    /// Whether Team Cache features should be enabled
    static var isTeamCacheEnabled: Bool {
        return !isOpenSource
    }
    
    /// Product name for display
    static var productName: String {
        return isOpenSource ? "AWSCostMonitor OSS" : "AWSCostMonitor"
    }
    
    /// Whether in-app purchases are available
    static var areInAppPurchasesEnabled: Bool {
        return !isOpenSource
    }
}