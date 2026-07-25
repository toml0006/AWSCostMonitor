//
//  CredentialAdapters.swift
//  AWSCostMonitor
//
//  Production wiring for CredentialResolver's seams. Kept separate so the
//  resolver's tests never reach the network.
//

import Foundation
import AWSSSO
import AWSSTS
import AWSSDKIdentity
import SmithyIdentity

/// Reads the AWS CLI's on-disk token cache.
struct CLITokenStore: SSOTokenProviding {
    func token(forKey key: String) async -> SSOToken? {
        SSOTokenCache.readCLIToken(forKey: key)
    }
}

/// Prefer a token this app minted; fall back to one the AWS CLI wrote. Either
/// direction of "who signed in last" then works, without writing the CLI cache.
/// Task 13 replaces this with an injectable, refresh-aware version.
struct LayeredTokenStore: SSOTokenProviding {
    let keychain = SSOTokenStore()
    let cli = CLITokenStore()

    func token(forKey key: String) async -> SSOToken? {
        if let mine = await keychain.token(forKey: key), !mine.isExpired {
            return mine
        }
        if let theirs = await cli.token(forKey: key), !theirs.isExpired {
            return theirs
        }

        // Both stale: return whichever exists so the caller can report expired
        // rather than never signed in, which implies different user action.
        if let mine = await keychain.token(forKey: key) {
            return mine
        }
        return await cli.token(forKey: key)
    }
}

struct LiveSSORoleFetcher: SSORoleCredentialsFetching {
    func fetch(
        accessToken: String,
        accountId: String,
        roleName: String,
        region: String
    ) async throws -> AWSCredentialIdentity {
        let config = try await SSOClient.SSOClientConfiguration(region: region)
        let client = SSOClient(config: config)
        let output = try await client.getRoleCredentials(
            input: GetRoleCredentialsInput(
                accessToken: accessToken,
                accountId: accountId,
                roleName: roleName
            )
        )
        guard let credentials = output.roleCredentials,
              let accessKey = credentials.accessKeyId,
              let secret = credentials.secretAccessKey else {
            throw AWSCostFetchError.credentialsNotFound(
                "GetRoleCredentials returned no credentials for \(roleName)@\(accountId)."
            )
        }

        // The IAM Identity Center Portal API returns Unix epoch milliseconds.
        let expiration = Date(
            timeIntervalSince1970: Double(credentials.expiration) / 1_000
        )
        return AWSCredentialIdentity(
            accessKey: accessKey,
            secret: secret,
            expiration: expiration,
            sessionToken: credentials.sessionToken
        )
    }
}

struct LiveSTSAssumer: STSAssuming {
    func assume(
        roleArn: String,
        sessionName: String,
        region: String,
        using source: AWSCredentialIdentity
    ) async throws -> AWSCredentialIdentity {
        let config = try await STSClient.STSClientConfiguration(
            awsCredentialIdentityResolver: StaticAWSCredentialIdentityResolver(source),
            region: region
        )
        let client = STSClient(config: config)
        let output = try await client.assumeRole(
            input: AssumeRoleInput(
                roleArn: roleArn,
                roleSessionName: sessionName
            )
        )
        guard let credentials = output.credentials,
              let accessKey = credentials.accessKeyId,
              let secret = credentials.secretAccessKey else {
            throw AWSCostFetchError.credentialsNotFound(
                "AssumeRole returned no credentials for \(roleArn)."
            )
        }
        return AWSCredentialIdentity(
            accessKey: accessKey,
            secret: secret,
            expiration: credentials.expiration,
            sessionToken: credentials.sessionToken
        )
    }
}
