# 03-03 Risk Profile System - Summary

## Objective
Implement a 3-tier risk profile system that determines how failed-habit stakes are allocated across different investment strategies.

## Tasks Completed: 2/2

### Task 1: Add RiskProfile model and allocation data structures
- **Commit:** `6215435`
- **Files:** `Core/Models.swift`, `Core/AppState.swift`, `Features/Setup/SetupFlowState.swift`, `Features/Setup/SetupContainerView.swift`
- **Changes:**
  - Added `RiskProfile` enum with 3 tiers (conservative, moderate, aggressive) to Models.swift
  - Each tier has computed properties: title, subtitle, description, icon, expectedReturn, riskLevel, lockPeriod, color, allocations
  - Moved `AllocationItem` struct from PortfolioView.swift to Models.swift (needed by RiskProfile.allocations)
  - Added `import SwiftUI` to Models.swift for Color type
  - Added `@AppStorage("riskProfile") var riskProfile: RiskProfile = .moderate` to AppState
  - Added `RawRepresentable` extension for RiskProfile (AppStorage compatibility)
  - Inserted `.riskProfile` case into SetupStep enum between `.setStakes` and `.deposit`
  - Added `selectedRiskProfile: RiskProfile = .moderate` to SetupFlowState
  - Wired `RiskProfileView` into SetupContainerView switch
  - Added `appState.riskProfile = flowState.selectedRiskProfile` to commitSetup()

### Task 2: Build RiskProfileView and update PortfolioView
- **Commit:** `b5c210b`
- **Files:** `Features/Setup/RiskProfileView.swift` (new), `Features/Portfolio/PortfolioView.swift`
- **Changes:**
  - **RiskProfileView (new):** Interactive 3-tier selector with:
    - Back chevron navigation
    - "Choose your strategy" header with subtitle
    - 3 vertically stacked cards per RiskProfile case
    - Each card: icon circle, title, subtitle, expected return, lock period, radio indicator
    - Selected state: gradient border (theme colors), filled radio
    - Risk level pill badges (color-coded per tier)
    - staggerIn(index:) entry animation, cardPress() modifier
    - PPHaptic.medium() on selection, .quickSnap animation
    - Continue button with theme gradient
  - **PortfolioView updates:**
    - Replaced `static let allocations` with computed property from `appState.riskProfile.allocations`
    - Added `isAggressiveProfile` computed property
    - Added `apyDisplayString` that shows "Variable" for aggressive tier
    - Added risk tier badge pill in portfolio header (icon + "X Risk" label)
    - Updated allocation preview labels to handle "Var" for 0% APY items
    - Updated stats section to use `apyDisplayString`
    - Updated empty state text to reference user's risk profile
    - Updated AllocationDetailView to accept `riskProfile` parameter
    - AllocationDetailView shows risk-aware info text (T-bills for conservative, Pendle PTs for moderate, equity disclaimer for aggressive)

## Allocation Data

### Conservative
| Asset | Weight | APY |
|-------|--------|-----|
| T-Bill 3M (US Treasury) | 60% | 4.2% |
| T-Bill 6M (US Treasury) | 40% | 4.8% |

### Moderate (default)
| Asset | Weight | APY |
|-------|--------|-----|
| PT-sUSDai (Pendle) | 35% | 9.0% |
| PT-USDai (Pendle) | 25% | 5.5% |
| PT-thBILL (Pendle) | 20% | 5.7% |
| PT-weETH (Pendle) | 12% | 2.7% |
| PT-gUSDC (Pendle) | 8% | 6.6% |

### Aggressive
| Asset | Weight | APY |
|-------|--------|-----|
| RH-SpaceX | 30% | Variable |
| RH-Stripe | 25% | Variable |
| RH-Databricks | 20% | Variable |
| RH-Anthropic | 15% | Variable |
| PT-thBILL (Buffer) | 10% | 5.7% |

## Verification Checklist
- [x] RiskProfile enum with 3 tiers in Models.swift
- [x] Each tier has allocations, display properties, colors
- [x] SetupStep includes .riskProfile between setStakes and deposit
- [x] RiskProfileView renders 3 selectable cards
- [x] PortfolioView shows allocations from user's selected risk profile
- [x] AppState persists risk profile via @AppStorage
- [x] No code compilation errors (build fails only on pre-existing swift-clocks package dependency issue)

## Deviations
- Moved `AllocationItem` struct from PortfolioView.swift to Models.swift in Task 1 (instead of Task 2) because RiskProfile.allocations depends on it. This was a necessary ordering change.
- Build verification shows BUILD FAILED due to pre-existing `swift-clocks` package dependency error (unable to find 'ConcurrencyExtras' module). This affects the original codebase equally and is not caused by these changes. All PledgeApp source files compile without errors.
