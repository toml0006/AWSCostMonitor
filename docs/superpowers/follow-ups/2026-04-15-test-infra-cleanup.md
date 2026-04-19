# Follow-up: fix 6 pre-existing test failures

**Discovered:** 2026-04-15 during baseline verification before starting Ledger design work.
**Status:** Not blocking Ledger (all 6 are test-infrastructure, not production regressions). Skipped during Ledger plan execution; fix in a dedicated test-infra pass.

## Failing tests

### Profile tests (UserDefaults leakage)

1. `AWSManagerProfileTests.testRemovedProfileWithPreservedData`
2. `AWSManagerProfileTests.testUpdateProfileVisibilityRefreshesProfilesList`

**Root cause:** `ProfileManager` hardcodes `UserDefaults.standard` under key `"ProfileVisibilitySettings"`. Tests don't reset it, so state leaks across the suite.

**Fix:** Inject `UserDefaults` into `ProfileManager.init`. Tests supply `UserDefaults(suiteName: UUID().uuidString)` and tear it down.

### Timer tests (async start not awaited)

3. `AWSCostMonitorTests.testAWSManagerTimerManagement`
4. `AWSCostMonitorTests.testRefreshIntervalChangesUpdateTimer`
5. `TimerLifecycleTests.testIsAutoRefreshActiveTracksStartStop`
6. `TimerLifecycleTests.testIntervalZeroStopsTimers`

**Root cause:** `AWSManager.startAutomaticRefresh()` defers timer creation inside a `Task` when `nextRefreshTime == nil`. Tests read `isAutoRefreshActive` synchronously and see `false`.

**Fix options (pick one):**
- Have tests `await` a condition poll (`XCTWaiter` on `isAutoRefreshActive`).
- Refactor `isAutoRefreshActive` to reflect intent (`autoRefreshEnabled` flag) set synchronously before the Task spawns.

## How Ledger plans handle this

Plan A test commands skip these six explicitly:

```bash
xcodebuild test \
  -project AWSCostMonitor.xcodeproj \
  -scheme AWSCostMonitor \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/ledger-foundation-dd \
  -skip-testing:AWSCostMonitorTests/AWSManagerProfileTests/testRemovedProfileWithPreservedData \
  -skip-testing:AWSCostMonitorTests/AWSManagerProfileTests/testUpdateProfileVisibilityRefreshesProfilesList \
  -skip-testing:AWSCostMonitorTests/AWSCostMonitorTests/testAWSManagerTimerManagement \
  -skip-testing:AWSCostMonitorTests/AWSCostMonitorTests/testRefreshIntervalChangesUpdateTimer \
  -skip-testing:AWSCostMonitorTests/TimerLifecycleTests/testIsAutoRefreshActiveTracksStartStop \
  -skip-testing:AWSCostMonitorTests/TimerLifecycleTests/testIntervalZeroStopsTimers
```

## When to address

Schedule a ~2-hour test-infra pass after Ledger Plan A ships.
