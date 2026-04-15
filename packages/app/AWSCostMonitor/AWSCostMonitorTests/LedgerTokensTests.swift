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

    func testAccentAmberBothSchemes() {
        let d = LedgerAppearance(colorScheme: .dark,  accent: .amber, density: .comfortable, contrast: .standard)
        let l = LedgerAppearance(colorScheme: .light, accent: .amber, density: .comfortable, contrast: .standard)
        XCTAssertEqual(LedgerTokens.Color.accent(d).nsHex, "F5B454")
        XCTAssertEqual(LedgerTokens.Color.accent(l).nsHex, "8A5A14")
    }

    func testAccentMintBothSchemes() {
        let d = LedgerAppearance(colorScheme: .dark,  accent: .mint, density: .comfortable, contrast: .standard)
        let l = LedgerAppearance(colorScheme: .light, accent: .mint, density: .comfortable, contrast: .standard)
        XCTAssertEqual(LedgerTokens.Color.accent(d).nsHex, "4AD6A3")
        XCTAssertEqual(LedgerTokens.Color.accent(l).nsHex, "1C7A57")
    }

    func testAccentPlasmaBothSchemes() {
        let d = LedgerAppearance(colorScheme: .dark,  accent: .plasma, density: .comfortable, contrast: .standard)
        let l = LedgerAppearance(colorScheme: .light, accent: .plasma, density: .comfortable, contrast: .standard)
        XCTAssertEqual(LedgerTokens.Color.accent(d).nsHex, "5AD9FF")
        XCTAssertEqual(LedgerTokens.Color.accent(l).nsHex, "0B6A90")
    }

    func testAccentBoneBothSchemes() {
        let d = LedgerAppearance(colorScheme: .dark,  accent: .bone, density: .comfortable, contrast: .standard)
        let l = LedgerAppearance(colorScheme: .light, accent: .bone, density: .comfortable, contrast: .standard)
        XCTAssertEqual(LedgerTokens.Color.accent(d).nsHex, "E7E2D2")
        XCTAssertEqual(LedgerTokens.Color.accent(l).nsHex, "4A443A")
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
