import Foundation

enum CurrencyFormatter {
    static func format(_ amount: Double,
                       currencyCode: String = "USD",
                       options: MenuBarOptions = MenuBarOptions()) -> String {
        if options.autoAbbreviate, abs(amount) >= 10_000 {
            let sign = amount < 0 ? "-" : ""
            let k = abs(amount) / 1000
            return "\(sign)$\(String(format: "%.1f", k))k"
        }
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = currencyCode
        let digits = options.hideCents ? 0 : 2
        nf.minimumFractionDigits = digits
        nf.maximumFractionDigits = digits
        if let s = nf.string(from: NSNumber(value: amount)) { return s }
        return options.hideCents ? "$\(Int(amount))" : String(format: "$%.2f", amount)
    }

    static func format(_ amount: Decimal,
                       currencyCode: String = "USD",
                       options: MenuBarOptions = MenuBarOptions()) -> String {
        format(NSDecimalNumber(decimal: amount).doubleValue,
               currencyCode: currencyCode, options: options)
    }
}
