import SwiftUI
import Vortex

struct PledgeCelebrationView: View {
    let habit: Habit
    let isFirstPledge: Bool
    let onContinue: () -> Void

    @Environment(\.themeColors) var theme

    // MARK: - Animation State

    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showStats = false
    @State private var showButton = false
    @State private var confettiProxy: VortexProxy?

    // MARK: - Body

    var body: some View {
        ZStack {
            WaterBackgroundView()

            VStack(spacing: 24) {
                Spacer()

                // Habit icon in themed gradient circle
                Text(habit.icon)
                    .font(.system(size: 56))
                    .frame(width: 120, height: 120)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.buttonTop, theme.buttonBottom],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .aquaBevel(cornerRadius: 60)
                    .scaleEffect(showIcon ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5), value: showIcon)

                // Title
                VStack(spacing: 8) {
                    Text(isFirstPledge ? "Your First Pledge!" : "Pledge Created!")
                        .pledgeHero(36)
                        .foregroundColor(.primary)
                        .embossed(.raised)
                        .multilineTextAlignment(.center)

                    Text(habit.name)
                        .pledgeHeadline()
                        .foregroundColor(.secondary)
                }
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 20)
                .animation(.springBounce, value: showTitle)

                // Stats card
                VStack(spacing: 12) {
                    HStack {
                        VStack(spacing: 4) {
                            Text("$\(Int(habit.stakeAmount))")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.primary)
                                .embossed(.raised)
                            Text("daily stake")
                                .pledgeCaption()
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(Color.primary.opacity(0.1))
                            .frame(width: 1, height: 40)

                        VStack(spacing: 4) {
                            Text("\(habit.schedule.count)")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.primary)
                                .embossed(.raised)
                            Text("days/week")
                                .pledgeCaption()
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .cleanCard()
                .scaleEffect(showStats ? 1 : 0.8)
                .opacity(showStats ? 1 : 0)
                .animation(.springBounce, value: showStats)

                Spacer()

                // Continue button
                Button {
                    PPHaptic.medium()
                    onContinue()
                } label: {
                    Text("Continue")
                }
                .buttonStyle(PrimaryCapsuleStyle())
                .padding(.horizontal, 20)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 30)
                .animation(.springBounce, value: showButton)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)

            // Confetti overlay
            VortexViewReader { proxy in
                VortexView(.confetti) {
                    Rectangle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .tag("square")

                    Circle()
                        .fill(.white)
                        .frame(width: 16)
                        .tag("circle")
                }
                .allowsHitTesting(false)
                .onAppear { confettiProxy = proxy }
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    // MARK: - Animation Choreography

    private func startAnimationSequence() {
        PPHaptic.success()

        // +0.1s: Icon bounces in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showIcon = true
        }

        // +0.3s: Confetti burst + heavy haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            confettiProxy?.burst()
            PPHaptic.heavy()
        }

        // +0.4s: Title fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showTitle = true
        }

        // +0.6s: Stats card scales in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showStats = true
        }

        // +0.8s: Button slides up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showButton = true
        }
    }
}
