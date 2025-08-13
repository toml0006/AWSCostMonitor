//
//  RealHistogramView.swift
//  AWSCostMonitor
//
//  Daily cost histogram view
//

import SwiftUI
import Charts
import AppKit

struct RealHistogramView: View {
    let dailyServiceCosts: [DailyServiceCost]
    let serviceName: String
    @EnvironmentObject var awsManager: AWSManager
    @Binding var selectedDayDetail: DayDetailData?
    @State private var hoveredIndex: Int? = nil
    @State private var pressedIndex: Int? = nil
    
    private func buildFullData() -> [DailyServiceCost] {
        let last14Days = getLast14DaysData()
        let calendar = Calendar.current
        let today = Date()
        var allDays: [DailyServiceCost] = []
        for i in (0..<14).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                if let existingDay = last14Days.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                    allDays.append(existingDay)
                } else {
                    allDays.append(DailyServiceCost(date: date, serviceName: serviceName, amount: 0, currency: "USD"))
                }
            }
        }
        return allDays
    }
    
    var body: some View {
        let allDays = buildFullData()
        let amounts = allDays.map { NSDecimalNumber(decimal: $0.amount).doubleValue }
        let maxAmount = amounts.max() ?? 1.0
        
        // Debug: Log the actual count
        let _ = print("🔵 RealHistogramView: FORCED to \(allDays.count) bars for service: \(serviceName)")
        
        // Get last month's average daily spend for comparison
        let lastMonthAvg = getLastMonthDailyAverage()
        
        ZStack(alignment: .topLeading) {
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 1) {  // Minimal spacing between bars
                    ForEach(Array(amounts.enumerated()), id: \.offset) { index, amount in
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(barColor(amount: amount, lastMonthAvg: lastMonthAvg, isPressed: pressedIndex == index, isHovered: hoveredIndex == index))
                                .frame(width: max(10, (geometry.size.width - CGFloat(13 * 1)) / 14), height: max(2, CGFloat(amount / maxAmount) * 30))  // Use almost all available width
                                .cornerRadius(1)
                                .overlay(
                                    Rectangle()
                                        .stroke(
                                            hoveredIndex == index ? Color.white.opacity(0.6) : Color.clear,
                                            lineWidth: hoveredIndex == index ? 1 : 0
                                        )
                                        .cornerRadius(1)
                                )
                                .scaleEffect(
                                    pressedIndex == index ? 1.1 : (hoveredIndex == index ? 1.05 : 1.0)
                                )
                                .animation(.easeInOut(duration: 0.15), value: hoveredIndex)
                                .animation(.easeInOut(duration: 0.1), value: pressedIndex)
                        }
                        .frame(height: 32)
                        // Full column highlight on hover/press
                        .background(
                            Rectangle()
                                .fill(
                                    pressedIndex == index ? Color.blue.opacity(0.3) :
                                    (hoveredIndex == index ? Color.blue.opacity(0.15) : Color.clear)
                                )
                                .cornerRadius(2)
                        )
                        .scaleEffect(pressedIndex == index ? 1.02 : (hoveredIndex == index ? 1.01 : 1.0))
                        .shadow(color: pressedIndex == index ? Color.blue.opacity(0.4) : Color.clear, radius: pressedIndex == index ? 2 : 0)
                        .animation(.easeInOut(duration: 0.1), value: pressedIndex)
                        .animation(.easeInOut(duration: 0.15), value: hoveredIndex)
                        .contentShape(Rectangle())
                        .background(Color.clear)
                        .overlay(
                            Button(action: {
                                // Handle the tap action with immediate response
                                if index < allDays.count {
                                    let day = allDays[index]
                                    print("Histogram bar tapped for service: \(serviceName), day: \(day.date)")
                                    
                                    // Visual feedback
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        pressedIndex = index
                                    }
                                    
                                    // Create the day detail data
                                    selectedDayDetail = DayDetailData(
                                        date: day.date,
                                        dailyCost: DailyCost(
                                            date: day.date,
                                            amount: getTotalCostForDay(day.date),
                                            currency: day.currency
                                        ),
                                        services: getAllServicesForDay(day.date),
                                        currencyFormatter: currencyFormatter,
                                        apiCalls: [],
                                        highlightedService: serviceName
                                    )
                                    
                                    // Reset pressed state
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        pressedIndex = nil
                                    }
                                }
                            }) {
                                Color.clear
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        )
                        .onHover { isHovering in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hoveredIndex = isHovering ? index : nil
                            }
                            
                            // Direct cursor change
                            if isHovering {
                                NSCursor.pointingHand.set()
                            } else {
                                NSCursor.arrow.set()
                            }
                        }
                    }
                }
            }
            .frame(height: 32)
            
            // Tooltip overlay positioned above the hovered bar
            GeometryReader { geometry in
                if let hoveredIndex = hoveredIndex, hoveredIndex < allDays.count {
                    let day = allDays[hoveredIndex]
                    let barWidth = max(10, (geometry.size.width - CGFloat(13 * 1)) / 14)
                    let xPosition = CGFloat(hoveredIndex) * (barWidth + 1) + barWidth / 2 - 30
                    
                    Text("\(day.date, formatter: dateFormatter): \(awsManager.formatCurrency(day.amount))")
                        .font(.system(size: 9))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                        .shadow(radius: 2)
                        .offset(x: xPosition, y: -8)  // Position above the hovered bar
                        .zIndex(1)
                }
            }
            .frame(height: 32)
        }
        .frame(minWidth: 220, idealWidth: 250, maxWidth: 280)  // Give histogram more space
        .padding(.vertical, 2)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    private func barColor(amount: Double, lastMonthAvg: Double, isPressed: Bool = false, isHovered: Bool = false) -> Color {
        if amount == 0 {
            return Color.gray.opacity(isPressed ? 0.8 : (isHovered ? 0.4 : 0.2))
        }
        
        var baseColor: Color
        
        // Compare to last month's daily average
        if lastMonthAvg > 0 {
            let percentDiff = ((amount - lastMonthAvg) / lastMonthAvg) * 100
            if percentDiff > 10 {
                // More than 10% above last month's average - red
                baseColor = Color.red
            } else if percentDiff < -10 {
                // More than 10% below last month's average - green
                baseColor = Color.green
            } else {
                // Within normal range - blue
                baseColor = Color.blue
            }
        } else {
            // Within normal range - blue
            baseColor = Color.blue
        }
        
        if isPressed {
            // Make pressed bars brighter and more opaque
            return baseColor.opacity(1.0)
        } else if isHovered {
            // Make hovered bars brighter
            return baseColor.opacity(0.9)
        } else {
            return baseColor.opacity(0.8)
        }
    }
    
    private func getLastMonthDailyAverage() -> Double {
        // Get the profile name from the current cost data
        guard let cost = awsManager.costData.first,
              let lastMonthData = awsManager.lastMonthServiceCosts[cost.profileName] else {
            return 0
        }
        
        // Find the same service in last month's data
        let lastMonthService = lastMonthData.first { $0.serviceName == serviceName }
        guard let serviceAmount = lastMonthService?.amount else {
            return 0
        }
        
        // Calculate daily average (assuming 30 days in a month)
        return NSDecimalNumber(decimal: serviceAmount).doubleValue / 30.0
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
    
    private func getTotalCostForDay(_ date: Date) -> Decimal {
        let calendar = Calendar.current
        guard let profileName = awsManager.selectedProfile?.name,
              let dailyServiceCosts = awsManager.dailyServiceCostsByProfile[profileName] else {
            return 0
        }
        
        return dailyServiceCosts
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func getAllServicesForDay(_ date: Date) -> [ServiceCost] {
        let calendar = Calendar.current
        guard let profileName = awsManager.selectedProfile?.name,
              let dailyServiceCosts = awsManager.dailyServiceCostsByProfile[profileName] else {
            return []
        }
        
        let dayServices = dailyServiceCosts
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .reduce(into: [String: Decimal]()) { result, cost in
                result[cost.serviceName, default: 0] += cost.amount
            }
        
        return dayServices.map { ServiceCost(serviceName: $0.key, amount: $0.value, currency: "USD") }
            .sorted()
    }
}

// MARK: - SwiftUI View

