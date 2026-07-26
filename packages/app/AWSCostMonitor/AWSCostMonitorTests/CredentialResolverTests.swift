import XCTest
import AWSSDKIdentity
import SmithyIdentity
@testable import AWSCostMonitor

// MARK: - Fakes

private actor FakeTokenStore: SSOTokenProviding {
    var tokens: [String: SSOToken]

    init(_ tokens: [String: SSOToken]) {
        self.tokens = tokens
    }

    func token(forKey key: String) async -> SSOToken? {
        tokens[key]
    }
}

private actor FakeRoleFetcher: SSORoleCredentialsFetching {
    private(set) var callCount = 0
    var expiry: Date

    init(expiry: Date) {
        self.expiry = expiry
    }

    func fetch(
        accessToken: String,
        accountId: String,
        roleName: String,
        region: String
    ) async throws -> AWSCredentialIdentity {
        callCount += 1
        return AWSCredentialIdentity(
            accessKey: "AK-\(accountId)",
            secret: "SK",
            expiration: expiry,
            sessionToken: "ST"
        )
    }

    func calls() -> Int {
        callCount
    }
}

private actor FakeAssumeRole: STSAssuming {
    private(set) var callCount = 0
    var expiry: Date

    init(expiry: Date) {
        self.expiry = expiry
    }

    func assume(
        roleArn: String,
        sessionName: String,
        region: String,
        using: AWSCredentialIdentity
    ) async throws -> AWSCredentialIdentity {
        callCount += 1
        return AWSCredentialIdentity(
            accessKey: "AK-assumed",
            secret: "SK",
            expiration: expiry,
            sessionToken: "ST"
        )
    }

    func calls() -> Int {
        callCount
    }
}

// MARK: - Tests

final class CredentialResolverTests: XCTestCase {

    private func liveToken() -> SSOToken {
        SSOToken(
            accessToken: "live",
            expiresAt: Date().addingTimeInterval(3600),
            region: "us-east-1",
            startUrl: nil,
            refreshToken: nil,
            clientId: nil,
            clientSecret: nil
        )
    }

    private func expiredToken() -> SSOToken {
        SSOToken(
            accessToken: "stale",
            expiresAt: Date().addingTimeInterval(-60),
            region: "us-east-1",
            startUrl: nil,
            refreshToken: nil,
            clientId: nil,
            clientSecret: nil
        )
    }

    private func ssoRef(_ account: String) -> SSOProfileRef {
        SSOProfileRef(
            sessionName: "ams",
            startUrl: "https://x.awsapps.com/start",
            ssoRegion: "us-east-1",
            accountId: account,
            roleName: "Admin"
        )
    }

    private func makeResolver(
        configs: [String: AWSProfileConfig],
        tokens: [String: SSOToken],
        roleExpiry: Date = Date().addingTimeInterval(3600),
        assumeExpiry: Date = Date().addingTimeInterval(3600)
    ) -> (CredentialResolver, FakeRoleFetcher, FakeAssumeRole) {
        let roles = FakeRoleFetcher(expiry: roleExpiry)
        let sts = FakeAssumeRole(expiry: assumeExpiry)
        let resolver = CredentialResolver(
            configs: configs,
            ssoTokens: FakeTokenStore(tokens),
            ssoRoles: roles,
            sts: sts
        )
        return (resolver, roles, sts)
    }

    // MARK: SSO

    func testSSOProfileResolvesViaGetRoleCredentials() async throws {
        let (resolver, roles, _) = makeResolver(
            configs: [
                "ams-dev": AWSProfileConfig(
                    name: "ams-dev",
                    region: "us-east-1",
                    source: .sso(ssoRef("111"))
                )
            ],
            tokens: ["ams": liveToken()]
        )

        _ = try await resolver.resolver(for: "ams-dev")

        let calls = await roles.calls()
        XCTAssertEqual(calls, 1)
    }

    func testMissingTokenThrowsNotLoggedIn() async {
        let (resolver, _, _) = makeResolver(
            configs: [
                "ams-dev": AWSProfileConfig(
                    name: "ams-dev",
                    region: nil,
                    source: .sso(ssoRef("111"))
                )
            ],
            tokens: [:]
        )

        await XCTAssertThrowsErrorAsync(
            try await resolver.resolver(for: "ams-dev")
        ) { error in
            guard case AWSCostFetchError.ssoNotLoggedIn(let session) = error else {
                return XCTFail("expected .ssoNotLoggedIn, got \(error)")
            }
            XCTAssertEqual(session, "ams")
        }
    }

    func testExpiredTokenThrowsSessionExpired() async {
        let (resolver, _, _) = makeResolver(
            configs: [
                "ams-dev": AWSProfileConfig(
                    name: "ams-dev",
                    region: nil,
                    source: .sso(ssoRef("111"))
                )
            ],
            tokens: ["ams": expiredToken()]
        )

        await XCTAssertThrowsErrorAsync(
            try await resolver.resolver(for: "ams-dev")
        ) { error in
            guard case AWSCostFetchError.ssoSessionExpired(let session) = error else {
                return XCTFail("expected .ssoSessionExpired, got \(error)")
            }
            XCTAssertEqual(session, "ams")
        }
    }

    // MARK: caching (DEC-002: never multiply API calls per refresh)

    func testCredentialsAreCachedUntilNearExpiry() async throws {
        let (resolver, roles, _) = makeResolver(
            configs: [
                "ams-dev": AWSProfileConfig(
                    name: "ams-dev",
                    region: nil,
                    source: .sso(ssoRef("111"))
                )
            ],
            tokens: ["ams": liveToken()]
        )

        for _ in 0..<5 {
            _ = try await resolver.resolver(for: "ams-dev")
        }

        let calls = await roles.calls()
        XCTAssertEqual(calls, 1, "5 call sites must share one GetRoleCredentials result")
    }

    func testNearlyExpiredCredentialsAreRefetched() async throws {
        let (resolver, roles, _) = makeResolver(
            configs: [
                "ams-dev": AWSProfileConfig(
                    name: "ams-dev",
                    region: nil,
                    source: .sso(ssoRef("111"))
                )
            ],
            tokens: ["ams": liveToken()],
            roleExpiry: Date().addingTimeInterval(60)
        )

        _ = try await resolver.resolver(for: "ams-dev")
        _ = try await resolver.resolver(for: "ams-dev")

        let calls = await roles.calls()
        XCTAssertEqual(calls, 2)
    }

    // MARK: assume-role

    func testAssumeRoleChainsThroughSourceProfile() async throws {
        let (resolver, roles, sts) = makeResolver(
            configs: [
                "ams-mgmt": AWSProfileConfig(
                    name: "ams-mgmt",
                    region: nil,
                    source: .sso(ssoRef("111"))
                ),
                "butler-production": AWSProfileConfig(
                    name: "butler-production",
                    region: "us-east-1",
                    source: .assumeRole(
                        roleArn: "arn:aws:iam::999:role/X",
                        sourceProfile: "ams-mgmt",
                        mfaSerial: nil
                    )
                ),
            ],
            tokens: ["ams": liveToken()]
        )

        _ = try await resolver.resolver(for: "butler-production")

        let roleCalls = await roles.calls()
        let stsCalls = await sts.calls()
        XCTAssertEqual(roleCalls, 1)
        XCTAssertEqual(stsCalls, 1)
    }

    func testCycleInSourceProfileChainIsRejected() async {
        let (resolver, _, _) = makeResolver(
            configs: [
                "a": AWSProfileConfig(
                    name: "a",
                    region: nil,
                    source: .assumeRole(
                        roleArn: "arn:a",
                        sourceProfile: "b",
                        mfaSerial: nil
                    )
                ),
                "b": AWSProfileConfig(
                    name: "b",
                    region: nil,
                    source: .assumeRole(
                        roleArn: "arn:b",
                        sourceProfile: "a",
                        mfaSerial: nil
                    )
                ),
            ],
            tokens: [:]
        )

        await XCTAssertThrowsErrorAsync(
            try await resolver.resolver(for: "a")
        ) { error in
            guard case AWSCostFetchError.unsupportedProfile(_, let reason) = error else {
                return XCTFail("expected .unsupportedProfile, got \(error)")
            }
            XCTAssertTrue(reason.lowercased().contains("cycle"))
        }
    }

    func testMFASerialIsRejectedWithAClearReason() async {
        let (resolver, _, _) = makeResolver(
            configs: [
                "src": AWSProfileConfig(
                    name: "src",
                    region: nil,
                    source: .sso(ssoRef("111"))
                ),
                "mfa": AWSProfileConfig(
                    name: "mfa",
                    region: nil,
                    source: .assumeRole(
                        roleArn: "arn:x",
                        sourceProfile: "src",
                        mfaSerial: "arn:aws:iam::1:mfa/u"
                    )
                ),
            ],
            tokens: ["ams": liveToken()]
        )

        await XCTAssertThrowsErrorAsync(
            try await resolver.resolver(for: "mfa")
        ) { error in
            guard case AWSCostFetchError.unsupportedProfile(_, let reason) = error else {
                return XCTFail("expected .unsupportedProfile, got \(error)")
            }
            XCTAssertTrue(reason.lowercased().contains("mfa"))
        }
    }

    func testUnknownProfileIsRejected() async {
        let (resolver, _, _) = makeResolver(configs: [:], tokens: [:])

        await XCTAssertThrowsErrorAsync(
            try await resolver.resolver(for: "nope")
        ) { error in
            guard case AWSCostFetchError.unsupportedProfile = error else {
                return XCTFail("expected .unsupportedProfile, got \(error)")
            }
        }
    }

    func testUnsupportedSourceIsRejectedWithItsReason() async {
        let (resolver, _, _) = makeResolver(
            configs: [
                "p": AWSProfileConfig(
                    name: "p",
                    region: nil,
                    source: .unsupported(
                        reason: "credential_process profiles are not supported."
                    )
                )
            ],
            tokens: [:]
        )

        await XCTAssertThrowsErrorAsync(
            try await resolver.resolver(for: "p")
        ) { error in
            guard case AWSCostFetchError.unsupportedProfile(_, let reason) = error else {
                return XCTFail("expected .unsupportedProfile, got \(error)")
            }
            XCTAssertTrue(reason.contains("credential_process"))
        }
    }
}

// MARK: - async throws assertion helper

func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ handler: (Error) -> Void
) async {
    do {
        _ = try await expression()
        XCTFail("expected an error but none was thrown", file: file, line: line)
    } catch {
        handler(error)
    }
}
