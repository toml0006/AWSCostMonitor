//
//  PopoverSizing.swift
//  AWSCostMonitor
//
//  Pure geometry for placing the menu bar popover, plus the observable channel
//  the status bar controller uses to publish the current screen constraint.
//

import Foundation
import AppKit

enum PopoverGeometry {
    /// Below this the hero columns (two 210pt fixedSize columns in HeroSplit)
    /// overflow their parent frame, and SwiftUI does not clip overflow — which
    /// is what produced the "cut off on the right" report.
    static let minWidth: CGFloat = 500
    static let edgeMargin: CGFloat = 12

    /// Horizontal space a popover may occupy on a given screen.
    static func availableWidth(screenWidth: CGFloat) -> CGFloat {
        screenWidth - 2 * edgeMargin
    }

    /// Width the content wants, floored at `minWidth` and capped to what the
    /// screen allows. The cap wins only on displays too narrow for both.
    /// Deliberately takes no status-item position: the popover is moved to fit,
    /// never shrunk to fit.
    static func clampedWidth(desired: CGFloat, availableWidth: CGFloat) -> CGFloat {
        min(max(desired, minWidth), availableWidth)
    }

    /// Origin.x that keeps `width` fully on screen, preferring `idealX`.
    /// When the frame cannot fit at all, the left edge wins.
    static func clampedOriginX(idealX: CGFloat, width: CGFloat, visible: NSRect) -> CGFloat {
        let maxX = visible.maxX - edgeMargin - width
        let minX = visible.minX + edgeMargin
        return max(minX, min(idealX, maxX))
    }
}

/// Synchronous replacement for the old UserDefaults width key. UserDefaults →
/// @AppStorage → SwiftUI relayout is asynchronous, while NSPopover measures its
/// content synchronously inside show(), so the old channel let a given show use
/// the previous show's width.
@MainActor
final class PopoverSizing: ObservableObject {
    @Published var availableWidth: CGFloat = .greatestFiniteMagnitude
}
