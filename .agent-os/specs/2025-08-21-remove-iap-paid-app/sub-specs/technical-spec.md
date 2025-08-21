# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-21-remove-iap-paid-app/spec.md

> Created: 2025-08-21
> Version: 1.0.0

## Technical Requirements

### Code Removal Requirements

**IAP Infrastructure Elimination:**
- Remove StoreKit framework imports and dependencies
- Delete IAP product configuration and validation code
- Remove App Store Connect IAP product definitions
- Eliminate purchase flow UI components and logic

**Trial System Removal:**
- Delete trial period tracking (14-day countdown)
- Remove trial expiration checks and notifications
- Eliminate trial reminder scheduling (day 7, 10, 13)
- Delete trial status persistence in UserDefaults

**License Validation Removal:**
- Remove cryptographic license key validation
- Delete Keychain integration for license storage
- Eliminate license transfer and offline validation logic
- Remove license-related API endpoints or external service calls

**Feature Gating Removal:**
- Delete all conditional feature access based on purchase status
- Remove upgrade prompts and purchase flow buttons
- Eliminate feature limitation UI indicators
- Delete purchase status checking throughout the application

### Entitlements and Configuration

**Xcode Project Changes:**
- Remove In-App Purchase capability from entitlements
- Update App Store Connect configuration to paid app model
- Remove IAP-related build configurations and schemes
- Clean up any IAP-specific build flags or preprocessor definitions

**App Store Connect Configuration:**
- Transition app from freemium to paid model
- Remove existing IAP products from App Store Connect
- Update app description to reflect full feature access
- Set appropriate paid app price point

### Feature Unification Implementation

**Multi-Profile Access:**
- Remove profile count limitations previously tied to Pro tier
- Enable unlimited AWS profile switching for all users
- Remove profile upgrade prompts and restrictions

**Advanced Features Access:**
- Enable smart refresh and budget features for all users
- Unlock cost forecasting, trends, and analytics
- Make service breakdown and export functionality universal
- Enable all keyboard shortcuts without restrictions

## Approach

### Phase 1: Code Audit and Mapping
1. **Identify IAP Touchpoints**: Comprehensive audit of all IAP-related code across the codebase
2. **Map Feature Gating**: Document all locations where features are conditionally enabled
3. **Dependency Analysis**: Identify external frameworks and services that can be removed

### Phase 2: Systematic Removal
1. **StoreKit Elimination**: Remove all StoreKit imports, delegates, and purchase logic
2. **Trial Logic Removal**: Delete trial tracking, expiration checks, and notifications
3. **License System Cleanup**: Remove cryptographic validation and Keychain integration
4. **Feature Gate Removal**: Enable all features unconditionally

### Phase 3: Configuration Updates
1. **Entitlements Cleanup**: Remove IAP capabilities from Xcode project
2. **Build Configuration**: Clean up IAP-related build settings and flags
3. **App Store Connect**: Transition to paid app model and remove IAP products

### Phase 4: Testing and Validation
1. **Feature Access Testing**: Verify all previously Pro features work for all users
2. **UI Cleanup Validation**: Ensure no upgrade prompts or purchase flows remain
3. **Build Testing**: Validate clean builds without IAP dependencies

## External Dependencies

### Dependencies to Remove
- **StoreKit Framework**: Apple's In-App Purchase framework
- **Keychain Services**: For license storage (if currently implemented)
- **License Validation Library**: Any third-party cryptographic validation
- **Payment Processor Integration**: Paddle/Gumroad/LemonSqueezy (if implemented)

### Dependencies to Retain
- **Core AWS SDK**: Maintains all current AWS Cost Explorer functionality
- **SwiftUI/AppKit**: UI framework dependencies remain unchanged
- **UserDefaults**: Still needed for user preferences (minus purchase status)
- **Foundation**: Core Swift functionality remains required

### New Dependencies
- **None Required**: This change removes complexity rather than adding it

## Migration Strategy

### User Data Preservation
- **Settings Migration**: Preserve all user preferences and configurations
- **Profile Data**: Maintain AWS profile configurations and selections
- **Cache Data**: Retain cost data cache and historical information

### Backward Compatibility
- **Settings Cleanup**: Remove purchase-related keys from UserDefaults
- **Feature Enablement**: Automatically enable all features for existing users
- **Data Integrity**: Ensure no data loss during monetization model transition

## Testing Requirements

### Unit Testing Updates
- **Remove IAP Tests**: Delete all purchase flow and license validation tests
- **Update Feature Tests**: Modify tests that previously checked for Pro tier access
- **Add Universal Access Tests**: Ensure all features are accessible without conditions

### Integration Testing
- **End-to-End Feature Access**: Test complete workflows for all previously Pro features
- **UI Flow Testing**: Verify no purchase prompts appear in user workflows
- **Profile Management**: Test unlimited profile switching functionality

### App Store Testing
- **Paid App Validation**: Test App Store purchase and download flow
- **Clean Installation**: Verify new users get full feature access immediately
- **Update Testing**: Ensure existing users maintain functionality after update