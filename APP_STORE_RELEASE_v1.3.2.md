# App Store Release Instructions for v1.3.2

## Build the App for Release

1. **Archive the app:**
```bash
cd /Users/jackson/dev/middleout/AWSCostMonitor/packages/app/AWSCostMonitor
xcodebuild -project AWSCostMonitor.xcodeproj -scheme AWSCostMonitor -configuration Release archive -archivePath build/AWSCostMonitor-v1.3.2.xcarchive
```

2. **Export for App Store:**
```bash
xcodebuild -exportArchive -archivePath build/AWSCostMonitor-v1.3.2.xcarchive -exportPath build/AppStore-v1.3.2 -exportOptionsPlist ExportOptions-AppStore.plist
```

## Using Fastlane (if configured)

```bash
bundle exec fastlane mac release
```

## Manual Upload via Xcode

1. Open Xcode
2. Product → Archive
3. Wait for archive to complete
4. Click "Distribute App"
5. Select "App Store Connect"
6. Follow the upload wizard

## App Store Connect Steps

1. Go to https://appstoreconnect.apple.com
2. Select AWSCostMonitor app
3. Create new version 1.3.2
4. Add What's New text:

```
What's New in Version 1.3.2:

• Team Remote Caching - Share cost data across your team using S3
• New Professional Icons - Complete visual redesign  
• Enhanced Timer System - More reliable refresh updates
• Comprehensive Setup Guide - Step-by-step team cache instructions

Bug Fixes:
• Fixed refresh timer not firing properly
• Improved error handling for cache operations
```

5. Upload the build from Xcode
6. Add screenshots if needed
7. Submit for review

## Pre-Release Checklist

- [ ] Version number updated to 1.3.2
- [ ] Build number incremented to 4
- [ ] All tests passing
- [ ] App signed with correct certificates
- [ ] Release notes prepared
- [ ] Screenshots up to date

## Notes

- Ensure you have the latest provisioning profiles
- Check that all entitlements are correct
- The app should be signed with the App Store distribution certificate