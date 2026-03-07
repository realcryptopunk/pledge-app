# Phase 03 Issues

## Open

### ISSUE-001: Coinbase Onramp requires server-side sessionToken
- **Severity:** Blocking (for real funding)
- **Found during:** 03-04 checkpoint
- **Description:** Coinbase enforces `sessionToken` parameter on all Onramp URLs (since July 2025). Tokens must be generated server-side via Coinbase's Create Onramp Session API using a JWT signed with the project's API key.
- **Current workaround:** Deposit is simulated for all users. CoinbaseOnrampView exists with URL builder but can't load without valid sessionToken.
- **Resolution:** Build a backend endpoint that generates sessionTokens. Pass token to CoinbaseOnrampView and add it to the URL query params.
- **References:**
  - Coinbase Onramp docs: https://docs.cdp.coinbase.com/onramp/docs/api-overview
  - Privy iOS SDK does NOT have `fundWallet()` — only available in React/Expo SDKs
