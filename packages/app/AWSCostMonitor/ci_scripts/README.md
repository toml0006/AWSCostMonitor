# Xcode Cloud Configuration

This directory contains scripts for Xcode Cloud builds. These scripts ensure that Xcode Cloud builds use the App Store configuration with in-app purchases, while GitHub Actions builds use the open source configuration.

## Build Configurations

### Xcode Cloud (App Store)
- **Scheme**: `AWSCostMonitor` (regular scheme)
- **Features**: Team Cache requires $3.99 in-app purchase
- **Distribution**: App Store Connect / TestFlight
- **StoreKit**: Enabled with purchase flow

### GitHub Actions (Open Source)
- **Scheme**: `AWSCostMonitor-OpenSource`
- **Features**: Team Cache included free
- **Distribution**: Direct download from GitHub
- **StoreKit**: Disabled, no purchase requirements

## Scripts

### `ci_post_clone.sh`
Runs after repository clone. Verifies correct scheme is selected and prevents accidental open source builds.

### `ci_pre_xcodebuild.sh`
Runs before build starts. Configures environment for App Store build with IAP.

### `ci_post_xcodebuild.sh`
Runs after build completes. Verifies build success and App Store configuration.

## Xcode Cloud Setup

To configure Xcode Cloud for App Store builds:

1. **In Xcode:**
   - Open `AWSCostMonitor.xcodeproj`
   - Go to Product → Xcode Cloud → Create Workflow

2. **Workflow Configuration:**
   - **Name**: "App Store Build"
   - **Scheme**: `AWSCostMonitor` (NOT OpenSource)
   - **Configuration**: Release
   - **Platform**: macOS

3. **Environment:**
   - No need to set `OTHER_SWIFT_FLAGS`
   - The regular scheme builds with IAP by default

4. **Actions:**
   - Archive for App Store Connect distribution
   - Run tests (optional)
   - Upload to TestFlight (optional)

## Important Notes

⚠️ **Never use `AWSCostMonitor-OpenSource` scheme in Xcode Cloud** - This is only for GitHub releases

✅ **Always use `AWSCostMonitor` scheme in Xcode Cloud** - This includes the $3.99 Team Cache purchase

## Testing

To test the configuration locally:
```bash
# Simulate Xcode Cloud environment
export CI_XCODE_SCHEME="AWSCostMonitor"
export CI_XCODEBUILD_CONFIGURATION="Release"

# Run the scripts
./ci_scripts/ci_post_clone.sh
./ci_scripts/ci_pre_xcodebuild.sh
# ... build ...
./ci_scripts/ci_post_xcodebuild.sh
```

## Troubleshooting

If Xcode Cloud builds fail:
1. Check the scheme in workflow settings
2. Ensure it's set to `AWSCostMonitor` (not OpenSource)
3. Review build logs for script output
4. Verify StoreKit configuration is present