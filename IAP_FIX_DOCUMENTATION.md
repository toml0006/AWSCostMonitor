# In-App Purchase Fix Documentation

## App Store Rejection Resolution
**Rejection Reason:** Guideline 2.1 - Performance - "Unable to load pricing" error in purchase window

## Root Cause Analysis
The app was rejected because StoreKit was unable to load the in-app purchase products, showing "Unable to load pricing" instead of the actual product information. This was due to:

1. Insufficient error handling and retry logic in StoreManager
2. No automatic retry mechanism when products fail to load
3. Missing onAppear trigger to reload products when purchase view is shown

## Fixes Implemented

### 1. Enhanced StoreManager.swift
- Added `loadProductsWithRetry()` method with 3 automatic retry attempts
- Improved error messages to be more user-friendly
- Added detailed logging for debugging
- Added 2-second delay between retry attempts
- Better handling of empty product responses

### 2. Updated TeamCachePurchaseView.swift
- Added `onAppear` modifier to trigger product loading when view appears
- Ensures products are loaded even if initial load failed
- Calls `loadProductsWithRetry()` for better reliability

### 3. Improved Error Handling
- More descriptive error messages for users
- Retry button in UI when products fail to load
- Clear instructions for users when issues occur

## Testing Instructions

### Local Testing with StoreKit Configuration
1. Open Xcode
2. Select scheme: AWSCostMonitor
3. Edit Scheme → Run → Options
4. StoreKit Configuration: Select `Configuration.storekit`
5. Run the app
6. Navigate to Settings → Team Cache tab
7. Verify products load and display correctly

### Sandbox Testing
1. Sign out of production App Store account
2. Sign in with sandbox test account
3. Run the app
4. Products should load from App Store sandbox environment

### Test Script
Run the included test script:
```bash
cd packages/app/AWSCostMonitor
swift test-iap.swift
```

## App Store Connect Configuration

### Required IAP Setup
1. **Product ID:** `middleout.AWSCostMonitor.teamcache`
2. **Type:** Non-Consumable
3. **Reference Name:** Team Cache
4. **Price Tier:** Tier 4 ($3.99 USD)
5. **Status:** Must be "Ready to Submit" or "Waiting for Review"

### Localization (Required)
- **Display Name:** Team Cache
- **Description:** Enable S3 caching to share costs with your team and reduce API calls by 90%

### Review Information
- **Screenshot:** Required (1024x1024 minimum)
- **Review Notes:** Explain the Team Cache feature functionality

## Submission Process

### Step 1: Verify IAP Configuration
1. Log into App Store Connect
2. Navigate to your app → Features → In-App Purchases
3. Verify "Team Cache" IAP exists with correct product ID
4. Ensure status is "Ready to Submit"
5. If not created, create new Non-Consumable IAP with above details

### Step 2: Submit IAP for Review
⚠️ **CRITICAL:** Submit IAP BEFORE uploading new app binary
1. Click on the Team Cache IAP
2. Add required screenshot if missing
3. Add review notes
4. Click "Submit for Review"
5. Wait for status to change to "Waiting for Review"

### Step 3: Build and Archive App
```bash
# Clean build folder
xcodebuild clean -project AWSCostMonitor.xcodeproj

# Archive for App Store
xcodebuild archive \
  -project AWSCostMonitor.xcodeproj \
  -scheme AWSCostMonitor \
  -configuration Release \
  -archivePath ~/Desktop/AWSCostMonitor.xcarchive
```

### Step 4: Upload to App Store Connect
1. Open Xcode → Window → Organizer
2. Select the archive
3. Click "Distribute App"
4. Choose "App Store Connect"
5. Upload

### Step 5: Create New Version
1. In App Store Connect, create version 1.3.3 (or next version)
2. Add the uploaded build
3. Update "What's New" with: "Fixed in-app purchase loading issue"

### Step 6: Add Review Notes
Include in review notes:
```
The app includes a Team Cache in-app purchase for $3.99.

To test the IAP:
1. Open the app
2. Click the gear icon to open Settings
3. Navigate to "Team Cache" tab
4. The purchase screen will load with pricing

The IAP loading issue from the previous submission has been resolved with:
- Retry logic for product loading
- Better error handling
- Automatic product refresh when view appears

For testing purposes, the app works fully without purchase. The Team Cache feature is an optional enhancement that enables S3 caching for teams.
```

### Step 7: Submit for Review
1. Ensure both IAP and app version are ready
2. Click "Add for Review"
3. Submit

## Verification Checklist

Before submission:
- [ ] IAP product ID matches exactly: `middleout.AWSCostMonitor.teamcache`
- [ ] IAP is in "Waiting for Review" status
- [ ] App loads products successfully in local testing
- [ ] Error handling shows retry button if loading fails
- [ ] Products reload when TeamCachePurchaseView appears
- [ ] Build configuration includes StoreKit entitlements
- [ ] Review notes explain the fix

## Common Issues and Solutions

### Issue: Products still not loading
**Solution:** 
- Verify exact product ID match
- Ensure IAP is submitted for review
- Check sandbox account is configured
- Verify bundle ID matches App Store Connect

### Issue: "Unable to connect to App Store"
**Solution:**
- Check internet connection
- Verify sandbox account credentials
- Ensure not rate-limited by App Store
- Try different network connection

### Issue: Products load in sandbox but not in review
**Solution:**
- Ensure IAP is submitted BEFORE app binary
- Verify IAP status is "Waiting for Review"
- Include clear review notes about IAP testing

## Code Changes Summary

### StoreManager.swift
- Added `loadProductsWithRetry(maxAttempts: Int = 3)` method
- Enhanced error messages in `loadProducts()`
- Added retry logic with exponential backoff
- Improved logging for debugging

### TeamCachePurchaseView.swift
- Added `.onAppear` modifier to trigger product loading
- Calls `loadProductsWithRetry()` when products are empty

## Contact for Issues
If reviewers encounter any issues:
- Email: support@awscostmonitor.io
- Include "App Store Review" in subject
- We'll respond within 24 hours

## Success Metrics
The fix is successful when:
1. Products load on first app launch
2. Retry mechanism recovers from temporary failures
3. Users see actual pricing instead of error message
4. App passes App Store review