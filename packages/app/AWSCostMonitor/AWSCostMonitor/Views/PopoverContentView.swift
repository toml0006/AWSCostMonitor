import SwiftUI
import Charts

struct PopoverContentView: View {
    @EnvironmentObject var awsManager: AWSManager
    @EnvironmentObject var appearance: AppearanceManager
    @AppStorage("SparklineRange") private var sparklineRangeRaw: String = SparklineRange.monthRolling.rawValue
    // Shared sparkline scrub position: set by the hero sparkline, read by the
    // hero (day value) and the service list (per-day amounts + highlight).
    @State private var hoveredDayIndex: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            ProfileRow(teamCacheOn: teamCacheEnabled)

            LedgerHairlineDivider()

            HeroSplit(
                mtd: mtd,
                projected: awsManager.projectedMonthlyTotal.map { NSDecimalNumber(decimal: $0).doubleValue },
                sparkline: sparklineSeries.values,
                sparklineHighlightIndex: sparklineSeries.todayIndex,
                sparklineStartDate: sparklineRange.startDate(),
                leftRows: actualRows,
                rightRows: forecastRows,
                projectedColor: forecastSignal,
                hideCents: hideCents,
                isLoading: awsManager.isLoading,
                range: Binding(
                    get: { SparklineRange(rawValue: sparklineRangeRaw) ?? .monthRolling },
                    set: { sparklineRangeRaw = $0.rawValue }
                ),
                hoveredIndex: $hoveredDayIndex,
                onSelectDay: { date in
                    CalendarWindowController.showCalendarWindow(awsManager: awsManager, initialDate: date)
                }
            )

            LedgerHairlineDivider()

            ServiceList(
                services: serviceCosts,
                total: mtd,
                hideCents: hideCents,
                isLoading: awsManager.isLoading,
                sparklines: serviceSparklines,
                hoveredDayIndex: hoveredDayIndex,
                hoveredDayTotal: hoveredDayTotal,
                sparklineStartDate: sparklineRange.startDate(),
                onSelect: { service in
                    CalendarWindowController.showCalendarWindow(awsManager: awsManager, highlightedService: service)
                }
            )

            LedgerHairlineDivider()

            FooterActions(
                onRefresh: { Task { await awsManager.fetchCostForSelectedProfile(force: true) } },
                onCalendar: { CalendarWindowController.showCalendarWindow(awsManager: awsManager) },
                onConsole: { openConsole() },
                onOverflow: { openOverflowMenu() }
            )
        }
        .frame(width: windowWidth, height: totalHeight)
        .ledgerSurface(.window)
        .environment(\.ledgerAppearance, appearance.appearance)
        .onAppear {
            guard let profile = awsManager.selectedProfile else { return }
            if awsManager.costCache[profile.name] == nil, !awsManager.isLoading {
                Task { await awsManager.fetchCostForSelectedProfile(force: true) }
            }
        }
        .onChange(of: awsManager.selectedProfile) { _, newProfile in
            guard newProfile != nil else { return }
            // Persistence is handled by didSet on selectedProfile.
            // Trigger an immediate fetch so the new profile loads without waiting for the timer.
            Task { await awsManager.fetchCostForSelectedProfile(force: false) }
        }
    }

    // MARK: - Derived

    private var mtd: Double {
        guard let profile = awsManager.selectedProfile,
              let entry = awsManager.costCache[profile.name] else { return 0 }
        return NSDecimalNumber(decimal: entry.mtdTotal).doubleValue
    }

    private var serviceCosts: [ServiceCost] {
        guard let profile = awsManager.selectedProfile,
              let entry = awsManager.costCache[profile.name] else { return [] }
        return entry.serviceCosts.sorted { $0.amount > $1.amount }
    }

    private var teamCacheEnabled: Bool {
        #if !OPENSOURCE
        guard let p = awsManager.selectedProfile else { return false }
        return awsManager.getTeamCacheSettings(for: p.name).teamCacheEnabled
        #else
        return false
        #endif
    }

    private var hideCents: Bool { MenuBarOptions().hideCents }

    private var sparklineRange: SparklineRange {
        SparklineRange(rawValue: sparklineRangeRaw) ?? .monthRolling
    }

    private var sparklineSeries: (values: [Double], todayIndex: Int?) {
        let points = awsManager.dailyPointsForSelectedProfile ?? []
        return sparklineRange.series(from: points)
    }

    // Total spend on the scrubbed day (the main sparkline's value at that index),
    // used to compute each service's share of that day.
    private var hoveredDayTotal: Double? {
        guard let i = hoveredDayIndex else { return nil }
        let vals = sparklineSeries.values
        guard i >= 0, i < vals.count else { return nil }
        return vals[i]
    }

    // Per-service sparkline series aligned to the current sparkline range. Top 5 services
    // by MTD cost get their own day-aligned series; remaining services are aggregated
    // into an "Other" series so the row beneath "Other" also shows its trend.
    private var serviceSparklines: [String: [Double]] {
        guard let profile = awsManager.selectedProfile,
              let dailyByService = awsManager.dailyServiceCostsByProfile[profile.name]
        else { return [:] }

        let top = serviceCosts.prefix(5).map(\.serviceName)
        let topSet = Set(top)

        var result: [String: [Double]] = [:]
        for name in top {
            let points = dailyByService
                .filter { $0.serviceName == name }
                .map { (date: $0.date, value: NSDecimalNumber(decimal: $0.amount).doubleValue) }
            result[name] = sparklineRange.series(from: points).values
        }

        // Aggregate "Other" series by summing all non-top services per day.
        var otherByDay: [Date: Double] = [:]
        let cal = Calendar.current
        for entry in dailyByService where !topSet.contains(entry.serviceName) {
            let day = cal.startOfDay(for: entry.date)
            otherByDay[day, default: 0] += NSDecimalNumber(decimal: entry.amount).doubleValue
        }
        if !otherByDay.isEmpty {
            let points = otherByDay.map { (date: $0.key, value: $0.value) }
            result["Other"] = sparklineRange.series(from: points).values
        }
        return result
    }

    // Dynamic layout dimensions
    private var serviceRowCount: Int {
        if awsManager.isLoading { return 5 } // placeholder rows during load
        let top = min(serviceCosts.count, 5)
        let hasOther = serviceCosts.count > 5
        return top + (hasOther ? 1 : 0)
    }

    private var totalHeight: CGFloat {
        let rowH = LedgerTokens.Layout.rowHeight(appearance.appearance)
        return 36          // ProfileRow
             + 1           // hairline
             + HeroSplit.panelHeight(leftCount: actualRows.count, rightCount: forecastRows.count)
             + 1           // hairline
             + CGFloat(serviceRowCount) * rowH
             + 1           // hairline
             + 44          // FooterActions
    }

    private var windowWidth: CGFloat {
        // Two mirrored hero columns (actual | forecast). Size each so neither
        // anchor number truncates; at 34pt monospaced ~20px per character.
        let mtdStr = CurrencyFormatter.format(mtd)
        let projStr = projectedDouble.map { CurrencyFormatter.format($0) } ?? mtdStr
        let heroChars = max(mtdStr.count, projStr.count)
        let columnWidth = CGFloat(heroChars) * 20 + 44
        return max(500, columnWidth * 2 + 1)
    }

    private var burnPerDay: Double {
        guard mtd > 0 else { return 0 }
        let daysElapsed = max(1.0, Double(Calendar.current.component(.day, from: Date())))
        return mtd / daysElapsed
    }

    private var monthlyBudget: Double? {
        guard let p = awsManager.selectedProfile,
              let b = awsManager.getBudget(for: p.name).monthlyBudget else { return nil }
        let v = NSDecimalNumber(decimal: b).doubleValue
        return v > 0 ? v : nil
    }

    private var projectedDouble: Double? {
        awsManager.projectedMonthlyTotal.map { NSDecimalNumber(decimal: $0).doubleValue }
    }

    // Forecast anchor color = the verdict on where the month is heading.
    // Over budget (or, absent a budget, trending above last month) is bad → red;
    // comfortably under is good → green; unknown stays neutral accent.
    private var forecastSignal: HeroSplit.KV.KVColor {
        guard let projected = projectedDouble else { return .accent }
        if let budget = monthlyBudget {
            return projected > budget ? .over : .under
        }
        if let p = awsManager.selectedProfile,
           let lastFull = awsManager.lastMonthData[p.name].map({ NSDecimalNumber(decimal: $0.amount).doubleValue }),
           lastFull > 0 {
            return projected > lastFull ? .over : .under
        }
        return .accent
    }

    // LEFT column — what already happened this month.
    private var actualRows: [HeroSplit.KV] {
        var out: [HeroSplit.KV] = []
        if let delta = awsManager.deltaFractionVsLastMonth {
            let sign = delta >= 0 ? "▲" : "▼"
            out.append(.init(
                label: "Δ vs last",
                value: "\(sign) \(String(format: "%.1f", abs(delta * 100)))%",
                color: delta >= 0 ? .over : .under
            ))
        }
        if burnPerDay > 0 {
            out.append(.init(label: "Burn / day", value: CurrencyFormatter.format(burnPerDay), color: .ink))
        }
        // Last month through the same day — the apples-to-apples basis for the
        // delta above, so both numbers describe the same elapsed window.
        if let p = awsManager.selectedProfile, let lastMTD = awsManager.lastMonthMTDData[p.name] {
            out.append(.init(label: "Last mo MTD", value: CurrencyFormatter.format(lastMTD.amount), color: .ink))
        }
        // Savings Plans coverage, backed by a real existence check.
        // - existence known false → no plan at all ("None")
        // - existence known true  → coverage % (or "Active" if CE hasn't reported)
        // - existence unknown (call failed / no savingsplans permission) →
        //   fall back to Cost Explorer coverage, preferring SP then RI.
        if let p = awsManager.selectedProfile,
           let summary = awsManager.commitmentSummary[p.name] {
            switch summary.savingsPlansExist {
            case .some(false):
                out.append(.init(label: "SP cover", value: "None", color: .ink))
            case .some(true):
                let v = summary.spCoveragePercent.map { String(format: "%.0f%%", $0) } ?? "Active"
                out.append(.init(label: "SP cover", value: v, color: .ink))
            case .none:
                if let coverage = summary.preferredCoveragePercent {
                    let label = summary.spCoveragePercent != nil ? "SP cover" : "RI cover"
                    out.append(.init(label: label, value: String(format: "%.0f%%", coverage), color: .ink))
                }
            }
            // Lean actionable nudge: only when AWS says real money is on the
            // table. The full breakdown lives in the Calendar window.
            if let rec = awsManager.spRecommendation[p.name], rec.isWorthwhile {
                out.append(.init(
                    label: "SP save / mo",
                    value: "~\(CurrencyFormatter.format(Decimal(rec.estimatedMonthlySavings)))",
                    color: .under
                ))
            }
        }
        // AWS-detected anomalies: show count + top-impact service when present.
        if let p = awsManager.selectedProfile,
           let cloud = awsManager.cloudAnomalies[p.name],
           !cloud.isEmpty {
            let top = cloud.first
            let label = cloud.count > 1 ? "\(cloud.count) anomalies" : "Anomaly"
            let value = top?.topService ?? CurrencyFormatter.format(top?.totalImpact ?? 0)
            out.append(.init(label: label, value: value, color: .over))
        }
        return out
    }

    // RIGHT column — what's projected to happen by month end. The forecast hero
    // ($ projection) lives in HeroSplit; these are its supporting projections.
    private var forecastRows: [HeroSplit.KV] {
        var out: [HeroSplit.KV] = []
        // Projected month-end vs last month's full total.
        if let projected = projectedDouble,
           let p = awsManager.selectedProfile,
           let lastFull = awsManager.lastMonthData[p.name].map({ NSDecimalNumber(decimal: $0.amount).doubleValue }),
           lastFull > 0 {
            let d = (projected - lastFull) / lastFull
            let sign = d >= 0 ? "▲" : "▼"
            out.append(.init(
                label: "vs last mo",
                value: "\(sign) \(String(format: "%.0f", abs(d * 100)))%",
                color: d >= 0 ? .over : .under
            ))
        }
        if let projected = projectedDouble, let budget = monthlyBudget {
            let pct = projected / budget * 100
            out.append(.init(
                label: "vs budget",
                value: pct >= 1000 ? ">999%" : String(format: "%.0f%%", pct),
                color: projected > budget ? .over : .under
            ))
            let left = budget - projected
            out.append(.init(
                label: "Budget left",
                value: CurrencyFormatter.format(left),
                color: left < 0 ? .over : .ink
            ))
        }
        // Projected exhaustion date — only meaningful when on track to exceed.
        if let budget = monthlyBudget, burnPerDay > 0, mtd < budget,
           let projected = projectedDouble, projected >= budget {
            let daysLeft = (budget - mtd) / burnPerDay
            if let date = Calendar.current.date(byAdding: .day, value: Int(daysLeft.rounded()), to: Date()) {
                let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
                out.append(.init(label: "Exhausts", value: fmt.string(from: date), color: .over))
            }
        }
        return out
    }

    private func openConsole() {
        guard let p = awsManager.selectedProfile else { return }
        let region = p.region ?? "us-east-1"
        if let url = URL(string: "https://\(region).console.aws.amazon.com/billing/home") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openOverflowMenu() {
        let handler = MenuActionHandler()
        handler.onSettings = { showSettingsWindowForApp(awsManager: self.awsManager) }

        let settingsItem = NSMenuItem(title: "Settings", action: #selector(MenuActionHandler.openSettings), keyEquivalent: ",")
        settingsItem.target = handler
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")

        let menu = NSMenu()
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)

        // Retain handler for the menu's lifetime
        objc_setAssociatedObject(menu, &MenuActionHandler.key, handler, .OBJC_ASSOCIATION_RETAIN)

        if let event = NSApp.currentEvent {
            NSMenu.popUpContextMenu(menu, with: event, for: NSApp.keyWindow?.contentView ?? NSView())
        }
    }
}

// MARK: - Menu Action Handler

private final class MenuActionHandler: NSObject {
    static var key = "MenuActionHandlerKey"
    var onSettings: (() -> Void)?
    @objc func openSettings() { onSettings?() }
}

// MARK: - Day Detail Data Structure

struct DayDetailData: Identifiable {
    let id = UUID()
    let date: Date
    let dailyCost: DailyCost
    let services: [ServiceCost]
    let currencyFormatter: NumberFormatter
    let apiCalls: [APIRequestRecord]
    let highlightedService: String
}

private struct ServiceListHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        value = max(value, next)
    }
}

// MARK: - Real Histogram View with Full Graphics
