import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var wordmarkOpacity: Double = 0
    @Environment(\.themeColors) var theme

    var body: some View {
        ZStack {
            WaterBackgroundView()

            VStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.surface, theme.light],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("Pledge")
                    .pledgeTitle()
                    .foregroundColor(.primary)
                    .embossed(.raised)
                    .opacity(wordmarkOpacity)
            }
        }
        .onAppear {
            withAnimation(.springBounce) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
                wordmarkOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(AppState())
}
