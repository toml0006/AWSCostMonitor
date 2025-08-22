//
//  ProfileBudget.swift
//  AWSCostMonitor
//
//  Budget configuration model
//

import Foundation

// Budget configuration for each profile
struct ProfileBudget: Codable, Identifiable {
    let id = UUID()
    let profileName: String
    var monthlyBudget: Decimal? // Optional monthly budget - if nil, no budget tracking
    var alertThreshold: Double // Percentage (0.0 - 1.0) - only used if monthlyBudget is set
    var apiBudget: Decimal // Cost Explorer API budget per month
    var refreshIntervalMinutes: Int // Auto-refresh interval (defaults to 8 hours)

    enum CodingKeys: String, CodingKey {
        case profileName, monthlyBudget, alertThreshold, apiBudget, refreshIntervalMinutes
    }

    init(profileName: String, monthlyBudget: Decimal? = nil, alertThreshold: Double = 0.8, apiBudget: Decimal = 5.0, refreshIntervalMinutes: Int = 480) {
        self.profileName = profileName
        self.monthlyBudget = monthlyBudget
        self.alertThreshold = alertThreshold
        self.apiBudget = apiBudget
        self.refreshIntervalMinutes = refreshIntervalMinutes
    }
}