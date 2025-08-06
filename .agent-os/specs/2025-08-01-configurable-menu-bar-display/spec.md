# Spec Requirements Document

> Spec: Configurable Menu Bar Display
> Created: 2025-08-01
> Status: Planning

## Overview

Implement configurable display options for the menu bar cost data, allowing users to choose between full format ($123.45), abbreviated format ($123), or icon-only display based on their preferences and available screen space.

## User Stories

### Flexible Display Preferences

As a macOS user with limited menu bar space, I want to configure how cost data appears in the menu bar, so that I can balance cost visibility with screen real estate.

**Detailed Workflow:**
1. User opens the settings/preferences window
2. User selects from display format options (full/abbreviated/icon-only)
3. User sees immediate preview of how their choice will appear
4. Settings are saved and menu bar updates to reflect the choice
5. Settings persist across app restarts

### Screen Space Optimization

As a user with many menu bar items, I want to minimize the space taken by the cost monitor, so that all my important menu bar tools remain visible.

**Detailed Workflow:**
1. User notices menu bar is crowded
2. User opens app preferences and selects "icon-only" mode
3. Menu bar now shows only the dollar sign icon
4. User can still access full cost data by clicking the icon

## Spec Scope

1. **Display Format Options** - Three distinct display modes: full currency format, abbreviated format, and icon-only
2. **Settings UI** - Preferences interface allowing users to select their preferred display format
3. **Live Preview** - Real-time preview in settings showing how each format appears
4. **Persistent Storage** - Save user preference and restore on app launch
5. **Menu Bar Updates** - Dynamically update menu bar display when settings change

## Out of Scope

- Custom formatting beyond the three predefined options
- Different display formats per AWS profile
- Animated transitions between display modes
- Font or color customization options

## Expected Deliverable

1. Settings window with radio buttons or picker for three display format options
2. Menu bar display updates in real-time based on selected format
3. User preferences persist across app restarts and maintain the selected display format