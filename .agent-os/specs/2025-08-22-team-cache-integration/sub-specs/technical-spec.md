# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-22-team-cache-integration/spec.md

> Created: 2025-08-22
> Version: 1.0.0

## Technical Requirements

### Core Integration Requirements

- **Cache-First Retrieval Pattern**: Modify `AWSManager.fetchCostForSelectedProfile()` to check team cache before making AWS API calls
- **S3CacheService Integration**: Wire up the existing S3CacheService (already 697 lines of production code) to the main cost retrieval workflow
- **Dual Cache Storage**: Store fresh API responses to both local cache (existing) and remote S3 cache (new integration)
- **Fallback Logic**: Implement graceful degradation when team cache is unavailable (network issues, permissions, etc.)

### Cooperative Policy Enforcement

- **Auto-Refresh Timer**: Implement a 6-hour interval timer with ±10% jitter computed once per process
- **Manual Cooldown**: Enforce 30-minute team-wide cooldown for manual refreshes
- **Soft Lock Mechanism**: 
  - Acquire lock before refresh (120-second TTL)
  - Use optimistic concurrency with ETags
  - Handle 412 Precondition Failed responses
  - Automatic lock recovery after TTL expiration

### UI/UX Specifications

- **Transparency Display**:
  - "Updated {relative_time} by {name} • Data through {as_of_date}"
  - Color-coded staleness indicators (green ≤12h, yellow 12-24h, red >24h)
  - Countdown timer for manual refresh availability
  - Next auto-refresh window display
  
- **Menu Bar Integration**:
  - Add team cache status to existing popover
  - Show cache hit/miss statistics
  - Display estimated API cost savings

### S3 Structure and Operations

- **Object Keys**:
  - Cache: `teams/{team_id}/cache.json`
  - Lock: `teams/{team_id}/cache.lock`
  - Audit: `teams/{team_id}/audit/{yyyy-mm-dd}/{uuid}.json`

- **Concurrency Control**:
  - Always fetch and store ETag from GET operations
  - Include `If-Match` header on PUT operations
  - Handle 412 responses with exponential backoff
  - Set `Content-Type: application/json` and `Cache-Control: no-store` headers

### Performance Criteria

- **API Call Reduction**: Target 5-10x reduction in Cost Explorer API calls for teams
- **Cache Response Time**: S3 cache retrieval should complete within 2 seconds
- **Background Operations**: All cache operations must be non-blocking to UI
- **Memory Usage**: Cache data should not exceed 10MB in memory

### Constants and Timings

```swift
static let AUTO_INTERVAL: TimeInterval = 6 * 60 * 60        // 6 hours
static let MANUAL_COOLDOWN: TimeInterval = 30 * 60          // 30 minutes
static let LEASE_TTL: TimeInterval = 120                    // 120 seconds
static let JITTER_PERCENTAGE: Double = 0.1                  // ±10%
static let STALE_YELLOW: TimeInterval = 12 * 60 * 60        // 12 hours
static let STALE_RED: TimeInterval = 24 * 60 * 60           // 24 hours
```

### Future Relay Hooks

- **Protocol Definition**: Create `TeamCacheStorage` protocol for abstraction
- **S3OnlyClient**: Current implementation using AWS SDK
- **RelayClient Stub**: Future implementation for API Gateway integration (not active)
- **Configuration**: Support `storage_mode` enum ("s3_only" | "relay")

## Approach

### Integration Pattern

The integration follows a cache-first approach where:
1. Check team cache first for existing data
2. Return cached data if fresh enough
3. Fall back to AWS API if cache miss or stale
4. Store API responses to both local and team cache

### Concurrency Management

Using optimistic concurrency control with ETags to handle multiple team members:
- Each cache operation includes ETag metadata
- PUT operations use If-Match headers
- 412 conflicts trigger retry with exponential backoff

### Error Handling

Graceful degradation ensures the app remains functional:
- Network failures fall back to local cache only
- S3 permission errors disable team cache temporarily  
- Invalid configurations revert to individual mode

## External Dependencies

- **AWS SDK for Swift - S3 Module** - Already included in project
  - **Justification:** Required for S3 operations (GET/PUT with ETags)
  - **Version:** Latest stable (already in Package.swift)