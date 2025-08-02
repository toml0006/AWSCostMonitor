# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-08-01-settings-window/spec.md

> Created: 2025-08-02
> Status: Ready for Implementation

## Tasks

- [x] 1. Implement SwiftUI Settings Scene
  - [x] 1.1 Write tests for Settings scene integration and window behavior
  - [x] 1.2 Add Settings scene to AWSCostMonitorApp.swift with proper environment objects
  - [x] 1.3 Verify Settings window opens with ⌘, keyboard shortcut
  - [x] 1.4 Verify all tests pass

- [x] 2. Create SettingsView with TabView Organization
  - [x] 2.1 Write tests for SettingsView tabs and layout
  - [x] 2.2 Create new SettingsView.swift file with TabView structure
  - [x] 2.3 Implement Display, Refresh, and AWS tabs with placeholder content
  - [x] 2.4 Verify all tests pass

- [x] 3. Migrate Display Format Settings to Settings Window
  - [x] 3.1 Write tests for display format settings persistence with @AppStorage
  - [x] 3.2 Replace UserDefaults calls with @AppStorage property wrappers
  - [x] 3.3 Implement Display tab with format selection and live preview
  - [x] 3.4 Remove display format controls from ContentView menu
  - [x] 3.5 Verify all tests pass

- [x] 4. Implement Automatic Refresh Functionality
  - [x] 4.1 Write tests for refresh timer functionality and interval management
  - [x] 4.2 Add refreshInterval property and timer management to AWSManager
  - [x] 4.3 Implement Refresh tab with interval configuration controls
  - [x] 4.4 Add automatic refresh timer that calls fetchCostForSelectedProfile()
  - [x] 4.5 Verify all tests pass

- [x] 5. Add Settings Menu Integration
  - [x] 5.1 Write tests for "Settings..." menu item and navigation
  - [x] 5.2 Add "Settings..." menu item to ContentView
  - [x] 5.3 Implement Settings window opening from menu bar popup
  - [x] 5.4 Verify Settings window opens correctly from menu action
  - [x] 5.5 Verify all tests pass