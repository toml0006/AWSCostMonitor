# Ledger Design System — Full Identity Refresh

**Status:** Approved design, ready for implementation planning
**Date:** 2026-04-15
**Scope:** App icon, menu bar, popover, all NSWindows, onboarding, and marketing website

## Summary

Replace the app's eight competing themes with a single opinionated design language called **Ledger**. Dark-and-light first-class, warm graphite + warm cream surfaces, one saturated accent (amber `#F5B454`), SF Mono figures with tabular numerals, and a dense "Command"-style popover inspired by trading terminals. Red and green appear only as *meaningful* signal — never decoration.

Ledger becomes the default and only shipping theme. The existing multi-theme picker is removed; the "Appearance" settings tab collapses to Ledger-specific controls.

## Goals

1. Functional value first: faster cost awareness, clearer hierarchy, fewer taps to the thing that matters.
2. A single opinionated visual identity that the app can be recognized by in a screenshot.
3. Full light/dark parity that follows the system setting.
4. No hardcoded colors or font sizes in views — everything reads from `LedgerTokens` / a single `Theme` struct.
5. Consistent application across app icon, menu bar, popover, all secondary windows, onboarding, and the marketing website.

## Non-goals

- New data-visualization *choice* for the Calendar window interior (picked in a later spec).
- Net-new features. This is a visual-system spec; no new product capabilities.
- Motion system beyond hover/focus transitions.
- Per-service deep-dive screens.
- Retaining the previous theme catalog (Classic, Modern, High Contrast, Compact, Comfortable, Terminal, Professional, Memphis) — they are removed.

## Section 1 — Brand posture

### Palette

**Dark (default on dark system):**

| Token | Hex | Use |
| --- | --- | --- |
| `surface/window` | `#0F1114` | Popover and window base |
| `surface/elevated` | `#14181E` | Cards, hero split, pill interiors |
| `surface/hairline` | `#1C2026` | 1pt dividers |
| `accent/amber` | `#F5B454` | Hero figure, primary action, sparkline, "on" states |
| `signal/over` | `#FF7A7A` | Over-budget, positive cost delta |
| `signal/under` | `#4AD6A3` | Under-budget, negative cost delta |
| `ink/primary` | `#E7E9EC` | Primary text |
| `ink/secondary` | `#A8B1BD` | Body text |
| `ink/tertiary` | `#7F8A99` | Labels, meta |

**Light (default on light system):**

| Token | Hex | Use |
| --- | --- | --- |
| `surface/window` | `#FAF7F2` | Popover and window base |
| `surface/elevated` | `#F1ECE1` | Cards, hero split, pill interiors |
| `surface/hairline` | `#E5DDC9` | 1pt dividers |
| `accent/amber` | `#8A5A14` | Darker amber for AAA contrast on cream |
| `signal/over` | `#B02020` | Over-budget, positive cost delta |
| `signal/under` | `#2F9E6B` | Under-budget, negative cost delta |
| `ink/primary` | `#1B1A17` | Primary text |
| `ink/secondary` | `#3A3731` | Body text |
| `ink/tertiary` | `#8A7F6C` | Labels, meta |

**Rules:**
- Amber appears *only* on: hero figure, menu-bar mark, sparkline/bar fills, primary action, "on" states.
- Signal red/green appear *only* when they carry meaning (budget state, delta direction).
- No ad-hoc colors anywhere in view code.

### Typography

| Role | Font | Size | Weight | Tracking | Numerals |
| --- | --- | --- | --- | --- | --- |
| Hero figure | SF Mono | 34pt | 300 | -0.02em | Tabular |
| Stat value | SF Mono | 11–16pt | 500 | -0.005em | Tabular |
| Label (uppercase) | SF Pro Text | 10pt | 600 | 0.12em | — |
| Body | SF Pro Text | 13pt | 400 | 0 | — |
| Meta | SF Pro Text | 11pt | 400 | 0 | Tabular for any numeric |
| Button | SF Pro Text | 11pt | 500 | 0 | — |

- Every dollar figure, percentage, timestamp, and count uses SF Mono with `font-variant-numeric: tabular-nums`.
- No hardcoded `.font(.system(size: N))` in views after migration.

### Surface elevation

Three levels, no shadows. Differentiation is by subtle surface lightness shift and a 1pt hairline. No translucency/Material — keeps rendering predictable across macOS versions and avoids reintroducing the Tahoe layout-cycle crash path.

### Hover & focus

Row-level hover: `rgba(255,255,255,.04)` (dark) / `rgba(0,0,0,.03)` (light). Primary buttons lighten amber by 8%. Focus ring: 2pt amber at 40% alpha, offset 2pt. All implemented as a single `LedgerHover` view modifier — no per-view `@State` hover flags.

## Section 2 — Menu bar

### Presets (user selects one)

- **A · Text only** — figure in ink primary.
- **B · Icon + figure** *(default)* — template bar-chart glyph left of figure, both rendered in system tint (macOS auto-tints for light/dark bar).
- **C · Amber pill** — figure inside a filled amber rounded-rect pill (6pt radius).
- **D · Figure + sparkline** — figure followed by a 60pt-wide 10-day inline sparkline, today's bar at 100% opacity.

### Orthogonal toggles

- **Hide cents** — `$2,847.23` → `$2,847`.
- **Show delta** — appends `↑2.1%` after figure; color follows delta direction (signal red/green).
- **Auto-abbreviate above $10k** — `$12,400` → `$12.4k`.

### Budget-aware tinting

When profile budget > 100%: amber everywhere in the menu bar (icon, text, pill fill) shifts to `signal/over`. Returns to amber when usage drops.

### Template icon

16×16 monochrome PDF: three ascending bars, 2pt wide each, 1pt gap, heights 40% / 70% / 95%. macOS templates auto-invert for dark/light bars — no per-mode asset.

## Section 3 — Popover (Command layout)

Fixed size: **360 × 440pt**. No scroll. Opens as a detachable `NSPopover` (behavior unchanged from today).

### Anatomy

```
┌──────────────────────────────────────────────┐
│ ● production             ▾    us-east-1     │  36pt — Profile row
├──────────────────────────────────────────────┤
│ MTD                  │ Δ vs last   +12.4%   │
│                      │ Forecast    $4,812   │
│ $2,847.23            │ Last mo     $4,103   │  120pt — Hero split
│ ▃▃▅▅▇▇██ (sparkline) │ Burn / day  $203.37  │
│                      │ Budget      57%      │
│                      │ Updated     09:42    │
├──────────────────────────────────────────────┤
│ EC2         42%                   $1,206.00 │
│ RDS         29%                     $812.40 │
│ S3          13%                     $372.15 │  180pt — Service list (6 rows)
│ CloudFront   8%                     $241.80 │
│ Lambda       5%                     $148.22 │
│ Other        3%                      $66.66 │
├──────────────────────────────────────────────┤
│ [ Refresh ]  [ Calendar ]  [ Console ]  [⋯] │  44pt — Footer
└──────────────────────────────────────────────┘
```

### Interaction

- Profile name is a `MenuPicker` styled as a plain button; the `▾` is the affordance.
- Hero figure is selectable (copy as plain text).
- Forecast value shows a tooltip on hover: *"AWS Cost Explorer forecast"* or *"Estimated at current rate"*.
- Clicking "Updated HH:MM" opens refresh settings (preserves current behavior).
- Clicking a service row opens the Calendar window filtered to that service.
- `⋯` overflow menu items: Settings, Help, Export, Quit.
- Hover state: whole-row highlight only; no per-button hover state in code.
- When Team Cache is enabled, a small `◉ Team` amber pill appears in the profile row; the separate team-cache status panel is removed.

### Removed from the current popover

- The collapsible "Services" expand/collapse — always visible, capped at 6.
- The DEBUG force-refresh banner — moved to a debug-only item in `⋯`.
- Inline per-service histograms (`RealHistogramView`) — moved into the Calendar window.
- The bottom `TeamCacheStatusView` — collapsed into the profile-row pill.

## Section 4 — Other surfaces

All secondary windows keep their current sizes (set during the v1.4.2 crash fix) and inherit Ledger tokens. None get bespoke redesigns; they apply the same type, surface, and signal rules.

### Settings (600 × 450, resizable)
- Sidebar: 160pt, category list, selected row gets amber 2pt left-border accent.
- Right pane: grouped sections, SF Pro Text labels, SF Mono for numeric inputs.
- Primary actions amber; destructive red.
- New **Appearance** section contains: menu-bar preset, hide-cents, show-delta, auto-abbreviate, light/dark override (`System` / `Always light` / `Always dark`).
- Theme picker is removed.

### Calendar window (900 × 700)
- Inherits chrome: header bar with month navigation, summary strip (MTD · Forecast · Peak · Avg), amber hero figure.
- Visualization *interior* — heat grid vs ledger table vs stacked columns — picked in a follow-up spec. Window shell and summary strip land in this spec.

### Multi-Profile Dashboard (800 × 600)
- Grid of profile cards, 180pt tall each, shown 2-up.
- Each card is a mini hero-split: profile name, MTD figure, delta pill, sparkline, forecast.
- Default sort: MTD descending. Clicking a card makes it the active profile and closes the window.

### Onboarding (700 × 550)
- Three steps: welcome → profile selection → budget setup.
- Left side: oversized amber wordmark on graphite. Right side: step content.
- Uses the same card and input components as Settings — nothing bespoke.

### Profile change alerts (450 × 400 and 550 × 500)
- Keep the fixed-size windows from the v1.4.2 crash fix.
- Swap chrome to Ledger tokens (graphite/cream surface, amber primary button, SF Pro Text body, SF Mono for any figures).

### Help (700 × 500)
- Two-column: sidebar table of contents + article pane.
- SF Mono for keyboard shortcuts rendered as `⌘R`-style pills.
- Amber for links.

### Export (500 × 600)
- Table of recent exports (mono figures), format chooser (CSV / JSON), primary amber "Export" button.

## Section 5 — App icon & website

### App icon

- **Concept:** a warm-cream ledger-paper square with thin horizontal ruling lines, tilted 6° counter-clockwise, overlaid by an amber three-bar ascending chart. Reads as "ledger" and "cost trend" at any size.
- **Sizes:** full set from 16×16 to 1024×1024. At 16–32pt the ruling lines drop out; only the paper square + bar chart remain.
- **Dock icon:** same ledger-paper square, full-bleed without tilt, subtle inner shadow, macOS-standard rounded-square mask.
- **Menu-bar template icon:** the 3-bar glyph alone, monochrome PDF, auto-tinted by macOS.

### Website

Located in `packages/web/` (existing marketing site).

- Tokens match the app: warm cream light-mode default, graphite dark, amber accent, SF Mono for figures.
- Hero section: oversized SF Mono hero number animates on scroll; same sparkline treatment as the popover.
- Replace the Memphis feature card with a "What's new in v1.5 — Ledger" card.
- Regenerate all product screenshots at 2x using the new popover, calendar, and dashboard.
- Changelog and docs keep SF Pro Text; mono for CLI/code.
- Footer: ledger wordmark, amber link treatments.

## Architecture & implementation notes

### Token layer

New `Managers/LedgerTokens.swift`:

```swift
enum LedgerTokens {
    enum Color {
        static func surfaceWindow(_ scheme: ColorScheme) -> SwiftUI.Color { … }
        static func accent(_ scheme: ColorScheme) -> SwiftUI.Color { … }
        static func signalOver(_ scheme: ColorScheme) -> SwiftUI.Color { … }
        // …
    }
    enum Typography {
        static let hero = Font.system(size: 34, weight: .light, design: .monospaced)
        static let statValue = Font.system(size: 14, weight: .medium, design: .monospaced)
        static let label = Font.system(size: 10, weight: .semibold).leading(.tight)
        // …
    }
    enum Layout { … }
}
```

Views consume tokens through a `.ledger()` view modifier and `@Environment(\.colorScheme)` — no manual switches in view code.

### Existing theme system

Delete:
- `Models/Theme.swift` (Classic, Modern, High Contrast, Compact, Comfortable, Terminal, Professional, Memphis).
- `Managers/ThemeManager.swift`.
- `Utilities/ThemeExtensions.swift` (`.themeFont`, `.themePadding`) — replaced by `LedgerTokens` + `.ledger()`.
- `Views/AppearanceSettingsTab.swift` theme picker UI (keep the tab, replace contents with Ledger controls).

Migrate every hardcoded `.font(.system(size: N))`, `.foregroundColor(.blue)`, `Color.gray.opacity(...)`, and hairline `Color(NSColor.separatorColor)` call to `LedgerTokens`.

### Menu-bar presets

New `Managers/MenuBarPresenter.swift`:
- `enum MenuBarPreset { case textOnly, iconFigure, amberPill, figureSparkline }`
- `struct MenuBarOptions { hideCents, showDelta, autoAbbreviate, appearanceOverride }`
- Renders `NSStatusItem.button` content from state, handles budget-aware tint, subscribes to profile/cost changes.

`Models/CostModels.swift` already produces the MTD amount and sparkline data points; no model changes needed.

### Popover rewrite

`Views/PopoverContentView.swift` is fully rewritten against the new components:
- `ProfileRow`
- `HeroSplit(mtd:, sparkline:, kvPairs:)`
- `ServiceList(rows:, onSelect:)`
- `FooterActions`

Size constraint: `.frame(width: 360, height: 440)` — no scroll view.

### Crash-fix preservation

All `NSHostingController` + `NSWindow` sites keep `hostingController.sizingOptions = []` and explicit `contentRect:` from the v1.4.2 crash fix. Any new hosting-controller windows added in this work follow the same pattern.

### Light/dark strategy

All views read `@Environment(\.colorScheme)`. Tokens compute per-scheme values. A user-visible "Appearance" override in Settings (`System` / `Always light` / `Always dark`) sets a `.preferredColorScheme(...)` at the app root.

## Migration & rollout

- Ships as app version **1.5.0**.
- In-app "What's New" dialog on first launch of 1.5 explains the redesign and points at the Appearance settings.
- User's previous selected theme is silently discarded; new installs and upgrades both land on Ledger with preset B (Icon + figure).
- Existing budget, profile, team-cache, and export settings are preserved untouched.

## Open follow-ups (out of scope here)

- Calendar-interior visualization choice (heat grid / ledger table / stacked columns) — separate spec.
- Motion language for number transitions (e.g., count-up on refresh).
- Per-service deep-dive screens.
- Tag-based cost breakdown visual treatment.
