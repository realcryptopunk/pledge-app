import Foundation

enum EnvConfig {
    static func value(for key: String) -> String {
        ProcessInfo.processInfo.environment[key] ?? ""
    }

    // MARK: - Privy

    static var privyAppId: String { value(for: "PRIVY_APP_ID") }
    static var privyAppClientId: String { value(for: "PRIVY_APP_CLIENT_ID") }

    // MARK: - Coinbase

    static var coinbaseOnrampAppId: String { value(for: "COINBASE_ONRAMP_APP_ID") }
}
