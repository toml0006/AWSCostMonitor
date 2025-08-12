# AWSCostMonitor - Open Source & App Store Versions

AWSCostMonitor is a macOS menu bar application for monitoring AWS costs in real-time. This repository contains both the open source version and the premium App Store version in a single codebase.

## 🆓 Open Source Version (This Build)

The open source version provides core AWS cost monitoring functionality:

- ✅ **Real-time cost monitoring** - Month-to-date spending in your menu bar
- ✅ **Multiple AWS profiles** - Unlimited profile support
- ✅ **Calendar view** - Visual daily spending breakdown
- ✅ **Smart refresh** - Intelligent API rate limiting
- ✅ **Cost forecasting** - Basic month-end projections
- ✅ **Privacy-first** - All data stays local, no telemetry

## 💎 App Store Pro Version

The App Store version includes additional team collaboration features:

- ✅ **All open source features**
- 🔒 **Team Cache** - Share cost data across your team via S3
- 🔒 **Advanced Forecasting** - Enhanced cost predictions and analytics
- 🔒 **Data Export** - Export cost data to CSV/JSON
- 🔒 **Priority Support** - Faster response to issues

**Pricing:** $3.99 one-time purchase • 3-day free trial • No subscription

## 🏗️ Architecture

This project uses conditional compilation to maintain a single codebase:

- **Open Source builds** use `PREMIUM_FEATURES=0 APPSTORE_BUILD=0`
- **App Store builds** use `PREMIUM_FEATURES=1 APPSTORE_BUILD=1`

All premium features are clearly marked and gracefully degrade in open source builds.

## 🚀 Getting Started

### Prerequisites
- macOS 13.0 or later
- Xcode 15.0 or later
- AWS credentials configured (`~/.aws/config`)

### Building from Source
1. Clone this repository
2. Open `AWSCostMonitor.xcodeproj` in Xcode
3. Build and run with the default scheme

The default build configuration compiles the open source version with premium features disabled.

### Configuration
1. Set up your AWS credentials in `~/.aws/config`
2. Ensure your IAM user has `cost-explorer:GetCostAndUsage` permissions
3. Run the app and select your AWS profile

## 🔧 Development

### Project Structure
```
AWSCostMonitor/
├── Core/                 # Core functionality (shared)
├── Views/               # UI components
├── Models/              # Data models
├── Managers/            # Business logic
├── Services/            # AWS integration
└── Premium/             # Premium-only features (conditional)
```

### Build Configurations
- **Debug/Release**: Open source builds
- **App Store Debug/Release**: Premium builds with StoreKit

See `setup-build-configs.md` for detailed Xcode configuration instructions.

## 🤝 Contributing

Contributions are welcome! Please feel free to:

- 🐛 Report bugs and issues
- 💡 Suggest new features
- 🔧 Submit pull requests
- 📖 Improve documentation

## 📱 Download App Store Version

If you'd like to support development and get premium features:

[**Download from App Store →**](https://apps.apple.com/app/awscostmonitor/id123456789)

- 3-day free trial of all Pro features
- One-time $3.99 purchase
- Same privacy-first approach
- Supports ongoing development

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

The same codebase powers both the open source and commercial versions, ensuring transparency and allowing you to verify exactly what the App Store version does.

## 🙏 Support

- **Open Source**: [GitHub Issues](https://github.com/yourusername/awscostmonitor/issues)
- **App Store Version**: Email support included with purchase

---

**Built with ❤️ using Swift and SwiftUI**

*This project demonstrates how to build sustainable open source software with a transparent commercial model.*