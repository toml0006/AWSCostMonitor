# App Store Release — v1.7.0

Version **1.7.0**, build **12** (build number is overridden by Xcode Cloud's `CI_BUILD_NUMBER` if built there). Scheme: **`AWSCostMonitor`** (App Store, includes the $3.99 Team Cache in-app purchase). Configuration: **Release**.

## Build & upload

### Option A — Xcode Cloud (primary)

Xcode Cloud builds the `AWSCostMonitor` scheme per the App Store Connect workflow and uploads to App Store Connect / TestFlight automatically. Confirm a 1.7.0 build appears under **App Store Connect → Xcode Cloud** and **TestFlight**.

### Option B — Local archive (currently NOT possible on this machine)

Verified 2026-07-25: a local App Store archive cannot be produced here.

- **No Mac Installer Distribution certificate.** `security find-identity -v` lists only `Developer ID Application`, `Apple Development`, and `Apple Distribution`. Signing the App Store `.pkg` requires a `3rd Party Mac Developer Installer` / `Mac Installer Distribution` identity.
- **No provisioning profile for `middleout.AWSCostMonitor`.** The only `match AppStore` profiles installed target `com.cibo.marketplace`, a different app.

Either use Xcode Cloud (Option A), or install the missing installer certificate and an App Store profile for this bundle ID first. This is the same class of problem that blocked v1.4–v1.6.

## App Store Connect — "What's New in This Version"

```
What's New in v1.7

• AWS SSO support — profiles that use `sso_session` (AWS IAM Identity Center) now work. Sign in from the app itself, or reuse the session you already created with `aws sso login`.
• Assume-role profiles — profiles using `role_arn` with `source_profile` now resolve, including chains that start from an SSO login.
• Sessions are managed in Settings, showing which SSO sessions are signed in and when each expires.
• Expired credentials now say so directly in the popover, with a Sign In button, instead of showing zeroes.
• Fixed the popover being cut off at the right edge of the screen when the menu bar icon sits near the corner.
• Fixed SSO session blocks in ~/.aws/config appearing in the profile picker as unusable entries.
```

## Notes for App Review

> Paste into **App Store Connect → Version 1.7.0 → App Review Information → Notes**.

```
ABOUT THE APP
AWSCostMonitor is a menu bar app that displays your AWS month-to-date spend. It reads your existing local AWS CLI configuration (~/.aws/config and ~/.aws/credentials) and calls the AWS Cost Explorer API directly from the user's machine. There is no account, login, or server — all data stays local.

TESTING WITHOUT AN AWS ACCOUNT
The app requires AWS credentials with Cost Explorer read permission, which the review team may not have. No credentials are needed to evaluate the UI: on the first-run onboarding screen tap "Use Demo Data" (or "Continue with demo data instead" on the AWS-folder access prompt). The menu bar, popover, and calendar/breakdown views then render with representative sample figures. Live numbers require a configured AWS profile in ~/.aws.

FILE ACCESS (SANDBOX)
The app is sandboxed. On first run it asks the user to grant read access to the ~/.aws folder using the standard open-file panel; access is then persisted with a security-scoped bookmark (com.apple.security.files.user-selected.read-only + bookmarks.app-scope). The app only reads AWS config/credentials — it never writes to them. This is unchanged in 1.7.0: the new SSO feature reads the AWS CLI's existing token cache at ~/.aws/sso/cache but never writes to it, which is why the entitlement remains read-only.

NEW IN 1.7.0 — AWS SSO SIGN-IN OPENS A BROWSER
This version adds support for AWS IAM Identity Center (SSO) profiles. Signing in uses the standard OAuth 2.0 Device Authorization flow: the app calls AWS's SSO OIDC service, then opens the user's default browser to the AWS-hosted approval page (e.g. https://<your-directory>.awsapps.com/start/...) so the user can approve the request with their own organization's identity provider. The app never sees or handles the user's password — approval happens entirely in the browser against AWS. On approval the app receives a short-lived token.

Tokens obtained this way are stored in the macOS Keychain (kSecClassGenericPassword, service "dev.middleout.AWSCostMonitor.sso"), NOT written to disk and NOT written into the AWS CLI's own cache.

NEW IN 1.7.0 — ADDITIONAL NETWORK ENDPOINTS
Outbound HTTPS only. In addition to the existing AWS endpoints (Cost Explorer, Savings Plans, STS, and optionally S3 for Team Cache), 1.7.0 may contact:
  • oidc.<region>.amazonaws.com — AWS SSO OIDC, for the device-authorization sign-in and token refresh
  • portal.sso.<region>.amazonaws.com — AWS SSO, to exchange an SSO token for temporary role credentials
Both are AWS-operated endpoints reached directly from the user's machine. There are still no analytics, telemetry, or third-party services. ITSAppUsesNonExemptEncryption is false (standard HTTPS only).

NEW IN 1.7.0 — ASSUME-ROLE PROFILES
Profiles configured with role_arn + source_profile now resolve via sts:AssumeRole, including chains whose source is an SSO profile. Read-only; used solely to obtain credentials for the Cost Explorer read calls.

IN-APP PURCHASE
"Team Cache" is a $3.99 non-consumable that lets teams share cost data through their own AWS S3 bucket to reduce API calls. All core cost-monitoring features work without the purchase. The purchase requires the user's own AWS S3 bucket; it does not unlock any Apple-hosted content. Unchanged in 1.7.0.

CONTACT
Happy to provide a test AWS profile or a screen recording on request.
```

## Privacy / data

- **Data collection:** none. No analytics, no telemetry, no accounts.
- App Privacy nutrition label: **Data Not Collected** (unchanged).
- SSO tokens are stored in the user's macOS Keychain and never leave the machine except to AWS's own endpoints.

## Pre-release checklist

- [x] `MARKETING_VERSION` = `1.7.0` (all targets)
- [ ] `CURRENT_PROJECT_VERSION` = `12` (or Xcode Cloud-managed)
- [x] Both schemes compile (`AWSCostMonitor`, `AWSCostMonitor-OpenSource`)
- [x] Entitlements unchanged — still `files.user-selected.read-only`
- [x] 118 XCTest assertions pass headlessly (`scripts/run-tests.sh`)
- [ ] **Full suite run in Xcode (Cmd-U)** — 2 XCTest classes and 8 swift-testing suites cannot run headlessly, see below
- [ ] **Popover clipping verified visually** — the fix is geometric and has no automated coverage
- [ ] **SSO verified against a real AWS account** — see "Unverified" below
- [ ] CHANGELOG + website updated
- [ ] Build appears in App Store Connect / TestFlight
- [ ] "What's New" pasted
- [ ] App Review notes pasted
- [ ] Screenshots — consider adding the Settings SSO session list
- [ ] Submit for review

## Unverified at time of writing — read before submitting

These are gaps in verification, not known defects. They are listed so the decision to ship is made knowingly.

1. **No SSO sign-in has ever succeeded end to end.** Every credential test uses injected fakes. On the build machine the `ams` SSO token was expired and its CLI refresh token was rejected by AWS (`InvalidGrantException`), so the live path — device-authorization sign-in → `GetRoleCredentials` → `GetCostAndUsage` — has never run. To close this: run `aws sso login --sso-session <name>`, launch the app, select an SSO profile, and confirm a real dollar figure appears. Then sign out and use the app's own Sign In button to exercise the in-app flow.
2. **The popover clipping fix has not been looked at.** It is verified by 11 unit tests over the pure geometry, but placement itself is untested. Check with the menu bar icon near the right corner, on a second display, and while switching to a profile with more digits.
3. **10 test classes did not run headlessly.** `AWSManagerProfileTests` and `TeamCacheUITests` throw `bundleProxyForCurrentProcess is nil` under `xcrun xctest`; 8 swift-testing suites are outside `xctest` entirely. One `Cmd-U` in Xcode covers all of them.

## Notes

- The App Store build uses the **`AWSCostMonitor`** scheme (NOT `-OpenSource`).
- Design and implementation records: `docs/superpowers/specs/2026-07-25-sso-and-popover-clamp-design.md`, `docs/superpowers/plans/2026-07-25-sso-and-popover-clamp.md`.
- SSO tokens minted by the app go to the Keychain rather than `~/.aws/sso/cache`, deliberately, to keep the sandbox entitlement read-only. Consequence: an in-app sign-in does not refresh the user's `aws` CLI session, and Settings' Sign Out is disabled when the usable token belongs to the CLI rather than the app.
