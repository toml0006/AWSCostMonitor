# Team Cache Documentation

## Overview

This directory contains comprehensive documentation for the AWSCostMonitor Team Cache feature, which allows teams to securely share AWS cost data through S3-based caching.

## Documentation Structure

### Setup & Configuration

- **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** - Step-by-step guide for setting up team cache
- **[s3-bucket-cloudformation.yaml](./s3-bucket-cloudformation.yaml)** - CloudFormation template for automated S3 bucket setup
- **[s3-bucket-terraform.tf](./s3-bucket-terraform.tf)** - Terraform configuration for infrastructure as code

### Security

- **[SECURITY.md](./SECURITY.md)** - Comprehensive security best practices and compliance guidance
- **[iam-policy-template.json](./iam-policy-template.json)** - IAM policy for full team cache access
- **[iam-policy-readonly.json](./iam-policy-readonly.json)** - IAM policy for read-only team members

### Implementation

- **[IMPLEMENTATION_EXAMPLE.md](./IMPLEMENTATION_EXAMPLE.md)** - Code examples for secure implementation

## Quick Start

### 1. Choose Your Setup Method

- **CloudFormation** (Recommended): Use `s3-bucket-cloudformation.yaml`
- **Terraform**: Use `s3-bucket-terraform.tf`
- **Manual**: Follow steps in `SETUP_GUIDE.md`

### 2. Configure IAM Permissions

Replace `YOUR_BUCKET_NAME` in the IAM policy templates with your actual bucket name:

```bash
sed -i 's/YOUR_BUCKET_NAME/my-team-cache/g' iam-policy-template.json
```

### 3. Enable in AWSCostMonitor

1. Open Settings → Team Cache
2. Enter bucket name and region
3. Test connection
4. Enable for desired profiles

## Security Features

### Encryption Options

- **SSE-S3**: AWS-managed encryption (default)
- **SSE-KMS**: Customer-managed KMS keys
- **None**: Not recommended

### Access Control

- IAM-based authentication
- Principle of least privilege
- Cross-account support
- Audit logging

### Compliance

- GDPR compliant
- SOC 2 ready
- HIPAA considerations
- Full audit trail

## File Descriptions

### Infrastructure Templates

| File | Purpose | Use Case |
|------|---------|----------|
| `s3-bucket-cloudformation.yaml` | AWS CloudFormation stack | Automated AWS deployment |
| `s3-bucket-terraform.tf` | Terraform configuration | Infrastructure as code |

### IAM Policies

| File | Purpose | Permissions |
|------|---------|-------------|
| `iam-policy-template.json` | Full access policy | Read, write, delete cache |
| `iam-policy-readonly.json` | Read-only policy | Read cache only |

### Documentation

| File | Purpose | Audience |
|------|---------|----------|
| `SETUP_GUIDE.md` | Installation guide | DevOps, Team Leads |
| `SECURITY.md` | Security documentation | Security Teams, Compliance |
| `IMPLEMENTATION_EXAMPLE.md` | Code examples | Developers |

## Best Practices

1. **Always enable encryption** (SSE-S3 minimum)
2. **Use IAM policies** from templates
3. **Enable audit logging** for compliance
4. **Test permissions** before rollout
5. **Monitor access patterns** regularly

## Support Matrix

| Feature | SSE-S3 | SSE-KMS | No Encryption |
|---------|--------|---------|---------------|
| Zero Config | ✅ | ❌ | ✅ |
| Compliance Ready | ✅ | ✅ | ❌ |
| Key Management | AWS | Customer | N/A |
| Additional Cost | No | Yes | No |
| Audit Trail | ✅ | ✅ | ✅ |

## Troubleshooting

### Common Issues

1. **Access Denied**: Check IAM policy attachment
2. **Bucket Not Found**: Verify bucket name and region
3. **KMS Errors**: Ensure KMS key permissions
4. **Network Errors**: Check firewall/proxy settings

### Debug Steps

1. Enable debug mode in AWSCostMonitor
2. Check logs at `~/Library/Logs/AWSCostMonitor/`
3. Verify with AWS CLI: `aws s3 ls s3://your-bucket/`
4. Test IAM permissions with policy simulator

## Migration Path

### From v1.2.0 to v1.3.0

1. No breaking changes
2. Optional: Enable audit logging
3. Optional: Switch to KMS encryption
4. Optional: Update IAM policies for new features

## Roadmap

### Current (v1.3.0)
- ✅ S3-based team cache
- ✅ SSE-S3 and SSE-KMS encryption
- ✅ IAM permission validation
- ✅ Audit logging

### Future Considerations
- 🔄 Client-side encryption option
- 🔄 Cache analytics dashboard
- 🔄 Automated permission remediation
- 🔄 Multi-region cache replication

## Contributing

To contribute to team cache documentation:

1. Follow existing documentation style
2. Test all code examples
3. Update this README with new files
4. Submit PR with clear description

## License

This documentation is part of AWSCostMonitor and follows the same license terms.

---

*Last Updated: 2025-08-11*
*Documentation Version: 1.0.0*
*Compatible with: AWSCostMonitor v1.3.0+*