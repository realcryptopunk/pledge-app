import SwiftUI
import AuthenticationServices
import CryptoKit

struct SignInWithAppleView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme
    @State private var currentNonce: String?
    @State private var errorMessage: String?
    @State private var isSigningIn = false

    var body: some View {
        ZStack {
            WaterBackgroundView()

            VStack(spacing: 0) {
                Spacer()

                // MARK: - Header

                Text("Welcome to\nPledge")
                    .pledgeHero(42)
                    .foregroundColor(.primary)
                    .embossed(.raised)
                    .multilineTextAlignment(.center)
                    .staggerIn(index: 0)

                Spacer().frame(height: 12)

                Text("Stake your habits.\nBuild your future.")
                    .pledgeBody()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .staggerIn(index: 1)

                Spacer()

                // MARK: - Sign In Card

                VStack(spacing: 20) {
                    SignInWithAppleButton(.signIn, onRequest: configureRequest, onCompletion: handleResult)
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 52)
                        .clipShape(Capsule())
                        .staggerIn(index: 2)
                        .disabled(isSigningIn)
                        .opacity(isSigningIn ? 0.6 : 1)

                    if let errorMessage {
                        Text(errorMessage)
                            .pledgeCaption()
                            .foregroundColor(.pledgeRed)
                            .multilineTextAlignment(.center)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Text("By continuing, you agree to our [Terms](https://pledge.app/terms) & [Privacy Policy](https://pledge.app/privacy)")
                        .pledgeCaption()
                        .foregroundColor(.secondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .staggerIn(index: 3)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Apple Sign In

    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    private func handleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Unable to retrieve Apple credentials."
                return
            }

            // Save name from Apple (only provided on first sign-in)
            if let fullName = credential.fullName {
                let name = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                if !name.isEmpty {
                    appState.userName = name
                }
            }

            isSigningIn = true
            errorMessage = nil

            Task {
                await appState.authService.signInWithApple(idToken: idToken, nonce: nonce)
                isSigningIn = false
                if let error = appState.authService.authError {
                    errorMessage = error
                }
            }

        case .failure(let error):
            // Don't show error for user cancellation
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        precondition(errorCode == errSecSuccess)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    SignInWithAppleView()
        .environmentObject(AppState())
}
