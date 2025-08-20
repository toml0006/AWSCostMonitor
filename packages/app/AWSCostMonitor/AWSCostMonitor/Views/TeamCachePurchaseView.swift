//
//  TeamCachePurchaseView.swift
//  AWSCostMonitor
//
//  Purchase UI for Team Cache feature
//

import SwiftUI
import StoreKit

struct TeamCachePurchaseView: View {
    @EnvironmentObject var storeManager: StoreManager
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Enable Team Cache")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Share cost data with your team via S3")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Benefits List
                VStack(alignment: .leading, spacing: 16) {
                    Text("What You Get:")
                        .font(.headline)
                    
                    BenefitRow(
                        icon: "arrow.down.circle.fill",
                        title: "90% Fewer API Calls",
                        description: "Check S3 cache first, reducing AWS API costs"
                    )
                    
                    BenefitRow(
                        icon: "person.3.fill",
                        title: "Team Collaboration",
                        description: "Share cost data across your entire team"
                    )
                    
                    BenefitRow(
                        icon: "bolt.fill",
                        title: "Faster Updates",
                        description: "Get cost data from cache in milliseconds"
                    )
                    
                    BenefitRow(
                        icon: "dollarsign.circle.fill",
                        title: "Cost Savings",
                        description: "Save money on Cost Explorer API calls"
                    )
                    
                    BenefitRow(
                        icon: "lock.shield.fill",
                        title: "Your S3 Bucket",
                        description: "Data stays in your AWS account"
                    )
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                
                // How It Works
                VStack(alignment: .leading, spacing: 12) {
                    Text("How It Works:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        StepRow(number: "1", text: "Configure your S3 bucket details")
                        StepRow(number: "2", text: "App checks S3 for cached data first")
                        StepRow(number: "3", text: "Falls back to API if cache miss")
                        StepRow(number: "4", text: "Updates cache for team members")
                    }
                }
                .padding(.horizontal)
                
                // Purchase Section
                if !storeManager.products.isEmpty {
                    if let product = storeManager.products.first {
                        VStack(spacing: 16) {
                            // Price Badge
                            HStack {
                                Text("One-time purchase")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(product.displayPrice)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal)
                            
                            // Purchase Button
                            Button(action: {
                                Task {
                                    await purchaseProduct(product)
                                }
                            }) {
                                if storeManager.isPurchasing {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(0.8)
                                        Text("Processing...")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                } else {
                                    HStack {
                                        Image(systemName: "cart.fill")
                                        Text("Enable Team Cache - \(product.displayPrice)")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(storeManager.isPurchasing)
                            .padding(.horizontal)
                        }
                    }
                } else if storeManager.isLoadingProducts {
                    // Loading products
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading pricing...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    // Error loading products
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("Unable to load pricing")
                            .font(.headline)
                        
                        if let error = storeManager.purchaseError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Retry") {
                            Task {
                                await storeManager.loadProducts()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
                
                // Restore Purchase Button
                Button(action: {
                    Task {
                        await restorePurchases()
                    }
                }) {
                    Text("Restore Purchase")
                        .font(.caption)
                }
                .buttonStyle(.link)
                .disabled(storeManager.isPurchasing)
                
                // FAQ Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Frequently Asked Questions")
                        .font(.headline)
                    
                    FAQItem(
                        question: "Do I need to set up an S3 bucket?",
                        answer: "Yes, you'll need an S3 bucket in your AWS account. The app will guide you through the simple setup."
                    )
                    
                    FAQItem(
                        question: "Will this reduce my AWS costs?",
                        answer: "Yes! By caching data in S3, you'll make 90% fewer Cost Explorer API calls, saving approximately $0.01 per prevented call."
                    )
                    
                    FAQItem(
                        question: "Is my data secure?",
                        answer: "Absolutely. All data stays in your own AWS account and S3 bucket. We never see or store your cost data."
                    )
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)
                
                // Error message
                if let error = storeManager.purchaseError {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            // Ensure products are loaded when view appears
            if storeManager.products.isEmpty && !storeManager.isLoadingProducts {
                Task {
                    await storeManager.loadProductsWithRetry()
                }
            }
        }
        .alert("Restore Complete", isPresented: $showingRestoreAlert) {
            Button("OK") { }
        } message: {
            Text(restoreMessage)
        }
    }
    
    private func purchaseProduct(_ product: Product) async {
        let success = await storeManager.purchase(product)
        if success {
            // Purchase successful - UI will update automatically
        }
    }
    
    private func restorePurchases() async {
        await storeManager.restorePurchases()
        
        if storeManager.hasTeamCache {
            restoreMessage = "Your Team Cache purchase has been restored successfully!"
        } else {
            restoreMessage = "No previous Team Cache purchase found. If you believe this is an error, please contact support."
        }
        showingRestoreAlert = true
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct StepRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.blue))
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question)
                .font(.system(size: 13, weight: .semibold))
            
            Text(answer)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

// Preview
struct TeamCachePurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        TeamCachePurchaseView()
            .environmentObject(StoreManager.shared)
            .frame(width: 600, height: 800)
    }
}