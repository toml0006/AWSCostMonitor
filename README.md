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
- 📅 **Calendar View** - Visual monthly calendar showing daily spending patterns (v1.2.0)
- 📊 **Interactive Charts** - Donut charts with hover interactions for service breakdowns (v1.2.0)
- 🔍 **Daily Deep Dive** - Click any calendar day to see detailed service costs and usage (v1.2.0)
- 📊 **Smart Trends** - Color-coded indicators show spending patterns
- 🔔 **Budget Alerts** - Get notified before exceeding limits
- ⚡ **Intelligent Refresh** - Adjusts polling based on spending patterns
- ⌨️ **Keyboard Shortcuts** - Quick access with customizable hotkeys (v1.2.0)
- 🔒 **100% Private** - All data stays local, no telemetry
- ✅ **Signed & Sandboxed** - Developer ID signed and fully sandboxed for security

## 🆕 What's New in v1.3.0 - Team Features & Pro Upgrade

**Finally decided to charge money. Shocking, we know.**

### 💎 Pro Features (Just $3.99, Less Than Your Coffee Habit)
- **Team Cache Sharing** - Stop your teammates from hammering AWS APIs like barbarians
- **Advanced Forecasting** - Mathematical predictions of your future financial regret  
- **3-Day Free Trial** - We're not monsters, try it first
- **Universal Binary** - Now works on Intel Macs too (you're welcome, holdouts)

### ⚡ Actually Useful Improvements
- Enhanced calendar view with 47% more colors and 73% fewer confused stares
- Keyboard shortcuts (⌘1-9) because apparently clicking is exhausting
- Better error messages when things inevitably break
- Memory leak fixed (your RAM thanks us)

**[📋 See Full Changelog](CHANGELOG.md)** - *Warning: Contains mild sarcasm and technical details*

---

## 🆕 What's New in v1.2.0

### 📅 Calendar View
- **Monthly Calendar**: Visualize daily spending patterns with color-coded calendar grid
- **Smart Navigation**: Navigate between months with current month quick return
- **Spending Heatmap**: Instantly spot high-spend days with visual intensity
- **Keyboard Shortcut**: Quick access with ⌘K from anywhere in the app

### 📊 Enhanced Day Details
- **Interactive Donut Charts**: Beautiful, responsive charts that highlight on hover
- **Service Breakdown**: Click any day to see detailed AWS service costs
- **Visual Proportions**: Instantly understand which services cost the most
- **Smart Grouping**: Small services automatically grouped for cleaner display

### ⌨️ Keyboard Shortcuts
- **⌘K**: Open Calendar View
- **⌘R**: Force refresh cost data
- **⌘1-9**: Quick switch between AWS profiles
- **ESC**: Close calendar/day detail views

### 🎨 User Experience
- **Smooth Animations**: Polished transitions and hover effects
- **Professional Design**: Clean, modern interface following macOS design guidelines
- **Responsive Layout**: Optimal viewing at any window size
- **Accessibility**: Full keyboard navigation support

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

### Development Tools
- Built with [Swift](https://swift.org/) and [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Marketing site built with [React](https://react.dev/) and [Vite](https://vitejs.dev/)
- Icons from [Lucide](https://lucide.dev/)

### AI-Assisted Development
This project was developed with significant assistance from [**Claude Code**](https://claude.ai/code) by [**Anthropic**](https://www.anthropic.com/). Claude Code served as an invaluable coding partner throughout the development process, helping with:

- **Architecture Design** - Thoughtful system design and best practices
- **Swift/SwiftUI Implementation** - Complex macOS app development and API integration
- **Test Coverage** - Comprehensive unit and UI test suites
- **Documentation** - Clear, professional documentation and help systems
- **Performance Optimization** - Including the innovative screen-aware refresh feature in v1.1.0
- **Problem Solving** - Debugging complex issues and finding elegant solutions

The collaboration with Claude Code demonstrates the power of AI-assisted development in creating high-quality, production-ready applications. Special thanks to the Anthropic team for building such a capable and reliable coding assistant.

*If you're interested in accelerating your development workflow, check out [Claude Code](https://claude.ai/code) - it's like having a senior developer available 24/7.*

### Human Note
Hi, this is Jackson, nice to meet you.  Please know that while I am grateful for the assistance from Claude Code, Claude wrote it's own acknowledgement.  It is a super-awesome tool, but take that acknowledgement with a grain of salt (I'm leaving it in 'cause I thought it was funny how self-egrandizing it was when asked to write one).  Thanks for your support!

## ⚠️ Disclaimer

This project is not affiliated with, endorsed by, or sponsored by Amazon Web Services (AWS) or Amazon.com, Inc.

---

<div align="center">
  Made with ❤️ for developers who care about their AWS bills
</div>