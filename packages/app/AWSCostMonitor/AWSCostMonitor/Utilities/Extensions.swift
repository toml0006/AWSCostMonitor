//
//  Extensions.swift
//  AWSCostMonitor
//
//  Common extensions
//

import Foundation
import OSLog

extension Logger {
    /// Custom logging subsystem for AWSCostMonitor
    static let app = Logger(subsystem: "com.awscostmonitor.app", category: "general")
    static let aws = Logger(subsystem: "com.awscostmonitor.app", category: "aws")
    static let ui = Logger(subsystem: "com.awscostmonitor.app", category: "ui")
    static let api = Logger(subsystem: "com.awscostmonitor.app", category: "api")
    static let cache = Logger(subsystem: "com.awscostmonitor.app", category: "cache")
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}