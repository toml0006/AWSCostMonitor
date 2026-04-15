import SwiftUI

struct AppearanceSettingsTab: View {
    @ObservedObject private var appearance = AppearanceManager.shared

    var body: some View {
        AppearanceSettingsContent()
            .environmentObject(appearance)
            .environment(\.ledgerAppearance, appearance.appearance)
    }
}

private struct AppearanceSettingsContent: View {
    @EnvironmentObject var appearance: AppearanceManager
    @State private var options = MenuBarOptions()

    var body: some View {
        Form {
            Section("Color scheme") {
                Picker("", selection: Binding(
                    get: { appearance.schemePreference },
                    set: { appearance.setSchemePreference($0) }
                )) {
                    ForEach(LedgerSchemePreference.allCases, id: \.self) { preference in
                        Text(preference.displayName).tag(preference)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Accent") {
                HStack(spacing: 12) {
                    ForEach(LedgerAccent.allCases) { accent in
                        AccentSwatch(accent: accent, selected: appearance.appearance.accent == accent)
                            .onTapGesture { appearance.setAccent(accent) }
                    }
                }
            }

            Section("Density") {
                Picker("", selection: Binding(
                    get: { appearance.appearance.density },
                    set: { appearance.setDensity($0) }
                )) {
                    ForEach(LedgerDensity.allCases, id: \.self) { density in
                        Text(density.displayName).tag(density)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Contrast") {
                Toggle("WCAG AAA contrast", isOn: Binding(
                    get: { appearance.appearance.contrast == .aaa },
                    set: { appearance.setContrast($0 ? .aaa : .standard) }
                ))
            }

            Section("Menu bar") {
                Picker("Presentation", selection: Binding(
                    get: { options.preset },
                    set: {
                        options.preset = $0
                        NotificationCenter.default.post(name: .menuBarOptionsChanged, object: nil)
                    }
                )) {
                    ForEach(MenuBarPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }

                Toggle("Hide cents", isOn: Binding(
                    get: { options.hideCents },
                    set: {
                        options.hideCents = $0
                        NotificationCenter.default.post(name: .menuBarOptionsChanged, object: nil)
                    }
                ))

                Toggle("Show delta (↑ / ↓ %)", isOn: Binding(
                    get: { options.showDelta },
                    set: {
                        options.showDelta = $0
                        NotificationCenter.default.post(name: .menuBarOptionsChanged, object: nil)
                    }
                ))

                Toggle("Auto-abbreviate above $10k", isOn: Binding(
                    get: { options.autoAbbreviate },
                    set: {
                        options.autoAbbreviate = $0
                        NotificationCenter.default.post(name: .menuBarOptionsChanged, object: nil)
                    }
                ))
            }
        }
        .padding(20)
        .ledgerSurface(.window)
    }
}

private struct AccentSwatch: View {
    @Environment(\.ledgerAppearance) private var appearance

    let accent: LedgerAccent
    let selected: Bool

    var body: some View {
        let previewAppearance = LedgerAppearance(
            colorScheme: appearance.colorScheme,
            accent: accent,
            density: appearance.density,
            contrast: appearance.contrast
        )

        return VStack(spacing: 6) {
            Circle()
                .fill(LedgerTokens.Color.accent(previewAppearance))
                .frame(width: 32, height: 32)
                .overlay(
                    Circle().stroke(
                        selected ? LedgerTokens.Color.inkPrimary(appearance) : .clear,
                        lineWidth: 2
                    )
                )

            Text(accent.displayName).ledgerMeta()
        }
    }
}

extension Notification.Name {
    static let menuBarOptionsChanged = Notification.Name("ledger.menuBarOptionsChanged")
}

#Preview {
    AppearanceSettingsTab()
        .frame(width: 600, height: 400)
}
