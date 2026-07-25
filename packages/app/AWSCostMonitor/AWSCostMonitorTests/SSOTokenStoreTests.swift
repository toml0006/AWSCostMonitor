import XCTest
@testable import AWSCostMonitor

final class SSOTokenStoreTests: XCTestCase {

    private let key = "unit-test-session"
    private var store: SSOTokenStore {
        SSOTokenStore(service: "dev.middleout.AWSCostMonitor.tests")
    }

    override func tearDown() {
        try? store.delete(forKey: key)
        super.tearDown()
    }

    private func token(
        expiresIn: TimeInterval,
        access: String = "tok"
    ) -> SSOToken {
        SSOToken(
            accessToken: access,
            expiresAt: Date().addingTimeInterval(expiresIn),
            region: "us-east-1",
            startUrl: "https://x.awsapps.com/start",
            refreshToken: "rt",
            clientId: "cid",
            clientSecret: "cs"
        )
    }

    func testRoundTripsAToken() async throws {
        try store.save(token(expiresIn: 3600), forKey: key)
        let loaded = await store.token(forKey: key)
        XCTAssertEqual(loaded?.accessToken, "tok")
        XCTAssertEqual(loaded?.refreshToken, "rt")
        XCTAssertEqual(loaded?.region, "us-east-1")
    }

    func testOverwritesAnExistingToken() async throws {
        try store.save(
            token(expiresIn: 3600, access: "first"),
            forKey: key
        )
        try store.save(
            token(expiresIn: 3600, access: "second"),
            forKey: key
        )
        let loaded = await store.token(forKey: key)
        XCTAssertEqual(loaded?.accessToken, "second")
    }

    func testDeleteRemovesTheToken() async throws {
        try store.save(token(expiresIn: 3600), forKey: key)
        try store.delete(forKey: key)
        let loaded = await store.token(forKey: key)
        XCTAssertNil(loaded)
    }

    func testMissingKeyReturnsNil() async {
        let loaded = await store.token(forKey: "never-written")
        XCTAssertNil(loaded)
    }

    func testRegistrationRoundTrips() throws {
        let registration = OIDCRegistration(
            clientId: "cid",
            clientSecret: "cs",
            expiresAt: Date().addingTimeInterval(90 * 86400)
        )
        try store.saveRegistration(registration, forKey: key)
        let loaded = store.registration(forKey: key)
        XCTAssertEqual(loaded?.clientId, "cid")
        XCTAssertEqual(loaded?.clientSecret, "cs")
    }

    func testExpiredRegistrationIsNotReturned() throws {
        let registration = OIDCRegistration(
            clientId: "cid",
            clientSecret: "cs",
            expiresAt: Date().addingTimeInterval(-1)
        )
        try store.saveRegistration(registration, forKey: key)
        XCTAssertNil(
            store.registration(forKey: key),
            "an expired client registration must be re-created, not reused"
        )
    }
}
