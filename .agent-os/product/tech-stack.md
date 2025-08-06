# Technical Stack

> Last Updated: 2025-08-02
> Version: 1.0.0

## Core Technologies

### Application Framework
- **Framework:** SwiftUI
- **Version:** 5.0+
- **Language:** Swift 5.0+
- **Platform:** macOS

### Development Environment
- **IDE:** Xcode
- **Build System:** Xcode Build System
- **Target Platform:** macOS 13.0+

## Dependencies

### AWS SDK
- **Library:** AWS SDK for Swift
- **Modules Used:**
  - AWSCostExplorer
  - AWSClientRuntime
  - AWSSTS
- **Version:** Latest stable

### Native Frameworks
- **SwiftUI:** UI framework for menu bar app
- **Foundation:** Core Swift functionality
- **AppKit:** macOS-specific functionality (NSApplication)

## Architecture

### Design Pattern
- **Pattern:** MVVM (Model-View-ViewModel)
- **State Management:** SwiftUI @StateObject and @Published

### Data Storage
- **Preferences:** UserDefaults
- **Configuration:** AWS config file (~/.aws/config)
- **Persistence:** Local file system only

## UI/UX

### Interface Type
- **Type:** Menu Bar Extra
- **Design System:** macOS native
- **Icons:** SF Symbols (system icons)

## Testing

### Test Frameworks
- **Unit Tests:** XCTest
- **UI Tests:** XCUITest

## Infrastructure

### Application Distribution
- **Platform:** Direct download / GitHub releases
- **Format:** .app bundle
- **Code Signing:** Developer ID (planned)

### Version Control
- **System:** Git
- **Hosting:** GitHub
- **Branching Strategy:** Git Flow

## Build & Deployment

### Build Configuration
- **Debug:** Development builds with logging
- **Release:** Optimized production builds
- **Architecture:** Universal (Apple Silicon + Intel)

### CI/CD Pipeline
- **Platform:** GitHub Actions (planned)
- **Automated Tests:** On PR and push to main
- **Release Process:** Tagged releases with artifacts

## Security

### API Authentication
- **Method:** AWS IAM credentials
- **Storage:** System AWS config file
- **Access:** Read-only Cost Explorer permissions

### Data Handling
- **Encryption:** None (no sensitive data stored)
- **Network:** HTTPS only for AWS API calls
- **Privacy:** No telemetry or external services

## Code Repository URL
- **URL:** To be determined (GitHub repository)