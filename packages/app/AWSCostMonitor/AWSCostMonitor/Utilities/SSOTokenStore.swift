//
//  SSOTokenStore.swift
//  AWSCostMonitor
//
//  Keychain storage for tokens this app mints. Deliberately does not write
//  ~/.aws/sso/cache: the sandbox entitlement is user-selected read-only, and
//  requesting read-write purely to share a token back to the CLI is a poor
//  trade for an app whose premise is read-only access (DEC-003). Sharing is
//  therefore one-directional — the CLI's cache is read, never written.
//

import Foundation
import Security

struct OIDCRegistration: Codable, Equatable {
    let clientId: String
    let clientSecret: String
    let expiresAt: Date
}

private struct StoredToken: Codable {
    let accessToken: String
    let expiresAt: Date
    let region: String?
    let startUrl: String?
    let refreshToken: String?
    let clientId: String?
    let clientSecret: String?
}

enum SSOTokenStoreError: Error {
    case keychain(OSStatus)
}

struct SSOTokenStore: SSOTokenProviding {
    let service: String

    init(service: String = "dev.middleout.AWSCostMonitor.sso") {
        self.service = service
    }

    // MARK: - Tokens

    func token(forKey key: String) async -> SSOToken? {
        guard let data = read(account: "token:\(key)"),
              let stored = try? JSONDecoder().decode(
                StoredToken.self,
                from: data
              ) else {
            return nil
        }
        return SSOToken(
            accessToken: stored.accessToken,
            expiresAt: stored.expiresAt,
            region: stored.region,
            startUrl: stored.startUrl,
            refreshToken: stored.refreshToken,
            clientId: stored.clientId,
            clientSecret: stored.clientSecret
        )
    }

    func save(_ token: SSOToken, forKey key: String) throws {
        let stored = StoredToken(
            accessToken: token.accessToken,
            expiresAt: token.expiresAt,
            region: token.region,
            startUrl: token.startUrl,
            refreshToken: token.refreshToken,
            clientId: token.clientId,
            clientSecret: token.clientSecret
        )
        try write(
            try JSONEncoder().encode(stored),
            account: "token:\(key)"
        )
    }

    func delete(forKey key: String) throws {
        try remove(account: "token:\(key)")
    }

    // MARK: - OIDC client registration

    /// Returns nil for an expired registration so the caller re-registers
    /// rather than sending a client ID that the service will reject.
    func registration(forKey key: String) -> OIDCRegistration? {
        guard let data = read(account: "registration:\(key)"),
              let registration = try? JSONDecoder().decode(
                OIDCRegistration.self,
                from: data
              ),
              registration.expiresAt > Date() else {
            return nil
        }
        return registration
    }

    func saveRegistration(
        _ registration: OIDCRegistration,
        forKey key: String
    ) throws {
        try write(
            try JSONEncoder().encode(registration),
            account: "registration:\(key)"
        )
    }

    // MARK: - Keychain primitives

    private func query(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    private func read(account: String) -> Data? {
        var keychainQuery = query(account: account)
        keychainQuery[kSecReturnData as String] = true
        keychainQuery[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(
            keychainQuery as CFDictionary,
            &item
        ) == errSecSuccess else {
            return nil
        }
        return item as? Data
    }

    private func write(_ data: Data, account: String) throws {
        var keychainQuery = query(account: account)
        keychainQuery[kSecValueData as String] = data
        keychainQuery[kSecAttrAccessible as String] =
            kSecAttrAccessibleAfterFirstUnlock

        let addStatus = SecItemAdd(keychainQuery as CFDictionary, nil)
        if addStatus == errSecSuccess {
            return
        }
        guard addStatus == errSecDuplicateItem else {
            throw SSOTokenStoreError.keychain(addStatus)
        }

        let updateStatus = SecItemUpdate(
            query(account: account) as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        guard updateStatus == errSecSuccess else {
            throw SSOTokenStoreError.keychain(updateStatus)
        }
    }

    private func remove(account: String) throws {
        let status = SecItemDelete(query(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SSOTokenStoreError.keychain(status)
        }
    }
}
