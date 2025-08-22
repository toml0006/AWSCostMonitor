//
//  CalendarView.swift
//  AWSCostMonitor
//
//  Calendar view showing daily AWS spending
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var awsManager: AWSManager
    let highlightedService: String?
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var showingDayDetail = false
    @State private var selectedDayData: DailyCost?
    @State private var selectedDayServices: [ServiceCost] = []
    @State private var hoveredDate: Date?
    
    init(highlightedService: String? = nil) {
        self.highlightedService = highlightedService
    }
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .help("Previous month")
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .help("Next month")
                .disabled(isNextMonthDisabled)
                
                Button(action: {
                    currentMonth = Date()
                }) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .help("Go to current month")
                .disabled(isCurrentMonth)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Profile selector
            if awsManager.profiles.count > 1 {
                HStack {
                    Text("Profile:")
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: Binding(
                        get: { awsManager.selectedProfile },
                        set: { newProfile in
                            awsManager.selectedProfile = newProfile
                            Task {
                                await awsManager.fetchCostForSelectedProfile()
                            }
                        }
                    )) {
                        ForEach(awsManager.profiles) { profile in
                            Text(profile.name).tag(profile as AWSProfile?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)
                    
                    Spacer()
                    
                    if let profile = awsManager.selectedProfile {
                        let budget = awsManager.getBudget(for: profile.name)
                        Text("Total: \(formatCurrency(monthTotal))")
                            .font(.headline)
                            .foregroundColor(budget.monthlyBudget.map { monthTotal > $0 } ?? false ? .red : .primary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
            }
            
            Divider()
            
            // Calendar grid
            ScrollView {
                VStack(spacing: 0) {
                    // Days of week header
                    HStack(spacing: 0) {
                        ForEach(weekdaySymbols, id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    // Calendar days grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 7), spacing: 1) {
                        ForEach(calendarDays, id: \.self) { date in
                            if let date = date {
                                DayCell(
                                    date: date,
                                    dailyCost: getDailyCost(for: date),
                                    isToday: calendar.isDateInToday(date),
                                    isHovered: hoveredDate == date,
                                    maxDailyCost: maxDailyCost
                                )
                                .onTapGesture {
                                    selectDay(date)
                                }
                                .onHover { isHovered in
                                    hoveredDate = isHovered ? date : nil
                                }
                            } else {
                                Color.clear
                                    .frame(height: 80)
                            }
                        }
                    }
                    .background(Color(NSColor.separatorColor))
                }
                .padding()
            }
            
            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 10, height: 10)
                    Text("Low spend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: 10, height: 10)
                    Text("Medium spend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 10, height: 10)
                    Text("High spend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Refresh") {
                    Task {
                        await awsManager.fetchCostForSelectedProfile(force: true)
                    }
                }
                .disabled(awsManager.isLoading)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingDayDetail) {
            DayDetailView(
                date: selectedDate,
                dailyCost: selectedDayData,
                services: selectedDayServices,
                currencyFormatter: currencyFormatter,
                apiCalls: getAPICallsForDay(selectedDate),
                highlightedService: highlightedService,
                onNavigateToDate: { newDate in
                    selectDay(newDate)
                }
            )
        }
        .onAppear {
            // Load data if needed
            if awsManager.selectedProfile != nil && awsManager.costData.isEmpty {
                Task {
                    await awsManager.fetchCostForSelectedProfile()
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var weekdaySymbols: [String] {
        calendar.shortWeekdaySymbols
    }
    
    private var calendarDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start) - 1
        let numberOfDays = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day! + 1
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for dayOffset in 0..<numberOfDays {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: monthInterval.start) {
                days.append(date)
            }
        }
        
        // Fill remaining cells to complete the grid
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private var monthTotal: Decimal {
        guard let profile = awsManager.selectedProfile,
              let dailyCosts = awsManager.dailyCostsByProfile[profile.name] else {
            return 0
        }
        
        let monthDates = calendarDays.compactMap { $0 }
        return dailyCosts
            .filter { cost in
                monthDates.contains { calendar.isDate($0, inSameDayAs: cost.date) }
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var maxDailyCost: Decimal {
        guard let profile = awsManager.selectedProfile,
              let dailyCosts = awsManager.dailyCostsByProfile[profile.name] else {
            return 1
        }
        
        return dailyCosts.map { $0.amount }.max() ?? 1
    }
    
    private var isCurrentMonth: Bool {
        calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month)
    }
    
    private var isNextMonthDisabled: Bool {
        // Can't navigate to future months
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            return nextMonth > Date()
        }
        return true
    }
    
    // MARK: - Helper Methods
    
    private func getDailyCost(for date: Date) -> DailyCost? {
        guard let profile = awsManager.selectedProfile,
              let dailyCosts = awsManager.dailyCostsByProfile[profile.name] else {
            return nil
        }
        
        return dailyCosts.first { cost in
            calendar.isDate(cost.date, inSameDayAs: date)
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        currencyFormatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
    
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth),
           newMonth <= Date() {
            currentMonth = newMonth
        }
    }
    
    private func selectDay(_ date: Date) {
        selectedDate = date
        selectedDayData = getDailyCost(for: date)
        
        // Get service breakdown for the selected day
        if let profile = awsManager.selectedProfile,
           let dailyServiceCosts = awsManager.dailyServiceCostsByProfile[profile.name] {
            
            let dayServices = dailyServiceCosts
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(into: [String: Decimal]()) { result, cost in
                    result[cost.serviceName, default: 0] += cost.amount
                }
            
            selectedDayServices = dayServices.map { ServiceCost(serviceName: $0.key, amount: $0.value, currency: "USD") }
                .sorted()
        } else {
            selectedDayServices = []
        }
        
        showingDayDetail = true
    }
    
    private func getAPICallCount(for date: Date) -> Int {
        guard let profile = awsManager.selectedProfile else { return 0 }
        
        return awsManager.apiRequestRecords.filter { record in
            record.profileName == profile.name &&
            calendar.isDate(record.timestamp, inSameDayAs: date) &&
            record.endpoint.contains("GetCostAndUsage")
        }.count
    }
    
    private func getAPICallsForDay(_ date: Date) -> [APIRequestRecord] {
        guard let profile = awsManager.selectedProfile else { return [] }
        
        return awsManager.apiRequestRecords.filter { record in
            record.profileName == profile.name &&
            calendar.isDate(record.timestamp, inSameDayAs: date) &&
            record.endpoint.contains("GetCostAndUsage")
        }.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Day Cell Component

struct DayCell: View {
    let date: Date
    let dailyCost: DailyCost?
    let isToday: Bool
    let isHovered: Bool
    let maxDailyCost: Decimal
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: isToday ? 2 : 1)
                )
            
            VStack(spacing: 4) {
                Text(dayFormatter.string(from: date))
                    .font(.system(size: 14, weight: isToday ? .bold : .medium))
                    .foregroundColor(isToday ? .accentColor : .primary)
                
                if let cost = dailyCost {
                    Text(formatAmount(cost.amount))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(costColor(cost.amount))
                    
                    // Visual indicator bar
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(costColor(cost.amount).opacity(0.7))
                            .frame(width: geometry.size.width * CGFloat(truncating: NSDecimalNumber(decimal: cost.amount / maxDailyCost)), height: 4)
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 4)
                } else if date <= Date() {
                    Text("$0")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                } else {
                    Text("-")
                        .font(.system(size: 12))
                        .foregroundColor(Color.secondary.opacity(0.5))
                }
            }
            .padding(8)
        }
        .frame(height: 80)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
    
    private var backgroundColor: Color {
        if isHovered {
            return Color.accentColor.opacity(0.1)
        } else if let cost = dailyCost {
            return costBackgroundColor(cost.amount)
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }
    
    private var borderColor: Color {
        if isToday {
            return .accentColor
        } else if isHovered {
            return Color.accentColor.opacity(0.5)
        } else {
            return Color(NSColor.separatorColor)
        }
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        if amount < 1 {
            return String(format: "$%.2f", NSDecimalNumber(decimal: amount).doubleValue)
        } else if amount < 100 {
            return String(format: "$%.1f", NSDecimalNumber(decimal: amount).doubleValue)
        } else {
            return currencyFormatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0"
        }
    }
    
    private func costColor(_ amount: Decimal) -> Color {
        let percentage = NSDecimalNumber(decimal: amount / maxDailyCost).doubleValue
        if percentage > 0.75 {
            return .red
        } else if percentage > 0.5 {
            return .orange
        } else if percentage > 0.25 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func costBackgroundColor(_ amount: Decimal) -> Color {
        let percentage = NSDecimalNumber(decimal: amount / maxDailyCost).doubleValue
        if percentage > 0.75 {
            return Color.red.opacity(0.1)
        } else if percentage > 0.5 {
            return Color.orange.opacity(0.1)
        } else if percentage > 0.25 {
            return Color.yellow.opacity(0.1)
        } else {
            return Color.green.opacity(0.1)
        }
    }
}

// MARK: - API Call Badge Component

struct APICallBadge: View {
    let count: Int
    let isHovered: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.systemBlue).opacity(isHovered ? 0.9 : 0.8))
                .frame(width: 16, height: 16)
            
            Text("\(count)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
        }
        .shadow(color: .black.opacity(0.2), radius: 0.5, x: 0, y: 0.5)
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isHovered)
        .help("\(count) API call\(count == 1 ? "" : "s") made by this app")
    }
}

