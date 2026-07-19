# Spectrum Theme — Design

> Date: 2026-07-14
> Status: Approved, implementing

## Goal

Add a vivid, colorful accent theme that matches the app icon's aesthetic: a
dark background with a glowing neon sparkline that gradients
green → yellow → orange → hot-magenta.

## Model

Represented as **one new accent value** `.spectrum`, not a new appearance axis.
It's a specific cohesive look, not a modifier you'd combine with Amber. Fits the
existing accent row as one more swatch — auto-rendered via
`LedgerAccent.allCases`, zero new UserDefaults/env plumbing. All vivid behavior
gates on `accent == .spectrum`.

### Palette (from the icon)

| Role | Dark | Light |
|------|------|-------|
| Gradient stop 1 (green) | `#5FE39A` | `#5FE39A` |
| Gradient stop 2 (yellow) | `#FFD84D` | `#FFD84D` |
| Gradient stop 3 (orange) | `#F5A623` | `#F5A623` |
| Gradient stop 4 (magenta) | `#FF2D9B` | `#FF2D9B` |
| Base accent (solid fallback) | `#FF2D9B` | `#B0186A` |
| signalOver (neon) | `#FF3B6B` | `#C21F4E` |
| signalUnder (neon) | `#3DE8A0` | `#12875A` |

Base accent is used everywhere a single color is needed (hero numbers, chevrons,
selection rings, and the **menu-bar sparkline** — which stays solid magenta).

## Token changes (`LedgerTokens.Color`)

- `accent()`: add `.spectrum` case → magenta base (dark/light).
- New `accentGradient(_:) -> [Color]?` — 4 stops for `.spectrum`, `nil`
  otherwise. Callers fall back to solid `accent()` when nil, so nothing breaks.
- `signalOver` / `signalUnder`: leading `if a.accent == .spectrum` branch
  returning the neon pair; else existing color-scheme logic. Non-spectrum
  accents unchanged.
- New `.spectrumGlow(a, color:)` view modifier — layered
  `.shadow(radius: 4)` + `.shadow(radius: 8)` at ~0.6 opacity, applied only when
  `accent == .spectrum`. Subtle "lit," not "blurry."

## View changes

- `Popover/HeroSplit.swift` — `Sparkline`: when `accentGradient` is non-nil,
  fill bars via a per-bar sample of a left→right `LinearGradient`
  (green at oldest day → magenta at newest, mirroring the icon's rising line);
  apply `spectrumGlow`. Highlight bar keeps full alpha; others 0.5 as today.
  Hero number gets `spectrumGlow` when spectrum.
- `Views/AppearanceSettingsTab.swift` — `AccentSwatch` renders the gradient in
  the preview circle for `.spectrum` (so the swatch itself shows the multi-hue).

## Explicitly out of scope

- **Menu-bar sparkline** (`MenuBarSparklineImage` / `MenuBarPresenter`):
  left solid magenta. Gradient smears and blur costs a CIFilter pass every
  render at 60×14; legibility in the system menu bar wins.

## Verification

- Unit: `accentGradient` returns 4 stops for `.spectrum`, nil for others;
  `accent` / `signalOver` / `signalUnder` return spectrum hues. Pure token
  tests, no UI.
- Build: `xcodebuild` app target.
- Visual: run app → Settings → Appearance → Spectrum swatch → confirm popover
  sparkline gradient + glow, hero magenta, menu-bar solid magenta. Screenshot.
