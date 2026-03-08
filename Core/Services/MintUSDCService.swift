import Foundation

// MARK: - MintUSDCService

/// Calls the mint-usdc Supabase edge function to mint MockUSDC to a wallet on Arbitrum Sepolia.
/// Used during simulated deposit flows (Apple Pay, Robinhood) so on-chain balance reflects the deposit.
enum MintUSDCService {

    // MARK: - Response Model

    struct Response {
        let txHash: String
        let explorerURL: String
    }

    // MARK: - Error Types

    enum MintError: LocalizedError {
        case invalidURL
        case serverError(statusCode: Int, body: String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid Supabase URL for mint-usdc"
            case .serverError(let statusCode, let body):
                return "Mint HTTP \(statusCode): \(body)"
            case .invalidResponse:
                return "Could not parse mint-usdc response"
            }
        }
    }

    // MARK: - API

    /// Mints MockUSDC to the given wallet on Arbitrum Sepolia.
    ///
    /// - Parameters:
    ///   - toWallet: The recipient wallet address (0x...)
    ///   - usdcAmount: The amount of USDC to mint (e.g., 50.0)
    /// - Returns: `Response` containing the transaction hash and explorer URL
    /// - Throws: `MintError` on failure
    static func mint(toWallet: String, usdcAmount: Double) async throws -> Response {
        guard let url = URL(string: "\(EnvConfig.supabaseURL)/functions/v1/mint-usdc") else {
            throw MintError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(EnvConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "user_wallet": toWallet,
            "usdc_amount": usdcAmount
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MintError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw MintError.serverError(statusCode: httpResponse.statusCode, body: errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let txHash = json["tx_hash"] as? String,
              let explorerURL = json["explorer_url"] as? String else {
            throw MintError.invalidResponse
        }

        return Response(txHash: txHash, explorerURL: explorerURL)
    }
}
