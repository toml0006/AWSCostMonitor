import AppKit

@MainActor
final class MenuBarPresenter {
    private let button: NSStatusBarButton
    private let templateIconName = "MenuBarLedgerMark"   // 16×16 template PDF in Assets

    init(button: NSStatusBarButton) {
        self.button = button
    }

    func render(
        amount: Double,
        delta: Double?,
        budgetUsed: Double,
        sparkline: [Double],
        options: MenuBarOptions,
        accent: NSColor,
        overBudget: NSColor
    ) {
        let color = budgetUsed > 1.0 ? overBudget : accent
        let text = MenuBarFormatter.format(amount: amount, options: options, delta: delta)

        // Reset
        button.image = nil
        button.attributedTitle = NSAttributedString(string: "")
        button.title = ""
        button.imagePosition = .noImage

        switch options.preset {
        case .textOnly:
            button.attributedTitle = Self.attributedTitle(text, color: color, pill: false)

        case .iconFigure:
            let icon = NSImage(named: templateIconName)
            icon?.isTemplate = true
            button.image = icon
            button.imagePosition = .imageLeft
            button.attributedTitle = Self.attributedTitle(text, color: color, pill: false)

        case .pill:
            button.image = Self.pillImage(text: text, fillColor: color.withAlphaComponent(0.14), textColor: color)

        case .figureSparkline:
            button.image = Self.sparklineImage(text: text, textColor: color, sparkline: sparkline)
        }
    }

    private static func attributedTitle(_ s: String, color: NSColor, pill: Bool) -> NSAttributedString {
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        return NSAttributedString(string: s, attributes: [
            .font: font,
            .foregroundColor: color,
        ])
    }

    private static func pillImage(text: String, fillColor: NSColor, textColor: NSColor) -> NSImage {
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let textSize = (text as NSString).size(withAttributes: attrs)
        let padH: CGFloat = 9, padV: CGFloat = 2
        let size = NSSize(width: ceil(textSize.width) + padH*2, height: ceil(textSize.height) + padV*2)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }
        fillColor.setFill()
        let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: size.height/2, yRadius: size.height/2)
        path.fill()
        (text as NSString).draw(at: NSPoint(x: padH, y: padV), withAttributes: attrs)
        return image
    }

    private static func sparklineImage(text: String, textColor: NSColor, sparkline: [Double]) -> NSImage {
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let textSize = (text as NSString).size(withAttributes: attrs)
        let gap: CGFloat = 6
        let sparkSize = NSSize(width: 60, height: 14)
        let size = NSSize(width: ceil(textSize.width) + gap + sparkSize.width, height: max(ceil(textSize.height), sparkSize.height))
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }
        (text as NSString).draw(at: NSPoint(x: 0, y: (size.height - textSize.height)/2), withAttributes: attrs)
        let sparkline = MenuBarSparklineImage.render(values: sparkline, color: textColor)
        sparkline.draw(at: NSPoint(x: textSize.width + gap, y: (size.height - sparkSize.height)/2), from: .zero, operation: .sourceOver, fraction: 1.0)
        return image
    }
}
