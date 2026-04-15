import Foundation

enum MenuBarPreset: String, CaseIterable, Codable, Identifiable {
    case textOnly, iconFigure, pill, figureSparkline
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .textOnly:        return "Text only"
        case .iconFigure:      return "Icon + figure"
        case .pill:            return "Amber pill"
        case .figureSparkline: return "Figure + sparkline"
        }
    }
}

struct MenuBarOptions {
    private let defaults: UserDefaults

    private enum Keys {
        static let preset = "menubar.preset"
        static let hideCents = "menubar.hideCents"
        static let showDelta = "menubar.showDelta"
        static let autoAbbreviate = "menubar.autoAbbreviate"
    }

    var preset: MenuBarPreset {
        get { MenuBarPreset(rawValue: defaults.string(forKey: Keys.preset) ?? "") ?? .iconFigure }
        set { defaults.set(newValue.rawValue, forKey: Keys.preset) }
    }
    var hideCents: Bool {
        get { defaults.bool(forKey: Keys.hideCents) }
        set { defaults.set(newValue, forKey: Keys.hideCents) }
    }
    var showDelta: Bool {
        get { defaults.bool(forKey: Keys.showDelta) }
        set { defaults.set(newValue, forKey: Keys.showDelta) }
    }
    var autoAbbreviate: Bool {
        get { defaults.bool(forKey: Keys.autoAbbreviate) }
        set { defaults.set(newValue, forKey: Keys.autoAbbreviate) }
    }

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
}
