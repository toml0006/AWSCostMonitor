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