import Foundation

enum EnvConfig {
    // MARK: - Bundle Reader

    private static func value(for key: String) -> String {
        Bundle.main.infoDictionary?[key] as? String ?? ""
    }

    // MARK: - Privy

    static var privyAppId: String { value(for: "PRIVY_APP_ID") }
    static var privyAppClientId: String { value(for: "PRIVY_APP_CLIENT_ID") }

    // MARK: - Coinbase

    static var coinbaseOnrampAppId: String { value(for: "COINBASE_ONRAMP_APP_ID") }

    // MARK: - Supabase

    static var supabaseURL: String { value(for: "SUPABASE_URL") }
    static var supabaseAnonKey: String { value(for: "SUPABASE_ANON_KEY") }

    // MARK: - Gemini

    static var geminiApiKey: String { value(for: "GEMINI_API_KEY") }
}
