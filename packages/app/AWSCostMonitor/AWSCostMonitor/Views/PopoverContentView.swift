import SwiftUI
import Charts

struct PopoverContentView: View {
    @EnvironmentObject var awsManager: AWSManager
    @EnvironmentObject var appearance: AppearanceManager

    var body: some View {
        VStack(spacing: 0) {
            ProfileRow(teamCacheOn: teamCacheEnabled)

            LedgerHairlineDivider()

            HeroSplit(
                mtd: mtd,
                sparkline: awsManager.dailyTotalsForSelectedProfile ?? [],
                rows: heroRows
            )

            LedgerHairlineDivider()

            ServiceList(
                services: serviceCosts,
                total: mtd,
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
        .frame(width: 360, height: 440)
        .ledgerSurface(.window)
        .environment(\.ledgerAppearance, appearance.appearance)
    }

    // MARK: - Derived

    private var mtd: Double {
        guard let c = awsManager.costData.first else { return 0 }
        return NSDecimalNumber(decimal: c.amount).doubleValue
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
        if let f = awsManager.projectedMonthlyTotal {
            let nf = NumberFormatter(); nf.numberStyle = .currency; nf.currencyCode = "USD"
            nf.maximumFractionDigits = 0
            let str = nf.string(from: NSDecimalNumber(decimal: f)) ?? ""
            out.append(.init(label: "Forecast", value: str, color: .accent))
        }
        if let p = awsManager.selectedProfile, let last = awsManager.lastMonthData[p.name] {
            let nf = NumberFormatter(); nf.numberStyle = .currency; nf.currencyCode = "USD"
            nf.maximumFractionDigits = 0
            out.append(.init(label: "Last mo", value: nf.string(from: NSDecimalNumber(decimal: last.amount)) ?? "", color: .ink))
        }
        if let daily = awsManager.dailyTotalsForSelectedProfile, !daily.isEmpty {
            let burn = daily.reduce(0, +) / Double(daily.count)
            out.append(.init(label: "Burn / day", value: String(format: "$%.2f", burn), color: .ink))
        }
        if let f = awsManager.budgetFraction {
            out.append(.init(
                label: "Budget",
                value: String(format: "%.0f%%", f * 100),
                color: f > 1.0 ? .over : .ink
            ))
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
        let menu = NSMenu()
        menu.addItem(withTitle: "Settings", action: #selector(NSApp.sendAction(_:to:from:)), keyEquivalent: ",")
        menu.addItem(withTitle: "Help",     action: nil, keyEquivalent: "?")
        menu.addItem(withTitle: "Export",   action: nil, keyEquivalent: "e")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit",     action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")
        if let event = NSApp.currentEvent {
            NSMenu.popUpContextMenu(menu, with: event, for: NSApp.keyWindow?.contentView ?? NSView())
        }
    }
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
