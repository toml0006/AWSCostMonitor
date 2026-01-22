//
//  Theme.swift
//  AWSCostMonitor
//
//  Theme system for customizable UI appearance
//

import Foundation
import SwiftUI

// MARK: - Menu Bar Background Style

enum MenuBarBackgroundStyle {
    case none
    case pill
}

// MARK: - Theme Protocol

protocol Theme {
    // Metadata
    var name: String { get }
    var description: String { get }
    var identifier: String { get }
    
    // Colors
    var primaryColor: Color { get }
    var secondaryColor: Color { get }
    var accentColor: Color { get }
    var backgroundColor: Color { get }
    var textColor: Color { get }
    var errorColor: Color { get }
    var warningColor: Color { get }
    var successColor: Color { get }
    
    // Text Formatting
    var smallFontSize: CGFloat { get }
    var regularFontSize: CGFloat { get }
    var largeFontSize: CGFloat { get }
    var primaryFontWeight: Font.Weight { get }
    var secondaryFontWeight: Font.Weight { get }
    
    // Layout Density
    var paddingScale: CGFloat { get }
    var spacingMultiplier: CGFloat { get }

    // Menu Bar Background Styling
    var menuBarBackgroundStyle: MenuBarBackgroundStyle { get }
    var menuBarBackgroundColor: Color { get }
    var menuBarPillCornerRadius: CGFloat { get }

    // Theme-specific colors for different states
    func menuBarTextColor(isActive: Bool) -> Color
    func chartColor(for index: Int) -> Color
    func dayBackgroundColor(cost: Double?, maxCost: Double) -> Color
}

// MARK: - Default Theme Implementation

extension Theme {
    // Default menu bar background properties
    var menuBarBackgroundStyle: MenuBarBackgroundStyle { .none }
    var menuBarBackgroundColor: Color { Color.gray.opacity(0.2) }
    var menuBarPillCornerRadius: CGFloat { 6 }

    func menuBarTextColor(isActive: Bool) -> Color {
        return isActive ? textColor : secondaryColor
    }
    
    func chartColor(for index: Int) -> Color {
        let colors = [accentColor, primaryColor, successColor, warningColor, errorColor]
        return colors[index % colors.count]
    }
    
    func dayBackgroundColor(cost: Double?, maxCost: Double) -> Color {
        guard let cost = cost, maxCost > 0 else {
            return backgroundColor
        }
        
        let intensity = min(cost / maxCost, 1.0)
        
        if intensity < 0.2 {
            return successColor.opacity(0.2)
        } else if intensity < 0.6 {
            return warningColor.opacity(0.3)
        } else {
            return errorColor.opacity(0.4)
        }
    }
}

// MARK: - Classic Theme

struct ClassicTheme: Theme {
    let name = "Classic"
    let description = "Default macOS system appearance with standard spacing and text sizes"
    let identifier = "classic"
    
    // Colors - Using system colors for automatic light/dark adaptation
    let primaryColor = Color.primary
    let secondaryColor = Color.secondary
    let accentColor = Color.accentColor
    let backgroundColor = Color(NSColor.windowBackgroundColor)
    let textColor = Color.primary
    let errorColor = Color.red
    let warningColor = Color.orange
    let successColor = Color.green
    
    // Text Formatting
    let smallFontSize: CGFloat = 11
    let regularFontSize: CGFloat = 13
    let largeFontSize: CGFloat = 15
    let primaryFontWeight = Font.Weight.regular
    let secondaryFontWeight = Font.Weight.medium
    
    // Layout Density
    let paddingScale: CGFloat = 1.0
    let spacingMultiplier: CGFloat = 1.0
}

// MARK: - Modern Theme

struct ModernTheme: Theme {
    let name = "Modern"
    let description = "Contemporary flat design with vibrant colors and clean typography"
    let identifier = "modern"
    
    // Colors - Vibrant modern palette
    let primaryColor = Color.primary
    let secondaryColor = Color.secondary
    let accentColor = Color.blue
    let backgroundColor = Color(NSColor.controlBackgroundColor)
    let textColor = Color.primary
    let errorColor = Color(red: 1.0, green: 0.23, blue: 0.19)
    let warningColor = Color(red: 1.0, green: 0.58, blue: 0.0)
    let successColor = Color(red: 0.20, green: 0.78, blue: 0.35)
    
    // Text Formatting - Slightly larger for modern look
    let smallFontSize: CGFloat = 12
    let regularFontSize: CGFloat = 14
    let largeFontSize: CGFloat = 16
    let primaryFontWeight = Font.Weight.medium
    let secondaryFontWeight = Font.Weight.semibold
    
    // Layout Density - More spacious
    let paddingScale: CGFloat = 1.1
    let spacingMultiplier: CGFloat = 1.2
}

// MARK: - High Contrast Theme

struct HighContrastTheme: Theme {
    let name = "High Contrast"
    let description = "WCAG AAA compliant high contrast theme with larger text for accessibility"
    let identifier = "highContrast"
    
    // Colors - High contrast for accessibility
    let primaryColor = Color.primary
    let secondaryColor = Color.secondary
    let accentColor = Color.blue
    let backgroundColor = Color(NSColor.windowBackgroundColor)
    let textColor = Color.primary
    let errorColor = Color.red
    let warningColor = Color.orange
    let successColor = Color.green
    
    // Text Formatting - Larger for accessibility
    let smallFontSize: CGFloat = 13
    let regularFontSize: CGFloat = 15
    let largeFontSize: CGFloat = 18
    let primaryFontWeight = Font.Weight.semibold
    let secondaryFontWeight = Font.Weight.bold
    
    // Layout Density - More space for readability
    let paddingScale: CGFloat = 1.3
    let spacingMultiplier: CGFloat = 1.4
}

// MARK: - Compact Theme

struct CompactTheme: Theme {
    let name = "Compact"
    let description = "Information-dense layout with reduced spacing and smaller text"
    let identifier = "compact"
    
    // Colors - Standard system colors
    let primaryColor = Color.primary
    let secondaryColor = Color.secondary
    let accentColor = Color.accentColor
    let backgroundColor = Color(NSColor.windowBackgroundColor)
    let textColor = Color.primary
    let errorColor = Color.red
    let warningColor = Color.orange
    let successColor = Color.green
    
    // Text Formatting - Smaller for density
    let smallFontSize: CGFloat = 10
    let regularFontSize: CGFloat = 12
    let largeFontSize: CGFloat = 14
    let primaryFontWeight = Font.Weight.regular
    let secondaryFontWeight = Font.Weight.medium
    
    // Layout Density - Compact spacing
    let paddingScale: CGFloat = 0.8
    let spacingMultiplier: CGFloat = 0.7
}

// MARK: - Comfortable Theme

struct ComfortableTheme: Theme {
    let name = "Comfortable"
    let description = "Relaxed spacing with larger text for easy reading during long sessions"
    let identifier = "comfortable"
    
    // Colors
    let primaryColor = Color.primary
    let secondaryColor = Color.secondary
    let accentColor = Color.accentColor
    let backgroundColor = Color(NSColor.windowBackgroundColor)
    let textColor = Color.primary
    let errorColor = Color.red
    let warningColor = Color.orange
    let successColor = Color.green
    
    // Text Formatting - Larger for comfort
    let smallFontSize: CGFloat = 12
    let regularFontSize: CGFloat = 14
    let largeFontSize: CGFloat = 17
    let primaryFontWeight = Font.Weight.regular
    let secondaryFontWeight = Font.Weight.medium
    
    // Layout Density - Extra space for comfort
    let paddingScale: CGFloat = 1.4
    let spacingMultiplier: CGFloat = 1.5
}

// MARK: - Terminal Theme

struct TerminalTheme: Theme {
    let name = "Terminal"
    let description = "Dark developer-friendly theme with monospace aesthetics"
    let identifier = "terminal"
    
    // Colors - Terminal-inspired dark theme
    let primaryColor = Color(red: 0.0, green: 1.0, blue: 0.0) // Terminal green
    let secondaryColor = Color(red: 0.7, green: 0.7, blue: 0.7)
    let accentColor = Color(red: 0.0, green: 0.8, blue: 0.0)
    let backgroundColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    let textColor = Color(red: 0.0, green: 1.0, blue: 0.0)
    let errorColor = Color(red: 1.0, green: 0.2, blue: 0.2)
    let warningColor = Color(red: 1.0, green: 1.0, blue: 0.0) // Terminal yellow
    let successColor = Color(red: 0.0, green: 1.0, blue: 0.0)
    
    // Text Formatting - Monospace feel
    let smallFontSize: CGFloat = 11
    let regularFontSize: CGFloat = 13
    let largeFontSize: CGFloat = 15
    let primaryFontWeight = Font.Weight.regular
    let secondaryFontWeight = Font.Weight.medium
    
    // Layout Density
    let paddingScale: CGFloat = 0.9
    let spacingMultiplier: CGFloat = 1.0
}

// MARK: - Professional Theme

struct ProfessionalTheme: Theme {
    let name = "Professional"
    let description = "Formal business appearance with muted colors and elegant typography"
    let identifier = "professional"
    
    // Colors - Professional, muted palette
    let primaryColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let secondaryColor = Color(red: 0.5, green: 0.5, blue: 0.6)
    let accentColor = Color(red: 0.0, green: 0.3, blue: 0.6) // Professional blue
    let backgroundColor = Color(red: 0.98, green: 0.98, blue: 0.99)
    let textColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let errorColor = Color(red: 0.8, green: 0.2, blue: 0.2)
    let warningColor = Color(red: 0.9, green: 0.5, blue: 0.1)
    let successColor = Color(red: 0.1, green: 0.6, blue: 0.3)
    
    // Text Formatting - Elegant and readable
    let smallFontSize: CGFloat = 11
    let regularFontSize: CGFloat = 13
    let largeFontSize: CGFloat = 16
    let primaryFontWeight = Font.Weight.regular
    let secondaryFontWeight = Font.Weight.semibold
    
    // Layout Density - Balanced
    let paddingScale: CGFloat = 1.1
    let spacingMultiplier: CGFloat = 1.2
}

// MARK: - Memphis Theme

struct MemphisTheme: Theme {
    let name = "Memphis"
    let description = "Playful 80s-inspired design with bold colors and geometric shapes"
    let identifier = "memphis"

    // Colors - Bold Memphis palette (pink, teal, yellow, purple)
    let primaryColor = Color(red: 0.95, green: 0.26, blue: 0.50)  // Hot pink
    let secondaryColor = Color(red: 0.10, green: 0.74, blue: 0.74)  // Teal
    let accentColor = Color(red: 1.0, green: 0.84, blue: 0.0)  // Yellow
    let backgroundColor = Color(red: 0.98, green: 0.96, blue: 0.93)  // Cream
    let textColor = Color(red: 0.20, green: 0.20, blue: 0.30)  // Dark gray
    let errorColor = Color(red: 1.0, green: 0.30, blue: 0.30)
    let warningColor = Color(red: 1.0, green: 0.60, blue: 0.0)
    let successColor = Color(red: 0.10, green: 0.74, blue: 0.74)

    // Text Formatting - Bold, playful
    let smallFontSize: CGFloat = 12
    let regularFontSize: CGFloat = 14
    let largeFontSize: CGFloat = 17
    let primaryFontWeight = Font.Weight.bold
    let secondaryFontWeight = Font.Weight.semibold

    // Layout Density - Spacious
    let paddingScale: CGFloat = 1.2
    let spacingMultiplier: CGFloat = 1.3

    // Memphis uses pill background by default
    var menuBarBackgroundStyle: MenuBarBackgroundStyle { .pill }
    var menuBarBackgroundColor: Color { Color(red: 0.95, green: 0.26, blue: 0.50).opacity(0.15) }
    var menuBarPillCornerRadius: CGFloat { 8 }

    // Custom chart colors - Memphis palette
    func chartColor(for index: Int) -> Color {
        let colors = [
            Color(red: 0.95, green: 0.26, blue: 0.50),  // Hot pink
            Color(red: 0.10, green: 0.74, blue: 0.74),  // Teal
            Color(red: 1.0, green: 0.84, blue: 0.0),    // Yellow
            Color(red: 0.55, green: 0.35, blue: 0.90),  // Purple
            Color(red: 0.98, green: 0.50, blue: 0.45)   // Coral
        ]
        return colors[index % colors.count]
    }
}