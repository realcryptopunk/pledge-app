import SwiftUI

struct OnboardingPage2: View {
    @State private var titleVisible = false
    @State private var subtitleVisible = false
    @State private var chartProgress: CGFloat = 0
    @Environment(\.themeColors) var theme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
                    .frame(height: 220)

                VStack(spacing: 16) {
                    ChartLineView(progress: chartProgress)
                        .frame(height: 100)
                        .padding(.horizontal, 32)

                    HStack(spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.pledgeGreen)
                        Text("Your penalties → tokenized stocks")
                            .pledgeCaption()
                            .foregroundColor(.secondary)
                    }
                }
            }
            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
            .padding(.horizontal, 32)

            Spacer().frame(height: 48)

            VStack(spacing: 4) {
                Text("What if every failure")
                    .pledgeHero(32)
                    .foregroundColor(.primary)
                    .embossed(.raised)

                Text("made you richer?")
                    .pledgeHero(32)
                    .foregroundColor(.primary)
                    .embossed(.raised)
            }
            .multilineTextAlignment(.center)
            .opacity(titleVisible ? 1 : 0)
            .offset(y: titleVisible ? 0 : 10)

            Spacer().frame(height: 16)

            Text("When you miss a pledge, your stake auto-invests into tokenized stocks — Tesla, Amazon, Palantir — on Robinhood Chain. Build discipline or build a portfolio.")
                .pledgeBody()
                .foregroundColor(.secondary)
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
    @Environment(\.themeColors) var theme

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
            .stroke(theme.surface, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

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
                    colors: [theme.surface.opacity(0.2), theme.surface.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .opacity(Double(progress))
        }
    }
}

#Preview {
    ZStack {
        WaterBackgroundView()
        OnboardingPage2()
    }
    .environmentObject(AppState())
}
