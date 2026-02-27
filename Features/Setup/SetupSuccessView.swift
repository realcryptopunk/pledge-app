import SwiftUI
import Vortex

struct SetupSuccessView: View {
    @Bindable var flowState: SetupFlowState
    let onComplete: () -> Void

    @Environment(\.themeColors) var theme
    @EnvironmentObject var appState: AppState

    // MARK: - Animation State

    @State private var showCheckmark = false
    @State private var showTitle = false
    @State private var showStats = false
    @State private var showCountdown = false
    @State private var showButton = false
    @State private var confettiProxy: VortexProxy?
    @State private var now = Date()
    @State private var timer: Timer?

    // MARK: - Computed

    private var habitCount: Int {
        flowState.selectedTypes.count
    }

    private var dailyStake: Double {
        flowState.dailyExposure
    }

    private var countdownString: String {
        // Next midnight or next morning — simplified to "tomorrow"
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
            return "Tomorrow"
        }
        let components = calendar.dateComponents([.hour, .minute], from: now, to: tomorrow)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        return "\(hours)h \(minutes)m"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            FloatingOrbsView(height: UIScreen.main.bounds.height)

            VStack(spacing: 24) {
                Spacer()

                // Green checkmark in gradient circle
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.pledgeGreen, Color(hex: "16A34A")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .aquaBevel(cornerRadius: 50)
                    .scaleEffect(showCheckmark ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5), value: showCheckmark)

                // Title
                Text("You're in.")
                    .pledgeHero(48)
                    .foregroundColor(.primary)
                    .embossed(.raised)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 20)
                    .animation(.springBounce, value: showTitle)

                // Stats card
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("$\(Int(flowState.depositAmount))")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                            .embossed(.raised)
                        Text("loaded")
                            .pledgeCaption()
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 1, height: 40)

                    VStack(spacing: 4) {
                        Text("\(habitCount)")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                            .embossed(.raised)
                        Text("habits")
                            .pledgeCaption()
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 1, height: 40)

                    VStack(spacing: 4) {
                        Text("$\(Int(dailyStake))")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                            .embossed(.raised)
                        Text("/day")
                            .pledgeCaption()
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .cleanCard()
                .scaleEffect(showStats ? 1 : 0.8)
                .opacity(showStats ? 1 : 0)
                .animation(.springBounce, value: showStats)

                // Countdown
                VStack(spacing: 4) {
                    Text("First habit in")
                        .pledgeCaption()
                        .foregroundColor(.secondary)
                    Text(countdownString)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .opacity(showCountdown ? 1 : 0)
                .animation(.springBounce, value: showCountdown)

                Spacer()

                // Let's Go button
                Button {
                    PPHaptic.heavy()
                    onComplete()
                } label: {
                    Text("Let's Go")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            Capsule()
                                .fill(Color.black)
                        )
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                }
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
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Animation Choreography

    private func startAnimationSequence() {
        PPHaptic.success()

        // Start countdown timer
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            now = Date()
        }

        // +0.1s: Checkmark bounces in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showCheckmark = true
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

        // +0.8s: Countdown appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showCountdown = true
        }

        // +1.0s: Button slides up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showButton = true
        }
    }
}
