# App Store Setup Instructions

Since Fastlane's `produce` action has limitations with API key authentication, we'll create the app manually and then use Fastlane for everything else.

## Step 1: Create App Manually on App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Sign in with your Apple ID: `jackson.tomlinson@gmai.com`
3. Click **"My Apps"**
4. Click the **"+"** button to create a new app
5. Fill in the app details:

   **Platform:** macOS
   **Name:** AWSCostMonitor
   **Primary Language:** English (U.S.)
   **Bundle ID:** middleout.AWSCostMonitor
   **SKU:** awscostmonitor-2025

6. Click **"Create"**

## Step 2: Configure Basic App Information

Once the app is created, configure these basic settings:

**App Information:**
- Category: Developer Tools
- Pricing and Availability: Free with In-App Purchase
- Age Rating: 4+ (No objectionable content)

**In-App Purchase:**
- Product ID: `com.middleout.awscostmonitor.pro`
- Type: Non-Consumable
- Display Name: AWSCostMonitor Pro
- Description: Unlock team features including team cache and advanced forecasting
- Price: $3.99 (Tier 4)

## Step 3: Use Fastlane for Everything Else

Once the app exists on App Store Connect, you can use Fastlane for:

```bash
# Upload metadata and screenshots
bundle exec fastlane mac upload_metadata

# Build and upload to App Store
bundle exec fastlane mac release

# Upload to TestFlight for beta testing
bundle exec fastlane mac beta

# Submit for review
bundle exec fastlane mac submit_for_review
```

## Why This Approach?

The `produce` action in Fastlane has limited API key support and still requires Apple ID password authentication for creating new apps. However, all other Fastlane actions (uploading builds, metadata, screenshots, etc.) work perfectly with API keys.

This hybrid approach gives us:
- ✅ One-time manual app creation (5 minutes)
- ✅ Fully automated builds, uploads, and submissions
- ✅ No password storage or 2FA complications
- ✅ All benefits of API key authentication for ongoing work

## Next Steps

After creating the app manually:

1. **Test the upload process:**
   ```bash
   bundle exec fastlane mac upload_metadata
   ```

2. **Create your first build:**
   ```bash
   bundle exec fastlane mac beta
   ```

3. **Submit for review when ready:**
   ```bash
   bundle exec fastlane mac release submit:true
   ```