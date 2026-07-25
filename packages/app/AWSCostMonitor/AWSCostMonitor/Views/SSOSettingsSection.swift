import SwiftUI

/// Lists the sso-sessions declared in ~/.aws/config with their current token
/// state, so a user can sign in ahead of an expiry instead of discovering it
/// when the menu bar goes blank.
struct SSOSettingsSection: View {
    @EnvironmentObject var awsManager: AWSManager
    @State private var statuses: [String: SessionStatus] = [:]

    private let store = SSOTokenStore()

    /// Which store a usable token came from, not just when it expires. Sign Out
    /// can only delete the app's own Keychain token — by design, the app never
    /// writes ~/.aws/sso/cache, so it cannot revoke a session the AWS CLI owns.
    /// Without naming the source, a live CLI token makes Sign Out look broken:
    /// the row would still read "Signed in" immediately after clicking it.
    private struct SessionStatus {
        enum Source { case app, cli }
        let source: Source
        let expiresAt: Date
        var isExpired: Bool { expiresAt <= Date() }
    }

    var body: some View {
        Section("AWS SSO") {
            if awsManager.ssoSessions.isEmpty {
                Text("No sso-session blocks found in ~/.aws/config.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            ForEach(awsManager.ssoSessions.keys.sorted(), id: \.self) { name in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name).font(.body)
                        Text(statusText(for: name))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Sign In") {
                        Task {
                            await awsManager.signInToSSO(session: name)
                            await refreshExpiry(for: name)
                        }
                    }
                    .disabled(awsManager.ssoLogin.isSigningIn)

                    Button("Sign Out") {
                        try? store.delete(forKey: name)
                        Task {
                            await awsManager.credentialResolver.invalidateCache()
                            await refreshExpiry(for: name)
                        }
                    }
                    // Nothing of ours to delete unless the token is the app's.
                    .disabled(statuses[name]?.source != .app)
                }
                .padding(.vertical, 2)
            }
        }
        .task { await refreshAllExpiries() }
    }

    private func statusText(for name: String) -> String {
        guard let status = statuses[name] else { return "Not signed in" }
        let origin = status.source == .cli ? " via AWS CLI" : ""
        if status.isExpired { return "Expired\(origin)" }
        let formatter = RelativeDateTimeFormatter()
        let when = formatter.localizedString(for: status.expiresAt, relativeTo: Date())
        return "Signed in\(origin) — expires \(when)"
    }

    private func refreshAllExpiries() async {
        for name in awsManager.ssoSessions.keys {
            await refreshExpiry(for: name)
        }
    }

    private func refreshExpiry(for name: String) async {
        // Mirrors LayeredTokenStore's precedence — prefer a live app token, then
        // a live CLI one, then whatever stale token exists so the row can say
        // "Expired" (offer Sign In) rather than "Not signed in", which implies
        // different user action. Queried per-store rather than through
        // LayeredTokenStore because the source has to survive into the label.
        let appToken = await store.token(forKey: name)
        let cliToken = await CLITokenStore().token(forKey: name)

        if let appToken, !appToken.isExpired {
            statuses[name] = SessionStatus(source: .app, expiresAt: appToken.expiresAt)
        } else if let cliToken, !cliToken.isExpired {
            statuses[name] = SessionStatus(source: .cli, expiresAt: cliToken.expiresAt)
        } else if let appToken {
            statuses[name] = SessionStatus(source: .app, expiresAt: appToken.expiresAt)
        } else if let cliToken {
            statuses[name] = SessionStatus(source: .cli, expiresAt: cliToken.expiresAt)
        } else {
            statuses[name] = nil
        }
    }
}
