import XCTest
@testable import AWSCostMonitor

final class SSOTokenCacheTests: XCTestCase {

    // MARK: filename derivation

    /// SHA-1 of "ams", lowercase hex, with a .json suffix — the AWS CLI's scheme.
    /// STEP 2 BELOW COMPUTES THE EXPECTED DIGEST. Do not invent it; run the
    /// shasum command and paste the result here before running this test.
    func testCacheFileNameIsSHA1OfSessionName() {
        XCTAssertEqual(
            SSOTokenCache.cacheFileName(forKey: "ams"),
            "044a2f5446224495d6813d561c55539f695c57ce.json"
        )
    }

    func testCacheFileNameForStartURLDiffersFromSessionName() {
        let a = SSOTokenCache.cacheFileName(forKey: "ams")
        let b = SSOTokenCache.cacheFileName(forKey: "https://d-906674c76d.awsapps.com/start")
        XCTAssertNotEqual(a, b)
        XCTAssertTrue(b.hasSuffix(".json"))
        XCTAssertEqual(b.count, 40 + ".json".count)
    }

    func testCacheFileNameIsLowercaseHex() {
        let name = SSOTokenCache.cacheFileName(forKey: "Mixed-Case-Session")
        let stem = String(name.dropLast(".json".count))
        XCTAssertEqual(stem, stem.lowercased())
        XCTAssertTrue(stem.allSatisfy { $0.isHexDigit })
    }

    // MARK: decoding

    private func json(_ body: String) -> Data { Data(body.utf8) }

    func testDecodesFractionalSecondsExpiry() throws {
        let token = try SSOTokenCache.decode(json("""
        {"accessToken":"tok","expiresAt":"2026-07-25T18:30:00.123Z","region":"us-east-1"}
        """))
        XCTAssertEqual(token.accessToken, "tok")
        XCTAssertEqual(token.region, "us-east-1")
        XCTAssertEqual(token.expiresAt.timeIntervalSince1970, 1785004200, accuracy: 1)
    }

    func testDecodesWholeSecondsExpiry() throws {
        let token = try SSOTokenCache.decode(json("""
        {"accessToken":"tok","expiresAt":"2026-07-25T18:30:00Z"}
        """))
        XCTAssertEqual(token.expiresAt.timeIntervalSince1970, 1785004200, accuracy: 1)
    }

    func testDecodesUTCSuffixForm() throws {
        // Older CLI versions wrote this shape.
        let token = try SSOTokenCache.decode(json("""
        {"accessToken":"tok","expiresAt":"2026-07-25T18:30:00UTC"}
        """))
        XCTAssertEqual(token.expiresAt.timeIntervalSince1970, 1785004200, accuracy: 1)
    }

    func testDecodesOptionalRefreshFields() throws {
        let token = try SSOTokenCache.decode(json("""
        {"accessToken":"tok","expiresAt":"2026-07-25T18:30:00Z",
         "refreshToken":"rt","clientId":"cid","clientSecret":"cs",
         "startUrl":"https://example.awsapps.com/start"}
        """))
        XCTAssertEqual(token.refreshToken, "rt")
        XCTAssertEqual(token.clientId, "cid")
        XCTAssertEqual(token.clientSecret, "cs")
        XCTAssertEqual(token.startUrl, "https://example.awsapps.com/start")
    }

    func testMissingAccessTokenThrows() {
        XCTAssertThrowsError(try SSOTokenCache.decode(json("""
        {"expiresAt":"2026-07-25T18:30:00Z"}
        """)))
    }

    func testUnparseableExpiryThrows() {
        XCTAssertThrowsError(try SSOTokenCache.decode(json("""
        {"accessToken":"tok","expiresAt":"never"}
        """)))
    }

    // MARK: expiry

    func testTokenExpiringSoonCountsAsExpired() {
        // The 5-minute safety margin: a token valid for 60s must not be used,
        // or a refresh started now could outlive it mid-request.
        let token = SSOToken(accessToken: "t", expiresAt: Date().addingTimeInterval(60),
                             region: nil, startUrl: nil, refreshToken: nil,
                             clientId: nil, clientSecret: nil)
        XCTAssertTrue(token.isExpired)
    }

    func testTokenWithAmpleLifeIsNotExpired() {
        let token = SSOToken(accessToken: "t", expiresAt: Date().addingTimeInterval(3600),
                             region: nil, startUrl: nil, refreshToken: nil,
                             clientId: nil, clientSecret: nil)
        XCTAssertFalse(token.isExpired)
    }

    func testPastExpiryIsExpired() {
        let token = SSOToken(accessToken: "t", expiresAt: Date().addingTimeInterval(-1),
                             region: nil, startUrl: nil, refreshToken: nil,
                             clientId: nil, clientSecret: nil)
        XCTAssertTrue(token.isExpired)
    }
}
