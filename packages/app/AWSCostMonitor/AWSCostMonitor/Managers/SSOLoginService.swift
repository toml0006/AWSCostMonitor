//
//  SSOLoginService.swift
//  AWSCostMonitor
//
//  OIDC device-authorization flow. The sandbox forbids shelling out to the AWS
//  CLI, so signing in has to happen in-process: register a public client, start
//  a device authorization, open the browser, then poll for the token.
//

import Foundation
import AppKit
import AWSSSOOIDC

enum SSOLoginError: LocalizedError {
    case timedOut
    case cancelled
    case serviceRejected(String)

    var errorDescription: String? {
        switch self {
        case .timedOut:
            return "Sign-in timed out. Try again."
        case .cancelled:
            return "Sign-in cancelled."
        case .serviceRejected(let reason):
            return "AWS rejected the sign-in: \(reason)"
        }
    }
}

@MainActor
final class SSOLoginService: ObservableObject {
    /// Shown to the user so they can confirm the browser page matches.
    @Published private(set) var userCode: String?
    @Published private(set) var isSigningIn = false

    private let store: SSOTokenStore
    private var cancelled = false

    nonisolated init(store: SSOTokenStore = SSOTokenStore()) {
        self.store = store
    }

    func cancel() {
        cancelled = true
    }

    func signIn(session: SSOSession) async throws -> SSOToken {
        isSigningIn = true
        cancelled = false
        defer {
            isSigningIn = false
            userCode = nil
        }

        let config = try await SSOOIDCClient.SSOOIDCClientConfiguration(
            region: session.ssoRegion
        )
        let client = SSOOIDCClient(config: config)
        let registration = try await registration(
            for: session,
            client: client
        )

        let authorization = try await client.startDeviceAuthorization(
            input: StartDeviceAuthorizationInput(
                clientId: registration.clientId,
                clientSecret: registration.clientSecret,
                startUrl: session.startUrl
            )
        )

        guard let deviceCode = authorization.deviceCode,
              let verificationURL = authorization.verificationUriComplete
                .flatMap(URL.init(string:)) else {
            throw SSOLoginError.serviceRejected(
                "StartDeviceAuthorization returned no device code."
            )
        }
        userCode = authorization.userCode
        NSWorkspace.shared.open(verificationURL)

        // The service dictates the poll rate; ignoring it earns
        // SlowDownException.
        var interval = TimeInterval(
            authorization.interval > 0 ? authorization.interval : 5
        )
        let authorizationLifetime = TimeInterval(
            authorization.expiresIn > 0 ? authorization.expiresIn : 600
        )
        let deadline = Date().addingTimeInterval(authorizationLifetime)

        while Date() < deadline {
            if cancelled {
                throw SSOLoginError.cancelled
            }
            try await Task.sleep(
                nanoseconds: UInt64(interval * 1_000_000_000)
            )

            do {
                let output = try await client.createToken(
                    input: CreateTokenInput(
                        clientId: registration.clientId,
                        clientSecret: registration.clientSecret,
                        deviceCode: deviceCode,
                        grantType: "urn:ietf:params:oauth:grant-type:device_code"
                    )
                )
                guard let accessToken = output.accessToken else {
                    throw SSOLoginError.serviceRejected(
                        "CreateToken returned no access token."
                    )
                }
                let lifetime = TimeInterval(
                    output.expiresIn > 0 ? output.expiresIn : 28_800
                )
                let token = SSOToken(
                    accessToken: accessToken,
                    expiresAt: Date().addingTimeInterval(lifetime),
                    region: session.ssoRegion,
                    startUrl: session.startUrl,
                    refreshToken: output.refreshToken,
                    clientId: registration.clientId,
                    clientSecret: registration.clientSecret
                )
                try store.save(token, forKey: session.name)
                return token
            } catch is AuthorizationPendingException {
                continue
            } catch is SlowDownException {
                interval += 5
            } catch let error as ExpiredTokenException {
                throw SSOLoginError.serviceRejected(
                    error.message
                        ?? error.properties.error_description
                        ?? "device code expired"
                )
            }
        }
        throw SSOLoginError.timedOut
    }

    /// Renew an expired token without user interaction. This requires both the
    /// refresh token and the client registration that minted it.
    func refresh(
        session: SSOSession,
        token: SSOToken
    ) async throws -> SSOToken {
        guard let refreshToken = token.refreshToken,
              let clientId = token.clientId,
              let clientSecret = token.clientSecret else {
            throw AWSCostFetchError.ssoSessionExpired(session: session.name)
        }

        let config = try await SSOOIDCClient.SSOOIDCClientConfiguration(
            region: session.ssoRegion
        )
        let client = SSOOIDCClient(config: config)
        let output = try await client.createToken(
            input: CreateTokenInput(
                clientId: clientId,
                clientSecret: clientSecret,
                grantType: "refresh_token",
                refreshToken: refreshToken
            )
        )
        guard let accessToken = output.accessToken else {
            throw AWSCostFetchError.ssoSessionExpired(session: session.name)
        }
        let lifetime = TimeInterval(
            output.expiresIn > 0 ? output.expiresIn : 28_800
        )
        let renewed = SSOToken(
            accessToken: accessToken,
            expiresAt: Date().addingTimeInterval(lifetime),
            region: session.ssoRegion,
            startUrl: session.startUrl,
            // The service may rotate the refresh token.
            refreshToken: output.refreshToken ?? refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        )
        try store.save(renewed, forKey: session.name)
        return renewed
    }

    /// Registrations last roughly 90 days; reuse one until it expires.
    private func registration(
        for session: SSOSession,
        client: SSOOIDCClient
    ) async throws -> OIDCRegistration {
        if let existing = store.registration(forKey: session.name) {
            return existing
        }

        let output = try await client.registerClient(
            input: RegisterClientInput(
                clientName: "AWSCostMonitor",
                clientType: "public",
                scopes: session.scopes.isEmpty
                    ? ["sso:account:access"]
                    : session.scopes
            )
        )
        guard let clientId = output.clientId,
              let clientSecret = output.clientSecret else {
            throw SSOLoginError.serviceRejected(
                "RegisterClient returned no client credentials."
            )
        }
        let expiration = output.clientSecretExpiresAt > 0
            ? Date(
                timeIntervalSince1970: TimeInterval(
                    output.clientSecretExpiresAt
                )
            )
            : Date().addingTimeInterval(80 * 86_400)
        let registration = OIDCRegistration(
            clientId: clientId,
            clientSecret: clientSecret,
            expiresAt: expiration
        )
        try store.saveRegistration(registration, forKey: session.name)
        return registration
    }
}
