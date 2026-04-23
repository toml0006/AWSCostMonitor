import SwiftUI
import Charts

struct PopoverContentView: View {
    @EnvironmentObject var awsManager: AWSManager
    @EnvironmentObject var appearance: AppearanceManager
    @AppStorage("SparklineRange") private var sparklineRangeRaw: String = SparklineRange.monthRolling.rawValue

    var body: some View {
        VStack(spacing: 0) {
            ProfileRow(teamCacheOn: teamCacheEnabled)

            LedgerHairlineDivider()

            HeroSplit(
                mtd: mtd,
                sparkline: sparklineSeries.values,
                sparklineHighlightIndex: sparklineSeries.todayIndex,
                sparklineStartDate: sparklineRange.startDate(),
                rows: heroRows,
                hideCents: hideCents,
                isLoading: awsManager.isLoading,
                range: Binding(
                    get: { SparklineRange(rawValue: sparklineRangeRaw) ?? .monthRolling },
                    set: { sparklineRangeRaw = $0.rawValue }
                ),
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
             + 152         // HeroSplit
             + 1           // hairline
             + CGFloat(serviceRowCount) * rowH
             + 1           // hairline
             + 44          // FooterActions
    }

    private var windowWidth: CGFloat {
        // Size the window so the hero value never truncates.
        // At 34pt monospaced light, each character is ~20px wide.
        let heroStr = CurrencyFormatter.format(mtd)
        let leftPanel = CGFloat(heroStr.count) * 20 + 28  // content + horizontal padding
        let rightPanel: CGFloat = 168                      // KV rows comfortably fit
        return max(360, leftPanel + rightPanel + 1)
    }

    private var heroRows: [HeroSplit.KV] {
        var out: [HeroSplit.KV] = []
        if let delta = awsManager.deltaFractionVsLastMonth {
            let sign = delta >= 0 ? "▲" : "▼"
            out.append(.init(
                label: "Δ vs last",
                value: "\(sign) \(String(format: "%.1f", abs(delta * 100)))%",
                color: delta >= 0 ? .over : .under
            ))
        }
        // Forecast: prefer Cost Explorer's GetCostForecast (ML model with
        // day-of-week seasonality, RI amortization, etc.). Falls back to a
        // local linear extrapolation when the API hasn't returned a value.
        if let projected = awsManager.projectedMonthlyTotal {
            out.append(.init(label: "Forecast", value: CurrencyFormatter.format(projected), color: .accent))
        }
        if let p = awsManager.selectedProfile, let last = awsManager.lastMonthData[p.name] {
            out.append(.init(label: "Last mo", value: CurrencyFormatter.format(last.amount), color: .ink))
        }
        if mtd > 0 {
            let daysElapsed = max(1.0, Double(Calendar.current.component(.day, from: Date())))
            let burn = mtd / daysElapsed
            out.append(.init(label: "Burn / day", value: CurrencyFormatter.format(burn), color: .ink))
        }
        if let f = awsManager.budgetFraction {
            out.append(.init(
                label: "Budget",
                value: String(format: "%.0f%%", f * 100),
                color: f > 1.0 ? .over : .ink
            ))
        }
        // Savings Plans / RI coverage. Prefer SP when both available since
        // modern AWS accounts use SP; fall back to RI when the account only
        // has reservations.
        if let p = awsManager.selectedProfile,
           let summary = awsManager.commitmentSummary[p.name],
           let coverage = summary.preferredCoveragePercent {
            let label = summary.spCoveragePercent != nil ? "SP cover" : "RI cover"
            out.append(.init(label: label, value: String(format: "%.0f%%", coverage), color: .ink))
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
        if let p = awsManager.selectedProfile, let entry = awsManager.costCache[p.name] {
            let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
            out.append(.init(label: "Updated", value: fmt.string(from: entry.fetchDate), color: .ink))
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
