//
//  AWSCredentialsHelper.swift
//  AWSCostMonitor
//
//  AWS credentials parsing
//

import Foundation

// Function to parse AWS credentials from credentials file content
func parseAWSCredentials(content: String, profileName: String) -> ParsedAWSCredentials? {
    let lines = content.components(separatedBy: .newlines)
    var inTargetProfile = false
    var accessKeyId: String?
    var secretAccessKey: String?
    var sessionToken: String?
    
    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Check if we're entering the target profile section
        if trimmed == "[\(profileName)]" {
            inTargetProfile = true
            continue
        }
        
        // Check if we're entering a different profile section
        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") && trimmed != "[\(profileName)]" {
            inTargetProfile = false
            continue
        }
        
        // Only process lines when we're in the target profile
        if inTargetProfile && trimmed.contains("=") {
            let components = trimmed.components(separatedBy: "=")
            if components.count >= 2 {
                let key = components[0].trimmingCharacters(in: .whitespaces)
                let value = components.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespaces)
                
                switch key {
                case "aws_access_key_id":
                    accessKeyId = value
                case "aws_secret_access_key":
                    secretAccessKey = value
                case "aws_session_token":
                    sessionToken = value
                default:
                    break
                }
            }
        }
    }
    
    // Must have at least access key and secret
    guard let accessKey = accessKeyId, let secretKey = secretAccessKey else {
        return nil
    }
    
    return ParsedAWSCredentials(
        accessKeyId: accessKey,
        secretAccessKey: secretKey,
        sessionToken: sessionToken
    )
}
