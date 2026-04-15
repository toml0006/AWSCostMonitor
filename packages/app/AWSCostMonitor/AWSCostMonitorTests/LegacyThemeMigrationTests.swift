import XCTest
@testable import AWSCostMonitor

final class LegacyThemeMigrationTests: XCTestCase {
    func testClassicMigratesToAmberComfortStandard() {
        let out = LegacyThemeMigration.migrate(themeId: "classic")
        XCTAssertEqual(out, .init(accent: .amber, density: .comfortable, contrast: .standard))
    }
    func testHighContrastMigratesToAAA() {
        let out = LegacyThemeMigration.migrate(themeId: "highContrast")
        XCTAssertEqual(out.contrast, .aaa)
    }
    func testCompactMigratesToCompactDensity() {
        let out = LegacyThemeMigration.migrate(themeId: "compact")
        XCTAssertEqual(out.density, .compact)
    }
    func testTerminalMigratesToMintCompact() {
        let out = LegacyThemeMigration.migrate(themeId: "terminal")
        XCTAssertEqual(out.accent, .mint)
        XCTAssertEqual(out.density, .compact)
    }
    func testProfessionalMigratesToBone() {
        let out = LegacyThemeMigration.migrate(themeId: "professional")
        XCTAssertEqual(out.accent, .bone)
    }
    func testMemphisMigratesToAmberComfort() {
        let out = LegacyThemeMigration.migrate(themeId: "memphis")
        XCTAssertEqual(out.accent, .amber)
        XCTAssertEqual(out.density, .comfortable)
    }
    func testUnknownIdFallsBackToDefaults() {
        let out = LegacyThemeMigration.migrate(themeId: "martian")
        XCTAssertEqual(out, .init(accent: .amber, density: .comfortable, contrast: .standard))
    }
    func testNilIdFallsBackToDefaults() {
        let out = LegacyThemeMigration.migrate(themeId: nil)
        XCTAssertEqual(out, .init(accent: .amber, density: .comfortable, contrast: .standard))
    }
}
