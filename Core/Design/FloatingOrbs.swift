import SwiftUI

struct FloatingOrb: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let startX: CGFloat
    let startY: CGFloat
    let driftX: CGFloat
    let driftY: CGFloat
    let duration: Double
}

struct FloatingOrbsView: View {
    let height: CGFloat
    
    @State private var animate = false
    
    private let orbs: [FloatingOrb] = [
        FloatingOrb(color: Color(hex: "93C5FD"), size: 60, startX: 0.2, startY: 0.3, driftX: 15, driftY: -10, duration: 8),
        FloatingOrb(color: Color(hex: "F9A8D4"), size: 50, startX: 0.8, startY: 0.6, driftX: -12, driftY: 8, duration: 10),
        FloatingOrb(color: Color(hex: "86EFAC"), size: 70, startX: 0.5, startY: 0.2, driftX: 10, driftY: 12, duration: 9),
        FloatingOrb(color: Color(hex: "C4B5FD"), size: 45, startX: 0.15, startY: 0.7, driftX: -8, driftY: -15, duration: 11),
        FloatingOrb(color: Color(hex: "FDBA74"), size: 55, startX: 0.75, startY: 0.25, driftX: 12, driftY: 10, duration: 8.5),
        FloatingOrb(color: Color(hex: "67E8F9"), size: 40, startX: 0.4, startY: 0.8, driftX: -10, driftY: -8, duration: 12),
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(orbs) { orb in
                    Circle()
                        .fill(orb.color)
                        .frame(width: orb.size, height: orb.size)
                        .blur(radius: 25)
                        .opacity(0.3)
                        .position(
                            x: geo.size.width * orb.startX + (animate ? orb.driftX : -orb.driftX),
                            y: geo.size.height * orb.startY + (animate ? orb.driftY : -orb.driftY)
                        )
                        .scaleEffect(animate ? 1.05 : 0.95)
                }
            }
        }
        .frame(height: height)
        .clipped()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}

#Preview {
    FloatingOrbsView(height: 200)
}
