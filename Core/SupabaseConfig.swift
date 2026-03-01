import Foundation
import Supabase

enum SupabaseConfig {
    // TODO: Replace with your Supabase project URL
    static let url = URL(string: "https://YOUR_PROJECT_REF.supabase.co")!
    // TODO: Replace with your Supabase anon key
    static let anonKey = "YOUR_ANON_KEY"

    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey
    )
}
