import SwiftUI

struct MultiProfileDashboard: View {
    @EnvironmentObject var awsManager: AWSManager
    @State private var isLoadingProfiles: [String: Bool] = [:]
    @State private var profileCosts: [String: CostData] = [:]
    @State private var selectedProfiles: Set<String> = []
    
    var totalCost: Decimal {
        selectedProfiles.reduce(Decimal(0)) { sum, profileName in
            sum + (profileCosts[profileName]?.amount ?? 0)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                Text("Multi-Profile Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                HStack {
                    Text("Total Cost Across Selected Profiles:")
                        .font(.headline)
                    Spacer()
                    Text(CostDisplayFormatter.format(
                        amount: totalCost,
                        currency: "USD",
                        format: .full
                    ))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(totalCost > 100 ? .red : .primary)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding()
            
            Divider()
            
            // Profile list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(awsManager.profiles, id: \.self) { profile in
                        ProfileCostRow(
                            profile: profile,
                            isSelected: selectedProfiles.contains(profile.name),
                            isLoading: isLoadingProfiles[profile.name] ?? false,
                            costData: profileCosts[profile.name],
                            onToggle: { isSelected in
                                if isSelected {
                                    selectedProfiles.insert(profile.name)
                                    if profileCosts[profile.name] == nil {
                                        loadCostForProfile(profile)
                                    }
                                } else {
                                    selectedProfiles.remove(profile.name)
                                }
                            },
                            onRefresh: {
                                loadCostForProfile(profile)
                            }
                        )
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Actions
            HStack {
                Button(action: refreshAllSelected) {
                    Label("Refresh Selected", systemImage: "arrow.clockwise")
                }
                
                Spacer()
                
                Button(action: selectAll) {
                    Text("Select All")
                }
                
                Button(action: deselectAll) {
                    Text("Deselect All")
                }
            }
            .padding()
        }
        .frame(width: 800, height: 600)
        .onAppear {
            // Pre-select and load current profile
            if let currentProfile = awsManager.selectedProfile {
                selectedProfiles.insert(currentProfile.name)
                if let currentCost = awsManager.costData.first {
                    profileCosts[currentProfile.name] = currentCost
                }
            }
        }
    }
    
    private func loadCostForProfile(_ profile: AWSProfile) {
        isLoadingProfiles[profile.name] = true
        
        Task {
            do {
                let cost = try await awsManager.fetchCostForProfile(profile)
                await MainActor.run {
                    profileCosts[profile.name] = CostData(
                        profileName: profile.name,
                        amount: cost,
                        currency: "USD"
                    )
                    isLoadingProfiles[profile.name] = false
                }
            } catch {
                await MainActor.run {
                    isLoadingProfiles[profile.name] = false
                    awsManager.log(.error, category: "Dashboard", "Failed to load cost for \(profile.name): \(error)")
                }
            }
        }
    }
    
    private func refreshAllSelected() {
        for profileName in selectedProfiles {
            if let profile = awsManager.profiles.first(where: { $0.name == profileName }) {
                loadCostForProfile(profile)
            }
        }
    }
    
    private func selectAll() {
        selectedProfiles = Set(awsManager.profiles.map { $0.name })
        // Load costs for any profiles we don't have data for
        for profile in awsManager.profiles {
            if profileCosts[profile.name] == nil {
                loadCostForProfile(profile)
            }
        }
    }
    
    private func deselectAll() {
        selectedProfiles.removeAll()
    }
}

struct ProfileCostRow: View {
    let profile: AWSProfile
    let isSelected: Bool
    let isLoading: Bool
    let costData: CostData?
    let onToggle: (Bool) -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { onToggle($0) }
            ))
            .toggleStyle(.checkbox)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.headline)
                if let region = profile.region {
                    Text(region)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if let cost = costData {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(CostDisplayFormatter.format(
                        amount: cost.amount,
                        currency: cost.currency,
                        format: .full
                    ))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    
                    // Show budget status if available
                    let budget = AWSManager().getBudget(for: profile.name)
                    let status = AWSManager().calculateBudgetStatus(cost: cost.amount, budget: budget)
                    
                    HStack(spacing: 4) {
                        ProgressView(value: status.percentage, total: 1.0)
                            .progressViewStyle(.linear)
                            .frame(width: 100)
                            .tint(status.isOverBudget ? .red : (status.isNearThreshold ? .orange : .green))
                        
                        Text("\(Int(status.percentage * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else if isSelected {
                Text("No data")
                    .foregroundColor(.secondary)
            }
            
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    MultiProfileDashboard()
        .environmentObject(AWSManager())
}