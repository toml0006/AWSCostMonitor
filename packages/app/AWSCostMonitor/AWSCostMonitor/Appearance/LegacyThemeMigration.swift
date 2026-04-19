import Foundation

enum LegacyThemeMigration {
    struct Result: Equatable {
        var accent: LedgerAccent
        var density: LedgerDensity
        var contrast: LedgerContrast
    }

    static func migrate(themeId: String?) -> Result {
        switch themeId {
        case "highContrast"?:
            return .init(accent: .amber, density: .comfortable, contrast: .aaa)
        case "compact"?:
            return .init(accent: .amber, density: .compact, contrast: .standard)
        case "terminal"?:
            return .init(accent: .mint, density: .compact, contrast: .standard)
        case "professional"?:
            return .init(accent: .bone, density: .comfortable, contrast: .standard)
        default:
            // classic / modern / comfortable / memphis / unknown / nil
            return .init(accent: .amber, density: .comfortable, contrast: .standard)
        }
    }
}
