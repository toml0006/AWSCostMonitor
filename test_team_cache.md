# Team Cache Feature Test Plan

## Prerequisites
1. AWS credentials configured in ~/.aws/config
2. S3 bucket created for team cache storage  
3. Proper IAM permissions for S3 bucket access

## Test Steps

### 1. Enable Team Cache
1. Open AWSCostMonitor app
2. Open Settings (⌘,)
3. Navigate to "Team Cache" tab
4. Select an AWS profile from the dropdown
5. Toggle "Enable team cache for this profile" ON
6. Enter S3 bucket name (e.g., "awscost-team-cache")
7. Select AWS region (e.g., "us-east-1")
8. Enter cache prefix (e.g., "awscost-team-cache")
9. Settings save automatically when changed (no Save button needed)

### 2. Verify Initial Cache Write
1. Select an AWS profile (same one configured for team cache)
2. Click refresh or wait for automatic refresh
3. Check Console.app for logs (filter by "AWSCostMonitor"):
   - Look for "📤 Starting team cache update after API call"
   - Look for "✅ Successfully stored cache in S3"
4. Verify in AWS S3 Console:
   - Navigate to your S3 bucket
   - Check for cache files under the prefix path
   - File format: `cache-v1/[ACCOUNT_ID]/[YYYY-MM]/full-data.json.gz`

### 3. Test Cache Read
1. Force quit the app (⌘Q)
2. Relaunch AWSCostMonitor
3. Select the same AWS profile
4. Observe:
   - Data should load from cache (faster)
   - Console should show "Fetched cache from S3"
   - API request counter should NOT increment

### 4. Test Cache Expiration
1. Wait for cache TTL to expire (default 1 hour)
2. Click refresh
3. Verify:
   - New API call is made
   - Cache is updated in S3
   - Fresh data is displayed

### 5. Test Multi-Profile Cache
1. Configure team cache for multiple profiles
2. Switch between profiles
3. Verify each profile:
   - Has its own cache entry
   - Uses correct account ID in cache key
   - Maintains separate cache TTLs

### 6. Test Error Handling
1. Enter invalid S3 bucket name
2. Verify error message appears
3. Remove S3 permissions temporarily
4. Verify graceful fallback to API calls

## Expected Results

✅ Team cache successfully stores cost data in S3
✅ Cache is retrieved on subsequent app launches
✅ API calls are reduced when cache is valid
✅ Multiple profiles maintain separate cache entries
✅ Errors are handled gracefully with fallback to direct API

## Console Log Indicators

### Success Messages:
- "Initialized S3 cache service for profile"
- "Team cache check completed - data is fresh"
- "Stored cache entry in S3"
- "Fetched cache from S3"

### Error Messages:
- "Team cache not enabled for profile"
- "Failed to fetch from team cache"
- "Failed to store in team cache"

## S3 Bucket Structure

```
your-bucket/
└── awscost-team-cache/
    └── cache-v1/
        └── 123456789012/  (AWS Account ID)
            └── 2025-08/    (Year-Month)
                └── full-data.json.gz
```

## Troubleshooting

1. **No cache files in S3**: Check IAM permissions for s3:PutObject
2. **Cache not being read**: Check IAM permissions for s3:GetObject  
3. **Account ID issues**: Ensure STS permissions for GetCallerIdentity
4. **Compression errors**: Verify LZFSE support in AWS SDK

## Notes

- Team cache feature requires Pro license (or open source build)
- Cache TTL is 1 hour by default
- Background sync runs every 30 minutes
- Old cache entries (>3 months) are automatically cleaned up