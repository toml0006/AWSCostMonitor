# Release v1.3.2 - Team Collaboration & Visual Refresh

## 🎉 What's New

**Major visual refresh and team collaboration features!**

We've redesigned the app with professional new icons and added comprehensive team caching support to reduce API costs for organizations.

## ✨ Features Added

- **Team Remote Caching** - Share cost data across your team using S3 to dramatically reduce API calls
- **New Professional App Icons** - Complete redesign with modern, polished look
- **Comprehensive Setup Guide** - Step-by-step instructions for team cache configuration
- **Enhanced Timer Reliability** - Fixed refresh timer using Timer.scheduledTimer

## 🐛 Bug Fixes

- Fixed refresh timer not firing properly
- Improved timer scheduling for consistent updates

## 🔧 Technical Improvements

- Updated to proper timer implementation with scheduledTimer
- Added comprehensive team cache documentation
- Improved S3 integration for team data sharing
- Enhanced error handling for cache operations

## 📝 Notes

The team cache feature is optional and maintains our privacy-first approach - it uses your existing AWS infrastructure with no third-party services involved.

## 📦 Download

Download the latest release for macOS below. The app requires macOS 13.0 or later.

---

*For more details, visit [awscostmonitor.app](https://awscostmonitor.app)*

## Instructions to Create GitHub Release

1. Go to https://github.com/toml0006/AWSCostMonitor/releases/new
2. Select the `v1.3.2` tag
3. Title: `v1.3.2 - Team Collaboration & Visual Refresh`
4. Copy the release notes above into the description
5. Upload the built app binary
6. Check "Set as the latest release"
7. Click "Publish release"