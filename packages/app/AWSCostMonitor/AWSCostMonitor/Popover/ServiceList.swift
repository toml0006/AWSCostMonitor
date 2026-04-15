import SwiftUI

struct ServiceList: View {
    @Environment(\.ledgerAppearance) private var a
    let services: [ServiceCost]
    let total: Double
    let onSelect: (String) -> Void

    var body: some View {
        let topServices = Array(services.prefix(5))
        let otherTotal = services
            .dropFirst(5)
            .reduce(0.0) { partialResult, service in
                partialResult + NSDecimalNumber(decimal: service.amount).doubleValue
            }

        return VStack(spacing: 0) {
            ForEach(topServices) { service in
                row(
                    for: service.serviceName,
                    amount: NSDecimalNumber(decimal: service.amount).doubleValue
                )
            }

            if otherTotal > 0 {
                row(for: "Other", amount: otherTotal)
            }
        }
        .frame(height: 180, alignment: .top)
    }

    private func row(for name: String, amount: Double) -> some View {
        let percentage = total > 0 ? amount / total : 0
        return HStack {
            Text(name).ledgerBody()
            Text(String(format: "%.0f%%", percentage * 100)).ledgerMeta()
            Spacer()
            Text(format(amount)).ledgerStatValue()
        }
        .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.75)
        .frame(height: LedgerTokens.Layout.rowHeight(a))
        .contentShape(Rectangle())
        .onTapGesture { onSelect(name) }
    }

    private func format(_ value: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = "USD"
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        return numberFormatter.string(from: NSNumber(value: value)) ?? ""
    }
}
