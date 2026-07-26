# Changelog

All notable changes to AWS Cost Monitor will be documented in this file.

## [1.8.0] - 2026-07-26

### What's New

**AWS SSO and assume-role support.**

v1.8 makes the app work with how most teams actually authenticate to AWS: IAM Identity Center (`sso_session`) profiles and assume-role (`role_arn` + `source_profile`) profiles now resolve, including chains that start from an SSO login. It also fixes the popover clipping off the right edge of the screen — which v1.7 attempted three times without success.

### Features Added

- **AWS SSO (IAM Identity Center) profiles** — profiles declaring `sso_session`, and legacy profiles inlining `sso_start_url`, now authenticate. The app reads the AWS CLI's existing token cache, so an `aws sso login` session is picked up automatically
- **In-app sign-in** — OAuth 2.0 Device Authorization flow; the app opens your browser to AWS's own approval page. No Terminal required, and the app never handles your password
- **Silent session renewal** — tokens the app minted are refreshed in the background rather than prompting you
- **Assume-role profiles** — `role_arn` with `source_profile` resolves via `sts:AssumeRole`, including multi-step chains sourced from an SSO profile, with cycle and depth detection
- **SSO session management in Settings** — each `sso-session` listed with its state (signed in and expiry, expired, or not signed in) and per-session Sign In / Sign Out
- **Credential errors are visible** — an expired or missing session shows a banner in the popover with a Sign In button instead of silently rendering zeroes

### Bug Fixes

- **The popover no longer runs off the right edge of the screen.** The earlier attempts shrank the popover to fit beside the menu bar icon; because the hero columns have a fixed intrinsic width and SwiftUI does not clip overflow, the squeezed popover spilled its own contents. It is now measured against the display and repositioned rather than shrunk, and the on-screen correction no longer depends on animation timing
- **The popover is correct on the first open** — the width previously crossed from controller to view via `UserDefaults` (asynchronous) while the popover measures synchronously, so an open could use the previous open's width
- **`[sso-session ...]` blocks no longer appear in the profile picker** as unusable entries
- Unsupported profiles (`credential_process`, `mfa_serial`, `role_arn` without `source_profile`, dangling SSO session references) report a specific reason rather than a generic credentials error

### Privacy & security

- Tokens created by the app are stored in the **macOS Keychain**, never written to disk or into the AWS CLI's cache. The app reads `~/.aws` but never writes to it, so the sandbox entitlement remains read-only
- Sharing is one-directional by design: a Terminal `aws sso login` is picked up by the app; an in-app sign-in does not alter your CLI session
- New outbound endpoints, AWS-operated and only for SSO profiles: `oidc.<region>.amazonaws.com` and `portal.sso.<region>.amazonaws.com`
- No new IAM permissions required

## [1.7.0] - 2026-07-21

### What's New

**Spectrum accent theme and stability fixes.**

### Features Added

- **Spectrum accent theme** matching the app icon
- **Quieter popover footer** in the Cadence style — navigation links muted on the left, version and Quit anchored right

### Bug Fixes

- Fixed a crash when switching appearance themes, caused by applying theme changes inside the control's own transaction
- Fixed a crash when closing the Settings window (`isReleasedWhenClosed` double-free)
- Hardened the Spectrum glow against a popover-animation teardown crash
- More legible service rows and a balanced forecast column in the popover
- Initial attempts at fixing right-edge popover clipping — superseded in 1.8.0, which identifies and corrects the actual cause

## [1.6.0] - 2026-06-24

### What's New

**Sharper cost intelligence — and the menu bar tells you what to do about it.**

v1.6 splits the popover into what already happened and what's coming, surfaces AWS's own savings recommendation, and adds account / region / tag breakdowns to the calendar — while fixing the month-over-month delta so the numbers actually line up.

### Features Added

- **Savings Plan purchase recommendation** — the popover shows a lean "SP save / mo" nudge when AWS recommends a purchase; the Calendar window expands it into a full "Savings opportunity" card (commitment, estimated savings %, ROI, term)
- **Real Savings Plan existence check** — `DescribeSavingsPlans` disambiguates "no plan" from "0% covered," so SP cover reads None / Active / % correctly
- **Cost breakdown by account, region, and tag** — a new breakdown switcher in the Calendar window, scoped to the selected month
- **Past / forecast hero split** — the popover separates month-to-date actuals (left) from the month-end forecast (right), with budget moved to the forecast column
- **Sparkline scrubbing** — hover the main sparkline to read any day's total; per-service rows cross-highlight and update to that day, with week and month grid lines
- **Last-updated time** in the popover header

### Improvements

- Forecast carries a good/bad signal color; month boundaries are marked in all sparklines
- Tighter hero stat spacing and a recombined service-row sparkline / percentage
- Cost metrics standardized on AmortizedCost across current month, last month, and every breakdown dimension for consistent totals

### Bug Fixes

- **Month-over-month delta is now AWS-direct MTD-vs-MTD** instead of a locally computed projection, and compares like metrics (AmortizedCost on both sides) — accounts with Savings Plans, Reserved Instances, or credits no longer show skewed deltas
- Calendar cost breakdown follows the selected month instead of always showing the current month
- RI-only accounts fall back to RI coverage instead of reading "SP cover None"
- Savings recommendation nudge clears when AWS stops recommending a purchase

## [1.5.0] - 2026-04-19

### What's New

**Ledger — a refreshed visual identity.**

v1.5 introduces Ledger, a ground-up redesign centered on making the menu bar readable, tunable, and at home on any display. One opinionated identity, four orthogonal controls.

### Features Added

- **Ledger Design System** — Accent (Amber · Mint · Plasma · Bone · System), Density (Comfortable · Compact), Contrast (Standard · WCAG AAA), and Color Scheme (System · Light · Dark) are independent axes
- **Pill Menu Bar with Sparkline** — Optional accent-colored pill renders MTD with a 14-day sparkline and luminance-aware ink that stays legible on any accent
- **WCAG AAA Contrast Mode** — One toggle for sharper type, stronger separators, and AAA-grade pairings
- **HeroSplit Popover** — Large MTD hero number paired with a detail column, plus a sparkline range toggle and per-service sparklines rendered inline
- **"What's New in Ledger" window** — One-time welcome on first launch points to Settings → Appearance

### Improvements

- Per-service sparklines (14-day, 0.22 opacity) now appear inline in the service list
- Settings → Appearance consolidates accent, density, contrast, and color scheme into a single tab
- Legacy theme preferences from pre-1.5 installs migrate on first launch

### Bug Fixes

- Fixed a profile-change alert that could flash briefly on every launch after adopting the App Sandbox
- New AWS profiles are now added silently to the dropdown instead of re-prompting each time the config file changes
- Pre-sandbox profile visibility settings now migrate forward so already-known profiles aren't re-flagged as "new"

## [1.3.2] - 2025-08-19

### 🎉 What's New

**Major visual refresh and team collaboration features!**

We've redesigned the app with professional new icons and added comprehensive team caching support to reduce API costs for organizations.

### ✨ Features Added

- **New Professional App Icons** - Complete redesign with modern, polished look
- **Team Remote Caching** - Share cost data across team using S3 to reduce API calls
- **Comprehensive Setup Guide** - Step-by-step instructions for team cache configuration
- **Enhanced Timer Reliability** - Fixed refresh timer using Timer.scheduledTimer

### 🐛 Bug Fixes

- Fixed refresh timer not firing properly
- Improved timer scheduling for consistent updates

### 🔧 Technical Improvements

- Updated to proper timer implementation with scheduledTimer
- Added comprehensive team cache documentation
- Improved S3 integration for team data sharing
- Enhanced error handling for cache operations

### 📝 Notes

The team cache feature is optional and maintains our privacy-first approach - it uses your existing AWS infrastructure with no third-party services involved.

---

## [1.1.0] - 2025-08-10

### 🎉 What's New

**Your app is now smarter about when to check AWS costs!**

We've added intelligent screen-aware refresh that automatically pauses cost updates when you're not looking. This means:

- 💰 **Lower API costs** - No more checking AWS when your screen is off or Mac is locked
- 🔋 **Better battery life** - The app takes a break when you do
- 🧠 **Smart caching** - Shows your last known costs instead of errors when offline

### ✨ Features Added

- **Screen-aware refresh** - Automatically pauses updates when your display sleeps or system locks
- **User activity detection** - Knows when you've stepped away from your desk
- **Intelligent cache management** - Uses cached data smartly when refresh is paused
- **Comprehensive test coverage** - Added 50+ new tests for reliability

### 🐛 Bug Fixes

- Fixed potential crashes during test execution
- Improved handling of private AppStorage properties in tests
- Better error handling when screen state changes

### 🔧 Technical Improvements

- Added `ScreenStateMonitor` class for system state detection
- Integrated screen state checks into refresh logic
- Enhanced test suite with UI and unit tests for all major features
- Improved refresh rate logic with budget-based intervals

### 📝 Notes

The screen-aware refresh is completely automatic - no configuration needed! Your app will just use less resources and save you money on AWS API calls. It's like having a thoughtful assistant who knows when you're actually at your desk.

---

## [1.0.0] - 2025-08-01

### 🚀 Initial Release

- Menu bar cost display with real-time MTD spending
- Multi-profile support with persistent selection
- Smart refresh intervals based on budget proximity
- Sandbox support for Mac App Store compliance
- ACME demo mode for testing
- Comprehensive logging and debugging tools
- Budget tracking and alerts
- Service cost breakdown
- Historical data tracking
- Anomaly detection
- Help documentation

---

*For more details, visit [awscostmonitor.app](https://awscostmonitor.app)*