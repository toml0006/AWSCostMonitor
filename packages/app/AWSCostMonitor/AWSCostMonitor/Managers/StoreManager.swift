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
    case teamCache = "middleout.AWSCostMonitor.teamcachepro"
    
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
        #if !OPENSOURCE
        // Start listening for transactions
        updateListenerTask = listenForTransactions()
        
        // Load products on init with retry logic
        Task {
            await loadProductsWithRetry()
            await updatePurchasedProducts()
        }
        #else
        // Open source build - no in-app purchases
        hasTeamCache = true // Always enabled in open source
        #endif
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
            print("🛍️ StoreManager: Loading products with IDs: \(productIDs)")
            
            // Request products from StoreKit
            products = try await Product.products(for: productIDs)
            
            if products.isEmpty {
                print("⚠️ StoreManager: No products returned from StoreKit")
                print("⚠️ StoreManager: Requested product IDs: \(productIDs)")
                print("⚠️ StoreManager: Make sure these products are configured in App Store Connect")
                purchaseError = "Products not available. Please ensure you're signed into the App Store and try again."
            } else {
                print("✅ StoreManager: Successfully loaded \(products.count) products")
                for product in products {
                    print("  - \(product.id): \(product.displayName) - \(product.displayPrice)")
                }
                purchaseError = nil
            }
            
            isLoadingProducts = false
        } catch {
            print("❌ StoreManager: Failed to load products: \(error)")
            purchaseError = "Unable to connect to the App Store. Please check your internet connection and try again."
            isLoadingProducts = false
        }
    }
    
    // MARK: - Product Loading with Retry
    
    func loadProductsWithRetry(maxAttempts: Int = 3) async {
        var attempts = 0
        var lastError: Error?
        
        while attempts < maxAttempts {
            attempts += 1
            print("🔄 StoreManager: Loading products (attempt \(attempts)/\(maxAttempts))")
            
            await loadProducts()
            
            // If products loaded successfully, break
            if !products.isEmpty {
                print("✅ StoreManager: Products loaded successfully on attempt \(attempts)")
                return
            }
            
            // If this isn't the last attempt, wait before retrying
            if attempts < maxAttempts {
                print("⏳ StoreManager: Waiting 2 seconds before retry...")
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }
        }
        
        // If we get here, all attempts failed
        if products.isEmpty {
            print("❌ StoreManager: Failed to load products after \(maxAttempts) attempts")
            purchaseError = "Unable to load products from the App Store. Please try again later."
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
        let latestExpirationDate: Date? = nil
        
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