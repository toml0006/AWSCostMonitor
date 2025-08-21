# App Store Submission Checklist

## ✅ Completed Items

### Code Preparation
- [x] Removed automatic purchase simulation from release builds
- [x] Updated StoreKit configuration with correct Team ID (TJSYWP4C3D)
- [x] Fixed product ID to match bundle identifier pattern (middleout.AWSCostMonitor.teamcachepro)
- [x] All debug code is properly wrapped in `#if DEBUG` blocks
- [x] Team Cache purchase flow implemented with StoreKit 2

### Configuration
- [x] Bundle Identifier: `middleout.AWSCostMonitor`
- [x] Development Team: `TJSYWP4C3D`
- [x] Product ID: `middleout.AWSCostMonitor.teamcachepro`
- [x] Price: $3.99 (Non-consumable)

## 📋 Required Actions Before Submission

### 1. App Store Connect Setup
- [ ] Create app in App Store Connect
- [ ] Add Team Cache in-app purchase ($3.99 non-consumable)
- [ ] Upload app screenshots (menu bar, settings, calendar view)
- [ ] Write app description highlighting key features
- [ ] Set up app review information

### 2. Legal Documents
- [ ] Create Privacy Policy (app collects no personal data)
- [ ] Create Terms of Service (if required)
- [ ] Add URLs to app metadata in App Store Connect

### 3. Testing
- [ ] Test purchase flow in sandbox environment
- [ ] Test restore purchases functionality
- [ ] Verify all features work without debug code
- [ ] Test on multiple macOS versions (13.0+)

### 4. Build Configuration
- [ ] Set version number (currently 1.3.0)
- [ ] Set build number
- [ ] Archive with Release configuration
- [ ] Validate archive before upload

### 5. App Review Notes
Suggested review notes:
```
AWSCostMonitor is a menu bar app for monitoring AWS costs.

The Team Cache in-app purchase ($3.99) enables:
- S3-based caching to reduce API calls by 90%
- Team cost data sharing
- Faster updates from cache

To test:
1. Configure AWS credentials in ~/.aws/config
2. Click menu bar icon to see costs
3. Settings → Teams tab shows Team Cache purchase
4. Purchase enables S3 configuration options

No account creation required. All data stays local.
```

## 🚨 Important Notes

1. **Debug Features**: The app includes debug features that are ONLY visible in DEBUG builds:
   - Debug timer controls
   - Force refresh with bypass
   - Purchase simulation toggle
   - "DEBUG BUILD" label

2. **Privacy**: The app:
   - Does NOT collect any user data
   - Does NOT use analytics
   - Does NOT transmit data to external servers
   - Only connects to AWS APIs using user's credentials

3. **Permissions Required**:
   - Network access (for AWS API calls)
   - File access (to read ~/.aws/config)

4. **Minimum Requirements**:
   - macOS 13.0 or later
   - AWS credentials configured

## 📱 In-App Purchase Details

**Product Name**: Team Cache
**Product ID**: `middleout.AWSCostMonitor.teamcachepro`
**Type**: Non-Consumable
**Price**: $3.99 USD
**Description**: Enable S3 caching to share cost data with your team and reduce API calls by 90%

## 🔧 Build Commands

```bash
# Clean build
xcodebuild clean -scheme AWSCostMonitor

# Archive for App Store
xcodebuild archive \
  -scheme AWSCostMonitor \
  -configuration Release \
  -archivePath ~/Desktop/AWSCostMonitor.xcarchive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath ~/Desktop/AWSCostMonitor.xcarchive \
  -exportPath ~/Desktop \
  -exportOptionsPlist ExportOptions.plist
```

## 📝 Final Checks

- [ ] Remove any test AWS credentials
- [ ] Verify no hardcoded sensitive data
- [ ] Test fresh install flow
- [ ] Verify auto-update mechanism (if applicable)
- [ ] Check code signing and notarization