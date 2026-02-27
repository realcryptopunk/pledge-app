import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var wordmarkOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.pledgeBgAdaptive
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.pledgeBlackAdaptive)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                Text("Pledge")
                    .pledgeTitle()
                    .foregroundColor(.pledgeBlackAdaptive)
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
}
