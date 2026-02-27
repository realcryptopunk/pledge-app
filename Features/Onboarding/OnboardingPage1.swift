import SwiftUI

struct OnboardingPage1: View {
    @State private var line1Visible = false
    @State private var line2Visible = false
    @State private var subtitleVisible = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Illustration placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.pledgeGrayUltraAdaptive)
                    .frame(height: 220)
                
                VStack(spacing: 12) {
                    Image(systemName: "checklist.unchecked")
                        .font(.system(size: 64))
                        .foregroundColor(.pledgeGray)
                    Text("92%")
                        .pledgeDisplay(48)
                        .foregroundColor(.pledgeRed)
                    Text("abandon habits")
                        .pledgeCaption()
                        .foregroundColor(.pledgeGray)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer().frame(height: 48)
            
            // Title
            VStack(spacing: 4) {
                Text("Habits are easy to start.")
                    .pledgeHero(32)
                    .foregroundColor(.pledgeBlackAdaptive)
                    .opacity(line1Visible ? 1 : 0)
                    .offset(y: line1Visible ? 0 : 10)
                
                Text("Impossible to keep.")
                    .pledgeHero(32)
                    .foregroundColor(.pledgeBlackAdaptive)
                    .opacity(line2Visible ? 1 : 0)
                    .offset(y: line2Visible ? 0 : 10)
            }
            .multilineTextAlignment(.center)
            
            Spacer().frame(height: 16)
            
            Text("92% of people abandon their habits within 30 days.")
                .pledgeBody()
                .foregroundColor(.pledgeGray)
                .multilineTextAlignment(.center)
                .opacity(subtitleVisible ? 1 : 0)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.springBounce.delay(0.1)) { line1Visible = true }
            withAnimation(.springBounce.delay(0.25)) { line2Visible = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) { subtitleVisible = true }
        }
    }
}

#Preview {
    OnboardingPage1()
}
