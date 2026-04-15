import XCTest
import SwiftUI
@testable import AWSCostMonitor

final class LedgerTokensTests: XCTestCase {
    func testDefaultAppearance() {
        let a = LedgerAppearance.default
        XCTAssertEqual(a.accent, .amber)
        XCTAssertEqual(a.density, .comfortable)
        XCTAssertEqual(a.contrast, .standard)
    }

    func testAccentRawValues() {
        XCTAssertEqual(LedgerAccent.amber.rawValue, "amber")
        XCTAssertEqual(LedgerAccent.mint.rawValue, "mint")
        XCTAssertEqual(LedgerAccent.plasma.rawValue, "plasma")
        XCTAssertEqual(LedgerAccent.bone.rawValue, "bone")
    }
}
