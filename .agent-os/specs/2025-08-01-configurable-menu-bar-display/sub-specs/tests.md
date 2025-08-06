# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-08-01-configurable-menu-bar-display/spec.md

> Created: 2025-08-01
> Version: 1.0.0

## Test Coverage

### Unit Tests

**CostDisplayFormatter**
- Test full format with various cost values ($0.00, $1.23, $1234.56, $999999.99)
- Test abbreviated format rounds correctly ($1.23 → $1, $1234.56 → $1235)
- Test icon-only format returns empty string
- Test edge cases: negative values, nil values, very large numbers
- Test locale-specific formatting (currency symbols, decimal separators)

**MenuBarDisplayFormat Enum**
- Test enum raw values match expected strings
- Test CaseIterable provides all three cases
- Test enum initialization from string values

**UserDefaults Integration**
- Test default value when no preference is stored
- Test reading and writing display format preference
- Test invalid stored values fall back to default

### Integration Tests

**Settings Window Integration**
- Test picker selection updates UserDefaults immediately
- Test picker reflects current stored preference on window open
- Test preview labels update when picker selection changes
- Test settings window can be opened and closed without errors

**Menu Bar Display Integration**
- Test menu bar text updates when display format preference changes
- Test format changes apply to current cost data immediately
- Test app launch respects saved display format preference
- Test menu bar handles format changes during API loading states

**Full Workflow Tests**
- Test complete user workflow: open settings → change format → see menu bar update
- Test format persistence across app restart
- Test format changes work with different cost values and AWS profiles

### Mocking Requirements

- **UserDefaults:** Mock UserDefaults for isolated unit testing
- **Cost Data:** Mock cost values to test formatting with predictable inputs
- **Settings Window:** Mock settings interactions for testing format changes without UI automation