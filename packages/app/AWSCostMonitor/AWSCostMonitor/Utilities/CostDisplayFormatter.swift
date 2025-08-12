//
//  CostDisplayFormatter.swift
//  AWSCostMonitor
//
//  Service to handle cost display formatting
//

import Foundation

class CostDisplayFormatter {
    static func format(
        amount: Decimal,
        currency: String,
        format: MenuBarDisplayFormat,
        showCurrencySymbol: Bool = true,
        decimalPlaces: Int = 2,
        useThousandsSeparator: Bool = true
    ) -> String {
        switch format {
        case .full:
            // Full format with customizable options
            let formatter = NumberFormatter()
            formatter.numberStyle = showCurrencySymbol ? .currency : .decimal
            formatter.locale = Locale.current
            formatter.currencyCode = currency
            formatter.maximumFractionDigits = decimalPlaces
            formatter.minimumFractionDigits = decimalPlaces
            formatter.usesGroupingSeparator = useThousandsSeparator
            
            let formattedAmount = formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0"
            
            // If not showing currency symbol but we used decimal style, prepend the symbol manually if needed
            if !showCurrencySymbol && formatter.numberStyle == .decimal {
                return formattedAmount
            }
            
            return formattedAmount
            
        case .abbreviated:
            // Abbreviated format: always round to nearest dollar
            let formatter = NumberFormatter()
            formatter.numberStyle = showCurrencySymbol ? .currency : .decimal
            formatter.locale = Locale.current
            formatter.currencyCode = currency
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
            formatter.usesGroupingSeparator = useThousandsSeparator
            
            return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0"
            
        case .iconOnly:
            // Icon only: empty string (the icon is shown by the MenuBarExtra)
            return ""
        }
    }
    
    // Preview helper for settings UI
    static func previewText(for format: MenuBarDisplayFormat) -> String {
        switch format {
        case .full:
            return "$123.45"
        case .abbreviated:
            return "$123"
        case .iconOnly:
            return "(icon only)"
        }
    }
}