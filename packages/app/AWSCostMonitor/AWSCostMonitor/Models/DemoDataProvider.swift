//
//  DemoDataProvider.swift
//  AWSCostMonitor
//
//  Demo data for App Store review
//

import Foundation

struct DemoDataProvider {
    static let demoProfileName = "demo-aws-account"
    
    // Generate realistic demo cost data
    static func generateDemoCostData() -> DemoCostData {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate month-to-date total
        let dayOfMonth = calendar.component(.day, from: now)
        let baseDaily = 42.50
        let variance = 15.0
        
        var dailyCosts: [DemoDailyCost] = []
        var totalMTD = 0.0
        
        // Generate daily costs for the last 14 days (for histogram)
        var last14DaysCosts: [DemoDailyCost] = []
        for daysAgo in 0..<14 {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) {
                let dailyVariance = Double.random(in: -variance...variance)
                let cost = baseDaily + dailyVariance
                
                last14DaysCosts.insert(DemoDailyCost(
                    date: date,
                    amount: cost,
                    services: generateServiceBreakdown(totalCost: cost)
                ), at: 0) // Insert at beginning to maintain chronological order
            }
        }
        
        // Also generate daily costs for the current month (for MTD calculation)
        for day in 1...dayOfMonth {
            let dailyVariance = Double.random(in: -variance...variance)
            let cost = baseDaily + dailyVariance
            totalMTD += cost
            
            if let date = calendar.date(from: DateComponents(
                year: calendar.component(.year, from: now),
                month: calendar.component(.month, from: now),
                day: day
            )) {
                // Check if this date is not already in last14DaysCosts
                let isInLast14Days = last14DaysCosts.contains { 
                    calendar.isDate($0.date, inSameDayAs: date) 
                }
                
                if !isInLast14Days {
                    dailyCosts.append(DemoDailyCost(
                        date: date,
                        amount: cost,
                        services: generateServiceBreakdown(totalCost: cost)
                    ))
                }
            }
        }
        
        // Combine both lists, ensuring no duplicates and proper ordering
        dailyCosts = (dailyCosts + last14DaysCosts).sorted { $0.date < $1.date }
        
        // Calculate previous month for comparison
        let previousMonthTotal = baseDaily * 30 + Double.random(in: -100...100)
        
        // Service breakdown for MTD
        let services = [
            ServiceCost(serviceName: "Amazon EC2", amount: Decimal(totalMTD * 0.35), currency: "USD"),
            ServiceCost(serviceName: "Amazon RDS", amount: Decimal(totalMTD * 0.20), currency: "USD"),
            ServiceCost(serviceName: "Amazon S3", amount: Decimal(totalMTD * 0.15), currency: "USD"),
            ServiceCost(serviceName: "AWS Lambda", amount: Decimal(totalMTD * 0.10), currency: "USD"),
            ServiceCost(serviceName: "Amazon CloudFront", amount: Decimal(totalMTD * 0.08), currency: "USD"),
            ServiceCost(serviceName: "AWS Support", amount: Decimal(totalMTD * 0.05), currency: "USD"),
            ServiceCost(serviceName: "Amazon DynamoDB", amount: Decimal(totalMTD * 0.04), currency: "USD"),
            ServiceCost(serviceName: "Other Services", amount: Decimal(totalMTD * 0.03), currency: "USD")
        ]
        
        // Calculate forecast
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let remainingDays = daysInMonth - dayOfMonth
        let averageDaily = totalMTD / Double(dayOfMonth)
        let forecastTotal = totalMTD + (averageDaily * Double(remainingDays))
        
        return DemoCostData(
            mtdSpend: totalMTD,
            previousMonthSpend: previousMonthTotal,
            dailyCosts: dailyCosts,
            services: services,
            forecast: forecastTotal,
            lastUpdated: now,
            profile: demoProfileName
        )
    }
    
    private static func generateServiceBreakdown(totalCost: Double) -> [ServiceCost] {
        return [
            ServiceCost(serviceName: "Amazon EC2", amount: Decimal(totalCost * 0.35), currency: "USD"),
            ServiceCost(serviceName: "Amazon RDS", amount: Decimal(totalCost * 0.20), currency: "USD"),
            ServiceCost(serviceName: "Amazon S3", amount: Decimal(totalCost * 0.15), currency: "USD"),
            ServiceCost(serviceName: "AWS Lambda", amount: Decimal(totalCost * 0.10), currency: "USD"),
            ServiceCost(serviceName: "Amazon CloudFront", amount: Decimal(totalCost * 0.08), currency: "USD"),
            ServiceCost(serviceName: "Other", amount: Decimal(totalCost * 0.12), currency: "USD")
        ]
    }
    
    // Demo AWS profiles for the picker
    static let demoProfiles = [
        AWSProfile(name: "demo-aws-account", region: "us-east-1"),
        AWSProfile(name: "demo-production", region: "us-west-2"),
        AWSProfile(name: "demo-staging", region: "eu-west-1"),
        AWSProfile(name: "demo-development", region: "ap-southeast-1")
    ]
}

// Simple models for demo data
struct DemoCostData {
    let mtdSpend: Double
    let previousMonthSpend: Double
    let dailyCosts: [DemoDailyCost]
    let services: [ServiceCost]
    let forecast: Double
    let lastUpdated: Date
    let profile: String
}

struct DemoDailyCost {
    let date: Date
    let amount: Double
    let services: [ServiceCost]
}