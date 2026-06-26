# App Store Release — v1.6.0

Version **1.6.0**, build **11** (build number is overridden by Xcode Cloud's `CI_BUILD_NUMBER` if built there). Scheme: **`AWSCostMonitor`** (App Store, includes the $3.99 Team Cache in-app purchase). Configuration: **Release**.

## Build & upload

### Option A — Xcode Cloud (primary)

Xcode Cloud builds the `AWSCostMonitor` scheme on push/tag (per the App Store Connect workflow) and uploads to App Store Connect / TestFlight automatically. Confirm a 1.6.0 build appears under **App Store Connect → Xcode Cloud** and **TestFlight**.

### Option B — Local archive (fallback)

```bash
cd /Users/jackson/dev/middleout/AWSCostMonitor/packages/app/AWSCostMonitor
xcodebuild -project AWSCostMonitor.xcodeproj \
           -scheme AWSCostMonitor \
           -configuration Release \
           archive \
           -archivePath build/AWSCostMonitor-v1.6.0.xcarchive

xcodebuild -exportArchive \
           -archivePath build/AWSCostMonitor-v1.6.0.xcarchive \
           -exportPath build/AppStore-v1.6.0 \
           -exportOptionsPlist ExportOptions-AppStore.plist
```

Then upload the `.pkg` via **Xcode Organizer → Distribute App → App Store Connect**, or **Transporter**.

## App Store Connect — "What's New in This Version"

```
What's New in v1.6

• Savings Plan recommendations — when AWS suggests a Savings Plan purchase, the menu bar shows the estimated monthly savings, and the calendar window breaks down the recommended commitment, savings %, ROI, and term.
• Cost breakdown by account, region, or cost-allocation tag — for any month you select in the calendar.
• The popover now separates month-to-date actuals from the month-end forecast, with sparkline scrubbing that highlights any day across every per-service row.
• Fixed the month-over-month delta to use AWS-reported month-to-date on both sides, so accounts with Savings Plans, Reserved Instances, or credits compare correctly.
```

## Notes for App Review

> Paste into **App Store Connect → Version 1.6.0 → App Review Information → Notes**.

```
ABOUT THE APP
AWSCostMonitor is a menu bar app that displays your AWS month-to-date spend. It reads your existing local AWS CLI configuration (~/.aws/config and ~/.aws/credentials) and calls the AWS Cost Explorer API directly from the user's machine. There is no account, login, or server — all data stays local.

TESTING WITHOUT AN AWS ACCOUNT
The app requires AWS credentials with Cost Explorer read permission, which the review team may not have. No credentials are needed to evaluate the UI: on the first-run onboarding screen tap "Use Demo Data" (or "Continue with demo data instead" on the AWS-folder access prompt). The menu bar, popover, and calendar/breakdown views then render with representative sample figures. Live numbers require a configured AWS profile in ~/.aws.

FILE ACCESS (SANDBOX)
The app is sandboxed. On first run it asks the user to grant read access to the ~/.aws folder using the standard open-file panel; access is then persisted with a security-scoped bookmark (com.apple.security.files.user-selected.read-only + bookmarks.app-scope). The app only reads AWS config/credentials — it never writes to them.

NETWORK
Outbound HTTPS only, to AWS API endpoints (Cost Explorer, Savings Plans, STS, and optionally S3 for the Team Cache feature). No analytics, telemetry, or third-party services. ITSAppUsesNonExemptEncryption is false (standard HTTPS only).

IN-APP PURCHASE
"Team Cache" is a $3.99 non-consumable that lets teams share cost data through their own AWS S3 bucket to reduce API calls. All core cost-monitoring features work without the purchase. The purchase requires the user's own AWS S3 bucket; it does not unlock any Apple-hosted content.

NEW IN 1.6.0 — PERMISSIONS
This version can optionally call two additional read-only AWS APIs: ce:GetSavingsPlansPurchaseRecommendation (savings recommendation) and savingsplans:DescribeSavingsPlans (detect whether a Savings Plan exists). Both are optional; the app degrades gracefully if the user's IAM policy doesn't grant them.

CONTACT
Happy to provide a test AWS profile or a screen recording on request.
```

## Privacy / data

- **Data collection:** none. No analytics, no telemetry, no accounts.
- App Privacy nutrition label: **Data Not Collected** (unchanged from prior versions).
- All cost data is fetched live from AWS to the user's machine and cached locally.

## Pre-release checklist

- [x] `MARKETING_VERSION` = `1.6.0` (all targets)
- [x] `CURRENT_PROJECT_VERSION` = `11` (or Xcode Cloud-managed)
- [x] Both schemes compile (`AWSCostMonitor`, `AWSCostMonitor-OpenSource`)
- [x] CHANGELOG + website updated
- [ ] Archive with App Store distribution certificate (`3rd Party Mac Developer Application` + `match AppStore` profile) — or via Xcode Cloud
- [ ] Build appears in App Store Connect / TestFlight
- [ ] "What's New" pasted
- [ ] App Review notes pasted
- [ ] Screenshots current (popover past/forecast split, calendar breakdown, savings card are new in 1.6)
- [ ] Submit for review

## Notes

- The App Store build uses the **`AWSCostMonitor`** scheme (NOT `-OpenSource`); the OpenSource scheme is for the free GitHub direct-download build only.
- Screenshots: consider refreshing to show the new past/forecast popover, the savings-opportunity card, and the account/region/tag breakdown in the calendar window.
