# Changelog

All notable changes to AWS Cost Monitor will be documented in this file.

## [1.3.2] - 2025-08-19

### 🎉 What's New

**Major visual refresh and team collaboration features!**

We've redesigned the app with professional new icons and added comprehensive team caching support to reduce API costs for organizations.

### ✨ Features Added

- **New Professional App Icons** - Complete redesign with modern, polished look
- **Team Remote Caching** - Share cost data across team using S3 to reduce API calls
- **Comprehensive Setup Guide** - Step-by-step instructions for team cache configuration
- **Enhanced Timer Reliability** - Fixed refresh timer using Timer.scheduledTimer

### 🐛 Bug Fixes

- Fixed refresh timer not firing properly
- Improved timer scheduling for consistent updates

### 🔧 Technical Improvements

- Updated to proper timer implementation with scheduledTimer
- Added comprehensive team cache documentation
- Improved S3 integration for team data sharing
- Enhanced error handling for cache operations

### 📝 Notes

The team cache feature is optional and maintains our privacy-first approach - it uses your existing AWS infrastructure with no third-party services involved.

---

## [1.1.0] - 2025-08-10

### 🎉 What's New

**Your app is now smarter about when to check AWS costs!**

We've added intelligent screen-aware refresh that automatically pauses cost updates when you're not looking. This means:

- 💰 **Lower API costs** - No more checking AWS when your screen is off or Mac is locked
- 🔋 **Better battery life** - The app takes a break when you do
- 🧠 **Smart caching** - Shows your last known costs instead of errors when offline

### ✨ Features Added

- **Screen-aware refresh** - Automatically pauses updates when your display sleeps or system locks
- **User activity detection** - Knows when you've stepped away from your desk
- **Intelligent cache management** - Uses cached data smartly when refresh is paused
- **Comprehensive test coverage** - Added 50+ new tests for reliability

### 🐛 Bug Fixes

- Fixed potential crashes during test execution
- Improved handling of private AppStorage properties in tests
- Better error handling when screen state changes

### 🔧 Technical Improvements

- Added `ScreenStateMonitor` class for system state detection
- Integrated screen state checks into refresh logic
- Enhanced test suite with UI and unit tests for all major features
- Improved refresh rate logic with budget-based intervals

### 📝 Notes

The screen-aware refresh is completely automatic - no configuration needed! Your app will just use less resources and save you money on AWS API calls. It's like having a thoughtful assistant who knows when you're actually at your desk.

---

## [1.0.0] - 2025-08-01

### 🚀 Initial Release

- Menu bar cost display with real-time MTD spending
- Multi-profile support with persistent selection
- Smart refresh intervals based on budget proximity
- Sandbox support for Mac App Store compliance
- ACME demo mode for testing
- Comprehensive logging and debugging tools
- Budget tracking and alerts
- Service cost breakdown
- Historical data tracking
- Anomaly detection
- Help documentation

---

*For more details, visit [awscostmonitor.app](https://awscostmonitor.app)*