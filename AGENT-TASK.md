# Pledge App — TestFlight Build Task

## Goal
Make this app **fully functional and compilable** so it can be submitted to TestFlight. Currently we have 24 SwiftUI files with UI built but NO Xcode project and NO working data layer.

## IMPORTANT: Read These First
1. `../pledge-ui-spec-v2.md` — Full UI specification with all screens, flows, animations
2. `Core/Models.swift` — Current data models
3. `Core/AppState.swift` — Current state (uses mock data)
4. `PledgeApp.swift` — App entry point
5. All files in `Features/` — Existing UI views

## What Needs To Be Done

### 1. Create Xcode Project
- Create a proper Swift Package or Xcode project structure
- Target: iOS 18+ (use iOS 18 APIs, not iOS 26 — we need it to work NOW)
- Bundle ID: `com.pledge.app`
- App name: Pledge
- Add all existing Swift files to the project

### 2. Fix iOS Compatibility
- The current code targets iOS 26 with Liquid Glass APIs that don't exist yet
- Replace any `.glassEffect()` or Liquid Glass APIs with standard iOS 18 equivalents
- Use `.ultraThinMaterial` / `.regularMaterial` instead of glass effects
- Keep the Hyperliquid-inspired visual style (clean white, bold numbers, black capsules)

### 3. SwiftData Persistence Layer
- Add SwiftData models for: Habit, HabitLog, UserProfile
- Replace the mock data in AppState with real SwiftData queries
- Habits should persist across app launches
- Habit check-ins should be logged with timestamps

### 4. Build Habit Flows (Core Feature)
These are the MOST IMPORTANT screens to build:

#### a. Add Habit Flow
- Screen 1: Habit selection grid (show all HabitType cases as tappable cards with icons)
- Screen 2: Configure habit (set schedule — which days, set target value if applicable)
- Screen 3: Set stake amount (custom number pad, preset pills: $5, $10, $25, $50)
- Screen 4: Confirmation — Create button

#### b. Habit Detail Sheet
- Shows habit name, icon, current streak, success rate
- Calendar view showing check-in history (green = done, red = missed, gray = future)
- Stake history (total staked, total penalties, total saved)
- Edit / Pause / Delete buttons

#### c. Daily Check-In Flow
- Tap a habit on Home → opens check-in sheet
- For simple habits: Yes/No
- For measurable habits (steps, water): enter value with number pad
- Success animation on completion
- Update streak counter

#### d. Habit Editing
- Edit stake amount, schedule, target value
- Pause habit (stops penalties but breaks streak)
- Delete habit (confirmation dialog)

### 5. Make Home Tab Functional
- Today's habits from real data (habits scheduled for current day)
- Tapping a habit opens check-in flow
- Verified count updates in real-time
- Streak calculated from consecutive completed days

### 6. Make Portfolio Tab Functional (Simulated)
- Show total penalties as "Investment Pool"
- Fake portfolio allocation (BTC 40%, ETH 30%, SOL 20%, Other 10%)
- Simple line chart using Swift Charts

### 7. Working Settings
- Profile name editing
- Dark mode toggle
- Notification preferences

### 8. Navigation & State
- Proper NavigationStack usage
- Sheet presentations for detail views

## Design Guidelines (Keep These!)
- White bg, black text, blue accent (#0EA5E9), violet portfolio (#7C3AED), green success (#22C55E), red missed (#EF4444), orange streaks (#F97316)
- SF Pro Rounded for big numbers, SF Pro for body
- Black capsule CTAs (height 52, full cornerRadius)
- White cards with subtle shadow, cornerRadius 16
- Spring bounce animations, numeric text transitions
- Haptics: light impact taps, medium on completions

## Skip for MVP
- Real crypto, server-side, social features, Apple Watch, widgets, photo verification, paywall, push notifications

## Technical Notes
- SwiftData (not Core Data), Swift Charts, @Observable or @ObservableObject (consistent)
- No external dependencies — Apple frameworks only
- Must compile and run in Simulator

When completely finished, run this command:
openclaw system event --text "Done: Pledge app TestFlight-ready" --mode now
