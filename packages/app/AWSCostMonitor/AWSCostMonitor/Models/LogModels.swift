//
//  LogModels.swift
//  AWSCostMonitor
//
//  Logging and tracking data models
//

import Foundation
import SwiftUI

// Log entry for tracking
struct LogEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let category: String
    let message: String
    let metadata: [String: String]?
    
    enum LogLevel: String, Codable, CaseIterable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        
        var color: Color {
            switch self {
            case .debug: return .gray
            case .info: return .primary
            case .warning: return .orange
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .debug: return "ant.circle"
            case .info: return "info.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            }
        }
    }
}

// API request tracking
struct APIRequestRecord: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let profileName: String
    let endpoint: String
    let success: Bool
    let duration: TimeInterval
    let errorMessage: String?
}