# Spec Requirements Document

> Spec: Team Cache Integration
> Created: 2025-08-22

## Overview

Implement a team-shared cost snapshot cache using Amazon S3 to reduce redundant AWS Cost Explorer API calls across team members. The feature enables cooperative policy enforcement with auto-refresh cadence, manual cooldown periods, and optimistic concurrency control, while maintaining the app's privacy-first architecture.

## User Stories

### Team Cost Collaboration

As a **DevOps Team Lead**, I want to share AWS cost data cache with my team members, so that we reduce API costs and all team members see consistent cost information.

When I enable team cache for our AWS profile, the app will automatically share fresh cost data to an S3 bucket that all team members can access. The app shows who last refreshed the data and when, preventing unnecessary duplicate API calls. Each refresh saves the team money by avoiding redundant Cost Explorer queries that cost $0.01 each.

### Transparent Cache Management

As a **Developer on a team**, I want to see when cost data was last updated and by whom, so that I know the freshness of the data and when I can refresh it myself.

The menu bar displays "Updated 2h ago by Jackson • Data through Aug 21" with a color-coded staleness indicator. When data is stale (>12h old), I can trigger a manual refresh if no one else has done so in the last 30 minutes. The app shows a countdown timer when manual refresh is on cooldown, ensuring fair access for all team members.

### Automatic Background Synchronization

As an **Engineering Manager**, I want the cost data to stay reasonably fresh without manual intervention, so that my team always has recent cost visibility without thinking about it.

The app automatically checks for refresh eligibility every 6 hours (with ±10% jitter to prevent synchronized attempts). When eligible, it acquires a soft lock, fetches fresh data from AWS Cost Explorer, and updates the shared cache. If multiple team members' apps try to refresh simultaneously, the optimistic concurrency control ensures only one succeeds, preventing duplicate API calls.

## Spec Scope

1. **S3-based Team Cache** - Store and retrieve cost snapshots from a configurable S3 bucket with team-based prefixes
2. **Cooperative Policy Enforcement** - Client-side enforcement of 6-hour auto-refresh intervals and 30-minute manual cooldowns
3. **Optimistic Concurrency Control** - Use ETags and soft locks to prevent simultaneous updates and race conditions
4. **Transparency UI Elements** - Display last updater, update time, data freshness, and next eligible refresh windows
5. **Graceful Degradation** - Fall back to local-only mode when team cache is unavailable, maintaining core functionality

## Out of Scope

- Server-side policy enforcement (will be added in future relay implementation)
- Cross-team data sharing or aggregation
- Historical data retention beyond current month
- Real-time synchronization between clients
- Automated IAM policy provisioning

## Expected Deliverable

1. Complete integration of existing S3CacheService with AWSManager's cost fetching workflow, checking team cache before making API calls
2. Functional auto-refresh timer that respects 6-hour intervals with jitter and acquires/releases locks appropriately
3. UI showing transparent cache status including who updated when, staleness indicators, and countdown timers for manual refresh availability