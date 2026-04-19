import XCTest
import SwiftUI
@testable import AWSCostMonitor

@MainActor
final class AppearanceManagerTests: XCTestCase {
    private let suiteName = "AppearanceManagerTests"
    var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testDefaultsWhenNoPreferencesStored() {
        let mgr = AppearanceManager(defaults: defaults, systemIsDark: { true })
        XCTAssertEqual(mgr.appearance.colorScheme, .dark)
        XCTAssertEqual(mgr.appearance.accent, .amber)
        XCTAssertEqual(mgr.appearance.density, .comfortable)
        XCTAssertEqual(mgr.appearance.contrast, .standard)
    }

    func testAccentPersistsAcrossInstances() {
        let a = AppearanceManager(defaults: defaults, systemIsDark: { true })
        a.setAccent(.mint)
        let b = AppearanceManager(defaults: defaults, systemIsDark: { true })
        XCTAssertEqual(b.appearance.accent, .mint)
    }

    func testDensityAndContrastPersist() {
        let a = AppearanceManager(defaults: defaults, systemIsDark: { true })
        a.setDensity(.compact)
        a.setContrast(.aaa)
        let b = AppearanceManager(defaults: defaults, systemIsDark: { true })
        XCTAssertEqual(b.appearance.density, .compact)
        XCTAssertEqual(b.appearance.contrast, .aaa)
    }

    func testSchemeOverrideAlwaysLight() {
        let mgr = AppearanceManager(defaults: defaults, systemIsDark: { true })
        mgr.setSchemePreference(.light)
        XCTAssertEqual(mgr.appearance.colorScheme, .light)
    }

    func testSchemeOverrideAlwaysDark() {
        let mgr = AppearanceManager(defaults: defaults, systemIsDark: { false })
        mgr.setSchemePreference(.dark)
        XCTAssertEqual(mgr.appearance.colorScheme, .dark)
    }

    func testSchemeFollowsSystemWhenPreferenceIsSystem() {
        var systemDark = true
        let mgr = AppearanceManager(defaults: defaults, systemIsDark: { systemDark })
        mgr.setSchemePreference(.system)
        XCTAssertEqual(mgr.appearance.colorScheme, .dark)

        systemDark = false
        mgr.systemAppearanceDidChange()
        XCTAssertEqual(mgr.appearance.colorScheme, .light)
    }

    func testMigratesLegacyTerminalThemeOnce() {
        defaults.set("terminal", forKey: "selectedTheme")
        let a = AppearanceManager(defaults: defaults, systemIsDark: { true })
        a.runLegacyMigrationIfNeeded()
        XCTAssertEqual(a.appearance.accent, .mint)
        XCTAssertEqual(a.appearance.density, .compact)
        XCTAssertTrue(defaults.bool(forKey: "ledger.migrated"))
    }

    func testMigrationIsIdempotent() {
        defaults.set("terminal", forKey: "selectedTheme")
        let a = AppearanceManager(defaults: defaults, systemIsDark: { true })
        a.runLegacyMigrationIfNeeded()
        a.setAccent(.bone)                  // user changes accent after migration
        a.runLegacyMigrationIfNeeded()      // should NOT re-run
        XCTAssertEqual(a.appearance.accent, .bone)
    }
}
