# Xcode Build Configuration Setup

Follow these steps to set up the build configurations for your GitHub and App Store builds:

## 1. Open Xcode Project Settings

1. Open `AWSCostMonitor.xcodeproj` in Xcode
2. Select the project (blue icon) in the navigator
3. Select the "AWSCostMonitor" target
4. Go to the "Build Settings" tab
5. Make sure "All" and "Combined" are selected at the top

## 2. Add Custom Build Settings

### For GitHub Builds (Debug/Release):

1. Search for "Swift Compiler - Custom Flags"
2. Find "Other Swift Flags"
3. For both Debug and Release configurations, add:
   ```
   -DPREMIUM_FEATURES=0
   -DAPPSTORE_BUILD=0
   ```

### For App Store Builds:

1. Create new configurations:
   - Click the "+" button next to Configurations
   - Duplicate "Debug" → name it "App Store Debug" 
   - Duplicate "Release" → name it "App Store Release"

2. For the new App Store configurations, set "Other Swift Flags":
   ```
   -DPREMIUM_FEATURES=1
   -DAPPSTORE_BUILD=1
   ```

## 3. Update Scheme Settings

### GitHub Build Scheme:
1. Go to Product → Scheme → Edit Scheme
2. Make sure Debug/Release configurations use the standard configs
3. This will have team features disabled

### App Store Build Scheme:
1. Create new scheme: Product → Scheme → New Scheme
2. Name it "AWSCostMonitor App Store"
3. Set Build Configuration to "App Store Release"
4. This will have team features enabled with purchase flow

## 4. Configure Info.plist (App Store only)

For App Store builds, you may need to add:

```xml
<key>SKProduct</key>
<array>
    <string>com.middleout.awscostmonitor.pro</string>
</array>
```

## 5. Build and Test

### GitHub Build:
- Select "AWSCostMonitor" scheme
- Build and run
- Team Cache should show upgrade prompt
- No purchase flow should be available

### App Store Build:
- Select "AWSCostMonitor App Store" scheme  
- Build and run
- Team Cache should be functional
- Purchase flow should be available
- Trial system should work

## 6. Distribution

### GitHub Releases:
- Use standard Release configuration
- Archive and export as "Developer ID"
- Users get team features locked behind upgrade prompt

### App Store:
- Use "App Store Release" configuration
- Archive and export for App Store
- Full purchase flow available

## Verification Checklist

- [ ] GitHub build shows team cache upgrade prompt
- [ ] GitHub build has no purchase UI
- [ ] App Store build has full team cache functionality
- [ ] App Store build shows trial and purchase options
- [ ] Remote config loads correctly in both builds
- [ ] Feature flags work as expected

## Troubleshooting

If you see compilation errors:
1. Clean build folder (⇧⌘K)
2. Delete derived data
3. Verify Swift flags are correct
4. Check that all #if blocks have proper #else/#endif

The conditional compilation should make the GitHub version completely free of any purchase code while keeping everything in the same repository.