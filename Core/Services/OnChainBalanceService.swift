import Foundation

// MARK: - OnChainBalanceService

/// Reads ERC-20 USDC balances across multiple chains via raw JSON-RPC `eth_call`.
/// No signing or API keys required — uses public RPCs with URLSession.
enum OnChainBalanceService {

    // MARK: - Chain Configuration

    private struct ChainConfig {
        let name: String
        let rpcURL: String
        let usdcAddress: String
        let decimals: Int
    }

    private static let chains: [ChainConfig] = [
        ChainConfig(
            name: "Base",
            rpcURL: "https://mainnet.base.org",
            usdcAddress: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
            decimals: 6
        ),
        ChainConfig(
            name: "Arbitrum Sepolia",
            rpcURL: "https://sepolia-rollup.arbitrum.io/rpc",
            usdcAddress: "0x9cA75917e9c158569a602cb2504823282fb4Fc45",
            decimals: 6
        ),
        ChainConfig(
            name: "Robinhood Testnet",
            rpcURL: "https://rpc.testnet.chain.robinhood.com",
            usdcAddress: "0x89621E6a57a6872869fE30F433BE454B40dde7b3",
            decimals: 6
        ),
    ]

    // MARK: - Errors

    enum BalanceError: LocalizedError {
        case invalidURL
        case rpcError(chain: String, message: String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid RPC URL"
            case .rpcError(let chain, let message):
                return "RPC error on \(chain): \(message)"
            case .invalidResponse:
                return "Invalid RPC response"
            }
        }
    }

    // MARK: - Public API

    /// Fetches USDC balance across all configured chains and returns the sum as a human-readable Double.
    static func fetchTotalUSDCBalance(walletAddress: String) async throws -> Double {
        async let baseBalance = fetchBalance(chain: chains[0], walletAddress: walletAddress)
        async let arbBalance = fetchBalance(chain: chains[1], walletAddress: walletAddress)
        async let rhBalance = fetchBalance(chain: chains[2], walletAddress: walletAddress)

        var total: Double = 0
        // Sum up balances, treating individual chain failures as 0
        do { total += try await baseBalance } catch {
            print("[OnChainBalance] \(chains[0].name) failed: \(error.localizedDescription)")
        }
        do { total += try await arbBalance } catch {
            print("[OnChainBalance] \(chains[1].name) failed: \(error.localizedDescription)")
        }
        do { total += try await rhBalance } catch {
            print("[OnChainBalance] \(chains[2].name) failed: \(error.localizedDescription)")
        }

        return total
    }

    // MARK: - Private Helpers

    /// Fetches the USDC balance for a single chain.
    private static func fetchBalance(chain: ChainConfig, walletAddress: String) async throws -> Double {
        let callData = encodeBalanceOf(address: walletAddress)
        let resultHex = try await ethCall(rpcURL: chain.rpcURL, contractAddress: chain.usdcAddress, callData: callData)
        return decodeUInt256(hex: resultHex, decimals: chain.decimals)
    }

    /// Encodes `balanceOf(address)` call data.
    /// Selector: `0x70a08231` + 32-byte zero-padded address.
    private static func encodeBalanceOf(address: String) -> String {
        let selector = "0x70a08231"
        // Strip 0x prefix and left-pad to 64 hex chars (32 bytes)
        let cleanAddress = address.hasPrefix("0x") ? String(address.dropFirst(2)) : address
        let padded = String(repeating: "0", count: max(0, 64 - cleanAddress.count)) + cleanAddress.lowercased()
        return selector + padded
    }

    /// Makes a raw JSON-RPC `eth_call` POST request.
    private static func ethCall(rpcURL: String, contractAddress: String, callData: String) async throws -> String {
        guard let url = URL(string: rpcURL) else {
            throw BalanceError.invalidURL
        }

        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_call",
            "params": [
                ["to": contractAddress, "data": callData],
                "latest"
            ],
            "id": 1
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BalanceError.invalidResponse
        }

        if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
            throw BalanceError.rpcError(chain: rpcURL, message: message)
        }

        guard let result = json["result"] as? String else {
            throw BalanceError.invalidResponse
        }

        return result
    }

    /// Decodes a hex-encoded uint256 value to a human-readable Double with the given decimals.
    private static func decodeUInt256(hex: String, decimals: Int) -> Double {
        let cleanHex = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        guard let value = UInt64(cleanHex, radix: 16) else { return 0 }
        let divisor = pow(10.0, Double(decimals))
        return Double(value) / divisor
    }
}
