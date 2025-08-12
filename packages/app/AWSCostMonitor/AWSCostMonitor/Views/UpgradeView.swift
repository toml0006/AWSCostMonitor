//
//  UpgradeView.swift
//  AWSCostMonitor
//
//  Pro upgrade and trial management interface
//  Only available in App Store builds
//

#if APPSTORE_BUILD
import SwiftUI

struct UpgradeView: View {
    @StateObject private var purchaseManager = PurchaseManager.shared
    @StateObject private var remoteConfig = RemoteConfig.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingFeatureComparison = false
    @State private var showingTrialInfo = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.yellow)
                        
                        Text("AWSCostMonitor Pro")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Unlock team features and advanced monitoring")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Current Status
                    currentStatusView
                    
                    // Feature List
                    premiumFeaturesView
                    
                    // Pricing & Purchase
                    purchaseSection
                    
                    // Trial Section
                    if purchaseManager.canStartTrial {
                        trialSection
                    }
                    
                    // Feature Comparison
                    Button(action: { showingFeatureComparison = true }) {
                        HStack {
                            Text("Compare Free vs Pro Features")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Upgrade to Pro")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingFeatureComparison) {
            FeatureComparisonView()
        }
        .sheet(isPresented: $showingTrialInfo) {
            TrialInfoView()
        }
        .task {
            await purchaseManager.loadProducts()
        }
    }
    
    // MARK: - Current Status View
    
    @ViewBuilder
    private var currentStatusView: some View {
        VStack(spacing: 12) {
            if purchaseManager.hasPremiumAccess {
                Label("Pro features unlocked", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.headline)
            } else if purchaseManager.isTrialActive {
                VStack(spacing: 4) {
                    Label("Trial Active", systemImage: "timer")
                        .foregroundColor(.blue)
                        .font(.headline)
                    
                    Text(purchaseManager.trialStatusDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Free Version")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Premium Features View
    
    @ViewBuilder
    private var premiumFeaturesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pro Features")
                .font(.headline)
            
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(PremiumFeature.allCases, id: \.self) { feature in
                    FeatureRow(
                        feature: feature,
                        isAvailable: purchaseManager.hasAccessToProFeatures
                    )
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Purchase Section
    
    @ViewBuilder
    private var purchaseSection: some View {
        if !purchaseManager.hasPremiumAccess {
            VStack(spacing: 16) {
                if purchaseManager.isLoading {
                    ProgressView("Loading...")
                        .frame(height: 44)
                } else {
                    Button(action: {
                        purchaseManager.purchasePro()
                    }) {
                        HStack {
                            Text("Upgrade to Pro")
                            Spacer()
                            Text(purchaseManager.proProductPrice)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button("Restore Purchases") {
                        purchaseManager.restorePurchases()
                    }
                    .foregroundColor(.secondary)
                }
                
                if let error = purchaseManager.purchaseError {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
    }
    
    // MARK: - Trial Section
    
    @ViewBuilder
    private var trialSection: some View {
        VStack(spacing: 12) {
            Text("Try Pro Free")
                .font(.headline)
            
            Text("Start your \(remoteConfig.trialDurationDays)-day free trial to experience all Pro features")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                purchaseManager.startTrial()
            }) {
                HStack {
                    Image(systemName: "gift")
                    Text("Start \(remoteConfig.trialDurationDays)-Day Free Trial")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Button("Learn More About Trial") {
                showingTrialInfo = true
            }
            .foregroundColor(.secondary)
            .font(.caption)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let feature: PremiumFeature
    let isAvailable: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isAvailable ? .green : .secondary)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Feature Comparison View

struct FeatureComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Feature Comparison")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Comparison Table
                    VStack(spacing: 0) {
                        // Header Row
                        HStack {
                            Text("Feature")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Free")
                                .font(.headline)
                                .frame(width: 60)
                            
                            Text("Pro")
                                .font(.headline)
                                .frame(width: 60)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        
                        Divider()
                        
                        // Feature Rows
                        comparisonRow("AWS Profiles", free: "1", pro: "Unlimited")
                        comparisonRow("Calendar View", free: "✓", pro: "✓")
                        comparisonRow("Smart Refresh", free: "✓", pro: "✓")
                        comparisonRow("Team Cache", free: "✗", pro: "✓")
                        comparisonRow("Advanced Forecasting", free: "✗", pro: "✓")
                        comparisonRow("Data Export", free: "✗", pro: "✓")
                        comparisonRow("Priority Support", free: "✗", pro: "✓")
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // Pricing
                    Text("One-time purchase • No subscription")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Compare Features")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func comparisonRow(_ feature: String, free: String, pro: String) -> some View {
        HStack {
            Text(feature)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(free)
                .frame(width: 60)
                .foregroundColor(free == "✓" ? .green : (free == "✗" ? .red : .primary))
            
            Text(pro)
                .frame(width: 60)
                .foregroundColor(pro == "✓" ? .green : (pro == "✗" ? .red : .primary))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        
        Divider()
    }
}

// MARK: - Trial Info View

struct TrialInfoView: View {
    @StateObject private var remoteConfig = RemoteConfig.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Free Trial Details")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        TrialDetailRow(
                            title: "Duration",
                            detail: "\(remoteConfig.trialDurationDays) days"
                        )
                        
                        TrialDetailRow(
                            title: "Full Access",
                            detail: "All Pro features included"
                        )
                        
                        TrialDetailRow(
                            title: "No Credit Card",
                            detail: "No payment required to start"
                        )
                        
                        TrialDetailRow(
                            title: "Auto-Cancel",
                            detail: "Trial ends automatically"
                        )
                        
                        TrialDetailRow(
                            title: "Upgrade Anytime",
                            detail: "Purchase Pro during or after trial"
                        )
                    }
                    
                    Text("What happens after the trial?")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("When your trial ends, you'll continue to have access to all free features. Pro features will be disabled until you purchase the upgrade.")
                        .foregroundColor(.secondary)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Trial Information")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TrialDetailRow: View {
    let title: String
    let detail: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
}

#if DEBUG
struct UpgradeView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradeView()
    }
}
#endif

#else

// MARK: - Open Source Build Information

import SwiftUI

struct UpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        
                        Text("Open Source Version")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Thank you for using the open source build!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Feature Comparison
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Version Comparison")
                            .font(.headline)
                        
                        VStack(spacing: 0) {
                            // Header Row
                            HStack {
                                Text("Feature")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("Open Source")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(width: 80)
                                
                                Text("App Store")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(width: 80)
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            
                            Divider()
                            
                            // Feature Rows
                            ossComparisonRow("Basic Cost Monitoring", oss: "✓", appstore: "✓")
                            ossComparisonRow("Calendar View", oss: "✓", appstore: "✓")
                            ossComparisonRow("Smart Refresh", oss: "✓", appstore: "✓")
                            ossComparisonRow("AWS Profiles", oss: "Unlimited", appstore: "Unlimited")
                            ossComparisonRow("Team Cache Sharing", oss: "✗", appstore: "✓")
                            ossComparisonRow("Advanced Forecasting", oss: "✗", appstore: "✓")
                            ossComparisonRow("Data Export", oss: "✗", appstore: "✓")
                            ossComparisonRow("Priority Support", oss: "Community", appstore: "✓")
                            ossComparisonRow("Price", oss: "Free", appstore: "$3.99")
                        }
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    // Open Source Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Open Source Benefits")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ossFeatureRow("🔍", "Full source code transparency")
                            ossFeatureRow("🔧", "Customize and modify as needed")
                            ossFeatureRow("🤝", "Community-driven development")
                            ossFeatureRow("🔒", "Complete data privacy guaranteed")
                            ossFeatureRow("📖", "Learn from production Swift/SwiftUI code")
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    
                    // App Store Version Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Get AWSCostMonitor Pro")
                            .font(.headline)
                        
                        Text("The App Store version includes team collaboration features and is the same codebase with premium features enabled.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("3-day free trial of all Pro features")
                            }
                            
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(.green)
                                Text("One-time purchase - no subscription")
                            }
                            
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(.blue)
                                Text("Same privacy-first approach")
                            }
                        }
                        .font(.subheadline)
                        
                        // App Store Button
                        Button(action: {
                            if let url = URL(string: "https://apps.apple.com/app/awscostmonitor/id123456789") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "app.badge")
                                Text("Download from App Store")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Support the Project
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Support This Project")
                            .font(.headline)
                        
                        Text("If you find this tool useful, consider:")
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Star the repository on GitHub")
                            }
                            
                            HStack {
                                Image(systemName: "app.badge")
                                    .foregroundColor(.blue)
                                Text("Purchase the App Store version")
                            }
                            
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.green)
                                Text("Share with your team")
                            }
                        }
                        .font(.subheadline)
                        
                        Button("View on GitHub") {
                            if let url = URL(string: "https://github.com/yourusername/awscostmonitor") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Version Information")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 700)
    }
    
    @ViewBuilder
    private func ossComparisonRow(_ feature: String, oss: String, appstore: String) -> some View {
        HStack {
            Text(feature)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(oss)
                .frame(width: 80)
                .foregroundColor(oss == "✓" ? .green : (oss == "✗" ? .red : .primary))
            
            Text(appstore)
                .frame(width: 80)
                .foregroundColor(appstore == "✓" ? .green : (appstore == "✗" ? .red : .primary))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .font(.subheadline)
        
        Divider()
    }
    
    @ViewBuilder
    private func ossFeatureRow(_ icon: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.title3)
            
            Text(description)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#endif