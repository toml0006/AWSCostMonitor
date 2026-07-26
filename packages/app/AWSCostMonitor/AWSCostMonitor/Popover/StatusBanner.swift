import SwiftUI

/// One-line, dismissable-by-fixing status strip. Used for credential failures,
/// which are routine (SSO tokens expire every ~8 hours) and always actionable.
struct StatusBanner: View {
    @Environment(\.ledgerAppearance) private var a
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    static let height: CGFloat = 28

    var body: some View {
        HStack(spacing: LedgerTokens.Layout.unit(a)) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundColor(LedgerTokens.Color.signalOver(a))

            Text(message)
                .ledgerMeta()
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: LedgerTokens.Layout.unit(a))

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.plain)
                    .ledgerMeta()
                    .foregroundColor(LedgerTokens.Color.accent(a))
            }
        }
        .padding(.horizontal, LedgerTokens.Layout.unit(a) * 1.75)
        .frame(height: Self.height)
        .background(LedgerTokens.Color.signalOver(a).opacity(0.10))
    }
}
