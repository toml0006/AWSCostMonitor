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

### Root Cause

`Views/PopoverContentView.swift:176` derives the popover width from the length of the
formatted cost string:

```swift
private var windowWidth: CGFloat {
    let mtdStr = CurrencyFormatter.format(mtd)
    let projStr = projectedDouble.map { CurrencyFormatter.format($0) } ?? mtdStr
    let heroChars = max(mtdStr.count, projStr.count)
    let columnWidth = CGFloat(heroChars) * 20 + 44
    return max(500, columnWidth * 2 + 1)
}
```

This yields 500pt for `$1,234.56` and roughly 610pt for a seven-figure month-to-date total.

`Controllers/StatusBarController.swift:37` sets `popover.contentSize` to
`NSSize(width: 360, height: 500)` once during `init`, and line 138 calls
`popover.show(relativeTo:of:preferredEdge:)`.

`NSPopover` performs its screen-edge clamping exactly once, at `show()` time, using the
`contentSize` in effect at that moment. It therefore clamps for a 360pt popover. Afterwards
`NSHostingController` reports the true SwiftUI `fittingSize` through `preferredContentSize`,
the popover grows outward from an anchor that was already committed, and no re-clamp runs.
The resulting overhang past the right screen edge is approximately
`(actualWidth - 360) / 2`.

This explains the intermittence: whether the overhang is visible depends jointly on how far
right the status item sits in the menu bar and on how many digits the currently selected
profile's MTD total has. Switching profiles while the popover is open resizes it live and
reproduces the same bug without any re-clamp at all.

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

`PopoverGeometryTests` covers the two pure functions:

- `availableWidth` subtracts `2 * edgeMargin` from the screen width
- `clampedWidth` with a desired width below `minWidth` returns `minWidth`
- `clampedWidth` with a desired width above the allowance returns `availableWidth`
- `clampedWidth` with a desired width that fits returns it unchanged
- a narrow external display forces a result below `minWidth` (screen cap wins)

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

1. **Popover clamp** — `PopoverGeometry`, `PopoverSizing`, `StatusBarController` changes.
   No dependency on the rest.
2. **Config parser** — `AWSConfigParser`, `AWSManager.loadProfiles` migration. Fixes the
   phantom `sso-session` profile immediately and is a prerequisite for steps 3 and 4.
3. **SSO via cached token** — `SSOTokenCache`, `CredentialResolver` SSO path, typed errors,
   popover and settings messaging. Delivers working SSO for anyone with a live
   `aws sso login` session.
4. **Assume-role chaining** — `CredentialResolver` assume-role path with cycle guard.
5. **In-app device-auth sign-in** — `SSOLoginService`, Keychain storage, sign-in sheet,
   Settings section. Removes the Terminal dependency.
