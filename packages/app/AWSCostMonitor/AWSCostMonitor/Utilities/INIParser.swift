//
//  INIParser.swift
//  AWSCostMonitor
//
//  Utility to parse INI configuration files
//

import Foundation

// This is necessary to list all available profiles.
class INIParser {
    static func parse(filePath: String) -> [String: [String: String]] {
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            return parseString(content)
        } catch {
            print("Error reading INI file: \(error.localizedDescription)")
            return [:]
        }
    }
    
    static func parseString(_ content: String) -> [String: [String: String]] {
        var profiles = [String: [String: String]]()
        var currentProfileName: String?
        let lines = content.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for line in lines {
            if line.isEmpty || line.hasPrefix("#") {
                continue
            }

            if line.hasPrefix("[profile ") && line.hasSuffix("]") {
                let name = String(line.dropFirst(9).dropLast(1))
                currentProfileName = name
                profiles[name] = [String: String]()
            } else if line.hasPrefix("[") && line.hasSuffix("]") {
                let name = String(line.dropFirst().dropLast())
                currentProfileName = name
                profiles[name] = [String: String]()
            } else if let currentName = currentProfileName {
                let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count == 2 {
                    profiles[currentName]?[String(parts[0])] = String(parts[1])
                }
            }
        }
        return profiles
    }
}