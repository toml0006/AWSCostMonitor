import SwiftUI
import AppKit
import Combine

@MainActor
final class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()

    @Published private(set) var appearance: LedgerAppearance

    private let defaults: UserDefaults
    private let systemIsDark: () -> Bool

    private enum Keys {
        static let scheme   = "ledger.schemePreference"
        static let accent   = "ledger.accent"
        static let density  = "ledger.density"
        static let contrast = "ledger.contrast"
    }

    private(set) var schemePreference: LedgerSchemePreference

    init(defaults: UserDefaults = .standard, systemIsDark: @escaping () -> Bool = {
        NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }) {
        self.defaults = defaults
        self.systemIsDark = systemIsDark

        let scheme   = LedgerSchemePreference(rawValue: defaults.string(forKey: Keys.scheme)   ?? "") ?? .system
        let accent   = LedgerAccent(rawValue:           defaults.string(forKey: Keys.accent)   ?? "") ?? .amber
        let density  = LedgerDensity(rawValue:          defaults.string(forKey: Keys.density)  ?? "") ?? .comfortable
        let contrast = LedgerContrast(rawValue:         defaults.string(forKey: Keys.contrast) ?? "") ?? .standard

        self.schemePreference = scheme
        self.appearance = LedgerAppearance(
            colorScheme: Self.resolve(scheme: scheme, systemIsDark: systemIsDark),
            accent: accent,
            density: density,
            contrast: contrast
        )
    }

    func setSchemePreference(_ p: LedgerSchemePreference) {
        schemePreference = p
        defaults.set(p.rawValue, forKey: Keys.scheme)
        appearance.colorScheme = Self.resolve(scheme: p, systemIsDark: systemIsDark)
    }

    func setAccent(_ v: LedgerAccent) {
        defaults.set(v.rawValue, forKey: Keys.accent)
        appearance.accent = v
    }

    func setDensity(_ v: LedgerDensity) {
        defaults.set(v.rawValue, forKey: Keys.density)
        appearance.density = v
    }

    func setContrast(_ v: LedgerContrast) {
        defaults.set(v.rawValue, forKey: Keys.contrast)
        appearance.contrast = v
    }

    /// Called by the app root when NSApp.effectiveAppearance publishes a change.
    func systemAppearanceDidChange() {
        guard schemePreference == .system else { return }
        appearance.colorScheme = Self.resolve(scheme: .system, systemIsDark: systemIsDark)
    }

    private static func resolve(scheme: LedgerSchemePreference, systemIsDark: () -> Bool) -> ColorScheme {
        switch scheme {
        case .system: return systemIsDark() ? .dark : .light
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

extension AppearanceManager {
    /// Migrates the user's previously-selected legacy theme id to the new axis tuple.
    /// Runs once; subsequent calls are no-ops.
    func runLegacyMigrationIfNeeded() {
        guard !defaults.bool(forKey: "ledger.migrated") else { return }
        let legacy = defaults.string(forKey: "selectedTheme")
        let mapped = LegacyThemeMigration.migrate(themeId: legacy)
        setAccent(mapped.accent)
        setDensity(mapped.density)
        setContrast(mapped.contrast)
        defaults.set(true, forKey: "ledger.migrated")
    }
}
