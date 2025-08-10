# AWSCostMonitor

<div align="center">
  <img src="logo-simple.svg" alt="AWSCostMonitor Logo" width="128" height="128">
  
  **Keep Your AWS Costs Under Control**
  
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
  [![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)](https://www.apple.com/macos/)
  [![Swift](https://img.shields.io/badge/Swift-5.0%2B-orange)](https://swift.org/)
  
  [Download](https://github.com/toml0006/AWSCostMonitor/releases) • [Documentation](https://toml0006.github.io/AWSCostMonitor/) • [Report Bug](https://github.com/toml0006/AWSCostMonitor/issues)
</div>

---

## 📖 About

AWSCostMonitor is a lightweight macOS menu bar application that provides real-time visibility into your AWS spending. Built by developers who got tired of AWS bill surprises, this tool helps you track multiple AWS accounts, get smart alerts, and prevent bill shock — all with zero setup complexity and complete privacy.

🌐 **Visit our website**: [https://toml0006.github.io/AWSCostMonitor/](https://toml0006.github.io/AWSCostMonitor/)

## 🚀 Overview

Monitor your AWS costs in real-time directly from your macOS menu bar. No subscriptions, no cloud services, no tracking — just a simple, effective tool that respects your privacy while keeping your AWS costs under control.

### ✨ Key Features

- 👁️ **Always Visible** - Lives in your menu bar for instant cost visibility
- 👥 **Multi-Profile Support** - Switch between multiple AWS accounts effortlessly
- 📊 **Smart Trends** - Color-coded indicators show spending patterns
- 🔔 **Budget Alerts** - Get notified before exceeding limits
- ⚡ **Intelligent Refresh** - Adjusts polling based on spending patterns
- 🔒 **100% Private** - All data stays local, no telemetry
- ✅ **Signed & Sandboxed** - Developer ID signed and fully sandboxed for security

## 📁 Repository Structure

This is a monorepo containing:

```
awscostmonitor/
├── packages/
│   ├── app/          # macOS application (Swift/SwiftUI)
│   └── website/      # Marketing website (React/Vite)
├── README.md
└── package.json
```

## 🛠️ Development

### Prerequisites

- **macOS**: 13.0 or later
- **Xcode**: 15.0 or later
- **Node.js**: 18.0 or later
- **AWS CLI**: Configured with profiles

### Setup

1. Clone the repository:
```bash
git clone https://github.com/toml0006/AWSCostMonitor.git
cd AWSCostMonitor
```

2. Install dependencies:
```bash
npm install
```

### Building the macOS App

```bash
npm run build:app
```

Or using Xcode:
1. Open `packages/app/AWSCostMonitor/AWSCostMonitor.xcodeproj`
2. Build and run (⌘+R)

### Running the Website

```bash
npm run dev:website
```

Visit `http://localhost:5173` to see the marketing site.

## 📦 Installation

### Download Pre-built App

1. Download the latest release from [Releases](https://github.com/toml0006/AWSCostMonitor/releases)
2. Unzip and drag `AWSCostMonitor.app` to your Applications folder
3. Launch from Applications or Spotlight

✅ **The app is fully signed and sandboxed** - It will open without any security warnings on macOS 13.0 and later.

### Build from Source

```bash
git clone https://github.com/toml0006/AWSCostMonitor.git
cd AWSCostMonitor
npm run build:app
```

## 🔧 Configuration

AWSCostMonitor uses your existing AWS CLI configuration from `~/.aws/config`. Ensure you have:

1. AWS CLI installed and configured
2. At least one profile with Cost Explorer read permissions
3. The following IAM permissions:
   - `ce:GetCostAndUsage`
   - `ce:GetCostForecast`

## 🔐 Security

AWSCostMonitor is built with security and privacy as top priorities:

- **✅ Code Signed** - Signed with Apple Developer ID for authenticity
- **🔒 Sandboxed** - Runs in a secure sandbox with limited system access
- **🏠 Local Only** - All data stays on your Mac, no external servers
- **🚫 No Tracking** - Zero telemetry, analytics, or data collection
- **📖 Open Source** - Full source code available for inspection
- **🔑 Your Credentials** - Uses existing AWS CLI credentials, never stores or transmits them

## 💖 Support

If AWSCostMonitor saves you money on your AWS bills, consider supporting the project:

- ⭐ **Star this repository** - Help others discover the tool
- ☕ **[Buy Me a Coffee](https://buymeacoffee.com/jacksontomlinson)** - Help me pay my own AWS bills while building tools to help you pay yours!
- 🔗 **Share on LinkedIn** - Spread the word to your network
- 🐛 **Report bugs** - Help improve the tool for everyone

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Swift](https://swift.org/) and [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Marketing site built with [React](https://react.dev/) and [Vite](https://vitejs.dev/)
- Icons from [Lucide](https://lucide.dev/)

## ⚠️ Disclaimer

This project is not affiliated with, endorsed by, or sponsored by Amazon Web Services (AWS) or Amazon.com, Inc.

---

<div align="center">
  Made with ❤️ for developers who care about their AWS bills
</div>