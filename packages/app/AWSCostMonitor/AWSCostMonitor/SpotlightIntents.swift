import AppIntents
import Foundation
import SwiftUI

// MARK: - App Intent for Cost Checking
@available(macOS 13.0, *)
struct CheckAWSCostIntent: AppIntent {
    static var title: LocalizedStringResource = "Check AWS Cost"
    
    static var description = IntentDescription("Check your current AWS spending")
    
    static var searchKeywords: [String] = ["aws", "cost", "bill", "spending", "cloud"]
    
    @Parameter(title: "Profile Name", description: "AWS profile to check")
    var profileName: String?
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let manager = AWSManager.shared
        
        // If no profile specified, use the selected one
        let targetProfile: String
        if let profileName = profileName {
            targetProfile = profileName
        } else if let selectedProfile = manager.selectedProfile {
            targetProfile = selectedProfile.name
        } else {
            return .result(
                dialog: "No AWS profile selected. Please open AWSCostMonitor to configure profiles.",
                view: CostDisplaySnippet(
                    profileName: "No Profile",
                    amount: "N/A",
                    currency: "USD",
                    status: "error"
                )
            )
        }
        
        // Get cost data for the profile
        if let costData = manager.costData.first(where: { $0.profileName == targetProfile }) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = costData.currency
            
            let formattedAmount = formatter.string(from: NSDecimalNumber(decimal: costData.amount)) ?? "$0.00"
            
            // Check budget status
            let budget = manager.getBudget(for: targetProfile)
            let budgetStatus = manager.calculateBudgetStatus(cost: costData.amount, budget: budget)
            
            let statusMessage: String
            let status: String
            if budgetStatus.isOverBudget {
                statusMessage = "Over budget by \(Int((budgetStatus.percentage - 1.0) * 100))%"
                status = "over_budget"
            } else if budgetStatus.isNearThreshold {
                statusMessage = "At \(Int(budgetStatus.percentage * 100))% of budget"
                status = "near_threshold"
            } else {
                statusMessage = "Within budget (\(Int(budgetStatus.percentage * 100))%)"
                status = "normal"
            }
            
            return .result(
                dialog: "\(targetProfile): \(formattedAmount) - \(statusMessage)",
                view: CostDisplaySnippet(
                    profileName: targetProfile,
                    amount: formattedAmount,
                    currency: costData.currency,
                    status: status
                )
            )
        } else {
            return .result(
                dialog: "No cost data available for \(targetProfile). Try refreshing in AWSCostMonitor.",
                view: CostDisplaySnippet(
                    profileName: targetProfile,
                    amount: "No Data",
                    currency: "USD",
                    status: "no_data"
                )
            )
        }
    }
}

// MARK: - Snippet View for Spotlight Results
@available(macOS 13.0, *)
struct CostDisplaySnippet: View {
    let profileName: String
    let amount: String
    let currency: String
    let status: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForStatus)
                    .foregroundColor(colorForStatus)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(profileName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(amount)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(colorForStatus)
                }
                
                Spacer()
            }
            
            if status != "no_data" && status != "error" {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .frame(maxWidth: 300)
    }
    
    private var iconForStatus: String {
        switch status {
        case "over_budget":
            return "exclamationmark.triangle.fill"
        case "near_threshold":
            return "exclamationmark.circle.fill"
        case "normal":
            return "checkmark.circle.fill"
        case "no_data":
            return "questionmark.circle.fill"
        case "error":
            return "xmark.circle.fill"
        default:
            return "dollarsign.circle.fill"
        }
    }
    
    private var colorForStatus: Color {
        switch status {
        case "over_budget":
            return .red
        case "near_threshold":
            return .orange
        case "normal":
            return .green
        case "no_data":
            return .secondary
        case "error":
            return .red
        default:
            return .blue
        }
    }
    
    private var statusText: String {
        switch status {
        case "over_budget":
            return "Budget exceeded - review spending"
        case "near_threshold":
            return "Approaching budget limit"
        case "normal":
            return "Spending within budget"
        default:
            return ""
        }
    }
}

// MARK: - Intent for Getting All Profiles Costs
@available(macOS 13.0, *)
struct GetAllProfilesCostIntent: AppIntent {
    static var title: LocalizedStringResource = "Get All AWS Costs"
    
    static var description = IntentDescription("Check costs for all AWS profiles")
    
    static var searchKeywords: [String] = ["aws", "all", "profiles", "total", "costs"]
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = AWSManager.shared
        
        guard !manager.costData.isEmpty else {
            return .result(dialog: "No cost data available. Please refresh data in AWSCostMonitor.")
        }
        
        let totalCost = manager.costData.reduce(Decimal(0)) { $0 + $1.amount }
        let profileCount = manager.costData.count
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = manager.costData.first?.currency ?? "USD"
        
        let formattedTotal = formatter.string(from: NSDecimalNumber(decimal: totalCost)) ?? "$0.00"
        
        let profileSummary = manager.costData.map { costData in
            let amount = formatter.string(from: NSDecimalNumber(decimal: costData.amount)) ?? "$0.00"
            return "\(costData.profileName): \(amount)"
        }.joined(separator: ", ")
        
        return .result(
            dialog: "Total across \(profileCount) profile\(profileCount == 1 ? "" : "s"): \(formattedTotal). Breakdown: \(profileSummary)"
        )
    }
}

// MARK: - App Shortcuts Provider
@available(macOS 13.0, *)
struct AWSCostShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckAWSCostIntent(),
            phrases: [
                "Check my AWS cost in ${applicationName}",
                "What's my AWS bill in ${applicationName}",
                "Show AWS spending with ${applicationName}",
                "Get AWS cost from ${applicationName}"
            ],
            shortTitle: "Check AWS Cost",
            systemImageName: "dollarsign.circle"
        )
        
        AppShortcut(
            intent: GetAllProfilesCostIntent(),
            phrases: [
                "Get all AWS costs in ${applicationName}",
                "Show total AWS spending with ${applicationName}",
                "All profile costs from ${applicationName}"
            ],
            shortTitle: "All AWS Costs",
            systemImageName: "list.bullet.circle"
        )
    }
}