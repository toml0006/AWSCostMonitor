# Open Source Build Instructions

## Overview

The open source build of AWSCostMonitor removes all in-app purchase and Team Cache purchase flows, making the Team Cache feature freely available to all users.

## Differences from App Store Version

### Open Source Version Includes:
- ✅ All core cost monitoring features
- ✅ Multiple AWS profile support
- ✅ Team Cache functionality (no purchase required)
- ✅ All display formats and settings
- ✅ Alerts and notifications
- ✅ Calendar view and visualizations

### Open Source Version Excludes:
- ❌ In-app purchase flow
- ❌ StoreKit integration
- ❌ Purchase/restore UI
- ❌ Team Cache purchase requirement

## Building the Open Source Version

### Method 1: Command Line

```bash
# Build with OPENSOURCE flag
xcodebuild -scheme AWSCostMonitor \
  -configuration Debug \
  OTHER_SWIFT_FLAGS="-D OPENSOURCE" \
  build

# For release build
xcodebuild -scheme AWSCostMonitor \
  -configuration Release \
  OTHER_SWIFT_FLAGS="-D OPENSOURCE" \
  build
```

### Method 2: Xcode

1. Open `AWSCostMonitor.xcodeproj` in Xcode
2. Select the AWSCostMonitor scheme
3. Edit Scheme (Product → Scheme → Edit Scheme)
4. Select "Run" on the left
5. Go to the "Arguments" tab
6. Add to "Arguments Passed On Launch":
   ```
   -D OPENSOURCE
   ```
7. Build and run

### Method 3: Use the Pre-configured Scheme (Recommended)

The repository includes a pre-configured scheme `AWSCostMonitor-OpenSource` that automatically builds with the OPENSOURCE flag.

1. Open `AWSCostMonitor.xcodeproj` in Xcode
2. Select the `AWSCostMonitor-OpenSource` scheme from the scheme selector
3. Build and run (⌘R)

The scheme is already configured with the necessary build flags and will compile the open source version without any purchase requirements.

## Verification

To verify you're running the open source build:

1. Open Settings in the app
2. Check that there's no "Team Cache" tab with a Pro badge
3. If Team Cache is configured, it should be directly accessible without any purchase UI

## Distribution

When distributing the open source version:

1. Build with the OPENSOURCE flag as shown above
2. The resulting `.app` will have Team Cache enabled by default
3. No App Store or purchase infrastructure is included
4. Can be distributed freely under the project's open source license

## Code Organization

The codebase uses conditional compilation to manage features:

```swift
#if !OPENSOURCE
// App Store specific code (purchases, StoreKit, etc.)
#else
// Open source specific code
#endif
```

Key files affected:
- `BuildConfiguration.swift` - Central configuration
- `SettingsView.swift` - Conditional Team Cache tab
- `StoreManager.swift` - Disabled in open source builds
- `TeamCachePurchaseView.swift` - Not shown in open source

## Support

For issues specific to the open source build, please mention "OPENSOURCE build" in your GitHub issue.