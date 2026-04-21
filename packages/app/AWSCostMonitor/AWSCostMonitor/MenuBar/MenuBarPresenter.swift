import AppKit

@MainActor
final class MenuBarPresenter {
    private let button: NSStatusBarButton

    init(button: NSStatusBarButton) {
        self.button = button
    }

    func render(
        amount: Double,
        delta: Double?,
        budgetUsed: Double,
        sparkline: [Double],
        sparklineHighlightIndex: Int? = nil,
        options: MenuBarOptions,
        accent: NSColor,
        overBudget: NSColor
    ) {
        let accentColor = budgetUsed > 1.0 ? overBudget : accent
        let isOver = budgetUsed > 1.0
        // Text color for non-pill rendering follows the system menubar color
        // (adapts to light/dark menubar automatically). Over-budget keeps its signal.
        let plainTextColor: NSColor = isOver ? overBudget : .labelColor
        let text = MenuBarFormatter.format(amount: amount, options: options, delta: delta)

        let needsImage = options.showSparkline || options.pillBackground
        if needsImage {
            let newImage: NSImage
            if options.pillBackground {
                // Solid themed chip with contrasting ink for readability.
                let pillFill = accentColor.withAlphaComponent(0.92)
                let pillInk = Self.contrastingInk(on: accentColor)
                newImage = Self.composeImage(
                    text: text,
                    textColor: pillInk,
                    sparkline: options.showSparkline ? sparkline : nil,
                    sparklineColor: pillInk,
                    sparklineHighlightIndex: sparklineHighlightIndex,
                    pillFill: pillFill
                )
            } else {
                // Sparkline only — text uses system menubar color, sparkline keeps accent.
                newImage = Self.composeImage(
                    text: text,
                    textColor: plainTextColor,
                    sparkline: sparkline,
                    sparklineColor: accentColor,
                    sparklineHighlightIndex: sparklineHighlightIndex,
                    pillFill: nil
                )
            }
            // Set end state without an intermediate `image = nil` / empty-title step.
            // Rapid back-to-back renders during theme changes were triggering a zombie
            // _NSWindowTransformAnimation release via the status-bar button's hosting
            // window — clearing and re-setting within the same runloop pass multiplied
            // the animations.
            if button.attributedTitle.length > 0 {
                button.attributedTitle = NSAttributedString()
            }
            if button.image !== newImage {
                button.image = newImage
            }
        } else {
            if button.image != nil {
                button.image = nil
            }
            button.attributedTitle = Self.attributedTitle(text, color: plainTextColor)
        }
    }

    /// Pick black or white based on the luminance of the given background color,
    /// so text on a themed pill stays legible across all accents.
    private static func contrastingInk(on background: NSColor) -> NSColor {
        let rgb = background.usingColorSpace(.sRGB) ?? background
        let r = rgb.redComponent
        let g = rgb.greenComponent
        let b = rgb.blueComponent
        // Relative luminance (WCAG)
        let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return lum > 0.55 ? NSColor(white: 0.08, alpha: 1.0) : NSColor(white: 0.98, alpha: 1.0)
    }

    private static func attributedTitle(_ s: String, color: NSColor) -> NSAttributedString {
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        return NSAttributedString(string: s, attributes: [
            .font: font,
            .foregroundColor: color,
        ])
    }

    private static func composeImage(
        text: String,
        textColor: NSColor,
        sparkline: [Double]?,
        sparklineColor: NSColor,
        sparklineHighlightIndex: Int?,
        pillFill: NSColor?
    ) -> NSImage {
        let weight: NSFont.Weight = pillFill != nil ? .semibold : .medium
        let fontSize: CGFloat = pillFill != nil ? 12 : 13
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: weight)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let textSize = (text as NSString).size(withAttributes: attrs)

        let sparkSize = NSSize(width: 60, height: 14)
        let gap: CGFloat = 6
        let padH: CGFloat = pillFill != nil ? 9 : 0
        let padV: CGFloat = pillFill != nil ? 2 : 0

        let contentWidth = ceil(textSize.width) + (sparkline != nil ? gap + sparkSize.width : 0)
        let contentHeight = max(ceil(textSize.height), sparkline != nil ? sparkSize.height : 0)
        let size = NSSize(width: contentWidth + padH * 2, height: contentHeight + padV * 2)

        // Use the drawing-handler initializer instead of lockFocus/unlockFocus —
        // it's safer for short-lived images built on the main runloop and avoids
        // retaining CA animation state between draws.
        return NSImage(size: size, flipped: false) { _ in
            if let pillFill {
                pillFill.setFill()
                NSBezierPath(roundedRect: NSRect(origin: .zero, size: size),
                             xRadius: size.height / 2,
                             yRadius: size.height / 2).fill()
            }

            let textOrigin = NSPoint(x: padH, y: padV + (contentHeight - textSize.height) / 2)
            (text as NSString).draw(at: textOrigin, withAttributes: attrs)

            if let sparkline {
                let sparkImage = MenuBarSparklineImage.render(
                    values: sparkline,
                    color: sparklineColor,
                    highlightIndex: sparklineHighlightIndex
                )
                let sparkOrigin = NSPoint(
                    x: padH + ceil(textSize.width) + gap,
                    y: padV + (contentHeight - sparkSize.height) / 2
                )
                sparkImage.draw(at: sparkOrigin, from: .zero, operation: .sourceOver, fraction: 1.0)
            }
            return true
        }
    }
}
