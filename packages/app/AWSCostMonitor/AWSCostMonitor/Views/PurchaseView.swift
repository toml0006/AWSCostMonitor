//
//  PurchaseView.swift
//  AWSCostMonitor
//
//  In-app purchase upgrade flow
//

import SwiftUI
import AppKit

struct PurchaseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isProcessing = false
    @State private var purchaseComplete = false
    @State private var selectedPlan: PurchasePlan = .lifetime
    
    enum PurchasePlan: String, CaseIterable {
        case lifetime = "lifetime"
        case annual = "annual"
        
        var title: String {
            switch self {
            case .lifetime: return "Lifetime"
            case .annual: return "Annual"
            }
        }
        
        var price: String {
            switch self {
            case .lifetime: return "$29"
            case .annual: return "$12/year"
            }
        }
        
        var savings: String? {
            switch self {
            case .lifetime: return "Best Value - Pay Once"
            case .annual: return "Save 58%"
            }
        }
        
        var description: String {
            switch self {
            case .lifetime: return "One-time purchase\nLifetime updates\nAll future features"
            case .annual: return "Billed yearly\nCancel anytime\nAll Pro features"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Upgrade to Pro")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Unlock all features and support development")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 30)
            .padding(.bottom, 20)
            
            // Features List
            VStack(alignment: .leading, spacing: 12) {
                PurchaseFeatureRow(icon: "person.3.fill", text: "Unlimited AWS profiles", isIncluded: true)
                PurchaseFeatureRow(icon: "arrow.triangle.2.circlepath", text: "Smart auto-refresh", isIncluded: true)
                PurchaseFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Cost forecasting & trends", isIncluded: true)
                PurchaseFeatureRow(icon: "calendar", text: "Historical data & comparisons", isIncluded: true)
                PurchaseFeatureRow(icon: "chart.pie.fill", text: "Service cost breakdown", isIncluded: true)
                PurchaseFeatureRow(icon: "square.and.arrow.up", text: "Export to CSV/JSON", isIncluded: true)
                PurchaseFeatureRow(icon: "keyboard", text: "Keyboard shortcuts", isIncluded: true)
                PurchaseFeatureRow(icon: "paintbrush.fill", text: "Custom display formats", isIncluded: true)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Pricing Plans
            VStack(spacing: 12) {
                ForEach(PurchasePlan.allCases, id: \.self) { plan in
                    PlanButton(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        action: { selectedPlan = plan }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: handlePurchase) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "lock.open.fill")
                        }
                        Text(isProcessing ? "Processing..." : "Unlock Pro Features")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
                
                Button("Maybe Later") {
                    dismiss()
                }
                .buttonStyle(.link)
                
                // Terms
                Text("By purchasing, you agree to our [Terms](https://example.com/terms) and [Privacy Policy](https://example.com/privacy)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 720)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $purchaseComplete) {
            SuccessView()
        }
    }
    
    private func handlePurchase() {
        isProcessing = true
        
        // Simulate purchase processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            purchaseComplete = true
        }
    }
}

struct PurchaseFeatureRow: View {
    let icon: String
    let text: String
    let isIncluded: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isIncluded ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isIncluded ? .green : .red)
                .font(.system(size: 16))
            
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 13))
            
            Spacer()
        }
    }
}

struct PlanButton: View {
    let plan: PurchaseView.PurchasePlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.title)
                            .font(.system(size: 14, weight: .semibold))
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(plan.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(plan.price)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isSelected ? .blue : .primary)
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.blue.opacity(0.05) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct SuccessView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("Welcome to Pro!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Thank you for your purchase. All Pro features have been unlocked.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Start Using Pro") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
        .frame(width: 400, height: 300)
    }
}

// Window controller for showing purchase view
class PurchaseWindowController: NSWindowController {
    static func showPurchaseWindow() {
        let purchaseView = PurchaseView()
        let hostingController = NSHostingController(rootView: purchaseView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Upgrade to AWSCostMonitor Pro"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        window.level = .floating
        
        let controller = PurchaseWindowController(window: window)
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// Preview
struct PurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseView()
    }
}