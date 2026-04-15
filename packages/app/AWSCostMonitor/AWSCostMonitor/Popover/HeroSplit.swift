import SwiftUI

struct HeroSplit: View {
    @Environment(\.ledgerAppearance) private var a
    let mtd: Double
    let sparkline: [Double]
    let rows: [KV]

    struct KV: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let color: KVColor

        enum KVColor {
            case ink
            case accent
            case over
            case under
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: LedgerTokens.Layout.unit(a) / 2) {
                Text("MTD").ledgerLabel()
                Text(formatted(mtd)).ledgerHero()
                Sparkline(values: sparkline)
                    .frame(height: 28)
            }
            .padding(LedgerTokens.Layout.unit(a) * 1.5)
            .frame(maxWidth: .infinity, alignment: .topLeading)

            Rectangle()
                .fill(LedgerTokens.Color.surfaceHairline(a))
                .frame(width: LedgerTokens.Layout.hairlineWidth(a))

            VStack(alignment: .trailing, spacing: 3) {
                ForEach(rows) { row in
                    HStack {
                        Text(row.label).ledgerLabel()
                        Spacer()
                        Text(row.value)
                            .ledgerStatValue()
                            .foregroundColor(color(for: row.color))
                    }
                    .frame(height: 16)
                }
            }
            .padding(LedgerTokens.Layout.unit(a) * 1.5)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(height: 120)
    }

    private func color(for kind: KV.KVColor) -> SwiftUI.Color {
        switch kind {
        case .ink:
            return LedgerTokens.Color.inkPrimary(a)
        case .accent:
            return LedgerTokens.Color.accent(a)
        case .over:
            return LedgerTokens.Color.signalOver(a)
        case .under:
            return LedgerTokens.Color.signalUnder(a)
        }
    }

    private func formatted(_ value: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = "USD"
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        return numberFormatter.string(from: NSNumber(value: value)) ?? ""
    }
}

struct Sparkline: View {
    @Environment(\.ledgerAppearance) private var a
    let values: [Double]

    var body: some View {
        GeometryReader { geometry in
            let maxValue = max(values.max() ?? 0, 1)
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(values.indices, id: \.self) { index in
                    let height = CGFloat(values[index] / maxValue) * geometry.size.height
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LedgerTokens.Color.accent(a).opacity(index == values.count - 1 ? 1 : 0.7))
                        .frame(height: max(1, height))
                }
            }
        }
    }
}
