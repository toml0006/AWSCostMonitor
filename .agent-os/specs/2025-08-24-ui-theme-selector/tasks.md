# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-08-24-ui-theme-selector/spec.md

> Created: 2025-08-24
> Status: Ready for Implementation

## Tasks

- [ ] 1. Create Theme Infrastructure and Data Models
  - [ ] 1.1 Write tests for Theme protocol and struct definitions
  - [ ] 1.2 Create Theme protocol with color, text, and layout properties
  - [ ] 1.3 Implement 7 pre-defined theme structs (Classic, Modern, High Contrast, Compact, Comfortable, Terminal, Professional)
  - [ ] 1.4 Create ThemeManager singleton with @Published properties
  - [ ] 1.5 Implement theme persistence using UserDefaults
  - [ ] 1.6 Add system appearance monitoring for light/dark mode sync
  - [ ] 1.7 Verify all tests pass for theme infrastructure

- [ ] 2. Build Theme Settings UI
  - [ ] 2.1 Write tests for theme selection UI components
  - [ ] 2.2 Add "Appearance" tab to existing Settings window
  - [ ] 2.3 Create theme preview cards showing actual UI components
  - [ ] 2.4 Implement theme grid selector with hover effects
  - [ ] 2.5 Add "Sync with System Appearance" toggle switch
  - [ ] 2.6 Connect UI to ThemeManager for live preview updates
  - [ ] 2.7 Verify all tests pass for settings UI

- [ ] 3. Apply Themes to Menu Bar Components
  - [ ] 3.1 Write tests for themed menu bar display
  - [ ] 3.2 Create theme-aware color extensions for menu bar
  - [ ] 3.3 Update menu bar cost display to use theme colors
  - [ ] 3.4 Apply theme text formatting to menu bar text
  - [ ] 3.5 Implement theme-based layout density for menu bar
  - [ ] 3.6 Verify all tests pass for menu bar theming

- [ ] 4. Apply Themes to Dropdown Menu and Popovers
  - [ ] 4.1 Write tests for themed dropdown components
  - [ ] 4.2 Update PopoverContentView to use theme colors
  - [ ] 4.3 Apply theme text formatting to menu items
  - [ ] 4.4 Implement theme-based spacing in dropdown menus
  - [ ] 4.5 Update all menu buttons and controls with theme colors
  - [ ] 4.6 Verify all tests pass for dropdown theming

- [ ] 5. Apply Themes to Calendar View and Visualizations
  - [ ] 5.1 Write tests for themed calendar and chart components
  - [ ] 5.2 Update CalendarView to use theme colors for day cells
  - [ ] 5.3 Apply themes to donut charts and histograms
  - [ ] 5.4 Update DayDetailView with theme colors and formatting
  - [ ] 5.5 Ensure chart readability across all theme variations
  - [ ] 5.6 Test theme transitions and persistence across view changes
  - [ ] 5.7 Verify all tests pass for visualization theming