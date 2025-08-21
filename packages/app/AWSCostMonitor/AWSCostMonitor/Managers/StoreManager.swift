//
//  StoreManager.swift
//  AWSCostMonitor
//
//  Handles in-app purchases using StoreKit 2
//

import SwiftUI

// Team Cache is now a standard feature

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    // Team Cache is always enabled 
    @Published var hasTeamCache = true
    
    init() {
        // Team cache is now always enabled
        UserDefaults.standard.set(true, forKey: "HasTeamCache")
    }
    
    #if DEBUG
    func simulateSuccessfulPurchase() {
        // Kept for backwards compatibility and testing
        print("🎉 DEBUG: Team Cache always available")
    }
    
    func clearPurchase() {
        // Kept for backwards compatibility and testing
        print("🗑️ DEBUG: Team Cache always available")
    }
    #endif
}