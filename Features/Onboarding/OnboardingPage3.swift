import SwiftUI

struct OnboardingPage3: View {
    let onGetStarted: () -> Void

    @State private var buttonVisible = false
    @State private var titleVisible = false
    @Environment(\.themeColors) var theme

    private var steps: [(icon: String, color: Color, title: String, desc: String)] {
        [
            ("🎯", theme.light, "Set a habit", "Wake up early, work out, limit screen time"),
            ("💰", .pledgeGreen, "Stake your money", "$10 says you'll follow through"),
            ("📈", theme.surface, "Miss it? You own stocks.", "Auto-invested into Tesla, Amazon & more on Robinhood Chain"),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title
            VStack(spacing: 4) {
                Text("How It Works")
                    .pledgeHero(32)
                    .foregroundColor(.primary)
                    .embossed(.raised)
                Text("Three simple steps")
                    .pledgeBody()
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .opacity(titleVisible ? 1 : 0)
            .offset(y: titleVisible ? 0 : 10)
            .onAppear {
                withAnimation(.springBounce.delay(0.1)) {
                    titleVisible = true
                }
            }

            Spacer().frame(height: 32)

            VStack(spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(step.color.opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                                )
                            Text(step.icon)
                                .font(.system(size: 22))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .pledgeHeadline()
                                .foregroundColor(.primary)
                            Text(step.desc)
                                .pledgeCaption()
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .aquaGlass(cornerRadius: 16)
                    .staggerIn(index: index)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                PPHaptic.medium()
                onGetStarted()
            } label: {
                Text("Get Started")
            }
            .buttonStyle(PrimaryCapsuleStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(buttonVisible ? 1 : 0)
            .offset(y: buttonVisible ? 0 : 10)
            .onAppear {
                withAnimation(.springBounce.delay(0.4)) {
                    buttonVisible = true
                }
            }
        }
    }
}

#Preview {
    ZStack {
        WaterBackgroundView()
        OnboardingPage3(onGetStarted: {})
    }
    .environmentObject(AppState())
}
