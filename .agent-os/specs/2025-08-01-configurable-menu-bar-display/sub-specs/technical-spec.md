# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-01-configurable-menu-bar-display/spec.md

> Created: 2025-08-01
> Version: 1.0.0

## Technical Requirements

- **Display Format Enum**: Create enumeration for three display modes (full, abbreviated, iconOnly)
- **Settings Window**: SwiftUI Settings scene with picker/radio buttons for format selection
- **UserDefaults Integration**: Store display format preference with appropriate key
- **Menu Bar Update Logic**: Dynamic text updating based on current format and cost data
- **Format Processing**: Logic to convert cost values into appropriate display strings
- **Real-time Preview**: Live preview in settings window showing format examples

## Approach Options

**Option A: Computed Property Approach**
- Pros: Simple implementation, automatic updates when data changes
- Cons: Format logic scattered across view code

**Option B: Dedicated Formatter Service** (Selected)
- Pros: Centralized formatting logic, easier testing, reusable across views
- Cons: Slightly more complex architecture

**Option C: View Modifier Approach**
- Pros: SwiftUI-native pattern, composable
- Cons: Less flexible for complex formatting rules

**Rationale:** Option B provides the best balance of maintainability and testability. A dedicated formatter service keeps all display logic in one place and can be easily unit tested.

## External Dependencies

No new external dependencies required. Implementation will use existing SwiftUI and Foundation frameworks.

## Implementation Details

### Display Format Enum
```swift
enum MenuBarDisplayFormat: String, CaseIterable {
    case full = "full"
    case abbreviated = "abbreviated" 
    case iconOnly = "iconOnly"
}
```

### Formatter Service
- `CostDisplayFormatter` class with methods for each format type
- Input: cost value (Double), format preference (MenuBarDisplayFormat)
- Output: formatted string for menu bar display

### Settings Integration
- Add display format picker to existing or new settings window
- Bind picker to UserDefaults using @AppStorage property wrapper
- Include preview labels showing example formatted costs

### Menu Bar Updates
- Observe display format changes via UserDefaults
- Update menu bar text through existing cost display logic
- Handle edge cases (zero costs, API errors) for each format