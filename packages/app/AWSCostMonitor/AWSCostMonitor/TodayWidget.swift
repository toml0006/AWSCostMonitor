import WidgetKit
import SwiftUI
import Foundation

// MARK: - Widget Timeline Provider
struct CostWidgetProvider: TimelineProvider {
    typealias Entry = CostWidgetEntry
    
    func placeholder(in context: Context) -> CostWidgetEntry {
        CostWidgetEntry(
            date: Date(),
            profileName: "Production",
            cost: Decimal(125.50),
            currency: "USD",
            budgetStatus: .normal,
            errorMessage: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CostWidgetEntry) -> Void) {
        let manager = AWSManager.shared
        
        if let costData = manager.costData.first {
            let budget = manager.getBudget(for: costData.profileName)
            let status = manager.calculateBudgetStatus(cost: costData.amount, budget: budget)
            
            let budgetStatus: WidgetBudgetStatus
            if status.isOverBudget {
                budgetStatus = .overBudget
            } else if status.isNearThreshold {
                budgetStatus = .nearThreshold
            } else {
                budgetStatus = .normal
            }
            
            let entry = CostWidgetEntry(
                date: Date(),
                profileName: costData.profileName,
                cost: costData.amount,
                currency: costData.currency,
                budgetStatus: budgetStatus,
                errorMessage: nil
            )
            completion(entry)
        } else {
            let entry = CostWidgetEntry(
                date: Date(),
                profileName: "No Profile",
                cost: 0,
                currency: "USD",
                budgetStatus: .normal,
                errorMessage: "No cost data available"
            )
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CostWidgetEntry>) -> Void) {
        let manager = AWSManager.shared
        var entries: [CostWidgetEntry] = []
        
        let currentDate = Date()
        
        // Create an entry for the current time
        if let costData = manager.costData.first {
            let budget = manager.getBudget(for: costData.profileName)
            let status = manager.calculateBudgetStatus(cost: costData.amount, budget: budget)
            
            let budgetStatus: WidgetBudgetStatus
            if status.isOverBudget {
                budgetStatus = .overBudget
            } else if status.isNearThreshold {
                budgetStatus = .nearThreshold
            } else {
                budgetStatus = .normal
            }
            
            let entry = CostWidgetEntry(
                date: currentDate,
                profileName: costData.profileName,
                cost: costData.amount,
                currency: costData.currency,
                budgetStatus: budgetStatus,
                errorMessage: nil
            )
            entries.append(entry)
        } else {
            let entry = CostWidgetEntry(
                date: currentDate,
                profileName: "No Profile",
                cost: 0,
                currency: "USD",
                budgetStatus: .normal,
                errorMessage: "No cost data available"
            )
            entries.append(entry)
        }
        
        // Refresh the widget in 15 minutes
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

// MARK: - Widget Entry
struct CostWidgetEntry: TimelineEntry {
    let date: Date
    let profileName: String
    let cost: Decimal
    let currency: String
    let budgetStatus: WidgetBudgetStatus
    let errorMessage: String?
}

enum WidgetBudgetStatus {
    case normal
    case nearThreshold
    case overBudget
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .nearThreshold: return .orange
        case .overBudget: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .normal: return "checkmark.circle.fill"
        case .nearThreshold: return "exclamationmark.circle.fill"
        case .overBudget: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Widget View
struct CostWidgetView: View {
    var entry: CostWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: CostWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                Spacer()
                Image(systemName: entry.budgetStatus.icon)
                    .foregroundColor(entry.budgetStatus.color)
                    .font(.caption)
            }
            
            if let errorMessage = entry.errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else {
                Text(entry.profileName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(formattedCost)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(entry.budgetStatus.color)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = entry.currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: entry.cost)) ?? "$0"
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: CostWidgetEntry
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("AWS Costs")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                if let errorMessage = entry.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text(entry.profileName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(formattedCost)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(entry.budgetStatus.color)
                }
                
                Spacer()
            }
            
            Spacer()
            
            VStack {
                Image(systemName: entry.budgetStatus.icon)
                    .foregroundColor(entry.budgetStatus.color)
                    .font(.title2)
                
                Text(statusText)
                    .font(.caption2)
                    .foregroundColor(entry.budgetStatus.color)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = entry.currency
        return formatter.string(from: NSDecimalNumber(decimal: entry.cost)) ?? "$0.00"
    }
    
    private var statusText: String {
        switch entry.budgetStatus {
        case .normal: return "On Track"
        case .nearThreshold: return "Near Limit"
        case .overBudget: return "Over Budget"
        }
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: CostWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("AWS Cost Monitor")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            if let errorMessage = entry.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } else {
                // Main content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Spending")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.profileName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text(formattedCost)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(entry.budgetStatus.color)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Image(systemName: entry.budgetStatus.icon)
                                .foregroundColor(entry.budgetStatus.color)
                                .font(.title)
                            
                            Text(statusText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(entry.budgetStatus.color)
                        }
                    }
                }
                
                // Additional info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Updated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(entry.date, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = entry.currency
        return formatter.string(from: NSDecimalNumber(decimal: entry.cost)) ?? "$0.00"
    }
    
    private var statusText: String {
        switch entry.budgetStatus {
        case .normal: return "On Track"
        case .nearThreshold: return "Near Limit"
        case .overBudget: return "Over Budget"
        }
    }
}

// MARK: - Widget Configuration
@available(macOS 11.0, *)
struct CostWidget: Widget {
    let kind: String = "CostWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CostWidgetProvider()) { entry in
            CostWidgetView(entry: entry)
        }
        .configurationDisplayName("AWS Cost Monitor")
        .description("Monitor your current AWS spending and budget status")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle
// Note: This would be @main in a separate Widget Extension target
@available(macOS 11.0, *)
struct AWSCostWidgetBundle: WidgetBundle {
    var body: some Widget {
        CostWidget()
    }
}