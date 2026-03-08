import Foundation

// MARK: - InvestRelayerService

/// Calls the invest-relayer Supabase edge function to execute on-chain investments
/// via PledgeVaultRH.investForUser when a user misses a habit.
enum InvestRelayerService {

    // MARK: - Response Model

    struct Response {
        let txHash: String
        let explorerURL: String
    }

    // MARK: - Error Types

    enum RelayerError: LocalizedError {
        case invalidURL
        case serverError(statusCode: Int, body: String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid Supabase URL for invest-relayer"
            case .serverError(let statusCode, let body):
                return "Relayer HTTP \(statusCode): \(body)"
            case .invalidResponse:
                return "Could not parse invest-relayer response"
            }
        }
    }

    // MARK: - API

    /// Calls the invest-relayer edge function to execute an on-chain investment.
    ///
    /// - Parameters:
    ///   - userWallet: The user's embedded wallet address (0x...)
    ///   - usdcAmount: The USDC amount to invest (e.g., 5.0)
    /// - Returns: `Response` containing the transaction hash and explorer URL
    /// - Throws: `RelayerError` on failure
    static func callInvestRelayer(userWallet: String, usdcAmount: Double) async throws -> Response {
        guard let url = URL(string: "\(EnvConfig.supabaseURL)/functions/v1/invest-relayer") else {
            throw RelayerError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "user_wallet": userWallet,
            "usdc_amount": usdcAmount
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RelayerError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw RelayerError.serverError(statusCode: httpResponse.statusCode, body: errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let txHash = json["tx_hash"] as? String,
              let explorerURL = json["explorer_url"] as? String else {
            throw RelayerError.invalidResponse
        }

        return Response(txHash: txHash, explorerURL: explorerURL)
    }
}
