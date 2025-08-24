//
//  DayDetailView.swift
//  AWSCostMonitor
//
//  Day detail view for calendar showing service breakdown
//

import SwiftUI

struct DayDetailView: View {
    let date: Date
    let dailyCost: DailyCost?
    let services: [ServiceCost]
    let currencyFormatter: NumberFormatter
    let apiCalls: [APIRequestRecord]
    let highlightedService: String?
    let onNavigateToDate: ((Date) -> Void)?
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @State private var hoveredService: String? = nil
    @State private var showAllServices = false
    @State private var showAPIDetails = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    // Group small services into "Other"
    private var processedServices: [(name: String, amount: Decimal, isGrouped: Bool)] {
        let threshold: Decimal = 0.10 // Group services less than $0.10
        let sortedServices = services.sorted()
        
        var result: [(String, Decimal, Bool)] = []
        var otherTotal: Decimal = 0
        var otherCount = 0
        
        for service in sortedServices {
            if service.amount >= threshold || sortedServices.count <= 5 {
                result.append((service.serviceName, service.amount, false))
            } else {
                otherTotal += service.amount
                otherCount += 1
            }
        }
        
        if otherTotal > 0 {
            result.append(("Other Services (\(otherCount))", otherTotal, true))
        }
        
        return result
    }
    
    private var totalAmount: Decimal {
        services.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            
            if !services.isEmpty {
                GeometryReader { geometry in
                    HStack(spacing: 20) {
                        donutChartView
                            .frame(width: geometry.size.width * 0.45)
                        
                        serviceListView
                            .frame(width: geometry.size.width * 0.45)
                    }
                    .padding()
                }
            } else {
                noDataView
            }
            
            // API Calls Section
            Divider()
            apiCallsSection
            
            // Footer with Close button
            Divider()
            footerView
        }
        .frame(width: 700, height: showAPIDetails ? 650 : 500)
        .onExitCommand {
            dismiss()
        }
    }
    
    private var headerView: some View {
        HStack {
            // Navigation buttons on the left, matching calendar view style
            Button(action: navigateToPreviousDay) {
                Image(systemName: "chevron.left")
                    .font(.system(size: theme.largeFontSize))
                    .foregroundColor(theme.accentColor)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.leftArrow, modifiers: [])
            .help("Previous day")
            
            VStack(alignment: .leading, spacing: 4) {
                Text(dateFormatter.string(from: date))
                    .themeFont(theme, size: .large, weight: .primary)
                    .foregroundColor(theme.textColor)
                
                if let cost = dailyCost {
                    Text("Total: \(currencyFormatter.string(from: NSDecimalNumber(decimal: cost.amount)) ?? "$0.00")")
                        .themeFont(theme, size: .regular, weight: .secondary)
                        .foregroundColor(theme.secondaryColor)
                } else {
                    Text("No data available")
                        .themeFont(theme, size: .regular, weight: .secondary)
                        .foregroundColor(theme.secondaryColor)
                }
            }
            .themePadding(theme, .horizontal, 8)
            
            Spacer()
            
            // Calendar button to jump to today
            Button(action: navigateToToday) {
                Image(systemName: "calendar")
                    .font(.system(size: theme.largeFontSize))
                    .foregroundColor(isViewingToday ? theme.secondaryColor : theme.accentColor)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("t", modifiers: [.command])
            .help("Go to today")
            .disabled(isViewingToday)
            
            // Forward navigation button
            Button(action: navigateToNextDay) {
                Image(systemName: "chevron.right")
                    .font(.system(size: theme.largeFontSize))
                    .foregroundColor(isNextDayInFuture ? theme.secondaryColor : theme.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(isNextDayInFuture)
            .keyboardShortcut(.rightArrow, modifiers: [])
            .help(isNextDayInFuture ? "Cannot navigate to future dates" : "Next day")
        }
        .themePadding(theme, .all, 12)
        .background(theme.backgroundColor)
    }
    
    private var donutChartView: some View {
        VStack {
            Text("Cost Distribution")
                .themeFont(theme, size: .large, weight: .primary)
                .foregroundColor(theme.textColor)
                .padding(.bottom, 10)
            
            ZStack {
                // Donut chart using custom drawing
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = min(size.width, size.height) / 2 - 10
                    let innerRadius = radius * 0.618 // Golden ratio for inner radius
                    
                    var currentAngle: Double = -90 // Start at top
                    
                    for (_, service) in processedServices.enumerated() {
                        let percentage = totalAmount > 0 ? Double(truncating: NSDecimalNumber(decimal: service.amount / totalAmount)) : 0
                        let angleSpan = percentage * 360
                        
                        let startAngle = Angle.degrees(currentAngle)
                        let endAngle = Angle.degrees(currentAngle + angleSpan)
                        
                        // Create path for donut segment
                        var path = Path()
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: false
                        )
                        path.addArc(
                            center: center,
                            radius: innerRadius,
                            startAngle: endAngle,
                            endAngle: startAngle,
                            clockwise: true
                        )
                        path.closeSubpath()
                        
                        // Fill the segment
                        let serviceColor = colorForService(service.name)
                        let opacity = (hoveredService == nil || hoveredService == service.name) ? 1.0 : 0.3
                        
                        context.fill(path, with: .color(serviceColor.opacity(opacity)))
                        
                        // Add subtle stroke
                        context.stroke(path, with: .color(theme.secondaryColor.opacity(0.2)), lineWidth: 1)
                        
                        currentAngle += angleSpan
                    }
                }
                .frame(width: 250, height: 250)
                
                // Center text showing hovered service or total
                centerTextView
            }
        }
    }
    
    private var centerTextView: some View {
        VStack(spacing: 4) {
            if let hovered = hoveredService,
               let service = processedServices.first(where: { $0.name == hovered }) {
                // Show hovered service details
                Text(service.name)
                    .themeFont(theme, size: .small, weight: .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.textColor)
                
                Text(currencyFormatter.string(from: NSDecimalNumber(decimal: service.amount)) ?? "$0")
                    .themeFont(theme, size: .large, weight: .primary)
                    .foregroundColor(theme.primaryColor)
                
                let percentage = totalAmount > 0 ? (service.amount / totalAmount) * 100 : 0
                Text("\(Int(truncating: NSDecimalNumber(decimal: percentage)))%")
                    .themeFont(theme, size: .small, weight: .secondary)
                    .foregroundColor(theme.secondaryColor)
            } else {
                // Show total when nothing is hovered
                Text("Total")
                    .themeFont(theme, size: .small, weight: .secondary)
                    .foregroundColor(theme.secondaryColor)
                
                Text(currencyFormatter.string(from: NSDecimalNumber(decimal: totalAmount)) ?? "$0")
                    .themeFont(theme, size: .large, weight: .primary)
                    .foregroundColor(theme.primaryColor)
                
                Text("All Services")
                    .themeFont(theme, size: .small, weight: .secondary)
                    .foregroundColor(theme.secondaryColor)
            }
        }
        .frame(width: 140, height: 140)
        .background(theme.backgroundColor)
        .clipShape(Circle())
    }
    
    private var serviceListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Services")
                .themeFont(theme, size: .large, weight: .primary)
                .foregroundColor(theme.textColor)
                .padding(.bottom, 4)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(displayedServices) { service in
                        serviceRowView(for: service)
                    }
                    
                    toggleButton
                }
                .themePadding(theme, .trailing, 8)
            }
            .frame(maxHeight: 350)
        }
    }
    
    private var displayedServices: [ServiceCost] {
        if showAllServices {
            return services.sorted()
        } else {
            return processedServices.map { 
                ServiceCost(serviceName: $0.name, amount: $0.amount, currency: "USD") 
            }
        }
    }
    
    private func serviceRowView(for service: ServiceCost) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(colorForService(service.serviceName))
                .frame(width: 8, height: 8)
            
            Text(service.serviceName)
                .themeFont(theme, size: .small, weight: .secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(theme.textColor)
            
            Text(currencyFormatter.string(from: NSDecimalNumber(decimal: service.amount)) ?? "$0")
                .themeFont(theme, size: .small, weight: .primary)
                .foregroundColor(service.amount > 10 ? theme.errorColor : (service.amount > 1 ? theme.warningColor : theme.textColor))
        }
        .themePadding(theme, .vertical, 4)
        .themePadding(theme, .horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    highlightedService == service.serviceName ? theme.accentColor.opacity(0.2) :
                    hoveredService == service.serviceName ? theme.accentColor.opacity(0.1) : Color.clear
                )
        )
        .onHover { isHovered in
            hoveredService = isHovered ? service.serviceName : nil
        }
    }
    
    @ViewBuilder
    private var toggleButton: some View {
        if processedServices.contains(where: { $0.isGrouped }) {
            if !showAllServices {
                Button(action: { showAllServices = true }) {
                    HStack {
                        Image(systemName: "chevron.down.circle")
                        Text("Show all services")
                            .themeFont(theme, size: .small, weight: .secondary)
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .padding(.top, 4)
            } else {
                Button(action: { showAllServices = false }) {
                    HStack {
                        Image(systemName: "chevron.up.circle")
                        Text("Show less")
                            .themeFont(theme, size: .small, weight: .secondary)
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .padding(.top, 4)
            }
        }
    }
    
    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No service breakdown available for this day")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Service-level data may not be available for all dates")
                .font(.caption)
                .foregroundColor(Color.secondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func colorForService(_ serviceName: String) -> Color {
        // Use theme chart colors for services
        let serviceNames = processedServices.map { $0.name }
        if let index = serviceNames.firstIndex(of: serviceName) {
            return theme.chartColor(for: index)
        }
        
        // Generate a consistent color based on the service name
        let hash = serviceName.hashValue
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
    
    // MARK: - API Calls Section
    
    private var apiCallsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { withAnimation(.easeInOut(duration: 0.3)) { showAPIDetails.toggle() } }) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(Color(.systemBlue))
                    
                    Text("App API Calls")
                        .font(.headline)
                    
                    Text("(\(apiCalls.count) call\(apiCalls.count == 1 ? "" : "s") today)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: showAPIDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .themeFont(theme, size: .small, weight: .secondary)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(Color(.systemBlue).opacity(0.05))
            
            // Expandable content
            if showAPIDetails {
                apiCallsDetailView
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
            }
        }
    }
    
    private var apiCallsDetailView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Info banner
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(Color(.systemBlue))
                    .font(.caption)
                
                Text("These are API calls made by this AWSCostMonitor app only, not your total AWS account API usage.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            if apiCalls.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "network.slash")
                            .font(.title2)
                            .foregroundColor(Color(.systemBlue).opacity(0.5))
                        Text("No API calls recorded for this day")
                            .themeFont(theme, size: .small, weight: .secondary)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(apiCalls) { call in
                            apiCallRow(for: call)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 120)
                
                // Footer info
                HStack(spacing: 16) {
                    Label("Rate Limit: 1 call/minute", systemImage: "speedometer")
                        .themeFont(theme, size: .small, weight: .secondary)
                        .foregroundColor(.secondary)
                    
                    Label("Est. cost: ~$\(String(format: "%.3f", Double(apiCalls.count) * 0.01))", systemImage: "dollarsign.circle")
                        .themeFont(theme, size: .small, weight: .secondary)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemBlue).opacity(0.02))
    }
    
    private func apiCallRow(for call: APIRequestRecord) -> some View {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        return HStack(spacing: 12) {
            Circle()
                .fill(call.success ? Color.green : Color.red)
                .frame(width: 6, height: 6)
            
            Text(timeFormatter.string(from: call.timestamp))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 60, alignment: .leading)
            
            Image(systemName: "network")
                .font(.caption)
                .foregroundColor(Color(.systemBlue))
            
            Text("Cost Explorer - \(call.endpoint.replacingOccurrences(of: "GetCostAndUsage-", with: ""))")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Spacer()
            
            if call.duration > 0 {
                Text("\(String(format: "%.1fs", call.duration))")
                    .font(.system(size: 10))
                    .foregroundColor(Color(.systemBlue).opacity(0.7))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemBlue).opacity(0.03))
        )
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            Spacer()
            
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .themePadding(theme, .horizontal, 12)
            .themePadding(theme, .vertical, 12)
        }
        .background(theme.backgroundColor)
    }
    
    // MARK: - Navigation
    
    private var isNextDayInFuture: Bool {
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        let today = Calendar.current.startOfDay(for: Date())
        let nextDayStart = Calendar.current.startOfDay(for: nextDay)
        return nextDayStart > today
    }
    
    private var isViewingToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let viewingDay = Calendar.current.startOfDay(for: date)
        return viewingDay == today
    }
    
    private func navigateToPreviousDay() {
        let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        onNavigateToDate?(previousDay)
    }
    
    private func navigateToNextDay() {
        guard !isNextDayInFuture else { return }
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        onNavigateToDate?(nextDay)
    }
    
    private func navigateToToday() {
        let today = Calendar.current.startOfDay(for: Date())
        onNavigateToDate?(today)
    }
}