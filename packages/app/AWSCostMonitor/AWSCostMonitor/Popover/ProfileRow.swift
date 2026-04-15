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

            if let profile = awsManager.selectedProfile, let region = profile.region {
                Text(region).ledgerMeta()
            }
        }
        .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.75)
        .frame(height: 36)
        .ledgerSurface(.window)
    }
}
