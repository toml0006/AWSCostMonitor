# Release v1.5.1 — Reliable Auto-Refresh

A focused patch that fixes two scheduling bugs from v1.5.0 where the menu bar could silently go hours without updating.

## Bug Fixes

- **Per-profile staleness** — Refresh scheduling now anchors on each profile's own last-fetch timestamp instead of a single global timer. Profiles that went stale while another profile was selected now catch up correctly after switching.
- **Cache expiry honors user interval** — `CostCacheEntry.isValidForBudget(_:)` now clamps validity by the profile's configured `refreshIntervalMinutes`. Budget-proximity windows can only tighten the refresh, never extend it past what the user set.
- **Removed the Auto-Refresh toggle** — Auto-refresh is a core function of the app and is now always on. A stale `AutoRefreshEnabled = false` in UserDefaults could silently disable all cost fetches indefinitely (observed on a machine with a 22-hour-old cache). On first launch under v1.5.1 the obsolete key is cleared from both `UserDefaults.standard` and the app suite.

## Internal

- Heartbeat tick and `scheduleNextRefresh` share a single `lastFetchDate(for:)` / `isRefreshDue(for:)` helper pair, removing the window where the timer and the cache could disagree.
- Settings → Refresh Rate no longer shows a Start/Stop row. The refresh interval slider is the only control that remains.

## Requirements

macOS 13.0 or later. Apple Silicon and Intel.

---

## App Store Connect — "What's New" copy

Paste into App Store Connect → Version 1.5.1 → What's New in this Version.

### Short (recommended — first ~170 chars surface in Updates tab)

```
v1.5.1 fixes auto-refresh: each profile now tracks its own last fetch, cache expiry honors your configured interval, and the always-on toggle can no longer be silently disabled.
```

### Full

```
What's New in v1.5.1

• Per-profile refresh scheduling — profiles that went stale while another profile was selected now catch up after switching
• Cache expiry respects the refresh interval you configured — budget proximity can only tighten the window, never extend it
• Removed the Auto-Refresh on/off toggle. Auto-refresh is always on; a stale off value could previously silently disable all updates.
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
           -archivePath build/AWSCostMonitor-v1.5.1.xcarchive
```

### Export for App Store

```bash
xcodebuild -exportArchive \
           -archivePath build/AWSCostMonitor-v1.5.1.xcarchive \
           -exportPath build/AppStore-v1.5.1 \
           -exportOptionsPlist ExportOptions-AppStore.plist
```

### Pre-release checklist

- [x] `MARKETING_VERSION` = `1.5.1` in all targets
- [x] `CURRENT_PROJECT_VERSION` = `9`
- [ ] Archive with Release configuration
- [ ] Validate via App Store Connect
- [ ] Upload via Transporter or Xcode Organizer

## GitHub Release Instructions

1. Tag `v1.5.1` on main (done as part of the release commit).
2. Release title: `v1.5.1 — Reliable Auto-Refresh`.
3. Paste the "Bug Fixes" section above as the description.
4. Attach the signed build artifact.
5. Mark as latest release.
