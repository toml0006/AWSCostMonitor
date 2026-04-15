# Ledger Plan B — Secondary Surfaces (v1.5.1)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the Ledger design system to every secondary window: Calendar chrome + summary strip, Multi-Profile Dashboard, Onboarding, Profile change alerts, Help, Export.

**Architecture:** All windows read `LedgerAppearance` from the environment installed in Plan A. No new state management. Each window gets tokens, new primitives where it needs them, and an explicit migration off any remaining legacy theme calls.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit.

**Precondition:** Plan A is complete and merged. Every call site compiles against `LedgerTokens` / `.ledgerHero()` etc.

**Spec:** `docs/superpowers/specs/2026-04-15-ledger-design-system-design.md` (Section 4)

---

## File structure

**Create:**
- `AWSCostMonitor/Components/SummaryStrip.swift` — reused by Calendar and any future dashboard top bar.
- `AWSCostMonitor/Components/LedgerCard.swift` — rounded-rect container used by Dashboard + Onboarding.
- `AWSCostMonitor/Components/LedgerPrimaryButton.swift` — amber filled button.
- `AWSCostMonitor/Components/LedgerSecondaryButton.swift` — outlined button.
- `AWSCostMonitor/Components/LedgerKeyCap.swift` — `⌘R`-style key cap pill for Help.
- `AWSCostMonitorTests/SummaryStripTests.swift`
- `AWSCostMonitorTests/MultiProfileDashboardTests.swift`

**Modify:**
- `AWSCostMonitor/Views/CalendarView.swift` — chrome only (header + summary strip). Interior viz deferred.
- `AWSCostMonitor/Controllers/CalendarWindowController.swift` — already wired for hosting-controller safety in v1.4.2; add `.environment(\.ledgerAppearance, …)`.
- `AWSCostMonitor/Views/DayDetailView.swift` — tokenize.
- `AWSCostMonitor/Views/MultiProfileDashboard.swift` — full rewrite.
- `AWSCostMonitor/OnboardingView.swift` — full rewrite.
- `AWSCostMonitor/Views/ProfileChangeAlert.swift` — chrome tokenize (structure unchanged from v1.4.2 fix).
- `AWSCostMonitor/Views/ContentView.swift` (lines 850+ around help window) — tokenize Help window body.
- `AWSCostMonitor/Views/ExportView.swift` — tokenize.
- `AWSCostMonitor/Controllers/AppDelegates.swift:30-100` — inject `\\.ledgerAppearance` into Export and Settings windows' hosting controllers.
- `AWSCostMonitor/Views/TeamCacheStatusView.swift` — will now render only inside the profile row pill, not in the popover footer (leftover from Plan A). Simplify.

---

## Phase 1 — Shared components

### Task 1.1: SummaryStrip

**Files:**
- Create: `packages/app/AWSCostMonitor/AWSCostMonitor/Components/SummaryStrip.swift`
- Test: `packages/app/AWSCostMonitor/AWSCostMonitorTests/SummaryStripTests.swift`

`SummaryStrip` renders a horizontal 4-cell strip with labels and mono values, dividers between cells, amber-tinted value for the "primary" cell.

- [ ] **Step 1: Write a snapshot-free behavior test**

```swift
import XCTest
import SwiftUI
@testable import AWSCostMonitor

final class SummaryStripTests: XCTestCase {
    func testCellsExposeLabelsAndValues() {
        let cells = [
            SummaryStrip.Cell(label: "MTD", value: "$2,847", primary: true),
            SummaryStrip.Cell(label: "Forecast", value: "$4,812", primary: false),
            SummaryStrip.Cell(label: "Peak day", value: "$412", primary: false),
            SummaryStrip.Cell(label: "Avg / day", value: "$203", primary: false)
        ]
        XCTAssertEqual(cells.first?.primary, true)
        XCTAssertEqual(cells.map(\.label), ["MTD", "Forecast", "Peak day", "Avg / day"])
    }
}
```

- [ ] **Step 2: Implement**

```swift
import SwiftUI

struct SummaryStrip: View {
    struct Cell: Identifiable, Equatable {
        let id = UUID()
        var label: String
        var value: String
        var primary: Bool = false
    }

    @Environment(\.ledgerAppearance) private var a
    let cells: [Cell]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.1.id) { idx, c in
                VStack(alignment: .leading, spacing: 3) {
                    Text(c.label).ledgerLabel()
                    Text(c.value)
                        .font(LedgerTokens.Typography.statValue(a))
                        .foregroundColor(c.primary ? LedgerTokens.Color.accent(a) : LedgerTokens.Color.inkPrimary(a))
                }
                .padding(.vertical, LedgerTokens.Layout.unit(a) * 1.25)
                .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.75)
                .frame(maxWidth: .infinity, alignment: .leading)
                if idx < cells.count - 1 {
                    Rectangle().fill(LedgerTokens.Color.surfaceHairline(a)).frame(width: 1)
                }
            }
        }
        .background(LedgerTokens.Color.surfaceElevated(a))
        .overlay(
            Rectangle().fill(LedgerTokens.Color.surfaceHairline(a)).frame(height: 1),
            alignment: .bottom
        )
    }
}
```

- [ ] **Step 3: Build + test**

```bash
xcodebuild test -scheme AWSCostMonitor -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/SummaryStripTests
```

- [ ] **Step 4: Commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/Components/SummaryStrip.swift \
        packages/app/AWSCostMonitor/AWSCostMonitorTests/SummaryStripTests.swift
git commit -m "feat(ledger): SummaryStrip shared component"
```

### Task 1.2: LedgerCard, LedgerPrimaryButton, LedgerSecondaryButton

**Files:**
- Create: three files under `AWSCostMonitor/Components/`

These are pure presentation primitives; no unit tests, verified via usage in later tasks.

- [ ] **Step 1: LedgerCard**

```swift
// LedgerCard.swift
import SwiftUI

struct LedgerCard<Content: View>: View {
    @Environment(\.ledgerAppearance) private var a
    let content: () -> Content
    var padding: CGFloat? = nil

    init(padding: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding ?? LedgerTokens.Layout.unit(a) * 2)
            .background(
                RoundedRectangle(cornerRadius: LedgerTokens.Layout.cornerRadius)
                    .fill(LedgerTokens.Color.surfaceElevated(a))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LedgerTokens.Layout.cornerRadius)
                    .stroke(LedgerTokens.Color.surfaceHairline(a), lineWidth: 1)
            )
    }
}
```

- [ ] **Step 2: LedgerPrimaryButton**

```swift
// LedgerPrimaryButton.swift
import SwiftUI

struct LedgerPrimaryButton: View {
    @Environment(\.ledgerAppearance) private var a
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LedgerTokens.Typography.body(a))
                .foregroundColor(LedgerTokens.Color.accent(a))
                .padding(.vertical, LedgerTokens.Layout.unit(a))
                .padding(.horizontal, LedgerTokens.Layout.unit(a) * 2)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LedgerTokens.Color.accent(a).opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(LedgerTokens.Color.accent(a).opacity(0.32), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 3: LedgerSecondaryButton**

```swift
// LedgerSecondaryButton.swift
import SwiftUI

struct LedgerSecondaryButton: View {
    @Environment(\.ledgerAppearance) private var a
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LedgerTokens.Typography.body(a))
                .foregroundColor(LedgerTokens.Color.inkPrimary(a))
                .padding(.vertical, LedgerTokens.Layout.unit(a))
                .padding(.horizontal, LedgerTokens.Layout.unit(a) * 2)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LedgerTokens.Color.surfaceElevated(a))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(LedgerTokens.Color.surfaceHairline(a), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 4: Build + commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/Components/LedgerCard.swift \
        packages/app/AWSCostMonitor/AWSCostMonitor/Components/LedgerPrimaryButton.swift \
        packages/app/AWSCostMonitor/AWSCostMonitor/Components/LedgerSecondaryButton.swift
git commit -m "feat(ledger): LedgerCard + primary/secondary button primitives"
```

### Task 1.3: LedgerKeyCap

**Files:**
- Create: `packages/app/AWSCostMonitor/AWSCostMonitor/Components/LedgerKeyCap.swift`

- [ ] **Step 1: Implement**

```swift
import SwiftUI

/// Renders a monospace keyboard shortcut inside a rounded pill (e.g., `⌘R`).
struct LedgerKeyCap: View {
    @Environment(\.ledgerAppearance) private var a
    let keys: [String]

    init(_ keys: String...) { self.keys = keys }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(keys, id: \.self) { k in
                Text(k)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .foregroundColor(LedgerTokens.Color.inkPrimary(a))
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LedgerTokens.Color.surfaceElevated(a))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(LedgerTokens.Color.surfaceHairline(a), lineWidth: 1)
                    )
            }
        }
    }
}
```

- [ ] **Step 2: Build + commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/Components/LedgerKeyCap.swift
git commit -m "feat(ledger): LedgerKeyCap for keyboard shortcut display"
```

---

## Phase 2 — Calendar window chrome

### Task 2.1: Apply SummaryStrip + tokenize CalendarView header

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Views/CalendarView.swift`
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Controllers/CalendarWindowController.swift`

- [ ] **Step 1: Inject appearance in `CalendarWindowController`**

In `CalendarWindowController.showCalendarWindow(awsManager:highlightedService:)`, wrap the hosting controller's root view:

```swift
let root = CalendarView(highlightedService: highlightedService)
    .environmentObject(awsManager)
    .environmentObject(appearance)          // pass through at call site
    .environment(\.ledgerAppearance, appearance.appearance)
let hostingController = NSHostingController(rootView: root)
hostingController.sizingOptions = []        // preserved from v1.4.2
```

Add `appearance: AppearanceManager` as a required parameter; update call sites in popover and status bar to pass it.

- [ ] **Step 2: Replace CalendarView header + summary**

At the top of `CalendarView`, replace the existing header block with:

```swift
VStack(spacing: 0) {
    HStack {
        Text(monthTitle).ledgerStatValue()
        Spacer()
        Button(action: previousMonth) { Image(systemName: "chevron.left") }
        Button(action: nextMonth)     { Image(systemName: "chevron.right") }
    }
    .padding(.horizontal, LedgerTokens.Layout.unit(a) * 2)
    .padding(.vertical, LedgerTokens.Layout.unit(a) * 1.5)

    LedgerHairlineDivider()

    SummaryStrip(cells: [
        .init(label: "MTD",       value: formatted(mtdTotal),   primary: true),
        .init(label: "Forecast",  value: formatted(forecast),   primary: false),
        .init(label: "Peak day",  value: formatted(peakDay),    primary: false),
        .init(label: "Avg / day", value: formatted(avgPerDay),  primary: false)
    ])

    // …existing calendar interior stays as-is (heat grid); deferred to a later spec
}
.ledgerSurface(.window)
```

Delete any remaining `@Environment(\.theme)` reads and swap for `@Environment(\.ledgerAppearance) private var a`. Swap every `.themeFont(…)` for `.ledgerStatValue()` / `.ledgerLabel()` / etc. as documented in Plan A Task 9.2's replacement table.

- [ ] **Step 3: Build + verify**

```bash
xcodebuild -scheme AWSCostMonitor build 2>&1 | tail -3
```

Open the Calendar window from the popover. Confirm:
- Header is tokenized (dark/light switching works via menu-bar preset live preview).
- SummaryStrip shows 4 cells with amber MTD.
- Existing heat-grid interior is untouched (spec defers visualization choice).

- [ ] **Step 4: Commit**

```bash
git commit -am "feat(ledger): Calendar window chrome with SummaryStrip"
```

### Task 2.2: Tokenize DayDetailView

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Views/DayDetailView.swift`

- [ ] **Step 1: Mechanical token swap**

Replace every theme-dependent call using the Plan A Task 9.2 table. Wrap the root container in `.ledgerSurface(.window)`. Use `LedgerCard { … }` around any grouped sections.

- [ ] **Step 2: Verify**: click a day in Calendar, confirm Day Detail chrome uses amber/graphite tokens consistently.

- [ ] **Step 3: Commit**

```bash
git commit -am "feat(ledger): tokenize DayDetailView"
```

---

## Phase 3 — Multi-Profile Dashboard

### Task 3.1: Rewrite as cards grid

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Views/ContentView.swift` (the `MultiProfileDashboard` view lives in `ContentView.swift` currently; move it if it grows)
- Test: `packages/app/AWSCostMonitor/AWSCostMonitorTests/MultiProfileDashboardTests.swift`

- [ ] **Step 1: Extract `MultiProfileDashboard` into its own file**

Create `packages/app/AWSCostMonitor/AWSCostMonitor/Views/MultiProfileDashboard.swift`; move the existing struct there. Delete the old definition from `ContentView.swift`.

- [ ] **Step 2: Write sort-order test**

```swift
import XCTest
@testable import AWSCostMonitor

final class MultiProfileDashboardTests: XCTestCase {
    func testProfilesSortedByMTDDescending() {
        let input: [DashboardProfileSummary] = [
            .init(name: "dev", amount: 120, delta: nil, forecast: nil, sparkline: []),
            .init(name: "stg", amount: 980, delta: nil, forecast: nil, sparkline: []),
            .init(name: "prd", amount: 450, delta: nil, forecast: nil, sparkline: [])
        ]
        let sorted = DashboardProfileSummary.sortedByMTDDescending(input)
        XCTAssertEqual(sorted.map(\.name), ["stg", "prd", "dev"])
    }
}
```

- [ ] **Step 3: Define `DashboardProfileSummary` value type in `MultiProfileDashboard.swift`**

```swift
struct DashboardProfileSummary: Identifiable {
    var id: String { name }
    let name: String
    let amount: Double
    let delta: Double?
    let forecast: Double?
    let sparkline: [Double]

    static func sortedByMTDDescending(_ v: [DashboardProfileSummary]) -> [DashboardProfileSummary] {
        v.sorted { $0.amount > $1.amount }
    }
}
```

- [ ] **Step 4: Card component**

```swift
struct DashboardCard: View {
    @Environment(\.ledgerAppearance) private var a
    let profile: DashboardProfileSummary
    let onSelect: () -> Void

    var body: some View {
        LedgerCard {
            VStack(alignment: .leading, spacing: LedgerTokens.Layout.unit(a)) {
                Text(profile.name).ledgerLabel()
                Text(formatted(profile.amount)).ledgerHero()
                if let d = profile.delta {
                    Text(String(format: "%@ %.1f%%", d >= 0 ? "▲" : "▼", abs(d * 100)))
                        .ledgerMeta()
                        .foregroundColor(d >= 0 ? LedgerTokens.Color.signalOver(a) : LedgerTokens.Color.signalUnder(a))
                }
                Sparkline(values: profile.sparkline)
                    .frame(height: 28)
                if let f = profile.forecast {
                    HStack {
                        Text("Forecast").ledgerLabel()
                        Spacer()
                        Text(formatted(f)).ledgerStatValue()
                    }
                }
            }
            .frame(height: 140)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }

    private func formatted(_ v: Double) -> String {
        let nf = NumberFormatter(); nf.numberStyle = .currency; nf.currencyCode = "USD"
        nf.maximumFractionDigits = 0
        return nf.string(from: NSNumber(value: v)) ?? ""
    }
}
```

- [ ] **Step 5: Dashboard layout**

```swift
struct MultiProfileDashboard: View {
    @EnvironmentObject var awsManager: AWSManager
    @Environment(\.ledgerAppearance) private var a

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(DashboardProfileSummary.sortedByMTDDescending(awsManager.dashboardSummaries)) { p in
                    DashboardCard(profile: p) {
                        if let profile = awsManager.profiles.first(where: { $0.name == p.name }) {
                            awsManager.saveSelectedProfile(profile: profile)
                        }
                        NSApp.keyWindow?.close()
                    }
                }
            }
            .padding(16)
        }
        .ledgerSurface(.window)
    }
}
```

Add `var dashboardSummaries: [DashboardProfileSummary]` on `AWSManager` producing one summary per profile from the cost cache.

- [ ] **Step 6: Build + commit**

```bash
git add packages/app/AWSCostMonitor/AWSCostMonitor/Views/MultiProfileDashboard.swift \
        packages/app/AWSCostMonitor/AWSCostMonitorTests/MultiProfileDashboardTests.swift
git commit -am "feat(ledger): Multi-Profile Dashboard rewrite as card grid"
```

---

## Phase 4 — Onboarding

### Task 4.1: Rewrite OnboardingView

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/OnboardingView.swift`

- [ ] **Step 1: Shell with amber wordmark + step pane**

```swift
struct OnboardingView: View {
    @EnvironmentObject var awsManager: AWSManager
    @Environment(\.ledgerAppearance) private var a
    @State private var step: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            // LEFT — brand pane
            VStack(alignment: .leading, spacing: LedgerTokens.Layout.unit(a) * 2) {
                Text("Ledger").ledgerHero()
                Text("AWS Cost Monitor · v1.5")
                    .ledgerLabel()
                Spacer()
                Text("Step \(step + 1) of 3").ledgerMeta()
            }
            .padding(LedgerTokens.Layout.unit(a) * 3)
            .frame(width: 280)
            .background(LedgerTokens.Color.surfaceElevated(a))

            // RIGHT — step pane
            Group {
                switch step {
                case 0: WelcomeStep(onNext: { step = 1 })
                case 1: ProfileStep(onNext: { step = 2 })
                default: BudgetStep(onFinish: { dismiss() })
                }
            }
            .padding(LedgerTokens.Layout.unit(a) * 3)
            .frame(maxWidth: .infinity)
        }
        .ledgerSurface(.window)
    }

    private func dismiss() { NSApp.keyWindow?.close() }
}
```

Define `WelcomeStep`, `ProfileStep`, `BudgetStep` in the same file as private structs. Each uses `LedgerCard`, `LedgerPrimaryButton`, `LedgerSecondaryButton`.

- [ ] **Step 2: Hosting controller safety**

In `showOnboardingWindow(awsManager:)` (already defined at the bottom of the file), ensure:

```swift
hostingController.sizingOptions = []
let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 700, height: 550),
    styleMask: [.titled, .closable],
    backing: .buffered,
    defer: false
)
window.contentViewController = hostingController
```

(Confirmed by the v1.4.2 crash fix — retain the pattern.)

- [ ] **Step 3: Build + visual check**

Run the app with a fresh UserDefaults domain to trigger onboarding.

- [ ] **Step 4: Commit**

```bash
git commit -am "feat(ledger): Onboarding rewrite against token system"
```

---

## Phase 5 — Profile change alerts + Help + Export

### Task 5.1: Tokenize ProfileChangeAlert bodies

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Views/ProfileChangeAlert.swift`

- [ ] **Step 1: Replace raw `Text(…).font(.system(size:…))` with `.ledgerBody()` / `.ledgerLabel()` / `.ledgerHero()`**

The window chrome (fixed size, styleMask, hosting controller safety) is already correct from v1.4.2. Do not change it.

Every button should be `LedgerPrimaryButton` / `LedgerSecondaryButton`. Use `LedgerCard` around the profile-list section.

- [ ] **Step 2: Commit**

```bash
git commit -am "feat(ledger): tokenize ProfileChangeAlert bodies"
```

### Task 5.2: Rewrite Help window body

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Views/ContentView.swift` (the `HelpView` struct around line 855)

- [ ] **Step 1: Two-column layout**

```swift
struct HelpView: View {
    @Environment(\.ledgerAppearance) private var a
    @State private var selected: HelpSection = .gettingStarted

    enum HelpSection: String, CaseIterable, Identifiable {
        case gettingStarted = "Getting started"
        case profiles       = "Profiles"
        case budgets        = "Budgets"
        case teamCache      = "Team cache"
        case shortcuts      = "Keyboard shortcuts"
        var id: String { rawValue }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(HelpSection.allCases) { s in
                    Button(action: { selected = s }) {
                        HStack {
                            Text(s.rawValue).ledgerBody()
                            Spacer()
                        }
                        .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.5)
                        .padding(.vertical, LedgerTokens.Layout.unit(a))
                        .background(
                            selected == s
                                ? LedgerTokens.Color.accent(a).opacity(0.10)
                                : .clear
                        )
                        .overlay(
                            Rectangle()
                                .fill(selected == s ? LedgerTokens.Color.accent(a) : .clear)
                                .frame(width: 2),
                            alignment: .leading
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .frame(width: 180)
            .background(LedgerTokens.Color.surfaceElevated(a))

            ScrollView {
                HelpArticle(section: selected)
                    .padding(LedgerTokens.Layout.unit(a) * 3)
            }
        }
        .ledgerSurface(.window)
    }
}

private struct HelpArticle: View {
    @Environment(\.ledgerAppearance) private var a
    let section: HelpView.HelpSection

    var body: some View {
        VStack(alignment: .leading, spacing: LedgerTokens.Layout.unit(a) * 2) {
            Text(section.rawValue).ledgerHero()
            switch section {
            case .shortcuts:
                VStack(alignment: .leading, spacing: 8) {
                    row(keys: ["⌘", "R"],  label: "Refresh")
                    row(keys: ["⌘", "K"],  label: "Open Calendar")
                    row(keys: ["⌘", ","],  label: "Settings")
                    row(keys: ["⌘", "1–9"], label: "Switch profile")
                }
            default:
                Text(copy(for: section)).ledgerBody()
            }
        }
    }

    private func row(keys: [String], label: String) -> some View {
        HStack {
            LedgerKeyCap(keys.first ?? "", keys.last ?? "")
            Text(label).ledgerBody()
            Spacer()
        }
    }

    private func copy(for s: HelpView.HelpSection) -> String {
        switch s {
        case .gettingStarted: return "Click the amber figure in the menu bar to open the popover. MTD spending is the hero figure; forecast, delta, and service breakdown are shown to the right."
        case .profiles:       return "Switch AWS profiles from the header of the popover. Cost data is cached per profile."
        case .budgets:        return "Set a monthly budget per profile in Settings → Profiles. Budget use appears as a percentage and turns red when exceeded."
        case .teamCache:      return "Team cache lets multiple teammates share the same cost fetch via an S3-backed store."
        case .shortcuts:      return ""
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git commit -am "feat(ledger): Help window rewrite with key-cap shortcuts"
```

### Task 5.3: Tokenize ExportView

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Views/ExportView.swift`

- [ ] **Step 1: Replace theme references + raw sizes**

Use the Plan A Task 9.2 table. Wrap the table in `LedgerCard`. Replace the Export button with `LedgerPrimaryButton`.

- [ ] **Step 2: Commit**

```bash
git commit -am "feat(ledger): tokenize Export window"
```

---

## Phase 6 — TeamCacheStatusView cleanup

### Task 6.1: Remove leftover popover-footer code

**Files:**
- Modify: `packages/app/AWSCostMonitor/AWSCostMonitor/Views/TeamCacheStatusView.swift`

Plan A removed the popover-footer instance of this view but left the component in place. It's now rendered only inline in the profile row pill. If nothing else depends on the full view, delete it. If the Settings tab still shows a larger status panel, tokenize but keep.

- [ ] **Step 1: `grep -rn TeamCacheStatusView packages/app/AWSCostMonitor/AWSCostMonitor/`** — list callers.

- [ ] **Step 2:** If only Settings uses it, tokenize; if unused, `git rm` and remove from project.

- [ ] **Step 3: Commit**

```bash
git commit -am "chore(ledger): clean up TeamCacheStatusView call sites"
```

---

## Phase 7 — Version bump

### Task 7.1: Bump to 1.5.1

```bash
cd packages/app/AWSCostMonitor
agvtool new-marketing-version 1.5.1
agvtool new-version -all 9
git commit -am "chore: bump version to 1.5.1 (build 9)"
```

---

## Acceptance

- [ ] Full-app grep for `themeFont\|themePadding\|ThemeManager\|@Environment(\\\\.theme` returns zero.
- [ ] All tests pass.
- [ ] Calendar window: header + summary strip render in Ledger tokens; interior heat grid untouched.
- [ ] Multi-Profile Dashboard renders a grid of cards sorted MTD desc; clicking a card switches profile and closes the dashboard window.
- [ ] Onboarding: 3-step flow, amber wordmark on left, step pane on right.
- [ ] Profile change alerts: bodies use Ledger tokens; the fixed sizes from v1.4.2 are preserved.
- [ ] Help: two-column layout, key-cap pills for shortcuts.
- [ ] Export: Ledger primary button; tokenized table.
