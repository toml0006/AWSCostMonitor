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
