import Foundation
import Supabase

@MainActor
class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var authError: String?
    @Published var userEmail: String?

    private var authStateTask: Task<Void, Never>?

    init() {
        authStateTask = Task { [weak self] in
            await self?.checkExistingSession()
            await self?.listenToAuthChanges()
        }
    }

    deinit {
        authStateTask?.cancel()
    }

    // MARK: - Session

    func checkExistingSession() async {
        defer { isLoading = false }
        do {
            let session = try await SupabaseConfig.client.auth.session
            isAuthenticated = true
            userEmail = session.user.email
        } catch {
            isAuthenticated = false
        }
    }

    // MARK: - Auth State Listener

    private func listenToAuthChanges() async {
        for await (event, session) in SupabaseConfig.client.auth.authStateChanges {
            switch event {
            case .signedIn:
                isAuthenticated = true
                userEmail = session?.user.email
            case .signedOut:
                isAuthenticated = false
                userEmail = nil
            default:
                break
            }
        }
    }

    // MARK: - Sign in with Apple

    func signInWithApple(idToken: String, nonce: String) async {
        authError = nil
        do {
            let session = try await SupabaseConfig.client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            isAuthenticated = true
            userEmail = session.user.email
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await SupabaseConfig.client.auth.signOut()
            isAuthenticated = false
            userEmail = nil
        } catch {
            authError = error.localizedDescription
        }
    }
}
