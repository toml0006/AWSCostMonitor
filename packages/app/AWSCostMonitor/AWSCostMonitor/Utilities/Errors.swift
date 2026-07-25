//
//  Errors.swift
//  AWSCostMonitor
//
//  Error definitions
//

import Foundation

// Custom errors for AWS cost fetching
enum AWSCostFetchError: Error {
    case credentialsNotFound(String)
    /// No SSO token at all for this session — the user has never signed in.
    case ssoNotLoggedIn(session: String)
    /// A token exists but is past its expiry, and refresh was unavailable or failed.
    case ssoSessionExpired(session: String)
    /// The profile uses a credential mechanism this app does not implement.
    case unsupportedProfile(profile: String, reason: String)
}

extension AWSCostFetchError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .credentialsNotFound(let detail):
            return detail
        case .ssoNotLoggedIn(let session):
            return "Not signed in to SSO session '\(session)'."
        case .ssoSessionExpired(let session):
            return "SSO session '\(session)' has expired."
        case .unsupportedProfile(let profile, let reason):
            return "Profile '\(profile)' can't be used: \(reason)"
        }
    }
}
