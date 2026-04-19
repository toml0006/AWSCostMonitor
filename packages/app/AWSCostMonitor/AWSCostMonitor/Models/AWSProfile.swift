//
//  AWSProfile.swift
//  AWSCostMonitor
//
//  AWS Profile data model
//

import Foundation

// A simple structure to hold the parsed AWS profile data.
// Identity is derived from `name` so re-parsing the config file produces instances
// that remain equal to a previously stored selection. Using a per-instance UUID here
// broke the Picker binding: any profile reload changed ids, so `selectedProfile`
// no longer matched any row and clicks appeared to "miss".
struct AWSProfile: Identifiable, Hashable, Codable {
    var id: String { name }
    let name: String
    let region: String?
    let accountId: String?
    let isRemoved: Bool
    let lastSeenDate: Date?

    init(name: String, region: String?, accountId: String? = nil, isRemoved: Bool = false, lastSeenDate: Date? = nil) {
        self.name = name
        self.region = region
        self.accountId = accountId
        self.isRemoved = isRemoved
        self.lastSeenDate = lastSeenDate
    }

    static func == (lhs: AWSProfile, rhs: AWSProfile) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

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