//
//  AWSCredentialsHelper.swift
//  AWSCostMonitor
//
//  AWS Credentials parsing and provider creation
//

import Foundation
import AWSSDKIdentity
import SmithyIdentity

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

// Helper function to create appropriate credentials provider for sandbox/non-sandbox
func createAWSCredentialsProvider(for profileName: String) throws -> any AWSCredentialIdentityResolver {
    if ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil {
        // Sandboxed environment - use manual credential parsing
        let accessManager = AWSConfigAccessManager.shared
        
        guard let credentialsContent = accessManager.readCredentialsFile() else {
            throw AWSCostFetchError.credentialsNotFound("Unable to read credentials file via security-scoped access")
        }
        
        guard let profileCredentials = parseAWSCredentials(content: credentialsContent, profileName: profileName) else {
            throw AWSCostFetchError.credentialsNotFound("No credentials found for profile '\(profileName)' in credentials file")
        }
        
        let awsCredentials = AWSCredentialIdentity(
            accessKey: profileCredentials.accessKeyId,
            secret: profileCredentials.secretAccessKey,
            sessionToken: profileCredentials.sessionToken
        )
        
        return StaticAWSCredentialIdentityResolver(awsCredentials)
    } else {
        // Not sandboxed - use standard ProfileAWSCredentialIdentityResolver
        return try ProfileAWSCredentialIdentityResolver(profileName: profileName)
    }
}