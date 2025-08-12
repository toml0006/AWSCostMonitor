# Privacy Policy for AWSCostMonitor

**Last Updated: August 12, 2025**

## Overview

AWSCostMonitor is committed to protecting your privacy. This privacy policy explains our data practices for the AWSCostMonitor macOS application.

## Data Collection

**We do not collect any personal data.**

AWSCostMonitor is a privacy-first application that:
- Does NOT collect any personal information
- Does NOT track user behavior or analytics
- Does NOT send data to external servers (except AWS APIs for cost retrieval)
- Does NOT use cookies or tracking technologies
- Does NOT share any information with third parties

## Local Data Storage

All application data is stored locally on your Mac:
- AWS profile selections are saved in macOS UserDefaults
- Cost data is temporarily cached in memory during app usage
- Security-scoped bookmarks for AWS credential file access are stored locally
- All data remains on your device and under your control

## AWS API Communication

The app communicates only with AWS Cost Explorer APIs to retrieve your cost data:
- Uses your existing AWS credentials from ~/.aws/config
- Makes read-only API calls to AWS Cost Explorer
- Does not modify any AWS resources
- Communication is encrypted using HTTPS

## Team Cache Feature (Pro Version)

If you enable the optional Team Cache feature:
- Data is stored in YOUR AWS S3 bucket
- You control all access permissions
- No data passes through our servers
- All S3 operations use your AWS credentials

## Children's Privacy

This app is not directed to children under 13. We do not knowingly collect personal information from children.

## Changes to This Policy

We may update this privacy policy from time to time. Any changes will be reflected in the "Last Updated" date above.

## Contact

If you have questions about this privacy policy, please contact us:
- GitHub Issues: https://github.com/toml0006/AWSCostMonitor/issues
- Email: [Your contact email]

## Compliance

This app complies with:
- Apple's App Store Review Guidelines
- macOS App Sandbox requirements
- General Data Protection Regulation (GDPR) principles

---

© 2025 AWSCostMonitor. All rights reserved.