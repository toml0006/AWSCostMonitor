# AWS SSO Support & Menu Bar Popover Clamp — Design

> Date: 2026-07-25
> Status: Approved
> Scope: `packages/app/AWSCostMonitor`

## Summary

Two independent defects in the shipped app, addressed together because both surface at the
same moment (opening the menu bar popover against a real-world AWS config):

1. The popover overflows the right edge of the screen because its `contentSize` is stale
   when AppKit computes screen clamping.
2. The app cannot authenticate any AWS SSO profile, cannot authenticate any
   `role_arn` + `source_profile` chain, and leaks `[sso-session ...]` config sections into
   the profile picker as phantom profiles.

---

## Part A: Popover Width Clamp

### Prior Art

This bug has been attacked three times already on `main`: `39ab91f`
("clamp width to screen so it can't clip off a display edge"), `04d1aaf`, `2a56c3d`
("size at show-time, not via live-resize"), and `cb744d1` ("robustly prevent right-edge
clipping"). The machinery those commits added is still present and is part of the current
root cause. This design replaces it rather than adding a fourth layer.

### Root Cause

`Views/PopoverContentView.swift:187` derives the ideal width from the length of the
formatted cost string, then clamps it against a value published by the controller:

```swift
private var windowWidth: CGFloat {
    let mtdStr = CurrencyFormatter.format(mtd)
    let projStr = projectedDouble.map { CurrencyFormatter.format($0) } ?? mtdStr
    let heroChars = max(mtdStr.count, projStr.count)
    let columnWidth = CGFloat(heroChars) * 20 + 44
    let ideal = max(500, columnWidth * 2 + 1)
    return availableWidth > 0 ? min(ideal, CGFloat(availableWidth)) : ideal
}
```

`ideal` is 500pt for `$1,234.56` and roughly 610pt for a seven-figure month-to-date total.

Three defects compound.

**A1 — The clamp shrinks the content instead of moving the window.**
`Controllers/StatusBarController.swift:181` computes the published width:

```swift
let rightGap = visible.maxX - itemCenterX
let leftGap  = itemCenterX - visible.minX
let centeredFit = 2 * min(rightGap, leftGap) - margin
let available = max(360, min(visible.width - 2 * margin, centeredFit))
```

`centeredFit` assumes the popover must stay centered on its arrow. For a menu bar item near
the right edge — which is the normal case for this app — `rightGap` is small, so
`centeredFit` is small, and `available` floors out at 360. `windowWidth` then returns
`min(ideal, 360)` = 360.

But `Popover/HeroSplit.swift:174` lays out each hero column at `.frame(width: 210,
alignment: .leading)`, with `.fixedSize()` text inside, and SwiftUI does not clip children
that overflow their parent frame. Roughly 420pt of intrinsic content is therefore rendered
inside a 360pt popover and spills past its right edge. **The anti-clipping mechanism is what
produces the visible clipping.**

**A2 — The width channel is asynchronous, so the first show uses stale data.**
`updateAvailableWidth` writes to `UserDefaults` under key `popover.availableWidth`;
`PopoverContentView.swift:10` reads it back through
`@AppStorage("popover.availableWidth")`. `NSPopover` measures its content synchronously
inside `show()`. The existing comment at `StatusBarController.swift:153-157` already concedes
that "a given show can use the previous show's width". Moving between displays, or switching
to a profile with a different digit count, is wrong on the first open and right on the
second.

**A3 — The safety net's precondition was silently revoked.**
`cb744d1` introduced `clampPopoverOnScreen()` and, in the same commit, set
`popover.animates = false`. The doc comment at `StatusBarController.swift:158` records the
dependency in prose: "With animations off the window is already at its final frame here, so
this is a stable, one-shot adjustment." Commit `9f1c3c9` ("restore glow + fade") flipped
`popover.animates` back to `true` (line 44) and left the clamp untouched. The clamp now reads
`win.frame` while the popover is mid-fade, and the presentation animation overwrites the
corrected origin.

Nothing in the type system or the test suite tied the clamp to `animates == false`, which is
why a polish commit could revert the precondition from a distance. The fix must be
independent of animation timing so that this cannot recur.

### Design

The governing correction is **stop shrinking, start moving**. A 610pt popover fits
comfortably on any display the app supports; what it needs is to be shifted left, not
squeezed below the width its own content requires.

Three changes, each addressing one defect.

**A1 — Remove the centered-fit squeeze and enforce a content floor.**
The published width is constrained only by the total usable screen width, never by where the
status item happens to sit:

```swift
// Utilities/PopoverSizing.swift
enum PopoverGeometry {
    static let minWidth: CGFloat = 500      // below this, HeroSplit's columns overflow
    static let edgeMargin: CGFloat = 12

    /// Horizontal space a popover may occupy on a given screen.
    static func availableWidth(screenWidth: CGFloat) -> CGFloat {
        screenWidth - 2 * edgeMargin
    }

    /// Width the content wants, floored at `minWidth` and capped to what the screen allows.
    /// The screen cap wins over `minWidth` only on displays too narrow to honour both.
    static func clampedWidth(desired: CGFloat, availableWidth: CGFloat) -> CGFloat {
        min(max(desired, minWidth), availableWidth)
    }

    /// Origin.x that keeps `width` fully on screen, preferring `idealX`.
    static func clampedOriginX(idealX: CGFloat, width: CGFloat, visible: NSRect) -> CGFloat {
        let maxX = visible.maxX - edgeMargin - width
        let minX = visible.minX + edgeMargin
        return max(minX, min(idealX, maxX))
    }
}
```

`minWidth` rises from the old 360 floor to 500, matching the value `windowWidth` already
treats as its own minimum. The two are now the same constant rather than two numbers that
disagree.

**A2 — Replace the UserDefaults channel with a synchronous one.**

```swift
@MainActor
final class PopoverSizing: ObservableObject {
    /// Published by the controller from the status item's current screen.
    @Published var availableWidth: CGFloat = .greatestFiniteMagnitude
}
```

`StatusBarController` owns the instance, injects it via `.environmentObject`, and retains a
reference to the `NSHostingController` (it currently constructs one inline at line 48 and
discards the reference). `PopoverContentView` drops
`@AppStorage("popover.availableWidth")` in favour of `@EnvironmentObject var sizing:
PopoverSizing`, and routes its computed `ideal` through
`PopoverGeometry.clampedWidth(desired:availableWidth:)`.

```swift
func showPopover() {
    guard let button = statusItem.button else { return }
    let screen = button.window?.screen ?? NSScreen.main
    sizing.availableWidth = PopoverGeometry.availableWidth(
        screenWidth: screen?.visibleFrame.width ?? 1440
    )
    // Force SwiftUI to re-lay-out against the new cap before measuring. Without
    // this, fittingSize reports the previous layout pass and the stale-width bug
    // (A2) reappears through a different route.
    hostingController.view.layoutSubtreeIfNeeded()
    popover.contentSize = hostingController.view.fittingSize
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
}
```

Setting `contentSize` explicitly before `show()` means AppKit performs its own edge
clamping against the true size rather than a stale one.

**A3 — Make the window clamp independent of animation timing.**
`clampPopoverOnScreen()` moves from an inline call after `show()` to the
`NSPopoverDelegate` callback `popoverDidShow(_:)`, which fires after the presentation
animation completes regardless of the `animates` setting. `StatusBarController` adopts
`NSPopoverDelegate` and sets `popover.delegate = self`. The body is rewritten in terms of
`PopoverGeometry.clampedOriginX` so the geometry is testable:

```swift
func popoverDidShow(_ notification: Notification) {
    guard let win = popover.contentViewController?.view.window else { return }
    let visible = (win.screen ?? NSScreen.main ?? NSScreen.screens.first!).visibleFrame
    var frame = win.frame
    frame.origin.x = PopoverGeometry.clampedOriginX(
        idealX: frame.origin.x, width: frame.width, visible: visible
    )
    if frame.origin.x != win.frame.origin.x {
        win.setFrame(frame, display: true, animate: false)
    }
}
```

`popover.animates` is left at `true`; the fade restored in `9f1c3c9` is preserved. The stale
doc comment at `StatusBarController.swift:153-159` asserting a dependency on animations being
off is deleted, since the dependency no longer exists.

Live resizing (switching from a low-cost profile to a high-cost one while the popover is
open) re-runs the measure-and-show sequence. This attaches to the existing debounced
`Publishers.MergeMany` pipeline at `Controllers/StatusBarController.swift:92` — one
additional sink, not a new mechanism — so it inherits the 50ms debounce that was added to
prevent overlapping AppKit mutations. Display topology changes are handled by observing
`NSApplication.didChangeScreenParametersNotification`.

The `popover.availableWidth` UserDefaults key is removed. No migration is needed; a stale
value left in the domain is simply never read again.

### Design

Introduce a pure geometry helper and a small observable object that lets the AppKit
controller communicate the screen constraint down into SwiftUI.

```swift
// Utilities/PopoverSizing.swift
enum PopoverGeometry {
    static let minWidth: CGFloat = 500
    static let edgeMargin: CGFloat = 12

    /// Horizontal space a popover may occupy on a given screen.
    static func availableWidth(screenWidth: CGFloat) -> CGFloat {
        screenWidth - 2 * edgeMargin
    }

    /// Width the content wants, floored at `minWidth` and capped to what the screen allows.
    /// The screen cap wins over `minWidth` on displays too narrow to honour both.
    static func clampedWidth(desired: CGFloat, availableWidth: CGFloat) -> CGFloat {
        min(max(desired, minWidth), availableWidth)
    }
}

@MainActor
final class PopoverSizing: ObservableObject {
    /// Published by the controller from the status item's current screen.
    @Published var availableWidth: CGFloat = .greatestFiniteMagnitude
}
```

`PopoverContentView.windowWidth` keeps its existing character-count computation, then routes
the result through `PopoverGeometry.clampedWidth(desired:availableWidth:)` using the
published `sizing.availableWidth`, so content never renders wider than the popover can be.
`StatusBarController` owns the `PopoverSizing` instance, injects it into the hosting
controller's environment, and retains a reference to the `NSHostingController` (it currently
constructs one inline and discards the reference).

```swift
func showPopover() {
    guard let button = statusItem.button else { return }
    let screen = button.window?.screen ?? NSScreen.main
    syncContentSize(on: screen)
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
}

private func syncContentSize(on screen: NSScreen?) {
    sizing.availableWidth = PopoverGeometry.availableWidth(
        screenWidth: screen?.visibleFrame.width ?? 1440
    )
    // Let SwiftUI re-lay-out against the new cap before measuring.
    hostingController.view.layoutSubtreeIfNeeded()
    popover.contentSize = hostingController.view.fittingSize
}
```

Because `contentSize` is now correct before `show()`, AppKit's own clamping shifts the
popover left as needed while keeping the arrow on the status item.

Live resizing (switching from a low-cost profile to a high-cost one while the popover is
open) is handled by re-running `syncContentSize` and calling `show(relativeTo:of:)` again.
Calling `show` on an already-visible popover re-anchors it without replaying the present
animation. This attaches to the existing debounced `Publishers.MergeMany` pipeline at
`Controllers/StatusBarController.swift:84` — one additional sink, not a new mechanism — so
it inherits the 50ms debounce that was added to prevent overlapping AppKit mutations.

Display topology changes are handled by observing
`NSApplication.didChangeScreenParametersNotification` and re-running `syncContentSize`.

### Testing

`PopoverGeometryTests` covers the three pure functions:

- `availableWidth` subtracts `2 * edgeMargin` from the screen width
- `clampedWidth` with a desired width below `minWidth` returns `minWidth`
- `clampedWidth` with a desired width above the allowance returns `availableWidth`
- `clampedWidth` with a desired width that fits returns it unchanged
- `clampedWidth` on a display too narrow for `minWidth` returns the screen cap
- **Regression for A1:** a status item near the right edge must not reduce the width. The
  old `centeredFit` path is gone, so `clampedWidth` takes no item position at all; the test
  asserts the signature carries only `desired` and `availableWidth`, and that a 610pt
  desired width on a 1440pt display returns 610 — not 360.
- `clampedOriginX` shifts a frame left when it overruns `visible.maxX - edgeMargin`
- `clampedOriginX` shifts a frame right when it underruns `visible.minX + edgeMargin`
- `clampedOriginX` returns `idealX` unchanged when the frame already fits
- `clampedOriginX` prefers the left edge when the frame is wider than the visible area

`NSPopover` placement and the `popoverDidShow` delegate hook are not unit tested; the logic
under test is the pure geometry.

`NSPopover` placement itself is not unit tested; the logic under test is the pure function.

---

## Part B: AWS SSO and Assume-Role Support

### Root Cause

Three distinct defects.

**B1 — Credential resolution ignores SSO entirely.**
`Utilities/AWSCredentialsHelper.swift` branches on the sandbox. The sandboxed branch, which
is what ships (`AWSCostMonitor.entitlements` sets `com.apple.security.app-sandbox` to true),
reads only `~/.aws/credentials` and requires `aws_access_key_id` and
`aws_secret_access_key`. SSO profiles have no entry in that file at all, so resolution
throws `credentialsNotFound`. Non-sandboxed development builds fall through to
`ProfileAWSCredentialIdentityResolver`, which can mask the problem locally while the App
Store build fails.

**B2 — `[sso-session ...]` sections become phantom profiles.**
`Utilities/INIParser.swift:37` treats every bracketed section that is not prefixed
`[profile ` as a profile name. `Managers/AWSManager.swift:673` then maps every parsed key
into an `AWSProfile`. A config containing `[sso-session ams]` therefore produces a
selectable profile literally named `sso-session ams`.

**B3 — Assume-role chains are equally unsupported.**
Profiles declaring `role_arn` with `source_profile` have no static keys of their own and
fail identically to B1.

### Enabling Facts

- The security-scoped bookmark in `AWSConfigAccessManager` is taken on the **`~/.aws`
  folder**, not on individual files. `~/.aws/sso/cache/` is therefore already reachable
  under the sandbox without any entitlement change.
- `AWSSSO` and `AWSSSOOIDC` are present in the pinned `aws-sdk-swift` 1.5.12 checkout. No
  new package dependency is required. `AWSSTS` is already linked in the Xcode project.
- SSO has two credential layers. A **token** is scoped to an `sso-session`, cached under
  `~/.aws/sso/cache/<sha1>.json`, and lives roughly 8 hours; `aws sso login` refreshes only
  this layer. **Credentials** are per-profile, minted by calling `sso:GetRoleCredentials`
  with that token plus `sso_account_id` and `sso_role_name`, and live roughly 1 hour.

### B2 Design: Config Parser

New `Utilities/AWSConfigParser.swift` layered on the existing `INIParser`:

```swift
struct SSOSession {
    let name: String
    let startUrl: String
    let ssoRegion: String
    let scopes: [String]
}

struct SSOProfileRef {
    let sessionName: String?     // nil for legacy inline sso_start_url profiles
    let startUrl: String
    let ssoRegion: String
    let accountId: String
    let roleName: String
}

enum ProfileCredentialSource {
    case staticKeys
    case sso(SSOProfileRef)
    case assumeRole(roleArn: String, sourceProfile: String, mfaSerial: String?)
    case unsupported(reason: String)
}

struct AWSProfileConfig {
    let name: String
    let region: String?
    let source: ProfileCredentialSource
}

enum AWSConfigParser {
    static func parse(configContent: String) -> (profiles: [AWSProfileConfig],
                                                 ssoSessions: [String: SSOSession])
}
```

Section classification rules:

| Section header      | Treated as                                          |
| ------------------- | --------------------------------------------------- |
| `[profile foo]`     | profile named `foo`                                 |
| `[default]`         | profile named `default`                             |
| `[sso-session bar]` | SSO session named `bar` — **never a profile**       |
| `[services baz]`    | ignored                                             |

Source classification, in precedence order:

1. `sso_session` present → `.sso`, resolving `startUrl`/`ssoRegion` from the named session.
   A `sso_session` referencing a session that does not exist yields `.unsupported`.
2. `sso_start_url` present without `sso_session` → `.sso` with `sessionName == nil` (legacy
   inline form).
3. `role_arn` present → `.assumeRole`, carrying `source_profile` and any `mfa_serial`.
   `role_arn` without `source_profile` yields `.unsupported`.
4. `credential_process` present → `.unsupported(reason:)`.
5. Otherwise → `.staticKeys`.

`AWSManager.loadProfiles` consumes `AWSConfigParser.parse` instead of `INIParser.parseString`
directly, which resolves B2 as a side effect of correct classification. `AWSProfile` gains no
new stored properties; the richer `AWSProfileConfig` is held by the resolver, keyed by name,
so the existing `Identifiable`/`Hashable`-by-name contract that the Picker binding depends on
is unchanged.

`AWSConfigParser` is a pure `String` to structs function with no I/O, so it is directly
testable.

### B3 Design: Token Cache

New `Utilities/SSOTokenCache.swift`.

The cache filename is the lowercase SHA-1 hex digest of a cache key. Following the AWS CLI
and botocore convention, the key is the **`sso_session` name** when the profile uses
`sso_session`, and the **`sso_start_url`** for legacy inline profiles. Getting this
derivation right is a hard requirement — an incorrect key silently finds no token and the
feature appears not to work.

The cached JSON carries `accessToken`, `expiresAt`, `region`, `startUrl`, and optionally
`refreshToken`, `clientId`, `clientSecret`, `registrationExpiresAt`. `expiresAt` is ISO 8601
and appears in the wild both with and without fractional seconds; parsing must accept both.

Reads go through `AWSConfigAccessManager`, which currently exposes only `readConfigFile()`
and `readCredentialsFile()`. It gains a general scoped-access accessor so arbitrary paths
under the bookmarked `~/.aws` folder can be read:

```swift
func withScopedAccess<T>(_ body: (URL) throws -> T) rethrows -> T?
```

### B3 Design: Token Storage Decision

**Tokens minted by the app are stored in the macOS Keychain, not written back to
`~/.aws/sso/cache`.**

Rationale: the entitlements file grants `com.apple.security.files.user-selected.read-only`.
Writing the CLI's cache would require upgrading to read-write, which is a materially harder
App Store review posture for an application whose stated differentiator (DEC-003) is
privacy-first, local, read-only access to existing AWS configuration.

Accepted cost: sharing is one-directional. A `aws sso login` run in Terminal is picked up by
the app for free, because the app reads the CLI cache. An in-app sign-in does **not**
refresh the CLI's session.

Keychain items are keyed by SSO session name (or start URL for legacy profiles) and store
the same token fields, plus the OIDC client registration (`clientId`, `clientSecret`,
`registrationExpiresAt`), which is valid for roughly 90 days and is reused across sign-ins.

### B1/B3 Design: Credential Resolver

New `Managers/CredentialResolver.swift`, replacing `createAWSCredentialsProvider`:

```swift
actor CredentialResolver {
    func resolver(for profileName: String) async throws -> any AWSCredentialIdentityResolver
}
```

The ~12 call sites in `AWSManager` change only by awaiting the actor; the returned type is
unchanged, so `CostExplorerClientConfiguration` and `SavingsplansClientConfiguration`
construction is untouched.

Resolution by source:

- **`.staticKeys`** — existing `parseAWSCredentials` path, behaviour unchanged.
- **`.sso`** — obtain an unexpired token, preferring the Keychain and falling back to the
  CLI cache; call `SSOClient.getRoleCredentials(accessToken:accountId:roleName:)` in
  `sso_region`; wrap the result in `StaticAWSCredentialIdentityResolver`.
- **`.assumeRole`** — resolve `source_profile` recursively, then `STSClient.assumeRole`
  with `roleArn` and a generated `roleSessionName`, and wrap the result. Recursion carries a
  visited-set cycle guard and a depth cap of 5, because AWS config files can and do contain
  loops. A profile declaring `mfa_serial` throws `.unsupportedProfile` with an explanatory
  message rather than hanging on an un-answerable prompt.
- **`.unsupported`** — throws `.unsupportedProfile(reason:)` immediately.

**Credential caching is load-bearing, not an optimization.** A representative config chains
eight `*-production` / `*-staging` profiles through a single SSO session. Every call site in
`AWSManager` currently constructs a fresh provider. Uncached, one Cost Explorer refresh
becomes `GetRoleCredentials` + `AssumeRole` + `GetCostAndUsage` — triple the API volume,
directly against the one-request-per-minute principle established in DEC-002. The resolver
caches minted credentials in memory, keyed by profile name, until `expiration - 5 minutes`.
Tokens are cached by session key on the same expiry-margin basis.

### B4 Design: In-App Sign-In

New `Managers/SSOLoginService.swift`, using `AWSSSOOIDC`:

1. `RegisterClient` with `clientName: "AWSCostMonitor"`, `clientType: "public"`, and scopes
   from the session's `sso_registration_scopes` (defaulting to `sso:account:access`). The
   resulting registration is cached in the Keychain and reused until
   `registrationExpiresAt`.
2. `StartDeviceAuthorization` with the session `startUrl`, yielding
   `verificationUriComplete`, `deviceCode`, `interval`, and `expiresIn`.
3. `NSWorkspace.shared.open(verificationUriComplete)`.
4. Poll `CreateToken` with `grantType: "urn:ietf:params:oauth:grant-type:device_code"`,
   honouring the server-supplied `interval`. `AuthorizationPendingException` means continue;
   `SlowDownException` increases the interval by 5 seconds; `ExpiredTokenException` and
   `expiresIn` elapsing both abort with a user-visible message.
5. Persist the token to the Keychain.

Silent renewal: when a stored token carries a `refreshToken`, the resolver attempts
`CreateToken` with `grantType: "refresh_token"` before surfacing an expiry error to the user.

### Error Model

`Utilities/Errors.swift` gains typed cases replacing the generic `credentialsNotFound` for
these paths:

- `.ssoNotLoggedIn(session: String)` — no token found for the session
- `.ssoSessionExpired(session: String)` — token found but past `expiresAt`, and refresh
  either absent or failed
- `.unsupportedProfile(profile: String, reason: String)` — `credential_process`,
  `mfa_serial`, dangling `sso_session`, `role_arn` without `source_profile`, cycle detected,
  or depth cap exceeded

Every failure path maps to one of these and renders as actionable text. No path silently
falls back to demo data or to a different profile.

### UI

- **Popover.** When the selected profile fails with `.ssoNotLoggedIn` or
  `.ssoSessionExpired`, `ProfileRow` renders an inline `Sign in to <session>` button in place
  of the generic error text.
- **Sign-in sheet.** Displays the user code and a "waiting for browser" state while
  `CreateToken` polls, with a cancel action that aborts the poll loop.
- **Settings.** A new section lists discovered SSO sessions with their token expiry and
  offers Sign In / Sign Out per session.
- Profiles are **not** regrouped by SSO session in the picker. Deliberately out of scope.

### Testing

- `AWSConfigParserTests` — fixture mirroring a real multi-account config containing
  `[default]`, `[sso-session ...]`, session-based SSO profiles, legacy inline SSO profiles,
  `role_arn` chains, and a `credential_process` profile. Asserts no phantom profiles are
  emitted and that every profile is classified into the correct `ProfileCredentialSource`.
- `SSOTokenCacheTests` — SHA-1 key derivation for both the session-name and start-URL forms;
  ISO 8601 expiry parsing with and without fractional seconds; expired-token detection.
- `CredentialResolverTests` — protocol-injected fake SSO and STS clients covering assume-role
  chain depth, cycle detection, cache reuse before expiry, cache miss after expiry, and each
  typed error case.
- `PopoverGeometryTests` — as described in Part A.

---

## Delivery Sequence

Each step is independently releasable and independently testable.

1. **Popover clamp** — `PopoverGeometry`, `PopoverSizing`, `StatusBarController` and
   `PopoverContentView` changes, removing the `centeredFit` squeeze, the
   `popover.availableWidth` UserDefaults channel, and the inline post-show clamp. No
   dependency on the rest.
2. **Config parser** — `AWSConfigParser`, `AWSManager.loadProfiles` migration. Fixes the
   phantom `sso-session` profile immediately and is a prerequisite for steps 3 and 4.
3. **SSO via cached token** — `SSOTokenCache`, `CredentialResolver` SSO path, typed errors,
   popover and settings messaging. Delivers working SSO for anyone with a live
   `aws sso login` session.
4. **Assume-role chaining** — `CredentialResolver` assume-role path with cycle guard.
5. **In-app device-auth sign-in** — `SSOLoginService`, Keychain storage, sign-in sheet,
   Settings section. Removes the Terminal dependency.
