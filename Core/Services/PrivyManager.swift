import Foundation
import PrivySDK

// MARK: - PrivyManager Errors

enum PrivyManagerError: Error, LocalizedError {
    case notInitialized
    case notAuthenticated
    case walletCreationFailed(String)
    case otpSendFailed(String)
    case otpVerifyFailed(String)

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Privy SDK has not been initialized."
        case .notAuthenticated:
            return "User is not authenticated."
        case .walletCreationFailed(let detail):
            return "Wallet creation failed: \(detail)"
        case .otpSendFailed(let detail):
            return "Failed to send OTP: \(detail)"
        case .otpVerifyFailed(let detail):
            return "Failed to verify OTP: \(detail)"
        }
    }
}

// MARK: - PrivyManager

@MainActor
class PrivyManager: ObservableObject {

    static let shared = PrivyManager()

    // MARK: - Published Properties

    @Published var isAuthenticated = false
    @Published var walletAddress: String?
    @Published var userPhone: String?
    @Published var authError: String?
    @Published var isLoading = false
    @Published var supabaseAccessToken: String?
    @Published var supabaseUserId: String?

    /// Timestamp when the current Supabase token expires (Unix epoch seconds)
    private var supabaseTokenExpiresAt: TimeInterval = 0

    // MARK: - Private Properties

    private var privy: Privy?
    private var authenticatedUser: PrivyUser?

    // MARK: - Init

    private init() {}

    // MARK: - SDK Initialization

    /// Initializes the Privy SDK. Must be called once at app launch before any other methods.
    /// Maintains a single Privy instance across the app lifetime.
    func initialize() {
        guard privy == nil else { return }

        let appId = EnvConfig.privyAppId
        let clientId = EnvConfig.privyAppClientId

        let config = PrivyConfig(
            appId: appId,
            appClientId: clientId
        )

        privy = PrivySdk.initialize(config: config)
    }

    // MARK: - Phone OTP Authentication

    /// Sends an OTP code to the given phone number.
    /// - Parameter phoneNumber: Phone number in E.164 format (e.g., "+14155551234")
    func sendOTP(to phoneNumber: String) async throws {
        guard let privy else {
            throw PrivyManagerError.notInitialized
        }

        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            try await privy.sms.sendCode(to: phoneNumber)
        } catch {
            let message = error.localizedDescription
            authError = message
            throw PrivyManagerError.otpSendFailed(message)
        }
    }

    /// Verifies an OTP code and authenticates the user. On success, automatically creates
    /// an embedded wallet if the user does not already have one.
    /// - Parameters:
    ///   - code: The OTP code entered by the user
    ///   - phoneNumber: The phone number the code was sent to (E.164 format)
    func verifyOTP(code: String, phoneNumber: String) async throws {
        guard let privy else {
            throw PrivyManagerError.notInitialized
        }

        isLoading = true
        authError = nil

        do {
            let user = try await privy.sms.loginWithCode(code, sentTo: phoneNumber)
            authenticatedUser = user
            userPhone = phoneNumber

            // Create wallet before setting isAuthenticated so routing doesn't
            // see isLoading=true and get stuck on SplashView.
            try? await createWalletIfNeeded()

            // Obtain Supabase session via auth bridge (non-blocking on failure)
            await authenticateWithSupabase()

            isLoading = false
            isAuthenticated = true
        } catch {
            isLoading = false
            let message = error.localizedDescription
            authError = message
            throw PrivyManagerError.otpVerifyFailed(message)
        }
    }

    // MARK: - Wallet Management

    /// Creates an embedded Ethereum wallet for the authenticated user if they don't already have one.
    /// Stores the wallet address in `walletAddress`.
    func createWalletIfNeeded() async throws {
        guard let user = authenticatedUser else {
            throw PrivyManagerError.notAuthenticated
        }

        do {
            // Check for existing wallets first
            let existingWallets = user.embeddedEthereumWallets
            if let firstWallet = existingWallets.first {
                walletAddress = firstWallet.address
                return
            }

            // No existing wallet — create one
            let wallet = try await user.createEthereumWallet()
            walletAddress = wallet.address
        } catch {
            let message = error.localizedDescription
            throw PrivyManagerError.walletCreationFailed(message)
        }
    }

    // MARK: - Supabase Auth Bridge

    /// Calls the auth-bridge edge function to exchange a Privy token for a Supabase JWT.
    /// Upserts the user profile in Supabase and stores the access token + user ID.
    private func authenticateWithSupabase() async {
        guard let user = authenticatedUser else { return }

        do {
            let privyToken = try await user.getAccessToken()

            let bridgeURL = URL(string: "\(EnvConfig.supabaseURL)/functions/v1/auth-bridge")!
            var request = URLRequest(url: bridgeURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "privy_token": privyToken,
                "wallet_address": walletAddress ?? "",
                "phone": userPhone ?? ""
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[PrivyManager] Auth bridge: invalid response type")
                return
            }

            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "unknown"
                print("[PrivyManager] Auth bridge failed (\(httpResponse.statusCode)): \(errorBody)")
                return
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("[PrivyManager] Auth bridge: failed to parse response JSON")
                return
            }

            supabaseAccessToken = json["access_token"] as? String
            supabaseUserId = json["user_id"] as? String
            supabaseTokenExpiresAt = json["expires_at"] as? TimeInterval ?? 0

            print("[PrivyManager] Supabase auth bridge success — user_id: \(supabaseUserId ?? "nil")")
        } catch {
            print("[PrivyManager] Auth bridge error: \(error.localizedDescription)")
        }
    }

    /// Refreshes the Supabase token if it has expired or is about to expire (within 5 minutes).
    func refreshSupabaseTokenIfNeeded() async {
        let now = Date().timeIntervalSince1970
        // Refresh if token expires within 5 minutes
        guard supabaseAccessToken != nil,
              now > supabaseTokenExpiresAt - 300 else {
            return
        }

        print("[PrivyManager] Supabase token expiring soon, refreshing...")
        await authenticateWithSupabase()
    }

    // MARK: - Auth State

    /// Checks the current authentication state and updates published properties.
    /// If the user is authenticated, also loads their existing wallet address.
    func checkAuthState() async {
        guard let privy else { return }

        // Wait for SDK to be ready
        await privy.awaitReady()

        switch privy.authState {
        case .authenticated(let user):
            authenticatedUser = user

            // Load existing wallet address if available
            if let firstWallet = user.embeddedEthereumWallets.first {
                walletAddress = firstWallet.address
            }

            // Obtain Supabase session on app relaunch
            await authenticateWithSupabase()

            isAuthenticated = true
        case .unauthenticated:
            isAuthenticated = false
            authenticatedUser = nil
            walletAddress = nil
            userPhone = nil
        case .notReady:
            // SDK not ready yet — should not happen after awaitReady()
            break
        default:
            break
        }
    }

    // MARK: - Guest Mode (Dev)

    /// Signs in as a guest for development. Sets isAuthenticated=true with no wallet.
    func signInAsGuest() {
        isAuthenticated = true
        walletAddress = nil
        userPhone = nil
        authError = nil
        isLoading = false
    }

    // MARK: - Sign Out

    /// Signs the user out and clears all published state.
    func signOut() async {
        if let user = authenticatedUser {
            await user.logout()
        }

        authenticatedUser = nil
        isAuthenticated = false
        walletAddress = nil
        userPhone = nil
        authError = nil
        supabaseAccessToken = nil
        supabaseUserId = nil
        supabaseTokenExpiresAt = 0
    }
}
