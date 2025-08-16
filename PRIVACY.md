# Privacy Policy for AWSCostMonitor

*Last Updated: August 16, 2025*

## Overview

AWSCostMonitor is committed to protecting your privacy. This privacy policy explains how our macOS application handles your information.

## Information We Collect

**We do not collect any personal information.** AWSCostMonitor operates entirely on your local machine and does not transmit any data to external servers owned or operated by us.

## How the App Works

### Local Operation Only
- All app functionality runs locally on your Mac
- No telemetry, analytics, or usage data is collected
- No personal information is transmitted to us
- No advertising or tracking mechanisms are included

### AWS Credentials
- The app reads AWS credentials from your local system configuration (`~/.aws/config` and `~/.aws/credentials`)
- These credentials are never transmitted to us or any third party
- Credentials are only used to make direct API calls to AWS services
- All AWS API calls go directly from your machine to AWS

### AWS API Usage
- The app makes direct calls to AWS Cost Explorer API using your credentials
- These calls are made over secure HTTPS connections directly to AWS
- We do not proxy, intercept, or store any of this data
- AWS may collect data about API usage according to their own privacy policy

### Team Cache Feature (Optional)
If you enable the Team Cache feature:
- Data is stored in your own AWS S3 bucket that you control
- You maintain complete ownership and control of this data
- The app only reads and writes to the S3 bucket you specify
- No data passes through our servers

## Data Storage

### Local Storage
- User preferences are stored locally using macOS UserDefaults
- Cached cost data is stored temporarily in memory
- All data remains on your device

### No Cloud Storage
- We do not operate any cloud services
- We do not have access to any of your data
- We cannot see your AWS costs or usage

## Third-Party Services

### AWS Services
- The app connects directly to AWS services (Cost Explorer, S3 if Team Cache is enabled)
- Your use of AWS services is governed by the [AWS Privacy Policy](https://aws.amazon.com/privacy/)
- We recommend reviewing AWS's privacy practices

### App Store Version
- If downloaded from the Mac App Store, Apple's standard terms apply
- In-app purchases (if any) are processed by Apple
- We do not receive any personal information from these transactions

## Data Security

- All connections to AWS use industry-standard HTTPS encryption
- Your AWS credentials are managed by the macOS Keychain and system configuration
- We follow Apple's security best practices for macOS applications

## Your Rights

Since we don't collect any personal data:
- There is no personal data to request, modify, or delete
- You maintain complete control over your AWS credentials
- You can uninstall the app at any time to remove all local data

## Children's Privacy

AWSCostMonitor is not intended for use by children under 13 years of age. We do not knowingly collect personal information from children under 13.

## Changes to This Policy

We may update this privacy policy from time to time. We will notify you of any changes by updating the "Last Updated" date at the top of this policy.

## Open Source

AWSCostMonitor is open source software. You can review our code at:
https://github.com/toml0006/AWSCostMonitor

## Contact

If you have questions about this privacy policy, please contact us through:
- GitHub Issues: https://github.com/toml0006/AWSCostMonitor/issues
- Email: [Add your contact email here]

## Summary

**Your privacy is protected because:**
- ✅ No data collection
- ✅ No telemetry or analytics
- ✅ No external servers
- ✅ Everything stays on your Mac
- ✅ You control your AWS credentials
- ✅ Open source for transparency