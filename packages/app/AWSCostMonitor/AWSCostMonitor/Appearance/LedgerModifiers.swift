import SwiftUI

private struct LedgerAppearanceKey: EnvironmentKey {
    static let defaultValue: LedgerAppearance = .default
}

extension EnvironmentValues {
    var ledgerAppearance: LedgerAppearance {
        get { self[LedgerAppearanceKey.self] }
        set { self[LedgerAppearanceKey.self] = newValue }
    }
}
