# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-08-01-settings-window/spec.md

> Created: 2025-08-01
> Version: 1.0.0

## Test Coverage

### Unit Tests

**AWSManager Refresh Timer**
- Test refreshInterval property changes update timer
- Test startAutomaticRefresh() creates and starts timer correctly
- Test stopAutomaticRefresh() properly invalidates timer
- Test timer fires at correct intervals and calls fetchCostForSelectedProfile()
- Test timer is recreated when interval changes

**Settings Persistence**
- Test @AppStorage properties save and load correctly
- Test migration from old UserDefaults keys to new @AppStorage keys
- Test default values are applied when no stored settings exist

### Integration Tests

**Settings Window Integration**
- Test Settings scene appears when ⌘, is pressed
- Test Settings window has correct size and positioning
- Test Settings window can be opened and closed properly
- Test multiple tabs display correct content

**Menu Bar Integration**
- Test "Settings..." menu item appears in menu bar popup
- Test "Settings..." menu item opens Settings window
- Test settings changes reflect immediately in menu bar display

### UI Tests

**Settings Interface**
- Test all tabs are accessible and display correct content
- Test display format changes show live preview
- Test refresh interval slider or picker works correctly
- Test AWS profile selection works in settings
- Test settings window respects macOS accessibility guidelines

**User Workflow Tests**
- Test complete user flow: open settings → change display format → verify menu bar updates
- Test complete user flow: change refresh interval → verify automatic refresh works
- Test settings persist across app restarts

### Mocking Requirements

- **Timer:** Mock Timer.scheduledTimer for testing refresh intervals without waiting
- **UserDefaults:** Mock UserDefaults for testing settings persistence
- **AWS API calls:** Use existing AWS manager mocking patterns for refresh testing