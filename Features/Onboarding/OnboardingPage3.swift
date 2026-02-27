import SwiftUI

struct OnboardingPage3: View {
    let onGetStarted: () -> Void
    
    @State private var buttonVisible = false
    
    private let steps: [(icon: String, color: Color, title: String, desc: String)] = [
        ("🎯", .pledgeBlue, "Set a habit", "Wake up early, work out, limit screen time"),
        ("💰", .pledgeGreen, "Stake your money", "$10 says you'll follow through"),
        ("📈", .pledgeViolet, "Miss it? It's invested.", "Your penalty grows in your portfolio"),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 16) {
                        // Icon circle
                        ZStack {
                            Circle()
                                .fill(step.color.opacity(0.15))
                                .frame(width: 48, height: 48)
                            Text(step.icon)
                                .font(.system(size: 22))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .pledgeHeadline()
                                .foregroundColor(.pledgeBlackAdaptive)
                            Text(step.desc)
                                .pledgeCaption()
                                .foregroundColor(.pledgeGray)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.pledgeGrayUltraAdaptive)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .staggerIn(index: index)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Get Started button
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
    OnboardingPage3(onGetStarted: {})
}
