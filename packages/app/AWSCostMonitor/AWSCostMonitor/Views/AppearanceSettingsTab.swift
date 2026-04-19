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

    // Bind directly to UserDefaults so the toggles reflect persisted state
    // and re-render when changed.
    @AppStorage("menubar.showDelta")      private var showDelta: Bool = false
    @AppStorage("menubar.showSparkline")  private var showSparkline: Bool = false
    @AppStorage("menubar.pillBackground") private var pillBackground: Bool = false
    @AppStorage("menubar.hideCents")      private var rounding: Bool = false
    @AppStorage("menubar.autoAbbreviate") private var autoAbbreviate: Bool = false

    private func notifyMenuBarChanged() {
        NotificationCenter.default.post(name: .menuBarOptionsChanged, object: nil)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                section("Color scheme") {
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

                section("Accent") {
                    HStack(spacing: 12) {
                        ForEach(LedgerAccent.allCases) { accent in
                            Button {
                                appearance.setAccent(accent)
                            } label: {
                                AccentSwatch(accent: accent, selected: appearance.appearance.accent == accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                section("Density") {
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

                section("Contrast") {
                    Toggle("WCAG AAA contrast", isOn: Binding(
                        get: { appearance.appearance.contrast == .aaa },
                        set: { appearance.setContrast($0 ? .aaa : .standard) }
                    ))
                }

                section("Menubar") {
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Delta (↑ / ↓ %)", isOn: $showDelta)
                            .onChange(of: showDelta) { _, _ in notifyMenuBarChanged() }

                        Toggle("Sparkline", isOn: $showSparkline)
                            .onChange(of: showSparkline) { _, _ in notifyMenuBarChanged() }

                        Toggle("Background", isOn: $pillBackground)
                            .onChange(of: pillBackground) { _, _ in notifyMenuBarChanged() }
                    }
                }

                section("Currency") {
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Rounding", isOn: $rounding)
                            .onChange(of: rounding) { _, _ in notifyMenuBarChanged() }

                        Toggle("Abbreviate above $10k", isOn: $autoAbbreviate)
                            .onChange(of: autoAbbreviate) { _, _ in notifyMenuBarChanged() }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
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
