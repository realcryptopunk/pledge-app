# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pledge is an iOS habit tracking app where users stake real money on daily habits. Failed habits automatically invest stakes into a time-locked crypto portfolio ("Miss your habit, fund your future").

## Build & Run

This project uses XcodeGen to generate the Xcode project from `project.yml`:

```bash
# Generate/regenerate the Xcode project
xcodegen generate -s project.yml

# Build from command line
xcodebuild -project PledgeApp.xcodeproj -scheme PledgeApp -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16'

# Or open in Xcode
open PledgeApp.xcodeproj
```

**Target:** iOS 17.0+ | Swift 5.9 | Xcode 16+

No external dependencies — pure SwiftUI + Foundation.

## Architecture

**App entry point** (`PledgeApp.swift`): Routes between Splash → Onboarding → Auth → MainTabView based on AppState. Forces dark mode globally.

**Two-layer structure:**

- `Core/` — Shared infrastructure
  - `AppState.swift` — @MainActor ObservableObject, central state holder. Uses @AppStorage for persistence, @Published for runtime state. All views access via @EnvironmentObject.
  - `Models.swift` — Data models: `Habit`, `HabitLog`, `TodayHabit`, `ActivityItem` with mock data (no backend yet).
  - `Design/` — Full design system (see below).

- `Features/` — Feature modules, one folder per feature. Each contains its own views.
  - Flow: Splash → Onboarding (3 pages) → Auth (Phone → OTP) → Main (5 tabs: Home, Habits, Portfolio, Social, Settings)

## Design System

The app uses a **skeuomorphic + glassmorphism hybrid** aesthetic inspired by Hyperliquid.

**Theme system:** 6 themes (Aqua, Amethyst, Emerald, Sunset, Rose, Midnight) defined in `BackgroundTheme.swift`. Theme colors are distributed via a custom SwiftUI environment key (`\.themeColors`). Access in views:

```swift
@Environment(\.themeColors) var theme
```

**Key design files:**
- `PledgeColors.swift` — Static color palette (pledgeBg, pledgeBlack, pledgeBlue, etc.)
- `PledgeButtons.swift` — Button styles: Primary, Accent, Secondary, Destructive, Ghost, Pill
- `PledgeCards.swift` — Card components: AccentCard, CleanCard, FlatCard, StatRow
- `PledgeAnimations.swift` — Animation presets: `.springBounce`, `.quickSnap`, `.staggerIn(index:)`
- `AquaBevel.swift` / `AquaGlass.swift` / `AquaTextures.swift` — Skeuomorphic effects as view modifiers (`.aquaBevel()`, `.aquaGlass()`, `.embossed()`)
- `PledgeHaptics.swift` — Haptic feedback helpers

**Conventions:**
- All styling via SwiftUI view modifiers and extensions
- Typography presets in `PledgeTypography.swift` (pledgeXL: 96pt, pledgeHero: 48pt, etc.) with monospaced for monetary values
- Use MARK comments to organize view sections
- NavigationStack (not NavigationView)

## Documentation

- `PRD.md` — Product requirements document
- `UI-SPEC.md` — Design system specification (colors, typography, components, animations)
