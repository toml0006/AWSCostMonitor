# Team Cache Setup Guide

## Quick Start

This guide will help you set up team cache for AWSCostMonitor in 15 minutes.

## Prerequisites

- AWSCostMonitor v1.3.0 or later
- AWS account with admin or power user access
- AWS CLI configured (optional, for testing)

## Step 1: Choose Your Setup Method

### Option A: CloudFormation (Recommended)

Best for teams wanting automated, repeatable setup.

### Option B: Terraform

Best for teams already using Terraform for infrastructure.

### Option C: Manual Setup

Best for understanding the components or customizing the setup.

## Step 2: CloudFormation Setup

### Deploy the Stack

1. Download the CloudFormation template:
   ```bash
   curl -O https://raw.githubusercontent.com/yourusername/AWSCostMonitor/main/docs/team-cache/s3-bucket-cloudformation.yaml
   ```

2. Deploy via AWS Console:
   - Navigate to CloudFormation in AWS Console
   - Click "Create Stack" → "With new resources"
   - Upload the template file
   - Fill in parameters:
     - **BucketName**: `my-team-awscost-cache`
     - **EnableKMSEncryption**: `false` (or `true` for enhanced security)
     - **TeamAccountIds**: Comma-separated AWS account IDs (if multi-account)
   - Review and create stack

3. Or deploy via AWS CLI:
   ```bash
   aws cloudformation create-stack \
     --stack-name awscost-team-cache \
     --template-body file://s3-bucket-cloudformation.yaml \
     --parameters \
       ParameterKey=BucketName,ParameterValue=my-team-awscost-cache \
       ParameterKey=EnableKMSEncryption,ParameterValue=false \
     --capabilities CAPABILITY_NAMED_IAM
   ```

4. Wait for stack creation:
   ```bash
   aws cloudformation wait stack-create-complete \
     --stack-name awscost-team-cache
   ```

5. Get the outputs:
   ```bash
   aws cloudformation describe-stacks \
     --stack-name awscost-team-cache \
     --query 'Stacks[0].Outputs'
   ```

## Step 3: Terraform Setup

1. Create `terraform.tfvars`:
   ```hcl
   bucket_name = "my-team-awscost-cache"
   enable_kms_encryption = false
   team_account_ids = ["123456789012", "234567890123"]
   ```

2. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. Note the outputs:
   ```bash
   terraform output
   ```

## Step 4: Manual Setup

### Create S3 Bucket

1. Create the bucket:
   ```bash
   aws s3 mb s3://my-team-awscost-cache --region us-east-1
   ```

2. Enable encryption:
   ```bash
   aws s3api put-bucket-encryption \
     --bucket my-team-awscost-cache \
     --server-side-encryption-configuration '{
       "Rules": [{
         "ApplyServerSideEncryptionByDefault": {
           "SSEAlgorithm": "AES256"
         }
       }]
     }'
   ```

3. Block public access:
   ```bash
   aws s3api put-public-access-block \
     --bucket my-team-awscost-cache \
     --public-access-block-configuration \
       "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
   ```

4. Enable versioning:
   ```bash
   aws s3api put-bucket-versioning \
     --bucket my-team-awscost-cache \
     --versioning-configuration Status=Enabled
   ```

5. Add lifecycle policy:
   ```bash
   aws s3api put-bucket-lifecycle-configuration \
     --bucket my-team-awscost-cache \
     --lifecycle-configuration '{
       "Rules": [{
         "ID": "DeleteOldCache",
         "Status": "Enabled",
         "Prefix": "awscost-team-cache/",
         "Expiration": {
           "Days": 30
         }
       }]
     }'
   ```

## Step 5: Configure IAM Permissions

### For Each Team Member

1. Create IAM policy from template:
   ```bash
   # Download the policy template
   curl -O https://raw.githubusercontent.com/yourusername/AWSCostMonitor/main/docs/team-cache/iam-policy-template.json
   
   # Replace YOUR_BUCKET_NAME with your actual bucket name
   sed -i 's/YOUR_BUCKET_NAME/my-team-awscost-cache/g' iam-policy-template.json
   ```

2. Create the policy:
   ```bash
   aws iam create-policy \
     --policy-name AWSCostMonitor-TeamCache \
     --policy-document file://iam-policy-template.json
   ```

3. Attach to user or role:
   ```bash
   aws iam attach-user-policy \
     --user-name username \
     --policy-arn arn:aws:iam::123456789012:policy/AWSCostMonitor-TeamCache
   ```

### For Read-Only Team Members

Use `iam-policy-readonly.json` instead for members who should only consume cached data.

## Step 6: Configure AWSCostMonitor

### In the App

1. Open AWSCostMonitor
2. Click the gear icon → Settings
3. Navigate to "Team Cache" tab
4. Enter your configuration:
   - **S3 Bucket Name**: `my-team-awscost-cache`
   - **AWS Region**: `us-east-1` (or your chosen region)
   - **Cache Prefix**: `awscost-team-cache` (default)
5. Click "Test Connection"
6. If successful, enable for desired profiles

### Per-Profile Configuration

1. In Settings → Profiles
2. Select a profile
3. Toggle "Enable Team Cache" 
4. Save settings

## Step 7: Verify Setup

### Test Cache Write

1. Select a profile with team cache enabled
2. Click "Refresh" to fetch fresh data
3. Check S3 bucket for cache files:
   ```bash
   aws s3 ls s3://my-team-awscost-cache/awscost-team-cache/ --recursive
   ```

### Test Cache Read

1. Have another team member configure the same bucket
2. They should see cached data without making API calls
3. Verify in the status bar: "📦 Cached" indicator

### Check Audit Logs

```bash
aws s3 ls s3://my-team-awscost-cache-audit-logs/team-cache-access/
```

## Troubleshooting

### Common Issues

#### "Access Denied" Error

**Cause**: Missing IAM permissions
**Solution**: 
1. Verify IAM policy is attached
2. Check bucket policy allows your account
3. Ensure credentials are current

#### "Bucket Not Found" Error

**Cause**: Incorrect bucket name or region
**Solution**:
1. Verify bucket exists: `aws s3 ls | grep my-team-awscost-cache`
2. Check region matches configuration
3. Ensure bucket name has no typos

#### "Network Error" 

**Cause**: Connectivity issues or firewall
**Solution**:
1. Test AWS connectivity: `aws s3 ls`
2. Check corporate firewall/proxy settings
3. Verify AWS credentials are valid

#### Cache Not Being Used

**Cause**: Cache expired or missing
**Solution**:
1. Check cache TTL settings
2. Verify another team member has populated cache
3. Look for "📦" indicator in menu bar

### Debug Mode

Enable debug logging for detailed troubleshooting:

1. Settings → Advanced → Enable Debug Mode
2. Check logs: `~/Library/Logs/AWSCostMonitor/`
3. Look for S3CacheService entries

## Best Practices

### For Team Leads

1. **Set Up Once**: Use CloudFormation/Terraform for consistency
2. **Document Settings**: Share bucket name and region with team
3. **Monitor Usage**: Review audit logs monthly
4. **Rotate Credentials**: Update IAM credentials quarterly

### For Team Members

1. **Enable Selectively**: Only enable for shared accounts
2. **Respect Cache**: Don't force refresh unnecessarily  
3. **Report Issues**: Alert team lead of any errors
4. **Keep Updated**: Use latest AWSCostMonitor version

### For Security

1. **Use Encryption**: Enable SSE-S3 at minimum
2. **Audit Access**: Review logs regularly
3. **Limit Scope**: Only share non-sensitive accounts
4. **Rotate Keys**: If using KMS, rotate annually

## Advanced Configuration

### Multi-Region Setup

For global teams, set up buckets in multiple regions:

```bash
# US Team
aws s3 mb s3://awscost-cache-us --region us-east-1

# EU Team  
aws s3 mb s3://awscost-cache-eu --region eu-west-1

# APAC Team
aws s3 mb s3://awscost-cache-apac --region ap-southeast-1
```

### Cross-Account Access

For multi-account organizations:

1. Set up bucket in central account
2. Add bucket policy for cross-account access
3. Create roles in each account with assume permissions
4. Configure AWSCostMonitor to use role assumption

### KMS Encryption

For enhanced security:

1. Create KMS key:
   ```bash
   aws kms create-key --description "AWSCostMonitor Team Cache"
   ```

2. Update bucket encryption:
   ```bash
   aws s3api put-bucket-encryption \
     --bucket my-team-awscost-cache \
     --server-side-encryption-configuration '{
       "Rules": [{
         "ApplyServerSideEncryptionByDefault": {
           "SSEAlgorithm": "aws:kms",
           "KMSMasterKeyID": "arn:aws:kms:..."
         }
       }]
     }'
   ```

3. Grant team members KMS permissions

## Migration Guide

### From Local-Only to Team Cache

1. Back up local cache settings
2. Deploy S3 infrastructure
3. Configure one profile at a time
4. Verify functionality before full rollout
5. Monitor for first week

### Changing S3 Buckets

1. Create new bucket with setup steps
2. Update configuration in app
3. Wait for old cache to expire (30 days)
4. Delete old bucket

## Support

### Documentation

- [Security Best Practices](./SECURITY.md)
- [IAM Policy Templates](./iam-policy-template.json)
- [CloudFormation Template](./s3-bucket-cloudformation.yaml)
- [Terraform Configuration](./s3-bucket-terraform.tf)

### Getting Help

- GitHub Issues: [Report problems](https://github.com/yourusername/AWSCostMonitor/issues)
- Discussions: [Ask questions](https://github.com/yourusername/AWSCostMonitor/discussions)

---

*Last Updated: 2025-08-11*
*Version: 1.0.0*