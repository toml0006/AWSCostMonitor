# Auto-Refresh Timers, Catch-Up, and Reliability

This document explains how AWSCostMonitor schedules background refreshes, how idle/lock state affects them, what “catch-up” refresh does, and how to verify behavior in the field.

## Overview
- Dual-timer strategy for resilience:
  - Dispatch timer: `DispatchSourceTimer` scheduled on a background queue
  - Async timer: Task-based loop using `Task.sleep` with a 60s validation loop
- Screen-aware policy to avoid unnecessary API calls while you’re away:
  - Refreshes only proceed when the screen is on, the system is unlocked, and the user has been active within the last 5 minutes
- Catch-up refresh: when you become active/unlocked again, the app checks staleness and performs a refresh if needed

## How Auto-Refresh Works
- Entry: `AWSManager.startAutomaticRefresh()`
  - Cancels any existing timers
  - Sets `AutoRefreshEnabled = true`
  - Determines the interval from the selected profile’s budget (`refreshIntervalMinutes`)
  - If data looks stale, performs an immediate refresh, then schedules timers
  - Otherwise schedules timers directly
- Scheduling:
  - `scheduleNextRefresh()` creates a `DispatchSourceTimer` and logs:
    - “Scheduling next refresh in X minutes …”
    - “DispatchSourceTimer scheduled successfully. Next refresh at: …”
    - When fired: “🔄 Refresh timer FIRED …”
  - `startAsyncRefreshTimer()` starts a Task loop and a validation Task:
    - Logs: “Starting modern async refresh timer …”
    - When fired: “🔄 Async refresh timer FIRED …”
    - If overdue: validation logs and restarts the timers

## Screen-Aware Refresh
- `ScreenStateMonitor.shouldAllowRefresh()` requires:
  - Screen on (not asleep), and system unlocked
  - User input within last 5 minutes (idle < 300s)
- If not allowed, scheduled fires log:
  - “Skipped scheduled refresh: screen off or locked”
- This reduces API usage while you’re away, but by itself can starve refreshes if every fire happens while idle/locked.

## Catch-Up Refresh (Becoming Active/Unlocked)
- On state change to active/unlocked (`handleScreenStateChange()`):
  - If auto-refresh is enabled and no timers are running (Dispatch or async), timers are started
  - If auto-refresh is enabled and data appears stale (`checkIfRefreshNeeded()`), a one-time catch-up refresh is triggered immediately
  - Log anchor: “Catch-up refresh after becoming active/unlocked”
- Effect: missed runs due to idle/lock no longer leave the app stale until the next distant interval or a manual click.

## Timer Lifecycle Improvements
- Interval changes (`refreshInterval` didSet):
  - Now restart timers when either timer type is active (Dispatch or async)
- Profile switch (`saveSelectedProfile`):
  - Restarts timers if any timer is active
  - Starts timers if `AutoRefreshEnabled` is true but no timers are running
- Startup restore (`loadSelectedProfile`):
  - Starts timers if `AutoRefreshEnabled` is true and no timers are running

## Verification (no UI interaction required)
- Live logs (watch a few minutes):
  - `log stream --style compact --predicate 'process == "AWSCostMonitor"'`
  - Look for:
    - “Starting automatic refresh timer …”
    - “DispatchSourceTimer scheduled successfully …”
    - “🔄 Refresh timer FIRED …” / “🔄 Async refresh timer FIRED …”
    - “Skipped scheduled refresh: screen off or locked”
    - “Catch-up refresh after becoming active/unlocked”
- Check current cache age and settings:
  - `swift packages/app/AWSCostMonitor/check_timer_status.swift`
- Inspect persisted defaults (advanced):
  - `defaults export middleout.AWSCostMonitor -` (then decode keys like `CostCacheData`, `APIRequestRecords`)

## Common Symptoms and Likely Causes
- “Only updates when I click the menubar”
  - Idle/lock gating was skipping scheduled fires; opening the popover forces a refresh (if data > 30 min old)
  - Catch-up refresh fixes this: a refresh runs when you become active/unlocked
- Interval changed but background didn’t seem to adapt
  - Previously only restarted when the Dispatch timer was active; now restarts for either timer type
- Switched profiles and refreshes stopped
  - Previously restarted only if Dispatch timer was present; now consistently restarts/starts based on `AutoRefreshEnabled`

## Notes
- Rate limiting is still enforced (~1 request/min). If a catch-up runs soon after a prior fetch, the request may be deferred to respect limits.
- Release builds may filter some debug logs; prefer the Info/Warning/Error messages noted above.

