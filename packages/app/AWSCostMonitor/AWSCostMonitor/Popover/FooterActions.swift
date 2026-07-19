import SwiftUI

// Quiet, uncluttered footer in the spirit of a native menu-bar app: navigation
// links sit muted on the left, the app version and Quit anchor the right. No
// pills or borders — the primary action (Refresh) lives up in the header now.
struct FooterActions: View {
    @Environment(\.ledgerAppearance) private var a
    var version: String
    var onCalendar: () -> Void
    var onConsole: () -> Void
    var onSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        HStack(spacing: LedgerTokens.Layout.unit(a) * 2) {
            link(label: "Calendar", systemImage: "calendar", action: onCalendar)
            link(label: "Console", systemImage: "globe", action: onConsole)
            link(label: "Settings", systemImage: "gearshape", action: onSettings)

            Spacer()

            Text("v\(version)")
                .font(LedgerTokens.Typography.meta(a))
                .foregroundColor(LedgerTokens.Color.inkTertiary(a))

            link(label: "Quit", systemImage: "power", action: onQuit)
        }
        .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.75)
        .frame(height: 40)
    }

    private func link(label: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(LedgerTokens.Typography.meta(a))
                Text(label)
                    .font(LedgerTokens.Typography.meta(a))
            }
            .foregroundColor(LedgerTokens.Color.inkSecondary(a))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
