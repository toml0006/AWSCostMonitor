# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-11-team-remote-cache/spec.md

> Created: 2025-08-11
> Version: 1.0.0

## Technical Requirements

### Remote Cache Architecture
- Use AWS S3 as the remote cache storage backend
- Implement cache keys based on AWS Account ID + Month/Year + Data Type
- Support cache TTL of 15-60 minutes based on existing local cache logic
- Store cache metadata including timestamp and data freshness indicators

### Data Format and Structure
- Cache objects stored as JSON in S3 with standardized naming convention
- Include metadata: timestamp, account_id, profile_name, data_type, ttl
- Compress large cache objects to minimize S3 storage costs
- Implement cache versioning to handle schema changes

### Security and Access Control
- Leverage existing AWS IAM credentials and profiles for S3 access
- Require S3 bucket read/write permissions in addition to Cost Explorer access
- No additional authentication mechanisms beyond AWS IAM
- Support cross-account access for teams with multiple AWS accounts

### Configuration Management
- Add "Team Cache" section to Settings window
- Per-profile toggle for team cache participation
- S3 bucket configuration per profile or globally
- Cache behavior configuration (TTL overrides, fallback preferences)

### Error Handling and Resilience
- Implement exponential backoff for S3 access failures
- Clear error messages for common misconfigurations (bucket permissions, etc.)
- Automatic fallback to local-only mode when remote cache is unavailable
- Retry logic for transient S3 failures

## Approach Options

**Option A:** Profile-Specific S3 Buckets
- Pros: Complete isolation between teams/accounts, simpler permissions
- Cons: More complex configuration, potential for bucket sprawl

**Option B:** Shared S3 Bucket with Key Prefixing (Selected)
- Pros: Simpler configuration, cost-effective, supports cross-account teams
- Cons: Requires careful key management, potential for permission complexity

**Option C:** Custom Cache Server
- Pros: Full control over caching behavior, custom authentication
- Cons: Infrastructure complexity, contradicts privacy-first design

**Rationale:** Option B provides the best balance of simplicity and functionality while leveraging AWS's existing security model. Teams can use a single S3 bucket with appropriate IAM policies to control access.

## External Dependencies

### AWS SDK Extensions
- **AWSS3** - S3 SDK module for cache storage operations
- **Justification:** Required for reading/writing cache data to S3 buckets

### JSON Handling
- **Foundation JSONEncoder/Decoder** - Enhanced for cache serialization
- **Justification:** Need reliable serialization for cache objects with metadata

### Compression Library
- **Compression** - Swift's built-in compression framework
- **Justification:** Reduce S3 storage costs and transfer time for large cache objects

## Implementation Details

### Cache Key Structure
```
cache-v1/{account_id}/{year}-{month}/{data_type}.json.gz
Example: cache-v1/123456789012/2025-08/mtd-costs.json.gz
```

### S3 Bucket Configuration
- Versioning enabled for cache object history
- Lifecycle rules to automatically delete old cache objects (>30 days)
- Server-side encryption enabled by default
- Cross-account access via bucket policy when needed

### Data Flow
1. User requests cost data
2. Check local cache first (existing behavior)
3. If local cache miss, check remote S3 cache
4. If remote cache hit and fresh, use cached data
5. If remote cache miss/stale, call AWS Cost Explorer API
6. Store fresh data in both local and remote cache
7. Display data to user

### Configuration Schema
```swift
struct TeamCacheConfig {
    var enabled: Bool
    var s3BucketName: String
    var s3Region: String
    var cachePrefix: String
    var ttlOverride: TimeInterval?
}

struct ProfileConfig {
    var teamCacheEnabled: Bool
    var teamCacheConfig: TeamCacheConfig?
}
```

### Error Scenarios and Handling
- **S3 bucket doesn't exist**: Clear error message with setup instructions
- **Insufficient S3 permissions**: Detailed error with required IAM policy
- **Network connectivity issues**: Automatic fallback with retry logic
- **Corrupted cache data**: Delete corrupted objects and fallback to API
- **S3 service outage**: Graceful degradation to local-only mode