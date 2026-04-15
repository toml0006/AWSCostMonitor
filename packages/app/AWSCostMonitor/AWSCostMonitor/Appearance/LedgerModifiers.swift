import SwiftUI

private struct LedgerAppearanceKey: EnvironmentKey {
    static let defaultValue: LedgerAppearance = .default
}

extension EnvironmentValues {
    var ledgerAppearance: LedgerAppearance {
        get { self[LedgerAppearanceKey.self] }
        set { self[LedgerAppearanceKey.self] = newValue }
    }
}

enum LedgerSurface { case window, elevated }

struct LedgerSurfaceModifier: ViewModifier {
    let surface: LedgerSurface
    @Environment(\.ledgerAppearance) private var a
    func body(content: Content) -> some View {
        content.background(
            surface == .window
                ? LedgerTokens.Color.surfaceWindow(a)
                : LedgerTokens.Color.surfaceElevated(a)
        )
    }
}

struct LedgerHairlineDivider: View {
    @Environment(\.ledgerAppearance) private var a
    var body: some View {
        Rectangle()
            .fill(LedgerTokens.Color.surfaceHairline(a))
            .frame(height: LedgerTokens.Layout.hairlineWidth(a))
    }
}

extension View {
    func ledgerSurface(_ s: LedgerSurface) -> some View {
        modifier(LedgerSurfaceModifier(surface: s))
    }

    func ledgerHero() -> some View {
        modifier(FontModifier(kind: .hero, color: .accent))
    }
    func ledgerStatValue() -> some View {
        modifier(FontModifier(kind: .statValue, color: .inkPrimary))
    }
    func ledgerLabel() -> some View {
        modifier(FontModifier(kind: .label, color: .inkTertiary))
            .textCase(.uppercase)
            .tracking(0.12 * 10)
    }
    func ledgerBody() -> some View {
        modifier(FontModifier(kind: .body, color: .inkSecondary))
    }
    func ledgerMeta() -> some View {
        modifier(FontModifier(kind: .meta, color: .inkTertiary))
    }
}

private enum TokenColorKind { case accent, inkPrimary, inkSecondary, inkTertiary }
private enum TokenFontKind { case hero, statValue, label, body, meta }

private struct FontModifier: ViewModifier {
    let kind: TokenFontKind
    let color: TokenColorKind
    @Environment(\.ledgerAppearance) private var a
    func body(content: Content) -> some View {
        let font: Font = {
            switch kind {
            case .hero:      return LedgerTokens.Typography.hero(a)
            case .statValue: return LedgerTokens.Typography.statValue(a)
            case .label:     return LedgerTokens.Typography.label(a)
            case .body:      return LedgerTokens.Typography.body(a)
            case .meta:      return LedgerTokens.Typography.meta(a)
            }
        }()
        let fg: SwiftUI.Color = {
            switch color {
            case .accent:        return LedgerTokens.Color.accent(a)
            case .inkPrimary:    return LedgerTokens.Color.inkPrimary(a)
            case .inkSecondary:  return LedgerTokens.Color.inkSecondary(a)
            case .inkTertiary:   return LedgerTokens.Color.inkTertiary(a)
            }
        }()
        content
            .font(font)
            .foregroundColor(fg)
            .monospacedDigit()
    }
}
