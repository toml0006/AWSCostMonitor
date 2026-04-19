import SwiftUI

struct ServiceList: View {
    @Environment(\.ledgerAppearance) private var a
    let services: [ServiceCost]
    let total: Double
    let hideCents: Bool
    let isLoading: Bool
    let sparklines: [String: [Double]]
    let onSelect: (String) -> Void

    var body: some View {
        let topServices = Array(services.prefix(5))
        let otherTotal = services
            .dropFirst(5)
            .reduce(0.0) { partial, service in
                partial + NSDecimalNumber(decimal: service.amount).doubleValue
            }

        VStack(spacing: 0) {
            if isLoading {
                // Placeholder rows while data is loading
                ForEach(0..<5, id: \.self) { _ in
                    placeholderRow()
                }
            } else {
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
        }
        .animation(.easeOut(duration: 0.35), value: isLoading)
    }

    private func row(for name: String, amount: Double) -> some View {
        let percentage = total > 0 ? amount / total : 0
        let series = sparklines[name] ?? []
        return ZStack {
            if !series.isEmpty {
                Sparkline(values: series)
                    .opacity(0.22)
                    .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.75)
                    .padding(.vertical, 3)
                    .allowsHitTesting(false)
            }
            HStack(spacing: 0) {
                Text(name)
                    .ledgerBody()
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 6)
                Text(String(format: "%.0f%%", percentage * 100))
                    .ledgerMeta()
                    .frame(width: 36, alignment: .trailing)
                Spacer().frame(width: 6)
                Text(format(amount))
                    .ledgerStatValue()
                    .frame(minWidth: 72, alignment: .trailing)
            }
            .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.75)
        }
        .frame(height: LedgerTokens.Layout.rowHeight(a))
        .contentShape(Rectangle())
        .onTapGesture { onSelect(name) }
    }

    private func placeholderRow() -> some View {
        PlaceholderRow()
            .frame(height: LedgerTokens.Layout.rowHeight(a))
            .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.75)
    }

    private func format(_ value: Double) -> String {
        CurrencyFormatter.format(value)
    }
}

private struct PlaceholderRow: View {
    @Environment(\.ledgerAppearance) private var a
    @State private var opacity: Double = 0.2

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(LedgerTokens.Color.inkTertiary(a).opacity(opacity))
                .frame(maxWidth: .infinity, maxHeight: 10)
            RoundedRectangle(cornerRadius: 3)
                .fill(LedgerTokens.Color.inkTertiary(a).opacity(opacity))
                .frame(width: 30, height: 10)
            RoundedRectangle(cornerRadius: 3)
                .fill(LedgerTokens.Color.inkTertiary(a).opacity(opacity))
                .frame(width: 60, height: 10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                opacity = 0.5
            }
        }
    }
}
