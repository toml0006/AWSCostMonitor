# Ledger Plan C — App Icon & Website (v1.5.2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce the Ledger app icon (1024 → 16 and the menu-bar template PDF) and refresh the marketing website so every visible Ledger surface — app, icon, and web — shares tokens.

**Architecture:** Icons are vector-first (SVG → PDF for menu-bar template; SVG → PNG for asset catalog). Website runs on the existing Vite/React stack in `packages/website/`; tokens migrate to CSS custom properties with a dark-preferred `@media (prefers-color-scheme)` switch.

**Tech Stack:** SVG, `rsvg-convert` (or Inkscape CLI) for rasterization, Xcode asset catalog for bundling. React + Vite for the website. Tailwind-free — hand-written CSS or existing project styling — the spec mandates token parity, not framework choice.

**Precondition:** Plans A and B are merged. The app runs end-to-end on Ledger.

**Spec:** `docs/superpowers/specs/2026-04-15-ledger-design-system-design.md` (Section 5)

---

## File structure

**Create:**
- `marketing-materials/icon-src/ledger-icon.svg` — master 1024×1024 SVG.
- `marketing-materials/icon-src/ledger-menubar-template.svg` — 16×16 template glyph.
- `marketing-materials/icon-src/build-icons.sh` — rasterizer script producing every required size.
- `packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset/` — new icon set replacing the current one.
- `packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/MenuBarLedgerMark.imageset/` — already referenced by Plan A Task 6.5; this plan provides the final artwork.
- `packages/website/src/styles/tokens.css` — CSS custom properties mirroring `LedgerTokens`.
- `packages/website/src/components/HeroSparkline.tsx` — animated hero figure + sparkline component.
- `packages/website/src/components/WhatsNewV15Card.tsx`

**Modify:**
- `packages/website/src/App.tsx` (or the existing root; map to repo's actual entry).
- `packages/website/src/components/Hero.tsx` — adopt HeroSparkline.
- `packages/website/src/routes/changelog.*` — add v1.5 entry.
- `packages/website/public/screenshots/` — regenerate 2x screenshots using the app's latest build.
- `packages/website/src/index.css` (or root stylesheet) — import `tokens.css`; strip any legacy theme classes.

**Delete:**
- Any Memphis-specific CSS or hero artwork left over from v1.4.

---

## Phase 1 — Icon artwork

### Task 1.1: Author the master SVG

**Files:**
- Create: `marketing-materials/icon-src/ledger-icon.svg`

- [ ] **Step 1: Write SVG**

```xml
<!-- 1024×1024 Ledger app icon master.
     Cream ledger-paper square, tilted 6° CCW, overlaid with amber ascending 3-bar chart. -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="paper" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FAF7F2"/>
      <stop offset="1" stop-color="#EFE9DB"/>
    </linearGradient>
    <filter id="softShadow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="18" stdDeviation="24" flood-color="#000" flood-opacity="0.22"/>
    </filter>
  </defs>

  <!-- Rounded graphite base (macOS icon mask handles the outer rounded-square; we fill solid). -->
  <rect x="0" y="0" width="1024" height="1024" rx="228" ry="228" fill="#0F1114"/>

  <!-- Tilted ledger paper -->
  <g transform="translate(512 512) rotate(-6) translate(-360 -480)" filter="url(#softShadow)">
    <rect x="0" y="0" width="720" height="960" rx="28" ry="28" fill="url(#paper)"/>
    <!-- Ruling lines -->
    <g stroke="#E5DDC9" stroke-width="2">
      <line x1="40" y1="120" x2="680" y2="120"/>
      <line x1="40" y1="190" x2="680" y2="190"/>
      <line x1="40" y1="260" x2="680" y2="260"/>
      <line x1="40" y1="330" x2="680" y2="330"/>
      <line x1="40" y1="400" x2="680" y2="400"/>
      <line x1="40" y1="470" x2="680" y2="470"/>
      <line x1="40" y1="540" x2="680" y2="540"/>
      <line x1="40" y1="610" x2="680" y2="610"/>
      <line x1="40" y1="680" x2="680" y2="680"/>
      <line x1="40" y1="750" x2="680" y2="750"/>
      <line x1="40" y1="820" x2="680" y2="820"/>
      <line x1="40" y1="890" x2="680" y2="890"/>
    </g>
    <!-- Vertical rule on the left (typical ledger red line, but we keep neutral) -->
    <line x1="120" y1="60" x2="120" y2="920" stroke="#D6CBB0" stroke-width="2"/>
  </g>

  <!-- Amber ascending bar chart -->
  <g transform="translate(300 350)">
    <!-- baseline aligned bars -->
    <rect x="0"   y="220" width="80" height="120" rx="8" fill="#F5B454"/>
    <rect x="120" y="120" width="80" height="220" rx="8" fill="#F5B454"/>
    <rect x="240" y="0"   width="80" height="340" rx="8" fill="#F5B454"/>
  </g>
</svg>
```

- [ ] **Step 2: Preview**

```bash
open marketing-materials/icon-src/ledger-icon.svg
```

- [ ] **Step 3: Commit**

```bash
git add marketing-materials/icon-src/ledger-icon.svg
git commit -m "feat(ledger): app icon master SVG"
```

### Task 1.2: Menu-bar template glyph

**Files:**
- Create: `marketing-materials/icon-src/ledger-menubar-template.svg`

- [ ] **Step 1: Write SVG**

```xml
<!-- 16×16 template glyph. Black-only; macOS tints. -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">
  <g fill="#000">
    <rect x="1"  y="9"  width="3" height="6" rx="1"/>
    <rect x="6"  y="6"  width="3" height="9" rx="1"/>
    <rect x="11" y="2"  width="3" height="13" rx="1"/>
  </g>
</svg>
```

- [ ] **Step 2: Commit**

```bash
git add marketing-materials/icon-src/ledger-menubar-template.svg
git commit -m "feat(ledger): menu-bar template glyph SVG"
```

### Task 1.3: Rasterizer script

**Files:**
- Create: `marketing-materials/icon-src/build-icons.sh`

- [ ] **Step 1: Script that produces every required size**

```bash
#!/usr/bin/env bash
# Produces the full AppIcon.appiconset PNG set + menu-bar template PDF.
# Requires: rsvg-convert (brew install librsvg) and Apple's iconutil.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
ICON_SVG="$SRC/ledger-icon.svg"
TEMPLATE_SVG="$SRC/ledger-menubar-template.svg"
OUT_APP="$SRC/../../packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset"
OUT_TEMPLATE="$SRC/../../packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/MenuBarLedgerMark.imageset"

mkdir -p "$OUT_APP" "$OUT_TEMPLATE"

declare -a sizes=(
  "16"      # 16×16 1x
  "32"      # 16×16 2x AND 32×32 1x
  "64"      # 32×32 2x
  "128"     # 128×128 1x
  "256"     # 128×128 2x AND 256×256 1x
  "512"     # 256×256 2x AND 512×512 1x
  "1024"    # 512×512 2x
)

for s in "${sizes[@]}"; do
  rsvg-convert -w "$s" -h "$s" "$ICON_SVG" -o "$OUT_APP/icon_${s}.png"
done

# Menu-bar template: export at 16 (1x) and 32 (2x) and a PDF master.
rsvg-convert -w 16 -h 16 "$TEMPLATE_SVG" -o "$OUT_TEMPLATE/menu-bar-16.png"
rsvg-convert -w 32 -h 32 "$TEMPLATE_SVG" -o "$OUT_TEMPLATE/menu-bar-32.png"
rsvg-convert -f pdf "$TEMPLATE_SVG" -o "$OUT_TEMPLATE/menu-bar.pdf"

echo "Icons written to $OUT_APP and $OUT_TEMPLATE"
```

- [ ] **Step 2: `chmod +x` and run**

```bash
chmod +x marketing-materials/icon-src/build-icons.sh
marketing-materials/icon-src/build-icons.sh
```

- [ ] **Step 3: Write `Contents.json` for each asset set**

For `AppIcon.appiconset/Contents.json`, use the standard macOS icon manifest mapping:

```json
{
  "images" : [
    { "idiom" : "mac", "size" : "16x16",   "scale" : "1x", "filename" : "icon_16.png" },
    { "idiom" : "mac", "size" : "16x16",   "scale" : "2x", "filename" : "icon_32.png" },
    { "idiom" : "mac", "size" : "32x32",   "scale" : "1x", "filename" : "icon_32.png" },
    { "idiom" : "mac", "size" : "32x32",   "scale" : "2x", "filename" : "icon_64.png" },
    { "idiom" : "mac", "size" : "128x128", "scale" : "1x", "filename" : "icon_128.png" },
    { "idiom" : "mac", "size" : "128x128", "scale" : "2x", "filename" : "icon_256.png" },
    { "idiom" : "mac", "size" : "256x256", "scale" : "1x", "filename" : "icon_256.png" },
    { "idiom" : "mac", "size" : "256x256", "scale" : "2x", "filename" : "icon_512.png" },
    { "idiom" : "mac", "size" : "512x512", "scale" : "1x", "filename" : "icon_512.png" },
    { "idiom" : "mac", "size" : "512x512", "scale" : "2x", "filename" : "icon_1024.png" }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
```

For `MenuBarLedgerMark.imageset/Contents.json`:

```json
{
  "images" : [
    { "idiom" : "universal", "scale" : "1x", "filename" : "menu-bar-16.png" },
    { "idiom" : "universal", "scale" : "2x", "filename" : "menu-bar-32.png" }
  ],
  "info" : { "version" : 1, "author" : "xcode" },
  "properties" : { "template-rendering-intent" : "template" }
}
```

- [ ] **Step 4: Build + verify in-app**

```bash
xcodebuild -scheme AWSCostMonitor -configuration Debug -destination 'platform=macOS' build
```

Launch the app. Menu-bar glyph should appear as three ascending bars, auto-tinted by macOS. The Dock icon and Finder preview should show the tilted ledger paper.

- [ ] **Step 5: Commit**

```bash
git add marketing-materials/icon-src/build-icons.sh \
        packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset \
        packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/MenuBarLedgerMark.imageset
git commit -m "feat(ledger): app icon and menu-bar template asset catalog"
```

---

## Phase 2 — Website tokens

### Task 2.1: tokens.css

**Files:**
- Create: `packages/website/src/styles/tokens.css`

- [ ] **Step 1: Author**

```css
:root {
  /* Dark tokens (default) */
  --surface-window: #0F1114;
  --surface-elevated: #14181E;
  --surface-hairline: #1C2026;
  --accent: #F5B454;
  --signal-over: #FF7A7A;
  --signal-under: #4AD6A3;
  --ink-primary: #E7E9EC;
  --ink-secondary: #A8B1BD;
  --ink-tertiary: #7F8A99;

  --font-mono: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
  --font-sans: -apple-system, "SF Pro Text", "Inter", system-ui, sans-serif;

  --hero-size: 34px;
  --stat-size: 14px;
  --label-size: 10px;
  --body-size: 13px;
  --meta-size: 11px;

  --radius-card: 10px;
  --hairline: 1px;
}

@media (prefers-color-scheme: light) {
  :root {
    --surface-window: #FAF7F2;
    --surface-elevated: #F1ECE1;
    --surface-hairline: #E5DDC9;
    --accent: #8A5A14;
    --signal-over: #B02020;
    --signal-under: #2F9E6B;
    --ink-primary: #1B1A17;
    --ink-secondary: #3A3731;
    --ink-tertiary: #8A7F6C;
  }
}

/* Uppercase label style */
.ledger-label {
  font-family: var(--font-sans);
  font-size: var(--label-size);
  font-weight: 600;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--ink-tertiary);
}

.ledger-hero {
  font-family: var(--font-mono);
  font-size: var(--hero-size);
  font-weight: 300;
  letter-spacing: -0.02em;
  font-variant-numeric: tabular-nums;
  color: var(--accent);
}

.ledger-stat {
  font-family: var(--font-mono);
  font-size: var(--stat-size);
  font-weight: 500;
  font-variant-numeric: tabular-nums;
  color: var(--ink-primary);
}

.ledger-body { font-family: var(--font-sans); font-size: var(--body-size); color: var(--ink-secondary); }
.ledger-meta { font-family: var(--font-sans); font-size: var(--meta-size); color: var(--ink-tertiary); }

.ledger-surface-window   { background: var(--surface-window); }
.ledger-surface-elevated { background: var(--surface-elevated); border: 1px solid var(--surface-hairline); border-radius: var(--radius-card); }
```

- [ ] **Step 2: Import from root stylesheet**

Add `@import "./styles/tokens.css";` at the top of `packages/website/src/index.css` (or the framework's global stylesheet). Delete any lingering Memphis-era classes.

- [ ] **Step 3: Commit**

```bash
git add packages/website/src/styles/tokens.css packages/website/src/index.css
git commit -m "feat(ledger-web): CSS token system with dark-default + prefers-color-scheme"
```

---

## Phase 3 — Hero + sparkline

### Task 3.1: HeroSparkline component

**Files:**
- Create: `packages/website/src/components/HeroSparkline.tsx`

- [ ] **Step 1: Implement**

```tsx
import { useEffect, useRef, useState } from "react";

interface Props {
  total: number;          // e.g., 2847.23
  spark: number[];        // 10 values
}

export function HeroSparkline({ total, spark }: Props) {
  const [displayed, setDisplayed] = useState(0);

  // Count-up animation on mount
  useEffect(() => {
    let raf = 0;
    const start = performance.now();
    const duration = 900;
    const loop = (t: number) => {
      const p = Math.min(1, (t - start) / duration);
      const eased = 1 - Math.pow(1 - p, 3);
      setDisplayed(total * eased);
      if (p < 1) raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, [total]);

  const max = Math.max(...spark, 1);
  return (
    <div className="ledger-surface-elevated" style={{ padding: 24, maxWidth: 420 }}>
      <div className="ledger-label" style={{ marginBottom: 6 }}>Month-to-date</div>
      <div className="ledger-hero">{format(displayed)}</div>
      <div style={{ display: "flex", alignItems: "flex-end", gap: 3, height: 28, marginTop: 12 }}>
        {spark.map((v, i) => (
          <div
            key={i}
            style={{
              width: 6,
              height: Math.max(1, (v / max) * 28),
              background: "var(--accent)",
              opacity: i === spark.length - 1 ? 1 : 0.65,
              borderRadius: 2,
            }}
          />
        ))}
      </div>
    </div>
  );
}

function format(n: number) {
  return n.toLocaleString("en-US", { style: "currency", currency: "USD", minimumFractionDigits: 2, maximumFractionDigits: 2 });
}
```

- [ ] **Step 2: Use in Hero**

Import `HeroSparkline` in the existing hero section, remove the Memphis feature card.

- [ ] **Step 3: Build + preview**

```bash
cd packages/website
npm run dev
```

- [ ] **Step 4: Commit**

```bash
git add packages/website/src/components/HeroSparkline.tsx packages/website/src/components/Hero.tsx
git commit -m "feat(ledger-web): hero sparkline with count-up animation"
```

---

## Phase 4 — What's New v1.5 card + changelog

### Task 4.1: WhatsNewV15Card

**Files:**
- Create: `packages/website/src/components/WhatsNewV15Card.tsx`

- [ ] **Step 1: Implement a static card**

```tsx
export function WhatsNewV15Card() {
  return (
    <article className="ledger-surface-elevated" style={{ padding: 28, maxWidth: 520 }}>
      <div className="ledger-label" style={{ marginBottom: 8 }}>v1.5 · Ledger</div>
      <h3 className="ledger-hero" style={{ marginBottom: 12 }}>Designed for people who live in numbers.</h3>
      <p className="ledger-body">
        A single opinionated identity with four orthogonal controls — accent, density, contrast, and light/dark.
        Mono-figure typography with tabular numerals, a dense trading-terminal popover, and amber where it matters.
      </p>
    </article>
  );
}
```

- [ ] **Step 2: Replace Memphis feature card with this on the home page**

- [ ] **Step 3: Append v1.5.0 to the changelog**

Use the existing changelog's data shape; add an entry dated `2026-04-15` that reads:

> **Ledger** — A full identity refresh. New tokenized design system, 4 menu-bar presets, 4 accents, 2 densities, AAA-contrast toggle. Legacy themes migrated automatically.

- [ ] **Step 4: Commit**

```bash
git add packages/website/src/components/WhatsNewV15Card.tsx
git commit -m "feat(ledger-web): v1.5 what's-new card + changelog entry"
```

---

## Phase 5 — Screenshot regeneration

### Task 5.1: Capture and replace screenshots

**Files:**
- Replace files in: `packages/website/public/screenshots/`

- [ ] **Step 1: Prepare a seeded demo profile**

Launch the app with the `acme` demo profile active (already exists in the codebase). Make sure:
- Menu bar shows preset B (default).
- Popover opens with the new Command layout.
- Calendar window opens with SummaryStrip visible.
- Multi-Profile Dashboard shows cards sorted MTD desc.

- [ ] **Step 2: Take 2× screenshots at native retina**

Use `screencapture -R <x,y,w,h>` or `⌘⇧4`. Required shots:
- `menubar-dark.png` and `menubar-light.png` (32pt tall, 400pt wide).
- `popover-dark.png` and `popover-light.png` (360×440).
- `calendar-dark.png` and `calendar-light.png` (900×700).
- `dashboard-dark.png` and `dashboard-light.png` (800×600).
- `onboarding-dark.png` (700×550).

Save all as 2× PNG (`@2x` suffix is inferred by file resolution).

- [ ] **Step 3: Replace files and update `<img srcset>` if present**

Delete any `memphis-*.png` or `classic-*.png` artifacts from previous releases.

- [ ] **Step 4: Commit**

```bash
git add packages/website/public/screenshots/
git commit -m "chore(ledger-web): regenerate 2x screenshots for v1.5"
```

---

## Phase 6 — Version bump

### Task 6.1: Bump app version

```bash
cd packages/app/AWSCostMonitor
agvtool new-marketing-version 1.5.2
agvtool new-version -all 10
git commit -am "chore: bump version to 1.5.2 (build 10)"
```

### Task 6.2: Bump website version (if separately versioned)

If the website's `package.json` carries its own version, bump to `1.5.2` to match.

```bash
cd packages/website
npm version 1.5.2 --no-git-tag-version
git commit -am "chore(web): version 1.5.2"
```

---

## Acceptance

- [ ] App icon renders as tilted ledger-paper + amber bar chart at every size (16 → 1024). Verify in Finder Get Info, the Dock, and the menu bar.
- [ ] Menu-bar template glyph auto-tints correctly on dark and light menu bars.
- [ ] `packages/website` builds (`npm run build`) and runs (`npm run dev`) without errors.
- [ ] Website tokens live in `tokens.css`; no component references raw theme colors.
- [ ] `@media (prefers-color-scheme: light)` switches the site to cream/ink without layout shift.
- [ ] Hero shows the animated count-up + sparkline on page load.
- [ ] Changelog shows v1.5 entry with a concise "Ledger" summary.
- [ ] Legacy screenshot files (Memphis, Classic) removed from `public/screenshots/`.
- [ ] Full asset catalog contains no leftover AppIcon PNGs from the previous icon.

---

## Out-of-scope follow-ups

- Calendar-interior visualization choice (heat grid vs ledger table vs stacked columns) — separate spec.
- Motion language beyond the hero count-up and row hover.
- App Store screenshots — distinct from website screenshots; treat as a separate marketing task.
- Favicon refresh — if the website doesn't already use the ledger icon, generate a favicon set from `ledger-icon.svg` in a follow-up.
