//
//  StoreManager.swift
//  AWSCostMonitor
//
//  Handles in-app purchases using StoreKit 2
//

import StoreKit
import SwiftUI

// Product IDs for App Store
enum ProductID: String, CaseIterable {
    case teamCache = "com.middleout.awscostmonitor.teamcache"
    
    var displayName: String {
        switch self {
        case .teamCache: return "Team Cache"
        }
    }
    
    var description: String {
        switch self {
        case .teamCache: return "Enable S3 caching\nShare costs with your team\nReduce API calls by 90%"
        }
    }
}

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoadingProducts = false
    @Published var purchaseError: String?
    @Published var isPurchasing = false
    
    // Team Cache features state
    @Published var hasTeamCache = false
    @Published var teamCacheExpirationDate: Date?
    
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        // Start listening for transactions
        updateListenerTask = listenForTransactions()
        
        // Load products on init
        Task {
            await loadProducts()
            await updatePurchasedProducts()
            
            // DEBUG: Simulate successful purchase for testing
            #if DEBUG
            simulateSuccessfulPurchase()
            #endif
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoadingProducts = true
        purchaseError = nil
        
        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            isLoadingProducts = false
        } catch {
            purchaseError = "Failed to load products: \(error.localizedDescription)"
            isLoadingProducts = false
        }
    }
    
    // MARK: - Purchase Flow
    
    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        purchaseError = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Check whether the transaction is verified
                let transaction = try checkVerified(verification)
                
                // Update purchased products
                await updatePurchasedProducts()
                
                // Always finish the transaction
                await transaction.finish()
                
                isPurchasing = false
                return true
                
            case .userCancelled:
                isPurchasing = false
                return false
                
            case .pending:
                purchaseError = "Purchase is pending approval"
                isPurchasing = false
                return false
                
            @unknown default:
                purchaseError = "Unknown purchase result"
                isPurchasing = false
                return false
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
            isPurchasing = false
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil
        
        do {
            // Sync with App Store
            try await AppStore.sync()
            
            // Update purchased products
            await updatePurchasedProducts()
            
            isPurchasing = false
            
            if hasTeamCache {
                purchaseError = nil // Clear any error on successful restore
            } else {
                purchaseError = "No Team Cache purchase found to restore"
            }
        } catch {
            purchaseError = "Restore failed: \(error.localizedDescription)"
            isPurchasing = false
        }
    }
    
    // MARK: - Transaction Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Update Purchased Products
    
    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        var hasActiveSubscription = false
        var latestExpirationDate: Date?
        
        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchased.insert(transaction.productID)
                
                // Team Cache is a one-time purchase that never expires
                if transaction.productID == ProductID.teamCache.rawValue {
                    hasActiveSubscription = true
                }
            } catch {
                // Skip unverified transactions
                continue
            }
        }
        
        purchasedProductIDs = purchased
        hasTeamCache = !purchased.isEmpty || hasActiveSubscription
        teamCacheExpirationDate = latestExpirationDate
        
        // Save Team Cache status to UserDefaults for quick access
        UserDefaults.standard.set(hasTeamCache, forKey: "HasTeamCache")
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transactions
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // Update purchased products
                    await self.updatePurchasedProducts()
                    
                    // Always finish transactions
                    await transaction.finish()
                } catch {
                    // Transaction failed verification
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    func product(for productID: ProductID) -> Product? {
        return products.first { $0.id == productID.rawValue }
    }
    
    func isPurchased(_ productID: ProductID) -> Bool {
        return purchasedProductIDs.contains(productID.rawValue)
    }
    
    func formattedPrice(for product: Product) -> String {
        return product.displayPrice
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    func simulateSuccessfulPurchase() {
        // Simulate that the user has purchased Team Cache
        purchasedProductIDs.insert(ProductID.teamCache.rawValue)
        hasTeamCache = true
        UserDefaults.standard.set(true, forKey: "HasTeamCache")
        purchaseError = nil
        
        print("🎉 DEBUG: Simulating successful Team Cache purchase")
    }
    
    func clearPurchase() {
        // Clear the simulated purchase for testing
        purchasedProductIDs.removeAll()
        hasTeamCache = false
        UserDefaults.standard.set(false, forKey: "HasTeamCache")
        
        print("🗑️ DEBUG: Cleared Team Cache purchase")
    }
    #endif
}

// MARK: - Store Errors

enum StoreError: Error, LocalizedError {
    case failedVerification
    case productNotFound
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found"
        }
    }
}