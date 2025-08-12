# API Specification

This is the API specification for the spec detailed in @.agent-os/specs/2025-08-11-team-remote-cache/spec.md

> Created: 2025-08-11
> Version: 1.0.0

## S3 Cache Operations

### Cache Retrieval

**Operation:** GetObject
**Purpose:** Retrieve cached cost data from S3 before calling AWS Cost Explorer
**Parameters:** 
- Bucket: Team-configured S3 bucket name
- Key: Generated cache key based on account/month/data-type
- ResponseCacheControl: no-cache (to get fresh metadata)

**Response Format:**
```json
{
  "metadata": {
    "timestamp": "2025-08-11T14:30:00Z",
    "account_id": "123456789012",
    "profile_name": "production",
    "data_type": "mtd_costs",
    "ttl_seconds": 3600,
    "app_version": "1.3.0"
  },
  "data": {
    "cost_and_usage": {
      // AWS Cost Explorer response data
    }
  }
}
```

**Error Handling:**
- NoSuchKey: Cache miss, proceed to AWS API call
- AccessDenied: Log error and fallback to local-only mode
- NetworkError: Retry with exponential backoff, then fallback

### Cache Storage

**Operation:** PutObject
**Purpose:** Store fresh cost data in S3 cache for team sharing
**Parameters:**
- Bucket: Team-configured S3 bucket name  
- Key: Generated cache key
- Body: Compressed JSON with metadata and cost data
- ContentType: application/json
- ContentEncoding: gzip

**Metadata Headers:**
- x-amz-meta-account-id: AWS Account ID
- x-amz-meta-profile: AWS Profile Name
- x-amz-meta-app-version: AWSCostMonitor version
- x-amz-meta-ttl: Cache TTL in seconds

### Cache Validation

**Operation:** HeadObject
**Purpose:** Check if cache exists and get metadata without downloading
**Parameters:**
- Bucket: Team-configured S3 bucket name
- Key: Generated cache key

**Usage:** Quick freshness check before deciding to download cache object

## Swift Service Layer

### RemoteCacheService Protocol

```swift
protocol RemoteCacheService {
    func getCachedData(for profile: AWSProfile, dataType: CacheDataType) async throws -> CachedCostData?
    func storeCachedData(_ data: CachedCostData, for profile: AWSProfile, dataType: CacheDataType) async throws
    func validateCacheKey(for profile: AWSProfile, dataType: CacheDataType) async throws -> CacheMetadata?
}
```

### S3CacheService Implementation

```swift
class S3CacheService: RemoteCacheService {
    private let s3Client: S3Client
    private let config: TeamCacheConfig
    
    func getCachedData(for profile: AWSProfile, dataType: CacheDataType) async throws -> CachedCostData? {
        let key = generateCacheKey(profile: profile, dataType: dataType)
        let request = GetObjectRequest(bucket: config.bucketName, key: key)
        
        do {
            let response = try await s3Client.getObject(input: request)
            return try parseCacheData(from: response.body)
        } catch let error as S3Error.NoSuchKey {
            return nil // Cache miss
        }
    }
}
```

### Cache Manager Integration

```swift
class CacheManager {
    private let localCache: LocalCacheService
    private let remoteCache: RemoteCacheService?
    
    func getCostData(for profile: AWSProfile) async throws -> CostData {
        // 1. Check local cache
        if let localData = localCache.get(for: profile), !localData.isStale {
            return localData
        }
        
        // 2. Check remote cache (if enabled)
        if let remoteCache = remoteCache, profile.teamCacheEnabled {
            if let remoteData = try? await remoteCache.getCachedData(for: profile, dataType: .mtdCosts) {
                if !remoteData.isStale {
                    localCache.store(remoteData, for: profile) // Update local cache
                    return remoteData.costData
                }
            }
        }
        
        // 3. Fallback to AWS API
        let freshData = try await costExplorerService.getCostData(for: profile)
        
        // Store in both caches
        localCache.store(freshData, for: profile)
        if let remoteCache = remoteCache, profile.teamCacheEnabled {
            try? await remoteCache.storeCachedData(freshData, for: profile, dataType: .mtdCosts)
        }
        
        return freshData
    }
}
```

## Error Response Handling

### S3 Service Errors

**AccessDenied (403)**
- **Cause:** Insufficient IAM permissions for S3 bucket
- **Action:** Log detailed error, display setup instructions to user, disable remote cache for profile
- **User Message:** "Team cache unavailable: Check S3 bucket permissions"

**NoSuchBucket (404)**
- **Cause:** S3 bucket doesn't exist or wrong region
- **Action:** Validate bucket configuration, provide bucket creation guide
- **User Message:** "Team cache bucket not found. Check configuration."

**ServiceUnavailable (503)**
- **Cause:** Temporary S3 service issues
- **Action:** Retry with exponential backoff, then fallback to local-only mode
- **User Message:** "Team cache temporarily unavailable, using local data only"

### Network and Connectivity

**Timeout Errors**
- **Action:** Retry with longer timeout, then fallback
- **Logging:** Log timeout duration and retry attempts

**DNS Resolution Failures**
- **Action:** Immediate fallback to local-only mode
- **Logging:** Log DNS error for troubleshooting

## IAM Policy Requirements

### Minimum Required Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:HeadObject"
      ],
      "Resource": "arn:aws:s3:::team-cost-cache/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::team-cost-cache"
    }
  ]
}
```

### Cross-Account Access Policy

For teams with multiple AWS accounts sharing a cache bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TeamCacheAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::ACCOUNT-A:root",
          "arn:aws:iam::ACCOUNT-B:root"
        ]
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:HeadObject"
      ],
      "Resource": "arn:aws:s3:::team-cost-cache/*"
    }
  ]
}
```