import SwiftUI

struct HeroSplit: View {
    @Environment(\.ledgerAppearance) private var a
    let mtd: Double
    let sparkline: [Double]
    let sparklineHighlightIndex: Int?
    let sparklineStartDate: Date?
    let rows: [KV]
    let hideCents: Bool
    let isLoading: Bool
    @Binding var range: SparklineRange
    var onSelectDay: ((Date) -> Void)? = nil

    @State private var hoveredIndex: Int? = nil

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
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: LedgerTokens.Layout.unit(a) / 2) {
                    Text("MTD").ledgerLabel()

                    if isLoading {
                        LoadingPulse()
                            .frame(height: LedgerTokens.Typography.heroPointSize(a) + 4)
                    } else {
                        Text(formatted(mtd))
                            .ledgerHero()
                            .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .leading)))
                    }
                }
                .padding(LedgerTokens.Layout.unit(a) * 1.5)
                .frame(maxWidth: .infinity, alignment: .topLeading)

                Rectangle()
                    .fill(LedgerTokens.Color.surfaceHairline(a))
                    .frame(width: LedgerTokens.Layout.hairlineWidth(a))

                VStack(alignment: .trailing, spacing: 3) {
                    if isLoading {
                        ForEach(0..<4, id: \.self) { _ in
                            LoadingPulse()
                                .frame(height: 14)
                                .cornerRadius(3)
                        }
                    } else {
                        ForEach(rows) { row in
                            HStack {
                                Text(row.label).ledgerLabel()
                                Spacer()
                                Text(row.value)
                                    .font(LedgerTokens.Typography.statValue(a))
                                    .foregroundColor(color(for: row.color))
                                    .monospacedDigit()
                            }
                            .frame(height: 16)
                        }
                    }
                }
                .padding(LedgerTokens.Layout.unit(a) * 1.5)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .animation(.easeOut(duration: 0.35), value: isLoading)
            }

            HStack(alignment: .center, spacing: 8) {
                Text(hoverCaption)
                    .ledgerMeta()
                    .foregroundColor(LedgerTokens.Color.inkSecondary(a))
                    .monospacedDigit()
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Menu {
                    Section("Rolling") {
                        Button(SparklineRange.weekRolling.menuTitle)    { range = .weekRolling }
                        Button(SparklineRange.monthRolling.menuTitle)   { range = .monthRolling }
                        Button(SparklineRange.quarterRolling.menuTitle) { range = .quarterRolling }
                    }
                    Section("Calendar") {
                        Button(SparklineRange.weekAbsolute.menuTitle)    { range = .weekAbsolute }
                        Button(SparklineRange.monthAbsolute.menuTitle)   { range = .monthAbsolute }
                        Button(SparklineRange.quarterAbsolute.menuTitle) { range = .quarterAbsolute }
                    }
                } label: {
                    HStack(spacing: 2) {
                        Text(range.label).ledgerMeta()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(LedgerTokens.Color.inkSecondary(a))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LedgerTokens.Color.surfaceHairline(a).opacity(0.4))
                    )
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
            .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.5)
            .padding(.bottom, 2)

            Sparkline(
                values: sparkline,
                highlightIndex: hoveredIndex ?? sparklineHighlightIndex,
                onHover: { hoveredIndex = $0 },
                onSelect: { idx in
                    guard let start = sparklineStartDate,
                          let day = Calendar.current.date(byAdding: .day, value: idx, to: start) else { return }
                    onSelectDay?(day)
                }
            )
            .frame(maxWidth: .infinity, minHeight: 36, maxHeight: 36)
            .opacity(isLoading ? 0.3 : 1)
            .animation(.easeOut(duration: 0.3), value: isLoading)
            .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.5)
            .padding(.bottom, LedgerTokens.Layout.unit(a))
        }
        .frame(height: 152)
    }

    private var hoverCaption: String {
        guard let idx = hoveredIndex, idx >= 0, idx < sparkline.count else { return "" }
        let value = sparkline[idx]
        let amount = formatted(value)
        guard let start = sparklineStartDate,
              let day = Calendar.current.date(byAdding: .day, value: idx, to: start) else {
            return amount
        }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: day)) · \(amount)"
    }

    private func color(for kind: KV.KVColor) -> SwiftUI.Color {
        switch kind {
        case .ink:    return LedgerTokens.Color.inkPrimary(a)
        case .accent: return LedgerTokens.Color.accent(a)
        case .over:   return LedgerTokens.Color.signalOver(a)
        case .under:  return LedgerTokens.Color.signalUnder(a)
        }
    }

    private func formatted(_ value: Double) -> String {
        CurrencyFormatter.format(value)
    }
}

// Subtle animated placeholder bar used while data is loading
private struct LoadingPulse: View {
    @Environment(\.ledgerAppearance) private var a
    @State private var opacity: Double = 0.3

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(LedgerTokens.Color.inkTertiary(a).opacity(opacity))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    opacity = 0.7
                }
            }
    }
}

struct Sparkline: View {
    @Environment(\.ledgerAppearance) private var a
    let values: [Double]
    var highlightIndex: Int? = nil
    var onHover: ((Int?) -> Void)? = nil
    var onSelect: ((Int) -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            let count = max(values.count, 1)
            let spacing: CGFloat = 2
            let barWidth = max(2, (geometry.size.width - spacing * CGFloat(count - 1)) / CGFloat(count))
            let maxValue = max(values.max() ?? 0, 1)
            let highlight = highlightIndex ?? (values.count - 1)
            let step = barWidth + spacing
            ZStack(alignment: .bottomLeading) {
                ForEach(values.indices, id: \.self) { index in
                    let barHeight = max(2, CGFloat(values[index] / maxValue) * geometry.size.height)
                    let x = CGFloat(index) * (barWidth + spacing)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(LedgerTokens.Color.accent(a).opacity(index == highlight ? 1.0 : 0.5))
                        .frame(width: barWidth, height: barHeight)
                        .offset(x: x, y: 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                guard let onHover else { return }
                switch phase {
                case .active(let location):
                    onHover(index(for: location.x, step: step))
                case .ended:
                    onHover(nil)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        guard let onSelect, let idx = index(for: value.location.x, step: step) else { return }
                        onSelect(idx)
                    }
            )
        }
    }

    private func index(for x: CGFloat, step: CGFloat) -> Int? {
        guard !values.isEmpty, step > 0 else { return nil }
        let raw = Int((x / step).rounded(.down))
        return max(0, min(values.count - 1, raw))
    }
}
