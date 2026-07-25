import SwiftUI

/// Lists the sso-sessions declared in ~/.aws/config with their current token
/// state, so a user can sign in ahead of an expiry instead of discovering it
/// when the menu bar goes blank.
struct SSOSettingsSection: View {
    @EnvironmentObject var awsManager: AWSManager
    @State private var expiries: [String: Date] = [:]

    private let store = SSOTokenStore()

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
                }
                .padding(.vertical, 2)
            }
        }
        .task { await refreshAllExpiries() }
    }

    private func statusText(for name: String) -> String {
        guard let expiry = expiries[name] else { return "Not signed in" }
        if expiry <= Date() { return "Expired" }
        let formatter = RelativeDateTimeFormatter()
        return "Signed in — expires \(formatter.localizedString(for: expiry, relativeTo: Date()))"
    }

    private func refreshAllExpiries() async {
        for name in awsManager.ssoSessions.keys {
            await refreshExpiry(for: name)
        }
    }

    private func refreshExpiry(for name: String) async {
        // Include CLI tokens and Task 13's silent refresh path so this status
        // reflects credentials the resolver can actually use.
        let layeredStore = LayeredTokenStore(
            keychain: store,
            cli: CLITokenStore(),
            sessions: awsManager.ssoSessions
        )
        expiries[name] = await layeredStore.token(forKey: name)?.expiresAt
    }
}
