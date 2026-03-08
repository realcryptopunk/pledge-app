# Task: End-to-End Demo Flow — Miss Habit → Invest in Stocks

DEADLINE: TOMORROW HACKATHON. This is the most important task.

The goal: when a user misses a habit in the app, show a complete flow of their stake being "invested" into tokenized stocks on Robinhood Chain, with per-stock portfolio tracking and mock transaction hashes.

## Current State
- When a habit fails, `investmentPoolValue += stakeAmount` in AppState.swift
- Portfolio view shows static allocation data
- No per-stock balance tracking
- No investment animation
- No transaction history tied to real on-chain data

## Changes Needed

### 1. AppState.swift — Add per-stock position tracking

Add these properties to AppState:

```swift
// Per-stock positions (symbol -> USDC value invested)
@Published var stockPositions: [String: Double] = [:]

// Transaction history for portfolio
@Published var investmentTransactions: [InvestmentTransaction] = []
```

Add this struct (can go in Models.swift):

```swift
struct InvestmentTransaction: Identifiable, Codable {
    let id: UUID
    let date: Date
    let habitName: String
    let totalAmount: Double
    let feeAmount: Double      // 20%
    let investedAmount: Double  // 80%
    let allocations: [StockPurchase]
    let txHash: String  // mock tx hash for demo
    
    struct StockPurchase: Codable {
        let symbol: String
        let name: String
        let amount: Double
        let percentage: Double
    }
}
```

### 2. AppState.swift — Update the failed habit handler

In both places where habits fail (around lines 313 and 382), after `investmentPoolValue += stakeAmount`, add stock allocation logic:

```swift
// Allocate across stocks based on risk profile
let fee = stakeAmount * 0.20
let investAmount = stakeAmount * 0.80
let allocations = riskProfile.allocations

var purchases: [InvestmentTransaction.StockPurchase] = []
for alloc in allocations {
    let stockAmount = investAmount * alloc.percentage
    stockPositions[alloc.symbol, default: 0] += stockAmount
    purchases.append(InvestmentTransaction.StockPurchase(
        symbol: alloc.symbol,
        name: alloc.name,
        amount: stockAmount,
        percentage: alloc.percentage
    ))
}

// Generate mock tx hash
let txHash = "0x" + UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(64)

let tx = InvestmentTransaction(
    id: UUID(),
    date: Date(),
    habitName: todayHabits[index].habit.name,
    totalAmount: stakeAmount,
    feeAmount: fee,
    investedAmount: investAmount,
    allocations: purchases,
    txHash: String(txHash)
)
investmentTransactions.insert(tx, at: 0)
```

Also update the activity item to be more descriptive:
```swift
let topStock = purchases.max(by: { $0.amount < $1.amount })?.symbol ?? "stocks"
let activity = ActivityItem(
    icon: "📈",
    title: "$\(Int(investAmount)) → \(topStock) & more",
    detail: "From missed \(todayHabits[index].habit.name)",
    isFailure: true
)
```

### 3. PortfolioView.swift — Show real stock positions

Update the portfolio view to read from `appState.stockPositions` instead of showing static mock data. In the allocation section, show ACTUAL invested amounts per stock:

Replace the static `allocations` array usage with dynamic data from appState. Something like:

```swift
// Dynamic allocations from actual investments
private var liveAllocations: [AllocationItem] {
    let profile = RiskProfile(rawValue: appState.riskProfile.rawValue) ?? .moderate
    return profile.allocations.map { alloc in
        let invested = appState.stockPositions[alloc.symbol] ?? 0
        return AllocationItem(
            symbol: alloc.symbol,
            name: alloc.name,
            icon: alloc.icon,
            percentage: alloc.percentage,
            fixedAPY: 0,
            color: alloc.color
        )
    }
}
```

And in the allocation cards, show the actual dollar amount invested:
```swift
Text("$\(Int(appState.stockPositions[alloc.symbol] ?? 0))")
```

### 4. PortfolioView.swift — Add transaction history section

Add a "Recent Investments" section below the allocation grid that shows `appState.investmentTransactions`:

```swift
// MARK: - Recent Investments
if !appState.investmentTransactions.isEmpty {
    VStack(alignment: .leading, spacing: 12) {
        Text("Recent Investments")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.primary)
        
        ForEach(appState.investmentTransactions.prefix(5)) { tx in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Missed \(tx.habitName)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(tx.allocations.map { "\($0.symbol) $\(Int($0.amount))" }.joined(separator: " · "))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    // Mock tx hash link
                    Button {
                        // Open in Robinhood Chain explorer
                        if let url = URL(string: "https://explorer.testnet.chain.robinhood.com/tx/\(tx.txHash)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 10))
                            Text(String(tx.txHash.prefix(10)) + "..." + String(tx.txHash.suffix(6)))
                                .font(.system(size: 11, design: .monospaced))
                        }
                        .foregroundColor(theme.surface)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("-$\(Int(tx.totalAmount))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.pledgeRed)
                    Text("$\(Int(tx.investedAmount)) invested")
                        .font(.system(size: 11))
                        .foregroundColor(.pledgeGreen)
                }
            }
            .padding(14)
            .aquaGlass(cornerRadius: 14)
        }
    }
    .padding(.horizontal, 20)
}
```

### 5. HomeView — Show investment notification when habit missed

After a habit fails on the home screen, briefly show a toast/banner:
"📈 $X invested into TSLA, AMZN & more on Robinhood Chain"

Find where the home view handles verification results and add a temporary banner state.

### 6. Persistence — Save/load stock positions

In AppState's save/load profile methods (search for `saveProfile` and `loadProfile` or wherever UserDefaults persistence happens), add stockPositions and investmentTransactions to the saved data.

### 7. Build and test

```bash
xcodebuild -project PledgeApp.xcodeproj -scheme PledgeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

Fix ALL build errors.

### 8. Commit

```bash
git add -A
git commit -m "feat: end-to-end demo flow — missed habits invest into tokenized stocks

- Per-stock position tracking (stockPositions dictionary)
- Investment transactions with mock tx hashes
- Portfolio shows real invested amounts per stock
- Transaction history with Robinhood Chain explorer links
- Investment toast notification on home screen
- Full persistence via UserDefaults"
git push origin feat/e2e-demo
```
