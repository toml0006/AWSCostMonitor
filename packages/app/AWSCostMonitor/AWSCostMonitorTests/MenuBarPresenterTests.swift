import XCTest
@testable import AWSCostMonitor

final class MenuBarPresenterTests: XCTestCase {
    private let suiteName = "MenuBarPresenterTests"
    var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testMenuBarOptionsDefaults() {
        let o = MenuBarOptions(defaults: defaults)
        XCTAssertEqual(o.preset, .iconFigure)
        XCTAssertFalse(o.hideCents)
        XCTAssertFalse(o.showDelta)
        XCTAssertFalse(o.autoAbbreviate)
    }

    func testMenuBarOptionsPersist() {
        var o = MenuBarOptions(defaults: defaults)
        o.preset = .pill
        o.hideCents = true
        o.showDelta = true
        o.autoAbbreviate = true
        let p = MenuBarOptions(defaults: defaults)
        XCTAssertEqual(p.preset, .pill)
        XCTAssertTrue(p.hideCents)
        XCTAssertTrue(p.showDelta)
        XCTAssertTrue(p.autoAbbreviate)
    }
}
