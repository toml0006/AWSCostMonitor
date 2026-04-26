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
        XCTAssertFalse(o.showSparkline)
        XCTAssertFalse(o.pillBackground)
        XCTAssertFalse(o.hideCents)
        XCTAssertFalse(o.showDelta)
        XCTAssertFalse(o.autoAbbreviate)
    }

    func testMenuBarOptionsPersist() {
        var o = MenuBarOptions(defaults: defaults)
        o.showSparkline = true
        o.pillBackground = true
        o.hideCents = true
        o.showDelta = true
        o.autoAbbreviate = true
        let p = MenuBarOptions(defaults: defaults)
        XCTAssertTrue(p.showSparkline)
        XCTAssertTrue(p.pillBackground)
        XCTAssertTrue(p.hideCents)
        XCTAssertTrue(p.showDelta)
        XCTAssertTrue(p.autoAbbreviate)
    }

    func testFormatter_defaultShowsCents() {
        let o = MenuBarOptions(defaults: defaults)
        XCTAssertEqual(MenuBarFormatter.format(amount: 2847.23, options: o), "$2,847.23")
    }
    func testFormatter_hideCents() {
        var o = MenuBarOptions(defaults: defaults); o.hideCents = true
        XCTAssertEqual(MenuBarFormatter.format(amount: 2847.23, options: o), "$2,847")
    }
    func testFormatter_autoAbbreviateAbove10k() {
        var o = MenuBarOptions(defaults: defaults); o.autoAbbreviate = true
        XCTAssertEqual(MenuBarFormatter.format(amount: 12400, options: o), "$12.4k")
        XCTAssertEqual(MenuBarFormatter.format(amount: 9999,  options: o), "$9,999.00")
    }
    func testFormatter_deltaAppendsSignedPct() {
        var o = MenuBarOptions(defaults: defaults); o.showDelta = true
        XCTAssertEqual(MenuBarFormatter.format(amount: 2847.23, options: o, delta: 0.124), "$2,847.23 ↑12.4%")
        XCTAssertEqual(MenuBarFormatter.format(amount: 2847.23, options: o, delta: -0.05), "$2,847.23 ↓5.0%")
    }
    func testFormatter_ignoresDeltaWhenShowDeltaOff() {
        let o = MenuBarOptions(defaults: defaults)
        XCTAssertEqual(MenuBarFormatter.format(amount: 100, options: o, delta: 0.5), "$100.00")
    }
}
