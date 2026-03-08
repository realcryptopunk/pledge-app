import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(string: EnvConfig.supabaseURL)!
    static let anonKey = EnvConfig.supabaseAnonKey

    /// Unauthenticated client (for public operations and edge function calls)
    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey
    )

    /// Creates an authenticated Supabase client using a custom JWT access token provider.
    /// The access token closure is called on each request to provide the current JWT.
    /// Used after Privy auth bridge returns a Supabase-compatible JWT.
    static func authenticatedClient(accessToken: @escaping @Sendable () async throws -> String?) -> SupabaseClient {
        SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: .init(
                auth: .init(
                    accessToken: accessToken
                )
            )
        )
    }
}
