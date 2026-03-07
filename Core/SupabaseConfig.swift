import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(string: EnvConfig.supabaseURL)!
    static let anonKey = EnvConfig.supabaseAnonKey

    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey
    )
}
