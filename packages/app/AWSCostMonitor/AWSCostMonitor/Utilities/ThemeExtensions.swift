//
//  ThemeExtensions.swift
//  AWSCostMonitor
//
//  Theme-aware extensions for menu bar and UI components
//

import Foundation
import SwiftUI
import AppKit

// MARK: - NSColor Extensions for Theme Integration

extension NSColor {
    /// Create NSColor from SwiftUI Color for menu bar usage
    static func from(_ swiftUIColor: Color) -> NSColor {
        // Convert SwiftUI Color to NSColor safely
        if #available(macOS 12.0, *) {
            return NSColor.from(swiftUIColor)
        } else {
            // Fallback for older macOS versions - return system colors
            return NSColor.labelColor // Default to primary label color
        }
    }
}

// MARK: - Theme-Aware Menu Bar Utilities

extension Theme {
    /// Get NSColor for menu bar text based on cost status and theme
    func menuBarTextNSColor(for status: MenuBarCostStatus) -> NSColor {
        // For now, use system colors that adapt to light/dark mode automatically
        // Later we can add theme-specific color mapping
        switch status {
        case .normal:
            // Use different colors based on theme type
            if identifier == "terminal" {
                return NSColor.systemGreen
            } else if identifier == "professional" {
                return NSColor.controlTextColor
            } else {
                return NSColor.labelColor
            }
        case .warning:
            return NSColor.systemOrange
        case .error:
            return NSColor.systemRed
        case .success:
            return NSColor.systemGreen
        case .loading:
            return NSColor.secondaryLabelColor
        }
    }
    
    /// Get NSAttributedString attributes for menu bar display
    func menuBarAttributes(for status: MenuBarCostStatus, isFlashing: Bool = false) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]
        
        // Font configuration based on theme
        let fontSize = regularFontSize
        let fontWeight: NSFont.Weight = primaryFontWeight == Font.Weight.regular ? .regular :
                                      primaryFontWeight == Font.Weight.medium ? .medium :
                                      primaryFontWeight == Font.Weight.semibold ? .semibold :
                                      primaryFontWeight == Font.Weight.bold ? .bold : .regular
        
        attributes[.font] = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: fontWeight)
        
        // Color configuration
        if isFlashing {
            attributes[.foregroundColor] = NSColor.systemRed
            attributes[.backgroundColor] = NSColor.systemYellow.withAlphaComponent(0.3)
        } else {
            attributes[.foregroundColor] = menuBarTextNSColor(for: status)
        }
        
        return attributes
    }
    
    /// Get theme-appropriate spacing for menu bar elements
    var menuBarSpacing: CGFloat {
        return 4.0 * spacingMultiplier
    }
    
    /// Get theme-appropriate padding for menu bar elements  
    var menuBarPadding: CGFloat {
        return 6.0 * paddingScale
    }
}

// MARK: - Menu Bar Cost Status

enum MenuBarCostStatus {
    case normal
    case warning
    case error
    case success
    case loading
}

// MARK: - Theme-Aware Menu Bar Builder

struct ThemedMenuBarDisplay {
    let theme: Theme
    let status: MenuBarCostStatus
    
    init(theme: Theme, status: MenuBarCostStatus = .normal) {
        self.theme = theme
        self.status = status
    }
    
    /// Create attributed string for menu bar display
    func attributedString(for text: String, isFlashing: Bool = false) -> NSAttributedString {
        let attributes = theme.menuBarAttributes(for: status, isFlashing: isFlashing)
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    /// Get cost status based on cost data and budget
    static func getStatus(for cost: CostData?, 
                         lastMonthData: [String: CostData],
                         budget: ProfileBudget) -> MenuBarCostStatus {
        guard let cost = cost else { return .loading }
        
        // Check last month comparison first (same logic as existing)
        if let lastMonthCost = lastMonthData[cost.profileName],
           lastMonthCost.amount > 0 {
            let currentAmount = NSDecimalNumber(decimal: cost.amount).doubleValue
            let lastAmount = NSDecimalNumber(decimal: lastMonthCost.amount).doubleValue
            let percentChange = ((currentAmount - lastAmount) / lastAmount) * 100
            
            if percentChange < -5 {
                return .success // Spending less than last month
            } else if percentChange > 20 {
                return .error // Spending significantly more
            } else if percentChange > 10 {
                return .warning // Spending moderately more
            } else {
                return .normal // Within normal range
            }
        }
        
        // Fallback to budget-based status
        if let monthlyBudget = budget.monthlyBudget {
            let amount = NSDecimalNumber(decimal: cost.amount).doubleValue
            let percentUsed = (amount / NSDecimalNumber(decimal: monthlyBudget).doubleValue) * 100
            
            if percentUsed >= 100 {
                return .error
            } else if percentUsed >= 80 {
                return .warning
            } else if percentUsed >= 60 {
                return .warning
            } else {
                return .success
            }
        }
        
        return .normal
    }
}

// MARK: - Theme-Aware Icon Generation

extension Theme {
    /// Generate theme-tinted menu bar icon for icon-only display
    func createMenuBarIcon(size: CGFloat = 18) -> NSImage? {
        // Use the existing MenuBarCloudIcon but potentially tint with theme colors
        let baseImage = MenuBarCloudIcon.createImage(size: size)
        
        // For terminal theme, we might want to tint the icon
        if identifier == "terminal" {
            // Create a template image that can be tinted
            let templateImage = baseImage?.copy() as? NSImage
            templateImage?.isTemplate = true
            return templateImage
        }
        
        return baseImage
    }
}

// MARK: - Theme Manager Extensions for Menu Bar

extension ThemeManager {
    /// Get current theme's menu bar display helper
    var menuBarDisplay: ThemedMenuBarDisplay {
        return ThemedMenuBarDisplay(theme: currentTheme)
    }
    
    /// Create attributed string for current theme
    func createMenuBarAttributedString(text: String, 
                                     status: MenuBarCostStatus = .normal, 
                                     isFlashing: Bool = false) -> NSAttributedString {
        let display = ThemedMenuBarDisplay(theme: currentTheme, status: status)
        return display.attributedString(for: text, isFlashing: isFlashing)
    }
}