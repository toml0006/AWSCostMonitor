# Ledger Plan A — Foundation & Primary Surfaces (v1.5.0)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 8-theme system with the Ledger design system (amber-accented, mono-figure, dense "Command" popover), migrate existing users to best-fit appearance tuples, and rewrite the menu bar + popover + Settings Appearance tab against tokenized views.

**Architecture:** A single `LedgerAppearance` value (`colorScheme`, `accent`, `density`, `contrast`) resolved by `AppearanceManager` flows through the SwiftUI environment. `LedgerTokens` answer questions about that appearance (colors, fonts, layout units). Views never inspect raw state — they call tokens via `.ledgerHero()`, `.ledgerSurface(.elevated)` etc. Legacy themes are deleted; a one-shot migrator maps previously-selected themes to the new axes.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit (`NSStatusItem`, `NSPopover`), XCTest. macOS 13.0+.

**Spec:** `docs/superpowers/specs/2026-04-15-ledger-design-system-design.md`

**Pre-existing failing tests to skip during this plan:** See `docs/superpowers/follow-ups/2026-04-15-test-infra-cleanup.md`. Every test command in this plan that runs the full suite MUST append these `-skip-testing` flags:

```
-skip-testing:AWSCostMonitorTests/AWSManagerProfileTests/testRemovedProfileWithPreservedData \
-skip-testing:AWSCostMonitorTests/AWSManagerProfileTests/testUpdateProfileVisibilityRefreshesProfilesList \
-skip-testing:AWSCostMonitorTests/AWSCostMonitorTests/testAWSManagerTimerManagement \
-skip-testing:AWSCostMonitorTests/AWSCostMonitorTests/testRefreshIntervalChangesUpdateTimer \
-skip-testing:AWSCostMonitorTests/TimerLifecycleTests/testIsAutoRefreshActiveTracksStartStop \
-skip-testing:AWSCostMonitorTests/TimerLifecycleTests/testIntervalZeroStopsTimers
```

Also use `-derivedDataPath /tmp/ledger-foundation-dd` to avoid colliding with the main worktree's DerivedData.

---

## File structure

**Create:**
- `AWSCostMonitor/Appearance/LedgerAppearance.swift` — the `LedgerAppearance` value and its enum axes.
- `AWSCostMonitor/Appearance/LedgerTokens.swift` — color / typography / layout accessors keyed by appearance.
- `AWSCostMonitor/Appearance/LedgerModifiers.swift` — view modifiers and environment keys.
- `AWSCostMonitor/Appearance/AppearanceManager.swift` — user preferences + system-observation + legacy migration.
- `AWSCostMonitor/Appearance/LegacyThemeMigration.swift` — pure function mapping legacy theme ids to appearance tuples.
- `AWSCostMonitor/MenuBar/MenuBarPresenter.swift` — renders `NSStatusItem` content from state.
- `AWSCostMonitor/MenuBar/MenuBarOptions.swift` — preset + toggle value types.
- `AWSCostMonitor/MenuBar/MenuBarSparklineImage.swift` — offscreen NSImage renderer for the D preset.
- `AWSCostMonitor/Popover/ProfileRow.swift`
- `AWSCostMonitor/Popover/HeroSplit.swift`
- `AWSCostMonitor/Popover/ServiceList.swift`
- `AWSCostMonitor/Popover/FooterActions.swift`
- `AWSCostMonitorTests/LedgerTokensTests.swift`
- `AWSCostMonitorTests/AppearanceManagerTests.swift`
- `AWSCostMonitorTests/LegacyThemeMigrationTests.swift`
- `AWSCostMonitorTests/MenuBarPresenterTests.swift`

**Modify:**
- `AWSCostMonitor/Views/PopoverContentView.swift` — rewrite against new components.
- `AWSCostMonitor/Controllers/StatusBarController.swift` — drive `MenuBarPresenter`; inject `AppearanceManager`.
- `AWSCostMonitor/Controllers/AppDelegates.swift:65-100` — inject `AppearanceManager` environment in Settings hosting controller.
- `AWSCostMonitor/AWSCostMonitorApp.swift` — install `AppearanceManager` at the app root; run migration once on first launch.
- `AWSCostMonitor/Views/AppearanceSettingsTab.swift` — gut contents, replace with new Appearance controls.

**Delete (at the end of the plan, once references are migrated):**
- `AWSCostMonitor/Models/Theme.swift` (8 theme structs + `Theme` protocol).
- `AWSCostMonitor/Managers/ThemeManager.swift`.
- `AWSCostMonitor/Utilities/ThemeExtensions.swift` (`.themeFont`, `.themePadding`).
- `AWSCostMonitorTests/ThemeTests.swift`
- `AWSCostMonitorTests/ThemedCalendarTests.swift`
- `AWSCostMonitorTests/ThemedDropdownTests.swift`
- `AWSCostMonitorTests/ThemedMenuBarTests.swift`
- `AWSCostMonitorTests/ThemeSettingsUITests.swift`

---

## Phase 1 — Appearance value types

### Task 1.1: LedgerAppearance value and enums

**Files:**
- Create: `packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/LedgerAppearance.swift`
- Test: `packages/app/AWSCostMonitor/AWSCostMonitorTests/LedgerTokensTests.swift`

- [ ] **Step 1: Write the failing test**

Create `LedgerTokensTests.swift`:

```swift
import XCTest
import SwiftUI
@testable import AWSCostMonitor

final class LedgerTokensTests: XCTestCase {
    func testDefaultAppearance() {
        let a = LedgerAppearance.default
        XCTAssertEqual(a.accent, .amber)
        XCTAssertEqual(a.density, .comfortable)
        XCTAssertEqual(a.contrast, .standard)
    }

    func testAccentRawValues() {
        XCTAssertEqual(LedgerAccent.amber.rawValue, "amber")
        XCTAssertEqual(LedgerAccent.mint.rawValue, "mint")
        XCTAssertEqual(LedgerAccent.plasma.rawValue, "plasma")
        XCTAssertEqual(LedgerAccent.bone.rawValue, "bone")
    }
}
```

- [ ] **Step 2: Run test; confirm it fails**

Run: `xcodebuild test -scheme AWSCostMonitor -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/LedgerTokensTests 2>&1 | tail -20`
Expected: `Cannot find 'LedgerAppearance' in scope`.

- [ ] **Step 3: Implement**

Create `LedgerAppearance.swift`:

```swift
import SwiftUI

enum LedgerAccent: String, CaseIterable, Codable, Identifiable {
    case amber, mint, plasma, bone
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .amber:  return "Amber"
        case .mint:   return "Mint"
        case .plasma: return "Plasma"
        case .bone:   return "Bone"
        }
    }
}

enum LedgerDensity: String, CaseIterable, Codable, Identifiable {
    case comfortable, compact
    var id: String { rawValue }
    var displayName: String {
        self == .comfortable ? "Comfortable" : "Compact"
    }
}

enum LedgerContrast: String, CaseIterable, Codable, Identifiable {
    case standard, aaa
    var id: String { rawValue }
    var displayName: String {
        self == .standard ? "Standard" : "AAA"
    }
}

enum LedgerSchemePreference: String, CaseIterable, Codable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "Follow System"
        case .light:  return "Always Light"
        case .dark:   return "Always Dark"
        }
    }
}

struct LedgerAppearance: Equatable {
    var colorScheme: ColorScheme   // resolved value — never .system
    var accent: LedgerAccent
    var density: LedgerDensity
    var contrast: LedgerContrast

    static let `default` = LedgerAppearance(
        colorScheme: .dark,
        accent: .amber,
        density: .comfortable,
        contrast: .standard
    )
}
```

- [ ] **Step 4: Run test; confirm PASS**

Run: `xcodebuild test -scheme AWSCostMonitor -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/LedgerTokensTests/testDefaultAppearance -only-testing:AWSCostMonitorTests/LedgerTokensTests/testAccentRawValues 2>&1 | tail -5`
Expected: PASS both.

- [ ] **Step 5: Commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/LedgerAppearance.swift \
        packages/app/AWSCostMonitor/AWSCostMonitorTests/LedgerTokensTests.swift
git commit -m "feat(ledger): add LedgerAppearance value and axis enums"
```

---

## Phase 2 — Tokens

### Task 2.1: Surface color tokens

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/LedgerTokens.swift` (create if absent)
- Test: `packages/app/AWSCostMonitor/AWSCostMonitorTests/LedgerTokensTests.swift`

- [ ] **Step 1: Write failing tests**

Append to `LedgerTokensTests.swift`:

```swift
func testSurfaceColorsDark() {
    let a = LedgerAppearance(colorScheme: .dark, accent: .amber, density: .comfortable, contrast: .standard)
    XCTAssertEqual(LedgerTokens.Color.surfaceWindow(a).nsHex, "0F1114")
    XCTAssertEqual(LedgerTokens.Color.surfaceElevated(a).nsHex, "14181E")
    XCTAssertEqual(LedgerTokens.Color.surfaceHairline(a).nsHex, "1C2026")
}

func testSurfaceColorsLight() {
    let a = LedgerAppearance(colorScheme: .light, accent: .amber, density: .comfortable, contrast: .standard)
    XCTAssertEqual(LedgerTokens.Color.surfaceWindow(a).nsHex, "FAF7F2")
    XCTAssertEqual(LedgerTokens.Color.surfaceElevated(a).nsHex, "F1ECE1")
    XCTAssertEqual(LedgerTokens.Color.surfaceHairline(a).nsHex, "E5DDC9")
}
```

And a helper extension at the bottom of the test file:

```swift
import AppKit
extension SwiftUI.Color {
    /// 6-char uppercase hex, no alpha. For test assertions only.
    var nsHex: String {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        let r = Int(round(ns.redComponent   * 255))
        let g = Int(round(ns.greenComponent * 255))
        let b = Int(round(ns.blueComponent  * 255))
        return String(format: "%02X%02X%02X", r, g, b)
    }
}
```

- [ ] **Step 2: Run tests; confirm they fail with "Cannot find 'LedgerTokens' in scope"**

- [ ] **Step 3: Implement**

Create `LedgerTokens.swift`:

```swift
import SwiftUI

enum LedgerTokens {
    enum Color {
        static func surfaceWindow(_ a: LedgerAppearance) -> SwiftUI.Color {
            a.colorScheme == .dark ? .hex(0x0F1114) : .hex(0xFAF7F2)
        }
        static func surfaceElevated(_ a: LedgerAppearance) -> SwiftUI.Color {
            a.colorScheme == .dark ? .hex(0x14181E) : .hex(0xF1ECE1)
        }
        static func surfaceHairline(_ a: LedgerAppearance) -> SwiftUI.Color {
            a.colorScheme == .dark ? .hex(0x1C2026) : .hex(0xE5DDC9)
        }
    }
}

extension SwiftUI.Color {
    static func hex(_ value: UInt32) -> SwiftUI.Color {
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8)  & 0xFF) / 255.0
        let b = Double( value        & 0xFF) / 255.0
        return SwiftUI.Color(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 4: Run tests; confirm PASS**

Run: `xcodebuild test -scheme AWSCostMonitor -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/LedgerTokensTests 2>&1 | tail -5`

- [ ] **Step 5: Commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/LedgerTokens.swift \
        packages/app/AWSCostMonitor/AWSCostMonitorTests/LedgerTokensTests.swift
git commit -m "feat(ledger): surface color tokens"
```

### Task 2.2: Accent color tokens (4 accents × 2 schemes)

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/LedgerTokens.swift`
- Test: `packages/app/AWSCostMonitor/AWSCostMonitorTests/LedgerTokensTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
func testAccentAmberBothSchemes() {
    let d = LedgerAppearance(colorScheme: .dark,  accent: .amber, density: .comfortable, contrast: .standard)
    let l = LedgerAppearance(colorScheme: .light, accent: .amber, density: .comfortable, contrast: .standard)
    XCTAssertEqual(LedgerTokens.Color.accent(d).nsHex, "F5B454")
    XCTAssertEqual(LedgerTokens.Color.accent(l).nsHex, "8A5A14")
}

func testAccentMintBothSchemes() {
    let d = LedgerAppearance(colorScheme: .dark,  accent: .mint, density: .comfortable, contrast: .standard)
    let l = LedgerAppearance(colorScheme: .light, accent: .mint, density: .comfortable, contrast: .standard)
    XCTAssertEqual(LedgerTokens.Color.accent(d).nsHex, "4AD6A3")
    XCTAssertEqual(LedgerTokens.Color.accent(l).nsHex, "1C7A57")
}

func testAccentPlasmaBothSchemes() {
    let d = LedgerAppearance(colorScheme: .dark,  accent: .plasma, density: .comfortable, contrast: .standard)
    let l = LedgerAppearance(colorScheme: .light, accent: .plasma, density: .comfortable, contrast: .standard)
    XCTAssertEqual(LedgerTokens.Color.accent(d).nsHex, "5AD9FF")
    XCTAssertEqual(LedgerTokens.Color.accent(l).nsHex, "0B6A90")
}

func testAccentBoneBothSchemes() {
    let d = LedgerAppearance(colorScheme: .dark,  accent: .bone, density: .comfortable, contrast: .standard)
    let l = LedgerAppearance(colorScheme: .light, accent: .bone, density: .comfortable, contrast: .standard)
    XCTAssertEqual(LedgerTokens.Color.accent(d).nsHex, "E7E2D2")
    XCTAssertEqual(LedgerTokens.Color.accent(l).nsHex, "4A443A")
}
```

- [ ] **Step 2: Run tests; confirm they fail**

- [ ] **Step 3: Implement**

Extend the `Color` enum inside `LedgerTokens`:

```swift
static func accent(_ a: LedgerAppearance) -> SwiftUI.Color {
    switch (a.accent, a.colorScheme) {
    case (.amber,  .dark):  return .hex(0xF5B454)
    case (.amber,  .light): return .hex(0x8A5A14)
    case (.mint,   .dark):  return .hex(0x4AD6A3)
    case (.mint,   .light): return .hex(0x1C7A57)
    case (.plasma, .dark):  return .hex(0x5AD9FF)
    case (.plasma, .light): return .hex(0x0B6A90)
    case (.bone,   .dark):  return .hex(0xE7E2D2)
    case (.bone,   .light): return .hex(0x4A443A)
    }
}
```

- [ ] **Step 4: Run tests; confirm PASS**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(ledger): accent color tokens for all four accents"
```

### Task 2.3: Signal & ink color tokens

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/LedgerTokens.swift`
- Test: `packages/app/AWSCostMonitor/AWSCostMonitorTests/LedgerTokensTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
func testSignalsAndInkDark() {
    let a = LedgerAppearance(colorScheme: .dark, accent: .amber, density: .comfortable, contrast: .standard)
    XCTAssertEqual(LedgerTokens.Color.signalOver(a).nsHex,  "FF7A7A")
    XCTAssertEqual(LedgerTokens.Color.signalUnder(a).nsHex, "4AD6A3")
    XCTAssertEqual(LedgerTokens.Color.inkPrimary(a).nsHex,   "E7E9EC")
    XCTAssertEqual(LedgerTokens.Color.inkSecondary(a).nsHex, "A8B1BD")
    XCTAssertEqual(LedgerTokens.Color.inkTertiary(a).nsHex,  "7F8A99")
}

func testSignalsAndInkLight() {
    let a = LedgerAppearance(colorScheme: .light, accent: .amber, density: .comfortable, contrast: .standard)
    XCTAssertEqual(LedgerTokens.Color.signalOver(a).nsHex,  "B02020")
    XCTAssertEqual(LedgerTokens.Color.signalUnder(a).nsHex, "2F9E6B")
    XCTAssertEqual(LedgerTokens.Color.inkPrimary(a).nsHex,   "1B1A17")
    XCTAssertEqual(LedgerTokens.Color.inkSecondary(a).nsHex, "3A3731")
    XCTAssertEqual(LedgerTokens.Color.inkTertiary(a).nsHex,  "8A7F6C")
}

func testAAAContrastPromotesInkTertiary() {
    let std = LedgerAppearance(colorScheme: .dark, accent: .amber, density: .comfortable, contrast: .standard)
    let aaa = LedgerAppearance(colorScheme: .dark, accent: .amber, density: .comfortable, contrast: .aaa)
    // AAA mode promotes tertiary to secondary values (brighter for readability).
    XCTAssertEqual(LedgerTokens.Color.inkTertiary(aaa).nsHex, "A8B1BD")
    XCTAssertEqual(LedgerTokens.Color.inkTertiary(std).nsHex, "7F8A99")
}
```

- [ ] **Step 2: Run tests; fail**

- [ ] **Step 3: Implement**

Append to `LedgerTokens.Color`:

```swift
static func signalOver(_ a: LedgerAppearance) -> SwiftUI.Color {
    a.colorScheme == .dark ? .hex(0xFF7A7A) : .hex(0xB02020)
}

static func signalUnder(_ a: LedgerAppearance) -> SwiftUI.Color {
    a.colorScheme == .dark ? .hex(0x4AD6A3) : .hex(0x2F9E6B)
}

static func inkPrimary(_ a: LedgerAppearance) -> SwiftUI.Color {
    a.colorScheme == .dark ? .hex(0xE7E9EC) : .hex(0x1B1A17)
}

static func inkSecondary(_ a: LedgerAppearance) -> SwiftUI.Color {
    a.colorScheme == .dark ? .hex(0xA8B1BD) : .hex(0x3A3731)
}

static func inkTertiary(_ a: LedgerAppearance) -> SwiftUI.Color {
    if a.contrast == .aaa {
        // AAA promotes tertiary to match secondary values
        return inkSecondary(a)
    }
    return a.colorScheme == .dark ? .hex(0x7F8A99) : .hex(0x8A7F6C)
}
```

- [ ] **Step 4: Run tests; PASS**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(ledger): signal and ink color tokens with AAA promotion"
```

### Task 2.4: Typography tokens (density-aware)

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/LedgerTokens.swift`
- Test: `packages/app/AWSCostMonitor/AWSCostMonitorTests/LedgerTokensTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
func testHeroFontSizeByDensity() {
    let comfort = LedgerAppearance(colorScheme: .dark, accent: .amber, density: .comfortable, contrast: .standard)
    let compact = LedgerAppearance(colorScheme: .dark, accent: .amber, density: .compact, contrast: .standard)
    XCTAssertEqual(LedgerTokens.Typography.heroPointSize(comfort), 34)
    XCTAssertEqual(LedgerTokens.Typography.heroPointSize(compact), 28)
}

func testStatValueFontSizeByDensity() {
    let comfort = LedgerAppearance(colorScheme: .dark, accent: .amber, density: .comfortable, contrast: .standard)
    let compact = LedgerAppearance(colorScheme: .dark, accent: .amber, density: .compact, contrast: .standard)
    XCTAssertEqual(LedgerTokens.Typography.statValuePointSize(comfort), 14)
    XCTAssertEqual(LedgerTokens.Typography.statValuePointSize(compact), 12)
}

func testLabelPointSizeConstantAcrossDensity() {
    let comfort = LedgerAppearance(colorScheme: .dark, accent: .amber, density: .comfortable, contrast: .standard)
    let compact = LedgerAppearance(colorScheme: .dark, accent: .amber, density: .compact, contrast: .standard)
    XCTAssertEqual(LedgerTokens.Typography.labelPointSize(comfort), 10)
    XCTAssertEqual(LedgerTokens.Typography.labelPointSize(compact), 10)
}
```

- [ ] **Step 2: Run tests; fail**

- [ ] **Step 3: Implement**

Append to `LedgerTokens`:

```swift
enum Typography {
    static func heroPointSize(_ a: LedgerAppearance) -> CGFloat {
        a.density == .comfortable ? 34 : 28
    }
    static func statValuePointSize(_ a: LedgerAppearance) -> CGFloat {
        a.density == .comfortable ? 14 : 12
    }
    static func labelPointSize(_ a: LedgerAppearance) -> CGFloat { 10 }
    static func bodyPointSize(_ a: LedgerAppearance) -> CGFloat {
        a.density == .comfortable ? 13 : 12
    }
    static func metaPointSize(_ a: LedgerAppearance) -> CGFloat { 11 }

    static func hero(_ a: LedgerAppearance) -> Font {
        .system(size: heroPointSize(a), weight: .light, design: .monospaced)
    }
    static func statValue(_ a: LedgerAppearance) -> Font {
        .system(size: statValuePointSize(a), weight: .medium, design: .monospaced)
    }
    static func label(_ a: LedgerAppearance) -> Font {
        .system(size: labelPointSize(a), weight: .semibold, design: .default)
    }
    static func body(_ a: LedgerAppearance) -> Font {
        .system(size: bodyPointSize(a), weight: .regular, design: .default)
    }
    static func meta(_ a: LedgerAppearance) -> Font {
        .system(size: metaPointSize(a), weight: .regular, design: .default)
    }
}
```

- [ ] **Step 4: Run tests; PASS**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(ledger): typography tokens with density scaling"
```

### Task 2.5: Layout tokens

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/LedgerTokens.swift`
- Test: `packages/app/AWSCostMonitor/AWSCostMonitorTests/LedgerTokensTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
func testLayoutUnitByDensity() {
    let comfort = LedgerAppearance(colorScheme: .dark, accent: .amber, density: .comfortable, contrast: .standard)
    let compact = LedgerAppearance(colorScheme: .dark, accent: .amber, density: .compact, contrast: .standard)
    XCTAssertEqual(LedgerTokens.Layout.unit(comfort), 8)
    XCTAssertEqual(LedgerTokens.Layout.unit(compact), 6)
    XCTAssertEqual(LedgerTokens.Layout.rowHeight(comfort), 32)
    XCTAssertEqual(LedgerTokens.Layout.rowHeight(compact), 26)
    XCTAssertEqual(LedgerTokens.Layout.hairlineWidth(comfort), 1)
    XCTAssertEqual(LedgerTokens.Layout.cornerRadius, 10)
}
```

- [ ] **Step 2: Run; fail**

- [ ] **Step 3: Implement**

```swift
enum Layout {
    static let cornerRadius: CGFloat = 10
    static func unit(_ a: LedgerAppearance) -> CGFloat {
        a.density == .comfortable ? 8 : 6
    }
    static func rowHeight(_ a: LedgerAppearance) -> CGFloat {
        a.density == .comfortable ? 32 : 26
    }
    static func hairlineWidth(_ a: LedgerAppearance) -> CGFloat { 1 }
}
```

- [ ] **Step 4: Run; PASS**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(ledger): layout tokens with density scaling"
```

---

## Phase 3 — Modifiers and environment

### Task 3.1: Environment key + inject appearance

**Files:**
- Create: `packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/LedgerModifiers.swift`
- Test: `packages/app/AWSCostMonitor/AWSCostMonitorTests/LedgerTokensTests.swift`

- [ ] **Step 1: Write failing test**

```swift
func testEnvironmentKeyDefault() {
    let holder = EnvironmentValues()
    XCTAssertEqual(holder.ledgerAppearance, LedgerAppearance.default)
}
```

- [ ] **Step 2: Run; fail (no `ledgerAppearance` key)**

- [ ] **Step 3: Implement**

Create `LedgerModifiers.swift`:

```swift
import SwiftUI

private struct LedgerAppearanceKey: EnvironmentKey {
    static let defaultValue: LedgerAppearance = .default
}

extension EnvironmentValues {
    var ledgerAppearance: LedgerAppearance {
        get { self[LedgerAppearanceKey.self] }
        set { self[LedgerAppearanceKey.self] = newValue }
    }
}
```

- [ ] **Step 4: Run; PASS**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(ledger): environment key for LedgerAppearance"
```

### Task 3.2: Convenience view modifiers

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/LedgerModifiers.swift`

This task has no unit tests (pure SwiftUI presentation). Verify visually in SwiftUI preview.

- [ ] **Step 1: Add the modifiers**

Append to `LedgerModifiers.swift`:

```swift
enum LedgerSurface { case window, elevated }

struct LedgerSurfaceModifier: ViewModifier {
    let surface: LedgerSurface
    @Environment(\.ledgerAppearance) private var a
    func body(content: Content) -> some View {
        content.background(
            surface == .window
                ? LedgerTokens.Color.surfaceWindow(a)
                : LedgerTokens.Color.surfaceElevated(a)
        )
    }
}

struct LedgerHairlineDivider: View {
    @Environment(\.ledgerAppearance) private var a
    var body: some View {
        Rectangle()
            .fill(LedgerTokens.Color.surfaceHairline(a))
            .frame(height: LedgerTokens.Layout.hairlineWidth(a))
    }
}

extension View {
    func ledgerSurface(_ s: LedgerSurface) -> some View {
        modifier(LedgerSurfaceModifier(surface: s))
    }

    func ledgerHero() -> some View {
        modifier(FontModifier(kind: .hero, color: .accent))
    }
    func ledgerStatValue() -> some View {
        modifier(FontModifier(kind: .statValue, color: .inkPrimary))
    }
    func ledgerLabel() -> some View {
        modifier(FontModifier(kind: .label, color: .inkTertiary))
            .textCase(.uppercase)
            .tracking(0.12 * 10)   // approx 0.12em at 10pt
    }
    func ledgerBody() -> some View {
        modifier(FontModifier(kind: .body, color: .inkSecondary))
    }
    func ledgerMeta() -> some View {
        modifier(FontModifier(kind: .meta, color: .inkTertiary))
    }
}

private enum TokenColorKind { case accent, inkPrimary, inkSecondary, inkTertiary }
private enum TokenFontKind { case hero, statValue, label, body, meta }

private struct FontModifier: ViewModifier {
    let kind: TokenFontKind
    let color: TokenColorKind
    @Environment(\.ledgerAppearance) private var a
    func body(content: Content) -> some View {
        let font: Font = {
            switch kind {
            case .hero:      return LedgerTokens.Typography.hero(a)
            case .statValue: return LedgerTokens.Typography.statValue(a)
            case .label:     return LedgerTokens.Typography.label(a)
            case .body:      return LedgerTokens.Typography.body(a)
            case .meta:      return LedgerTokens.Typography.meta(a)
            }
        }()
        let fg: SwiftUI.Color = {
            switch color {
            case .accent:        return LedgerTokens.Color.accent(a)
            case .inkPrimary:    return LedgerTokens.Color.inkPrimary(a)
            case .inkSecondary:  return LedgerTokens.Color.inkSecondary(a)
            case .inkTertiary:   return LedgerTokens.Color.inkTertiary(a)
            }
        }()
        content
            .font(font)
            .foregroundColor(fg)
            .monospacedDigit()
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -scheme AWSCostMonitor -configuration Debug -destination 'platform=macOS' build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git commit -am "feat(ledger): view modifiers for surface and typography tokens"
```

---

## Phase 4 — Legacy theme migration

### Task 4.1: Pure migration function

**Files:**
- Create: `packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/LegacyThemeMigration.swift`
- Test: `packages/app/AWSCostMonitor/AWSCostMonitorTests/LegacyThemeMigrationTests.swift`

- [ ] **Step 1: Write failing tests**

Create `LegacyThemeMigrationTests.swift`:

```swift
import XCTest
@testable import AWSCostMonitor

final class LegacyThemeMigrationTests: XCTestCase {
    func testClassicMigratesToAmberComfortStandard() {
        let out = LegacyThemeMigration.migrate(themeId: "classic")
        XCTAssertEqual(out, .init(accent: .amber, density: .comfortable, contrast: .standard))
    }
    func testHighContrastMigratesToAAA() {
        let out = LegacyThemeMigration.migrate(themeId: "highContrast")
        XCTAssertEqual(out.contrast, .aaa)
    }
    func testCompactMigratesToCompactDensity() {
        let out = LegacyThemeMigration.migrate(themeId: "compact")
        XCTAssertEqual(out.density, .compact)
    }
    func testTerminalMigratesToMintCompact() {
        let out = LegacyThemeMigration.migrate(themeId: "terminal")
        XCTAssertEqual(out.accent, .mint)
        XCTAssertEqual(out.density, .compact)
    }
    func testProfessionalMigratesToBone() {
        let out = LegacyThemeMigration.migrate(themeId: "professional")
        XCTAssertEqual(out.accent, .bone)
    }
    func testMemphisMigratesToAmberComfort() {
        let out = LegacyThemeMigration.migrate(themeId: "memphis")
        XCTAssertEqual(out.accent, .amber)
        XCTAssertEqual(out.density, .comfortable)
    }
    func testUnknownIdFallsBackToDefaults() {
        let out = LegacyThemeMigration.migrate(themeId: "martian")
        XCTAssertEqual(out, .init(accent: .amber, density: .comfortable, contrast: .standard))
    }
    func testNilIdFallsBackToDefaults() {
        let out = LegacyThemeMigration.migrate(themeId: nil)
        XCTAssertEqual(out, .init(accent: .amber, density: .comfortable, contrast: .standard))
    }
}
```

- [ ] **Step 2: Run; fail**

- [ ] **Step 3: Implement**

Create `LegacyThemeMigration.swift`:

```swift
import Foundation

enum LegacyThemeMigration {
    struct Result: Equatable {
        var accent: LedgerAccent
        var density: LedgerDensity
        var contrast: LedgerContrast
    }

    static func migrate(themeId: String?) -> Result {
        switch themeId {
        case "highContrast"?:
            return .init(accent: .amber, density: .comfortable, contrast: .aaa)
        case "compact"?:
            return .init(accent: .amber, density: .compact, contrast: .standard)
        case "terminal"?:
            return .init(accent: .mint, density: .compact, contrast: .standard)
        case "professional"?:
            return .init(accent: .bone, density: .comfortable, contrast: .standard)
        default:
            // classic / modern / comfortable / memphis / unknown / nil
            return .init(accent: .amber, density: .comfortable, contrast: .standard)
        }
    }
}
```

- [ ] **Step 4: Run; PASS**

- [ ] **Step 5: Commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/LegacyThemeMigration.swift \
        packages/app/AWSCostMonitor/AWSCostMonitorTests/LegacyThemeMigrationTests.swift
git commit -m "feat(ledger): legacy theme migration mapping with tests"
```

---

## Phase 5 — AppearanceManager

### Task 5.1: AppearanceManager with persisted preferences

**Files:**
- Create: `packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/AppearanceManager.swift`
- Test: `packages/app/AWSCostMonitor/AWSCostMonitorTests/AppearanceManagerTests.swift`

- [ ] **Step 1: Write failing tests**

Create `AppearanceManagerTests.swift`:

```swift
import XCTest
import SwiftUI
@testable import AWSCostMonitor

final class AppearanceManagerTests: XCTestCase {
    private let suiteName = "AppearanceManagerTests"
    var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testDefaultsWhenNoPreferencesStored() {
        let mgr = AppearanceManager(defaults: defaults, systemIsDark: { true })
        XCTAssertEqual(mgr.appearance.colorScheme, .dark)
        XCTAssertEqual(mgr.appearance.accent, .amber)
        XCTAssertEqual(mgr.appearance.density, .comfortable)
        XCTAssertEqual(mgr.appearance.contrast, .standard)
    }

    func testAccentPersistsAcrossInstances() {
        let a = AppearanceManager(defaults: defaults, systemIsDark: { true })
        a.setAccent(.mint)
        let b = AppearanceManager(defaults: defaults, systemIsDark: { true })
        XCTAssertEqual(b.appearance.accent, .mint)
    }

    func testDensityAndContrastPersist() {
        let a = AppearanceManager(defaults: defaults, systemIsDark: { true })
        a.setDensity(.compact)
        a.setContrast(.aaa)
        let b = AppearanceManager(defaults: defaults, systemIsDark: { true })
        XCTAssertEqual(b.appearance.density, .compact)
        XCTAssertEqual(b.appearance.contrast, .aaa)
    }

    func testSchemeOverrideAlwaysLight() {
        let mgr = AppearanceManager(defaults: defaults, systemIsDark: { true })
        mgr.setSchemePreference(.light)
        XCTAssertEqual(mgr.appearance.colorScheme, .light)
    }

    func testSchemeOverrideAlwaysDark() {
        let mgr = AppearanceManager(defaults: defaults, systemIsDark: { false })
        mgr.setSchemePreference(.dark)
        XCTAssertEqual(mgr.appearance.colorScheme, .dark)
    }

    func testSchemeFollowsSystemWhenPreferenceIsSystem() {
        var systemDark = true
        let mgr = AppearanceManager(defaults: defaults, systemIsDark: { systemDark })
        mgr.setSchemePreference(.system)
        XCTAssertEqual(mgr.appearance.colorScheme, .dark)

        systemDark = false
        mgr.systemAppearanceDidChange()
        XCTAssertEqual(mgr.appearance.colorScheme, .light)
    }
}
```

- [ ] **Step 2: Run; fail**

- [ ] **Step 3: Implement**

Create `AppearanceManager.swift`:

```swift
import SwiftUI
import AppKit
import Combine

@MainActor
final class AppearanceManager: ObservableObject {
    @Published private(set) var appearance: LedgerAppearance

    private let defaults: UserDefaults
    private let systemIsDark: () -> Bool

    private enum Keys {
        static let scheme   = "ledger.schemePreference"
        static let accent   = "ledger.accent"
        static let density  = "ledger.density"
        static let contrast = "ledger.contrast"
    }

    init(defaults: UserDefaults = .standard, systemIsDark: @escaping () -> Bool = {
        NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }) {
        self.defaults = defaults
        self.systemIsDark = systemIsDark

        let scheme   = LedgerSchemePreference(rawValue: defaults.string(forKey: Keys.scheme)   ?? "")  ?? .system
        let accent   = LedgerAccent(rawValue:           defaults.string(forKey: Keys.accent)   ?? "")  ?? .amber
        let density  = LedgerDensity(rawValue:          defaults.string(forKey: Keys.density)  ?? "")  ?? .comfortable
        let contrast = LedgerContrast(rawValue:         defaults.string(forKey: Keys.contrast) ?? "")  ?? .standard

        self.schemePreference = scheme
        self.appearance = LedgerAppearance(
            colorScheme: Self.resolve(scheme: scheme, systemIsDark: systemIsDark),
            accent: accent,
            density: density,
            contrast: contrast
        )
    }

    private(set) var schemePreference: LedgerSchemePreference

    func setSchemePreference(_ p: LedgerSchemePreference) {
        schemePreference = p
        defaults.set(p.rawValue, forKey: Keys.scheme)
        appearance.colorScheme = Self.resolve(scheme: p, systemIsDark: systemIsDark)
    }

    func setAccent(_ v: LedgerAccent) {
        defaults.set(v.rawValue, forKey: Keys.accent)
        appearance.accent = v
    }

    func setDensity(_ v: LedgerDensity) {
        defaults.set(v.rawValue, forKey: Keys.density)
        appearance.density = v
    }

    func setContrast(_ v: LedgerContrast) {
        defaults.set(v.rawValue, forKey: Keys.contrast)
        appearance.contrast = v
    }

    /// Called by the app root when `NSApp.effectiveAppearance` publishes a change.
    func systemAppearanceDidChange() {
        guard schemePreference == .system else { return }
        appearance.colorScheme = Self.resolve(scheme: .system, systemIsDark: systemIsDark)
    }

    private static func resolve(scheme: LedgerSchemePreference, systemIsDark: () -> Bool) -> ColorScheme {
        switch scheme {
        case .system: return systemIsDark() ? .dark : .light
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
```

- [ ] **Step 4: Run; PASS**

- [ ] **Step 5: Commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/AppearanceManager.swift \
        packages/app/AWSCostMonitor/AWSCostMonitorTests/AppearanceManagerTests.swift
git commit -m "feat(ledger): AppearanceManager with persisted preferences"
```

### Task 5.2: One-shot legacy theme migration on first launch

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Appearance/AppearanceManager.swift`
- Test: `packages/app/AWSCostMonitor/AWSCostMonitorTests/AppearanceManagerTests.swift`

- [ ] **Step 1: Write failing test**

Append to `AppearanceManagerTests.swift`:

```swift
func testMigratesLegacyTerminalThemeOnce() {
    defaults.set("terminal", forKey: "selectedTheme")
    let a = AppearanceManager(defaults: defaults, systemIsDark: { true })
    a.runLegacyMigrationIfNeeded()
    XCTAssertEqual(a.appearance.accent, .mint)
    XCTAssertEqual(a.appearance.density, .compact)
    XCTAssertTrue(defaults.bool(forKey: "ledger.migrated"))
}

func testMigrationIsIdempotent() {
    defaults.set("terminal", forKey: "selectedTheme")
    let a = AppearanceManager(defaults: defaults, systemIsDark: { true })
    a.runLegacyMigrationIfNeeded()
    a.setAccent(.bone)                 // user changes accent after migration
    a.runLegacyMigrationIfNeeded()      // should not re-run
    XCTAssertEqual(a.appearance.accent, .bone)
}
```

- [ ] **Step 2: Run; fail**

- [ ] **Step 3: Implement**

Append to `AppearanceManager.swift`:

```swift
extension AppearanceManager {
    /// Migrates the user's previously-selected legacy theme id to the new axis tuple.
    /// Runs once; subsequent calls are no-ops.
    func runLegacyMigrationIfNeeded() {
        guard !defaults.bool(forKey: "ledger.migrated") else { return }
        let legacy = defaults.string(forKey: "selectedTheme")
        let mapped = LegacyThemeMigration.migrate(themeId: legacy)
        setAccent(mapped.accent)
        setDensity(mapped.density)
        setContrast(mapped.contrast)
        defaults.set(true, forKey: "ledger.migrated")
    }
}
```

- [ ] **Step 4: Run; PASS**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(ledger): one-shot legacy theme migration on first launch"
```

---

## Phase 6 — Menu bar

### Task 6.1: MenuBarOptions value type with persistence

**Files:**
- Create: `packages/app/AWSCostMonitor/AWSCostMonitor/MenuBar/MenuBarOptions.swift`
- Test: `packages/app/AWSCostMonitor/AWSCostMonitorTests/MenuBarPresenterTests.swift`

- [ ] **Step 1: Write failing tests**

Create `MenuBarPresenterTests.swift`:

```swift
import XCTest
@testable import AWSCostMonitor

final class MenuBarPresenterTests: XCTestCase {
    private let suiteName = "MenuBarPresenterTests"
    var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testMenuBarOptionsDefaults() {
        let o = MenuBarOptions(defaults: defaults)
        XCTAssertEqual(o.preset, .iconFigure)
        XCTAssertFalse(o.hideCents)
        XCTAssertFalse(o.showDelta)
        XCTAssertFalse(o.autoAbbreviate)
    }

    func testMenuBarOptionsPersist() {
        var o = MenuBarOptions(defaults: defaults)
        o.preset = .pill
        o.hideCents = true
        o.showDelta = true
        o.autoAbbreviate = true
        let p = MenuBarOptions(defaults: defaults)
        XCTAssertEqual(p.preset, .pill)
        XCTAssertTrue(p.hideCents)
        XCTAssertTrue(p.showDelta)
        XCTAssertTrue(p.autoAbbreviate)
    }
}
```

- [ ] **Step 2: Run; fail**

- [ ] **Step 3: Implement**

Create `MenuBarOptions.swift`:

```swift
import Foundation

enum MenuBarPreset: String, CaseIterable, Codable, Identifiable {
    case textOnly, iconFigure, pill, figureSparkline
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .textOnly:        return "Text only"
        case .iconFigure:      return "Icon + figure"
        case .pill:            return "Amber pill"
        case .figureSparkline: return "Figure + sparkline"
        }
    }
}

struct MenuBarOptions {
    private let defaults: UserDefaults

    private enum Keys {
        static let preset = "menubar.preset"
        static let hideCents = "menubar.hideCents"
        static let showDelta = "menubar.showDelta"
        static let autoAbbreviate = "menubar.autoAbbreviate"
    }

    var preset: MenuBarPreset {
        get { MenuBarPreset(rawValue: defaults.string(forKey: Keys.preset) ?? "") ?? .iconFigure }
        set { defaults.set(newValue.rawValue, forKey: Keys.preset) }
    }
    var hideCents: Bool {
        get { defaults.bool(forKey: Keys.hideCents) }
        set { defaults.set(newValue, forKey: Keys.hideCents) }
    }
    var showDelta: Bool {
        get { defaults.bool(forKey: Keys.showDelta) }
        set { defaults.set(newValue, forKey: Keys.showDelta) }
    }
    var autoAbbreviate: Bool {
        get { defaults.bool(forKey: Keys.autoAbbreviate) }
        set { defaults.set(newValue, forKey: Keys.autoAbbreviate) }
    }

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
}
```

- [ ] **Step 4: Run; PASS**

- [ ] **Step 5: Commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/MenuBar/MenuBarOptions.swift \
        packages/app/AWSCostMonitor/AWSCostMonitorTests/MenuBarPresenterTests.swift
git commit -m "feat(ledger): MenuBarOptions value type with persistence"
```

### Task 6.2: Cost formatter (used by presenter)

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/MenuBar/MenuBarOptions.swift` (or a new `MenuBarFormatter.swift`)
- Test: `packages/app/AWSCostMonitor/AWSCostMonitorTests/MenuBarPresenterTests.swift`

- [ ] **Step 1: Write failing tests**

Append:

```swift
func testFormatter_defaultShowsCents() {
    let o = MenuBarOptions(defaults: defaults)
    XCTAssertEqual(MenuBarFormatter.format(amount: 2847.23, options: o), "$2,847.23")
}
func testFormatter_hideCents() {
    var o = MenuBarOptions(defaults: defaults); o.hideCents = true
    XCTAssertEqual(MenuBarFormatter.format(amount: 2847.23, options: o), "$2,847")
}
func testFormatter_autoAbbreviateAbove10k() {
    var o = MenuBarOptions(defaults: defaults); o.autoAbbreviate = true
    XCTAssertEqual(MenuBarFormatter.format(amount: 12400, options: o), "$12.4k")
    XCTAssertEqual(MenuBarFormatter.format(amount: 9999,  options: o), "$9,999.00")
}
func testFormatter_deltaAppendsSignedPct() {
    var o = MenuBarOptions(defaults: defaults); o.showDelta = true
    XCTAssertEqual(MenuBarFormatter.format(amount: 2847.23, options: o, delta: 0.124), "$2,847.23 ↑12.4%")
    XCTAssertEqual(MenuBarFormatter.format(amount: 2847.23, options: o, delta: -0.05), "$2,847.23 ↓5.0%")
}
func testFormatter_ignoresDeltaWhenShowDeltaOff() {
    let o = MenuBarOptions(defaults: defaults)
    XCTAssertEqual(MenuBarFormatter.format(amount: 100, options: o, delta: 0.5), "$100.00")
}
```

- [ ] **Step 2: Run; fail**

- [ ] **Step 3: Implement**

Create `packages/app/AWSCostMonitor/AWSCostMonitor/MenuBar/MenuBarFormatter.swift`:

```swift
import Foundation

enum MenuBarFormatter {
    static func format(amount: Double, options: MenuBarOptions, delta: Double? = nil) -> String {
        var body: String
        if options.autoAbbreviate, amount >= 10_000 {
            let k = amount / 1000
            body = String(format: "$%.1fk", k)
        } else if options.hideCents {
            let nf = NumberFormatter()
            nf.numberStyle = .currency
            nf.currencyCode = "USD"
            nf.maximumFractionDigits = 0
            body = nf.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
        } else {
            let nf = NumberFormatter()
            nf.numberStyle = .currency
            nf.currencyCode = "USD"
            nf.maximumFractionDigits = 2
            nf.minimumFractionDigits = 2
            body = nf.string(from: NSNumber(value: amount)) ?? String(format: "$%.2f", amount)
        }
        guard options.showDelta, let delta else { return body }
        let pct = abs(delta * 100)
        let arrow = delta >= 0 ? "↑" : "↓"
        return String(format: "\(body) \(arrow)%.1f%%", pct)
    }
}
```

- [ ] **Step 4: Run; PASS**

- [ ] **Step 5: Commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/MenuBar/MenuBarFormatter.swift
git commit -am "feat(ledger): MenuBarFormatter with hideCents, autoAbbreviate, delta"
```

### Task 6.3: Sparkline image renderer

**Files:**
- Create: `packages/app/AWSCostMonitor/AWSCostMonitor/MenuBar/MenuBarSparklineImage.swift`

No unit test — renders an `NSImage`. Verify visually.

- [ ] **Step 1: Implement**

Create `MenuBarSparklineImage.swift`:

```swift
import AppKit

enum MenuBarSparklineImage {
    /// Renders a 60×14 horizontal sparkline. `values` is MTD daily cost; normalized to max.
    /// `color` should come from `LedgerTokens.Color.accent(…)` resolved to NSColor.
    static func render(values: [Double], color: NSColor) -> NSImage {
        let size = NSSize(width: 60, height: 14)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        guard let maxV = values.max(), maxV > 0, !values.isEmpty else { return image }
        let columnWidth: CGFloat = 2
        let gap: CGFloat = 1
        let barCount = min(values.count, Int(size.width / (columnWidth + gap)))
        let start = max(0, values.count - barCount)
        let slice = Array(values[start..<values.count])

        for (i, v) in slice.enumerated() {
            let h = max(1, (CGFloat(v) / CGFloat(maxV)) * size.height)
            let x = CGFloat(i) * (columnWidth + gap)
            let rect = NSRect(x: x, y: 0, width: columnWidth, height: h)
            // Last bar (today) gets full alpha; the rest 0.6
            let alpha: CGFloat = i == slice.count - 1 ? 1.0 : 0.6
            color.withAlphaComponent(alpha).setFill()
            NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1).fill()
        }
        return image
    }
}
```

- [ ] **Step 2: Build**

`xcodebuild -scheme AWSCostMonitor -configuration Debug -destination 'platform=macOS' build 2>&1 | tail -3`

- [ ] **Step 3: Commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/MenuBar/MenuBarSparklineImage.swift
git commit -m "feat(ledger): menu-bar sparkline image renderer"
```

### Task 6.4: MenuBarPresenter — drives the NSStatusItem button

**Files:**
- Create: `packages/app/AWSCostMonitor/AWSCostMonitor/MenuBar/MenuBarPresenter.swift`

No isolated unit test (AppKit-bound); acceptance is visual + integration test in Task 6.5.

- [ ] **Step 1: Implement**

Create `MenuBarPresenter.swift`:

```swift
import AppKit

@MainActor
final class MenuBarPresenter {
    private let button: NSStatusBarButton
    private let templateIconName = "MenuBarLedgerMark"   // 16×16 template PDF in Assets

    init(button: NSStatusBarButton) {
        self.button = button
    }

    func render(
        amount: Double,
        delta: Double?,
        budgetUsed: Double,
        sparkline: [Double],
        options: MenuBarOptions,
        accent: NSColor,
        overBudget: NSColor
    ) {
        let color = budgetUsed > 1.0 ? overBudget : accent
        let text = MenuBarFormatter.format(amount: amount, options: options, delta: delta)

        // Reset
        button.image = nil
        button.attributedTitle = NSAttributedString(string: "")
        button.title = ""
        button.imagePosition = .noImage

        switch options.preset {
        case .textOnly:
            button.attributedTitle = Self.attributedTitle(text, color: color, pill: false)

        case .iconFigure:
            let icon = NSImage(named: templateIconName)
            icon?.isTemplate = true
            button.image = icon
            button.imagePosition = .imageLeft
            button.attributedTitle = Self.attributedTitle(text, color: color, pill: false)

        case .pill:
            // Render text inside a rounded pill as an image (avoids AppKit background quirks).
            button.image = Self.pillImage(text: text, fillColor: color.withAlphaComponent(0.14), textColor: color)

        case .figureSparkline:
            // Compose text + sparkline image side-by-side into one NSImage.
            button.image = Self.sparklineImage(text: text, textColor: color, sparkline: sparkline)
        }
    }

    private static func attributedTitle(_ s: String, color: NSColor, pill: Bool) -> NSAttributedString {
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        return NSAttributedString(string: s, attributes: [
            .font: font,
            .foregroundColor: color,
        ])
    }

    private static func pillImage(text: String, fillColor: NSColor, textColor: NSColor) -> NSImage {
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let textSize = (text as NSString).size(withAttributes: attrs)
        let padH: CGFloat = 9, padV: CGFloat = 2
        let size = NSSize(width: ceil(textSize.width) + padH*2, height: ceil(textSize.height) + padV*2)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }
        fillColor.setFill()
        let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: size.height/2, yRadius: size.height/2)
        path.fill()
        (text as NSString).draw(at: NSPoint(x: padH, y: padV), withAttributes: attrs)
        return image
    }

    private static func sparklineImage(text: String, textColor: NSColor, sparkline: [Double]) -> NSImage {
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let textSize = (text as NSString).size(withAttributes: attrs)
        let gap: CGFloat = 6
        let sparkSize = NSSize(width: 60, height: 14)
        let size = NSSize(width: ceil(textSize.width) + gap + sparkSize.width, height: max(ceil(textSize.height), sparkSize.height))
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }
        (text as NSString).draw(at: NSPoint(x: 0, y: (size.height - textSize.height)/2), withAttributes: attrs)
        let sparkline = MenuBarSparklineImage.render(values: sparkline, color: textColor)
        sparkline.draw(at: NSPoint(x: textSize.width + gap, y: (size.height - sparkSize.height)/2), from: .zero, operation: .sourceOver, fraction: 1.0)
        return image
    }
}
```

- [ ] **Step 2: Build**

`xcodebuild -scheme AWSCostMonitor -configuration Debug -destination 'platform=macOS' build 2>&1 | tail -3`

- [ ] **Step 3: Commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/MenuBar/MenuBarPresenter.swift
git commit -m "feat(ledger): MenuBarPresenter rendering all four presets"
```

### Task 6.5: Wire MenuBarPresenter into StatusBarController

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Controllers/StatusBarController.swift`

- [ ] **Step 1: Add `MenuBarLedgerMark` template PDF to the asset catalog**

Create a 16×16 PDF asset in `Assets.xcassets/MenuBarLedgerMark.imageset/` with three rising bars (40%, 70%, 95%). Mark it as a template image in the image set's JSON. This can be a monochrome PDF — Apple tints it automatically.

Acceptance: `NSImage(named: "MenuBarLedgerMark")?.isTemplate` returns `true` when the image set has `Render As: Template Image`.

- [ ] **Step 2: Replace status-item drawing logic**

Open `StatusBarController.swift` and replace the body that sets `statusItem.button?.title = …` with a call into the presenter. Keep the existing subscriptions to `awsManager.$costData` and `awsManager.$selectedProfile`. The controller now holds an `AppearanceManager` and `MenuBarOptions` reference.

Replacement block (near the top of `StatusBarController`):

```swift
private let presenter: MenuBarPresenter
let appearance: AppearanceManager
private var options = MenuBarOptions()

init(awsManager: AWSManager, appearance: AppearanceManager) {
    self.awsManager = awsManager
    self.appearance = appearance
    self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    self.presenter = MenuBarPresenter(button: statusItem.button!)
    // existing popover/hosting-controller setup continues here, unchanged
    bindUpdates()
}

private func bindUpdates() {
    // Any @Published change on awsManager or appearance republishes the menu bar.
    // Use Combine .combineLatest(…) to coalesce:
    // profile, cost, dailyServiceCostsByProfile, budgetFraction,
    // appearance.appearance, and a 60s ticker.
    // On each tick, call `renderStatusItem()`.
}

private func renderStatusItem() {
    let a = appearance.appearance
    let accent    = NSColor(LedgerTokens.Color.accent(a))
    let overColor = NSColor(LedgerTokens.Color.signalOver(a))
    let amount = Double(truncating: awsManager.costData.first?.amount as NSDecimalNumber? ?? 0)
    let delta  = awsManager.deltaFractionVsLastMonth   // see note below
    let budgetUsed = awsManager.budgetFraction ?? 0.0
    let sparkline  = awsManager.dailyTotalsForSelectedProfile ?? []

    presenter.render(
        amount: amount,
        delta: delta,
        budgetUsed: budgetUsed,
        sparkline: sparkline,
        options: options,
        accent: accent,
        overBudget: overColor
    )
}
```

Exact binding points (search-and-replace):

1. `StatusBarController.swift` top of file — add `import Combine`.
2. Delete every block that currently builds `statusItem.button?.title` string manually. Replace with `renderStatusItem()` calls at the same sites.
3. Add Combine subscriptions in `bindUpdates()`:

```swift
Publishers.CombineLatest4(
    awsManager.$selectedProfile,
    awsManager.$costData,
    awsManager.$dailyServiceCostsByProfile,
    appearance.$appearance
)
.receive(on: DispatchQueue.main)
.sink { [weak self] _, _, _, _ in self?.renderStatusItem() }
.store(in: &cancellables)
```

- [ ] **Step 3: Add required properties to AWSManager**

If `deltaFractionVsLastMonth`, `budgetFraction`, and `dailyTotalsForSelectedProfile` don't already exist, add them as computed convenience getters in `AWSManager.swift`. They each compose existing published data:

```swift
// MARK: - Ledger menu bar derived values
var deltaFractionVsLastMonth: Double? {
    guard let cost = costData.first,
          let lastMTD = lastMonthMTDData[cost.profileName],
          NSDecimalNumber(decimal: lastMTD.amount).doubleValue > 0 else { return nil }
    let now = NSDecimalNumber(decimal: cost.amount).doubleValue
    let prev = NSDecimalNumber(decimal: lastMTD.amount).doubleValue
    return (now - prev) / prev
}

var budgetFraction: Double? {
    guard let p = selectedProfile else { return nil }
    let b = getBudget(for: p.name)
    guard b.monthlyBudget > 0,
          let amount = costData.first?.amount else { return nil }
    return NSDecimalNumber(decimal: amount).doubleValue / b.monthlyBudget
}

var dailyTotalsForSelectedProfile: [Double]? {
    guard let p = selectedProfile,
          let daily = dailyServiceCostsByProfile[p.name] else { return nil }
    // Sum services per day; keep chronological order.
    let grouped = Dictionary(grouping: daily, by: { $0.date })
    let sorted = grouped.keys.sorted()
    return sorted.map { day in
        grouped[day]!
            .map { NSDecimalNumber(decimal: $0.amount).doubleValue }
            .reduce(0, +)
    }
}
```

- [ ] **Step 4: Build + verify visually**

```bash
xcodebuild -scheme AWSCostMonitor -configuration Debug -destination 'platform=macOS' build
open /Users/jackson/Library/Developer/Xcode/DerivedData/AWSCostMonitor-*/Build/Products/Debug/AWSCostMonitor.app
```

Click the menu-bar item, then open Settings → Appearance (once built in Phase 8) to toggle presets. For now, verify `iconFigure` default renders the icon and amber figure.

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(ledger): wire MenuBarPresenter into StatusBarController"
```

---

## Phase 7 — Popover rewrite

### Task 7.1: ProfileRow component

**Files:**
- Create: `packages/app/AWSCostMonitor/AWSCostMonitor/Popover/ProfileRow.swift`

- [ ] **Step 1: Implement**

```swift
import SwiftUI

struct ProfileRow: View {
    @EnvironmentObject var awsManager: AWSManager
    @Environment(\.ledgerAppearance) private var a
    var teamCacheOn: Bool

    var body: some View {
        HStack(spacing: LedgerTokens.Layout.unit(a)) {
            Circle()
                .fill(LedgerTokens.Color.accent(a))
                .frame(width: 6, height: 6)

            // Picker renders as a plain button; the caret is the affordance.
            Picker("", selection: $awsManager.selectedProfile) {
                ForEach(awsManager.profiles, id: \.self) { p in
                    Text(p.name).tag(Optional(p))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()

            Spacer()

            if teamCacheOn {
                Text("◉ Team")
                    .ledgerMeta()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(LedgerTokens.Color.accent(a).opacity(0.14))
                    )
                    .foregroundColor(LedgerTokens.Color.accent(a))
            }

            if let p = awsManager.selectedProfile, let r = p.region {
                Text(r).ledgerMeta()
            }
        }
        .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.75)
        .frame(height: 36)
        .ledgerSurface(.window)
    }
}
```

- [ ] **Step 2: Build**

- [ ] **Step 3: Commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/Popover/ProfileRow.swift
git commit -m "feat(ledger): ProfileRow component"
```

### Task 7.2: HeroSplit component (left hero + right kv grid)

**Files:**
- Create: `packages/app/AWSCostMonitor/AWSCostMonitor/Popover/HeroSplit.swift`

- [ ] **Step 1: Implement**

```swift
import SwiftUI

struct HeroSplit: View {
    @Environment(\.ledgerAppearance) private var a
    let mtd: Double
    let sparkline: [Double]
    let rows: [KV]

    struct KV: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let color: KVColor
        enum KVColor { case ink, accent, over, under }
    }

    var body: some View {
        HStack(spacing: 0) {
            // LEFT
            VStack(alignment: .leading, spacing: LedgerTokens.Layout.unit(a) / 2) {
                Text("MTD").ledgerLabel()
                Text(formatted(mtd)).ledgerHero()
                Sparkline(values: sparkline)
                    .frame(height: 28)
            }
            .padding(LedgerTokens.Layout.unit(a) * 1.5)
            .frame(maxWidth: .infinity, alignment: .topLeading)

            Rectangle()
                .fill(LedgerTokens.Color.surfaceHairline(a))
                .frame(width: LedgerTokens.Layout.hairlineWidth(a))

            // RIGHT
            VStack(alignment: .trailing, spacing: 3) {
                ForEach(rows) { row in
                    HStack {
                        Text(row.label).ledgerLabel()
                        Spacer()
                        Text(row.value)
                            .ledgerStatValue()
                            .foregroundColor(color(for: row.color))
                    }
                    .frame(height: 16)
                }
            }
            .padding(LedgerTokens.Layout.unit(a) * 1.5)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(height: 120)
    }

    private func color(for k: KV.KVColor) -> SwiftUI.Color {
        switch k {
        case .ink:    return LedgerTokens.Color.inkPrimary(a)
        case .accent: return LedgerTokens.Color.accent(a)
        case .over:   return LedgerTokens.Color.signalOver(a)
        case .under:  return LedgerTokens.Color.signalUnder(a)
        }
    }

    private func formatted(_ v: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency; nf.currencyCode = "USD"
        nf.minimumFractionDigits = 2; nf.maximumFractionDigits = 2
        return nf.string(from: NSNumber(value: v)) ?? ""
    }
}

struct Sparkline: View {
    @Environment(\.ledgerAppearance) private var a
    let values: [Double]
    var body: some View {
        GeometryReader { geo in
            let maxV = (values.max() ?? 0) > 0 ? values.max()! : 1
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(values.indices, id: \.self) { i in
                    let h = CGFloat(values[i] / maxV) * geo.size.height
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LedgerTokens.Color.accent(a).opacity(i == values.count - 1 ? 1 : 0.7))
                        .frame(height: max(1, h))
                }
            }
        }
    }
}
```

- [ ] **Step 2: Build**

- [ ] **Step 3: Commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/Popover/HeroSplit.swift
git commit -m "feat(ledger): HeroSplit component with inline sparkline"
```

### Task 7.3: ServiceList component (6-row grid)

**Files:**
- Create: `packages/app/AWSCostMonitor/AWSCostMonitor/Popover/ServiceList.swift`

- [ ] **Step 1: Implement**

```swift
import SwiftUI

struct ServiceList: View {
    @Environment(\.ledgerAppearance) private var a
    let services: [ServiceCost]     // from CostModels.swift
    let total: Double
    let onSelect: (String) -> Void  // service name

    var body: some View {
        let top = Array(services.prefix(5))
        let other = services.dropFirst(5).map { NSDecimalNumber(decimal: $0.amount).doubleValue }.reduce(0, +)
        VStack(spacing: 0) {
            ForEach(top, id: \.serviceName) { row(for: $0.serviceName, amount: NSDecimalNumber(decimal: $0.amount).doubleValue) }
            if other > 0 { row(for: "Other", amount: other) }
        }
        .frame(height: 180, alignment: .top)
    }

    private func row(for name: String, amount: Double) -> some View {
        let pct = total > 0 ? amount / total : 0
        return HStack {
            Text(name).ledgerBody()
            Text(String(format: "%.0f%%", pct * 100)).ledgerMeta()
            Spacer()
            Text(format(amount)).ledgerStatValue()
        }
        .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.75)
        .frame(height: LedgerTokens.Layout.rowHeight(a))
        .contentShape(Rectangle())
        .onTapGesture { onSelect(name) }
        .onHover { hovering in
            // hover styling handled by ambient LedgerHover modifier in a later task
        }
    }

    private func format(_ v: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency; nf.currencyCode = "USD"
        nf.minimumFractionDigits = 2; nf.maximumFractionDigits = 2
        return nf.string(from: NSNumber(value: v)) ?? ""
    }
}
```

- [ ] **Step 2: Build**

- [ ] **Step 3: Commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/Popover/ServiceList.swift
git commit -m "feat(ledger): ServiceList component"
```

### Task 7.4: FooterActions component (4 buttons)

**Files:**
- Create: `packages/app/AWSCostMonitor/AWSCostMonitor/Popover/FooterActions.swift`

- [ ] **Step 1: Implement**

```swift
import SwiftUI

struct FooterActions: View {
    @Environment(\.ledgerAppearance) private var a
    var onRefresh: () -> Void
    var onCalendar: () -> Void
    var onConsole: () -> Void
    var onOverflow: () -> Void

    var body: some View {
        HStack(spacing: LedgerTokens.Layout.unit(a)) {
            button(label: "Refresh",  primary: true,  action: onRefresh)
            button(label: "Calendar", primary: false, action: onCalendar)
            button(label: "Console",  primary: false, action: onConsole)
            button(label: "⋯",        primary: false, action: onOverflow)
        }
        .padding(LedgerTokens.Layout.unit(a) * 1.5)
        .frame(height: 44)
    }

    private func button(label: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(LedgerTokens.Typography.meta(a))
                .foregroundColor(primary ? LedgerTokens.Color.accent(a) : LedgerTokens.Color.inkSecondary(a))
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(primary
                              ? LedgerTokens.Color.accent(a).opacity(0.10)
                              : LedgerTokens.Color.surfaceElevated(a))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(primary
                              ? LedgerTokens.Color.accent(a).opacity(0.28)
                              : LedgerTokens.Color.surfaceHairline(a),
                              lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Build**

- [ ] **Step 3: Commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/Popover/FooterActions.swift
git commit -m "feat(ledger): FooterActions component"
```

### Task 7.5: Rewrite `PopoverContentView`

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Views/PopoverContentView.swift`

- [ ] **Step 1: Full replacement**

Replace the contents with:

```swift
import SwiftUI
import Charts

struct PopoverContentView: View {
    @EnvironmentObject var awsManager: AWSManager
    @EnvironmentObject var appearance: AppearanceManager

    var body: some View {
        VStack(spacing: 0) {
            ProfileRow(teamCacheOn: teamCacheEnabled)

            LedgerHairlineDivider()

            HeroSplit(
                mtd: mtd,
                sparkline: awsManager.dailyTotalsForSelectedProfile ?? [],
                rows: heroRows
            )

            LedgerHairlineDivider()

            ServiceList(
                services: serviceCosts,
                total: mtd,
                onSelect: { service in
                    CalendarWindowController.showCalendarWindow(awsManager: awsManager, highlightedService: service)
                }
            )

            LedgerHairlineDivider()

            FooterActions(
                onRefresh: { Task { await awsManager.fetchCostForSelectedProfile(force: true) } },
                onCalendar: { CalendarWindowController.showCalendarWindow(awsManager: awsManager) },
                onConsole: { openConsole() },
                onOverflow: { openOverflowMenu() }
            )
        }
        .frame(width: 360, height: 440)
        .ledgerSurface(.window)
        .environment(\.ledgerAppearance, appearance.appearance)
    }

    // MARK: - Derived

    private var mtd: Double {
        guard let c = awsManager.costData.first else { return 0 }
        return NSDecimalNumber(decimal: c.amount).doubleValue
    }

    private var serviceCosts: [ServiceCost] {
        guard let profile = awsManager.selectedProfile,
              let entry = awsManager.costCache[profile.name] else { return [] }
        return entry.serviceCosts.sorted { $0.amount > $1.amount }
    }

    private var teamCacheEnabled: Bool {
        #if !OPENSOURCE
        guard let p = awsManager.selectedProfile else { return false }
        return awsManager.getTeamCacheSettings(for: p.name).teamCacheEnabled
        #else
        return false
        #endif
    }

    private var heroRows: [HeroSplit.KV] {
        var out: [HeroSplit.KV] = []
        if let delta = awsManager.deltaFractionVsLastMonth {
            let sign = delta >= 0 ? "▲" : "▼"
            out.append(.init(
                label: "Δ vs last",
                value: "\(sign) \(String(format: "%.1f", abs(delta * 100)))%",
                color: delta >= 0 ? .over : .under
            ))
        }
        if let f = awsManager.projectedMonthlyTotal {
            let nf = NumberFormatter(); nf.numberStyle = .currency; nf.currencyCode = "USD"
            nf.maximumFractionDigits = 0
            let str = nf.string(from: NSDecimalNumber(decimal: f)) ?? ""
            out.append(.init(
                label: "Forecast",
                value: str,
                color: awsManager.projectedMonthlyTotalSource == .costExplorer ? .accent : .ink
            ))
        }
        if let p = awsManager.selectedProfile, let last = awsManager.lastMonthData[p.name] {
            let nf = NumberFormatter(); nf.numberStyle = .currency; nf.currencyCode = "USD"
            nf.maximumFractionDigits = 0
            out.append(.init(label: "Last mo", value: nf.string(from: NSDecimalNumber(decimal: last.amount)) ?? "", color: .ink))
        }
        if let daily = awsManager.dailyTotalsForSelectedProfile, !daily.isEmpty {
            let burn = daily.reduce(0, +) / Double(daily.count)
            out.append(.init(label: "Burn / day", value: String(format: "$%.2f", burn), color: .ink))
        }
        if let f = awsManager.budgetFraction {
            out.append(.init(
                label: "Budget",
                value: String(format: "%.0f%%", f * 100),
                color: f > 1.0 ? .over : .ink
            ))
        }
        if let p = awsManager.selectedProfile, let entry = awsManager.costCache[p.name] {
            let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
            out.append(.init(label: "Updated", value: fmt.string(from: entry.fetchDate), color: .ink))
        }
        return out
    }

    private func openConsole() {
        guard let p = awsManager.selectedProfile else { return }
        let region = p.region ?? "us-east-1"
        if let url = URL(string: "https://\(region).console.aws.amazon.com/billing/home") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openOverflowMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Settings",     action: #selector(NSApp.sendAction(_:to:from:)), keyEquivalent: ",")
        menu.addItem(withTitle: "Help",         action: nil, keyEquivalent: "?")
        menu.addItem(withTitle: "Export",       action: nil, keyEquivalent: "e")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit",         action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")
        // Attach NSMenu targets in the AppDelegate, same as today.
        if let event = NSApp.currentEvent { NSMenu.popUpContextMenu(menu, with: event, for: NSApp.keyWindow?.contentView ?? NSView()) }
    }
}
```

- [ ] **Step 2: Build and run**

`xcodebuild -scheme AWSCostMonitor -configuration Debug -destination 'platform=macOS' build`

- [ ] **Step 3: Sanity-check visually**

- Menu bar click opens a 360×440 popover.
- Hero figure is amber mono; sparkline under it.
- Right column has 6 rows of kv pairs.
- Service list shows up to 5 services + Other.
- Footer has 4 buttons. Refresh triggers a fetch.

- [ ] **Step 4: Commit**

```bash
git commit -am "feat(ledger): rewrite popover against new components"
```

---

## Phase 8 — Settings Appearance tab

### Task 8.1: Rewrite `AppearanceSettingsTab`

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Views/AppearanceSettingsTab.swift`

- [ ] **Step 1: Full replacement**

```swift
import SwiftUI

struct AppearanceSettingsTab: View {
    @EnvironmentObject var appearance: AppearanceManager
    @Environment(\.ledgerAppearance) private var a
    @State private var options = MenuBarOptions()

    var body: some View {
        Form {
            Section("Color scheme") {
                Picker("", selection: Binding(
                    get: { appearance.schemePreference },
                    set: { appearance.setSchemePreference($0) }
                )) {
                    ForEach(LedgerSchemePreference.allCases) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Accent") {
                HStack(spacing: 12) {
                    ForEach(LedgerAccent.allCases) { accent in
                        AccentSwatch(accent: accent, selected: appearance.appearance.accent == accent)
                            .onTapGesture { appearance.setAccent(accent) }
                    }
                }
            }

            Section("Density") {
                Picker("", selection: Binding(
                    get: { appearance.appearance.density },
                    set: { appearance.setDensity($0) }
                )) {
                    ForEach(LedgerDensity.allCases) { d in Text(d.displayName).tag(d) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Contrast") {
                Toggle("WCAG AAA contrast", isOn: Binding(
                    get: { appearance.appearance.contrast == .aaa },
                    set: { appearance.setContrast($0 ? .aaa : .standard) }
                ))
            }

            Section("Menu bar") {
                Picker("Presentation", selection: Binding(
                    get: { options.preset },
                    set: { options.preset = $0; NotificationCenter.default.post(name: .menuBarOptionsChanged, object: nil) }
                )) {
                    ForEach(MenuBarPreset.allCases) { p in Text(p.displayName).tag(p) }
                }
                Toggle("Hide cents", isOn: Binding(
                    get: { options.hideCents },
                    set: { options.hideCents = $0; NotificationCenter.default.post(name: .menuBarOptionsChanged, object: nil) }
                ))
                Toggle("Show delta (↑ / ↓ %)", isOn: Binding(
                    get: { options.showDelta },
                    set: { options.showDelta = $0; NotificationCenter.default.post(name: .menuBarOptionsChanged, object: nil) }
                ))
                Toggle("Auto-abbreviate above $10k", isOn: Binding(
                    get: { options.autoAbbreviate },
                    set: { options.autoAbbreviate = $0; NotificationCenter.default.post(name: .menuBarOptionsChanged, object: nil) }
                ))
            }
        }
        .padding(20)
        .ledgerSurface(.window)
    }
}

private struct AccentSwatch: View {
    @Environment(\.ledgerAppearance) private var a
    let accent: LedgerAccent
    let selected: Bool
    var body: some View {
        let previewAppearance = LedgerAppearance(
            colorScheme: a.colorScheme, accent: accent,
            density: a.density, contrast: a.contrast
        )
        return VStack(spacing: 6) {
            Circle()
                .fill(LedgerTokens.Color.accent(previewAppearance))
                .frame(width: 32, height: 32)
                .overlay(
                    Circle().stroke(
                        selected ? LedgerTokens.Color.inkPrimary(a) : .clear,
                        lineWidth: 2
                    )
                )
            Text(accent.displayName).ledgerMeta()
        }
    }
}

extension Notification.Name {
    static let menuBarOptionsChanged = Notification.Name("ledger.menuBarOptionsChanged")
}
```

- [ ] **Step 2: Hook `menuBarOptionsChanged` in `StatusBarController`**

In `bindUpdates()` add:

```swift
NotificationCenter.default.publisher(for: .menuBarOptionsChanged)
    .receive(on: DispatchQueue.main)
    .sink { [weak self] _ in
        self?.options = MenuBarOptions()
        self?.renderStatusItem()
    }
    .store(in: &cancellables)
```

- [ ] **Step 3: Build, open Settings → Appearance, toggle every control, confirm menu bar reacts**

- [ ] **Step 4: Commit**

```bash
git commit -am "feat(ledger): Appearance settings tab with all four axes"
```

---

## Phase 9 — App root wiring + deletes

### Task 9.1: Install `AppearanceManager` at the app root

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/AWSCostMonitorApp.swift`

- [ ] **Step 1: Patch the app entry**

```swift
@main
struct AWSCostMonitorApp: App {
    @StateObject private var awsManager = AWSManager()
    @StateObject private var appearance = AppearanceManager()

    init() {
        appearance.runLegacyMigrationIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra("AWSCostMonitor", systemImage: "dollarsign.circle") {
            PopoverContentView()
                .environmentObject(awsManager)
                .environmentObject(appearance)
                .environment(\.ledgerAppearance, appearance.appearance)
        }
        .menuBarExtraStyle(.window)
    }
}
```

- [ ] **Step 2: Observe system appearance changes**

Where the app registers for `NSApp.appearance` KVO today, add:

```swift
appearance.systemAppearanceDidChange()
```

…and also call `appearance.objectWillChange.send()` inside the subscriber so dependent views re-render.

- [ ] **Step 3: Build, launch, verify dark/light system toggling refreshes the popover**

- [ ] **Step 4: Commit**

```bash
git commit -am "feat(ledger): install AppearanceManager at app root and run migration"
```

### Task 9.2: Delete legacy theme system

**Files:**
- Delete: `packages/app/AWSCostMonitor/AWSCostMonitor/Models/Theme.swift`
- Delete: `packages/app/AWSCostMonitor/AWSCostMonitor/Managers/ThemeManager.swift`
- Delete: `packages/app/AWSCostMonitor/AWSCostMonitor/Utilities/ThemeExtensions.swift`
- Delete: `packages/app/AWSCostMonitor/AWSCostMonitorTests/ThemeTests.swift`
- Delete: `packages/app/AWSCostMonitor/AWSCostMonitorTests/ThemedCalendarTests.swift`
- Delete: `packages/app/AWSCostMonitor/AWSCostMonitorTests/ThemedDropdownTests.swift`
- Delete: `packages/app/AWSCostMonitor/AWSCostMonitorTests/ThemedMenuBarTests.swift`
- Delete: `packages/app/AWSCostMonitor/AWSCostMonitorTests/ThemeSettingsUITests.swift`

- [ ] **Step 1: Remove files and resolve every compile error**

```bash
git rm \
  packages/app/AWSCostMonitor/AWSCostMonitor/Models/Theme.swift \
  packages/app/AWSCostMonitor/AWSCostMonitor/Managers/ThemeManager.swift \
  packages/app/AWSCostMonitor/AWSCostMonitor/Utilities/ThemeExtensions.swift \
  packages/app/AWSCostMonitor/AWSCostMonitorTests/ThemeTests.swift \
  packages/app/AWSCostMonitor/AWSCostMonitorTests/ThemedCalendarTests.swift \
  packages/app/AWSCostMonitor/AWSCostMonitorTests/ThemedDropdownTests.swift \
  packages/app/AWSCostMonitor/AWSCostMonitorTests/ThemedMenuBarTests.swift \
  packages/app/AWSCostMonitor/AWSCostMonitorTests/ThemeSettingsUITests.swift
```

Then run:

```bash
xcodebuild -scheme AWSCostMonitor -configuration Debug -destination 'platform=macOS' build 2>&1 | grep error:
```

For every error that references `.themeFont(…)`, `.themePadding(…)`, `@Environment(\.theme)`, `ThemeManager`, or a specific theme struct, replace the call site with a Ledger modifier or `LedgerTokens` accessor. Common replacements:

| Remove | Replace with |
| --- | --- |
| `@Environment(\.theme) var theme` | `@Environment(\.ledgerAppearance) private var a` |
| `.themeFont(theme, size: .large, weight: .secondary)` | `.ledgerStatValue()` or `.ledgerHero()` (depending on prior size) |
| `.themePadding(theme)` | `.padding(LedgerTokens.Layout.unit(a) * 1.5)` |
| `theme.accentColor` | `LedgerTokens.Color.accent(a)` |
| `theme.errorColor` | `LedgerTokens.Color.signalOver(a)` |
| `theme.successColor` | `LedgerTokens.Color.signalUnder(a)` |
| `theme.backgroundColor` | `LedgerTokens.Color.surfaceWindow(a)` |

Files known to reference these (`grep -rl "theme\." packages/app/AWSCostMonitor/AWSCostMonitor/Views`):
- `ContentView.swift`
- `PopoverContentView.swift` (already rewritten)
- `CalendarView.swift` (will be rewritten in Plan B — for now, migrate tokens inline)
- `DayDetailView.swift`
- `RealHistogramView.swift`
- `ServiceHistogramView.swift`
- `MenuButton.swift`
- `TeamCacheStatusView.swift`

Migrate each mechanically. Do not change layouts in Plan A; just swap tokens so the app compiles.

- [ ] **Step 2: Full build + full test run**

```bash
xcodebuild test -scheme AWSCostMonitor -configuration Debug -destination 'platform=macOS' 2>&1 | tail -20
```

Expected: every test passes (remaining ones are non-theme suites).

- [ ] **Step 3: Commit**

```bash
git commit -am "chore(ledger): remove legacy theme system, migrate token references"
```

---

## Phase 10 — Version bump and release notes

### Task 10.1: Bump to 1.5.0

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Info.plist` (or the Xcode project-level version)

- [ ] **Step 1: Use `agvtool` to bump**

```bash
cd packages/app/AWSCostMonitor
agvtool new-marketing-version 1.5.0
agvtool new-version -all 8
```

- [ ] **Step 2: Commit**

```bash
git commit -am "chore: bump version to 1.5.0 (build 8) for Ledger release"
```

### Task 10.2: What's New dialog

**Files:**
- Create: `packages/app/AWSCostMonitor/AWSCostMonitor/Views/WhatsNewV15.swift`
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/AWSCostMonitorApp.swift`

- [ ] **Step 1: Simple window presenting the redesign highlights**

```swift
import SwiftUI

struct WhatsNewV15: View {
    @Environment(\.ledgerAppearance) private var a
    var body: some View {
        VStack(alignment: .leading, spacing: LedgerTokens.Layout.unit(a) * 2) {
            Text("Ledger").ledgerHero()
            Text("A redesigned AWSCostMonitor for v1.5.").ledgerBody()
            Divider().background(LedgerTokens.Color.surfaceHairline(a))
            Text("One opinionated identity, four orthogonal controls.")
                .ledgerBody()
            Text("• Accent: Amber · Mint · Plasma · Bone")
            Text("• Density: Comfortable · Compact")
            Text("• Contrast: Standard · WCAG AAA")
            Text("• Color scheme: Follow system / Always light / Always dark")
            Spacer()
            Text("Open Settings → Appearance to tune any of them.").ledgerMeta()
        }
        .padding(24)
        .frame(width: 440, height: 340)
        .ledgerSurface(.window)
    }
}
```

Show the window on first launch of 1.5.0 (guard with a `UserDefaults` flag `shownWhatsNew.1.5.0`). Use `NSWindow(contentRect:styleMask:backing:defer:)` + `hostingController.sizingOptions = []` (per v1.4.2 crash fix guardrails).

- [ ] **Step 2: Commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/Views/WhatsNewV15.swift
git commit -am "feat(ledger): v1.5 what's-new window on first launch"
```

---

## Acceptance

- [ ] All tests pass: `xcodebuild test -scheme AWSCostMonitor -configuration Debug -destination 'platform=macOS'`.
- [ ] `grep -rnw "ThemeManager\|\.themeFont\|\.themePadding\|\.environment(\\\\.theme" packages/app/AWSCostMonitor/AWSCostMonitor/` returns no hits.
- [ ] Legacy files are deleted from the Xcode project (verify in the project navigator, not just on disk).
- [ ] Launching the app against a legacy `UserDefaults` state that has `selectedTheme = "terminal"` migrates the user to `accent=mint, density=compact` and sets `ledger.migrated = true`.
- [ ] All four menu-bar presets render against both dark and light system bars.
- [ ] Popover is exactly 360×440 and never scrolls.
- [ ] Settings → Appearance toggles take effect instantly in the popover and menu bar.
- [ ] App icon, Calendar interior, Multi-Profile Dashboard, Onboarding, Profile alerts, Help, Export — unchanged by this plan (handled by Plan B).
