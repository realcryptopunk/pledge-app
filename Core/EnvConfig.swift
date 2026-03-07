import Foundation

enum EnvConfig {
    private static let values: [String: String] = {
        guard let url = Bundle.main.url(forResource: ".env", withExtension: nil),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }
        var dict: [String: String] = [:]
        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
            dict[key] = value
        }
        return dict
    }()

    static func value(for key: String) -> String {
        values[key] ?? ""
    }

    // MARK: - Privy

    static var privyAppId: String { value(for: "PRIVY_APP_ID") }
    static var privyAppClientId: String { value(for: "PRIVY_APP_CLIENT_ID") }

    // MARK: - Coinbase

    static var coinbaseOnrampAppId: String { value(for: "COINBASE_ONRAMP_APP_ID") }
}
