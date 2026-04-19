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

        // Reset
        button.image = nil
        button.attributedTitle = NSAttributedString(string: "")
        button.title = ""
        button.imagePosition = .noImage

        let needsImage = options.showSparkline || options.pillBackground
        if needsImage {
            if options.pillBackground {
                // Solid themed chip with contrasting ink for readability.
                let pillFill = accentColor.withAlphaComponent(0.92)
                let pillInk = Self.contrastingInk(on: accentColor)
                button.image = Self.composeImage(
                    text: text,
                    textColor: pillInk,
                    sparkline: options.showSparkline ? sparkline : nil,
                    sparklineColor: pillInk,
                    sparklineHighlightIndex: sparklineHighlightIndex,
                    pillFill: pillFill
                )
            } else {
                // Sparkline only — text uses system menubar color, sparkline keeps accent.
                button.image = Self.composeImage(
                    text: text,
                    textColor: plainTextColor,
                    sparkline: sparkline,
                    sparklineColor: accentColor,
                    sparklineHighlightIndex: sparklineHighlightIndex,
                    pillFill: nil
                )
            }
        } else {
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

        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

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

        return image
    }
}
