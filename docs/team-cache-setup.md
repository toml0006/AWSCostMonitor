# Team Cache Setup Guide

## Overview

Team Cache is a powerful feature in AWSCostMonitor that allows teams to share AWS cost data through a centralized S3 bucket. This dramatically reduces API calls to AWS Cost Explorer (by up to 90%) and ensures all team members see consistent, up-to-date cost information.

## Benefits

- **90% Reduction in API Calls**: Share cached data across your team
- **Cost Savings**: Fewer API calls mean lower AWS bills ($0.01 per API call)
- **Consistent Data**: All team members see the same cost information
- **Faster Performance**: Retrieve data from S3 cache instead of waiting for API calls
- **Automatic Synchronization**: Background updates keep cache fresh

## Prerequisites

Before setting up Team Cache, ensure you have:

1. **AWS Account** with appropriate permissions
2. **S3 Bucket** for storing cache data (or ability to create one)
3. **IAM Permissions** for both S3 and STS services
4. **AWSCostMonitor Pro** (Team Cache is a Pro feature)

## Step 1: Create an S3 Bucket

### Option A: Using AWS Console

1. Open the [AWS S3 Console](https://console.aws.amazon.com/s3/)
2. Click **Create bucket**
3. Enter a globally unique bucket name (e.g., `myteam-awscost-cache`)
4. Select your preferred AWS Region
5. Keep default settings for:
   - Object Ownership: ACLs disabled
   - Block Public Access: Block all public access (enabled)
   - Bucket Versioning: Disabled
   - Encryption: Server-side encryption with S3 managed keys (SSE-S3)
6. Click **Create bucket**

### Option B: Using AWS CLI

```bash
# Create the bucket
aws s3api create-bucket \
  --bucket myteam-awscost-cache \
  --region us-east-1

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket myteam-awscost-cache \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

### Option C: Using Terraform

```hcl
resource "aws_s3_bucket" "team_cache" {
  bucket = "myteam-awscost-cache"
  
  tags = {
    Name        = "AWSCostMonitor Team Cache"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "team_cache" {
  bucket = aws_s3_bucket.team_cache.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "team_cache" {
  bucket = aws_s3_bucket.team_cache.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

## Step 2: Configure IAM Permissions

Each team member needs the following IAM permissions:

### Required S3 Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::myteam-awscost-cache",
        "arn:aws:s3:::myteam-awscost-cache/*"
      ]
    }
  ]
}
```

### Required STS Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

### Complete IAM Policy

Create a policy named `AWSCostMonitorTeamCache` with:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::myteam-awscost-cache",
        "arn:aws:s3:::myteam-awscost-cache/*"
      ]
    },
    {
      "Sid": "STSAccess",
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CostExplorerAccess",
      "Effect": "Allow",
      "Action": [
        "ce:GetCostAndUsage"
      ],
      "Resource": "*"
    }
  ]
}
```

## Step 3: Enable Team Cache in AWSCostMonitor

1. Open AWSCostMonitor
2. Open **Preferences** (⌘,)
3. Navigate to the **Team Cache** tab
4. Select your AWS profile from the dropdown
5. Toggle **"Enable team cache for this profile"** to ON
6. Configure the following settings:

   - **S3 Bucket Name**: Enter your bucket name (e.g., `myteam-awscost-cache`)
   - **S3 Region**: Select the region where your bucket is located
   - **Cache Prefix**: Enter a prefix for organizing cache files (default: `awscost-team-cache`)

7. Click **Test Connection** to verify setup
8. Settings save automatically when changed

## Step 4: Verify Team Cache is Working

### Check Cache Writes

1. In AWSCostMonitor, click the refresh button or wait for automatic refresh
2. Open your S3 bucket in the AWS Console
3. Navigate to: `awscost-team-cache/cache-v1/[ACCOUNT_ID]/[YYYY-MM]/`
4. You should see a file named `full-data.json.gz`

### View Cache Statistics

1. In Team Cache settings, click **Show Statistics**
2. You'll see:
   - Cache hits and misses
   - Hit ratio percentage
   - Error count
   - Total entries and size

### Monitor Console Logs

Enable debug logging to see cache operations:
1. Open Console.app on macOS
2. Filter by "AWSCostMonitor"
3. Look for messages with:
   - `📤 Starting team cache update`
   - `✅ Successfully stored cache in S3`
   - `📥 Team cache service found`

## Step 5: Configure Team Settings

### Recommended Team Configuration

All team members should use the same:
- S3 bucket name
- AWS region
- Cache prefix

### Cache Behavior

- **TTL (Time to Live)**: 1 hour by default
- **Background Sync**: Runs every 30 minutes
- **Auto Cleanup**: Removes cache entries older than 3 months
- **Compression**: Uses LZFSE compression to minimize storage

## Troubleshooting

### Common Issues and Solutions

#### "Connection failed" Error
- Verify S3 bucket exists and is accessible
- Check IAM permissions are correctly configured
- Ensure AWS credentials are properly configured (`~/.aws/credentials`)

#### "Could not resolve account ID" Error
- Add STS permissions to your IAM policy
- Verify `sts:GetCallerIdentity` permission is granted

#### Cache Not Being Written
- Check S3 bucket permissions for `s3:PutObject`
- Verify bucket name and region are correct
- Look for error messages in Console.app

#### Cache Not Being Read
- Ensure `s3:GetObject` permission is granted
- Check if cache files exist in S3
- Verify team members are using the same bucket and prefix

### Testing Permissions

Test your IAM permissions with AWS CLI:

```bash
# Test STS access
aws sts get-caller-identity

# Test S3 read access
aws s3 ls s3://myteam-awscost-cache/

# Test S3 write access
echo "test" | aws s3 cp - s3://myteam-awscost-cache/test.txt

# Test S3 delete access
aws s3 rm s3://myteam-awscost-cache/test.txt
```

## Security Best Practices

1. **Use Encryption**: Enable SSE-S3 or SSE-KMS encryption on your S3 bucket
2. **Restrict Access**: Only grant team members the minimum required permissions
3. **Enable Versioning**: Consider enabling S3 versioning for data recovery
4. **Monitor Access**: Enable S3 access logging to track usage
5. **Regular Audits**: Review IAM policies and bucket permissions quarterly

## Cost Optimization

### API Cost Comparison

Without Team Cache (10 team members):
- 10 members × 48 refreshes/day × 30 days = 14,400 API calls/month
- Cost: 14,400 × $0.01 = **$144/month**

With Team Cache:
- 1 shared cache × 48 refreshes/day × 30 days = 1,440 API calls/month
- Cost: 1,440 × $0.01 = **$14.40/month**
- **Savings: $129.60/month (90% reduction)**

### S3 Storage Costs

- Cache size: ~50KB per month
- S3 Standard storage: $0.023 per GB/month
- Monthly cost: **< $0.01**

## Advanced Configuration

### Custom Cache TTL

Modify cache duration based on your needs:
- **High-frequency updates**: 15-30 minutes for critical monitoring
- **Standard updates**: 1 hour (default)
- **Low-frequency updates**: 2-4 hours for stable environments

### Cross-Account Access

For teams using multiple AWS accounts:

1. Create a centralized S3 bucket in one account
2. Configure cross-account IAM roles
3. Use AssumeRole to access the shared bucket
4. Ensure all accounts have proper trust relationships

### Monitoring and Alerting

Set up CloudWatch alarms for:
- Excessive API calls (potential cache failures)
- S3 bucket size growth
- Failed cache operations
- Access denied errors

## Support

### Need Help?

- **Documentation**: [AWSCostMonitor Docs](https://toml0006.github.io/AWSCostMonitor/)
- **Issues**: [GitHub Issues](https://github.com/toml0006/AWSCostMonitor/issues)
- **Email**: support@awscostmonitor.com

### Feature Requests

Have ideas for improving Team Cache? Submit a feature request on GitHub!

---

*Last updated: August 2024*
*AWSCostMonitor version: 1.2.0+*