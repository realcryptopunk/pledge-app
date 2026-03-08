# Task: Robinhood Chain UI Updates

Branch: feat/robinhood-chain-ui (already checked out)

## 1. PortfolioView.swift — Replace Pendle PTs with Tokenized Stocks

Change the `allocations` array from Pendle PTs to tokenized stocks on Robinhood Chain:

```swift
static let allocations: [AllocationItem] = [
    AllocationItem(symbol: "TSLA", name: "Tesla", icon: "🚗", percentage: 0.30, fixedAPY: 0, color: .pledgeBlue),
    AllocationItem(symbol: "AMZN", name: "Amazon", icon: "📦", percentage: 0.25, fixedAPY: 0, color: .pledgeViolet),
    AllocationItem(symbol: "PLTR", name: "Palantir", icon: "🔮", percentage: 0.25, fixedAPY: 0, color: .pledgeGreen),
    AllocationItem(symbol: "AMD", name: "AMD", icon: "💻", percentage: 0.20, fixedAPY: 0, color: .pledgeOrange),
]
```

Also update any references to "Fixed APY" or "Pendle" in this file:
- Change "Fixed APY" labels → "24h Change" or just remove APY references
- Change "Pendle Principal Tokens" → "Tokenized Stocks"  
- Change "Yield Portfolio" or "Investment Pool" → "Stock Portfolio"
- Change weightedAPY display to show a total return % instead
- Anywhere it says "PT-" or "Pendle" → replace with stock-related terminology
- Keep the chart, allocation pie, and transaction list structure the same

## 2. SetupDepositView.swift — Add Robinhood Payment Option

After the Apple Pay button and before "Or pay with card", add a Robinhood deposit option button:

```swift
// Robinhood deposit option
Button {
    PPHaptic.heavy()
    flowState.depositAmount = depositValue
    flowState.goForward()
} label: {
    HStack(spacing: 10) {
        // Robinhood green feather icon
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.0, green: 0.82, blue: 0.33).opacity(0.15))
                .frame(width: 40, height: 40)
            Image(systemName: "leaf.fill")
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.33))
        }
        
        VStack(alignment: .leading, spacing: 2) {
            Text("Robinhood")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            HStack(spacing: 6) {
                Text("No Fees")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.33))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(red: 0.0, green: 0.82, blue: 0.33).opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        
        Spacer()
        
        VStack(alignment: .trailing, spacing: 2) {
            Text("No Limits")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            Text("Unlimited Deposit")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
    .padding(16)
    .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(red: 0.0, green: 0.82, blue: 0.33).opacity(0.3), lineWidth: 1)
            )
    )
}
.disabled(!canDeposit)
.opacity(canDeposit ? 1.0 : 0.35)
.padding(.horizontal, 20)
```

Also add a "Powered by Robinhood Chain" line at the bottom near the security note:
```swift
HStack(spacing: 6) {
    Image(systemName: "leaf.fill")
        .font(.system(size: 10))
        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.33))
    Text("Powered by Robinhood Chain")
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(.secondary.opacity(0.6))
}
```

## 3. OnboardingPage2.swift — Mention Tokenized Stocks

Change the subtitle text from:
"When you miss a pledge, we invest the money for you. You're building discipline or building wealth."
To:
"When you miss a pledge, your stake auto-invests into tokenized stocks — Tesla, Amazon, Palantir — on Robinhood Chain. Build discipline or build a portfolio."

Change "Your penalties, invested" to "Your penalties → tokenized stocks"

## 4. OnboardingPage3.swift — Update Steps

Change the third step from:
("📈", theme.surface, "Miss it? It's invested.", "Your penalty grows in your portfolio")
To:
("📈", theme.surface, "Miss it? You own stocks.", "Auto-invested into Tesla, Amazon & more on Robinhood Chain")

## 5. Build Check
After all changes, run:
```bash
cd /Users/openclaw/.openclaw/workspace/pledge-app
xcodebuild -project PledgeApp.xcodeproj -scheme PledgeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```
Fix any build errors.

## 6. Commit
```bash
git add -A
git commit -m "feat: Robinhood Chain UI — stocks in portfolio, RH deposit option, updated onboarding"
```
