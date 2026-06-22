import SwiftUI

struct ProfileRow: View {
    @EnvironmentObject var awsManager: AWSManager
    @Environment(\.ledgerAppearance) private var a
    var teamCacheOn: Bool

    var body: some View {
        HStack(spacing: LedgerTokens.Layout.unit(a)) {
            Circle()
                .fill(LedgerTokens.Color.accent(a))
                .frame(width: 6, height: 6)

            Picker("", selection: $awsManager.selectedProfile) {
                ForEach(awsManager.profiles) { profile in
                    Text(profile.name).tag(Optional(profile))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()

            Spacer()

            if teamCacheOn {
                Text("◉ Team")
                    .ledgerMeta()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(LedgerTokens.Color.accent(a).opacity(0.14))
                    )
                    .foregroundColor(LedgerTokens.Color.accent(a))
            }

            let region = awsManager.selectedProfile?.region

            if let updated = lastUpdatedString {
                HStack(spacing: 3) {
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 9))
                    Text(updated)
                }
                .ledgerMeta()
                .help("Local fetch time. Cost Explorer doesn't report when AWS last refreshed the data.")

                if region != nil {
                    Text("·")
                        .ledgerMeta()
                        .foregroundColor(LedgerTokens.Color.inkTertiary(a))
                }
            }

            if let region {
                Text(region).ledgerMeta()
            }
        }
        .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.75)
        .frame(height: 36)
        .ledgerSurface(.window)
    }

    // When the selected profile's cost data was last fetched. Cost Explorer
    // returns no data-freshness timestamp, so this is our local fetch time.
    private var lastUpdatedString: String? {
        guard let profile = awsManager.selectedProfile,
              let entry = awsManager.costCache[profile.name] else { return nil }
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        // Include the date only when the data wasn't fetched today, so a stale
        // (e.g. yesterday's) timestamp is obvious at a glance.
        fmt.dateStyle = Calendar.current.isDateInToday(entry.fetchDate) ? .none : .medium
        return fmt.string(from: entry.fetchDate)
    }
}
