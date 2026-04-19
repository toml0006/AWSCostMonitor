import Foundation

struct MenuBarOptions {
    private let defaults: UserDefaults

    enum Keys {
        static let showDelta      = "menubar.showDelta"
        static let showSparkline  = "menubar.showSparkline"
        static let pillBackground = "menubar.pillBackground"
        static let hideCents      = "menubar.hideCents"
        static let autoAbbreviate = "menubar.autoAbbreviate"
    }

    var showDelta: Bool {
        get { defaults.bool(forKey: Keys.showDelta) }
        set { defaults.set(newValue, forKey: Keys.showDelta) }
    }
    var showSparkline: Bool {
        get { defaults.bool(forKey: Keys.showSparkline) }
        set { defaults.set(newValue, forKey: Keys.showSparkline) }
    }
    var pillBackground: Bool {
        get { defaults.bool(forKey: Keys.pillBackground) }
        set { defaults.set(newValue, forKey: Keys.pillBackground) }
    }
    var hideCents: Bool {
        get { defaults.bool(forKey: Keys.hideCents) }
        set { defaults.set(newValue, forKey: Keys.hideCents) }
    }
    var autoAbbreviate: Bool {
        get { defaults.bool(forKey: Keys.autoAbbreviate) }
        set { defaults.set(newValue, forKey: Keys.autoAbbreviate) }
    }

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
}
