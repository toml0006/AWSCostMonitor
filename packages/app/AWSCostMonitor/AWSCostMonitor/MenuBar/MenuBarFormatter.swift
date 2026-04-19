import Foundation

enum MenuBarFormatter {
    static func format(amount: Double, options: MenuBarOptions, delta: Double? = nil) -> String {
        let body = CurrencyFormatter.format(amount, options: options)
        guard options.showDelta, let delta else { return body }
        let pct = abs(delta * 100)
        let arrow = delta >= 0 ? "↑" : "↓"
        return String(format: "\(body) \(arrow)%.1f%%", pct)
    }
}
