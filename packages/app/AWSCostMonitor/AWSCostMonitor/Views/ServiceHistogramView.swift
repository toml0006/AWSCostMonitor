//
//  ServiceHistogramView.swift
//  AWSCostMonitor
//
//  Service-specific cost histogram view
//

import SwiftUI
import Charts

struct ServiceHistogramView: View {
    let dailyServiceCosts: [DailyServiceCost]
    let serviceName: String
    @Environment(\.theme) var theme
    
    var body: some View {
        let last14Days = getLast14DaysData()
        
        return VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 1) {
                // Enhanced text-based histogram with better visuals
                let histogramText = generateAdvancedHistogram(last14Days)
                
                HStack(spacing: 0) {
                    Text(histogramText.bars)
                        .font(.system(size: 10 * theme.spacingMultiplier, design: .monospaced))
                        .foregroundColor(theme.accentColor)
                    
                    Text(" ")
                        .font(.system(size: 6))
                    
                    Text(histogramText.trend)
                        .font(.system(size: 8 * theme.spacingMultiplier))
                        .foregroundColor(histogramText.trendColor)
                }
                
                Spacer()
                
                Text("14d")
                    .themeFont(theme, size: .small, weight: .secondary)
                    .foregroundColor(theme.secondaryColor)
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
            return (emptyBars, "—", theme.secondaryColor) // All zero bars with neutral trend
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
                trendColor = theme.errorColor
            } else if lastWeek < firstWeek * 0.8 { // 20% decrease
                trend = "↘"
                trendColor = theme.successColor
            } else {
                trend = "→"
                trendColor = theme.secondaryColor
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
                trendColor = theme.errorColor
            } else if lastHalf < firstHalf * 0.8 { // 20% decrease
                trend = "↘"
                trendColor = theme.successColor
            } else {
                trend = "→"
                trendColor = theme.secondaryColor
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

