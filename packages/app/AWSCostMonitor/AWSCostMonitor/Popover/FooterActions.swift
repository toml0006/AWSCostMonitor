import SwiftUI

struct FooterActions: View {
    @Environment(\.ledgerAppearance) private var a
    var onRefresh: () -> Void
    var onCalendar: () -> Void
    var onConsole: () -> Void
    var onOverflow: () -> Void

    var body: some View {
        HStack(spacing: LedgerTokens.Layout.unit(a)) {
            button(label: "Refresh", systemImage: "arrow.clockwise", primary: true, action: onRefresh)
            button(label: "Calendar", systemImage: "calendar", primary: false, action: onCalendar)
            button(label: "Console", systemImage: "globe", primary: false, action: onConsole)
            button(label: "⋯", systemImage: nil, primary: false, action: onOverflow)
        }
        .padding(LedgerTokens.Layout.unit(a) * 1.5)
        .frame(height: 44)
    }

    private func button(label: String, systemImage: String?, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(LedgerTokens.Typography.meta(a))
                }
                Text(label)
                    .font(LedgerTokens.Typography.meta(a))
            }
            .foregroundColor(primary ? LedgerTokens.Color.accent(a) : LedgerTokens.Color.inkSecondary(a))
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        primary
                            ? LedgerTokens.Color.accent(a).opacity(0.10)
                            : LedgerTokens.Color.surfaceElevated(a)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        primary
                            ? LedgerTokens.Color.accent(a).opacity(0.28)
                            : LedgerTokens.Color.surfaceHairline(a),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
