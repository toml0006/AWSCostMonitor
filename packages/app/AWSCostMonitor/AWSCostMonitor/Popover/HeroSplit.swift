import SwiftUI

struct HeroSplit: View {
    @Environment(\.ledgerAppearance) private var a
    let mtd: Double
    let projected: Double?
    let sparkline: [Double]
    let sparklineHighlightIndex: Int?
    let sparklineStartDate: Date?
    let leftRows: [KV]
    let rightRows: [KV]
    var projectedColor: KV.KVColor = .accent
    let hideCents: Bool
    let isLoading: Bool
    @Binding var range: SparklineRange
    // Day index hovered on the main sparkline, shared with the service list so
    // both highlight the same day and show that day's figures. nil = no hover.
    @Binding var hoveredIndex: Int?
    var onSelectDay: ((Date) -> Void)? = nil

    // Panel height grows with the taller of the two stat columns so neither
    // overflows into the header. Shared with PopoverContentView's layout math.
    static func panelHeight(leftCount: Int, rightCount: Int) -> CGFloat {
        let maxRows = max(leftCount, rightCount, 1)
        let columnContent: CGFloat = 12 + 44 + 6 + CGFloat(maxRows) * 19 + 24
        return columnContent + 64 // caption + sparkline + bottom padding
    }

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
            // Left column = what already happened (MTD actuals); right column =
            // what's projected to happen (forecast). The split is by time
            // orientation, not by number size.
            HStack(alignment: .top, spacing: 0) {
                // While scrubbing the sparkline, the left ("actual") column shows
                // the hovered day instead of the month-to-date total.
                column(
                    title: hoveredDate.map(Self.dayTitle) ?? "MONTH TO DATE",
                    hero: hoveredValue.map(formatted) ?? formatted(mtd),
                    heroColor: LedgerTokens.Color.accent(a),
                    heroLoading: isLoading,
                    rows: leftRows
                )

                Rectangle()
                    .fill(LedgerTokens.Color.surfaceHairline(a))
                    .frame(width: LedgerTokens.Layout.hairlineWidth(a))

                column(
                    title: "FORECAST",
                    hero: projected.map(formatted) ?? "—",
                    heroColor: color(for: projectedColor),
                    heroLoading: isLoading || projected == nil,
                    rows: rightRows
                )
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
                startDate: sparklineStartDate,
                showMonthBoundaries: true,
                showMonthLabels: true,
                showWeekLines: true,
                onHover: { hoveredIndex = $0 },
                onSelect: { idx in
                    guard let start = sparklineStartDate,
                          let day = Calendar.current.date(byAdding: .day, value: idx, to: start) else { return }
                    onSelectDay?(day)
                }
            )
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40)
            .opacity(isLoading ? 0.3 : 1)
            .animation(.easeOut(duration: 0.3), value: isLoading)
            .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.5)
            .padding(.bottom, LedgerTokens.Layout.unit(a))
        }
        .frame(height: HeroSplit.panelHeight(leftCount: leftRows.count, rightCount: rightRows.count))
    }

    // One time-oriented column: section label, anchor number, then stat rows.
    @ViewBuilder
    private func column(title: String, hero: String, heroColor: SwiftUI.Color, heroLoading: Bool, rows: [KV]) -> some View {
        VStack(alignment: .leading, spacing: LedgerTokens.Layout.unit(a) / 2) {
            Text(title).ledgerLabel()

            if heroLoading {
                LoadingPulse()
                    .frame(height: LedgerTokens.Typography.heroPointSize(a) + 4)
            } else {
                // Build the hero with the font directly instead of .ledgerHero()
                // so the caller's signal color is honored — ledgerHero() bakes in
                // an accent foregroundColor that would otherwise win.
                Text(hero)
                    .font(LedgerTokens.Typography.hero(a))
                    .foregroundColor(heroColor)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .leading)))
            }

            VStack(spacing: 3) {
                ForEach(rows) { row in
                    HStack(spacing: 6) {
                        Text(row.label).ledgerLabel().lineLimit(1)
                        Spacer(minLength: 8)
                        Text(row.value)
                            .font(LedgerTokens.Typography.statValue(a))
                            .foregroundColor(color(for: row.color))
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                    .frame(height: 16)
                }
            }
            // Constrain the stat block to roughly the hero number's width and
            // left-align it under the hero, so label→value gaps stay tight
            // instead of stretching across the full half-panel to the edge.
            .frame(width: 210, alignment: .leading)
            .padding(.top, 4)
        }
        .padding(LedgerTokens.Layout.unit(a) * 1.5)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .animation(.easeOut(duration: 0.35), value: heroLoading)
    }

    // The hovered day's total spend (the main sparkline value at that index).
    private var hoveredValue: Double? {
        guard let i = hoveredIndex, i >= 0, i < sparkline.count else { return nil }
        return sparkline[i]
    }

    private var hoveredDate: Date? {
        guard let i = hoveredIndex, let start = sparklineStartDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: i, to: start)
    }

    private static func dayTitle(_ date: Date) -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
        return fmt.string(from: date)
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
    var startDate: Date? = nil
    var showMonthBoundaries: Bool = false
    var showMonthLabels: Bool = true
    var showWeekLines: Bool = false
    var barSpacing: CGFloat = 2
    var minBarWidth: CGFloat = 2
    var onHover: ((Int?) -> Void)? = nil
    var onSelect: ((Int) -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            let count = max(values.count, 1)
            let spacing: CGFloat = barSpacing
            let barWidth = max(minBarWidth, (geometry.size.width - spacing * CGFloat(count - 1)) / CGFloat(count))
            let maxValue = max(values.max() ?? 0, 1)
            let highlight = highlightIndex ?? (values.count - 1)
            let step = barWidth + spacing
            ZStack(alignment: .bottomLeading) {
                // Week-boundary lines: faint hairlines at each start-of-week, so
                // the trend reads against the calendar grid. Drawn first (under
                // the month lines and bars) and lighter.
                if showWeekLines {
                    ForEach(weekBoundaries(), id: \.self) { idx in
                        Rectangle()
                            .fill(LedgerTokens.Color.inkTertiary(a).opacity(0.22))
                            .frame(width: 1, height: geometry.size.height)
                            .offset(x: CGFloat(idx) * step - spacing / 2)
                    }
                }
                // Month-boundary markers: a stronger hairline (and, in the hero,
                // a month label) at each day-1, so months read distinctly.
                if showMonthBoundaries {
                    ForEach(monthBoundaries(), id: \.index) { boundary in
                        let x = CGFloat(boundary.index) * step - spacing / 2
                        ZStack(alignment: .topLeading) {
                            Rectangle()
                                .fill(LedgerTokens.Color.inkTertiary(a).opacity(0.5))
                                .frame(width: 1, height: geometry.size.height)
                            if showMonthLabels {
                                Text(boundary.label)
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(LedgerTokens.Color.inkSecondary(a))
                                    .fixedSize()
                                    .offset(x: 3, y: -1)
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .offset(x: x)
                    }
                }
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

    // Indices where a bar falls on the 1st of a month, with a short month label.
    private func monthBoundaries() -> [(index: Int, label: String)] {
        guard let start = startDate, values.count > 1 else { return [] }
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        var result: [(index: Int, label: String)] = []
        for i in 1..<values.count {
            guard let day = cal.date(byAdding: .day, value: i, to: start) else { continue }
            if cal.component(.day, from: day) == 1 {
                result.append((i, fmt.string(from: day).uppercased()))
            }
        }
        return result
    }

    // Indices that fall on the first day of a calendar week (locale-aware).
    private func weekBoundaries() -> [Int] {
        guard let start = startDate, values.count > 1 else { return [] }
        let cal = Calendar.current
        var result: [Int] = []
        for i in 1..<values.count {
            guard let day = cal.date(byAdding: .day, value: i, to: start) else { continue }
            if cal.component(.weekday, from: day) == cal.firstWeekday {
                result.append(i)
            }
        }
        return result
    }
}
