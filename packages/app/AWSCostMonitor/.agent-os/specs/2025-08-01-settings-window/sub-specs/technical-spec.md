# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-01-settings-window/spec.md

> Created: 2025-08-01
> Version: 1.0.0

## Technical Requirements

- Implement SwiftUI Settings scene in AWSCostMonitorApp.swift
- Create new SettingsView SwiftUI view with TabView for organization
- Add refresh interval property and timer mechanism to AWSManager
- Migrate existing display format controls to settings with enhanced preview
- Add "Settings..." menu item to ContentView with proper action handling
- Ensure settings window appears with standard macOS behavior (centered, proper size, etc.)
- Implement automatic refresh functionality based on user-configured interval
- Use @AppStorage property wrappers for settings persistence instead of direct UserDefaults calls

## Approach Options

**Option A:** Single monolithic settings view with all controls
- Pros: Simple implementation, everything in one place
- Cons: Poor user experience as settings grow, no organization

**Option B:** TabView-based settings with categorized sections (Selected)
- Pros: Better organization, scalable for future settings, native macOS feel
- Cons: Slightly more complex implementation

**Option C:** Navigation-based hierarchical settings
- Pros: Very scalable, allows deep nesting
- Cons: Overly complex for current needs, non-standard for macOS settings

**Rationale:** Option B provides the best balance of organization and simplicity. TabView is the standard approach for macOS settings windows and will scale well as more settings are added. The categorization (Display, Refresh, AWS) provides logical grouping that users expect.

## External Dependencies

No new external dependencies required. The implementation will use existing SwiftUI framework components and the current AWS SDK integration.

## Implementation Details

### Settings Scene Structure
```swift
Settings {
    SettingsView()
        .environmentObject(awsManager)
}
```

### Settings Organization
- **Display Tab**: Display format selection with live preview
- **Refresh Tab**: Automatic refresh interval configuration  
- **AWS Tab**: Profile selection and management

### Refresh Timer Implementation
- Add Timer.scheduledTimer to AWSManager
- Add refreshInterval property with @Published wrapper
- Add startAutomaticRefresh() and stopAutomaticRefresh() methods
- Default interval: 5 minutes, configurable from 1-60 minutes

### Settings Persistence
Replace direct UserDefaults calls with @AppStorage:
- `@AppStorage("MenuBarDisplayFormat") var displayFormat`
- `@AppStorage("RefreshIntervalMinutes") var refreshInterval` 
- `@AppStorage("SelectedAWSProfileName") var selectedProfileName`