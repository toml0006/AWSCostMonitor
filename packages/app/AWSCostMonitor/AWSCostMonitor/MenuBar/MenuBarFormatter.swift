import Foundation

enum MenuBarFormatter {
    static func format(amount: Double, options: MenuBarOptions, delta: Double? = nil) -> String {
        var body: String
        if options.autoAbbreviate, amount >= 10_000 {
            let k = amount / 1000
            body = String(format: "$%.1fk", k)
        } else if options.hideCents {
            let nf = NumberFormatter()
            nf.numberStyle = .currency
            nf.currencyCode = "USD"
            nf.maximumFractionDigits = 0
            body = nf.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
        } else {
            let nf = NumberFormatter()
            nf.numberStyle = .currency
            nf.currencyCode = "USD"
            nf.maximumFractionDigits = 2
            nf.minimumFractionDigits = 2
            body = nf.string(from: NSNumber(value: amount)) ?? String(format: "$%.2f", amount)
        }
        guard options.showDelta, let delta else { return body }
        let pct = abs(delta * 100)
        let arrow = delta >= 0 ? "↑" : "↓"
        return String(format: "\(body) \(arrow)%.1f%%", pct)
    }
}
