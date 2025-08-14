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
    let accountId: String?
    let isRemoved: Bool
    let lastSeenDate: Date?
    
    // Initialize with default values for new properties
    init(name: String, region: String?, accountId: String? = nil, isRemoved: Bool = false, lastSeenDate: Date? = nil) {
        self.name = name
        self.region = region
        self.accountId = accountId
        self.isRemoved = isRemoved
        self.lastSeenDate = lastSeenDate
    }
    
    // Make it Codable for storage
    enum CodingKeys: String, CodingKey {
        case name, region, accountId, isRemoved, lastSeenDate
    }
}

// AWS Credentials structure for manual parsing
struct ParsedAWSCredentials {
    let accessKeyId: String
    let secretAccessKey: String
    let sessionToken: String?
}