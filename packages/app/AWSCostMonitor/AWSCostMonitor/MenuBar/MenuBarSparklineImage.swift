import AppKit

enum MenuBarSparklineImage {
    /// Renders a 60×14 horizontal sparkline. `values` is MTD daily cost; normalized to max.
    /// `color` should come from `LedgerTokens.Color.accent(…)` resolved to NSColor.
    static func render(values: [Double], color: NSColor) -> NSImage {
        let size = NSSize(width: 60, height: 14)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        guard let maxV = values.max(), maxV > 0, !values.isEmpty else { return image }
        let columnWidth: CGFloat = 2
        let gap: CGFloat = 1
        let barCount = min(values.count, Int(size.width / (columnWidth + gap)))
        let start = max(0, values.count - barCount)
        let slice = Array(values[start..<values.count])

        for (i, v) in slice.enumerated() {
            let h = max(1, (CGFloat(v) / CGFloat(maxV)) * size.height)
            let x = CGFloat(i) * (columnWidth + gap)
            let rect = NSRect(x: x, y: 0, width: columnWidth, height: h)
            // Last bar (today) gets full alpha; the rest 0.6
            let alpha: CGFloat = i == slice.count - 1 ? 1.0 : 0.6
            color.withAlphaComponent(alpha).setFill()
            NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1).fill()
        }
        return image
    }
}
