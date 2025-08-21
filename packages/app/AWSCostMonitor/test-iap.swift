#!/usr/bin/env swift

//
// Test script to verify StoreKit IAP functionality
// Run with: swift test-iap.swift
//

import StoreKit
import Foundation

// Product ID to test
let productID = "middleout.AWSCostMonitor.teamcachepro"

print("🧪 Testing StoreKit IAP functionality")
print("=====================================")
print("Product ID: \(productID)")
print("")

// Create a semaphore to handle async operations
let semaphore = DispatchSemaphore(value: 0)
var testPassed = false

Task {
    do {
        print("📱 Requesting products from StoreKit...")
        let products = try await Product.products(for: [productID])
        
        if products.isEmpty {
            print("❌ No products returned from StoreKit")
            print("   Make sure:")
            print("   1. The product ID matches exactly in App Store Connect")
            print("   2. The product is in 'Ready to Submit' or 'Approved' state")
            print("   3. You're signed into a sandbox account")
            print("   4. The app has the correct bundle ID")
        } else {
            print("✅ Successfully loaded \(products.count) product(s):")
            for product in products {
                print("   - ID: \(product.id)")
                print("   - Name: \(product.displayName)")
                print("   - Price: \(product.displayPrice)")
                print("   - Description: \(product.description)")
            }
            testPassed = true
        }
    } catch {
        print("❌ Failed to load products: \(error)")
        print("   Error details: \(error.localizedDescription)")
    }
    
    semaphore.signal()
}

// Wait for async operation to complete
semaphore.wait()

print("")
print("=====================================")
if testPassed {
    print("✅ IAP Test PASSED")
} else {
    print("❌ IAP Test FAILED")
    print("")
    print("Troubleshooting steps:")
    print("1. Verify product ID in App Store Connect")
    print("2. Ensure IAP is in 'Ready to Submit' state")
    print("3. Check that you're using a sandbox test account")
    print("4. Verify the app bundle ID matches App Store Connect")
    print("5. Try running in Xcode with StoreKit configuration file")
}

exit(testPassed ? 0 : 1)