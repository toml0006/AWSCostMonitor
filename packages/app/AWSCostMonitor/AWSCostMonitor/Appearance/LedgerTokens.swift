import SwiftUI

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
            }
        }
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
