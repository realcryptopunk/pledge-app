import SwiftUI

struct OnboardingPage2: View {
    @State private var titleVisible = false
    @State private var subtitleVisible = false
    @State private var chartProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Chart illustration
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.pledgeGrayUltraAdaptive)
                    .frame(height: 220)
                
                VStack(spacing: 16) {
                    // Animated chart line
                    ChartLineView(progress: chartProgress)
                        .frame(height: 100)
                        .padding(.horizontal, 32)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.pledgeGreen)
                        Text("Your penalties, invested")
                            .pledgeCaption()
                            .foregroundColor(.pledgeGray)
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer().frame(height: 48)
            
            VStack(spacing: 4) {
                Text("What if every failure")
                    .pledgeHero(32)
                    .foregroundColor(.pledgeBlackAdaptive)
                
                Text("made you richer?")
                    .pledgeHero(32)
                    .foregroundColor(.pledgeBlackAdaptive)
            }
            .multilineTextAlignment(.center)
            .opacity(titleVisible ? 1 : 0)
            .offset(y: titleVisible ? 0 : 10)
            
            Spacer().frame(height: 16)
            
            Text("When you miss a pledge, we invest the money for you. You're building discipline or building wealth.")
                .pledgeBody()
                .foregroundColor(.pledgeGray)
                .multilineTextAlignment(.center)
                .opacity(subtitleVisible ? 1 : 0)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).delay(0.2)) { chartProgress = 1.0 }
            withAnimation(.springBounce.delay(0.3)) { titleVisible = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.6)) { subtitleVisible = true }
        }
    }
}

// MARK: - Chart Line

struct ChartLineView: View {
    var progress: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            let points: [CGPoint] = [
                CGPoint(x: 0, y: h * 0.8),
                CGPoint(x: w * 0.15, y: h * 0.7),
                CGPoint(x: w * 0.3, y: h * 0.75),
                CGPoint(x: w * 0.45, y: h * 0.5),
                CGPoint(x: w * 0.6, y: h * 0.55),
                CGPoint(x: w * 0.75, y: h * 0.3),
                CGPoint(x: w * 0.9, y: h * 0.25),
                CGPoint(x: w, y: h * 0.15),
            ]
            
            Path { path in
                path.move(to: points[0])
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .trim(from: 0, to: progress)
            .stroke(Color.pledgeViolet, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            
            // Area fill
            Path { path in
                path.move(to: points[0])
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [Color.pledgeViolet.opacity(0.15), Color.pledgeViolet.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .opacity(Double(progress))
        }
    }
}

#Preview {
    OnboardingPage2()
}
