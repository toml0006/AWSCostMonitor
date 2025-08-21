# Privacy & Telemetry Policy

## Overview

AWSCostMonitor is committed to complete user privacy. This document explains our privacy practices and how we've implemented comprehensive telemetry opt-out measures.

## 🔒 Our Privacy Commitment

- **Zero Data Collection**: AWSCostMonitor itself collects no user data
- **Local-Only Storage**: All data stays on your Mac
- **No External Services**: No data is sent to any third-party services
- **Transparent Implementation**: Full source code available for inspection

## 🚫 AWS SDK Telemetry Opt-Out

### The Challenge

The AWS SDK for Swift includes OpenTelemetry instrumentation that could potentially collect:
- API call metrics (response times, success/failure rates)
- Request/response data (endpoints called, error codes)
- Performance data (latency, throughput)
- Usage patterns (which AWS services you use, how often)
- Error information (failed requests, retry attempts)

### Our Solution

We've implemented **comprehensive telemetry opt-out measures** at multiple levels:

#### 1. Environment Variables (Primary Method)
Set at app startup to disable all AWS SDK telemetry collection:

```bash
AWS_SDK_TELEMETRY_ENABLED=false
AWS_SDK_METRICS_ENABLED=false
AWS_SDK_TRACING_ENABLED=false
AWS_TELEMETRY_ENABLED=false
```

#### 2. Application-Level Configuration
- **App Initialization**: Environment variables set in `AWSCostMonitorApp.swift`
- **AWS Manager**: Additional telemetry opt-out in `AWSManager.swift`
- **S3 Cache Service**: Explicit telemetry configuration in `S3CacheService.swift`

#### 3. Logging & Transparency
All telemetry opt-out actions are logged for verification:
```swift
let logger = Logger(subsystem: "com.middleout.AWSCostMonitor", category: "App")
logger.info("AWS SDK telemetry collection disabled for privacy")
```

## 📋 What This Protects Against

### ✅ Protected Data
- **AWS Cost Data**: Your spending information stays completely private
- **Usage Patterns**: No data about how you use the app
- **Performance Metrics**: No response time or error rate collection
- **Request Details**: No API endpoint or parameter analysis
- **User Behavior**: No tracking of app usage patterns

### 🚫 What AWS Could Collect (But Doesn't)
- **Service Usage**: Which AWS services you access
- **API Patterns**: How often you make requests
- **Error Rates**: Success/failure of API calls
- **Performance**: Response times and latency
- **Usage Trends**: Patterns in your AWS consumption

## 🔧 Technical Implementation Details

### Code Locations

1. **`AWSCostMonitorApp.swift`** (Lines ~25-30)
   - Sets environment variables at app startup
   - Ensures telemetry is disabled before any AWS SDK initialization

2. **`AWSManager.swift`** (Lines ~25-35)
   - Additional telemetry opt-out in AWS manager initialization
   - Logs telemetry opt-out for transparency

3. **`S3CacheService.swift`** (Lines ~50-60)
   - Explicit telemetry configuration for S3 operations
   - Ensures team cache functionality doesn't enable telemetry

### Verification

You can verify telemetry opt-out by:

1. **Checking App Logs**: Look for "AWS SDK telemetry collection disabled for privacy"
2. **Environment Variables**: Verify variables are set to "false"
3. **Network Monitoring**: Confirm no telemetry data is sent to AWS
4. **Source Code Review**: All telemetry opt-out code is open source

## 🌐 AWS SDK Dependencies

### Why OpenTelemetry is Included
The AWS SDK for Swift includes OpenTelemetry as a transitive dependency:
```
Your App → AWSClientRuntime → smithy-swift → opentelemetry-swift
```

### What This Means
- **No Direct Usage**: We don't use OpenTelemetry features
- **Automatic Disabling**: All telemetry is disabled via environment variables
- **No Impact**: AWS SDK functionality works normally without telemetry

## 📱 Platform Considerations

### macOS Sandboxing
- **Environment Variables**: Properly set within sandbox constraints
- **File Access**: No telemetry data files are created
- **Network Access**: Only AWS API calls, no telemetry endpoints

### System Integration
- **Launch Services**: Telemetry opt-out persists across app launches
- **Background Processes**: All background operations respect telemetry settings
- **User Preferences**: Telemetry settings are not user-configurable (always disabled)

## 🔍 Privacy Verification

### How to Verify
1. **Monitor Network Traffic**: Use Network Link Conditioner or similar tools
2. **Check System Logs**: Look for telemetry-related entries
3. **Review Source Code**: All telemetry opt-out code is visible
4. **Test Functionality**: Verify AWS operations work without telemetry

### What to Look For
- ✅ No connections to telemetry endpoints
- ✅ No telemetry data files created
- ✅ No performance metrics sent to AWS
- ✅ Normal AWS API functionality maintained

## 📞 Privacy Support

If you have privacy concerns or questions:

1. **Review Source Code**: All implementation is open source
2. **Check Logs**: Telemetry opt-out is logged for transparency
3. **Report Issues**: Open GitHub issues for privacy-related concerns
4. **Contact Maintainers**: Reach out for privacy clarifications

## 🔄 Updates & Maintenance

### Ongoing Commitment
- **Code Reviews**: All telemetry-related changes are reviewed
- **Testing**: Telemetry opt-out is verified with each release
- **Documentation**: This document is updated with any changes
- **Transparency**: All privacy measures are documented

### Version History
- **v1.3.2**: Initial telemetry opt-out implementation
- **Future**: Continued privacy enhancements as needed

---

**Last Updated**: December 2024  
**Version**: 1.3.2  
**Status**: Active Implementation
