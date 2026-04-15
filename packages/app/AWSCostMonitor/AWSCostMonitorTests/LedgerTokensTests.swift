import XCTest
import SwiftUI
@testable import AWSCostMonitor

final class LedgerTokensTests: XCTestCase {
    func testDefaultAppearance() {
        let a = LedgerAppearance.default
        XCTAssertEqual(a.accent, .amber)
        XCTAssertEqual(a.density, .comfortable)
        XCTAssertEqual(a.contrast, .standard)
    }

    func testAccentRawValues() {
        XCTAssertEqual(LedgerAccent.amber.rawValue, "amber")
        XCTAssertEqual(LedgerAccent.mint.rawValue, "mint")
        XCTAssertEqual(LedgerAccent.plasma.rawValue, "plasma")
        XCTAssertEqual(LedgerAccent.bone.rawValue, "bone")
    }

    func testSurfaceColorsDark() {
        let a = LedgerAppearance(colorScheme: .dark, accent: .amber, density: .comfortable, contrast: .standard)
        XCTAssertEqual(LedgerTokens.Color.surfaceWindow(a).nsHex, "0F1114")
        XCTAssertEqual(LedgerTokens.Color.surfaceElevated(a).nsHex, "14181E")
        XCTAssertEqual(LedgerTokens.Color.surfaceHairline(a).nsHex, "1C2026")
    }

    func testSurfaceColorsLight() {
        let a = LedgerAppearance(colorScheme: .light, accent: .amber, density: .comfortable, contrast: .standard)
        XCTAssertEqual(LedgerTokens.Color.surfaceWindow(a).nsHex, "FAF7F2")
        XCTAssertEqual(LedgerTokens.Color.surfaceElevated(a).nsHex, "F1ECE1")
        XCTAssertEqual(LedgerTokens.Color.surfaceHairline(a).nsHex, "E5DDC9")
    }
}

import AppKit
extension SwiftUI.Color {
    /// 6-char uppercase hex, no alpha. For test assertions only.
    var nsHex: String {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        let r = Int(round(ns.redComponent   * 255))
        let g = Int(round(ns.greenComponent * 255))
        let b = Int(round(ns.blueComponent  * 255))
        return String(format: "%02X%02X%02X", r, g, b)
    }
}
