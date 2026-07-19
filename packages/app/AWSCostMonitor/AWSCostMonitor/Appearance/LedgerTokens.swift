import SwiftUI
import AppKit

enum LedgerTokens {
    enum Color {
        static func surfaceWindow(_ a: LedgerAppearance) -> SwiftUI.Color {
            a.colorScheme == .dark ? .hex(0x0F1114) : .hex(0xFAF7F2)
        }
        static func surfaceElevated(_ a: LedgerAppearance) -> SwiftUI.Color {
            a.colorScheme == .dark ? .hex(0x14181E) : .hex(0xF1ECE1)
        }
        static func surfaceHairline(_ a: LedgerAppearance) -> SwiftUI.Color {
            a.colorScheme == .dark ? .hex(0x1C2026) : .hex(0xE5DDC9)
        }
        static func accent(_ a: LedgerAppearance) -> SwiftUI.Color {
            switch (a.accent, a.colorScheme) {
            case (.amber,  .dark):  return .hex(0xF5B454)
            case (.amber,  .light): return .hex(0x8A5A14)
            case (.mint,   .dark):  return .hex(0x4AD6A3)
            case (.mint,   .light): return .hex(0x1C7A57)
            case (.plasma, .dark):  return .hex(0x5AD9FF)
            case (.plasma, .light): return .hex(0x0B6A90)
            case (.bone,   .dark):  return .hex(0xE7E2D2)
            case (.bone,   .light): return .hex(0x4A443A)
            case (.spectrum, .dark):  return .hex(0xFF2D9B)
            case (.spectrum, .light): return .hex(0xB0186A)
            case (.system, _):      return SwiftUI.Color(nsColor: .controlAccentColor)
            }
        }
        /// Raw stops for the icon-matching Spectrum gradient, oldest→newest
        /// (left→right on the sparkline): the icon's rising line runs
        /// green → yellow → orange → hot-magenta.
        static let spectrumStops: [UInt32] = [0x5FE39A, 0xFFD84D, 0xF5A623, 0xFF2D9B]

        /// Multi-hue gradient stops for the Spectrum accent as SwiftUI colors,
        /// or `nil` for every other accent — callers fall back to the solid
        /// `accent()` fill.
        static func accentGradient(_ a: LedgerAppearance) -> [SwiftUI.Color]? {
            guard a.accent == .spectrum else { return nil }
            return spectrumStops.map { .hex($0) }
        }

        /// Samples the Spectrum gradient at `fraction` (0…1) by linearly
        /// interpolating RGB between adjacent stops. Used to color each
        /// sparkline bar by its position along the range.
        static func spectrumColor(at fraction: Double) -> SwiftUI.Color {
            let stops = spectrumStops
            let clamped = min(max(fraction, 0), 1)
            let scaled = clamped * Double(stops.count - 1)
            let lo = Int(scaled.rounded(.down))
            let hi = min(lo + 1, stops.count - 1)
            let t = scaled - Double(lo)
            func channel(_ hex: UInt32, _ shift: UInt32) -> Double {
                Double((hex >> shift) & 0xFF)
            }
            let r = channel(stops[lo], 16) + (channel(stops[hi], 16) - channel(stops[lo], 16)) * t
            let g = channel(stops[lo], 8)  + (channel(stops[hi], 8)  - channel(stops[lo], 8))  * t
            let b = channel(stops[lo], 0)  + (channel(stops[hi], 0)  - channel(stops[lo], 0))  * t
            return SwiftUI.Color(red: r / 255, green: g / 255, blue: b / 255)
        }
        static func signalOver(_ a: LedgerAppearance) -> SwiftUI.Color {
            if a.accent == .spectrum {
                return a.colorScheme == .dark ? .hex(0xFF3B6B) : .hex(0xC21F4E)
            }
            return a.colorScheme == .dark ? .hex(0xFF7A7A) : .hex(0xB02020)
        }
        static func signalUnder(_ a: LedgerAppearance) -> SwiftUI.Color {
            if a.accent == .spectrum {
                return a.colorScheme == .dark ? .hex(0x3DE8A0) : .hex(0x12875A)
            }
            return a.colorScheme == .dark ? .hex(0x4AD6A3) : .hex(0x2F9E6B)
        }
        static func inkPrimary(_ a: LedgerAppearance) -> SwiftUI.Color {
            a.colorScheme == .dark ? .hex(0xE7E9EC) : .hex(0x1B1A17)
        }
        static func inkSecondary(_ a: LedgerAppearance) -> SwiftUI.Color {
            a.colorScheme == .dark ? .hex(0xA8B1BD) : .hex(0x3A3731)
        }
        static func inkTertiary(_ a: LedgerAppearance) -> SwiftUI.Color {
            if a.contrast == .aaa {
                return inkSecondary(a)
            }
            return a.colorScheme == .dark ? .hex(0x7F8A99) : .hex(0x8A7F6C)
        }
    }

    enum Typography {
        static func heroPointSize(_ a: LedgerAppearance) -> CGFloat {
            a.density == .comfortable ? 34 : 28
        }
        static func statValuePointSize(_ a: LedgerAppearance) -> CGFloat {
            a.density == .comfortable ? 14 : 12
        }
        static func labelPointSize(_ a: LedgerAppearance) -> CGFloat { 10 }
        static func bodyPointSize(_ a: LedgerAppearance) -> CGFloat {
            a.density == .comfortable ? 13 : 12
        }
        static func metaPointSize(_ a: LedgerAppearance) -> CGFloat { 11 }

        static func hero(_ a: LedgerAppearance) -> Font {
            .system(size: heroPointSize(a), weight: .light, design: .monospaced)
        }
        static func statValue(_ a: LedgerAppearance) -> Font {
            .system(size: statValuePointSize(a), weight: .medium, design: .monospaced)
        }
        static func label(_ a: LedgerAppearance) -> Font {
            .system(size: labelPointSize(a), weight: .semibold, design: .default)
        }
        static func body(_ a: LedgerAppearance) -> Font {
            .system(size: bodyPointSize(a), weight: .regular, design: .default)
        }
        static func meta(_ a: LedgerAppearance) -> Font {
            .system(size: metaPointSize(a), weight: .regular, design: .default)
        }
    }

    enum Layout {
        static let cornerRadius: CGFloat = 10
        static func unit(_ a: LedgerAppearance) -> CGFloat {
            a.density == .comfortable ? 8 : 6
        }
        static func rowHeight(_ a: LedgerAppearance) -> CGFloat {
            a.density == .comfortable ? 32 : 26
        }
        static func hairlineWidth(_ a: LedgerAppearance) -> CGFloat { 1 }
    }
}

extension SwiftUI.Color {
    static func hex(_ value: UInt32) -> SwiftUI.Color {
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8)  & 0xFF) / 255.0
        let b = Double( value        & 0xFF) / 255.0
        return SwiftUI.Color(red: r, green: g, blue: b)
    }
}
