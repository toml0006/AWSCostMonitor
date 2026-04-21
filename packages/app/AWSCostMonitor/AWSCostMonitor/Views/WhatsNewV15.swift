import SwiftUI

struct WhatsNewV15: View {
    @Environment(\.ledgerAppearance) private var a
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LedgerTokens.Layout.unit(a) * 2) {
            Text("New Stuff!").ledgerHero()
            Text("AWSCostMonitor v1.5 brings a redesigned visual identity.").ledgerBody()
            Divider().background(LedgerTokens.Color.surfaceHairline(a))
            VStack(alignment: .leading, spacing: LedgerTokens.Layout.unit(a)) {
                Text("One opinionated identity, four orthogonal controls:").ledgerBody()
                Text("• Accent: Amber · Mint · Plasma · Bone").ledgerBody()
                Text("• Density: Comfortable · Compact").ledgerBody()
                Text("• Contrast: Standard · WCAG AAA").ledgerBody()
                Text("• Color scheme: System · Light · Dark").ledgerBody()
            }
            Spacer()
            HStack {
                Spacer()
                Button("Get Started") { onDismiss() }
                    .buttonStyle(.plain)
                    .font(LedgerTokens.Typography.body(a))
                    .foregroundColor(LedgerTokens.Color.accent(a))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LedgerTokens.Color.accent(a).opacity(0.12))
                    )
            }
            Text("Open Settings → Appearance to tune any of these.").ledgerMeta()
        }
        .padding(24)
        .frame(width: 440, height: 340)
        .ledgerSurface(.window)
    }
}
