# Pledge — Complete UI & Flow Specification v2

**Version:** 2.0
**Date:** February 25, 2026
**Design Language:** Hyperliquid-inspired — clean, white, bold, confident
**Platform:** iOS 26+, SwiftUI

---

## Design System

### Core Philosophy
Inspired by Hyperliquid's UI: massive bold numbers, clean white backgrounds, floating decorative orbs, black capsule CTAs, stat rows with thin dividers, custom number pads, and vibrant accent-colored feature cards. The app should feel like a premium trading platform — but for discipline.

### Color Palette
| Token | Light Mode | Dark Mode | Usage |
|---|---|---|---|
| `pledgeBg` | #FFFFFF | #0A0A0F | Primary background |
| `pledgeBgSecondary` | #F8F9FA | #111118 | Section backgrounds, grouped rows |
| `pledgeBlack` | #000000 | #FFFFFF | Primary text, CTA buttons |
| `pledgeWhite` | #FFFFFF | #000000 | Inverse text (on dark fills) |
| `pledgeBlue` | #0EA5E9 | #38BDF8 | Primary accent — pledges, active tabs, verify buttons |
| `pledgeViolet` | #7C3AED | #8B5CF6 | Investment pool, premium features |
| `pledgeGreen` | #22C55E | #4ADE80 | Verified, gains, success states |
| `pledgeRed` | #EF4444 | #F87171 | Missed habits, penalties, losses |
| `pledgeOrange` | #F97316 | #FB923C | Streaks, fire emoji, warnings |
| `pledgeGray` | #6B7280 | #9CA3AF | Secondary text, captions |
| `pledgeGrayLight` | #E5E7EB | #374151 | Borders, dividers, inactive pills |
| `pledgeGrayUltra` | #F3F4F6 | #1F2937 | Card backgrounds (subtle) |

### Typography
| Style | Font | Size | Weight | Usage |
|---|---|---|---|---|
| `.pledgeXL` | SF Pro Rounded | 96pt | Black (900) | The One Big Number — primary stat on a page |
| `.pledgeHero` | SF Pro Rounded | 48-64pt | Bold (700) | Dollar amounts on home, portfolio value |
| `.pledgeDisplay` | SF Pro Rounded | 36pt | Bold | Secondary big numbers — streak, XP |
| `.pledgeTitle` | SF Pro | 20pt | Bold | Screen titles, section headers |
| `.pledgeHeadline` | SF Pro | 17pt | Semibold | Card titles, habit names, row labels |
| `.pledgeBody` | SF Pro | 15pt | Regular | Descriptions, body text |
| `.pledgeCallout` | SF Pro | 14pt | Medium | Button text, small headers |
| `.pledgeCaption` | SF Pro | 12pt | Medium | Timestamps, helper text, fine print |
| `.pledgeMono` | SF Mono | 15pt | Semibold | Dollar values in stat rows, percentages |
| `.pledgeMonoSmall` | SF Mono | 12pt | Medium | Secondary money values |

### Component Library

#### Buttons
| Style | Spec | Example |
|---|---|---|
| **Primary (Black Capsule)** | Black fill, white text, 15pt Semibold, height 52, cornerRadius 999, full-width | "Add Funds", "Set Pledge", "Get Started" |
| **Secondary (Gray Capsule)** | #F3F4F6 fill, black text, same dimensions | "Add Cash", "Skip" |
| **Accent (Blue Capsule)** | #0EA5E9 fill, white text, same dimensions | "Verify Now", "Deposit" |
| **Accent (Violet Capsule)** | #7C3AED fill, white text, same dimensions | "View Portfolio" |
| **Destructive (Red Tint)** | #FEE2E2 fill, #EF4444 text, same dimensions | "Withdraw Early", "Delete" |
| **Ghost** | No fill, #6B7280 text, no border | "Resend Code", "Skip for now" |
| **Dual CTA** | Two buttons side-by-side, 50/50 width, 12px gap, left = dark, right = blue | "Withdraw" / "Deposit" |
| **Pill Toggle** | Small capsules in a row, selected = black fill + white text, unselected = #F3F4F6 + gray text | "$5 $10 $25", time ranges |

#### Cards
| Style | Spec | Example |
|---|---|---|
| **Accent Card** | Solid color fill (#0EA5E9, #7C3AED, #F97316), white text, cornerRadius 20, padding 20, no border | Today's Pledges, Streak, Portfolio |
| **Clean Card** | White fill, shadow(color: .black.opacity(0.06), radius: 8, y: 2), cornerRadius 16, padding 16 | Habit cards, settings groups |
| **Flat Card** | #F8F9FA fill, no shadow, cornerRadius 16, padding 16 | Chart container, number pad bg |
| **Stat Row** | No card — label left, value right, separated by 1px #E5E7EB divider, padding vertical 14 | Portfolio stats, discipline stats |

#### Floating Orbs (Decorative)
- Circles, 40-80pt diameter
- Colors: pastel blue (#93C5FD), pastel pink (#F9A8D4), pastel green (#86EFAC), pastel violet (#C4B5FD), pastel orange (#FDBA74)
- Gaussian blur: 20-30pt
- Opacity: 25-35%
- Animation: slow random drift, 8-12s cycle, subtle scale breathing 0.95-1.05
- Used on: Home hero section, onboarding backgrounds, deposit screen

#### Navigation
| Element | Spec |
|---|---|
| **Top Pills** | Horizontal scrollable row of capsule pills. Selected: black fill + white text. Unselected: no fill + gray text. Gap: 8px. Height: 34. |
| **Tab Bar** | 5 tabs. Active: black icon + label. Inactive: gray icon + label. No background tint. Thin top border #E5E7EB. |
| **Back Button** | "←" arrow, black, 44x44 tap target, top-left |
| **Nav Title** | Center-aligned, `.pledgeTitle`, black |

#### Number Pad (Custom)
- 3x4 grid layout
- Numbers: SF Pro, 28pt, Regular, black
- Keys: no visible borders, 64x64 tap target
- Tap feedback: background briefly flashes #F3F4F6, scale 0.95→1.0 with `quickSnap`
- Bottom row: "." / "0" / "←" (backspace icon)
- Used for: stake amounts, deposit amounts

---

### Animations

| Name | Spec | Usage |
|---|---|---|
| `springBounce` | `.spring(response: 0.5, dampingFraction: 0.75)` | Page transitions, card appearances, sheet presentations |
| `quickSnap` | `.spring(response: 0.3, dampingFraction: 0.85)` | Button taps, toggles, pill selections, number pad |
| `heroCountUp` | `contentTransition(.numericText())` with `.animation(.easeOut(duration: 1.2))` | Big dollar amounts, streak numbers, XP score |
| `staggerIn` | `.offset(y: 20)` → `.offset(y: 0)` + `.opacity(0→1)` per item, 0.08s delay between items | Stat rows, habit lists, settings rows |
| `orbFloat` | `repeatForever`, random x/y drift ±15pt over 8-12s, scale 0.95→1.05 breathing | Floating pastel orbs on hero sections |
| `pillSlide` | `matchedGeometryEffect(id:)` on selection indicator | Tab pills, time range selectors, stake presets |
| `chartDraw` | `.trim(from: 0, to: 1)` over 1.0s with easeOut | Line charts, progress bars |
| `confettiBurst` | Vortex particle system — blue, violet, green, orange particles, 2s duration | Streak milestones, all habits verified, vault unlock |
| `shakeAlert` | `.offset(x:)` sequence: 0 → 8 → -8 → 6 → -6 → 0, 0.4s total | Failed habit penalty, error states |
| `progressFill` | Width animates from 0% → target% with `springBounce` | Habit progress bars, vault lock bar, XP bar |
| `cardPress` | Scale 1.0 → 0.97 on press, → 1.0 on release, with `quickSnap` | All tappable cards |
| `badgeScale` | Scale 0 → 1.2 → 1.0 with overshoot spring | Checkmarks appearing, notification badges, new status |
| `numPadFlash` | Background #F3F4F6 opacity 0→1→0 over 0.15s + scale 0.95→1.0 | Number pad key press |
| `slideIn` | `.transition(.move(edge: .trailing).combined(with: .opacity))` | Forward navigation |
| `slideBack` | `.transition(.move(edge: .leading).combined(with: .opacity))` | Back navigation |
| `accentPulse` | Border/shadow color opacity oscillates 0.5→1.0→0.5, 2s cycle, repeating | Active pledge card, premium badge, CTA shimmer |

---

## Complete Flow Map

```
App Launch
│
├─ First Time User
│   └─ Splash (S0) → Onboarding 1 (S1) → Onboarding 2 (S2) → Onboarding 3 (S3)
│     → Sign Up (S4) → OTP (S5) → Choose Habits (S6) → Configure Habits (S7)
│     → Set Stakes (S8) → Deposit (S9) → Success (S10) → Home (T1)
│
├─ Returning User (No Biometric)
│   └─ Splash (S0) → Home (T1)
│
└─ Returning User (Biometric ON)
    └─ Splash (S0) → Face ID Prompt → Home (T1)

Tab Bar (persistent, 5 tabs)
├─ 🏠 Home (T1)
│   ├─ Habit Card tap → Habit Detail Sheet (T1a)
│   ├─ "Verify Now" tap → Verification Flow (T1b)
│   ├─ Today's Pledges card tap → Today Detail Sheet (T1c)
│   ├─ Streak card tap → Streak History Sheet (T1d)
│   ├─ Pool card tap → navigates to Portfolio Tab (T3)
│   ├─ "Add Funds" → Deposit Flow (D1)
│   ├─ 🔔 tap → Notifications Sheet (N1)
│   └─ 👤 tap → navigates to Settings Tab (T5)
│
├─ 📋 Habits (T2)
│   ├─ Calendar day tap → Day Detail (T2a)
│   ├─ Habit row tap → Habit Detail Sheet (T1a)
│   ├─ Habit row swipe left → Quick Actions (pause/delete)
│   └─ "+" tap → Add Habit Flow (T2b → S6 → S7 → Stake Picker)
│
├─ 📈 Portfolio (T3)
│   ├─ Chart scrub → Floating tooltip
│   ├─ Time range pills → Chart redraws
│   ├─ "Edit" strategy → Strategy Picker Sheet (T3a) [Premium]
│   ├─ "Withdraw" → Withdrawal Flow (T3b)
│   ├─ "Deposit" → Deposit Flow (D1)
│   └─ Transaction row tap → Transaction Detail Sheet (T3c)
│
├─ 👥 Social (T4)
│   ├─ [Friends] / [Leaderboard] segment toggle
│   ├─ Friend row tap → Friend Profile Sheet (T4a)
│   ├─ "Add +" → Invite Sheet (T4b)
│   └─ Challenge card tap → Challenge Detail (T4c)
│
└─ ⚙️ Settings (T5)
    ├─ Profile → Edit Profile Sheet (T5a)
    ├─ Payment Methods → Stripe Sheet (T5b)
    ├─ Deposit / Withdraw → Balance Flow (D1 / T3b)
    ├─ Notifications → Preferences (T5c)
    ├─ Premium → Paywall Sheet (T5d)
    ├─ Pause All → Confirmation Alert
    ├─ Self-Exclusion → Confirmation Flow (T5e)
    └─ Sign Out / Delete → Destructive Alert
```

---

## Screen Specifications

---

### S0: Splash Screen

**Duration:** 0.8s, auto-advances

**Layout:**
- Background: `pledgeBg` (white)
- Center: Pledge logo — shield icon with inner checkmark, 80pt
  - Color: `pledgeBlack`
- Below logo (12pt gap): "Pledge" wordmark, `.pledgeTitle`, `pledgeBlack`

**Animations:**
- Logo: `scaleEffect(0.8)` → `scaleEffect(1.0)` with `springBounce`
- Logo opacity: 0 → 1 over 0.3s
- Wordmark: fades in 0.3s after logo settles
- Background: clean white, no effects
- Transition out: `.opacity` crossfade to next screen, 0.4s

---

### S1: Onboarding — Screen 1 of 3: "The Problem"

**Layout:**
- Background: `pledgeBg` (white)
- Top 45% of screen: illustration area
  - Centered illustration: a phone showing habit checkboxes being unchecked one by one
  - Style: flat vector, minimal, using `pledgeGray` + `pledgeRed` accents
  - OR: Vortex particle animation — checkmarks dissolving into nothing
- Bottom 55%:
  - Title: **"Habits are easy to start.\nImpossible to keep."**
    - `.pledgeHero(36)`, `pledgeBlack`, center-aligned
    - Each line fades in sequentially, 0.3s apart
  - Subtitle: "92% of people abandon their habits within 30 days."
    - `.pledgeBody`, `pledgeGray`, center-aligned
    - Fades in 0.3s after title complete
  - Page dots: 3 dots, centered, 8pt circles
    - Active: `pledgeBlack` filled, 24pt wide (pill shape)
    - Inactive: `pledgeGrayLight` filled, 8pt circle
  - "Next" text button: right-aligned, `.pledgeCallout`, `pledgeGray`
  - Or swipe horizontal to advance

**Animations:**
- Illustration plays on appear
- Title words: stagger fade-in, 0.15s per line
- Subtitle: fade in 0.3s after title
- Page dots: active dot width animates with `matchedGeometryEffect`
- Page swipe: content slides horizontally with `springBounce`
- Haptic: none

---

### S2: Onboarding — Screen 2 of 3: "The Solution"

**Layout:**
- Background: `pledgeBg`
- Top illustration: Dollar bills floating from a broken habit icon → landing on a growing chart
  - Style: bills are small green rectangles with $ symbol
  - Chart: simple line going up, drawn with `chartDraw` animation
  - Flat vector or Vortex particles
- Title: **"What if every failure\nmade you richer?"**
  - `.pledgeHero(36)`, `pledgeBlack`
- Subtitle: "When you miss a pledge, we invest the money for you. You're building discipline or building wealth."
  - `.pledgeBody`, `pledgeGray`
- Page dots + "Next"

**Animations:**
- Dollar bills: particle system, 5-8 small rectangles floating left → right with slight randomized arc
- Chart line: `trim(from: 0, to: 1)` drawing over 1.5s, starts 0.5s after bills begin moving
- Title/subtitle: same stagger pattern as S1
- Page dot: pill slides to position 2

---

### S3: Onboarding — Screen 3 of 3: "How It Works"

**Layout:**
- Background: `pledgeBg`
- No illustration — instead, 3 stacked horizontal cards:
  - Card 1: 🎯 icon (in blue circle) + **"Set a habit"** + "Wake up early, work out, limit screen time"
  - Card 2: 💰 icon (in green circle) + **"Stake your money"** + "$10 says you'll follow through"
  - Card 3: 📈 icon (in violet circle) + **"Miss it? It's invested."** + "Your penalty grows in your portfolio"
  - Each card: `pledgeGrayUltra` background, cornerRadius 16, padding 16
  - Icon: 40pt circle with pastel color fill, emoji/SF Symbol centered
  - Title: `.pledgeHeadline`, `pledgeBlack`
  - Description: `.pledgeCaption`, `pledgeGray`
- Bottom: **"Get Started"** button
  - Black Capsule style (full-width, height 52, black fill, white text, cornerRadius 999)

**Animations:**
- Cards: `staggerIn` — each card slides up from `offset(y: 30)` with `opacity(0→1)`, 0.12s apart
- Haptic: `.light` on each card appearing
- "Get Started" button: appears 0.3s after last card, fade in + slight slide up
- Button idle: very subtle `accentPulse` shadow (black shadow opacity oscillates 0.05→0.12→0.05)
- Tap: `cardPress` (scale 0.97 → 1.0) + haptic `.medium`

---

### S4: Sign Up

**Layout:**
- Background: `pledgeBg`
- Back button: "←" top-left, black, 44x44
- Title: **"Your phone number"**
  - `.pledgeHero(36)`, `pledgeBlack`, center
- Subtitle: "We'll send you a verification code"
  - `.pledgeBody`, `pledgeGray`, center
- 40pt vertical spacer
- Phone input row:
  - Left: Country pill — "🇺🇸 +1" in `pledgeGrayUltra` capsule, 42pt height
  - Right: Phone text field — `.pledgeHeadline`, `pledgeBlack`, in `pledgeGrayUltra` rounded rect
    - Placeholder: "(555) 123-4567" in `pledgeGrayLight`
    - Keyboard: `.phonePad`
    - Auto-format as user types: (XXX) XXX-XXXX
- Error text area: `.pledgeCaption`, `pledgeRed`, below input (hidden until error)
- Spacer (pushes button to bottom)
- "Continue" button: Black Capsule, full-width
  - Disabled state: opacity 0.35
  - Enabled: opacity 1.0 (when 10 digits entered)
  - Loading state: replace text with white `ProgressView`
- Bottom text: "By continuing, you agree to our [Terms] & [Privacy Policy]"
  - `.pledgeCaption`, `pledgeGray`, links in `pledgeBlue`

**Animations:**
- Phone input: border transitions `pledgeGrayLight` → `pledgeBlue` on focus, `quickSnap`
- Continue button: opacity animates 0.35 → 1.0 when valid, `quickSnap`
- Error text: slides down + fades in, `springBounce`
- Transition to OTP: `slideIn` (right-to-left)
- Haptic: `.medium` on Continue tap

---

### S5: OTP Verification

**Layout:**
- Background: `pledgeBg`
- Back button: "←" top-left
- Title: **"Enter the code"**
  - `.pledgeHero(36)`, `pledgeBlack`, center
- Subtitle: "Sent to +1 (555) 123-4567"
  - `.pledgeBody`, `pledgeGray`
- 48pt spacer
- 6 OTP boxes in a row:
  - Each: 48w × 56h, `pledgeGrayUltra` fill, cornerRadius 12
  - Digit: `.pledgeDisplay(24)`, `pledgeBlack`, center
  - Focused box: 2pt `pledgeBlue` border
  - Unfocused: 1pt `pledgeGrayLight` border
  - Spacing: 10pt between boxes
  - Keyboard: `.numberPad`, `.oneTimeCode` content type
  - Auto-advance on digit entry
  - Paste: auto-fill all 6 digits, auto-submit
- Error text: `.pledgeCaption`, `pledgeRed` (below boxes)
- Loading: `ProgressView` (blue tint) centered, shown on auto-submit
- Spacer
- Bottom: "Resend code in 28s" — `.pledgeCallout`, `pledgeGray`
  - Timer counts down from 30
  - When 0: changes to "Resend code" button, `.pledgeCallout`, `pledgeBlue`

**Animations:**
- OTP boxes: focused box border color transitions with `quickSnap`
- Digit entered: box briefly scales 1.0 → 1.05 → 1.0, `quickSnap`
- Paste all 6: all boxes flash `pledgeBlue` border simultaneously, 0.2s
- Success: all boxes flash `pledgeGreen` background, 0.3s → auto-advance
- Error: boxes `shakeAlert`, border flashes `pledgeRed`
- Transition: `slideIn` to next screen
- Haptic: `.success` on verified, `.error` on wrong code

---

### S6: Choose Your Habits

**Layout:**
- Background: `pledgeBg`
- Title: **"What will you pledge?"**
  - `.pledgeHero(32)`, `pledgeBlack`, left-aligned, padding horizontal 20
- Subtitle: "Pick 1-3 habits to start"
  - `.pledgeBody`, `pledgeGray`
- 24pt spacer
- Counter pill (floating, top-right): "2 of 3" — small `pledgeBlue` capsule, white text
- Scrollable grid: 2 columns, 12pt gap
  - Each cell: 
    - `pledgeGrayUltra` fill, cornerRadius 16, padding 16
    - Icon: 36pt, in colored circle (each habit has its own pastel color)
    - Name: `.pledgeHeadline`, `pledgeBlack`
    - Verification type badge: `.pledgeCaption`, `pledgeGray` — "Auto" / "HealthKit" / "Photo"
    - Height: ~110pt
  - Selected state: `pledgeBlue` 2pt border, `pledgeBlue` checkmark circle (top-right of card)
  - Unselected: no border
- Habit grid content:

| Habit | Icon | Color Circle | Verify Badge |
|---|---|---|---|
| Wake Up Early | ⏰ | Pastel orange | Auto |
| Daily Workout | 🏋️ | Pastel blue | HealthKit |
| Step Goal | 🚶 | Pastel green | HealthKit |
| Screen Time | 📵 | Pastel red | Screen Time |
| Sleep On Time | 😴 | Pastel indigo | HealthKit |
| Meditate | 🧘 | Pastel violet | HealthKit |
| No Social Media | 📱 | Pastel pink | Screen Time |
| Read | 📖 | Pastel amber | Photo |
| Cold Shower | 🥶 | Pastel cyan | Photo |
| Journal | ✍️ | Pastel teal | In-App |
| Drink Water | 💧 | Pastel sky | Manual |
| No Junk Food | 🥗 | Pastel lime | Photo |

- Bottom (sticky): "Continue" Black Capsule — disabled until ≥1 selected

**Animations:**
- Grid cells: `staggerIn` on appear (left-to-right, top-to-bottom, 0.05s apart)
- Selection: `cardPress` on tap → blue border fades in with `quickSnap` → checkmark `badgeScale`
- Deselection: border fades out, checkmark scales down to 0
- Counter pill: number uses `heroCountUp` transition
- Haptic: `.selection` on each tap
- Transition: `slideIn`

---

### S7: Configure Each Habit (Paged)

**Layout (repeats per selected habit, horizontal paging):**
- Background: `pledgeBg`
- Top: progress bar
  - Full width, 4pt height, `pledgeGrayLight` track, `pledgeBlue` fill
  - Fill width = (current habit / total habits) as fraction
- Subtitle above bar: "Habit 1 of 3" — `.pledgeCaption`, `pledgeGray`
- 24pt spacer
- Habit icon: 64pt, in colored circle (matching S6 color), centered
- Habit name: `.pledgeDisplay(28)`, `pledgeBlack`, center
- 32pt spacer
- Configuration card (`pledgeGrayUltra` fill, cornerRadius 16, padding 20):
  - Content varies by habit:
  
  **Wake Up Early:**
  - Label: "I'll wake up by"
  - Time picker: iOS wheel picker, `.datePickerStyle(.wheel)`, hours + AM/PM
  - Default: 6:00 AM
  
  **Daily Workout:**
  - Label: "Minimum workout duration"
  - Pill row: [15 min] [30 min] [45 min] [60 min]
  - Selected pill: black fill, white text
  - Default: 30 min
  
  **Step Goal:**
  - Label: "Daily step target"
  - Pill row: [5,000] [7,500] [10,000] [Custom]
  - Custom: slides in a text field with number pad
  - Default: 10,000
  
  **Screen Time:**
  - Label: "Maximum daily screen time"
  - Pill row: [1h] [2h] [3h] [4h]
  - Default: 3h
  
  **Sleep On Time:**
  - Label: "I'll be asleep by"
  - Time picker: wheel, hours + AM/PM
  - Default: 11:00 PM
  
  **Meditate:**
  - Label: "Minimum session"
  - Pill row: [5 min] [10 min] [15 min] [20 min]
  - Default: 10 min

- Schedule section (below config card):
  - Label: "Which days?" — `.pledgeHeadline`
  - Day pills: M T W T F S S (7 circles, 40pt each)
    - Selected: `pledgeBlack` fill, white letter
    - Unselected: `pledgeGrayUltra` fill, `pledgeGray` letter
  - Quick presets below: "Daily" / "Weekdays" / "Custom" text buttons

- Info card (bottom, small):
  - 💡 icon + "How we verify:" + description
  - `.pledgeCaption`, `pledgeGray`
  - `pledgeGrayUltra` background, cornerRadius 12

- Bottom: "Next →" Black Capsule (or "Set Your Stakes →" on last habit)

**Animations:**
- Progress bar: `progressFill` animation when advancing
- Habit icon: slight bounce on page appear
- Pill selection: `pillSlide` with `matchedGeometryEffect`
- Day circles: `quickSnap` fill animation on tap
- Time picker: system haptic on wheel tick
- Page transition: horizontal `slideIn` / `slideBack`
- Haptic: `.selection` on pill/day taps

---

### S8: Set Your Stakes

**Layout:**
- Background: `pledgeBg`
- Title: **"Put money\non it."**
  - `.pledgeHero(40)`, `pledgeBlack`, left-aligned
- 32pt spacer
- Per-habit stake rows (stacked, clean card style):
  - Each row: `pledgeGrayUltra` fill, cornerRadius 16, padding 16
  - Left: habit icon (24pt) + habit name (`.pledgeHeadline`)
  - Right: stake amount pills in a row
    - [$5] [$10] [$25] [Custom]
    - Selected: `pledgeBlack` fill, white text, cornerRadius 999
    - Unselected: `pledgeGrayLight` fill, `pledgeGray` text
    - Custom: tapping opens inline number field
  - 8pt gap between rows

- 24pt spacer
- Summary section (no card, just clean stat rows):
  - Thin `pledgeGrayLight` dividers between rows
  - Row: "Daily exposure" → "$45" (`.pledgeMono`, `pledgeBlack`)
  - Row: "Weekly exposure" → "$225"
  - Row: "Monthly max" → "$900"
  - Row: "Free passes" → "1 per week" with ⓘ info button
  
- Bottom (sticky):
  - Informational note: "You keep everything when you succeed. Miss a habit and it's invested for you."
    - `.pledgeCaption`, `pledgeGray`, center
  - "Fund Your Account →" Black Capsule

**Animations:**
- Rows: `staggerIn` on appear
- Pill selection: `pillSlide` with `matchedGeometryEffect`
- Summary amounts: `heroCountUp` when stakes change
- Haptic: `.selection` on pill tap, `.medium` on Continue
- Transition: `slideIn`

---

### S9: Deposit Funds

**Layout:**
- Background: `pledgeBg`
- Back button: "←"
- Title area (top center):
  - "Fund your pledge" — `.pledgeCaption`, `pledgeGray`
  - Amount: **"$100"** — `.pledgeXL(72)`, `pledgeBlack`, center
    - Dynamically updates as user taps number pad
  - "Minimum deposit: $50" — `.pledgeCaption`, `pledgeGray`

- Quick amount pills (centered row):
  - [$50] [$100] [$200] [$500]
  - Selected: `pledgeBlack` fill, white text
  - Unselected: `pledgeGrayUltra` fill, `pledgeGray` text

- Spacer

- Custom number pad (centered):
  ```
      1       2       3
      4       5       6
      7       8       9
      .       0       ←
  ```
  - SF Pro, 28pt, Regular, `pledgeBlack`
  - No borders, 64x64 tap targets
  - Grid: 3 columns, 16pt row spacing

- Bottom (sticky, above safe area):
  - Apple Pay button: standard `PKPaymentButton`, full width, height 52, cornerRadius 999
  - "Or pay with card" — `.pledgeCallout`, `pledgeBlue`, tappable → opens Stripe card sheet
  - 8pt spacer
  - 🔒 "Funds held securely. Withdraw anytime." — `.pledgeCaption`, `pledgeGray`

**Animations:**
- Amount number: `heroCountUp` on each digit/preset change
- Quick pills: `pillSlide` selection
- Number pad keys: `numPadFlash` on tap (gray bg flash + scale 0.95→1.0)
- Apple Pay button: subtle shimmer effect — diagonal white gradient sweep, 4s cycle, repeating
- Haptic: `.light` on number tap, `.selection` on pill tap, `.medium` on Apple Pay

---

### S10: Deposit Success → First Pledge

**Layout:**
- Background: `pledgeBg` with floating pastel orbs (5-7 orbs scattered)
- Center content:
  - Large checkmark in circle: 80pt, `pledgeGreen` circle fill, white checkmark
  - 16pt spacer
  - **"You're in."** — `.pledgeHero(44)`, `pledgeBlack`
  - 8pt spacer
  - "Your first pledge starts tomorrow" — `.pledgeBody`, `pledgeGray`
  - 32pt spacer
  - Summary stats (centered, no cards):
    - "$100 loaded" — `.pledgeHeadline`, `pledgeBlack`
    - "3 habits pledged" — `.pledgeBody`, `pledgeGray`
    - "$45/day at stake" — `.pledgeBody`, `pledgeGray`
  - 24pt spacer
  - Countdown: "First habit in **8h 23m**"
    - Time portion: `.pledgeMono`, `pledgeBlue`
    - Live updating every second

- Bottom: **"Let's Go"** Black Capsule → dismisses to Home (T1)

**Animations:**
- Orbs: `orbFloat` — slow drift + breathing
- Checkmark circle: `badgeScale` (0 → 1.2 → 1.0)
- `confettiBurst` fires 0.3s after checkmark lands — blue, violet, green, orange particles
- Title: fades in 0.2s after checkmark
- Stats: `staggerIn`, 0.1s apart
- Countdown: `heroCountUp` on appear, live `contentTransition(.numericText())` updates
- Haptic: `.success` on appear
- Transition: `.fullScreenCover` dismisses downward to reveal Home tab

---

### T1: Home Tab

**Layout:**

```
┌──────────────────────────────────────┐
│                              🔔  👤  │  ← Top-right icons, black
│                                      │
│  Balance                             │  ← .pledgeCaption, pledgeGray
│  $247.00                             │  ← .pledgeHero(56), pledgeBlack
│  +5.8% this month                    │  ← .pledgeCaption, pledgeGreen
│                                      │
│  ┌──────────────────────────────┐    │
│  │    ○        ○        ○       │    │  ← Floating orbs area
│  │  ○     ○        ○            │    │    (pastel blue, pink, green,
│  │       ┌──────────────┐       │    │     violet, orange)
│  │       │  Add funds   │       │    │  ← Black capsule, centered
│  │       └──────────────┘       │    │    Width: 140pt, height: 44
│  │    ○          ○        ○     │    │
│  │       ○              ○       │    │
│  └──────────────────────────────┘    │  ← Height: ~160pt
│                                      │
│  ┌────────────────────────────────┐  │
│  │  Today's Pledges            ›  │  │  ← BLUE accent card
│  │                                │  │    pledgeBlue fill
│  │  $45.00                        │  │  ← .pledgeDisplay(36), white
│  │                                │  │
│  │  📊 At stake        $45.00    │  │  ← White text rows
│  │  ✅ Verified         2 of 4    │  │
│  └────────────────────────────────┘  │
│                                      │
│  TODAY                               │  ← .pledgeCaption, pledgeGray
│                                      │    (section header, tracking caps)
│  ┌────────────────────────────────┐  │
│  │ ⏰  Wake Up 6:00 AM           │  │  ← Clean white card
│  │     Verified 5:47 AM     $10  │  │    with subtle shadow
│  │                           ✅   │  │    Green check right-aligned
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │  ← 1px divider
│  │ 🏋️  Gym Session (30+ min)     │  │
│  │     Closes 11:59 PM     $10  │  │
│  │                           ⏳   │  │  ← Amber clock
│  │             ┌─────────────┐   │  │
│  │             │ Verify Now  │   │  │  ← Blue capsule button
│  │             └─────────────┘   │  │    Small, right-aligned
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │ 📵  Screen Time < 3hrs        │  │
│  │     1h 47m used               │  │
│  │     ▓▓▓▓▓▓▓░░░░  1h 13m left │  │  ← Thin progress bar
│  │                      $25  ⏳   │  │    Blue fill on gray track
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │ 😴  Sleep by 11:00 PM         │  │
│  │     Verifies tomorrow AM      │  │
│  │                      $10  🔒   │  │  ← Gray lock icon
│  └────────────────────────────────┘  │
│                                      │
│  ┌─────────────┐  ┌──────────────┐  │  ← Two accent cards, side by side
│  │ 🔥 Streak   │  │ 💰 Pool      │  │
│  │             │  │              │  │
│  │    23       │  │   $261       │  │  ← .pledgeDisplay(32), white
│  │   days      │  │   +5.8%     │  │
│  └─────────────┘  └──────────────┘  │
│  (pledgeOrange)    (pledgeViolet)    │
│                                      │
│  RECENT                              │  ← Section header
│  ┌────────────────────────────────┐  │
│  │ ❌  Missed gym · yesterday     │  │  ← Clean card, stat rows
│  │     $10 → Investment Pool      │  │    Red icon for miss
│  │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │  │
│  │ ✅  Woke up 5:52 AM · yesterday│  │    Green icon for verified
│  │     $10 saved                  │  │
│  └────────────────────────────────┘  │
│                                      │
│     [🏠] [📋] [📈] [👥] [⚙️]       │  ← Tab bar
└──────────────────────────────────────┘
```

**Component Behavior:**

**Balance Section (top)**
- "Balance" label: `.pledgeCaption`, `pledgeGray`
- Amount: `.pledgeHero(56)`, `pledgeBlack`, `heroCountUp` on appear
- Change: `.pledgeCaption`, `pledgeGreen` (or `pledgeRed` if negative)

**Floating Orbs Area**
- 5-7 pastel circles, blurred, floating
- "Add funds" black capsule centered in the middle
- Height: ~160pt
- Orbs: `orbFloat` animation, slow drift
- Tap "Add funds": navigate to Deposit flow (D1)

**Today's Pledges Card (Blue)**
- `pledgeBlue` solid fill, cornerRadius 20, padding 20
- All text white
- Amount: `.pledgeDisplay(36)`
- Tap: opens Today Detail sheet (T1c)
- Arrow "›" right-aligned indicates tappable

**Habit Cards**
- Single clean white card with subtle shadow, all habits as rows separated by dashed dividers
- Each row:
  - Left: emoji + habit name (`.pledgeHeadline`) + detail line (`.pledgeCaption`, `pledgeGray`)
  - Right: stake amount (`.pledgeMono`) + status icon
  - Status icons: ✅ (green), ⏳ (amber), 🔒 (gray), ❌ (red)
- Pending habits with "Verify Now" show a small blue capsule button
- Screen Time habit shows a thin progress bar (4pt height, `pledgeBlue` fill on `pledgeGrayLight` track)
- Entire row tappable → opens Habit Detail sheet (T1a)

**Stat Cards (Streak + Pool)**
- Side by side, equal width, 12pt gap
- Streak: `pledgeOrange` fill, white text, 🔥 emoji, number in `.pledgeDisplay(32)`, "days" in `.pledgeCaption`
- Pool: `pledgeViolet` fill, white text, 💰 emoji, dollar value in `.pledgeDisplay(32)`, +% in `.pledgeCaption`
- Each tappable: streak → Streak sheet, pool → Portfolio tab

**Recent Activity**
- Clean card with stat rows
- Each row: status emoji + description + timeago, on second line: outcome
- ❌ items: `pledgeRed` tinted text for penalty
- ✅ items: `pledgeGreen` tinted text for saved

**Animations:**
- On appear: balance `heroCountUp`, orbs start `orbFloat`, pledges card slides up with `springBounce`
- Habit rows: `staggerIn` (0.06s apart)
- Stat cards: `staggerIn` after habit rows
- Pull to refresh: custom spinner — small blue circle rotating
- Habit verified (real-time): row flashes green bg (0.3s), ✅ `badgeScale` in, `confettiBurst` if all daily habits complete
- Habit failed (midnight push): row bg flashes red (0.3s), `shakeAlert` on the card, ❌ appears
- Bell icon: red notification badge `badgeScale` when new unread
- Haptic: `.success` when habit verified, `.error` when penalty

**Tab Bar:**
- 5 icons + labels
- Active: `pledgeBlack` icon + label
- Inactive: `pledgeGray` icon + label
- 1px `pledgeGrayLight` top border
- No background tint, just `pledgeBg`
- Icons: 🏠 Home, 📋 Habits, 📈 Portfolio, 👥 Social, ⚙️ Settings

---

### T1a: Habit Detail (Sheet)

**Presented as:** `.sheet(detents: [.medium, .large])`

**Layout:**
- Drag indicator: gray pill, centered top
- Header: Habit icon (48pt, colored circle) + name (`.pledgeTitle`) + status badge
- 20pt spacer

**Week Strip:**
- Horizontal row: M T W T F S S
- Each day: 36pt circle
  - ✅ done: `pledgeGreen` fill, white checkmark
  - ❌ missed: `pledgeRed` fill, white X
  - ⏳ pending (today): `pledgeBlue` ring, no fill
  - · future: `pledgeGrayLight` fill
  - · not scheduled: no circle, just gray dot

**Stats (stat rows, dividers):**
- 🔥 Current streak → "23 days"
- 📊 Success rate → "87%"
- 💰 Total saved → "$180"
- 📈 Total invested → "$30"
- ⏰ Stake → "$10/day"
- 📅 Schedule → "Weekdays"
- 🔍 Verification → "HealthKit workout data"

**History (scrollable list):**
- Last 14 days, each: date + time verified + ✅/❌
- Clean rows with thin dividers

**Actions (bottom):**
- "Edit Habit" — Ghost button, `pledgeBlue`
- "Pause Habit" — Ghost button, `pledgeOrange`
- "Delete Habit" — Ghost button, `pledgeRed`

**Animations:**
- Sheet: `springBounce` presentation
- Week circles: `staggerIn` left-to-right
- Stats: `staggerIn`
- Numbers: `heroCountUp`

---

### T1b: Verification Flow

**Auto-Verified Habits (Wake Up, Workout, Steps, Sleep, Screen Time, Meditate):**
- No manual flow. Background verification via HealthKit / DeviceActivity / timestamp.
- User sees push notification: "✅ Gym session verified at 7:32 AM. $10 saved."
- Home screen habit card updates in real-time.

**Photo-Verified Habits (Read, Cold Shower, Meals, Clean Room):**

**Presented as:** `.fullScreenCover`

**Layout:**
- Camera viewfinder: full screen
- Top overlay (safe area): habit icon + "📖 Take a photo to verify reading"
  - `.pledgeHeadline`, white, shadow for readability
- Bottom controls:
  - Flash toggle (top-left): SF Symbol, white
  - Capture button (center): 72pt white circle with 4pt `pledgeBlue` ring
  - Camera flip (top-right): SF Symbol, white
- After capture:
  - Photo fills screen with slight zoom-back animation
  - Overlay: timestamp + location watermark (bottom-left, small, semi-transparent)
  - ML analysis: "Analyzing..." spinner (1-2s)
  - Result card (slides up from bottom, white, cornerRadius 20):
    - ✅ "Looks like a book! Verified." — `pledgeGreen` icon, `.pledgeHeadline`
    - OR ⚠️ "We couldn't verify this. Try again?" — `pledgeOrange` icon
    - "Submit" Blue Capsule button / "Retake" Ghost button

**Animations:**
- Camera open: iris animation — circle mask expands from center, 0.4s
- Capture: screen flashes white, 0.1s
- Photo: slight scale 1.05 → 1.0 settle
- Analysis spinner: blue rotating circle
- Result card: slides up with `springBounce`
- Verified: `confettiBurst` if it completes all daily habits
- Haptic: `.medium` on capture, `.success` on verified

---

### T1c: Today Detail (Sheet)

**Presented as:** `.sheet(detents: [.medium])`

**Layout:**
- Title: "Today's Pledges" — `.pledgeTitle`
- Date: "Tuesday, Feb 25, 2026" — `.pledgeCaption`, `pledgeGray`
- Progress: "2 of 4 verified" with progress bar (segmented, one segment per habit)
- Stat rows:
  - Total at stake: $45
  - Verified: $20 (safe)
  - Pending: $25 (still at risk)
  - Lost today: $0
- Habit checklist: same as home card rows but expanded with timestamps

---

### T1d: Streak History (Sheet)

**Presented as:** `.sheet(detents: [.large])`

**Layout:**
- Title: "🔥 Streak" — `.pledgeTitle`
- Current: "23 days" — `.pledgeHero(48)`, `pledgeOrange`
- Longest ever: "31 days" — `.pledgeBody`, `pledgeGray`
- Calendar heat map (past 3 months):
  - Grid of small squares (GitHub contribution style)
  - Green = all habits done, Yellow = partial, Red = missed ≥1, Gray = no data
- Monthly breakdown: bar chart of success rate per month

---

### T2: Habits Tab

**Layout:**
```
┌──────────────────────────────────────┐
│  My Pledges                    [+]   │  ← .pledgeTitle + add button
│                                      │
│  ┌────────────────────────────────┐  │
│  │  ◄  February 2026  ►          │  │  ← Month nav, .pledgeHeadline
│  │                                │  │
│  │  M   T   W   T   F   S   S   │  │  ← Day headers, .pledgeCaption
│  │                         1   2  │  │
│  │  3   4   5   6   7   8   9   │  │  ← Date numbers
│  │  10  11  12  13  14  15  16  │  │
│  │  17  18  19  ●   21  22  23  │  │  ← ● = today (blue ring)
│  │  24  25                       │  │
│  │                                │  │
│  │  Day colors:                   │  │    Each date number sits on
│  │  🟢 = all done (green dot)     │  │    a small colored dot below
│  │  🟡 = partial (amber dot)     │  │    the number
│  │  🔴 = missed (red dot)        │  │
│  │  · = no data (gray dot)       │  │
│  └────────────────────────────────┘  │  ← Clean white card w/ shadow
│                                      │
│  ACTIVE                              │  ← Section header
│                                      │
│  ┌────────────────────────────────┐  │
│  │ ⏰ Wake Up Early              │  │  ← Clean card
│  │    🔥 23 days · 87% · $10/day │  │    Habit rows with dividers
│  │    Daily · Auto-verified      │  │    Swipe left for actions
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │ 🏋️ Gym Session               │  │
│  │    🔥 8 days · 72% · $10/day  │  │
│  │    Weekdays · HealthKit       │  │
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │ 📵 Screen Time < 3hrs        │  │
│  │    🔥 5 days · 65% · $25/day  │  │
│  │    Daily · Screen Time        │  │
│  └────────────────────────────────┘  │
│                                      │
│  PAUSED                              │
│  ┌────────────────────────────────┐  │
│  │ 📖 Read 30 min  (paused)     │  │
│  │    ┌────────┐                  │  │
│  │    │ Resume │                 │  │  ← Blue capsule, small
│  │    └────────┘                  │  │
│  └────────────────────────────────┘  │
│                                      │
│     [🏠] [📋] [📈] [👥] [⚙️]       │
└──────────────────────────────────────┘
```

**Interactions:**
- Tap date → expands below calendar showing that day's habit results
- Tap habit row → Habit Detail sheet (T1a)
- Swipe habit row left → reveals "Pause" (amber) and "Delete" (red) action buttons
- "+" button → Add Habit flow (S6 → S7 → stake picker, single habit)
- Month arrows: swipe or tap to change month

**Animations:**
- Calendar: month changes with horizontal slide
- Date dots: `staggerIn` on month load (left-to-right, top-to-bottom, 0.02s per date)
- Day expand: content slides down with `springBounce`
- Swipe actions: spring resistance reveal
- Habit rows: `staggerIn` on appear
- Haptic: `.selection` on date tap, `.light` on swipe reveal

---

### T2a: Day Detail (Expandable below calendar)

**Layout (inline expansion, not a sheet):**
- Slides down below the tapped date row in calendar
- Shows that day's habits as mini rows:
  - ✅ Wake Up — 5:47 AM — $10 saved
  - ❌ Gym — missed — $10 invested
  - ✅ Screen Time — 2h 41m — $25 saved
- Summary: "3 of 4 done · $10 invested"
- Collapsible — tap date again or tap another date

---

### T2b: Add Habit Flow

**Presented as:** `.fullScreenCover`
- Same screens as S6 (Choose Habit, single selection) → S7 (Configure) → Stake amount picker
- Final confirmation: "Add [habit name] · $[amount]/day"
- "Add Pledge" Blue Capsule button
- On success: dismiss with brief "Added ✅" toast at top

---

### T3: Portfolio Tab

**Layout:**
```
┌──────────────────────────────────────┐
│  ←    Investment Pool         ⭐     │  ← Nav bar (← only shows if
│                                      │    navigated from elsewhere)
│                                      │
│  $261.38                       🪙🔵  │  ← .pledgeHero(48), pledgeBlack
│  ↑$14.38 (+5.8%)                     │    Coin icons: small BTC + ETH
│  past month                          │    circles overlapping
│                                      │    Change: pledgeGreen
│  ┌────────────────────────────────┐  │
│  │                                │  │  ← Chart card (pledgeGrayUltra
│  │     ╱──╲      ╱──╲    ╱──     │  │    fill, cornerRadius 16)
│  │    ╱    ╲    ╱    ╲  ╱        │  │
│  │   ╱      ╲──╱      ╲╱   $261 │  │  ← Floating price tag at right
│  │  ╱                            │  │    edge of line
│  │                                │  │
│  │  Area fill: pledgeViolet 10%  │  │  ← Subtle violet gradient fill
│  │  Line: pledgeViolet 100%      │  │    below the line
│  │                                │  │
│  └────────────────────────────────┘  │
│                                      │
│       ┌────────────────────┐         │  ← Time pills (centered)
│       │ 1W  1M  3M  1Y ALL│         │    Gray bg, selected = black
│       └────────────────────┘         │    pill w/ white text
│                                      │
│  Stats                      ● Live   │  ← .pledgeHeadline + blue dot
│  ─────────────────────────────────── │  ← Stat rows with dividers
│  📊 24h change      +$3.21  +1.2%   │    (like Hyperliquid stats)
│  ─────────────────────────────────── │
│  📈 Total invested        $247.00   │
│  ─────────────────────────────────── │
│  🏦 Allocation        40 / 30 / 30  │  ← Tappable → Strategy sheet
│  ─────────────────────────────────── │
│  🔒 Vault unlock          47 days   │
│  ─────────────────────────────────── │
│  💸 Platform fees          $47.00   │
│  ─────────────────────────────────── │
│  🔄 Transactions               12   │  ← Tappable → Transaction list
│                                      │
│  ┌──────────────┐  ┌──────────────┐ │  ← Dual CTA
│  │  ↓ Withdraw  │  │  ↑ Deposit   │ │    Left: black capsule
│  └──────────────┘  └──────────────┘ │    Right: blue capsule
│                                      │
│     [🏠] [📋] [📈] [👥] [⚙️]       │
└──────────────────────────────────────┘
```

**Chart Behavior:**
- Swift Charts `LineMark` + `AreaMark` with gradient
- Line: `pledgeViolet`, 2pt stroke
- Area fill: `pledgeViolet` → transparent (top to bottom), 10% opacity
- Floating price tag: small pill at right end of line, shows current value
- Scrubbable: drag finger along chart → vertical line follows + floating tooltip with date + value
- Time ranges: 1W, 1M, 3M, 1Y, ALL — chart redraws with `chartDraw`

**Stat Rows:**
- Icon + label (left) in `.pledgeHeadline`
- Value (right) in `.pledgeMono`
- "● Live" blue dot pulses slowly (`accentPulse`)
- Tappable rows have "›" chevron

**Dual CTA:**
- Two buttons, 50/50 width, 12pt gap
- Withdraw: black capsule, white text
- Deposit: blue capsule, white text

**Animations:**
- Portfolio value: `heroCountUp` from $0 to actual, 1.2s
- Chart line: `chartDraw` — `trim(from: 0, to: 1)` over 1.0s
- Area fill: fades in 0.3s after line completes
- Stat rows: `staggerIn`
- Time range switch: chart crossfades to new data, line redraws
- Scrub: haptic `.selection` on each data point, tooltip follows finger
- Haptic: `.selection` on chart scrub, `.light` on pill tap

---

### T3a: Strategy Picker (Sheet — Premium)

**Presented as:** `.sheet(detents: [.medium])`

**Layout:**
- Title: "Investment Strategy" — `.pledgeTitle`
- 4 strategy cards (stacked, 8pt gap):
  
  Each card: `pledgeGrayUltra` fill, cornerRadius 16, padding 16
  - Left: strategy name (`.pledgeHeadline`) + description (`.pledgeCaption`, `pledgeGray`)
  - Right: mini allocation bar (3 colored segments: orange BTC, blue ETH, green USDC)
  - Selected card: `pledgeBlue` 2pt border + ✅ checkmark right
  
  | Strategy | Allocation | Description |
  |---|---|---|
  | Conservative | 20/10/70 | "Mostly stablecoins. Minimal risk." |
  | Balanced ✓ | 40/30/30 | "Mix of growth and stability." |
  | Aggressive | 50/40/10 | "Maximum growth exposure." |
  | Custom 🔒 | Sliders | "Set your own allocation." → 3 sliders for BTC/ETH/USDC |

- "Apply" Blue Capsule (bottom)
- Non-premium users: "Upgrade to Premium" overlay on Aggressive + Custom

**Animations:**
- Cards: `staggerIn`
- Mini allocation bars: `progressFill` to segment widths
- Selection: border fades in, checkmark `badgeScale`
- Custom sliders: real-time bar updates

---

### T3b: Withdrawal Flow (Sheet)

**Presented as:** `.sheet(detents: [.large])`

**Layout:**
- Title: "Withdraw" — `.pledgeTitle`
- If locked: amber warning banner
  - "⏰ Vault locked for 47 more days. Early withdrawal: 10% fee."
  - `pledgeOrange` left border, amber tinted background
- Amount: `.pledgeXL(56)`, center — updates with number pad
- Fee calculation (live, below amount):
  - "Withdraw $200 → $20 fee → You receive $180"
  - `.pledgeCaption`, `pledgeGray`
  - Fee amount in `pledgeRed`
- Custom number pad (same as S9)
- Destination: "Bank Account (····4829)" or "+ Add Bank Account" — row with chevron
- Processing: "1-3 business days" — `.pledgeCaption`
- CTA:
  - If locked: "Withdraw Early — 10% Fee" Destructive button (red tint)
  - If unlocked: "Withdraw" Black Capsule

**Animations:**
- Amount: `heroCountUp`
- Fee: live recalculation with `contentTransition(.numericText())`
- Number pad: `numPadFlash`

---

### T3c: Transaction Detail (Sheet)

**Presented as:** `.sheet(detents: [.medium])`

- Date + time
- Type: "Missed Gym Session"
- Amount: "$10.00"
- Breakdown: "$8.00 invested + $2.00 platform fee"
- Investment: "Bought: 0.003 ETH + 0.00012 BTC + $2.40 USDC"
- Status: "Confirmed ✅"

---

### T4: Social Tab

**Layout:**
```
┌──────────────────────────────────────┐
│  Community                    [+]    │  ← .pledgeTitle
│                                      │
│  ┌─────────────┐┌──────────────┐    │  ← Segment pills
│  │  Friends    ││ Leaderboard  │    │    (matchedGeometryEffect)
│  └─────────────┘└──────────────┘    │    Selected: black, white text
│                                      │
│  ── FRIENDS VIEW ──                  │
│                                      │
│  PARTNERS                            │
│  ┌────────────────────────────────┐  │
│  │ 🟢 Jake M.                    │  │  ← Clean card, rows
│  │    All done today   🔥 45 days │  │    Status dot: green/amber/red
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │ 🟡 Sarah K.                   │  │
│  │    2 of 3 pending   🔥 12 days│  │
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │ 🔴 Mike R.                    │  │
│  │    Missed gym       🔥 0 days │  │
│  └────────────────────────────────┘  │
│                                      │
│  ACTIVITY                            │
│  ┌────────────────────────────────┐  │
│  │ 😂 Mike missed his 6am alarm  │  │  ← Activity feed
│  │    $10 invested · 2h ago       │  │    Fun, slightly teasing tone
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │ 💪 Jake hit 30-day streak!    │  │
│  │    $0 invested this month 🏆   │  │
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │ ✅ Sarah finished all habits   │  │
│  │    $45 saved · 1h ago          │  │
│  └────────────────────────────────┘  │
│                                      │
│  ── LEADERBOARD VIEW ──             │
│                                      │
│  THIS WEEK                           │
│  ┌────────────────────────────────┐  │
│  │ 🥇  Jake M.       7/7 perfect │  │  ← Gold accent for #1
│  │ 🥈  You            5/7 days   │  │  ← Silver
│  │ 🥉  Sarah K.       4/7 days   │  │  ← Bronze
│  │  4.  Mike R.        2/7 days   │  │
│  └────────────────────────────────┘  │
│                                      │
│     [🏠] [📋] [📈] [👥] [⚙️]       │
└──────────────────────────────────────┘
```

**Interactions:**
- Segment toggle: `pillSlide` animation between Friends/Leaderboard
- Friend row tap: opens Friend Profile sheet (T4a)
- "+" button: opens Invite sheet — share link, search username, or contacts
- Activity feed: new items push in from top
- Leaderboard: ranks can shuffle with position change animation

**Animations:**
- Segment: `pillSlide` with `matchedGeometryEffect`
- Friend rows: `staggerIn`
- Activity items: new ones slide in from top with `springBounce`
- Leaderboard rank changes: rows slide to new position
- Status dots: subtle pulse for 🟢 (3s cycle)
- Haptic: `.selection` on segment tap

---

### T4a: Friend Profile (Sheet)

**Presented as:** `.sheet(detents: [.medium, .large])`

- Profile: avatar circle + name + username
- Their stats (stat rows):
  - Current streak
  - Success rate
  - Total invested
  - Member since
- Their recent activity (last 7 days)
- Actions: "Remove Friend" (destructive ghost button)

---

### T4b: Invite Sheet

**Presented as:** `.sheet(detents: [.medium])`

- Title: "Add Friends"
- Share link: "pledge.app/invite/NAVPLDG" — tappable to copy, blue text
- Share button: opens system share sheet
- Search: username search field → results
- "Import from Contacts" row

---

### T5: Settings Tab

**Layout:**
```
┌──────────────────────────────────────┐
│  Settings                            │  ← .pledgeTitle
│                                      │
│  ┌────────────────────────────────┐  │
│  │  👤  Nav                       │  │  ← Profile card
│  │      @nav · Joined Feb 2026   │  │    Avatar circle (initials)
│  │                       [Edit]  │  │    "Edit" = pledgeBlue text
│  └────────────────────────────────┘  │
│                                      │
│  ACCOUNT                             │  ← .pledgeCaption, tracking
│  ┌────────────────────────────────┐  │
│  │  💳  Payment Methods        › │  │  ← Clean card, rows
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │    with thin dividers
│  │  💰  Deposit / Withdraw     › │  │
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │  📊  Pledge History         › │  │
│  └────────────────────────────────┘  │
│                                      │
│  PREFERENCES                         │
│  ┌────────────────────────────────┐  │
│  │  🔔  Notifications          › │  │
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │  🔒  Face ID          [ ON ] │  │  ← Toggle, pledgeBlue tint
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │  🌙  Appearance       [Auto] │  │  ← System / Light / Dark
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │  💵  Default Stake       $10  │  │
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │  🛡️  Weekly Cap         $200  │  │
│  └────────────────────────────────┘  │
│                                      │
│  PREMIUM                             │
│  ┌────────────────────────────────┐  │
│  │  ⭐  Upgrade to Premium     › │  │  ← pledgeViolet left accent
│  │      Unlimited habits, custom  │  │    or subtle violet bg tint
│  │      strategies, and more      │  │
│  └────────────────────────────────┘  │
│                                      │
│  SAFETY                              │
│  ┌────────────────────────────────┐  │
│  │  ⏸️  Pause All Pledges      › │  │
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │  🚫  Self-Exclusion         › │  │
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │  📉  Reduce My Stakes       › │  │
│  └────────────────────────────────┘  │
│                                      │
│  ABOUT                               │
│  ┌────────────────────────────────┐  │
│  │  ❓  Help & Support          › │  │
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │  📄  Terms of Service        › │  │
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │  🔐  Privacy Policy          › │  │
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │  ℹ️  Version 1.0.0            │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  Sign Out                      │  │  ← pledgeGray text
│  ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  │
│  │  Delete Account                │  │  ← pledgeRed text
│  └────────────────────────────────┘  │
│                                      │
│     [🏠] [📋] [📈] [👥] [⚙️]       │
└──────────────────────────────────────┘
```

**Interactions:**
- Each row with "›" tappable → navigates to sub-screen or opens sheet
- Toggles: standard iOS toggle, `pledgeBlue` tint
- Sign Out: confirmation alert
- Delete Account: destructive confirmation with text input ("type DELETE to confirm")

**Animations:**
- Section rows: `staggerIn` per section
- Toggle: `quickSnap`
- Haptic: `.selection` on toggle, `.warning` on Sign Out/Delete

---

### T5a: Edit Profile (Sheet)

**Presented as:** `.sheet(detents: [.medium])`

- Avatar: tappable to change (camera / photos)
- Display Name: text field, `.pledgeHeadline`
- Username: text field with @ prefix, `.pledgeBody`
- "Save" Blue Capsule

---

### T5d: Paywall (Sheet)

**Presented as:** `.sheet(detents: [.large])`, non-dismissable header

**Layout:**
- Close "✕" button (top-right)
- Premium badge: shield icon with star, `pledgeViolet` circle, 64pt
  - Subtle `accentPulse` glow
- Title: **"Pledge Premium"** — `.pledgeHero(32)`, `pledgeBlack`
- Feature list (stacked rows, checkmarks):
  - ✅ Unlimited habits *(Free: 2)*
  - ✅ Photo + Location verification
  - ✅ Custom investment strategies
  - ✅ 30 / 90 / 365 day vault locks
  - ✅ 3 free passes per week *(Free: 1)*
  - ✅ Unlimited accountability partners
  - ✅ Advanced analytics & insights
  - ✅ Custom shareable cards
  - Each: green checkmark + `.pledgeBody` + dim comparison in `.pledgeCaption`

- Pricing toggle (two pills, centered):
  - [Monthly $9.99] [Annual $59.99]
  - Selected: black fill, white text
  - Annual shows "Save 50%" badge in `pledgeGreen`

- "Start Free Trial" Black Capsule (if trial) or "Subscribe" Black Capsule
- "Restore Purchases" Ghost button, `pledgeBlue`
- Fine print: auto-renewal, manage in Settings, `.pledgeCaption`, `pledgeGray`

**Animations:**
- Premium badge: `accentPulse` (violet glow oscillation)
- Feature checkmarks: `staggerIn`, 0.06s apart, checkmark `badgeScale`
- Pricing toggle: `pillSlide`
- CTA button: subtle `accentPulse` shadow
- Haptic: `.medium` on Subscribe

---

### N1: Notifications (Sheet)

**Presented as:** `.sheet(detents: [.medium, .large])` from 🔔 icon

**Layout:**
- Title: "Notifications" — `.pledgeTitle`
- Grouped by: TODAY / THIS WEEK / EARLIER — `.pledgeCaption`, `pledgeGray`
- Each notification row:
  - Icon (emoji in colored circle, 32pt)
  - Title: `.pledgeHeadline`, `pledgeBlack`
  - Detail: `.pledgeCaption`, `pledgeGray`
  - Time: `.pledgeCaption`, `pledgeGray`, right-aligned
  - Unread: small `pledgeBlue` dot, 8pt, left of icon

Types:
| Icon | Color | Title | Detail |
|---|---|---|---|
| ✅ | Green | "Gym verified" | "Saved $10 · 7:32 AM" |
| ❌ | Red | "Missed wake up" | "$10 invested · Portfolio: $261" |
| 🔥 | Orange | "25-day streak!" | "Your longest streak yet" |
| 💰 | Violet | "Portfolio update" | "Up 2.3% this week → $267" |
| 👥 | Blue | "Mike missed gym 😂" | "$10 invested · 2h ago" |
| 🔓 | Green | "Vault unlocks soon" | "7 days until your $247 unlocks" |

**Animations:**
- Rows: `staggerIn`
- Unread dot: `badgeScale` on first appear
- Mark as read: dot fades out, 0.3s

---

### M1: Midnight Penalty Sequence

**Background process, not a screen:**

11:59 PM → Verification engine checks each habit
- If unverified: push notification (30-min grace)
  - "⏰ 30 minutes to verify [habit]. $[X] at stake."
- If still unverified at 12:29 AM:
  - Push: "❌ Missed [habit]. $[invested] invested ($[fee] fee). Portfolio: $[total]"
  - If app is foregrounded:
    - Habit card: `shakeAlert` + border flashes `pledgeRed` + ❌ `badgeScale`
    - Streak number: spins down to 0 with `heroCountUp` (reverse)
    - Brief red flash overlay on card (0.2s)
  - Haptic: `.error`

---

### W1-W4: Widgets

**W1: Small (Home Screen)**
```
┌─────────────────┐
│                  │   White bg
│     🔥 23       │   .pledgeDisplay(28), black
│    day streak   │   .pledgeCaption, gray
│                  │
│    $45 today    │   .pledgeMono, pledgeBlue
└─────────────────┘
```

**W2: Medium (Home Screen)**
```
┌───────────────────────────────┐
│ Pledge              🔥 23 days│   White bg
│                               │
│ ⏰ Wake Up          ✅        │   Green check
│ 🏋️ Gym              ⏳  $10   │   Amber pending
│ 📵 Screen           ⏳  $25   │   
│                               │
│ $45 at stake today            │   .pledgeMono
└───────────────────────────────┘
```

**W3: Lock Screen**
- Circular: "🔥 23" — streak in fire emoji circle
- Rectangular: "2/4 done · $35 at stake"
- Inline: "🔥 23 · $45 at stake"

**W4: Live Activity (Dynamic Island + Lock Screen)**
```
Compact:  🔥 23 | 🏋️ 2h 14m · $10
Expanded:
┌──────────────────────────────────┐
│ 🏋️ Gym closes in 2h 14m   $10   │
│ ▓▓▓▓▓▓▓▓▓░░░░░░                 │
└──────────────────────────────────┘
```
- Live countdown timer
- Progress bar: `pledgeBlue` fill
- Tap → opens app to verification flow
- Updates to ✅ when verified

---

## Haptic Feedback Map

| Action | Haptic Type |
|---|---|
| Any button tap | `.impact(.light)` |
| CTA button tap (primary) | `.impact(.medium)` |
| Habit verified | `.notification(.success)` |
| Penalty triggered | `.notification(.error)` |
| Streak milestone | `.notification(.success)` |
| Stake pill selection | `.selectionChanged` |
| Number pad key | `.impact(.light)` |
| Day pill / toggle | `.selectionChanged` |
| Chart scrub | `.selectionChanged` (each point) |
| Pull to refresh | `.impact(.medium)` |
| Swipe reveal actions | `.impact(.light)` |
| Deposit confirmed | `.notification(.success)` |
| Sheet presented | None (system handles) |

---

## Page Transition Map

| From → To | Animation | Duration |
|---|---|---|
| Splash → Onboarding | `.opacity` crossfade | 0.4s |
| Onboarding pages (1↔2↔3) | `.slide` horizontal | `springBounce` |
| Onboarding → Sign Up | `slideIn` (right) | `springBounce` |
| Sign Up → OTP | `slideIn` | `springBounce` |
| OTP → Choose Habits | `slideIn` | `springBounce` |
| Choose → Configure (paged) | `slideIn` per page | `springBounce` |
| Configure → Stakes | `slideIn` | `springBounce` |
| Stakes → Deposit | `slideIn` | `springBounce` |
| Deposit → Success | `slideIn` | `springBounce` |
| Success → Home | `.fullScreenCover` dismiss (slide down) | `springBounce` |
| Tab switches | `.opacity` crossfade, 0.2s | instant feel |
| Any → Sheet | System sheet presentation | spring |
| Any → Full Screen Cover | Slide up from bottom | `springBounce` |
| Back navigation (any) | `slideBack` (left) | `springBounce` |

---

## Dark Mode Spec

All screens support dark mode. The design inverts cleanly:

| Element | Light | Dark |
|---|---|---|
| Background | #FFFFFF | #0A0A0F |
| Secondary bg | #F8F9FA | #111118 |
| Card bg | #F3F4F6 | #1F2937 |
| Primary text | #000000 | #FFFFFF |
| Secondary text | #6B7280 | #9CA3AF |
| Black capsule CTA | Black fill, white text | White fill, black text |
| Accent cards | Same colors (blue, violet, orange) | Same, slightly deeper |
| Orbs | 25% opacity | 15% opacity |
| Chart bg | #F8F9FA | #111118 |
| Dividers | #E5E7EB | #374151 |
| Shadows | rgba(0,0,0,0.06) | None (use subtle border instead) |

Follow `@Environment(\.colorScheme)`. Default: system setting. User override in Settings.

---

*"Clean lines. Bold numbers. No clutter. Every pixel earns its place."*
