# Release v1.8.0 — AWS SSO & Assume-Role Support

v1.8 makes the app work with how most teams actually authenticate to AWS. Profiles backed by IAM Identity Center (`sso_session`) and profiles that assume a role (`role_arn` + `source_profile`) now resolve — including chains that start from an SSO login. You can sign in from the app itself, or reuse the session you already created with `aws sso login`.

It also fixes the menu bar popover being cut off at the right edge of the screen. v1.7 attempted that fix three times; this release identifies why those attempts didn't hold and corrects the actual cause.

## Features Added

- **AWS SSO (IAM Identity Center) profiles** — profiles declaring `sso_session`, plus legacy profiles that inline `sso_start_url`, now authenticate. The app reads the AWS CLI's existing token cache, so if you've run `aws sso login` the app just works.
- **In-app sign-in** — no Terminal required. Signing in uses the standard OAuth 2.0 Device Authorization flow: the app opens your browser to AWS's own approval page, you approve with your organization's identity provider, and the app receives a short-lived token. Your password is never seen or handled by the app.
- **Silent session renewal** — when a token the app minted carries a refresh token, it renews in the background. Leaving the app running overnight no longer means a sign-in prompt in the morning for a renewal that needs no interaction.
- **Assume-role profiles** — `role_arn` with `source_profile` now resolves via `sts:AssumeRole`, including multi-step chains whose source is an SSO profile. Cycles and over-deep chains are detected and reported rather than hanging.
- **SSO session management in Settings** — every `sso-session` in your config is listed with its current state: signed in and when it expires, expired, or not signed in. Sign In and Sign Out per session.
- **Credential problems are now visible** — an expired or missing session shows an explicit banner in the popover with a Sign In button, instead of silently displaying zeroes.

## Bug Fixes

- **The popover no longer runs off the right edge of the screen.** Three earlier attempts (v1.7) tried to solve this by shrinking the popover to fit the space beside the menu bar icon. That was the bug: the hero columns have a fixed intrinsic width, SwiftUI does not clip content that overflows its frame, and so a squeezed popover spilled its contents past its own edge. The popover is now measured against the display and repositioned rather than shrunk, and the on-screen correction no longer depends on animation timing — which is what silently undid the previous fix.
- **The popover is correct on the first open.** The width used to cross from the controller to the view through `UserDefaults`, which updates asynchronously, while the popover measures its content synchronously — so a given open could use the *previous* open's width. Moving to a different display or switching to a profile with more digits was wrong once, then right.
- **`[sso-session ...]` blocks no longer appear in the profile picker.** They were being parsed as if they were profiles, producing unusable entries named e.g. `sso-session ams`.
- Profiles the app cannot use — `credential_process`, `mfa_serial`, `role_arn` without a `source_profile`, or a reference to an SSO session that doesn't exist — now report a specific reason instead of a generic credentials error.

## Under the hood

- Credentials are cached per profile until shortly before they expire. This matters: a config where several profiles chain through one SSO session would otherwise turn a single cost refresh into three AWS calls, against the app's one-request-per-minute limit.
- 118 unit tests, including the credential resolver's chain, cycle, and cache behaviour, and the popover's placement geometry.

## Privacy & security

- **Tokens the app creates are stored in the macOS Keychain**, not written to disk and not written into the AWS CLI's own cache. The app reads `~/.aws` but never writes to it, which is why the sandbox entitlement remains read-only.
- Sharing is deliberately one-directional: a Terminal `aws sso login` is picked up by the app; an in-app sign-in does not alter your CLI session. Settings shows which session a token came from, and Sign Out is disabled when the usable token belongs to the CLI rather than the app.
- No analytics, telemetry, or third-party services. All data stays on your machine.

## New network endpoints

Outbound HTTPS only, to AWS-operated endpoints, and only for SSO profiles:

- `oidc.<region>.amazonaws.com` — device-authorization sign-in and token refresh
- `portal.sso.<region>.amazonaws.com` — exchanging an SSO token for temporary role credentials

## New IAM permissions

None. SSO and assume-role use your existing identity; the app still only reads cost data.

## Requirements

macOS 13.0 or later. Apple Silicon and Intel.

---

## App Store Connect — "What's New" copy

Paste into App Store Connect → Version 1.8.0 → What's New in this Version.

### Short (first ~170 chars surface in the Updates tab)

```
AWS SSO support — IAM Identity Center profiles now work, with sign-in from the app or reuse of your existing aws sso login. Assume-role profiles too. Popover no longer clips off-screen.
```

### Full

```
AWS SSO and assume-role support.

• AWS SSO (IAM Identity Center) — profiles using sso_session now work. Sign in from the app, or reuse the session you already created with `aws sso login`.
• In-app sign-in — opens your browser to AWS's own approval page. No Terminal needed, and your password is never handled by the app.
• Silent session renewal — expired sessions renew in the background where possible, instead of prompting you.
• Assume-role profiles — role_arn with source_profile now resolves, including chains that start from an SSO login.
• Manage SSO sessions in Settings — see which are signed in, when they expire, and sign in or out per session.
• Expired credentials now say so in the popover with a Sign In button, instead of showing zeroes.
• Fixed: the popover could be cut off at the right edge of the screen.
• Fixed: SSO session blocks in ~/.aws/config appeared in the profile picker as unusable entries.

Tokens created by the app are stored in your macOS Keychain. The app reads ~/.aws but never writes to it.
```
