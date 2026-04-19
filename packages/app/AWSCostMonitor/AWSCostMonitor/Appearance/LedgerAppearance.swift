import SwiftUI

enum LedgerAccent: String, CaseIterable, Codable, Identifiable {
    case amber, mint, plasma, bone, system
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .amber:  return "Amber"
        case .mint:   return "Mint"
        case .plasma: return "Plasma"
        case .bone:   return "Bone"
        case .system: return "System"
        }
    }
}

enum LedgerDensity: String, CaseIterable, Codable, Identifiable {
    case comfortable, compact
    var id: String { rawValue }
    var displayName: String {
        self == .comfortable ? "Comfortable" : "Compact"
    }
}

enum LedgerContrast: String, CaseIterable, Codable, Identifiable {
    case standard, aaa
    var id: String { rawValue }
    var displayName: String {
        self == .standard ? "Standard" : "AAA"
    }
}

enum LedgerSchemePreference: String, CaseIterable, Codable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "Follow System"
        case .light:  return "Always Light"
        case .dark:   return "Always Dark"
        }
    }
}

struct LedgerAppearance: Equatable {
    var colorScheme: ColorScheme   // resolved value — never .system
    var accent: LedgerAccent
    var density: LedgerDensity
    var contrast: LedgerContrast

    static let `default` = LedgerAppearance(
        colorScheme: .dark,
        accent: .amber,
        density: .comfortable,
        contrast: .standard
    )
}
