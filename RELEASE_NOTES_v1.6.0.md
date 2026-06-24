# Release v1.6.0 — Savings Insights & Cost Breakdowns

v1.6 turns the menu bar from "here's your spend" into "here's what to do about it": it surfaces AWS's own Savings Plan purchase recommendation, adds account / region / tag cost breakdowns to the calendar window, and splits the popover into month-to-date actuals and a month-end forecast — while fixing the month-over-month delta so the numbers actually line up.

## Features Added

- **Savings Plan purchase recommendation** — `ce:GetSavingsPlansPurchaseRecommendation` (Compute SP, 1-year, No Upfront, 30-day lookback). The popover shows a lean "SP save / mo" nudge only when AWS recommends a purchase; the calendar window expands it into a "Savings opportunity" card with the recommended hourly commitment, estimated savings %, ROI, and term.
- **Real Savings Plan existence check** — `savingsplans:DescribeSavingsPlans` disambiguates "no plan" from "0% covered," so SP cover reads None / Active / % correctly.
- **Cost breakdown by account, region, and tag** — a breakdown switcher in the calendar window groups spend by linked account, region, or cost-allocation tag value, scoped to the selected month.
- **Past / forecast hero split** — the popover separates month-to-date actuals (left) from the month-end forecast (right), with budget moved to the forecast column.
- **Sparkline scrubbing** — hover the main sparkline to read any day's total; per-service rows cross-highlight and update to that day, with week and month grid lines.
- **Last-updated time** in the popover header.

## Improvements

- Forecast carries a good/bad signal color; month boundaries are marked in all sparklines.
- Tighter hero stat spacing and a recombined service-row sparkline / percentage.
- All cost metrics standardized on `AmortizedCost` across current month, last month, and every breakdown dimension for consistent totals.

## Bug Fixes

- **Month-over-month delta is now AWS-direct MTD-vs-MTD** instead of a locally computed projection, and compares like metrics (`AmortizedCost` on both sides). Accounts with Savings Plans, Reserved Instances, or credits no longer show skewed deltas.
- Calendar cost breakdown follows the selected month instead of always showing the current month.
- RI-only accounts fall back to RI coverage instead of reading "SP cover None".
- The savings recommendation nudge clears when AWS stops recommending a purchase (rather than persisting a stale value).

## New IAM permissions (optional)

Both are optional — the app degrades gracefully without them:

- `ce:GetSavingsPlansPurchaseRecommendation` — savings recommendation
- `savingsplans:DescribeSavingsPlans` — Savings Plan existence check

## Requirements

macOS 13.0 or later. Apple Silicon and Intel.

---

## App Store Connect — "What's New" copy

Paste into App Store Connect → Version 1.6.0 → What's New in this Version.

### Short (recommended — first ~170 chars surface in Updates tab)

```
v1.6 adds AWS Savings Plan purchase recommendations, account/region/tag cost breakdowns, and a past-vs-forecast popover — plus a fixed month-over-month delta that now matches AWS.
```

### Full

```
What's New in v1.6

• Savings Plan recommendations — a "save / mo" nudge in the menu bar, with commitment, savings %, ROI, and term in the calendar window
• Cost breakdown by account, region, or cost-allocation tag for any month
• Popover split into month-to-date actuals and a month-end forecast, with sparkline scrubbing across per-service rows
• Fixed the month-over-month delta to use AWS-reported month-to-date on both sides — accounts with Savings Plans, RIs, or credits now compare correctly
```

---

## Build & Ship

### Archive

```bash
cd /Users/jackson/dev/middleout/AWSCostMonitor/packages/app/AWSCostMonitor
xcodebuild -project AWSCostMonitor.xcodeproj \
           -scheme AWSCostMonitor \
           -configuration Release \
           archive \
           -archivePath build/AWSCostMonitor-v1.6.0.xcarchive
```

### Export for App Store

```bash
xcodebuild -exportArchive \
           -archivePath build/AWSCostMonitor-v1.6.0.xcarchive \
           -exportPath build/AppStore-v1.6.0 \
           -exportOptionsPlist ExportOptions-AppStore.plist
```

### Pre-release checklist

- [x] `MARKETING_VERSION` = `1.6.0` in all targets
- [x] `CURRENT_PROJECT_VERSION` = `11`
- [x] Debug build compiles (both `AWSCostMonitor` and `AWSCostMonitor-OpenSource` schemes)
- [ ] Archive with Release configuration
- [ ] Validate via App Store Connect
- [ ] Upload via Transporter or Xcode Organizer

## GitHub Release Instructions

The `release.yml` workflow builds and publishes automatically on a `v*` tag push:

1. Merge `worktree-fix-delta-math` → `main`.
2. Tag `v1.6.0` on main and push the tag.
3. CI (macos-14) builds the `AWSCostMonitor-OpenSource` scheme, signs with the Developer ID secrets, and attaches the artifact to a GitHub release.
4. Release title: `v1.6.0 — Savings Insights & Cost Breakdowns`.
5. Mark as latest release.
