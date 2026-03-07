# Phase 5: Investment Contracts — Discovery

## Research Date: 2026-03-07

## 1. Pendle API (Arbitrum)

**REST API**: `https://api-v2.pendle.finance/core/`
- `/v2/sdk/{chainId}/convert` — Generic swap endpoint (USDC → PT)
- `/v1/sdk/{chainId}/markets/{marketAddress}/swap` — Market-specific swap
- No API key required, no fees

**Router V4 (Arbitrum)**: `0x888888888889758F76e7103c6CbF23ABbF58F946`

**Swap function signature**:
```solidity
function swapExactTokenForPt(
    address receiver,
    address market,
    uint256 minPtOut,
    ApproxParams calldata guessPtOut,
    TokenInput calldata input,
    LimitOrderData calldata limit
) external payable returns (uint256 netPtOut, uint256 netSyFee, uint256 netSyInterm)
```

**TokenInput struct**:
```solidity
struct TokenInput {
    address tokenIn;         // USDC address
    uint256 netTokenIn;      // Amount
    address tokenMintSy;     // Token to mint into SY
    address pendleSwap;      // Swap aggregator address
    SwapData swapData;       // Aggregator data
}
```

**Key addresses (Arbitrum)**:
- Native USDC: `0xaf88d065e77c8cC2239327C5EDB3A432268e5831`
- USDC.e (bridged): `0xFF970A61A04b1cA14834A43f5de4533eBDDB5CC8`

**SDK**: `@pendle/sdk-v2` (npm) — can also use REST API directly from backend

## 2. Privy Server-Side Signing

**Critical finding**: Privy embedded wallets use 2-of-2 Shamir key split (device + TEE). Server CANNOT sign transactions with user wallets without explicit authorization.

**Options evaluated**:
- ❌ Direct server signing with embedded wallets — not possible
- ✅ Authorization Keys (Signers) — users grant server permission, complex setup
- ✅ Smart contract approval pattern — standard DeFi, no signing needed
- ⚠️ Server Wallets — custodial, different ownership model

**Decision**: Use smart contract approval pattern. Users approve USDC spending to PledgeVault contract during onboarding. Backend relayer calls vault to pull USDC and swap to PT. No server-side signing required.

**Relayer options**:
- Privy Server Wallet (`@privy-io/node` SDK) — managed by Privy, policy engine
- Simple EOA funded with ETH — simpler, full control
- Either works; Privy Server Wallet recommended for production

## 3. Smart Contract Architecture

**Pattern**: Modified ERC-4626 vault with per-user tracking

**Design**:
```
PledgeVault.sol
├── investForUser(user, amount, minPtOut) — relayer only
│   ├── USDC.transferFrom(user, vault, amount) — requires pre-approval
│   ├── USDC.approve(pendleRouter, amount)
│   └── pendleRouter.swapExactTokenForPt(...) → PT credited to user
├── emergencyWithdraw() — user only, sends PT to caller
├── redeemMaturedPT(user) — relayer only, after maturity
├── setActiveMarket(market, pt) — owner only
├── setRelayer(addr) — owner only
└── userPtBalance[user] — view function
```

**Tooling**: Foundry (forge/cast/anvil)
- Superior for DeFi testing (fork testing, fuzzing)
- Solidity-native test framework
- Industry standard for 2025-2026

**Dependencies**:
- OpenZeppelin Contracts (Ownable, ReentrancyGuard, SafeERC20)
- Pendle Router interface (minimal, just the swap function)

## 4. Regulatory Architecture

- **Non-custodial**: Users' wallets own the USDC. Vault holds PT with on-chain ownership mapping.
- **Emergency exit**: Users can withdraw PT directly from contract at any time.
- **Transparent**: All positions verifiable on Arbiscan.
- **No money transmission**: Smart contract handles transfers, not the company.
- **Audit required**: Before mainnet deployment (OpenZeppelin, Trail of Bits, etc.)

## Sources

- [Pendle Hosted SDK Docs](https://docs.pendle.finance/pendle-v2/Developers/Backend/HostedSdk)
- [Pendle Router Integration Guide](https://docs.pendle.finance/pendle-v2/Developers/Contracts/PendleRouter/ContractIntegrationGuide)
- [Pendle Arbitrum Deployments](https://docs.pendle.finance/Developers/Deployments/Arbitrum)
- [Privy Embedded Wallet Architecture](https://privy.io/blog/how-privy-embedded-wallets-work)
- [Privy Authorization Keys](https://docs.privy.io/controls/authorization-keys/keys/create/key)
- [Privy Server Wallets](https://docs.privy.io/guide/server-wallets/quickstart/api)
- [ERC-4626 Standard](https://ethereum.org/developers/docs/standards/tokens/erc-4626/)
- [Foundry Book](https://getfoundry.sh/)
