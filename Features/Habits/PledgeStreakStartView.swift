import SwiftUI

struct PledgeStreakStartView: View {
    let habit: Habit
    let totalPledgeCount: Int
    let onAddAnother: () -> Void
    let onDone: () -> Void

    @Environment(\.themeColors) var theme

    // MARK: - Animation State

    @State private var showFlame = false
    @State private var showDayCount = false
    @State private var showMessage = false
    @State private var showButtons = false

    // MARK: - Body

    var body: some View {
        ZStack {
            WaterBackgroundView()

            VStack(spacing: 24) {
                Spacer()

                // Fire emoji with badge scale
                Text("\u{1F525}")
                    .font(.system(size: 72))
                    .scaleEffect(showFlame ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.5), value: showFlame)

                // "Day 1" large text
                Text("Day 1")
                    .pledgeXL(80)
                    .foregroundColor(.primary)
                    .embossed(.raised)
                    .scaleEffect(showDayCount ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showDayCount)

                // Motivational text
                VStack(spacing: 8) {
                    Text("Your streak starts now")
                        .pledgeHero(24)
                        .foregroundColor(.primary)
                        .embossed(.raised)

                    Text("Show up every day and keep your money.\nMiss a day and it gets invested for your future.")
                        .pledgeBody()
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(showMessage ? 1 : 0)
                .offset(y: showMessage ? 0 : 20)
                .animation(.springBounce, value: showMessage)

                // 7-day circle row
                weekCirclesCard
                    .opacity(showMessage ? 1 : 0)
                    .animation(.springBounce.delay(0.1), value: showMessage)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        PPHaptic.medium()
                        onDone()
                    } label: {
                        Text("Done")
                    }
                    .buttonStyle(PrimaryCapsuleStyle())

                    Button {
                        PPHaptic.light()
                        onAddAnother()
                    } label: {
                        Text("Add Another Pledge")
                    }
                    .buttonStyle(GhostButtonStyle())
                }
                .padding(.horizontal, 20)
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 30)
                .animation(.springBounce, value: showButtons)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    // MARK: - Week Circles

    private var weekCirclesCard: some View {
        HStack(spacing: 10) {
            ForEach(Array(weekdayLabels.enumerated()), id: \.offset) { index, label in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(
                                index == 0
                                ? LinearGradient(colors: [theme.buttonTop, theme.buttonBottom], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: 38, height: 38)
                            .overlay(
                                Circle()
                                    .stroke(
                                        index == 0
                                        ? Color.white.opacity(0.3)
                                        : Color.primary.opacity(0.1),
                                        lineWidth: 0.5
                                    )
                            )

                        if index == 0 {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                    Text(label)
                        .pledgeCaption()
                        .foregroundColor(index == 0 ? .primary : .secondary)
                }
                .staggerIn(index: index)
            }
        }
        .frame(maxWidth: .infinity)
        .cleanCard()
    }

    // MARK: - Weekday Labels

    private var weekdayLabels: [String] {
        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let shortSymbols = ["S", "M", "T", "W", "T", "F", "S"]
        let todayIndex = Calendar.current.component(.weekday, from: Date()) - 1 // 0-based, Sunday=0
        return (0..<7).map { offset in
            shortSymbols[(todayIndex + offset) % 7]
        }
    }

    // MARK: - Animation Choreography

    private func startAnimationSequence() {
        // +0.1s: Flame bounces in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showFlame = true
        }

        // +0.3s: Day count scales in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showDayCount = true
        }

        // +0.5s: Message + circles fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showMessage = true
        }

        // +0.7s: Buttons slide up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            showButtons = true
        }
    }
}
