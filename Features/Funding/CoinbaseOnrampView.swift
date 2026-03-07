import SwiftUI
import WebKit

// MARK: - CoinbaseOnrampView

struct CoinbaseOnrampView: View {
    let walletAddress: String
    let amount: Double
    let sessionToken: String
    let onDismiss: () -> Void

    @Environment(\.themeColors) var theme
    @State private var isLoading = true
    @State private var hasError = false
    @State private var retryTrigger = UUID()

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Top Bar
            HStack {
                Text("Fund Your Wallet")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Button {
                    PPHaptic.light()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            // MARK: - WebView Content
            ZStack {
                if hasError {
                    errorView
                } else {
                    WKWebViewContainer(
                        url: buildOnrampURL(),
                        isLoading: $isLoading,
                        hasError: $hasError,
                        onComplete: onDismiss
                    )
                    .id(retryTrigger)

                    if isLoading {
                        loadingOverlay
                    }
                }
            }
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(theme.buttonTop)

            Text("Loading Coinbase...")
                .pledgeCaption()
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground).opacity(0.9))
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("Failed to load")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            Text("Check your connection and try again.")
                .pledgeCaption()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                PPHaptic.light()
                hasError = false
                isLoading = true
                retryTrigger = UUID()
            } label: {
                Text("Retry")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [theme.buttonTop, theme.buttonBottom],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - URL Builder

    private func buildOnrampURL() -> URL {
        // Build the addresses JSON: {"walletAddress":["base"]}
        let addressesDict = [walletAddress: ["base"]]
        let addressesJSON = (try? JSONSerialization.data(withJSONObject: addressesDict)) ?? Data()
        let addressesString = String(data: addressesJSON, encoding: .utf8) ?? "{}"

        let assetsJSON = "[\"USDC\"]"

        var components = URLComponents(string: "https://pay.coinbase.com/buy/select-asset")!
        components.queryItems = [
            URLQueryItem(name: "appId", value: EnvConfig.coinbaseOnrampAppId),
            URLQueryItem(name: "sessionToken", value: sessionToken),
            URLQueryItem(name: "addresses", value: addressesString),
            URLQueryItem(name: "assets", value: assetsJSON),
            URLQueryItem(name: "presetFiatAmount", value: String(Int(amount))),
            URLQueryItem(name: "fiatCurrency", value: "USD"),
            URLQueryItem(name: "defaultNetwork", value: "base"),
            URLQueryItem(name: "defaultAsset", value: "USDC"),
        ]

        return components.url!
    }
}

// MARK: - Session Token Fetcher

enum OnrampError: LocalizedError {
    case missingToken
    case serverError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Session token not found in response"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

enum OnrampService {
    /// Fetches a Coinbase Onramp session token from the Supabase edge function.
    static func fetchSessionToken(walletAddress: String, amount: Double) async throws -> String {
        guard let url = URL(string: "\(EnvConfig.supabaseURL)/functions/v1/coinbase-session-token") else {
            throw OnrampError.serverError("Invalid Supabase URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(EnvConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["wallet_address": walletAddress, "amount": amount]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OnrampError.serverError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OnrampError.serverError("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["token"] as? String else {
            throw OnrampError.missingToken
        }

        return token
    }
}

// MARK: - WKWebViewContainer (UIViewRepresentable)

struct WKWebViewContainer: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var hasError: Bool
    let onComplete: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground

        let request = URLRequest(url: url)
        webView.load(request)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed — URL is loaded once in makeUIView
    }

    // MARK: - Coordinator (WKNavigationDelegate)

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WKWebViewContainer

        init(parent: WKWebViewContainer) {
            self.parent = parent
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            let urlString = url.absoluteString.lowercased()

            // Detect Coinbase onramp completion/success patterns
            if urlString.contains("success") || urlString.contains("complete") {
                Task { @MainActor in
                    self.parent.onComplete()
                }
                decisionHandler(.cancel)
                return
            }

            // Allow all Coinbase URLs and related domains
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                self.parent.isLoading = false
                self.parent.hasError = true
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                self.parent.isLoading = false
                self.parent.hasError = true
            }
        }
    }
}
