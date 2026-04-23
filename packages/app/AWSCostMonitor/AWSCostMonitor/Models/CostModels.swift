//
//  CostModels.swift
//  AWSCostMonitor
//
//  Cost-related data models
//

import Foundation
import SwiftUI

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
    var id = UUID()
    let serviceName: String
    let amount: Decimal
    let currency: String
    
    static func < (lhs: ServiceCost, rhs: ServiceCost) -> Bool {
        lhs.amount > rhs.amount // Sort by amount descending
    }
}

// Tag-level cost breakdown
struct TagCost: Identifiable, Comparable, Codable {
    var id = UUID()
    let tagValue: String
    let amount: Decimal
    let currency: String
    
    static func < (lhs: TagCost, rhs: TagCost) -> Bool {
        lhs.amount > rhs.amount // Sort by amount descending
    }
}

// Account-level cost breakdown (linked accounts in an AWS Organization)
struct AccountCost: Identifiable, Comparable, Codable {
    var id = UUID()
    let accountId: String
    let accountName: String?   // Resolved from the SDK's Attributes map when present
    let amount: Decimal
    let currency: String

    var displayName: String { accountName ?? accountId }

    static func < (lhs: AccountCost, rhs: AccountCost) -> Bool {
        lhs.amount > rhs.amount
    }
}

// Region-level cost breakdown
struct RegionCost: Identifiable, Comparable, Codable {
    var id = UUID()
    let region: String
    let amount: Decimal
    let currency: String

    static func < (lhs: RegionCost, rhs: RegionCost) -> Bool {
        lhs.amount > rhs.amount
    }
}

// User preference for breakdown view
enum CostBreakdownMode: String, CaseIterable, Codable, Identifiable {
    case service
    case tag
    case account
    case region

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .service: return "Service"
        case .tag: return "Tag"
        case .account: return "Account"
        case .region: return "Region"
        }
    }
}

// Daily cost data point
struct DailyCost: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let amount: Decimal
    let currency: String
}

// Daily service cost data point for histograms
struct DailyServiceCost: Identifiable, Codable {
    var id = UUID()
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
    let forecastTotal: Decimal?
    let forecastCurrency: String?
    let forecastFetchDate: Date?
    
    var isValid: Bool {
        // Cache validity based on age and completeness
        let age = Date().timeIntervalSince(fetchDate)
        let maxAge: TimeInterval = 3600 // 1 hour default max age
        return age < maxAge
    }
    
    func isValidForBudget(_ budget: ProfileBudget) -> Bool {
        // Cache validity combines the profile's configured refresh interval
        // with a budget-aware tightening when spend is close to the budget.
        let age = Date().timeIntervalSince(fetchDate)
        let configuredMax = TimeInterval(max(1, budget.refreshIntervalMinutes) * 60)

        let budgetPercentage: Double
        if let monthlyBudget = budget.monthlyBudget, monthlyBudget > 0 {
            budgetPercentage = NSDecimalNumber(decimal: mtdTotal).dividing(by: NSDecimalNumber(decimal: monthlyBudget)).doubleValue
        } else {
            budgetPercentage = 0.0
        }

        // Budget proximity can only shorten the window, never extend it past
        // what the user configured.
        let budgetMax: TimeInterval
        if budgetPercentage > 0.95 {
            budgetMax = 900
        } else if budgetPercentage > 0.8 {
            budgetMax = 1800
        } else if budgetPercentage > 0.5 {
            budgetMax = 3600
        } else {
            budgetMax = configuredMax
        }

        return age < min(configuredMax, budgetMax)
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

// Anomaly surfaced by AWS Cost Explorer's own detection (GetAnomalies).
// Kept separate from SpendingAnomaly so the UI can show "AWS-detected"
// with dollar impact and root-cause services when available.
struct CloudAnomaly: Identifiable, Codable {
    var id: String { anomalyId }
    let anomalyId: String
    let startDate: Date
    let endDate: Date?
    let totalImpact: Double            // Dollars over expected
    let impactPercentage: Double       // % deviation
    let maxScore: Double               // 0..1 confidence
    let topService: String?            // From first RootCause if present
    let rootCauseCount: Int
}

// Aggregated commitment coverage/utilization across RIs and Savings Plans.
// nil fields indicate the corresponding API was unavailable (access denied,
// not configured, or no commitments exist for the account).
struct CommitmentSummary: Codable {
    let riCoveragePercent: Double?       // % of on-demand-eligible usage covered by RIs
    let riUtilizationPercent: Double?    // % of owned RI hours actually used
    let spCoveragePercent: Double?       // % of compute spend covered by Savings Plans
    let spUtilizationPercent: Double?    // % of SP commitment consumed
    let fetchDate: Date

    /// Combined coverage: prefer Savings Plans when both present (modern AWS
    /// accounts use SP over RI). Returns nil if neither is available.
    var preferredCoveragePercent: Double? {
        spCoveragePercent ?? riCoveragePercent
    }

    var hasAnyData: Bool {
        riCoveragePercent != nil
            || riUtilizationPercent != nil
            || spCoveragePercent != nil
            || spUtilizationPercent != nil
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
