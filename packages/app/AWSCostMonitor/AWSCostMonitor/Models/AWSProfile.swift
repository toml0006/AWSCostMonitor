//
//  AWSProfile.swift
//  AWSCostMonitor
//
//  AWS Profile data model
//

import Foundation

// A simple structure to hold the parsed AWS profile data.
struct AWSProfile: Identifiable, Hashable, Codable {
    let id = UUID()
    let name: String
    let region: String?
    
    // Make it Codable for storage
    enum CodingKeys: String, CodingKey {
        case name, region
    }
}

// AWS Credentials structure for manual parsing
struct ParsedAWSCredentials {
    let accessKeyId: String
    let secretAccessKey: String
    let sessionToken: String?
}