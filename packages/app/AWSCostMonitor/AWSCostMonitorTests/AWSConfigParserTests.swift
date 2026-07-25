import XCTest
@testable import AWSCostMonitor

final class AWSConfigParserTests: XCTestCase {

    /// Mirrors the shape of a real multi-account config: an sso-session block,
    /// session-based SSO profiles, a legacy inline SSO profile, assume-role
    /// chains, a credential_process profile, and a bare [default].
    private let fixture = """
    [default]
    region = us-east-1

    [sso-session ams]
    sso_start_url = https://d-906674c76d.awsapps.com/start
    sso_region = us-east-1
    sso_registration_scopes = sso:account:access

    [profile ams-mgmt]
    sso_session = ams
    sso_account_id = 138893339616
    sso_role_name = AdministratorAccess
    region = us-east-1

    [profile ams-dev]
    sso_session = ams
    sso_account_id = 350480401393
    sso_role_name = AdministratorAccess

    [profile legacy-sso]
    sso_start_url = https://legacy.awsapps.com/start
    sso_region = eu-west-1
    sso_account_id = 111122223333
    sso_role_name = ReadOnly

    [profile butler-production]
    role_arn = arn:aws:iam::920120424735:role/OrganizationAccountAccessRole
    source_profile = ams-mgmt
    region = us-east-1

    [profile mfa-protected]
    role_arn = arn:aws:iam::999988887777:role/Admin
    source_profile = ams-mgmt
    mfa_serial = arn:aws:iam::123456789012:mfa/jackson

    [profile via-process]
    credential_process = /opt/bin/mint-creds

    [profile dangling]
    sso_session = does-not-exist
    sso_account_id = 1
    sso_role_name = X

    [profile role-without-source]
    role_arn = arn:aws:iam::555555555555:role/Orphan

    [profile plain-keys]
    region = us-west-2

    [services my-services]
    cost_explorer =
      endpoint_url = https://example.invalid
    """

    private func parsed() -> ParsedAWSConfig {
        AWSConfigParser.parse(configContent: fixture)
    }

    // MARK: B2 regression

    func testSSOSessionSectionIsNotAProfile() {
        let names = parsed().profiles.map(\.name)
        XCTAssertFalse(names.contains("sso-session ams"))
        XCTAssertFalse(names.contains(where: { $0.hasPrefix("sso-session") }))
    }

    func testServicesSectionIsIgnored() {
        let names = parsed().profiles.map(\.name)
        XCTAssertFalse(names.contains(where: { $0.hasPrefix("services") }))
    }

    func testDefaultProfileIsIncludedUnprefixed() {
        XCTAssertTrue(parsed().profiles.map(\.name).contains("default"))
    }

    func testProfilePrefixIsStripped() {
        XCTAssertTrue(parsed().profiles.map(\.name).contains("ams-mgmt"))
        XCTAssertFalse(parsed().profiles.map(\.name).contains("profile ams-mgmt"))
    }

    // MARK: sso sessions

    func testSSOSessionIsParsed() {
        let session = parsed().ssoSessions["ams"]
        XCTAssertEqual(session?.startUrl, "https://d-906674c76d.awsapps.com/start")
        XCTAssertEqual(session?.ssoRegion, "us-east-1")
        XCTAssertEqual(session?.scopes, ["sso:account:access"])
    }

    // MARK: classification

    private func source(_ name: String) -> ProfileCredentialSource? {
        parsed().profiles.first(where: { $0.name == name })?.source
    }

    func testSessionBasedSSOProfileResolvesSessionFields() {
        guard case .sso(let ref)? = source("ams-mgmt") else {
            return XCTFail("expected .sso, got \(String(describing: source("ams-mgmt")))")
        }
        XCTAssertEqual(ref.sessionName, "ams")
        XCTAssertEqual(ref.startUrl, "https://d-906674c76d.awsapps.com/start")
        XCTAssertEqual(ref.ssoRegion, "us-east-1")
        XCTAssertEqual(ref.accountId, "138893339616")
        XCTAssertEqual(ref.roleName, "AdministratorAccess")
    }

    func testLegacyInlineSSOProfileHasNoSessionName() {
        guard case .sso(let ref)? = source("legacy-sso") else {
            return XCTFail("expected .sso")
        }
        XCTAssertNil(ref.sessionName)
        XCTAssertEqual(ref.startUrl, "https://legacy.awsapps.com/start")
        XCTAssertEqual(ref.ssoRegion, "eu-west-1")
    }

    func testAssumeRoleProfileCarriesSourceProfile() {
        guard case .assumeRole(let roleArn, let sourceProfile, let mfa)? = source("butler-production") else {
            return XCTFail("expected .assumeRole")
        }
        XCTAssertEqual(roleArn, "arn:aws:iam::920120424735:role/OrganizationAccountAccessRole")
        XCTAssertEqual(sourceProfile, "ams-mgmt")
        XCTAssertNil(mfa)
    }

    func testAssumeRoleProfileCarriesMFASerialWhenPresent() {
        guard case .assumeRole(_, _, let mfa)? = source("mfa-protected") else {
            return XCTFail("expected .assumeRole")
        }
        XCTAssertEqual(mfa, "arn:aws:iam::123456789012:mfa/jackson")
    }

    func testCredentialProcessIsUnsupported() {
        guard case .unsupported? = source("via-process") else {
            return XCTFail("expected .unsupported")
        }
    }

    func testDanglingSSOSessionReferenceIsUnsupported() {
        guard case .unsupported? = source("dangling") else {
            return XCTFail("expected .unsupported")
        }
    }

    func testRoleArnWithoutSourceProfileIsUnsupported() {
        guard case .unsupported? = source("role-without-source") else {
            return XCTFail("expected .unsupported")
        }
    }

    func testProfileWithNoCredentialHintsIsStaticKeys() {
        guard case .staticKeys? = source("plain-keys") else {
            return XCTFail("expected .staticKeys")
        }
    }

    func testRegionIsCarried() {
        let profiles = parsed().profiles
        XCTAssertEqual(profiles.first(where: { $0.name == "ams-mgmt" })?.region, "us-east-1")
        XCTAssertNil(profiles.first(where: { $0.name == "ams-dev" })?.region)
    }

    // MARK: robustness

    func testCommentsAndBlankLinesAreIgnored() {
        let content = """
        # leading comment
        [profile a]
        ; semicolon comment
        region = us-east-1

        """
        let result = AWSConfigParser.parse(configContent: content)
        XCTAssertEqual(result.profiles.count, 1)
        XCTAssertEqual(result.profiles[0].region, "us-east-1")
    }

    func testValuesContainingEqualsAreNotTruncated() {
        let content = """
        [sso-session s]
        sso_start_url = https://example.com/start?foo=bar
        sso_region = us-east-1
        """
        XCTAssertEqual(
            AWSConfigParser.parse(configContent: content).ssoSessions["s"]?.startUrl,
            "https://example.com/start?foo=bar"
        )
    }

    func testEmptyConfigProducesNothing() {
        let result = AWSConfigParser.parse(configContent: "")
        XCTAssertTrue(result.profiles.isEmpty)
        XCTAssertTrue(result.ssoSessions.isEmpty)
    }

    /// The phantom-profile bug as it appeared to the user: an sso-session block
    /// showing up as a selectable profile in the picker.
    func testRealisticConfigYieldsOnlyRealProfileNames() {
        let names = Set(parsed().profiles.map(\.name))
        XCTAssertEqual(names, [
            "default", "ams-mgmt", "ams-dev", "legacy-sso", "butler-production",
            "mfa-protected", "via-process", "dangling", "role-without-source", "plain-keys",
        ])
    }

    /// AWSManager retains the richer classified config for credential resolution
    /// while continuing to expose AWSProfile values to the existing picker.
    func testAWSManagerStoresClassifiedProfileData() {
        func assertStorageTypes(
            _ profiles: ReferenceWritableKeyPath<AWSManager, [String: AWSProfileConfig]>,
            _ sessions: ReferenceWritableKeyPath<AWSManager, [String: SSOSession]>
        ) {
            XCTAssertEqual(profiles, \AWSManager.profileConfigs)
            XCTAssertEqual(sessions, \AWSManager.ssoSessions)
        }

        assertStorageTypes(
            \AWSManager.profileConfigs,
            \AWSManager.ssoSessions
        )
    }
}
