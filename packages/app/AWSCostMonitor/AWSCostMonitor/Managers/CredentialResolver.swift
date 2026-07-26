//
//  CredentialResolver.swift
//  AWSCostMonitor
//
//  Turns a profile name into an AWS credential resolver, handling static keys,
//  SSO, and role_arn/source_profile chains. Replaces createAWSCredentialsProvider,
//  which only understood static keys from ~/.aws/credentials and therefore failed
//  for every SSO and assume-role profile in a sandboxed build.
//

import Foundation
import AWSSSO
import AWSSTS
import AWSSDKIdentity
import SmithyIdentity

// MARK: - Seams for testing

protocol SSOTokenProviding: Sendable {
    func token(forKey key: String) async -> SSOToken?
}

protocol SSORoleCredentialsFetching: Sendable {
    func fetch(
        accessToken: String,
        accountId: String,
        roleName: String,
        region: String
    ) async throws -> AWSCredentialIdentity
}

protocol STSAssuming: Sendable {
    func assume(
        roleArn: String,
        sessionName: String,
        region: String,
        using: AWSCredentialIdentity
    ) async throws -> AWSCredentialIdentity
}

// MARK: - Resolver

actor CredentialResolver {

    /// Refresh this far ahead of expiry so a request started now cannot outlive
    /// its credentials in flight.
    private static let expiryMargin: TimeInterval = 300

    /// Guards against pathological config; real chains are 1-2 deep.
    private static let maxChainDepth = 5

    private let configs: [String: AWSProfileConfig]
    private let ssoTokens: any SSOTokenProviding
    private let ssoRoles: any SSORoleCredentialsFetching
    private let sts: any STSAssuming

    private var cache: [String: AWSCredentialIdentity] = [:]

    init(
        configs: [String: AWSProfileConfig],
        ssoTokens: any SSOTokenProviding,
        ssoRoles: any SSORoleCredentialsFetching,
        sts: any STSAssuming
    ) {
        self.configs = configs
        self.ssoTokens = ssoTokens
        self.ssoRoles = ssoRoles
        self.sts = sts
    }

    func resolver(
        for profileName: String
    ) async throws -> any AWSCredentialIdentityResolver {
        let identity = try await credentials(for: profileName, visited: [])
        return StaticAWSCredentialIdentityResolver(identity)
    }

    /// Invalidate everything after a fresh sign-in.
    func invalidateCache() {
        cache.removeAll()
    }

    // MARK: - Chain

    private func credentials(
        for profileName: String,
        visited: Set<String>
    ) async throws -> AWSCredentialIdentity {
        if let cached = cache[profileName], !isNearExpiry(cached) {
            return cached
        }

        guard !visited.contains(profileName) else {
            throw AWSCostFetchError.unsupportedProfile(
                profile: profileName,
                reason: "Detected a cycle in the source_profile chain."
            )
        }
        guard visited.count < Self.maxChainDepth else {
            throw AWSCostFetchError.unsupportedProfile(
                profile: profileName,
                reason: "source_profile chain is deeper than \(Self.maxChainDepth) levels."
            )
        }
        guard let config = configs[profileName] else {
            throw AWSCostFetchError.unsupportedProfile(
                profile: profileName,
                reason: "No such profile in ~/.aws/config."
            )
        }

        let identity: AWSCredentialIdentity
        switch config.source {
        case .unsupported(let reason):
            throw AWSCostFetchError.unsupportedProfile(
                profile: profileName,
                reason: reason
            )

        case .staticKeys:
            identity = try staticCredentials(for: profileName)

        case .sso(let ref):
            identity = try await ssoCredentials(ref)

        case .assumeRole(let roleArn, let sourceProfile, let mfaSerial):
            if let mfaSerial, !mfaSerial.isEmpty {
                throw AWSCostFetchError.unsupportedProfile(
                    profile: profileName,
                    reason: "Profiles requiring MFA (mfa_serial \(mfaSerial)) aren't supported yet."
                )
            }
            let source = try await credentials(
                for: sourceProfile,
                visited: visited.union([profileName])
            )
            identity = try await sts.assume(
                roleArn: roleArn,
                sessionName: "AWSCostMonitor-\(profileName)",
                region: config.region ?? "us-east-1",
                using: source
            )
        }

        cache[profileName] = identity
        return identity
    }

    private func isNearExpiry(_ identity: AWSCredentialIdentity) -> Bool {
        guard let expiration = identity.expiration else {
            return false
        }
        return expiration.timeIntervalSinceNow <= Self.expiryMargin
    }

    private func staticCredentials(
        for profileName: String
    ) throws -> AWSCredentialIdentity {
        guard let content = AWSConfigAccessManager.shared.readCredentialsFile() else {
            throw AWSCostFetchError.credentialsNotFound(
                "Unable to read ~/.aws/credentials."
            )
        }
        guard let parsed = parseAWSCredentials(
            content: content,
            profileName: profileName
        ) else {
            throw AWSCostFetchError.credentialsNotFound(
                "No credentials for profile '\(profileName)' in ~/.aws/credentials."
            )
        }
        return AWSCredentialIdentity(
            accessKey: parsed.accessKeyId,
            secret: parsed.secretAccessKey,
            sessionToken: parsed.sessionToken
        )
    }

    private func ssoCredentials(
        _ ref: SSOProfileRef
    ) async throws -> AWSCredentialIdentity {
        let sessionLabel = ref.sessionName ?? ref.startUrl
        guard let token = await ssoTokens.token(forKey: ref.cacheKey) else {
            throw AWSCostFetchError.ssoNotLoggedIn(session: sessionLabel)
        }
        guard !token.isExpired else {
            throw AWSCostFetchError.ssoSessionExpired(session: sessionLabel)
        }
        return try await ssoRoles.fetch(
            accessToken: token.accessToken,
            accountId: ref.accountId,
            roleName: ref.roleName,
            region: ref.ssoRegion
        )
    }
}
