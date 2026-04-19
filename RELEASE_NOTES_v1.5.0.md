# Release v1.5.0 — Ledger: A Refreshed Visual Identity

## What's New

AWSCostMonitor v1.5 introduces **Ledger**, a ground-up redesign focused on making the menu bar readable, tunable, and at home on any display.

One opinionated identity, four orthogonal controls.

## Features

- **Ledger Design System** — Accent (Amber · Mint · Plasma · Bone · System), Density (Comfortable · Compact), Contrast (Standard · WCAG AAA), and Color Scheme (System · Light · Dark) are now independent axes you can mix freely.
- **Pill Menu Bar with Sparkline** — Turn on the accent-colored pill for an at-a-glance MTD chip. A luminance-aware ink color picks black or white automatically so the number stays legible on any accent.
- **WCAG AAA Contrast Mode** — One toggle produces sharper type, stronger separators, and AAA-grade pairings for bright rooms or external displays.
- **HeroSplit Popover** — The popover now pairs a large MTD hero number with a right-hand detail column, plus a sparkline range toggle and per-service sparklines rendered inline in the service list.
- **What's New in Ledger** — A one-time welcome on first launch points you to Settings → Appearance to tune the new axes.

## Improvements

- Per-service sparklines (14-day, 0.22 opacity) now appear inline in the service list.
- Settings → Appearance consolidates accent, density, contrast, and color scheme into a single tab.
- Legacy theme preferences from pre-1.5 installs migrate on first launch.

## Bug Fixes

- Fixed a profile-change alert that could flash briefly on every launch after adopting the App Sandbox.
- New AWS profiles are now added silently to the dropdown instead of re-prompting each time the config file changes.
- Pre-sandbox profile visibility settings now migrate forward so already-known profiles aren't re-flagged as "new."

## Requirements

macOS 13.0 or later. Apple Silicon and Intel.

---

## App Store Connect — "What's New" copy

Paste into App Store Connect → Version 1.5.0 → What's New in this Version.

### Short (recommended — first ~170 chars surface in Updates tab)

```
Meet Ledger — a refreshed visual identity for AWSCostMonitor. Tune four independent axes (accent, density, contrast, color scheme) and get a new menu bar pill with an inline 14-day sparkline.
```

### Full

```
What's New in v1.5 — Ledger

• Ledger design system — one identity, four orthogonal controls: accent, density, contrast, and color scheme
• Pill menu bar with an inline 14-day sparkline and luminance-aware ink that stays readable on any accent
• WCAG AAA contrast mode for sharper type and stronger separators
• HeroSplit popover with a large MTD hero number and per-service sparklines
• "What's New in Ledger" welcome points you to Settings → Appearance

Bug Fixes
• Fixed a profile-change alert that could briefly flash at launch
• New AWS profiles are now added silently instead of prompting each time
• Pre-sandbox preferences migrate forward so known profiles aren't re-flagged as new
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
           -archivePath build/AWSCostMonitor-v1.5.0.xcarchive
```

### Export for App Store

```bash
xcodebuild -exportArchive \
           -archivePath build/AWSCostMonitor-v1.5.0.xcarchive \
           -exportPath build/AppStore-v1.5.0 \
           -exportOptionsPlist ExportOptions-AppStore.plist
```

### Pre-release checklist

- [ ] `MARKETING_VERSION` = `1.5.0` in all targets (already set)
- [ ] `CURRENT_PROJECT_VERSION` incremented
- [ ] Legacy-theme migration tested on a pre-1.5 install
- [ ] Profile-change flash no longer reproduces
- [ ] Appearance tab renders all accent × density × contrast × scheme combinations
- [ ] Menu bar pill is legible on each accent in both light and dark menu bars
- [ ] App signed with App Store distribution certificate

## GitHub Release Instructions

1. Tag `v1.5.0` on main.
2. Release title: `v1.5.0 — Ledger: A Refreshed Visual Identity`.
3. Paste the "What's New" + "Features" + "Bug Fixes" sections above as the description.
4. Attach the signed build artifact.
5. Mark as latest release.

---

## Screenshot Shot List (manual capture)

Automation is unreliable for the menu-bar popover (selection resets and the popover dismisses on focus loss). Please capture these manually on desktop 3 with the `acme` demo profile selected. Target 2× Retina, save as PNG.

1. **`main-interface.png`** (2000×1125) — Popover open, MTD visible, service list expanded with sparklines. Use `acme`.
2. **`menubar-pill.png`** (new) — Tight crop of the menu bar showing the accent pill with sparkline. Capture once for each accent (Amber is default).
3. **`calendar-view.png`** — Calendar window with a full month of color-coded cells.
4. **`day-detail-donut.png`** — Day Detail view with the donut chart and service list visible.
5. **`settings-appearance.png`** (new, replaces `settings-display-format.png` as the hero settings shot) — Settings → Appearance tab showing accent picker, density, contrast, and color scheme controls.
6. **`whats-new-v15.png`** (new) — The "What's New in Ledger" welcome window.
7. **`settings-refresh-rate.png`** — Unchanged; re-capture only if Ledger style has visibly changed it.

Save to `packages/website/public/AWSCostMonitor/screenshots/` and commit.
