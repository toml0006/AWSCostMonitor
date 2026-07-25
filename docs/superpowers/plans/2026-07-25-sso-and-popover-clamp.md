# AWS SSO Support & Popover Clamp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the menu bar popover stop clipping off the right screen edge, and make AWS SSO profiles and `role_arn`/`source_profile` chains actually work in the sandboxed App Store build.

**Architecture:** Popover sizing moves from an asynchronous UserDefaults channel to a synchronous `ObservableObject`, the content-shrinking clamp is replaced by a window-moving clamp anchored in `popoverDidShow`, and all geometry becomes pure testable functions. Credential handling gains a classifying config parser, an SSO token cache that reads the AWS CLI's cache, a recursive credential resolver with cycle guarding and expiry-based caching, and an in-app SSOOIDC device-authorization sign-in whose tokens live in the Keychain.

**Tech Stack:** Swift 5, SwiftUI, AppKit, XCTest, `aws-sdk-swift` 1.5.12 (`AWSCostExplorer`, `AWSSTS`, `AWSSavingsplans` already linked; `AWSSSO` and `AWSSSOOIDC` to be added), `AWSSDKIdentity`, `SmithyIdentity`, Security.framework.

## Global Constraints

- **Spec:** `docs/superpowers/specs/2026-07-25-sso-and-popover-clamp-design.md`. Read it before starting.
- **Project root for all paths below:** `packages/app/AWSCostMonitor/`.
- **Source dir:** `packages/app/AWSCostMonitor/AWSCostMonitor/`. **Test dir:** `packages/app/AWSCostMonitor/AWSCostMonitorTests/`.
- **Test command — use the script, not `xcodebuild test`.** Run from the repo root:
  ```bash
  ./scripts/run-tests.sh                       # whole suite
  ./scripts/run-tests.sh PopoverGeometryTests  # one class
  ./scripts/run-tests.sh PopoverGeometryTests/testDesiredThatFitsIsReturnedUnchanged
  ```
  The first build compiles the whole AWS SDK and takes several minutes. Later runs are incremental (~20s).
- **Do not use `xcodebuild test`.** It fails in any non-GUI context with
  `Failed to install or launch the test runner … LaunchServices has returned error -10699 … Launch prevented due to "prevent launch" assertion`.
  The test host is the app itself, a menu bar agent (`LSUIElement`), and macOS refuses to launch it headlessly. This is an environment failure, not a red test. `scripts/run-tests.sh` sidesteps it by loading the bundle with `xcrun xctest`, which never involves LaunchServices; it also symlinks the host's `AWSCostMonitor.debug.dylib` into `PackageFrameworks/` because the bundle links it via `@rpath`.
- **Build-only check** (faster than a test run when you just want compile errors):
  ```bash
  cd packages/app/AWSCostMonitor && xcodebuild build-for-testing \
    -project AWSCostMonitor.xcodeproj -scheme AWSCostMonitor -destination 'platform=macOS' -quiet
  ```
- **New files must be added to the `AWSCostMonitor` target** (or `AWSCostMonitorTests` for tests) in `AWSCostMonitor.xcodeproj`. This project does not use a filesystem-synchronized group; a new `.swift` file that is not registered in `project.pbxproj` will not compile and the failure looks like "cannot find X in scope". Add the file reference, then verify with a build before writing more code.
- **Rate limiting is a product invariant** (`.agent-os/product/decisions.md` DEC-002): never introduce a code path that issues more AWS API calls per refresh than the one it replaces. Credential caching in Tasks 8 and 9 exists to satisfy this.
- **Privacy is a product invariant** (DEC-003): no telemetry, no external services. Tokens and credentials stay on the machine.
- **The entitlements file stays read-only.** Do not add `com.apple.security.files.user-selected.read-write` to `AWSCostMonitor/AWSCostMonitor.entitlements`. App-minted SSO tokens go to the Keychain; the AWS CLI's cache is read but never written.
- **Do not use `any` types** — the user's global standard forbids untyped escape hatches. In Swift, prefer concrete types and protocols over `Any`/`AnyObject`.
- **Comment style** (`~/.agent-os/standards/code-style.md`): comment the "why", not the "what". Several comments in the existing code record hard-won AppKit knowledge — preserve them unless the code they describe is deleted.

---

## Phase 1 — Popover Clamp (Tasks 1–3)

Independently releasable. Fixes the user-visible clipping.

### Task 1: Pure popover geometry

**Files:**
- Create: `AWSCostMonitor/Utilities/PopoverSizing.swift`
- Test: `AWSCostMonitorTests/PopoverGeometryTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `enum PopoverGeometry` with `static let minWidth: CGFloat`, `static let edgeMargin: CGFloat`, `static func availableWidth(screenWidth: CGFloat) -> CGFloat`, `static func clampedWidth(desired: CGFloat, availableWidth: CGFloat) -> CGFloat`, `static func clampedOriginX(idealX: CGFloat, width: CGFloat, visible: NSRect) -> CGFloat`. Also `final class PopoverSizing: ObservableObject` with `@Published var availableWidth: CGFloat`.

- [ ] **Step 1: Write the failing test**

Create `AWSCostMonitorTests/PopoverGeometryTests.swift`:

```swift
import XCTest
import AppKit
@testable import AWSCostMonitor

final class PopoverGeometryTests: XCTestCase {

    // MARK: availableWidth

    func testAvailableWidthSubtractsBothMargins() {
        XCTAssertEqual(
            PopoverGeometry.availableWidth(screenWidth: 1440),
            1440 - 2 * PopoverGeometry.edgeMargin
        )
    }

    // MARK: clampedWidth

    func testDesiredBelowMinimumIsRaisedToMinimum() {
        XCTAssertEqual(
            PopoverGeometry.clampedWidth(desired: 360, availableWidth: 1416),
            PopoverGeometry.minWidth
        )
    }

    func testDesiredThatFitsIsReturnedUnchanged() {
        XCTAssertEqual(
            PopoverGeometry.clampedWidth(desired: 610, availableWidth: 1416),
            610
        )
    }

    func testDesiredAboveAllowanceIsCappedToAllowance() {
        XCTAssertEqual(
            PopoverGeometry.clampedWidth(desired: 2000, availableWidth: 1416),
            1416
        )
    }

    func testNarrowDisplayCapWinsOverMinimum() {
        // A display too narrow to honour minWidth: the screen cap governs.
        XCTAssertEqual(
            PopoverGeometry.clampedWidth(desired: 610, availableWidth: 400),
            400
        )
    }

    /// Regression for A1. The old `centeredFit` path shrank the popover to 360
    /// whenever the status item sat near the right edge, and HeroSplit's two
    /// 210pt fixedSize columns then overflowed and clipped. Width must depend
    /// only on the content and the screen — never on the item's position.
    func testWidthIsIndependentOfStatusItemPosition() {
        let nearRightEdge = PopoverGeometry.clampedWidth(desired: 610, availableWidth: 1416)
        let nearCentre = PopoverGeometry.clampedWidth(desired: 610, availableWidth: 1416)
        XCTAssertEqual(nearRightEdge, nearCentre)
        XCTAssertEqual(nearRightEdge, 610, "must not collapse to the old 360 floor")
    }

    // MARK: clampedOriginX

    private var visible: NSRect { NSRect(x: 0, y: 0, width: 1440, height: 900) }

    func testOriginUnchangedWhenFrameAlreadyFits() {
        XCTAssertEqual(
            PopoverGeometry.clampedOriginX(idealX: 400, width: 610, visible: visible),
            400
        )
    }

    func testOriginShiftsLeftWhenOverrunningRightEdge() {
        // 1200 + 610 = 1810, well past 1440.
        XCTAssertEqual(
            PopoverGeometry.clampedOriginX(idealX: 1200, width: 610, visible: visible),
            1440 - PopoverGeometry.edgeMargin - 610
        )
    }

    func testOriginShiftsRightWhenUnderrunningLeftEdge() {
        XCTAssertEqual(
            PopoverGeometry.clampedOriginX(idealX: -50, width: 610, visible: visible),
            PopoverGeometry.edgeMargin
        )
    }

    func testOriginPrefersLeftEdgeWhenFrameWiderThanScreen() {
        // maxX bound would be negative; the minX bound must win.
        XCTAssertEqual(
            PopoverGeometry.clampedOriginX(idealX: 100, width: 2000, visible: visible),
            PopoverGeometry.edgeMargin
        )
    }

    func testOriginRespectsNonZeroVisibleOrigin() {
        // Second display to the right of the primary.
        let secondary = NSRect(x: 1440, y: 0, width: 1280, height: 800)
        XCTAssertEqual(
            PopoverGeometry.clampedOriginX(idealX: 1400, width: 610, visible: secondary),
            1440 + PopoverGeometry.edgeMargin
        )
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run from `packages/app/AWSCostMonitor/`:
```bash
./scripts/run-tests.sh \
  -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/PopoverGeometryTests
```
Expected: compile failure, "cannot find 'PopoverGeometry' in scope".

- [ ] **Step 3: Write minimal implementation**

Create `AWSCostMonitor/Utilities/PopoverSizing.swift`:

```swift
//
//  PopoverSizing.swift
//  AWSCostMonitor
//
//  Pure geometry for placing the menu bar popover, plus the observable channel
//  the status bar controller uses to publish the current screen constraint.
//

import Foundation
import AppKit

enum PopoverGeometry {
    /// Below this the hero columns (two 210pt fixedSize columns in HeroSplit)
    /// overflow their parent frame, and SwiftUI does not clip overflow — which
    /// is what produced the "cut off on the right" report.
    static let minWidth: CGFloat = 500
    static let edgeMargin: CGFloat = 12

    /// Horizontal space a popover may occupy on a given screen.
    static func availableWidth(screenWidth: CGFloat) -> CGFloat {
        screenWidth - 2 * edgeMargin
    }

    /// Width the content wants, floored at `minWidth` and capped to what the
    /// screen allows. The cap wins only on displays too narrow for both.
    /// Deliberately takes no status-item position: the popover is moved to fit,
    /// never shrunk to fit.
    static func clampedWidth(desired: CGFloat, availableWidth: CGFloat) -> CGFloat {
        min(max(desired, minWidth), availableWidth)
    }

    /// Origin.x that keeps `width` fully on screen, preferring `idealX`.
    /// When the frame cannot fit at all, the left edge wins.
    static func clampedOriginX(idealX: CGFloat, width: CGFloat, visible: NSRect) -> CGFloat {
        let maxX = visible.maxX - edgeMargin - width
        let minX = visible.minX + edgeMargin
        return max(minX, min(idealX, maxX))
    }
}

/// Synchronous replacement for the old `popover.availableWidth` UserDefaults
/// key. UserDefaults → @AppStorage → SwiftUI relayout is asynchronous, while
/// NSPopover measures its content synchronously inside show(), so the old
/// channel let a given show use the previous show's width.
@MainActor
final class PopoverSizing: ObservableObject {
    @Published var availableWidth: CGFloat = .greatestFiniteMagnitude
}
```

Register both files in `AWSCostMonitor.xcodeproj` — `PopoverSizing.swift` in the `AWSCostMonitor` target, `PopoverGeometryTests.swift` in `AWSCostMonitorTests`.

- [ ] **Step 4: Run test to verify it passes**

```bash
./scripts/run-tests.sh \
  -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/PopoverGeometryTests
```
Expected: PASS, 11 tests.

- [ ] **Step 5: Commit**

```bash
git add AWSCostMonitor/Utilities/PopoverSizing.swift \
        AWSCostMonitorTests/PopoverGeometryTests.swift \
        AWSCostMonitor.xcodeproj/project.pbxproj
git commit -m "feat(popover): pure geometry for width and origin clamping"
```

---

### Task 2: Replace the UserDefaults width channel

**Files:**
- Modify: `AWSCostMonitor/Views/PopoverContentView.swift:10` (remove `@AppStorage`), `:187-199` (`windowWidth`)
- Modify: `AWSCostMonitor/Controllers/StatusBarController.swift:36-53` (retain hosting controller, inject sizing), `:145-151` (`showPopover`), `:176-200` (delete `updateAvailableWidth`)

**Interfaces:**
- Consumes: `PopoverGeometry.availableWidth(screenWidth:)`, `PopoverGeometry.clampedWidth(desired:availableWidth:)`, `PopoverSizing` from Task 1.
- Produces: `StatusBarController` now holds `private let hostingController: NSHostingController<...>` and `private let sizing = PopoverSizing()`, and exposes `private func syncContentSize(on screen: NSScreen?)` used again in Task 3.

- [ ] **Step 1: Delete the old channel in the view**

In `AWSCostMonitor/Views/PopoverContentView.swift`, delete lines 8–10:

```swift
    // Max on-screen width published by StatusBarController before each show, so
    // the popover clamps itself to the display and never clips off an edge.
    @AppStorage("popover.availableWidth") private var availableWidth: Double = 0
```

and replace with:

```swift
    // Max on-screen width, published synchronously by StatusBarController before
    // each show. Was @AppStorage; UserDefaults round-trips asynchronously while
    // NSPopover measures synchronously in show(), so the first open after a
    // screen or profile change used the previous open's width.
    @EnvironmentObject var sizing: PopoverSizing
```

- [ ] **Step 2: Rewrite `windowWidth`**

Replace the body of `windowWidth` (currently lines 187–199):

```swift
    private var windowWidth: CGFloat {
        // Two mirrored hero columns (actual | forecast). Size each so neither
        // anchor number truncates; at 34pt monospaced ~20px per character.
        let mtdStr = CurrencyFormatter.format(mtd)
        let projStr = projectedDouble.map { CurrencyFormatter.format($0) } ?? mtdStr
        let heroChars = max(mtdStr.count, projStr.count)
        let columnWidth = CGFloat(heroChars) * 20 + 44
        let ideal = columnWidth * 2 + 1
        return PopoverGeometry.clampedWidth(desired: ideal, availableWidth: sizing.availableWidth)
    }
```

Note the `max(500, ...)` is gone from `ideal` — the floor now lives once, in `PopoverGeometry.minWidth`, rather than being duplicated here as 500 and in the controller as 360.

- [ ] **Step 3: Retain the hosting controller and inject sizing**

In `AWSCostMonitor/Controllers/StatusBarController.swift`, add stored properties beside the existing ones (near line 24):

```swift
    private let sizing = PopoverSizing()
    private var hostingController: NSHostingController<AnyView>!
```

Replace the `popover.contentViewController = NSHostingController(...)` assignment (lines 48–53) with:

```swift
        // Retained: showPopover() must measure this view's fittingSize before
        // handing a size to NSPopover.
        hostingController = NSHostingController(
            rootView: AnyView(
                PopoverContentView()
                    .environmentObject(awsManager)
                    .environmentObject(appearance)
                    .environmentObject(sizing)
                    .environment(\.ledgerAppearance, appearance.appearance)
            )
        )
        popover.contentViewController = hostingController
```

Also update the comment at lines 45–47, which describes the mechanism being removed:

```swift
        // Right-edge clipping is handled by measuring content against the screen
        // before show (syncContentSize) and moving the window onto the screen in
        // popoverDidShow. The popover is never shrunk to fit.
```

- [ ] **Step 4: Rewrite `showPopover` and delete `updateAvailableWidth`**

Replace `showPopover` (lines 145–151):

```swift
    func showPopover() {
        guard let button = statusItem.button else { return }
        syncContentSize(on: button.window?.screen ?? NSScreen.main)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    /// Publish the screen constraint, force a synchronous relayout against it,
    /// then hand NSPopover the true content size. Without the relayout,
    /// fittingSize reports the previous pass and NSPopover clamps against a
    /// stale size — the original bug by another route.
    private func syncContentSize(on screen: NSScreen?) {
        sizing.availableWidth = PopoverGeometry.availableWidth(
            screenWidth: screen?.visibleFrame.width ?? 1440
        )
        hostingController.view.layoutSubtreeIfNeeded()
        popover.contentSize = hostingController.view.fittingSize
    }
```

Delete the entire `updateAvailableWidth(for:)` method (lines 176–200) including its doc comment. Its `centeredFit` computation is the A1 defect.

- [ ] **Step 5: Build and verify no references remain**

```bash
grep -rn "popover.availableWidth\|updateAvailableWidth\|centeredFit" AWSCostMonitor/
```
Expected: no matches.

```bash
xcodebuild build -project AWSCostMonitor.xcodeproj -scheme AWSCostMonitor -destination 'platform=macOS'
```
Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Run the existing suite for regressions**

```bash
./scripts/run-tests.sh
```
Expected: PASS. `MenuBarPresenterTests` and `LedgerTokensTests` in particular must be unaffected.

- [ ] **Step 7: Commit**

```bash
git add AWSCostMonitor/Views/PopoverContentView.swift \
        AWSCostMonitor/Controllers/StatusBarController.swift
git commit -m "fix(popover): measure against the screen synchronously, stop shrinking content

The old path published a width through UserDefaults, which SwiftUI reads
asynchronously while NSPopover measures synchronously in show(), so a given
open used the previous open's width. Worse, updateAvailableWidth's centeredFit
assumed the popover stays centred on its arrow, flooring the width at 360 for
any status item near the right edge; HeroSplit's two 210pt fixedSize columns
then overflowed the frame and SwiftUI does not clip overflow.

Width is now published through an ObservableObject, forced through a
synchronous relayout, and handed to NSPopover as an explicit contentSize."
```

---

### Task 3: Move the window clamp off the animation timeline

**Files:**
- Modify: `AWSCostMonitor/Controllers/StatusBarController.swift:145-174` (delete inline clamp call and `clampPopoverOnScreen`, adopt `NSPopoverDelegate`)

**Interfaces:**
- Consumes: `PopoverGeometry.clampedOriginX(idealX:width:visible:)` from Task 1; `syncContentSize(on:)` from Task 2.
- Produces: `StatusBarController: NSPopoverDelegate` conformance with `func popoverDidShow(_ notification: Notification)`.

**Background:** commit `cb744d1` added `clampPopoverOnScreen()` and set `popover.animates = false` together; its doc comment states the clamp is "a stable, one-shot adjustment" only "with animations off". Commit `9f1c3c9` restored the fade (`animates = true`) without touching the clamp, so it now reads `win.frame` mid-animation. Fix the dependency rather than re-disabling the fade.

- [ ] **Step 1: Set the delegate**

In `init`, after `popover.animates = true` (line 44), add:

```swift
        // popoverDidShow fires after the presentation animation settles, so the
        // on-screen clamp no longer depends on `animates` being false. cb744d1
        // tied those together in a comment only, and 9f1c3c9 restored the fade
        // and silently broke the clamp.
        popover.delegate = self
```

- [ ] **Step 2: Replace the inline clamp**

In `showPopover`, remove the `clampPopoverOnScreen()` call so the method reads exactly:

```swift
    func showPopover() {
        guard let button = statusItem.button else { return }
        syncContentSize(on: button.window?.screen ?? NSScreen.main)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
```

Delete the existing `clampPopoverOnScreen()` method and its doc comment (lines 153–174 in the pre-Task-2 file).

- [ ] **Step 3: Add the delegate conformance**

At the end of the file, after the closing brace of `StatusBarController`:

```swift
// MARK: - NSPopoverDelegate

extension StatusBarController: NSPopoverDelegate {
    /// Timing-independent safety net for edge clipping. Fires once the
    /// presentation animation has settled, so `win.frame` is final.
    func popoverDidShow(_ notification: Notification) {
        guard let win = popover.contentViewController?.view.window else { return }
        let visible = (win.screen ?? NSScreen.main ?? NSScreen.screens.first!).visibleFrame
        var frame = win.frame
        frame.origin.x = PopoverGeometry.clampedOriginX(
            idealX: frame.origin.x, width: frame.width, visible: visible
        )
        guard frame.origin.x != win.frame.origin.x else { return }
        win.setFrame(frame, display: true, animate: false)
    }
}
```

- [ ] **Step 4: Re-clamp on live content changes and screen changes**

In `init`, add a second sink on the existing merged publisher (after the `renderStatusItem` sink at line 92–95):

```swift
        // A profile switch can change the hero digit count and therefore the
        // popover width while it is open. Re-measure and re-anchor; show() on an
        // already-visible popover re-positions without replaying the fade.
        Publishers.MergeMany(signals)
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.popover.isShown, let button = self.statusItem.button else { return }
                self.syncContentSize(on: button.window?.screen ?? NSScreen.main)
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                guard let self, let button = self.statusItem.button else { return }
                self.syncContentSize(on: button.window?.screen ?? NSScreen.main)
            }
            .store(in: &cancellables)
```

- [ ] **Step 5: Build and run the suite**

```bash
./scripts/run-tests.sh
```
Expected: PASS.

- [ ] **Step 6: Manual verification (required — the bug is visual)**

Build and run the app, then confirm all four:
1. Status item at the far right of the menu bar, popover opens fully on screen with no content clipped at the right edge.
2. Switch to a profile whose MTD has more digits while the popover is open — it widens and stays on screen.
3. Drag the app's menu bar item to a secondary display (or move the menu bar) and open — correct on the *first* open, not the second.
4. The fade-in animation is still present.

- [ ] **Step 7: Commit**

```bash
git add AWSCostMonitor/Controllers/StatusBarController.swift
git commit -m "fix(popover): clamp on popoverDidShow, not inline after show

cb744d1 added clampPopoverOnScreen() and set animates=false in the same commit,
recording the dependency only in a doc comment. 9f1c3c9 restored the fade and
left the clamp reading win.frame mid-animation, where the presentation
animation overwrites the corrected origin. Moving the clamp to the
NSPopoverDelegate callback makes it independent of the animates setting."
```

---

## Phase 2 — Config Parsing (Tasks 4–5)

Independently releasable. Removes the phantom `sso-session` profile and is a prerequisite for Phase 3.

### Task 4: Classifying AWS config parser

**Files:**
- Create: `AWSCostMonitor/Models/AWSProfileConfig.swift`
- Create: `AWSCostMonitor/Utilities/AWSConfigParser.swift`
- Test: `AWSCostMonitorTests/AWSConfigParserTests.swift`

**Interfaces:**
- Consumes: `INIParser.parseString(_:)` from `AWSCostMonitor/Utilities/INIParser.swift` is **not** used — its section handling is the B2 defect. Parse sections directly.
- Produces: `struct SSOSession`, `struct SSOProfileRef`, `enum ProfileCredentialSource`, `struct AWSProfileConfig`, and `enum AWSConfigParser` with `static func parse(configContent: String) -> ParsedAWSConfig` where `struct ParsedAWSConfig { let profiles: [AWSProfileConfig]; let ssoSessions: [String: SSOSession] }`.

- [ ] **Step 1: Write the failing test**

Create `AWSCostMonitorTests/AWSConfigParserTests.swift`:

```swift
import XCTest
@testable import AWSCostMonitor

final class AWSConfigParserTests: XCTestCase {

    /// Mirrors the shape of a real multi-account config: an sso-session block,
    /// session-based SSO profiles, a legacy inline SSO profile, assume-role
    /// chains, a credential_process profile, and a bare [default].
    private let fixture = """
    [default]
    region = us-east-1

    [sso-session ams]
    sso_start_url = https://d-906674c76d.awsapps.com/start
    sso_region = us-east-1
    sso_registration_scopes = sso:account:access

    [profile ams-mgmt]
    sso_session = ams
    sso_account_id = 138893339616
    sso_role_name = AdministratorAccess
    region = us-east-1

    [profile ams-dev]
    sso_session = ams
    sso_account_id = 350480401393
    sso_role_name = AdministratorAccess

    [profile legacy-sso]
    sso_start_url = https://legacy.awsapps.com/start
    sso_region = eu-west-1
    sso_account_id = 111122223333
    sso_role_name = ReadOnly

    [profile butler-production]
    role_arn = arn:aws:iam::920120424735:role/OrganizationAccountAccessRole
    source_profile = ams-mgmt
    region = us-east-1

    [profile mfa-protected]
    role_arn = arn:aws:iam::999988887777:role/Admin
    source_profile = ams-mgmt
    mfa_serial = arn:aws:iam::123456789012:mfa/jackson

    [profile via-process]
    credential_process = /opt/bin/mint-creds

    [profile dangling]
    sso_session = does-not-exist
    sso_account_id = 1
    sso_role_name = X

    [profile role-without-source]
    role_arn = arn:aws:iam::555555555555:role/Orphan

    [profile plain-keys]
    region = us-west-2

    [services my-services]
    cost_explorer =
      endpoint_url = https://example.invalid
    """

    private func parsed() -> ParsedAWSConfig {
        AWSConfigParser.parse(configContent: fixture)
    }

    // MARK: B2 regression

    func testSSOSessionSectionIsNotAProfile() {
        let names = parsed().profiles.map(\.name)
        XCTAssertFalse(names.contains("sso-session ams"))
        XCTAssertFalse(names.contains(where: { $0.hasPrefix("sso-session") }))
    }

    func testServicesSectionIsIgnored() {
        let names = parsed().profiles.map(\.name)
        XCTAssertFalse(names.contains(where: { $0.hasPrefix("services") }))
    }

    func testDefaultProfileIsIncludedUnprefixed() {
        XCTAssertTrue(parsed().profiles.map(\.name).contains("default"))
    }

    func testProfilePrefixIsStripped() {
        XCTAssertTrue(parsed().profiles.map(\.name).contains("ams-mgmt"))
        XCTAssertFalse(parsed().profiles.map(\.name).contains("profile ams-mgmt"))
    }

    // MARK: sso sessions

    func testSSOSessionIsParsed() {
        let session = parsed().ssoSessions["ams"]
        XCTAssertEqual(session?.startUrl, "https://d-906674c76d.awsapps.com/start")
        XCTAssertEqual(session?.ssoRegion, "us-east-1")
        XCTAssertEqual(session?.scopes, ["sso:account:access"])
    }

    // MARK: classification

    private func source(_ name: String) -> ProfileCredentialSource? {
        parsed().profiles.first(where: { $0.name == name })?.source
    }

    func testSessionBasedSSOProfileResolvesSessionFields() {
        guard case .sso(let ref)? = source("ams-mgmt") else {
            return XCTFail("expected .sso, got \(String(describing: source("ams-mgmt")))")
        }
        XCTAssertEqual(ref.sessionName, "ams")
        XCTAssertEqual(ref.startUrl, "https://d-906674c76d.awsapps.com/start")
        XCTAssertEqual(ref.ssoRegion, "us-east-1")
        XCTAssertEqual(ref.accountId, "138893339616")
        XCTAssertEqual(ref.roleName, "AdministratorAccess")
    }

    func testLegacyInlineSSOProfileHasNoSessionName() {
        guard case .sso(let ref)? = source("legacy-sso") else {
            return XCTFail("expected .sso")
        }
        XCTAssertNil(ref.sessionName)
        XCTAssertEqual(ref.startUrl, "https://legacy.awsapps.com/start")
        XCTAssertEqual(ref.ssoRegion, "eu-west-1")
    }

    func testAssumeRoleProfileCarriesSourceProfile() {
        guard case .assumeRole(let roleArn, let sourceProfile, let mfa)? = source("butler-production") else {
            return XCTFail("expected .assumeRole")
        }
        XCTAssertEqual(roleArn, "arn:aws:iam::920120424735:role/OrganizationAccountAccessRole")
        XCTAssertEqual(sourceProfile, "ams-mgmt")
        XCTAssertNil(mfa)
    }

    func testAssumeRoleProfileCarriesMFASerialWhenPresent() {
        guard case .assumeRole(_, _, let mfa)? = source("mfa-protected") else {
            return XCTFail("expected .assumeRole")
        }
        XCTAssertEqual(mfa, "arn:aws:iam::123456789012:mfa/jackson")
    }

    func testCredentialProcessIsUnsupported() {
        guard case .unsupported? = source("via-process") else {
            return XCTFail("expected .unsupported")
        }
    }

    func testDanglingSSOSessionReferenceIsUnsupported() {
        guard case .unsupported? = source("dangling") else {
            return XCTFail("expected .unsupported")
        }
    }

    func testRoleArnWithoutSourceProfileIsUnsupported() {
        guard case .unsupported? = source("role-without-source") else {
            return XCTFail("expected .unsupported")
        }
    }

    func testProfileWithNoCredentialHintsIsStaticKeys() {
        guard case .staticKeys? = source("plain-keys") else {
            return XCTFail("expected .staticKeys")
        }
    }

    func testRegionIsCarried() {
        let profiles = parsed().profiles
        XCTAssertEqual(profiles.first(where: { $0.name == "ams-mgmt" })?.region, "us-east-1")
        XCTAssertNil(profiles.first(where: { $0.name == "ams-dev" })?.region)
    }

    // MARK: robustness

    func testCommentsAndBlankLinesAreIgnored() {
        let content = """
        # leading comment
        [profile a]
        ; semicolon comment
        region = us-east-1

        """
        let result = AWSConfigParser.parse(configContent: content)
        XCTAssertEqual(result.profiles.count, 1)
        XCTAssertEqual(result.profiles[0].region, "us-east-1")
    }

    func testValuesContainingEqualsAreNotTruncated() {
        let content = """
        [sso-session s]
        sso_start_url = https://example.com/start?foo=bar
        sso_region = us-east-1
        """
        XCTAssertEqual(
            AWSConfigParser.parse(configContent: content).ssoSessions["s"]?.startUrl,
            "https://example.com/start?foo=bar"
        )
    }

    func testEmptyConfigProducesNothing() {
        let result = AWSConfigParser.parse(configContent: "")
        XCTAssertTrue(result.profiles.isEmpty)
        XCTAssertTrue(result.ssoSessions.isEmpty)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
./scripts/run-tests.sh \
  -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/AWSConfigParserTests
```
Expected: compile failure, "cannot find 'AWSConfigParser' in scope".

- [ ] **Step 3: Write the models**

Create `AWSCostMonitor/Models/AWSProfileConfig.swift`:

```swift
//
//  AWSProfileConfig.swift
//  AWSCostMonitor
//
//  Richer view of an ~/.aws/config profile than AWSProfile, carrying how the
//  profile's credentials are actually obtained.
//

import Foundation

struct SSOSession: Equatable {
    let name: String
    let startUrl: String
    let ssoRegion: String
    let scopes: [String]
}

struct SSOProfileRef: Equatable {
    /// nil for legacy profiles that inline sso_start_url instead of naming a session.
    let sessionName: String?
    let startUrl: String
    let ssoRegion: String
    let accountId: String
    let roleName: String

    /// Key the AWS CLI hashes to name the token cache file: the session name when
    /// one is used, otherwise the start URL.
    var cacheKey: String { sessionName ?? startUrl }
}

enum ProfileCredentialSource: Equatable {
    case staticKeys
    case sso(SSOProfileRef)
    case assumeRole(roleArn: String, sourceProfile: String, mfaSerial: String?)
    case unsupported(reason: String)
}

struct AWSProfileConfig: Equatable {
    let name: String
    let region: String?
    let source: ProfileCredentialSource
}

struct ParsedAWSConfig {
    let profiles: [AWSProfileConfig]
    let ssoSessions: [String: SSOSession]
}
```

- [ ] **Step 4: Write the parser**

Create `AWSCostMonitor/Utilities/AWSConfigParser.swift`:

```swift
//
//  AWSConfigParser.swift
//  AWSCostMonitor
//
//  Section-aware parser for ~/.aws/config. INIParser treats every bracketed
//  section as a profile, which surfaced [sso-session x] blocks in the profile
//  picker as phantom entries; this classifies sections properly and reports how
//  each profile's credentials are obtained.
//

import Foundation

enum AWSConfigParser {

    private enum Section {
        case profile(String)
        case ssoSession(String)
        case ignored
    }

    static func parse(configContent: String) -> ParsedAWSConfig {
        var rawProfiles: [(name: String, keys: [String: String])] = []
        var rawSessions: [(name: String, keys: [String: String])] = []
        var current: Section = .ignored
        var keys: [String: String] = [:]

        func flush() {
            switch current {
            case .profile(let name):    rawProfiles.append((name, keys))
            case .ssoSession(let name): rawSessions.append((name, keys))
            case .ignored:              break
            }
            keys = [:]
        }

        for rawLine in configContent.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix(";") { continue }

            if line.hasPrefix("[") && line.hasSuffix("]") {
                flush()
                current = classify(header: String(line.dropFirst().dropLast()))
                continue
            }

            // Split on the first '=' only: start URLs legitimately contain '='.
            guard let sep = line.firstIndex(of: "=") else { continue }
            let key = line[line.startIndex..<sep].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: sep)...].trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else { continue }
            keys[key] = value
        }
        flush()

        var sessions: [String: SSOSession] = [:]
        for raw in rawSessions {
            guard let startUrl = raw.keys["sso_start_url"],
                  let ssoRegion = raw.keys["sso_region"] else { continue }
            sessions[raw.name] = SSOSession(
                name: raw.name,
                startUrl: startUrl,
                ssoRegion: ssoRegion,
                scopes: (raw.keys["sso_registration_scopes"] ?? "sso:account:access")
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            )
        }

        let profiles = rawProfiles.map { raw in
            AWSProfileConfig(
                name: raw.name,
                region: raw.keys["region"],
                source: classifySource(keys: raw.keys, sessions: sessions)
            )
        }.sorted { $0.name < $1.name }

        return ParsedAWSConfig(profiles: profiles, ssoSessions: sessions)
    }

    private static func classify(header: String) -> Section {
        if header == "default" { return .profile("default") }
        if header.hasPrefix("profile ") {
            return .profile(String(header.dropFirst("profile ".count)).trimmingCharacters(in: .whitespaces))
        }
        if header.hasPrefix("sso-session ") {
            return .ssoSession(String(header.dropFirst("sso-session ".count)).trimmingCharacters(in: .whitespaces))
        }
        // [services ...] and anything else we don't model.
        return .ignored
    }

    private static func classifySource(
        keys: [String: String],
        sessions: [String: SSOSession]
    ) -> ProfileCredentialSource {
        if let sessionName = keys["sso_session"] {
            guard let session = sessions[sessionName] else {
                return .unsupported(reason: "References unknown sso-session '\(sessionName)'.")
            }
            guard let accountId = keys["sso_account_id"], let roleName = keys["sso_role_name"] else {
                return .unsupported(reason: "SSO profile is missing sso_account_id or sso_role_name.")
            }
            return .sso(SSOProfileRef(
                sessionName: sessionName,
                startUrl: session.startUrl,
                ssoRegion: session.ssoRegion,
                accountId: accountId,
                roleName: roleName
            ))
        }

        if let startUrl = keys["sso_start_url"] {
            guard let ssoRegion = keys["sso_region"],
                  let accountId = keys["sso_account_id"],
                  let roleName = keys["sso_role_name"] else {
                return .unsupported(reason: "Legacy SSO profile is missing sso_region, sso_account_id, or sso_role_name.")
            }
            return .sso(SSOProfileRef(
                sessionName: nil,
                startUrl: startUrl,
                ssoRegion: ssoRegion,
                accountId: accountId,
                roleName: roleName
            ))
        }

        if let roleArn = keys["role_arn"] {
            guard let sourceProfile = keys["source_profile"] else {
                return .unsupported(reason: "role_arn without source_profile is not supported.")
            }
            return .assumeRole(roleArn: roleArn, sourceProfile: sourceProfile, mfaSerial: keys["mfa_serial"])
        }

        if keys["credential_process"] != nil {
            return .unsupported(reason: "credential_process profiles are not supported.")
        }

        return .staticKeys
    }
}
```

Register both new files in the `AWSCostMonitor` target and the test file in `AWSCostMonitorTests`.

- [ ] **Step 5: Run test to verify it passes**

```bash
./scripts/run-tests.sh \
  -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/AWSConfigParserTests
```
Expected: PASS, 18 tests.

- [ ] **Step 6: Commit**

```bash
git add AWSCostMonitor/Models/AWSProfileConfig.swift \
        AWSCostMonitor/Utilities/AWSConfigParser.swift \
        AWSCostMonitorTests/AWSConfigParserTests.swift \
        AWSCostMonitor.xcodeproj/project.pbxproj
git commit -m "feat(config): section-aware parser classifying credential sources"
```

---

### Task 5: Wire the parser into profile loading

**Files:**
- Modify: `AWSCostMonitor/Managers/AWSManager.swift:669-677` (`loadProfiles` parsing block)
- Test: `AWSCostMonitorTests/AWSConfigParserTests.swift` (add one integration-shaped case)

**Interfaces:**
- Consumes: `AWSConfigParser.parse(configContent:)`, `ParsedAWSConfig`, `AWSProfileConfig` from Task 4.
- Produces: `AWSManager.profileConfigs: [String: AWSProfileConfig]` and `AWSManager.ssoSessions: [String: SSOSession]`, both read by the `CredentialResolver` in Tasks 8, 9 and the UI in Tasks 11, 13.

- [ ] **Step 1: Add storage to AWSManager**

Near the other `@Published` properties in `AWSManager`, add:

```swift
    /// How each profile's credentials are obtained, keyed by profile name.
    /// Populated by loadProfiles; read by CredentialResolver.
    @Published var profileConfigs: [String: AWSProfileConfig] = [:]
    /// SSO sessions declared in ~/.aws/config, keyed by session name.
    @Published var ssoSessions: [String: SSOSession] = [:]
```

- [ ] **Step 2: Replace the parsing block**

At `AWSCostMonitor/Managers/AWSManager.swift:669`, replace:

```swift
        let parsedProfiles = INIParser.parseString(configContent)
        log(.info, category: "Config", "Found \(parsedProfiles.count) profiles in AWS config")

        self.realProfiles = parsedProfiles.keys.map { profileName in
            let profileConfig = parsedProfiles[profileName]
            let region = profileConfig?["region"]
            return AWSProfile(name: profileName, region: region)
        }.sorted { $0.name < $1.name }
```

with:

```swift
        // AWSConfigParser, not INIParser: the latter treats every bracketed
        // section as a profile, so [sso-session x] blocks appeared in the picker
        // as phantom profiles named "sso-session x".
        let parsed = AWSConfigParser.parse(configContent: configContent)
        log(.info, category: "Config",
            "Found \(parsed.profiles.count) profiles and \(parsed.ssoSessions.count) SSO sessions in AWS config")

        self.profileConfigs = Dictionary(uniqueKeysWithValues: parsed.profiles.map { ($0.name, $0) })
        self.ssoSessions = parsed.ssoSessions
        self.realProfiles = parsed.profiles.map { AWSProfile(name: $0.name, region: $0.region) }
```

`parsed.profiles` is already sorted by name, so the trailing `.sorted` is dropped.

- [ ] **Step 3: Add the regression test**

Append to `AWSConfigParserTests`:

```swift
    /// The phantom-profile bug as it appeared to the user: an sso-session block
    /// showing up as a selectable profile in the picker.
    func testRealisticConfigYieldsOnlyRealProfileNames() {
        let names = Set(parsed().profiles.map(\.name))
        XCTAssertEqual(names, [
            "default", "ams-mgmt", "ams-dev", "legacy-sso", "butler-production",
            "mfa-protected", "via-process", "dangling", "role-without-source", "plain-keys",
        ])
    }
```

- [ ] **Step 4: Run tests**

```bash
./scripts/run-tests.sh
```
Expected: PASS. `AWSManagerProfileTests` and `ProfileManagementTests` must still pass — if either asserts on `INIParser` output shape, update it to the new source of truth rather than reverting this change.

- [ ] **Step 5: Manual verification**

Run the app and open the profile picker. Expected: no entry named `sso-session ams` or `sso-session middleout`; the real profiles are all present.

- [ ] **Step 6: Commit**

```bash
git add AWSCostMonitor/Managers/AWSManager.swift AWSCostMonitorTests/AWSConfigParserTests.swift
git commit -m "fix(config): stop listing [sso-session] blocks as selectable profiles"
```

---

## Phase 3 — SSO Credentials (Tasks 6–11)

Delivers working SSO for anyone with a live `aws sso login` session, plus assume-role chains.

### Task 6: Typed errors and scoped file access

**Files:**
- Modify: `AWSCostMonitor/Utilities/Errors.swift`
- Modify: `AWSCostMonitor/AWSConfigAccessManager.swift` (add `withScopedAccess`, refactor the two existing readers onto it)

**Interfaces:**
- Consumes: nothing.
- Produces: `AWSCostFetchError` cases `.ssoNotLoggedIn(session: String)`, `.ssoSessionExpired(session: String)`, `.unsupportedProfile(profile: String, reason: String)`, each with a `LocalizedError` message; `AWSConfigAccessManager.withScopedAccess<T>(_ body: (URL) throws -> T) rethrows -> T?` returning the `~/.aws` directory URL.

- [ ] **Step 1: Extend the error type**

Replace the whole of `AWSCostMonitor/Utilities/Errors.swift`:

```swift
//
//  Errors.swift
//  AWSCostMonitor
//
//  Error definitions
//

import Foundation

// Custom errors for AWS cost fetching
enum AWSCostFetchError: Error {
    case credentialsNotFound(String)
    /// No SSO token at all for this session — the user has never signed in.
    case ssoNotLoggedIn(session: String)
    /// A token exists but is past its expiry, and refresh was unavailable or failed.
    case ssoSessionExpired(session: String)
    /// The profile uses a credential mechanism this app does not implement.
    case unsupportedProfile(profile: String, reason: String)
}

extension AWSCostFetchError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .credentialsNotFound(let detail):
            return detail
        case .ssoNotLoggedIn(let session):
            return "Not signed in to SSO session '\(session)'."
        case .ssoSessionExpired(let session):
            return "SSO session '\(session)' has expired."
        case .unsupportedProfile(let profile, let reason):
            return "Profile '\(profile)' can't be used: \(reason)"
        }
    }
}
```

- [ ] **Step 2: Add generic scoped access**

In `AWSCostMonitor/AWSConfigAccessManager.swift`, add above `readConfigFile()`:

```swift
    /// Run `body` with the security-scoped `~/.aws` directory URL. The bookmark
    /// covers the folder, not individual files, so anything beneath it —
    /// including sso/cache — is reachable without a new entitlement.
    /// Returns nil when access is unavailable.
    func withScopedAccess<T>(_ body: (URL) throws -> T) rethrows -> T? {
        if !ProcessInfo.processInfo.environment.keys.contains("APP_SANDBOX_CONTAINER_ID") {
            let url = URL(fileURLWithPath: NSString("~/.aws").expandingTildeInPath)
            return try body(url)
        }
        guard let url = securityScopedURL else {
            logger.error("No security-scoped URL available")
            needsAccessGrant = true
            return nil
        }
        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Failed to start accessing security-scoped resource")
            needsAccessGrant = true
            return nil
        }
        defer { url.stopAccessingSecurityScopedResource() }
        return try body(url)
    }
```

Leave `readConfigFile()` and `readCredentialsFile()` as they are. Refactoring them onto `withScopedAccess` is tempting but changes their `needsAccessGrant` side effects, which the onboarding flow depends on; not worth the risk in this task.

- [ ] **Step 3: Build**

```bash
xcodebuild build -project AWSCostMonitor.xcodeproj -scheme AWSCostMonitor -destination 'platform=macOS'
```
Expected: BUILD SUCCEEDED. Existing `catch` sites that switch exhaustively on `AWSCostFetchError` will fail to compile — add the new cases there, mapping each to `error.localizedDescription`.

- [ ] **Step 4: Commit**

```bash
git add AWSCostMonitor/Utilities/Errors.swift AWSCostMonitor/AWSConfigAccessManager.swift
git commit -m "feat(errors): typed SSO failure cases and generic scoped ~/.aws access"
```

---

### Task 7: SSO token cache reader

**Files:**
- Create: `AWSCostMonitor/Utilities/SSOTokenCache.swift`
- Test: `AWSCostMonitorTests/SSOTokenCacheTests.swift`

**Interfaces:**
- Consumes: `AWSConfigAccessManager.withScopedAccess` from Task 6.
- Produces: `struct SSOToken { let accessToken: String; let expiresAt: Date; let region: String?; let startUrl: String?; let refreshToken: String?; let clientId: String?; let clientSecret: String?; var isExpired: Bool }` and `enum SSOTokenCache` with `static func cacheFileName(forKey key: String) -> String`, `static func decode(_ data: Data) throws -> SSOToken`, `static func readCLIToken(forKey key: String) -> SSOToken?`.

**Background:** the AWS CLI names each cache file with the lowercase SHA-1 hex digest of a key — the `sso_session` name when one is used, otherwise the `sso_start_url`. Getting this wrong means silently finding no token.

- [ ] **Step 1: Write the failing test**

Create `AWSCostMonitorTests/SSOTokenCacheTests.swift`:

```swift
import XCTest
@testable import AWSCostMonitor

final class SSOTokenCacheTests: XCTestCase {

    // MARK: filename derivation

    /// SHA-1 of "ams", lowercase hex, with a .json suffix — the AWS CLI's scheme.
    /// STEP 2 BELOW COMPUTES THE EXPECTED DIGEST. Do not invent it; run the
    /// shasum command and paste the result here before running this test.
    func testCacheFileNameIsSHA1OfSessionName() {
        XCTAssertEqual(
            SSOTokenCache.cacheFileName(forKey: "ams"),
            "<PASTE DIGEST FROM STEP 2>.json"
        )
    }

    func testCacheFileNameForStartURLDiffersFromSessionName() {
        let a = SSOTokenCache.cacheFileName(forKey: "ams")
        let b = SSOTokenCache.cacheFileName(forKey: "https://d-906674c76d.awsapps.com/start")
        XCTAssertNotEqual(a, b)
        XCTAssertTrue(b.hasSuffix(".json"))
        XCTAssertEqual(b.count, 40 + ".json".count)
    }

    func testCacheFileNameIsLowercaseHex() {
        let name = SSOTokenCache.cacheFileName(forKey: "Mixed-Case-Session")
        let stem = String(name.dropLast(".json".count))
        XCTAssertEqual(stem, stem.lowercased())
        XCTAssertTrue(stem.allSatisfy { $0.isHexDigit })
    }

    // MARK: decoding

    private func json(_ body: String) -> Data { Data(body.utf8) }

    func testDecodesFractionalSecondsExpiry() throws {
        let token = try SSOTokenCache.decode(json("""
        {"accessToken":"tok","expiresAt":"2026-07-25T18:30:00.123Z","region":"us-east-1"}
        """))
        XCTAssertEqual(token.accessToken, "tok")
        XCTAssertEqual(token.region, "us-east-1")
        XCTAssertEqual(token.expiresAt.timeIntervalSince1970, 1785004200, accuracy: 1)
    }

    func testDecodesWholeSecondsExpiry() throws {
        let token = try SSOTokenCache.decode(json("""
        {"accessToken":"tok","expiresAt":"2026-07-25T18:30:00Z"}
        """))
        XCTAssertEqual(token.expiresAt.timeIntervalSince1970, 1785004200, accuracy: 1)
    }

    func testDecodesUTCSuffixForm() throws {
        // Older CLI versions wrote this shape.
        let token = try SSOTokenCache.decode(json("""
        {"accessToken":"tok","expiresAt":"2026-07-25T18:30:00UTC"}
        """))
        XCTAssertEqual(token.expiresAt.timeIntervalSince1970, 1785004200, accuracy: 1)
    }

    func testDecodesOptionalRefreshFields() throws {
        let token = try SSOTokenCache.decode(json("""
        {"accessToken":"tok","expiresAt":"2026-07-25T18:30:00Z",
         "refreshToken":"rt","clientId":"cid","clientSecret":"cs",
         "startUrl":"https://example.awsapps.com/start"}
        """))
        XCTAssertEqual(token.refreshToken, "rt")
        XCTAssertEqual(token.clientId, "cid")
        XCTAssertEqual(token.clientSecret, "cs")
        XCTAssertEqual(token.startUrl, "https://example.awsapps.com/start")
    }

    func testMissingAccessTokenThrows() {
        XCTAssertThrowsError(try SSOTokenCache.decode(json("""
        {"expiresAt":"2026-07-25T18:30:00Z"}
        """)))
    }

    func testUnparseableExpiryThrows() {
        XCTAssertThrowsError(try SSOTokenCache.decode(json("""
        {"accessToken":"tok","expiresAt":"never"}
        """)))
    }

    // MARK: expiry

    func testTokenExpiringSoonCountsAsExpired() {
        // The 5-minute safety margin: a token valid for 60s must not be used,
        // or a refresh started now could outlive it mid-request.
        let token = SSOToken(accessToken: "t", expiresAt: Date().addingTimeInterval(60),
                             region: nil, startUrl: nil, refreshToken: nil,
                             clientId: nil, clientSecret: nil)
        XCTAssertTrue(token.isExpired)
    }

    func testTokenWithAmpleLifeIsNotExpired() {
        let token = SSOToken(accessToken: "t", expiresAt: Date().addingTimeInterval(3600),
                             region: nil, startUrl: nil, refreshToken: nil,
                             clientId: nil, clientSecret: nil)
        XCTAssertFalse(token.isExpired)
    }

    func testPastExpiryIsExpired() {
        let token = SSOToken(accessToken: "t", expiresAt: Date().addingTimeInterval(-1),
                             region: nil, startUrl: nil, refreshToken: nil,
                             clientId: nil, clientSecret: nil)
        XCTAssertTrue(token.isExpired)
    }
}
```

- [ ] **Step 2: Compute the real SHA-1 and fill in the expected literal**

```bash
printf '%s' 'ams' | shasum -a 1 | cut -d' ' -f1
```
Paste the output into `testCacheFileNameIsSHA1OfSessionName`, replacing the placeholder digest. Then cross-check against the machine's real cache to confirm the scheme end-to-end:

```bash
ls ~/.aws/sso/cache/
printf '%s' 'ams' | shasum -a 1 | cut -d' ' -f1
```
The digest should match one of the filenames (minus `.json`). If it does not, try hashing the `sso_start_url` instead and adjust `SSOProfileRef.cacheKey` accordingly — the session-name rule applies only to `sso_session`-style profiles.

- [ ] **Step 3: Run test to verify it fails**

```bash
./scripts/run-tests.sh \
  -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/SSOTokenCacheTests
```
Expected: compile failure, "cannot find 'SSOTokenCache' in scope".

- [ ] **Step 4: Write the implementation**

Create `AWSCostMonitor/Utilities/SSOTokenCache.swift`:

```swift
//
//  SSOTokenCache.swift
//  AWSCostMonitor
//
//  Reads the AWS CLI's SSO token cache. Read-only by design: the app's
//  entitlements grant user-selected read access only, and app-minted tokens go
//  to the Keychain instead (see SSOTokenStore).
//

import Foundation
import CryptoKit

struct SSOToken: Equatable {
    let accessToken: String
    let expiresAt: Date
    let region: String?
    let startUrl: String?
    let refreshToken: String?
    let clientId: String?
    let clientSecret: String?

    /// Treat a token as expired 5 minutes early so a request started now cannot
    /// outlive it in flight.
    static let expiryMargin: TimeInterval = 300

    var isExpired: Bool {
        expiresAt.timeIntervalSinceNow <= Self.expiryMargin
    }
}

enum SSOTokenCacheError: Error {
    case malformed(String)
}

enum SSOTokenCache {

    /// The AWS CLI names each cache file with the lowercase SHA-1 hex digest of
    /// the session name (or, for legacy profiles, the start URL).
    static func cacheFileName(forKey key: String) -> String {
        let digest = Insecure.SHA1.hash(data: Data(key.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return "\(hex).json"
    }

    static func decode(_ data: Data) throws -> SSOToken {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SSOTokenCacheError.malformed("Token cache is not a JSON object.")
        }
        guard let accessToken = object["accessToken"] as? String, !accessToken.isEmpty else {
            throw SSOTokenCacheError.malformed("Token cache has no accessToken.")
        }
        guard let expiresRaw = object["expiresAt"] as? String,
              let expiresAt = parseExpiry(expiresRaw) else {
            throw SSOTokenCacheError.malformed("Token cache has no parseable expiresAt.")
        }
        return SSOToken(
            accessToken: accessToken,
            expiresAt: expiresAt,
            region: object["region"] as? String,
            startUrl: object["startUrl"] as? String,
            refreshToken: object["refreshToken"] as? String,
            clientId: object["clientId"] as? String,
            clientSecret: object["clientSecret"] as? String
        )
    }

    /// Seen in the wild: with and without fractional seconds, and an older
    /// "…UTC" suffix instead of "Z".
    private static func parseExpiry(_ raw: String) -> Date? {
        let normalised = raw.hasSuffix("UTC")
            ? String(raw.dropLast(3)) + "Z"
            : raw

        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: normalised) { return date }

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: normalised)
    }

    /// Read the CLI's cached token for `key`, or nil when absent or unreadable.
    static func readCLIToken(forKey key: String) -> SSOToken? {
        let fileName = cacheFileName(forKey: key)
        return AWSConfigAccessManager.shared.withScopedAccess { awsDir -> SSOToken? in
            let url = awsDir.appendingPathComponent("sso/cache/\(fileName)")
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decode(data)
        } ?? nil
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
./scripts/run-tests.sh \
  -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/SSOTokenCacheTests
```
Expected: PASS, 12 tests.

- [ ] **Step 6: Commit**

```bash
git add AWSCostMonitor/Utilities/SSOTokenCache.swift \
        AWSCostMonitorTests/SSOTokenCacheTests.swift \
        AWSCostMonitor.xcodeproj/project.pbxproj
git commit -m "feat(sso): read the AWS CLI's SSO token cache"
```

---

### Task 8: Credential resolver — SSO path

**Files:**
- Create: `AWSCostMonitor/Managers/CredentialResolver.swift`
- Test: `AWSCostMonitorTests/CredentialResolverTests.swift`
- Modify: `AWSCostMonitor.xcodeproj` — add `AWSSSO` to the `AWSCostMonitor` target's package product dependencies (alongside the existing `AWSCostExplorer`, `AWSSTS`, `AWSSavingsplans`)

**Interfaces:**
- Consumes: `AWSProfileConfig`, `ProfileCredentialSource`, `SSOProfileRef` (Task 4); `SSOToken`, `SSOTokenCache` (Task 7); `AWSCostFetchError` (Task 6); `parseAWSCredentials(content:profileName:)` from the existing `AWSCostMonitor/Utilities/AWSCredentialsHelper.swift`.
- Produces: `protocol SSORoleCredentialsFetching { func fetch(accessToken: String, accountId: String, roleName: String, region: String) async throws -> AWSCredentialIdentity }`, `protocol SSOTokenProviding { func token(forKey key: String) async -> SSOToken? }`, `protocol STSAssuming { func assume(roleArn: String, sessionName: String, region: String, using: AWSCredentialIdentity) async throws -> AWSCredentialIdentity }`, and `actor CredentialResolver` with `init(configs: [String: AWSProfileConfig], ssoTokens: any SSOTokenProviding, ssoRoles: any SSORoleCredentialsFetching, sts: any STSAssuming)`, `func resolver(for profileName: String) async throws -> any AWSCredentialIdentityResolver`, and `func invalidateCache()`.

**Design note:** the two protocols exist so the tests never touch the network. Production wires them to `SSOClient` and `STSClient`; tests pass fakes.

- [ ] **Step 1: Write the failing test**

Create `AWSCostMonitorTests/CredentialResolverTests.swift`:

```swift
import XCTest
import AWSSDKIdentity
import SmithyIdentity
@testable import AWSCostMonitor

// MARK: - Fakes

private actor FakeTokenStore: SSOTokenProviding {
    var tokens: [String: SSOToken]
    init(_ tokens: [String: SSOToken]) { self.tokens = tokens }
    func token(forKey key: String) async -> SSOToken? { tokens[key] }
}

private actor FakeRoleFetcher: SSORoleCredentialsFetching {
    private(set) var callCount = 0
    var expiry: Date
    init(expiry: Date) { self.expiry = expiry }
    func fetch(accessToken: String, accountId: String, roleName: String,
               region: String) async throws -> AWSCredentialIdentity {
        callCount += 1
        return AWSCredentialIdentity(accessKey: "AK-\(accountId)", secret: "SK",
                                     expiration: expiry, sessionToken: "ST")
    }
    func calls() -> Int { callCount }
}

private actor FakeAssumeRole: STSAssuming {
    private(set) var callCount = 0
    var expiry: Date
    init(expiry: Date) { self.expiry = expiry }
    func assume(roleArn: String, sessionName: String, region: String,
                using: AWSCredentialIdentity) async throws -> AWSCredentialIdentity {
        callCount += 1
        return AWSCredentialIdentity(accessKey: "AK-assumed", secret: "SK",
                                     expiration: expiry, sessionToken: "ST")
    }
    func calls() -> Int { callCount }
}

// MARK: - Tests

final class CredentialResolverTests: XCTestCase {

    private func liveToken() -> SSOToken {
        SSOToken(accessToken: "live", expiresAt: Date().addingTimeInterval(3600),
                 region: "us-east-1", startUrl: nil, refreshToken: nil,
                 clientId: nil, clientSecret: nil)
    }

    private func expiredToken() -> SSOToken {
        SSOToken(accessToken: "stale", expiresAt: Date().addingTimeInterval(-60),
                 region: "us-east-1", startUrl: nil, refreshToken: nil,
                 clientId: nil, clientSecret: nil)
    }

    private func ssoRef(_ account: String) -> SSOProfileRef {
        SSOProfileRef(sessionName: "ams", startUrl: "https://x.awsapps.com/start",
                      ssoRegion: "us-east-1", accountId: account, roleName: "Admin")
    }

    private func makeResolver(
        configs: [String: AWSProfileConfig],
        tokens: [String: SSOToken],
        roleExpiry: Date = Date().addingTimeInterval(3600),
        assumeExpiry: Date = Date().addingTimeInterval(3600)
    ) -> (CredentialResolver, FakeRoleFetcher, FakeAssumeRole) {
        let roles = FakeRoleFetcher(expiry: roleExpiry)
        let sts = FakeAssumeRole(expiry: assumeExpiry)
        let resolver = CredentialResolver(
            configs: configs,
            ssoTokens: FakeTokenStore(tokens),
            ssoRoles: roles,
            sts: sts
        )
        return (resolver, roles, sts)
    }

    // MARK: SSO

    func testSSOProfileResolvesViaGetRoleCredentials() async throws {
        let (resolver, roles, _) = makeResolver(
            configs: ["ams-dev": AWSProfileConfig(name: "ams-dev", region: "us-east-1",
                                                  source: .sso(ssoRef("111")))],
            tokens: ["ams": liveToken()]
        )
        _ = try await resolver.resolver(for: "ams-dev")
        let calls = await roles.calls()
        XCTAssertEqual(calls, 1)
    }

    func testMissingTokenThrowsNotLoggedIn() async {
        let (resolver, _, _) = makeResolver(
            configs: ["ams-dev": AWSProfileConfig(name: "ams-dev", region: nil,
                                                  source: .sso(ssoRef("111")))],
            tokens: [:]
        )
        await XCTAssertThrowsErrorAsync(try await resolver.resolver(for: "ams-dev")) { error in
            guard case AWSCostFetchError.ssoNotLoggedIn(let session) = error else {
                return XCTFail("expected .ssoNotLoggedIn, got \(error)")
            }
            XCTAssertEqual(session, "ams")
        }
    }

    func testExpiredTokenThrowsSessionExpired() async {
        let (resolver, _, _) = makeResolver(
            configs: ["ams-dev": AWSProfileConfig(name: "ams-dev", region: nil,
                                                  source: .sso(ssoRef("111")))],
            tokens: ["ams": expiredToken()]
        )
        await XCTAssertThrowsErrorAsync(try await resolver.resolver(for: "ams-dev")) { error in
            guard case AWSCostFetchError.ssoSessionExpired(let session) = error else {
                return XCTFail("expected .ssoSessionExpired, got \(error)")
            }
            XCTAssertEqual(session, "ams")
        }
    }

    // MARK: caching (DEC-002: never multiply API calls per refresh)

    func testCredentialsAreCachedUntilNearExpiry() async throws {
        let (resolver, roles, _) = makeResolver(
            configs: ["ams-dev": AWSProfileConfig(name: "ams-dev", region: nil,
                                                  source: .sso(ssoRef("111")))],
            tokens: ["ams": liveToken()]
        )
        for _ in 0..<5 { _ = try await resolver.resolver(for: "ams-dev") }
        let calls = await roles.calls()
        XCTAssertEqual(calls, 1, "5 call sites must share one GetRoleCredentials result")
    }

    func testNearlyExpiredCredentialsAreRefetched() async throws {
        let (resolver, roles, _) = makeResolver(
            configs: ["ams-dev": AWSProfileConfig(name: "ams-dev", region: nil,
                                                  source: .sso(ssoRef("111")))],
            tokens: ["ams": liveToken()],
            roleExpiry: Date().addingTimeInterval(60)   // inside the 5-minute margin
        )
        _ = try await resolver.resolver(for: "ams-dev")
        _ = try await resolver.resolver(for: "ams-dev")
        let calls = await roles.calls()
        XCTAssertEqual(calls, 2)
    }

    // MARK: assume-role

    func testAssumeRoleChainsThroughSourceProfile() async throws {
        let (resolver, roles, sts) = makeResolver(
            configs: [
                "ams-mgmt": AWSProfileConfig(name: "ams-mgmt", region: nil, source: .sso(ssoRef("111"))),
                "butler-production": AWSProfileConfig(
                    name: "butler-production", region: "us-east-1",
                    source: .assumeRole(roleArn: "arn:aws:iam::999:role/X",
                                        sourceProfile: "ams-mgmt", mfaSerial: nil)),
            ],
            tokens: ["ams": liveToken()]
        )
        _ = try await resolver.resolver(for: "butler-production")
        let roleCalls = await roles.calls()
        let stsCalls = await sts.calls()
        XCTAssertEqual(roleCalls, 1)
        XCTAssertEqual(stsCalls, 1)
    }

    func testCycleInSourceProfileChainIsRejected() async {
        let (resolver, _, _) = makeResolver(
            configs: [
                "a": AWSProfileConfig(name: "a", region: nil,
                                      source: .assumeRole(roleArn: "arn:a", sourceProfile: "b", mfaSerial: nil)),
                "b": AWSProfileConfig(name: "b", region: nil,
                                      source: .assumeRole(roleArn: "arn:b", sourceProfile: "a", mfaSerial: nil)),
            ],
            tokens: [:]
        )
        await XCTAssertThrowsErrorAsync(try await resolver.resolver(for: "a")) { error in
            guard case AWSCostFetchError.unsupportedProfile(_, let reason) = error else {
                return XCTFail("expected .unsupportedProfile, got \(error)")
            }
            XCTAssertTrue(reason.lowercased().contains("cycle"))
        }
    }

    func testMFASerialIsRejectedWithAClearReason() async {
        let (resolver, _, _) = makeResolver(
            configs: [
                "src": AWSProfileConfig(name: "src", region: nil, source: .sso(ssoRef("111"))),
                "mfa": AWSProfileConfig(name: "mfa", region: nil,
                                        source: .assumeRole(roleArn: "arn:x", sourceProfile: "src",
                                                            mfaSerial: "arn:aws:iam::1:mfa/u")),
            ],
            tokens: ["ams": liveToken()]
        )
        await XCTAssertThrowsErrorAsync(try await resolver.resolver(for: "mfa")) { error in
            guard case AWSCostFetchError.unsupportedProfile(_, let reason) = error else {
                return XCTFail("expected .unsupportedProfile, got \(error)")
            }
            XCTAssertTrue(reason.lowercased().contains("mfa"))
        }
    }

    func testUnknownProfileIsRejected() async {
        let (resolver, _, _) = makeResolver(configs: [:], tokens: [:])
        await XCTAssertThrowsErrorAsync(try await resolver.resolver(for: "nope")) { error in
            guard case AWSCostFetchError.unsupportedProfile = error else {
                return XCTFail("expected .unsupportedProfile, got \(error)")
            }
        }
    }

    func testUnsupportedSourceIsRejectedWithItsReason() async {
        let (resolver, _, _) = makeResolver(
            configs: ["p": AWSProfileConfig(name: "p", region: nil,
                                            source: .unsupported(reason: "credential_process profiles are not supported."))],
            tokens: [:]
        )
        await XCTAssertThrowsErrorAsync(try await resolver.resolver(for: "p")) { error in
            guard case AWSCostFetchError.unsupportedProfile(_, let reason) = error else {
                return XCTFail("expected .unsupportedProfile, got \(error)")
            }
            XCTAssertTrue(reason.contains("credential_process"))
        }
    }
}

// MARK: - async throws assertion helper

func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ handler: (Error) -> Void
) async {
    do {
        _ = try await expression()
        XCTFail("expected an error but none was thrown", file: file, line: line)
    } catch {
        handler(error)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
./scripts/run-tests.sh \
  -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/CredentialResolverTests
```
Expected: compile failure, "cannot find 'CredentialResolver' in scope".

- [ ] **Step 3: Add the AWSSSO package product**

In Xcode: select the project, the `AWSCostMonitor` target, General → Frameworks, Libraries, and Embedded Content → `+` → `aws-sdk-swift` → `AWSSSO`. Verify the resulting `project.pbxproj` diff adds an `AWSSSO` entry mirroring the existing `AWSSTS` one.

- [ ] **Step 4: Write the implementation**

Create `AWSCostMonitor/Managers/CredentialResolver.swift`:

```swift
//
//  CredentialResolver.swift
//  AWSCostMonitor
//
//  Turns a profile name into an AWS credential resolver, handling static keys,
//  SSO, and role_arn/source_profile chains. Replaces createAWSCredentialsProvider,
//  which only understood static keys from ~/.aws/credentials and therefore failed
//  for every SSO and assume-role profile in a sandboxed build.
//

import Foundation
import AWSSSO
import AWSSTS
import AWSSDKIdentity
import SmithyIdentity

// MARK: - Seams for testing

protocol SSOTokenProviding: Sendable {
    func token(forKey key: String) async -> SSOToken?
}

protocol SSORoleCredentialsFetching: Sendable {
    func fetch(accessToken: String, accountId: String, roleName: String,
               region: String) async throws -> AWSCredentialIdentity
}

protocol STSAssuming: Sendable {
    func assume(roleArn: String, sessionName: String, region: String,
                using: AWSCredentialIdentity) async throws -> AWSCredentialIdentity
}

// MARK: - Resolver

actor CredentialResolver {

    /// Refresh this far ahead of expiry so a request started now cannot outlive
    /// its credentials in flight.
    private static let expiryMargin: TimeInterval = 300
    /// Guards against pathological config; real chains are 1-2 deep.
    private static let maxChainDepth = 5

    private let configs: [String: AWSProfileConfig]
    private let ssoTokens: any SSOTokenProviding
    private let ssoRoles: any SSORoleCredentialsFetching
    private let sts: any STSAssuming

    private var cache: [String: AWSCredentialIdentity] = [:]

    init(configs: [String: AWSProfileConfig],
         ssoTokens: any SSOTokenProviding,
         ssoRoles: any SSORoleCredentialsFetching,
         sts: any STSAssuming) {
        self.configs = configs
        self.ssoTokens = ssoTokens
        self.ssoRoles = ssoRoles
        self.sts = sts
    }

    func resolver(for profileName: String) async throws -> any AWSCredentialIdentityResolver {
        let identity = try await credentials(for: profileName, visited: [])
        return StaticAWSCredentialIdentityResolver(identity)
    }

    /// Invalidate everything — call after a fresh sign-in.
    func invalidateCache() { cache.removeAll() }

    // MARK: - Chain

    private func credentials(for profileName: String,
                             visited: Set<String>) async throws -> AWSCredentialIdentity {
        if let cached = cache[profileName], !isNearExpiry(cached) { return cached }

        guard !visited.contains(profileName) else {
            throw AWSCostFetchError.unsupportedProfile(
                profile: profileName,
                reason: "Detected a cycle in the source_profile chain.")
        }
        guard visited.count < Self.maxChainDepth else {
            throw AWSCostFetchError.unsupportedProfile(
                profile: profileName,
                reason: "source_profile chain is deeper than \(Self.maxChainDepth) levels.")
        }
        guard let config = configs[profileName] else {
            throw AWSCostFetchError.unsupportedProfile(
                profile: profileName,
                reason: "No such profile in ~/.aws/config.")
        }

        let identity: AWSCredentialIdentity
        switch config.source {
        case .unsupported(let reason):
            throw AWSCostFetchError.unsupportedProfile(profile: profileName, reason: reason)

        case .staticKeys:
            identity = try staticCredentials(for: profileName)

        case .sso(let ref):
            identity = try await ssoCredentials(ref, profileName: profileName)

        case .assumeRole(let roleArn, let sourceProfile, let mfaSerial):
            if let mfaSerial, !mfaSerial.isEmpty {
                throw AWSCostFetchError.unsupportedProfile(
                    profile: profileName,
                    reason: "Profiles requiring MFA (mfa_serial \(mfaSerial)) aren't supported yet.")
            }
            let source = try await credentials(for: sourceProfile,
                                               visited: visited.union([profileName]))
            identity = try await sts.assume(
                roleArn: roleArn,
                sessionName: "AWSCostMonitor-\(profileName)",
                region: config.region ?? "us-east-1",
                using: source)
        }

        cache[profileName] = identity
        return identity
    }

    private func isNearExpiry(_ identity: AWSCredentialIdentity) -> Bool {
        guard let expiration = identity.expiration else { return false }
        return expiration.timeIntervalSinceNow <= Self.expiryMargin
    }

    private func staticCredentials(for profileName: String) throws -> AWSCredentialIdentity {
        guard let content = AWSConfigAccessManager.shared.readCredentialsFile() else {
            throw AWSCostFetchError.credentialsNotFound(
                "Unable to read ~/.aws/credentials.")
        }
        guard let parsed = parseAWSCredentials(content: content, profileName: profileName) else {
            throw AWSCostFetchError.credentialsNotFound(
                "No credentials for profile '\(profileName)' in ~/.aws/credentials.")
        }
        return AWSCredentialIdentity(accessKey: parsed.accessKeyId,
                                     secret: parsed.secretAccessKey,
                                     sessionToken: parsed.sessionToken)
    }

    private func ssoCredentials(_ ref: SSOProfileRef,
                                profileName: String) async throws -> AWSCredentialIdentity {
        let sessionLabel = ref.sessionName ?? ref.startUrl
        guard let token = await ssoTokens.token(forKey: ref.cacheKey) else {
            throw AWSCostFetchError.ssoNotLoggedIn(session: sessionLabel)
        }
        guard !token.isExpired else {
            throw AWSCostFetchError.ssoSessionExpired(session: sessionLabel)
        }
        return try await ssoRoles.fetch(accessToken: token.accessToken,
                                        accountId: ref.accountId,
                                        roleName: ref.roleName,
                                        region: ref.ssoRegion)
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
./scripts/run-tests.sh \
  -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/CredentialResolverTests
```
Expected: PASS, 10 tests.

- [ ] **Step 6: Commit**

```bash
git add AWSCostMonitor/Managers/CredentialResolver.swift \
        AWSCostMonitorTests/CredentialResolverTests.swift \
        AWSCostMonitor.xcodeproj/project.pbxproj
git commit -m "feat(auth): credential resolver for SSO and assume-role chains

Caches per-profile credentials until 5 minutes before expiry. Without this,
each of the ~12 AWSManager call sites would mint fresh credentials, turning one
refresh into GetRoleCredentials + AssumeRole + GetCostAndUsage against the
one-request-per-minute invariant in DEC-002."
```

---

### Task 9: Production adapters for the resolver seams

**Files:**
- Create: `AWSCostMonitor/Managers/CredentialAdapters.swift`
- Test: none (thin adapters over SDK clients; the logic they feed is covered by Task 8)

**Interfaces:**
- Consumes: `SSOTokenProviding`, `SSORoleCredentialsFetching`, `STSAssuming` (Task 8); `SSOTokenCache.readCLIToken(forKey:)` (Task 7).
- Produces: `struct CLITokenStore: SSOTokenProviding`, `struct LiveSSORoleFetcher: SSORoleCredentialsFetching`, `struct LiveSTSAssumer: STSAssuming`.

- [ ] **Step 1: Write the adapters**

Create `AWSCostMonitor/Managers/CredentialAdapters.swift`:

```swift
//
//  CredentialAdapters.swift
//  AWSCostMonitor
//
//  Production wiring for CredentialResolver's seams. Kept separate so the
//  resolver's tests never reach the network.
//

import Foundation
import AWSSSO
import AWSSTS
import AWSSDKIdentity
import SmithyIdentity

/// Reads the AWS CLI's on-disk token cache. Task 12 layers the Keychain store
/// in front of this.
struct CLITokenStore: SSOTokenProviding {
    func token(forKey key: String) async -> SSOToken? {
        SSOTokenCache.readCLIToken(forKey: key)
    }
}

struct LiveSSORoleFetcher: SSORoleCredentialsFetching {
    func fetch(accessToken: String, accountId: String, roleName: String,
               region: String) async throws -> AWSCredentialIdentity {
        let config = try await SSOClient.SSOClientConfiguration(region: region)
        let client = SSOClient(config: config)
        let output = try await client.getRoleCredentials(input: GetRoleCredentialsInput(
            accessToken: accessToken, accountId: accountId, roleName: roleName))
        guard let creds = output.roleCredentials,
              let accessKey = creds.accessKeyId,
              let secret = creds.secretAccessKey else {
            throw AWSCostFetchError.credentialsNotFound(
                "GetRoleCredentials returned no credentials for \(roleName)@\(accountId).")
        }
        // expiration arrives as epoch milliseconds.
        let expiration = creds.expiration.map { Date(timeIntervalSince1970: Double($0) / 1000) }
        return AWSCredentialIdentity(accessKey: accessKey, secret: secret,
                                     expiration: expiration, sessionToken: creds.sessionToken)
    }
}

struct LiveSTSAssumer: STSAssuming {
    func assume(roleArn: String, sessionName: String, region: String,
                using source: AWSCredentialIdentity) async throws -> AWSCredentialIdentity {
        let config = try await STSClient.STSClientConfiguration(
            awsCredentialIdentityResolver: StaticAWSCredentialIdentityResolver(source),
            region: region)
        let client = STSClient(config: config)
        let output = try await client.assumeRole(input: AssumeRoleInput(
            roleArn: roleArn, roleSessionName: sessionName))
        guard let creds = output.credentials,
              let accessKey = creds.accessKeyId,
              let secret = creds.secretAccessKey else {
            throw AWSCostFetchError.credentialsNotFound(
                "AssumeRole returned no credentials for \(roleArn).")
        }
        return AWSCredentialIdentity(accessKey: accessKey, secret: secret,
                                     expiration: creds.expiration, sessionToken: creds.sessionToken)
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -project AWSCostMonitor.xcodeproj -scheme AWSCostMonitor -destination 'platform=macOS'
```
Expected: BUILD SUCCEEDED. If `GetRoleCredentialsInput` or `RoleCredentials` field names or optionality differ in aws-sdk-swift 1.5.12, correct them against the generated headers — jump to definition on `SSOClient` — rather than guessing.

- [ ] **Step 3: Commit**

```bash
git add AWSCostMonitor/Managers/CredentialAdapters.swift AWSCostMonitor.xcodeproj/project.pbxproj
git commit -m "feat(auth): live SSO and STS adapters for the credential resolver"
```

---

### Task 10: Swap AWSManager onto the resolver

**Files:**
- Modify: `AWSCostMonitor/Managers/AWSManager.swift` — every `createAWSCredentialsProvider(for:)` call site (lines 2248, 2642, 2782, 2870, 2938, 3000, 3077, 3279, 3304, 3648, and any others `grep` finds)
- Modify: `AWSCostMonitor/Utilities/AWSCredentialsHelper.swift` — delete `createAWSCredentialsProvider`, keep `parseAWSCredentials`

**Interfaces:**
- Consumes: `CredentialResolver` (Task 8), `CLITokenStore`/`LiveSSORoleFetcher`/`LiveSTSAssumer` (Task 9), `AWSManager.profileConfigs` (Task 5).
- Produces: `AWSManager.credentialResolver: CredentialResolver`, rebuilt whenever `profileConfigs` changes.

- [ ] **Step 1: Add the resolver to AWSManager**

Beside `profileConfigs`:

```swift
    /// Rebuilt whenever the parsed config changes, so a profile added to
    /// ~/.aws/config while the app runs is resolvable without a restart.
    private(set) var credentialResolver = CredentialResolver(
        configs: [:], ssoTokens: CLITokenStore(),
        ssoRoles: LiveSSORoleFetcher(), sts: LiveSTSAssumer())
```

In `loadProfiles`, immediately after `self.profileConfigs = ...` (added in Task 5):

```swift
        self.credentialResolver = CredentialResolver(
            configs: self.profileConfigs, ssoTokens: CLITokenStore(),
            ssoRoles: LiveSSORoleFetcher(), sts: LiveSTSAssumer())
```

- [ ] **Step 2: Find every call site**

```bash
grep -n "createAWSCredentialsProvider" AWSCostMonitor/Managers/AWSManager.swift
```
Record the full list; every one must be converted.

- [ ] **Step 3: Convert each call site**

Replace each occurrence of:

```swift
            let credentialsProvider = try createAWSCredentialsProvider(for: profile.name)
```

with:

```swift
            let credentialsProvider = try await credentialResolver.resolver(for: profile.name)
```

For the site at line 3648, the variable is a bare `profileName` rather than `profile.name` — use `credentialResolver.resolver(for: profileName)` there. All these call sites are already inside `async` contexts (they `await` the client configuration on the following line), so no signature changes are needed. If any is not, make its enclosing function `async` and `await` at its caller.

Also delete the now-misleading sandbox log block at lines 2250–2254:

```swift
            if ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil {
                log(.debug, category: "API", "✅ Successfully created StaticAWSCredentialIdentityResolver for sandboxed environment")
            } else {
                log(.debug, category: "API", "✅ Successfully created ProfileAWSCredentialIdentityResolver for non-sandboxed environment")
            }
```

replacing it with:

```swift
            log(.debug, category: "API", "✅ Resolved credentials for profile '\(profile.name)'")
```

- [ ] **Step 4: Delete the old helper**

In `AWSCostMonitor/Utilities/AWSCredentialsHelper.swift`, delete the entire `createAWSCredentialsProvider(for:)` function. Keep `parseAWSCredentials(content:profileName:)` — `CredentialResolver.staticCredentials` calls it. Remove the now-unused `import AWSSDKIdentity`/`import SmithyIdentity` only if the compiler flags them.

- [ ] **Step 5: Verify nothing references the old helper**

```bash
grep -rn "createAWSCredentialsProvider" AWSCostMonitor/ AWSCostMonitorTests/
```
Expected: no matches.

- [ ] **Step 6: Build and test**

```bash
./scripts/run-tests.sh
```
Expected: PASS.

- [ ] **Step 7: Manual verification — the actual goal**

Run `aws sso login --sso-session ams` in Terminal, then launch the app and select `ams-dev`, `ams-mgmt`, and `ams-prod` in turn. Expected: real cost data for each. Then select `butler-production` (an assume-role profile). Expected: real cost data. Then `via-process` or another `credential_process` profile. Expected: a clear "can't be used" message, not a hang or a generic credentials error.

- [ ] **Step 8: Commit**

```bash
git add AWSCostMonitor/Managers/AWSManager.swift AWSCostMonitor/Utilities/AWSCredentialsHelper.swift
git commit -m "feat(auth): resolve every profile through CredentialResolver

SSO and assume-role profiles now work in the sandboxed build. The old helper
read only static keys from ~/.aws/credentials, which SSO profiles never have."
```

---

### Task 11: Surface credential errors in the popover

**Files:**
- Create: `AWSCostMonitor/Popover/StatusBanner.swift`
- Modify: `AWSCostMonitor/Views/PopoverContentView.swift` (insert the banner, extend `totalHeight`)

**Interfaces:**
- Consumes: `AWSCostFetchError` (Task 6), `AWSManager.errorMessage`.
- Produces: `struct StatusBanner: View` with `init(message: String, actionTitle: String?, action: (() -> Void)?)`; `AWSManager.credentialError: AWSCostFetchError?` published alongside `errorMessage`.

**Background:** `PopoverContentView` currently never renders `awsManager.errorMessage` — a failed profile shows as zeroes with no explanation. SSO makes this unacceptable, because "expired session" is a routine, actionable state.

- [ ] **Step 1: Publish the typed error**

In `AWSManager`, beside `errorMessage`:

```swift
    /// Set alongside errorMessage when the failure was a credential problem, so
    /// the popover can offer a sign-in action rather than plain text.
    @Published var credentialError: AWSCostFetchError?
```

In each `catch` that currently assigns `self.errorMessage = error.localizedDescription`, add before it:

```swift
            self.credentialError = error as? AWSCostFetchError
```

and set `self.credentialError = nil` wherever `errorMessage` is cleared (lines 504, 567, 942, 947, 2174, 3378, 3592).

- [ ] **Step 2: Write the banner**

Create `AWSCostMonitor/Popover/StatusBanner.swift`:

```swift
import SwiftUI

/// One-line, dismissable-by-fixing status strip. Used for credential failures,
/// which are routine (SSO tokens expire every ~8 hours) and always actionable.
struct StatusBanner: View {
    @Environment(\.ledgerAppearance) private var a
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    static let height: CGFloat = 28

    var body: some View {
        HStack(spacing: LedgerTokens.Layout.unit(a)) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundColor(LedgerTokens.Color.signalOver(a))

            Text(message)
                .ledgerMeta()
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: LedgerTokens.Layout.unit(a))

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.plain)
                    .ledgerMeta()
                    .foregroundColor(LedgerTokens.Color.accent(a))
            }
        }
        .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.75)
        .frame(height: Self.height)
        .background(LedgerTokens.Color.signalOver(a).opacity(0.10))
    }
}
```

- [ ] **Step 3: Insert it into the popover**

In `PopoverContentView.body`, immediately after the `ProfileRow(...)` block and before its following `LedgerHairlineDivider()`:

```swift
            if let banner = bannerContent {
                StatusBanner(message: banner.message,
                             actionTitle: banner.actionTitle,
                             action: banner.action)
            }
```

Add to the Derived section:

```swift
    private struct BannerContent {
        let message: String
        let actionTitle: String?
        let action: (() -> Void)?
    }

    /// Credential failures get an action; everything else is plain text.
    private var bannerContent: BannerContent? {
        if case .ssoNotLoggedIn(let session)? = awsManager.credentialError {
            return BannerContent(
                message: "Not signed in to '\(session)'.",
                actionTitle: "Sign In",
                action: { Task { await awsManager.signInToSSO(session: session) } })
        }
        if case .ssoSessionExpired(let session)? = awsManager.credentialError {
            return BannerContent(
                message: "SSO session '\(session)' expired.",
                actionTitle: "Sign In",
                action: { Task { await awsManager.signInToSSO(session: session) } })
        }
        guard let message = awsManager.errorMessage, !message.isEmpty else { return nil }
        return BannerContent(message: message, actionTitle: nil, action: nil)
    }
```

- [ ] **Step 4: Stub the sign-in entry point**

`signInToSSO(session:)` is implemented in Task 12. Add a stub to `AWSManager` now so this task compiles and can be committed independently:

```swift
    /// Implemented in Task 12 (SSOLoginService). Until then, direct the user to
    /// the CLI rather than silently doing nothing.
    func signInToSSO(session: String) async {
        errorMessage = "Run 'aws sso login --sso-session \(session)' in Terminal, then refresh."
    }
```

- [ ] **Step 5: Extend `totalHeight`**

In `PopoverContentView.totalHeight`, add the banner's contribution:

```swift
             + (bannerContent != nil ? StatusBanner.height : 0)
```

Place it directly after the `36 // ProfileRow` term, matching the view order. Getting this wrong leaves a gap or clips the footer, because the popover height is computed rather than measured.

- [ ] **Step 6: Build and test**

```bash
./scripts/run-tests.sh
```
Expected: PASS.

- [ ] **Step 7: Manual verification**

Let an SSO session expire (or rename its cache file in `~/.aws/sso/cache/` to simulate absence), open the popover, and confirm the banner appears with a Sign In button and the layout has no gap or clipped footer.

- [ ] **Step 8: Commit**

```bash
git add AWSCostMonitor/Popover/StatusBanner.swift AWSCostMonitor/Views/PopoverContentView.swift \
        AWSCostMonitor/Managers/AWSManager.swift AWSCostMonitor.xcodeproj/project.pbxproj
git commit -m "feat(popover): surface credential errors with an actionable banner"
```

---

## Phase 4 — In-App Sign-In (Tasks 12–14)

Removes the Terminal dependency.

### Task 12: Device-authorization sign-in

**Files:**
- Create: `AWSCostMonitor/Utilities/SSOTokenStore.swift` (Keychain)
- Create: `AWSCostMonitor/Managers/SSOLoginService.swift`
- Test: `AWSCostMonitorTests/SSOTokenStoreTests.swift`
- Modify: `AWSCostMonitor/Managers/AWSManager.swift` (replace the Task 11 stub)
- Modify: `AWSCostMonitor.xcodeproj` — add `AWSSSOOIDC` to the `AWSCostMonitor` target

**Interfaces:**
- Consumes: `SSOToken` (Task 7), `SSOSession` (Task 4), `SSOTokenProviding` (Task 8).
- Produces: `struct SSOTokenStore: SSOTokenProviding` with `func save(_ token: SSOToken, forKey key: String) throws`, `func delete(forKey key: String) throws`, `func registration(forKey key: String) -> OIDCRegistration?`, `func saveRegistration(_:forKey:) throws`; `struct OIDCRegistration { let clientId: String; let clientSecret: String; let expiresAt: Date }`; `@MainActor final class SSOLoginService: ObservableObject` with `@Published var userCode: String?`, `@Published var isSigningIn: Bool`, `func signIn(session: SSOSession) async throws -> SSOToken`, `func cancel()`.

**Constraint:** tokens go to the Keychain, never to `~/.aws/sso/cache` — the entitlements file stays read-only. See the spec's "Token Storage Decision".

- [ ] **Step 1: Write the failing Keychain test**

Create `AWSCostMonitorTests/SSOTokenStoreTests.swift`:

```swift
import XCTest
@testable import AWSCostMonitor

final class SSOTokenStoreTests: XCTestCase {

    private let key = "unit-test-session"
    private var store: SSOTokenStore { SSOTokenStore(service: "dev.middleout.AWSCostMonitor.tests") }

    override func tearDown() {
        try? store.delete(forKey: key)
        super.tearDown()
    }

    private func token(expiresIn: TimeInterval, access: String = "tok") -> SSOToken {
        SSOToken(accessToken: access, expiresAt: Date().addingTimeInterval(expiresIn),
                 region: "us-east-1", startUrl: "https://x.awsapps.com/start",
                 refreshToken: "rt", clientId: "cid", clientSecret: "cs")
    }

    func testRoundTripsAToken() async throws {
        try store.save(token(expiresIn: 3600), forKey: key)
        let loaded = await store.token(forKey: key)
        XCTAssertEqual(loaded?.accessToken, "tok")
        XCTAssertEqual(loaded?.refreshToken, "rt")
        XCTAssertEqual(loaded?.region, "us-east-1")
    }

    func testOverwritesAnExistingToken() async throws {
        try store.save(token(expiresIn: 3600, access: "first"), forKey: key)
        try store.save(token(expiresIn: 3600, access: "second"), forKey: key)
        let loaded = await store.token(forKey: key)
        XCTAssertEqual(loaded?.accessToken, "second")
    }

    func testDeleteRemovesTheToken() async throws {
        try store.save(token(expiresIn: 3600), forKey: key)
        try store.delete(forKey: key)
        let loaded = await store.token(forKey: key)
        XCTAssertNil(loaded)
    }

    func testMissingKeyReturnsNil() async {
        let loaded = await store.token(forKey: "never-written")
        XCTAssertNil(loaded)
    }

    func testRegistrationRoundTrips() throws {
        let reg = OIDCRegistration(clientId: "cid", clientSecret: "cs",
                                   expiresAt: Date().addingTimeInterval(90 * 86400))
        try store.saveRegistration(reg, forKey: key)
        let loaded = store.registration(forKey: key)
        XCTAssertEqual(loaded?.clientId, "cid")
        XCTAssertEqual(loaded?.clientSecret, "cs")
    }

    func testExpiredRegistrationIsNotReturned() throws {
        let reg = OIDCRegistration(clientId: "cid", clientSecret: "cs",
                                   expiresAt: Date().addingTimeInterval(-1))
        try store.saveRegistration(reg, forKey: key)
        XCTAssertNil(store.registration(forKey: key),
                     "an expired client registration must be re-created, not reused")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
./scripts/run-tests.sh \
  -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/SSOTokenStoreTests
```
Expected: compile failure, "cannot find 'SSOTokenStore' in scope".

- [ ] **Step 3: Write the Keychain store**

Create `AWSCostMonitor/Utilities/SSOTokenStore.swift`:

```swift
//
//  SSOTokenStore.swift
//  AWSCostMonitor
//
//  Keychain storage for tokens this app mints. Deliberately does not write
//  ~/.aws/sso/cache: the sandbox entitlement is user-selected read-only, and
//  requesting read-write purely to share a token back to the CLI is a poor
//  trade for an app whose premise is read-only access (DEC-003). Sharing is
//  therefore one-directional — the CLI's cache is read, never written.
//

import Foundation
import Security

struct OIDCRegistration: Codable, Equatable {
    let clientId: String
    let clientSecret: String
    let expiresAt: Date
}

private struct StoredToken: Codable {
    let accessToken: String
    let expiresAt: Date
    let region: String?
    let startUrl: String?
    let refreshToken: String?
    let clientId: String?
    let clientSecret: String?
}

enum SSOTokenStoreError: Error {
    case keychain(OSStatus)
}

struct SSOTokenStore: SSOTokenProviding {
    let service: String

    init(service: String = "dev.middleout.AWSCostMonitor.sso") {
        self.service = service
    }

    // MARK: Tokens

    func token(forKey key: String) async -> SSOToken? {
        guard let data = read(account: "token:\(key)"),
              let stored = try? JSONDecoder().decode(StoredToken.self, from: data) else { return nil }
        return SSOToken(accessToken: stored.accessToken, expiresAt: stored.expiresAt,
                        region: stored.region, startUrl: stored.startUrl,
                        refreshToken: stored.refreshToken,
                        clientId: stored.clientId, clientSecret: stored.clientSecret)
    }

    func save(_ token: SSOToken, forKey key: String) throws {
        let stored = StoredToken(accessToken: token.accessToken, expiresAt: token.expiresAt,
                                 region: token.region, startUrl: token.startUrl,
                                 refreshToken: token.refreshToken,
                                 clientId: token.clientId, clientSecret: token.clientSecret)
        try write(try JSONEncoder().encode(stored), account: "token:\(key)")
    }

    func delete(forKey key: String) throws {
        try remove(account: "token:\(key)")
    }

    // MARK: OIDC client registration

    /// Returns nil for an expired registration so the caller re-registers rather
    /// than sending a client_id the service will reject.
    func registration(forKey key: String) -> OIDCRegistration? {
        guard let data = read(account: "registration:\(key)"),
              let reg = try? JSONDecoder().decode(OIDCRegistration.self, from: data),
              reg.expiresAt > Date() else { return nil }
        return reg
    }

    func saveRegistration(_ registration: OIDCRegistration, forKey key: String) throws {
        try write(try JSONEncoder().encode(registration), account: "registration:\(key)")
    }

    // MARK: Keychain primitives

    private func query(account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    private func read(account: String) -> Data? {
        var q = query(account: account)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }

    private func write(_ data: Data, account: String) throws {
        try? remove(account: account)
        var q = query(account: account)
        q[kSecValueData as String] = data
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(q as CFDictionary, nil)
        guard status == errSecSuccess else { throw SSOTokenStoreError.keychain(status) }
    }

    private func remove(account: String) throws {
        let status = SecItemDelete(query(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SSOTokenStoreError.keychain(status)
        }
    }
}
```

- [ ] **Step 4: Run the Keychain test**

```bash
./scripts/run-tests.sh \
  -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/SSOTokenStoreTests
```
Expected: PASS, 6 tests. A sandboxed test host needs the keychain-access-group entitlement to be absent (it is) and will use the app's own keychain — if all tests fail with `errSecMissingEntitlement`, run the test target unsandboxed rather than adding an entitlement.

- [ ] **Step 5: Add the AWSSSOOIDC package product**

Xcode → target `AWSCostMonitor` → General → Frameworks, Libraries, and Embedded Content → `+` → `aws-sdk-swift` → `AWSSSOOIDC`.

- [ ] **Step 6: Write the login service**

Create `AWSCostMonitor/Managers/SSOLoginService.swift`:

```swift
//
//  SSOLoginService.swift
//  AWSCostMonitor
//
//  OIDC device-authorization flow. The sandbox forbids shelling out to the aws
//  CLI, so signing in has to happen in-process: register a public client, start
//  a device authorization, open the browser, then poll for the token.
//

import Foundation
import AppKit
import AWSSSOOIDC

enum SSOLoginError: LocalizedError {
    case timedOut
    case cancelled
    case serviceRejected(String)

    var errorDescription: String? {
        switch self {
        case .timedOut:                 return "Sign-in timed out. Try again."
        case .cancelled:                return "Sign-in cancelled."
        case .serviceRejected(let why): return "AWS rejected the sign-in: \(why)"
        }
    }
}

@MainActor
final class SSOLoginService: ObservableObject {
    /// Shown to the user so they can confirm the browser page matches.
    @Published private(set) var userCode: String?
    @Published private(set) var isSigningIn = false

    private let store: SSOTokenStore
    private var cancelled = false

    init(store: SSOTokenStore = SSOTokenStore()) {
        self.store = store
    }

    func cancel() { cancelled = true }

    func signIn(session: SSOSession) async throws -> SSOToken {
        isSigningIn = true
        cancelled = false
        defer { isSigningIn = false; userCode = nil }

        let config = try await SSOOIDCClient.SSOOIDCClientConfiguration(region: session.ssoRegion)
        let client = SSOOIDCClient(config: config)
        let registration = try await registration(for: session, client: client)

        let auth = try await client.startDeviceAuthorization(input: StartDeviceAuthorizationInput(
            clientId: registration.clientId,
            clientSecret: registration.clientSecret,
            startUrl: session.startUrl))

        guard let deviceCode = auth.deviceCode,
              let verificationUri = auth.verificationUriComplete.flatMap(URL.init(string:)) else {
            throw SSOLoginError.serviceRejected("StartDeviceAuthorization returned no device code.")
        }
        userCode = auth.userCode
        NSWorkspace.shared.open(verificationUri)

        // The service dictates the poll rate; ignoring it earns SlowDownException.
        var interval = TimeInterval(auth.interval ?? 5)
        let deadline = Date().addingTimeInterval(TimeInterval(auth.expiresIn ?? 600))

        while Date() < deadline {
            if cancelled { throw SSOLoginError.cancelled }
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))

            do {
                let output = try await client.createToken(input: CreateTokenInput(
                    clientId: registration.clientId,
                    clientSecret: registration.clientSecret,
                    deviceCode: deviceCode,
                    grantType: "urn:ietf:params:oauth:grant-type:device_code"))
                guard let accessToken = output.accessToken else {
                    throw SSOLoginError.serviceRejected("CreateToken returned no access token.")
                }
                let token = SSOToken(
                    accessToken: accessToken,
                    expiresAt: Date().addingTimeInterval(TimeInterval(output.expiresIn ?? 28800)),
                    region: session.ssoRegion,
                    startUrl: session.startUrl,
                    refreshToken: output.refreshToken,
                    clientId: registration.clientId,
                    clientSecret: registration.clientSecret)
                try store.save(token, forKey: session.name)
                return token
            } catch is AuthorizationPendingException {
                continue                       // user hasn't approved yet
            } catch is SlowDownException {
                interval += 5                  // service-mandated backoff
            } catch let error as ExpiredTokenException {
                throw SSOLoginError.serviceRejected(error.message ?? "device code expired")
            }
        }
        throw SSOLoginError.timedOut
    }

    /// Registrations last ~90 days; reuse one until it expires.
    private func registration(for session: SSOSession,
                              client: SSOOIDCClient) async throws -> OIDCRegistration {
        if let existing = store.registration(forKey: session.name) { return existing }

        let output = try await client.registerClient(input: RegisterClientInput(
            clientName: "AWSCostMonitor",
            clientType: "public",
            scopes: session.scopes.isEmpty ? ["sso:account:access"] : session.scopes))
        guard let clientId = output.clientId, let clientSecret = output.clientSecret else {
            throw SSOLoginError.serviceRejected("RegisterClient returned no client credentials.")
        }
        let registration = OIDCRegistration(
            clientId: clientId,
            clientSecret: clientSecret,
            expiresAt: output.clientSecretExpiresAt.map { Date(timeIntervalSince1970: Double($0)) }
                ?? Date().addingTimeInterval(80 * 86400))
        try store.saveRegistration(registration, forKey: session.name)
        return registration
    }
}
```

- [ ] **Step 7: Layer the Keychain in front of the CLI cache**

Create the composite in `AWSCostMonitor/Managers/CredentialAdapters.swift`:

```swift
/// Prefer a token this app minted; fall back to one the AWS CLI wrote. Either
/// direction of "who signed in last" then works, without writing the CLI's cache.
/// Task 13 replaces this with an injectable, refresh-aware version — this
/// simpler form exists so Task 12 is independently shippable.
struct LayeredTokenStore: SSOTokenProviding {
    let keychain = SSOTokenStore()
    let cli = CLITokenStore()

    func token(forKey key: String) async -> SSOToken? {
        if let mine = await keychain.token(forKey: key), !mine.isExpired { return mine }
        if let theirs = await cli.token(forKey: key), !theirs.isExpired { return theirs }
        // Both stale: return whichever exists so the caller can report *expired*
        // rather than *never signed in*, which implies different user action.
        return await keychain.token(forKey: key) ?? cli.token(forKey: key)
    }
}
```

Change both `CredentialResolver(...)` constructions in `AWSManager` (Task 10, Step 1) to pass `ssoTokens: LayeredTokenStore()`.

- [ ] **Step 8: Replace the Task 11 stub**

In `AWSManager`, add the service and implement the real method:

```swift
    let ssoLogin = SSOLoginService()

    func signInToSSO(session: String) async {
        guard let ssoSession = ssoSessions[session] else {
            errorMessage = "No sso-session named '\(session)' in ~/.aws/config."
            return
        }
        do {
            _ = try await ssoLogin.signIn(session: ssoSession)
            // Minted credentials derived from the old token are now stale.
            await credentialResolver.invalidateCache()
            credentialError = nil
            errorMessage = nil
            await fetchCostForSelectedProfile(force: true)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
```

- [ ] **Step 9: Show the user code while polling**

**Deviation from the spec, deliberate:** the spec describes a modal sign-in *sheet*. Reuse the `StatusBanner` from Task 11 instead. A sheet over a `.applicationDefined` popover fights the global click monitor that dismisses it (`StatusBarController.swift:98`), and the flow has nothing to show but one code and a cancel — the banner already carries both. If the code proves hard to read in the banner, promote it to a sheet later.

In `PopoverContentView.bannerContent`, put the in-flight case first so it wins over the error that triggered it:

```swift
        if awsManager.ssoLogin.isSigningIn {
            let code = awsManager.ssoLogin.userCode.map { " — code \($0)" } ?? ""
            return BannerContent(message: "Waiting for browser sign-in\(code)",
                                 actionTitle: "Cancel",
                                 action: { awsManager.ssoLogin.cancel() })
        }
```

`SSOLoginService` is `@MainActor` and `ObservableObject`; since it is held by `AWSManager` rather than observed directly, add `@Published` republishing in `AWSManager.init`:

```swift
        ssoLogin.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
```

- [ ] **Step 10: Build and test**

```bash
./scripts/run-tests.sh
```
Expected: PASS. Fix any exception-type mismatches against the generated `AWSSSOOIDC` headers — the exception names above (`AuthorizationPendingException`, `SlowDownException`, `ExpiredTokenException`) must match what the SDK actually throws; jump to definition on `SSOOIDCClient.createToken` to confirm.

- [ ] **Step 11: Manual verification — the whole point**

Delete the CLI token: `rm ~/.aws/sso/cache/<digest>.json` for the `ams` session. Open the popover, select `ams-dev`, confirm the "Not signed in" banner, click Sign In. Expected: browser opens to the AWS approval page, the banner shows the user code, approving in the browser makes the banner disappear and real cost data load — with no Terminal involved. Confirm `aws sts get-caller-identity --profile ams-dev` in Terminal still reports *not* logged in, verifying the one-directional design.

- [ ] **Step 12: Commit**

```bash
git add AWSCostMonitor/Utilities/SSOTokenStore.swift \
        AWSCostMonitor/Managers/SSOLoginService.swift \
        AWSCostMonitor/Managers/CredentialAdapters.swift \
        AWSCostMonitor/Managers/AWSManager.swift \
        AWSCostMonitor/Views/PopoverContentView.swift \
        AWSCostMonitorTests/SSOTokenStoreTests.swift \
        AWSCostMonitor.xcodeproj/project.pbxproj
git commit -m "feat(sso): in-app device-authorization sign-in

Tokens go to the Keychain rather than ~/.aws/sso/cache so the sandbox
entitlement stays user-selected read-only. Sharing is one-directional by
design: a CLI login is picked up by the app, an app login does not refresh the
CLI's session."
```

---

### Task 13: Silent token refresh

**Files:**
- Modify: `AWSCostMonitor/Managers/SSOLoginService.swift` (add `refresh(session:token:)`)
- Modify: `AWSCostMonitor/Managers/CredentialAdapters.swift` (`LayeredTokenStore` attempts refresh)
- Test: `AWSCostMonitorTests/SSOTokenStoreTests.swift` (add refresh-preference cases)

**Interfaces:**
- Consumes: `SSOToken.refreshToken`/`clientId`/`clientSecret` (Task 7), `SSOTokenStore` (Task 12).
- Produces: `SSOLoginService.refresh(session: SSOSession, token: SSOToken) async throws -> SSOToken`; `LayeredTokenStore.init(sessions:)` so it can look up the session needed for a refresh.

**Why this exists:** the spec requires that an expired token carrying a `refreshToken` is renewed silently before the user is asked to sign in again. SSO tokens expire roughly every 8 hours; without this, a user who left the app running overnight gets a sign-in prompt every morning even though renewal needs no interaction.

- [ ] **Step 1: Write the failing test**

Append to `AWSCostMonitorTests/SSOTokenStoreTests.swift`:

```swift
    func testLayeredStorePrefersAnUnexpiredKeychainToken() async throws {
        try store.save(token(expiresIn: 3600, access: "keychain"), forKey: key)
        let layered = LayeredTokenStore(keychain: store, cli: StubCLIStore(token: nil), sessions: [:])
        let loaded = await layered.token(forKey: key)
        XCTAssertEqual(loaded?.accessToken, "keychain")
    }

    func testLayeredStoreFallsBackToTheCLIWhenKeychainIsStale() async throws {
        try store.save(token(expiresIn: -60, access: "stale-keychain"), forKey: key)
        let cliToken = SSOToken(accessToken: "from-cli", expiresAt: Date().addingTimeInterval(3600),
                                region: nil, startUrl: nil, refreshToken: nil,
                                clientId: nil, clientSecret: nil)
        let layered = LayeredTokenStore(keychain: store, cli: StubCLIStore(token: cliToken), sessions: [:])
        let loaded = await layered.token(forKey: key)
        XCTAssertEqual(loaded?.accessToken, "from-cli")
    }

    /// Both stale: return the expired token anyway so the caller reports
    /// "expired" (offer Sign In) rather than "never signed in".
    func testLayeredStoreReturnsAnExpiredTokenWhenNoLiveOneExists() async throws {
        try store.save(token(expiresIn: -60, access: "stale-keychain"), forKey: key)
        let layered = LayeredTokenStore(keychain: store, cli: StubCLIStore(token: nil), sessions: [:])
        let loaded = await layered.token(forKey: key)
        XCTAssertEqual(loaded?.accessToken, "stale-keychain")
        XCTAssertTrue(loaded?.isExpired == true)
    }

    func testLayeredStoreReturnsNilWhenNeitherSourceHasAToken() async {
        let layered = LayeredTokenStore(keychain: store, cli: StubCLIStore(token: nil), sessions: [:])
        let loaded = await layered.token(forKey: "absent")
        XCTAssertNil(loaded)
    }
}

private struct StubCLIStore: SSOTokenProviding {
    let token: SSOToken?
    func token(forKey key: String) async -> SSOToken? { token }
}

extension SSOTokenStoreTests {
    // placeholder so the added closing brace above stays balanced
```

**Careful:** the block above closes `final class SSOTokenStoreTests` and opens an extension. When applying, put the four `testLayeredStore…` methods inside the existing class body and declare `StubCLIStore` at file scope after the class — do not paste the brace juggling literally.

- [ ] **Step 2: Run test to verify it fails**

```bash
./scripts/run-tests.sh \
  -destination 'platform=macOS' -only-testing:AWSCostMonitorTests/SSOTokenStoreTests
```
Expected: compile failure — `LayeredTokenStore` has no `init(keychain:cli:sessions:)`.

- [ ] **Step 3: Add the refresh call to SSOLoginService**

In `AWSCostMonitor/Managers/SSOLoginService.swift`:

```swift
    /// Renew an expired token without user interaction. Only possible when the
    /// token carries a refresh token and the client registration that minted it.
    func refresh(session: SSOSession, token: SSOToken) async throws -> SSOToken {
        guard let refreshToken = token.refreshToken,
              let clientId = token.clientId,
              let clientSecret = token.clientSecret else {
            throw AWSCostFetchError.ssoSessionExpired(session: session.name)
        }
        let config = try await SSOOIDCClient.SSOOIDCClientConfiguration(region: session.ssoRegion)
        let client = SSOOIDCClient(config: config)
        let output = try await client.createToken(input: CreateTokenInput(
            clientId: clientId,
            clientSecret: clientSecret,
            grantType: "refresh_token",
            refreshToken: refreshToken))
        guard let accessToken = output.accessToken else {
            throw AWSCostFetchError.ssoSessionExpired(session: session.name)
        }
        let renewed = SSOToken(
            accessToken: accessToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(output.expiresIn ?? 28800)),
            region: session.ssoRegion,
            startUrl: session.startUrl,
            // The service may rotate the refresh token; keep the new one if given.
            refreshToken: output.refreshToken ?? refreshToken,
            clientId: clientId,
            clientSecret: clientSecret)
        try store.save(renewed, forKey: session.name)
        return renewed
    }
```

- [ ] **Step 4: Make `LayeredTokenStore` injectable and refresh-aware**

Replace `LayeredTokenStore` in `AWSCostMonitor/Managers/CredentialAdapters.swift` with:

```swift
/// Prefer a token this app minted; fall back to one the AWS CLI wrote; try a
/// silent refresh before giving up. Never writes the CLI's cache.
struct LayeredTokenStore: SSOTokenProviding {
    let keychain: SSOTokenStore
    let cli: any SSOTokenProviding
    /// Needed to refresh: the OIDC endpoint region and start URL live here.
    let sessions: [String: SSOSession]

    init(keychain: SSOTokenStore = SSOTokenStore(),
         cli: any SSOTokenProviding = CLITokenStore(),
         sessions: [String: SSOSession] = [:]) {
        self.keychain = keychain
        self.cli = cli
        self.sessions = sessions
    }

    func token(forKey key: String) async -> SSOToken? {
        if let mine = await keychain.token(forKey: key), !mine.isExpired { return mine }
        if let theirs = await cli.token(forKey: key), !theirs.isExpired { return theirs }

        // Expired but renewable: refresh_token needs no user interaction, so
        // don't make the user sign in again just because 8 hours passed.
        if let stale = await keychain.token(forKey: key),
           stale.refreshToken != nil,
           let session = sessions[key],
           let renewed = try? await SSOLoginService(store: keychain).refresh(session: session, token: stale) {
            return renewed
        }

        // Return the expired token so the caller reports "expired" (offer Sign
        // In) rather than "never signed in", which implies different user action.
        return await keychain.token(forKey: key) ?? cli.token(forKey: key)
    }
}
```

`SSOLoginService` is `@MainActor`; calling `refresh` from this non-isolated context requires `await`, which the `try? await` above provides.

- [ ] **Step 5: Pass the sessions through**

In `AWSManager.loadProfiles`, update the resolver construction from Task 10 Step 1 to supply the parsed sessions:

```swift
        self.credentialResolver = CredentialResolver(
            configs: self.profileConfigs,
            ssoTokens: LayeredTokenStore(sessions: self.ssoSessions),
            ssoRoles: LiveSSORoleFetcher(), sts: LiveSTSAssumer())
```

- [ ] **Step 6: Run tests**

```bash
./scripts/run-tests.sh
```
Expected: PASS. Verify the `CreateTokenInput` label set for the refresh grant against the generated `AWSSSOOIDC` headers — `refreshToken` may be spelled differently, and `deviceCode` is absent for this grant type.

- [ ] **Step 7: Manual verification**

Sign in via the app, then edit the Keychain-stored token's `expiresAt` into the past (or wait out the 8 hours). Open the popover. Expected: costs load with no sign-in prompt and no browser window — the refresh happened silently. Confirm in Console that no `StartDeviceAuthorization` was issued.

- [ ] **Step 8: Commit**

```bash
git add AWSCostMonitor/Managers/SSOLoginService.swift \
        AWSCostMonitor/Managers/CredentialAdapters.swift \
        AWSCostMonitor/Managers/AWSManager.swift \
        AWSCostMonitorTests/SSOTokenStoreTests.swift
git commit -m "feat(sso): silently refresh expired tokens via refresh_token

SSO access tokens last ~8 hours. Without this, leaving the app running
overnight produces a sign-in prompt every morning for a renewal that needs no
user interaction."
```

---

### Task 14: SSO session management in Settings

**Files:**
- Create: `AWSCostMonitor/Views/SSOSettingsSection.swift`
- Modify: `AWSCostMonitor/SettingsView.swift` (mount the section)

**Interfaces:**
- Consumes: `AWSManager.ssoSessions` (Task 5), `SSOTokenStore` and `SSOLoginService` (Task 12), `LayeredTokenStore` (Task 12).
- Produces: `struct SSOSettingsSection: View`.

- [ ] **Step 1: Write the section**

Create `AWSCostMonitor/Views/SSOSettingsSection.swift`:

```swift
import SwiftUI

/// Lists the sso-sessions declared in ~/.aws/config with their current token
/// state, so a user can sign in ahead of an expiry instead of discovering it
/// when the menu bar goes blank.
struct SSOSettingsSection: View {
    @EnvironmentObject var awsManager: AWSManager
    @State private var expiries: [String: Date] = [:]

    private let store = SSOTokenStore()

    var body: some View {
        Section("AWS SSO") {
            if awsManager.ssoSessions.isEmpty {
                Text("No sso-session blocks found in ~/.aws/config.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            ForEach(awsManager.ssoSessions.keys.sorted(), id: \.self) { name in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name).font(.body)
                        Text(statusText(for: name))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Sign In") {
                        Task {
                            await awsManager.signInToSSO(session: name)
                            await refreshExpiry(for: name)
                        }
                    }
                    .disabled(awsManager.ssoLogin.isSigningIn)

                    Button("Sign Out") {
                        try? store.delete(forKey: name)
                        Task {
                            await awsManager.credentialResolver.invalidateCache()
                            await refreshExpiry(for: name)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .task { await refreshAllExpiries() }
    }

    private func statusText(for name: String) -> String {
        guard let expiry = expiries[name] else { return "Not signed in" }
        if expiry <= Date() { return "Expired" }
        let fmt = RelativeDateTimeFormatter()
        return "Signed in — expires \(fmt.localizedString(for: expiry, relativeTo: Date()))"
    }

    private func refreshAllExpiries() async {
        for name in awsManager.ssoSessions.keys { await refreshExpiry(for: name) }
    }

    private func refreshExpiry(for name: String) async {
        // LayeredTokenStore, not the Keychain alone: a session the user signed
        // into via the CLI is genuinely usable and should read as signed in.
        expiries[name] = await LayeredTokenStore().token(forKey: name)?.expiresAt
    }
}
```

- [ ] **Step 2: Mount it in Settings**

In `AWSCostMonitor/SettingsView.swift`, find the tab containing AWS/profile configuration and add `SSOSettingsSection()` to its `Form`. If the settings use a `TabView` of separate views, add it to the profiles/AWS tab rather than creating a new tab — one more tab for two buttons is not worth the navigation cost.

- [ ] **Step 3: Build and test**

```bash
./scripts/run-tests.sh
```
Expected: PASS.

- [ ] **Step 4: Manual verification**

Open Settings. Expected: both `ams` and `middleout` sessions listed, each showing "Signed in — expires in N hours", "Expired", or "Not signed in" correctly. Sign Out flips a session to "Not signed in" and makes its profiles show the banner. Sign In restores it.

- [ ] **Step 5: Commit**

```bash
git add AWSCostMonitor/Views/SSOSettingsSection.swift AWSCostMonitor/SettingsView.swift \
        AWSCostMonitor.xcodeproj/project.pbxproj
git commit -m "feat(settings): SSO session list with sign in and sign out"
```

---

## Final Verification

- [ ] **Full suite green**

```bash
./scripts/run-tests.sh
```

- [ ] **The open-source scheme still builds** (it has different signing and is what CI uses)

```bash
xcodebuild build -project AWSCostMonitor.xcodeproj -scheme AWSCostMonitor-OpenSource -destination 'platform=macOS'
```

- [ ] **Entitlements unchanged**

```bash
git diff --stat main -- AWSCostMonitor/AWSCostMonitor.entitlements
```
Expected: no output. Adding `files.user-selected.read-write` would contradict the spec's storage decision.

- [ ] **No dead references**

```bash
grep -rn "createAWSCredentialsProvider\|popover.availableWidth\|updateAvailableWidth\|centeredFit" \
  AWSCostMonitor/ AWSCostMonitorTests/
```
Expected: no matches.

- [ ] **Both original complaints resolved.** Popover opens fully on screen from a right-edge status item, on the first open, on every display. `ams-dev`, `ams-mgmt`, and `ams-prod` each show current costs.
