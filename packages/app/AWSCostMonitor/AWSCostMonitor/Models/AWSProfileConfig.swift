//
//  AWSProfileConfig.swift
//  AWSCostMonitor
//
//  Richer view of an ~/.aws/config profile than AWSProfile, carrying how the
//  profile's credentials are actually obtained.
//

import Foundation

struct SSOSession: Equatable {
    let name: String
    let startUrl: String
    let ssoRegion: String
    let scopes: [String]
}

struct SSOProfileRef: Equatable {
    /// nil for legacy profiles that inline sso_start_url instead of naming a session.
    let sessionName: String?
    let startUrl: String
    let ssoRegion: String
    let accountId: String
    let roleName: String

    /// Key the AWS CLI hashes to name the token cache file: the session name when
    /// one is used, otherwise the start URL.
    var cacheKey: String { sessionName ?? startUrl }
}

enum ProfileCredentialSource: Equatable {
    case staticKeys
    case sso(SSOProfileRef)
    case assumeRole(roleArn: String, sourceProfile: String, mfaSerial: String?)
    case unsupported(reason: String)
}

struct AWSProfileConfig: Equatable {
    let name: String
    let region: String?
    let source: ProfileCredentialSource
}

struct ParsedAWSConfig {
    let profiles: [AWSProfileConfig]
    let ssoSessions: [String: SSOSession]
}
