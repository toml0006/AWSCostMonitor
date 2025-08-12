//
//  PurchaseManager.swift
//  AWSCostMonitor
//
//  StoreKit integration for $3.99 Pro features with trial support
//

#if APPSTORE_BUILD
import Foundation
import SwiftUI
import StoreKit
import OSLog

@MainActor
class PurchaseManager: NSObject, ObservableObject {
    static let shared = PurchaseManager()
    
    private let logger = Logger(subsystem: "middleout.AWSCostMonitor", category: "PurchaseManager")
    
    // MARK: - Product Configuration
    
    /// Product ID for Pro features ($3.99)
    static let proProductID = "com.middleout.awscostmonitor.pro"
    
    // MARK: - Published State
    
    @Published private(set) var hasPremiumAccess = false
    @Published private(set) var availableProducts: [SKProduct] = []
    @Published private(set) var isLoading = false
    @Published private(set) var purchaseError: Error?
    @Published private(set) var transactionState: SKPaymentTransactionState?
    
    // MARK: - Trial Management
    
    @Published private(set) var isTrialActive = false
    @Published private(set) var trialDaysRemaining = 0
    @Published private(set) var trialStartDate: Date?
    @Published private(set) var trialEndDate: Date?
    
    private var productsRequest: SKProductsRequest?
    
    // MARK: - Computed Properties
    
    /// Whether the user has access to Pro features (purchased OR trial active)
    var hasAccessToProFeatures: Bool {
        return hasPremiumAccess || isTrialActive
    }
    
    /// The Pro product for purchase
    var proProduct: SKProduct? {
        return availableProducts.first { $0.productIdentifier == Self.proProductID }
    }
    
    /// Formatted price of the Pro product
    var proProductPrice: String {
        guard let product = proProduct else { return "$3.99" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? "$3.99"
    }
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        
        // Add payment transaction observer
        SKPaymentQueue.default().add(self)
        
        // Load purchase state
        loadPurchaseState()
        updateTrialStatus()
        
        // Load available products
        Task {
            await loadProducts()
        }
        
        logger.info("PurchaseManager initialized")
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        purchaseError = nil
        
        logger.info("Loading App Store products...")
        
        let productIdentifiers = Set([Self.proProductID])
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    // MARK: - Purchase Management
    
    /// Purchase the Pro product
    func purchasePro() {
        guard let product = proProduct else {
            logger.error("Pro product not available for purchase")
            purchaseError = PurchaseError.productNotAvailable
            return
        }
        
        guard SKPaymentQueue.canMakePayments() else {
            logger.error("Payments not allowed on this device")
            purchaseError = PurchaseError.paymentsNotAllowed
            return
        }
        
        logger.info("Starting purchase for Pro product: \(product.productIdentifier)")
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        
        isLoading = true
        purchaseError = nil
    }
    
    /// Restore previous purchases
    func restorePurchases() {
        logger.info("Restoring purchases...")
        
        isLoading = true
        purchaseError = nil
        
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - Trial Management
    
    /// Start the free trial period
    func startTrial() {
        guard !hasPremiumAccess && !isTrialActive else {
            logger.warning("Trial not available: premium=\(self.hasPremiumAccess), trial=\(self.isTrialActive)")
            return
        }
        
        let trialDuration = RemoteConfig.shared.trialDurationDays
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: trialDuration, to: startDate)!
        
        trialStartDate = startDate
        trialEndDate = endDate
        
        // Save trial state
        UserDefaults.standard.set(startDate, forKey: "trialStartDate")
        UserDefaults.standard.set(endDate, forKey: "trialEndDate")
        
        updateTrialStatus()
        
        logger.info("Started \(trialDuration)-day trial: \(startDate) to \(endDate)")
    }
    
    /// Update trial status based on dates
    private func updateTrialStatus() {
        guard let endDate = UserDefaults.standard.object(forKey: "trialEndDate") as? Date else {
            isTrialActive = false
            trialDaysRemaining = 0
            trialStartDate = nil
            trialEndDate = nil
            return
        }
        
        let startDate = UserDefaults.standard.object(forKey: "trialStartDate") as? Date
        let now = Date()
        
        if now < endDate {
            isTrialActive = true
            trialDaysRemaining = max(0, Calendar.current.dateComponents([.day], from: now, to: endDate).day ?? 0)
            trialStartDate = startDate
            trialEndDate = endDate
            
            logger.info("Trial active: \(self.trialDaysRemaining) days remaining")
        } else {
            isTrialActive = false
            trialDaysRemaining = 0
            trialStartDate = nil
            trialEndDate = nil
            
            // Clean up expired trial data
            UserDefaults.standard.removeObject(forKey: "trialStartDate")
            UserDefaults.standard.removeObject(forKey: "trialEndDate")
            
            logger.info("Trial expired")
        }
    }
    
    // MARK: - Purchase State Management
    
    private func loadPurchaseState() {
        hasPremiumAccess = UserDefaults.standard.bool(forKey: "hasPremiumAccess")
        logger.info("Loaded purchase state: premium=\(self.hasPremiumAccess)")
    }
    
    private func setPurchaseState(_ purchased: Bool) {
        hasPremiumAccess = purchased
        UserDefaults.standard.set(purchased, forKey: "hasPremiumAccess")
        
        if purchased {
            // If purchased, clear any trial data
            UserDefaults.standard.removeObject(forKey: "trialStartDate")
            UserDefaults.standard.removeObject(forKey: "trialEndDate")
            isTrialActive = false
            trialDaysRemaining = 0
        }
        
        logger.info("Set purchase state: premium=\(purchased)")
    }
    
    // MARK: - Receipt Validation
    
    private func validateReceipt() {
        // For a production app, you'd want to validate receipts with your server
        // For now, we'll trust the transaction state from StoreKit
        logger.info("Receipt validation (simplified implementation)")
    }
    
    // MARK: - Public Status Methods
    
    /// Check if the user can start a trial
    var canStartTrial: Bool {
        return !hasPremiumAccess && !isTrialActive && trialStartDate == nil
    }
    
    /// Get trial status description for UI
    var trialStatusDescription: String {
        if hasPremiumAccess {
            return "Pro features unlocked"
        } else if isTrialActive {
            let days = trialDaysRemaining
            return days > 1 ? "\(days) trial days remaining" : "Trial expires today"
        } else if trialStartDate != nil {
            return "Trial expired"
        } else {
            return "Start your free trial"
        }
    }
    
    /// Update trial status (call this periodically)
    func refreshTrialStatus() {
        updateTrialStatus()
    }
}

// MARK: - SKProductsRequestDelegate

extension PurchaseManager: SKProductsRequestDelegate {
    nonisolated func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        Task { @MainActor in
            self.availableProducts = response.products
            self.isLoading = false
            
            logger.info("Loaded \(response.products.count) products")
            
            for product in response.products {
                logger.info("Product: \(product.productIdentifier) - \(product.localizedTitle) - \(product.price)")
            }
            
            if !response.invalidProductIdentifiers.isEmpty {
                logger.warning("Invalid product identifiers: \(response.invalidProductIdentifiers)")
            }
        }
    }
    
    nonisolated func request(_ request: SKRequest, didFailWithError error: Error) {
        Task { @MainActor in
            self.isLoading = false
            self.purchaseError = error
            logger.error("Products request failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - SKPaymentTransactionObserver

extension PurchaseManager: SKPaymentTransactionObserver {
    nonisolated func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        Task { @MainActor in
            for transaction in transactions {
                await handleTransaction(transaction)
            }
        }
    }
    
    @MainActor
    private func handleTransaction(_ transaction: SKPaymentTransaction) async {
        transactionState = transaction.transactionState
        
        switch transaction.transactionState {
        case .purchased:
            logger.info("Transaction purchased: \(transaction.payment.productIdentifier)")
            
            if transaction.payment.productIdentifier == Self.proProductID {
                setPurchaseState(true)
                validateReceipt()
            }
            
            SKPaymentQueue.default().finishTransaction(transaction)
            isLoading = false
            purchaseError = nil
            
        case .restored:
            logger.info("Transaction restored: \(transaction.payment.productIdentifier)")
            
            if transaction.payment.productIdentifier == Self.proProductID {
                setPurchaseState(true)
            }
            
            SKPaymentQueue.default().finishTransaction(transaction)
            isLoading = false
            purchaseError = nil
            
        case .failed:
            logger.error("Transaction failed: \(transaction.error?.localizedDescription ?? "Unknown error")")
            
            if let error = transaction.error as? SKError {
                if error.code != .paymentCancelled {
                    purchaseError = error
                }
            }
            
            SKPaymentQueue.default().finishTransaction(transaction)
            isLoading = false
            
        case .deferred:
            logger.info("Transaction deferred (awaiting approval)")
            
        case .purchasing:
            logger.info("Transaction purchasing...")
            
        @unknown default:
            logger.warning("Unknown transaction state: \(transaction.transactionState.rawValue)")
        }
    }
    
    nonisolated func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        Task { @MainActor in
            self.isLoading = false
            logger.info("Restore completed transactions finished")
        }
    }
    
    nonisolated func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        Task { @MainActor in
            self.isLoading = false
            self.purchaseError = error
            logger.error("Restore failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Error Types

enum PurchaseError: Error, LocalizedError {
    case productNotAvailable
    case paymentsNotAllowed
    case receiptValidationFailed
    
    var errorDescription: String? {
        switch self {
        case .productNotAvailable:
            return "Product not available for purchase"
        case .paymentsNotAllowed:
            return "Purchases are not allowed on this device"
        case .receiptValidationFailed:
            return "Failed to validate purchase receipt"
        }
    }
}

#else

// MARK: - Stub Implementation for Non-App Store Builds

import Foundation
import SwiftUI

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    
    @Published private(set) var hasPremiumAccess = false
    @Published private(set) var isTrialActive = false
    @Published private(set) var trialDaysRemaining = 0
    
    var hasAccessToProFeatures: Bool { return false }
    var proProductPrice: String { return "$3.99" }
    var canStartTrial: Bool { return false }
    var trialStatusDescription: String { return "Premium features not available in this build" }
    
    private init() {}
    
    func loadProducts() async {}
    func purchasePro() {}
    func restorePurchases() {}
    func startTrial() {}
    func refreshTrialStatus() {}
}

#endif