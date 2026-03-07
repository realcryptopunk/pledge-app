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

        // TODO: Replace with actual credentials from Privy Dashboard
        // Register bundle ID com.navro.pledgeapp at https://dashboard.privy.io
        let config = PrivyConfig(
            appId: "YOUR_PRIVY_APP_ID",
            appClientId: "YOUR_PRIVY_APP_CLIENT_ID"
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
        defer { isLoading = false }

        do {
            let user = try await privy.sms.loginWithCode(code, sentTo: phoneNumber)
            authenticatedUser = user
            isAuthenticated = true
            userPhone = phoneNumber

            // Automatically create wallet if needed
            try await createWalletIfNeeded()
        } catch {
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
            isAuthenticated = true

            // Load existing wallet address if available
            if let firstWallet = user.embeddedEthereumWallets.first {
                walletAddress = firstWallet.address
            }
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
    }
}
