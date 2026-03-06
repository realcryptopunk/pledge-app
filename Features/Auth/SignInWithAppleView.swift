import SwiftUI
import AuthenticationServices
import CryptoKit

// MARK: - Fluid Purple Gradient Overlay

struct FluidPurpleGlow: View {
    @State private var animate = false
    @Environment(\.themeColors) var theme
    
    var body: some View {
        ZStack {
            // Blob 1 - deep pool blue
            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.deep.opacity(0.6), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 280
                    )
                )
                .frame(width: 550, height: 550)
                .offset(x: animate ? -60 : 60, y: animate ? -80 : -20)
                .blur(radius: 80)
            
            // Blob 2 - pool light / sky blue
            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.light.opacity(0.45), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 220
                    )
                )
                .frame(width: 450, height: 450)
                .offset(x: animate ? 80 : -100, y: animate ? -30 : -100)
                .blur(radius: 70)
            
            // Blob 3 - pool surface / foam
            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.surface.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: animate ? -80 : 80, y: animate ? 40 : -60)
                .blur(radius: 60)
            
            // Blob 4 - deep accent
            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.mid.opacity(0.35), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: animate ? 40 : -40, y: animate ? -120 : -40)
                .blur(radius: 60)
        }
        .frame(maxWidth: .infinity, maxHeight: 500, alignment: .top)
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

struct SignInWithAppleView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme
    @State private var currentNonce: String?
    @State private var errorMessage: String?
    @State private var isSigningIn = false

    var body: some View {
        ZStack {
            WaterBackgroundView()
            
            // Fluid purple glow at top
            VStack {
                FluidPurpleGlow()
                Spacer()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: - Logo
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.surface, theme.light],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: theme.surface.opacity(0.4), radius: 20, y: 10)
                    .staggerIn(index: 0)

                Spacer().frame(height: 24)

                // MARK: - Header
                Text("Welcome to")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .staggerIn(index: 0)

                Text("Pledge")
                    .pledgeHero(48)
                    .foregroundColor(.primary)
                    .embossed(.raised)
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
                        .frame(maxWidth: 310, maxHeight: 52)
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

                    Button { appState.authService.signInAsGuest() } label: {
                        Text("Skip for now \u{2192}")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.6))
                    }

                    Text("By continuing, you agree to our Terms & Privacy Policy")
                        .pledgeCaption()
                        .foregroundColor(.secondary.opacity(0.4))
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
