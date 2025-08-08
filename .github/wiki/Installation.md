# Installation Guide

This guide will help you install AWSCostMonitor on your Mac.

## System Requirements

- **macOS 13.0 (Ventura)** or later
- **AWS CLI** configured with profiles
- **Cost Explorer API permissions** in your AWS account

## Download Options

### Option 1: DMG Installer (Recommended)

1. Visit the [Releases page](https://github.com/toml0006/AWSCostMonitor/releases)
2. Download the latest `.dmg` file (e.g., `AWSCostMonitor-v1.2.0.dmg`)
3. Open the downloaded DMG file
4. Drag **AWSCostMonitor** to the **Applications** folder
5. Launch from Applications or Spotlight

### Option 2: Zip Archive

1. Visit the [Releases page](https://github.com/toml0006/AWSCostMonitor/releases)
2. Download the latest `.zip` file (e.g., `AWSCostMonitor-v1.2.0.zip`)
3. Extract the zip file
4. Move `AWSCostMonitor.app` to your Applications folder
5. Launch from Applications or Spotlight

## First Launch

When you first launch AWSCostMonitor:

1. **macOS Security Prompt**: You may see a security dialog since the app isn't code-signed yet
   - Go to **System Preferences → Security & Privacy → General**
   - Click **"Open Anyway"** next to the AWSCostMonitor message

2. **Menu Bar Icon**: Look for the dollar sign ($) icon in your menu bar

3. **Initial Setup**: The app will guide you through selecting your AWS profile

## Verification

To verify the installation:

1. Click the AWSCostMonitor icon in your menu bar
2. You should see a dropdown with options to select AWS profiles
3. If you see "No profiles found", check your [AWS Setup](AWS-Setup)

## Updating

AWSCostMonitor will notify you when updates are available. To update:

1. Download the latest version from the Releases page
2. Replace the old app with the new one
3. Your settings and data will be preserved

## Uninstalling

To remove AWSCostMonitor:

1. Quit the application
2. Delete `AWSCostMonitor.app` from your Applications folder
3. Optionally, remove preferences: `~/Library/Preferences/com.middleout.AWSCostMonitor.plist`

## Troubleshooting

**App won't launch?**
- Check macOS version compatibility
- Try the "Open Anyway" option in Security preferences

**No AWS profiles found?**
- Verify AWS CLI is installed: `aws --version`
- Check your `~/.aws/config` file exists
- See [AWS Setup](AWS-Setup) guide

**Permission denied errors?**
- Ensure the app has necessary permissions
- Check your IAM user permissions for Cost Explorer

---

**Next Steps:** Configure your [AWS Setup](AWS-Setup) →