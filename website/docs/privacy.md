# Privacy Policy

*Last Updated: August 16, 2025*

## Your Privacy is Our Priority

AWSCostMonitor is designed with privacy at its core. We believe in complete transparency about how our application works and how your data is handled.

## 🔒 Key Privacy Features

<div class="privacy-highlights">
  <div class="highlight-box">
    <h3>❌ No Data Collection</h3>
    <p>We don't collect, store, or transmit any of your personal or usage data</p>
  </div>
  <div class="highlight-box">
    <h3>🏠 100% Local</h3>
    <p>Everything runs on your Mac - no external servers or cloud services</p>
  </div>
  <div class="highlight-box">
    <h3>🔐 Your AWS, Your Control</h3>
    <p>Direct connection to AWS using your credentials - we never see them</p>
  </div>
</div>

## How AWSCostMonitor Works

### Local-Only Architecture

AWSCostMonitor operates entirely on your local machine:

- **No telemetry** - We don't track usage or collect analytics
- **No phone home** - The app never contacts our servers (we don't have any!)
- **No accounts** - No registration or sign-up required
- **No ads** - No advertising or tracking mechanisms

### AWS Credentials Management

Your AWS credentials are sacred to us:

- Read from your existing AWS CLI configuration (`~/.aws/config` and `~/.aws/credentials`)
- Never transmitted to us or any third party
- Used only for direct API calls from your Mac to AWS
- Managed by macOS's secure system configuration

### Data Flow

```
Your Mac → AWS Cost Explorer API
    ↓
Cost Data
    ↓
Display in Menu Bar
```

That's it. No detours through our servers. No middleman. Just direct, secure communication.

## Optional Team Cache Feature

If you choose to enable Team Cache:

- Data is stored in **your own AWS S3 bucket**
- You specify the bucket and control access
- Only team members with access to that bucket can share data
- We have no visibility into this data
- Everything stays within your AWS infrastructure

## What We Don't Do

- ❌ No user tracking
- ❌ No usage analytics
- ❌ No error reporting to us
- ❌ No crash analytics
- ❌ No behavioral data
- ❌ No marketing data
- ❌ No data selling
- ❌ No third-party sharing

## Data Storage

### On Your Mac
- User preferences: Stored in macOS UserDefaults
- Cache: Temporary cost data in memory only
- All data deleted when app is uninstalled

### Not in the Cloud
- We don't operate any servers
- We don't have a backend
- We can't access your data even if we wanted to

## Third-Party Services

### AWS Services
When you use AWSCostMonitor, you're connecting directly to AWS:
- Governed by [AWS Privacy Policy](https://aws.amazon.com/privacy/)
- Standard AWS API rate limits and costs apply
- AWS may log API calls per their policies

### Mac App Store (If Applicable)
If you download from the Mac App Store:
- Apple's standard terms apply
- In-app purchases processed by Apple
- We receive no personal information from transactions

## Security Measures

- ✅ HTTPS encryption for all AWS API calls
- ✅ macOS Keychain integration for credential security
- ✅ Sandboxed application (App Store version)
- ✅ No network listeners or servers
- ✅ Regular security updates

## Your Rights and Control

Since we don't collect data, you have complete control:

- **Access**: All your data is already on your machine
- **Deletion**: Uninstall the app to remove everything
- **Portability**: Your AWS data belongs to you
- **Correction**: Manage your preferences directly in the app
- **Opt-out**: Simply don't use features you don't want

## Open Source Transparency

AWSCostMonitor is open source. You can:
- Review our code: [GitHub Repository](https://github.com/toml0006/AWSCostMonitor)
- Verify our privacy claims
- Build it yourself from source
- Contribute improvements

## Children's Privacy

AWSCostMonitor is not intended for children under 13. We don't knowingly collect information from children.

## Policy Updates

We'll update this policy if our practices change:
- Check the "Last Updated" date
- Significant changes will be noted in release notes
- The latest version is always available here

## Contact Us

Questions about privacy? We're here to help:

- **GitHub Issues**: [Report an Issue](https://github.com/toml0006/AWSCostMonitor/issues)
- **Documentation**: [View Docs](https://toml0006.github.io/AWSCostMonitor/)

## Privacy Promise

We built AWSCostMonitor because we wanted a tool that respects privacy. That's why:

1. **No venture capital** = No pressure to monetize your data
2. **No data collection** = Nothing to leak or breach
3. **Open source** = Complete transparency
4. **Local only** = Your data never leaves your Mac

---

<div class="privacy-footer">
  <p><strong>Bottom Line:</strong> Your AWS cost data is yours alone. We can't see it, we don't want to see it, and we've built AWSCostMonitor to ensure it stays that way.</p>
</div>

<style>
.privacy-highlights {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin: 30px 0;
}

.highlight-box {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 20px;
  border-radius: 10px;
  text-align: center;
}

.highlight-box h3 {
  margin: 0 0 10px 0;
  font-size: 1.2em;
}

.highlight-box p {
  margin: 0;
  opacity: 0.95;
}

.privacy-footer {
  background: #f0f0f0;
  padding: 20px;
  border-radius: 10px;
  margin-top: 40px;
  text-align: center;
}

.dark .privacy-footer {
  background: #2a2a2a;
}
</style>