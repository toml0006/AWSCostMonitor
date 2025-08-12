//
//  DisplayFormat.swift
//  AWSCostMonitor
//
//  Display format configuration models
//

import Foundation

// Enum defining the different menu bar display formats
enum MenuBarDisplayFormat: String, CaseIterable {
    case full = "full"
    case abbreviated = "abbreviated"
    case iconOnly = "iconOnly"
    
    var displayName: String {
        switch self {
        case .full:
            return "Full ($123.45)"
        case .abbreviated:
            return "Abbreviated ($123)"
        case .iconOnly:
            return "Icon Only"
        }
    }
}