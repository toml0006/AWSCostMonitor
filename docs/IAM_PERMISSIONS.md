# IAM Permissions Guide for AWSCostMonitor

This document provides comprehensive IAM permission requirements for AWSCostMonitor, including both basic functionality and Team Cache features.

## Table of Contents

- [Basic Permissions](#basic-permissions)
- [Team Cache Permissions](#team-cache-permissions)
- [Complete IAM Policy](#complete-iam-policy)
- [Cross-Account Access](#cross-account-access)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)

## Basic Permissions

For basic AWSCostMonitor functionality, users need read-only access to AWS Cost Explorer.

### Minimum Required Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CostExplorerAccess",
      "Effect": "Allow",
      "Action": [
        "ce:GetCostAndUsage",
        "ce:GetCostForecast"
      ],
      "Resource": "*"
    }
  ]
}
```

### Optional Permissions

For enhanced functionality, you may also want to include:

```json
{
  "Sid": "OptionalEnhancements",
  "Effect": "Allow",
  "Action": [
    "ce:GetDimensionValues",
    "ce:GetTags",
    "ce:GetReservationUtilization",
    "ce:GetSavingsPlansPurchaseRecommendation"
  ],
  "Resource": "*"
}
```

## Team Cache Permissions

Team Cache requires additional S3 permissions to enable cost data sharing among team members.

### S3 Bucket Permissions

Replace `YOUR-BUCKET-NAME` with your actual S3 bucket name:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TeamCacheS3Access",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:HeadObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-BUCKET-NAME/*",
        "arn:aws:s3:::YOUR-BUCKET-NAME"
      ]
    }
  ]
}
```

### STS Permissions (Optional but Recommended)

For account ID resolution and cross-account scenarios:

```json
{
  "Sid": "STSAccess",
  "Effect": "Allow",
  "Action": [
    "sts:GetCallerIdentity"
  ],
  "Resource": "*"
}
```

## Complete IAM Policy

Here's a complete IAM policy that includes all permissions for full AWSCostMonitor functionality with Team Cache:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CostExplorerAccess",
      "Effect": "Allow",
      "Action": [
        "ce:GetCostAndUsage",
        "ce:GetCostForecast"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TeamCacheS3Access",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:HeadObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-BUCKET-NAME/*",
        "arn:aws:s3:::YOUR-BUCKET-NAME"
      ]
    },
    {
      "Sid": "STSAccess",
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

### Creating the IAM Policy

1. **Via AWS Console:**
   ```
   1. Navigate to IAM → Policies
   2. Click "Create policy"
   3. Select "JSON" tab
   4. Paste the policy above
   5. Replace YOUR-BUCKET-NAME with your bucket
   6. Review and create
   ```

2. **Via AWS CLI:**
   ```bash
   # Save the policy to a file
   cat > awscostmonitor-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [...]
   }
   EOF
   
   # Create the policy
   aws iam create-policy \
     --policy-name AWSCostMonitorAccess \
     --policy-document file://awscostmonitor-policy.json
   ```

### Attaching the Policy

1. **To an IAM User:**
   ```bash
   aws iam attach-user-policy \
     --user-name YOUR-USERNAME \
     --policy-arn arn:aws:iam::ACCOUNT-ID:policy/AWSCostMonitorAccess
   ```

2. **To an IAM Role:**
   ```bash
   aws iam attach-role-policy \
     --role-name YOUR-ROLE-NAME \
     --policy-arn arn:aws:iam::ACCOUNT-ID:policy/AWSCostMonitorAccess
   ```

## Cross-Account Access

For organizations using multiple AWS accounts, you can set up cross-account access for Team Cache.

### Option 1: Bucket Policy

Add this bucket policy to allow access from other accounts:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CrossAccountTeamCacheAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::ACCOUNT-ID-1:root",
          "arn:aws:iam::ACCOUNT-ID-2:root"
        ]
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:HeadObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-BUCKET-NAME/*",
        "arn:aws:s3:::YOUR-BUCKET-NAME"
      ]
    }
  ]
}
```

### Option 2: Assume Role

Create a role in the account with the S3 bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::TRUSTED-ACCOUNT-ID:root"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

## Troubleshooting

### Common Permission Issues

1. **"Access Denied" when reading cache:**
   - Verify `s3:GetObject` permission
   - Check bucket name in policy matches actual bucket
   - Ensure resource ARN includes both bucket and objects (`bucket-name/*`)

2. **"Cannot write to cache":**
   - Verify `s3:PutObject` permission
   - Check if bucket has versioning or encryption requirements
   - Ensure no explicit Deny statements in policies

3. **"Cannot list bucket contents":**
   - Verify `s3:ListBucket` permission
   - Note: ListBucket applies to the bucket ARN, not objects

4. **"Cannot determine account ID":**
   - Add `sts:GetCallerIdentity` permission
   - Check if using temporary credentials that have expired

### Testing Permissions

Use AWS CLI to test permissions:

```bash
# Test Cost Explorer access
aws ce get-cost-and-usage \
  --time-period Start=2025-08-01,End=2025-08-02 \
  --granularity DAILY \
  --metrics UnblendedCost \
  --profile YOUR-PROFILE

# Test S3 read access
aws s3 ls s3://YOUR-BUCKET-NAME/teams/ --profile YOUR-PROFILE

# Test S3 write access
echo "test" | aws s3 cp - s3://YOUR-BUCKET-NAME/teams/test.txt --profile YOUR-PROFILE

# Test STS access
aws sts get-caller-identity --profile YOUR-PROFILE
```

## Security Best Practices

### 1. Principle of Least Privilege

Only grant the minimum permissions necessary:
- Use specific bucket names, not wildcards
- Limit actions to only what's needed
- Consider read-only access for some team members

### 2. Resource Restrictions

Be specific with resource ARNs:
```json
// Good - Specific bucket
"Resource": "arn:aws:s3:::myteam-awscost-cache/*"

// Bad - All buckets
"Resource": "arn:aws:s3:::*"
```

### 3. Condition Keys

Add conditions for extra security:
```json
{
  "Sid": "RequireEncryptedTransport",
  "Effect": "Deny",
  "Action": "s3:*",
  "Resource": [
    "arn:aws:s3:::YOUR-BUCKET-NAME/*"
  ],
  "Condition": {
    "Bool": {
      "aws:SecureTransport": "false"
    }
  }
}
```

### 4. Regular Audits

- Review IAM policies quarterly
- Remove unused permissions
- Check CloudTrail logs for unusual activity
- Use AWS Access Analyzer to identify overly permissive policies

### 5. Separate Policies

Consider separate policies for different access levels:
- `AWSCostMonitor-ReadOnly` - Basic cost viewing
- `AWSCostMonitor-TeamCache-Read` - Can read team cache
- `AWSCostMonitor-TeamCache-Full` - Can read and write team cache

## Read-Only Team Member Policy

For team members who should only read cached data, not update it:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CostExplorerReadOnly",
      "Effect": "Allow",
      "Action": [
        "ce:GetCostAndUsage",
        "ce:GetCostForecast"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TeamCacheReadOnly",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:HeadObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-BUCKET-NAME/*",
        "arn:aws:s3:::YOUR-BUCKET-NAME"
      ]
    }
  ]
}
```

## KMS Encryption Support

If using KMS encryption for your S3 bucket, add these permissions:

```json
{
  "Sid": "KMSAccess",
  "Effect": "Allow",
  "Action": [
    "kms:Decrypt",
    "kms:GenerateDataKey"
  ],
  "Resource": "arn:aws:kms:REGION:ACCOUNT-ID:key/KEY-ID"
}
```

## Support

If you encounter permission issues not covered here:

1. Check the app's error logs for specific permission errors
2. Use AWS Policy Simulator to test your policies
3. Review CloudTrail logs for denied API calls
4. Open an issue on [GitHub](https://github.com/toml0006/AWSCostMonitor/issues)

---

*Last updated: August 2025*