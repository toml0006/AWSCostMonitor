#!/usr/bin/env swift

import Foundation
import os.log

// Simple script to check recent logs
print("=== Recent Log Check ===")
print("Current time: \(Date())")

// Try to read from the system log
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/log")
task.arguments = ["show", "--last", "2m", "--style", "compact"]

let pipe = Pipe()
task.standardOutput = pipe

do {
    try task.run()
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        let lines = output.components(separatedBy: .newlines)
        let relevantLines = lines.filter { line in
            line.contains("AWSCostMonitor") || 
            line.contains("STARTUP") || 
            line.contains("BYPASS") ||
            line.contains("Team cache") ||
            line.contains("DEBUG") ||
            line.contains("ecoengineers")
        }
        
        print("Found \(relevantLines.count) relevant log lines:")
        for line in relevantLines.prefix(20) {
            print("  \(line)")
        }
        
        if relevantLines.isEmpty {
            print("No relevant log lines found in the last 2 minutes")
        }
    }
} catch {
    print("Error running log command: \(error)")
}

