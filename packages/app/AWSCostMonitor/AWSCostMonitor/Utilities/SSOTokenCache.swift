//
//  SSOTokenCache.swift
//  AWSCostMonitor
//
//  Reads the AWS CLI's SSO token cache. Read-only by design: the app's
//  entitlements grant user-selected read access only, and app-minted tokens go
//  to the Keychain instead (see SSOTokenStore).
//

import Foundation
import CryptoKit

struct SSOToken: Equatable {
    let accessToken: String
    let expiresAt: Date
    let region: String?
    let startUrl: String?
    let refreshToken: String?
    let clientId: String?
    let clientSecret: String?

    /// Treat a token as expired 5 minutes early so a request started now cannot
    /// outlive it in flight.
    static let expiryMargin: TimeInterval = 300

    var isExpired: Bool {
        expiresAt.timeIntervalSinceNow <= Self.expiryMargin
    }
}

enum SSOTokenCacheError: Error {
    case malformed(String)
}

enum SSOTokenCache {

    /// The AWS CLI names each cache file with the lowercase SHA-1 hex digest of
    /// the session name (or, for legacy profiles, the start URL).
    static func cacheFileName(forKey key: String) -> String {
        let digest = Insecure.SHA1.hash(data: Data(key.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return "\(hex).json"
    }

    static func decode(_ data: Data) throws -> SSOToken {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SSOTokenCacheError.malformed("Token cache is not a JSON object.")
        }
        guard let accessToken = object["accessToken"] as? String, !accessToken.isEmpty else {
            throw SSOTokenCacheError.malformed("Token cache has no accessToken.")
        }
        guard let expiresRaw = object["expiresAt"] as? String,
              let expiresAt = parseExpiry(expiresRaw) else {
            throw SSOTokenCacheError.malformed("Token cache has no parseable expiresAt.")
        }
        return SSOToken(
            accessToken: accessToken,
            expiresAt: expiresAt,
            region: object["region"] as? String,
            startUrl: object["startUrl"] as? String,
            refreshToken: object["refreshToken"] as? String,
            clientId: object["clientId"] as? String,
            clientSecret: object["clientSecret"] as? String
        )
    }

    /// Seen in the wild: with and without fractional seconds, and an older
    /// "…UTC" suffix instead of "Z".
    private static func parseExpiry(_ raw: String) -> Date? {
        let normalised = raw.hasSuffix("UTC")
            ? String(raw.dropLast(3)) + "Z"
            : raw

        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: normalised) { return date }

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: normalised)
    }

    /// Read the CLI's cached token for `key`, or nil when absent or unreadable.
    static func readCLIToken(forKey key: String) -> SSOToken? {
        let fileName = cacheFileName(forKey: key)
        return AWSConfigAccessManager.shared.withScopedAccess { awsDir -> SSOToken? in
            let url = awsDir.appendingPathComponent("sso/cache/\(fileName)")
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decode(data)
        } ?? nil
    }
}
