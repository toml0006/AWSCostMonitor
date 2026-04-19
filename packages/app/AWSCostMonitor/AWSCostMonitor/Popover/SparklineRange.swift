import Foundation

enum SparklineRange: String, CaseIterable, Identifiable {
    case weekRolling
    case weekAbsolute
    case monthRolling
    case monthAbsolute
    case quarterRolling
    case quarterAbsolute

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weekRolling:    return "7D"
        case .weekAbsolute:   return "Week"
        case .monthRolling:   return "30D"
        case .monthAbsolute:  return "Month"
        case .quarterRolling: return "90D"
        case .quarterAbsolute:return "Quarter"
        }
    }

    var menuTitle: String {
        switch self {
        case .weekRolling:    return "Rolling 7 days"
        case .weekAbsolute:   return "This week"
        case .monthRolling:   return "Rolling 30 days"
        case .monthAbsolute:  return "This month"
        case .quarterRolling: return "Rolling 90 days"
        case .quarterAbsolute:return "This quarter"
        }
    }

    var isAbsolute: Bool {
        switch self {
        case .weekAbsolute, .monthAbsolute, .quarterAbsolute: return true
        default: return false
        }
    }

    func startDate(now: Date = Date(), calendar: Calendar = .current) -> Date {
        let startOfToday = calendar.startOfDay(for: now)
        switch self {
        case .weekRolling:
            return calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        case .weekAbsolute:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? startOfToday
        case .monthRolling:
            return calendar.date(byAdding: .day, value: -29, to: startOfToday) ?? startOfToday
        case .monthAbsolute:
            return calendar.dateInterval(of: .month, for: now)?.start ?? startOfToday
        case .quarterRolling:
            return calendar.date(byAdding: .day, value: -89, to: startOfToday) ?? startOfToday
        case .quarterAbsolute:
            return calendar.dateInterval(of: .quarter, for: now)?.start ?? startOfToday
        }
    }

    // Builds the day-aligned series for this range, padding missing days with zero.
    // Returns the values and the index of "today" within the series (nil if today falls outside the range).
    func series(from points: [(Date, Double)], now: Date = Date(), calendar: Calendar = .current) -> (values: [Double], todayIndex: Int?) {
        let start = startDate(now: now, calendar: calendar)
        let end = endDate(now: now, calendar: calendar)
        let today = calendar.startOfDay(for: now)
        let byDay = Dictionary(uniqueKeysWithValues: points.map { (calendar.startOfDay(for: $0.0), $0.1) })
        var values: [Double] = []
        var todayIndex: Int? = nil
        var day = start
        var i = 0
        while day <= end {
            if day == today { todayIndex = i }
            values.append(byDay[day] ?? 0)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
            i += 1
        }
        return (values, todayIndex)
    }

    // Last day included in the sparkline (inclusive).
    // Rolling ranges end today. Absolute ranges extend to the end of the period
    // so the sparkline shows the full week/month/quarter with future days included.
    func endDate(now: Date = Date(), calendar: Calendar = .current) -> Date {
        let startOfToday = calendar.startOfDay(for: now)
        switch self {
        case .weekRolling, .monthRolling, .quarterRolling:
            return startOfToday
        case .weekAbsolute:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return startOfToday }
            return calendar.date(byAdding: .day, value: -1, to: interval.end) ?? startOfToday
        case .monthAbsolute:
            guard let interval = calendar.dateInterval(of: .month, for: now) else { return startOfToday }
            return calendar.date(byAdding: .day, value: -1, to: interval.end) ?? startOfToday
        case .quarterAbsolute:
            guard let interval = calendar.dateInterval(of: .quarter, for: now) else { return startOfToday }
            return calendar.date(byAdding: .day, value: -1, to: interval.end) ?? startOfToday
        }
    }
}
