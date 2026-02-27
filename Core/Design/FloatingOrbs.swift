import SwiftUI

struct FloatingOrb: Identifiable {
    let id = UUID()
    let colorIndex: Int
    let width: CGFloat
    let height: CGFloat
    let startX: CGFloat
    let startY: CGFloat
    let driftX: CGFloat
    let driftY: CGFloat
    let rotation: Double
    let rotationDrift: Double
    let duration: Double
}

struct FloatingOrbsView: View {
    let height: CGFloat
    @EnvironmentObject var appState: AppState
    @State private var animate = false

    private static let orbData: [FloatingOrb] = [
        FloatingOrb(colorIndex: 0, width: 100, height: 45, startX: 0.2, startY: 0.2, driftX: 15, driftY: -10, rotation: 10, rotationDrift: 25, duration: 8),
        FloatingOrb(colorIndex: 1, width: 80, height: 130, startX: 0.8, startY: 0.4, driftX: -12, driftY: 8, rotation: -15, rotationDrift: 20, duration: 10),
        FloatingOrb(colorIndex: 2, width: 120, height: 50, startX: 0.5, startY: 0.15, driftX: 10, driftY: 12, rotation: 25, rotationDrift: -15, duration: 9),
        FloatingOrb(colorIndex: 3, width: 70, height: 110, startX: 0.15, startY: 0.6, driftX: -8, driftY: -15, rotation: -20, rotationDrift: 30, duration: 11),
        FloatingOrb(colorIndex: 4, width: 90, height: 40, startX: 0.75, startY: 0.25, driftX: 12, driftY: 10, rotation: 15, rotationDrift: -20, duration: 8.5),
        FloatingOrb(colorIndex: 5, width: 60, height: 100, startX: 0.4, startY: 0.7, driftX: -10, driftY: -8, rotation: -30, rotationDrift: 25, duration: 12),
        FloatingOrb(colorIndex: 6, width: 110, height: 48, startX: 0.3, startY: 0.45, driftX: 14, driftY: 6, rotation: 20, rotationDrift: -18, duration: 9.5),
        FloatingOrb(colorIndex: 7, width: 75, height: 120, startX: 0.65, startY: 0.55, driftX: -14, driftY: 12, rotation: -10, rotationDrift: 22, duration: 10.5),
        FloatingOrb(colorIndex: 8, width: 95, height: 42, startX: 0.1, startY: 0.85, driftX: 10, driftY: -12, rotation: 30, rotationDrift: -25, duration: 7.5),
        FloatingOrb(colorIndex: 9, width: 85, height: 55, startX: 0.55, startY: 0.35, driftX: -8, driftY: -6, rotation: -25, rotationDrift: 15, duration: 13),
        FloatingOrb(colorIndex: 10, width: 70, height: 95, startX: 0.9, startY: 0.75, driftX: 6, driftY: 10, rotation: 12, rotationDrift: -20, duration: 11.5),
        FloatingOrb(colorIndex: 11, width: 105, height: 46, startX: 0.35, startY: 0.9, driftX: -12, driftY: -10, rotation: -18, rotationDrift: 28, duration: 14),
        FloatingOrb(colorIndex: 12, width: 65, height: 108, startX: 0.7, startY: 0.1, driftX: 8, driftY: 14, rotation: 22, rotationDrift: -12, duration: 8),
    ]

    private var causticColors: [Color] {
        appState.backgroundTheme.causticColors
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Self.orbData) { orb in
                    Ellipse()
                        .fill(causticColors[orb.colorIndex % causticColors.count])
                        .frame(width: orb.width, height: orb.height)
                        .blur(radius: 25)
                        .opacity(0.15)
                        .blendMode(.screen)
                        .rotationEffect(.degrees(animate ? orb.rotation + orb.rotationDrift : orb.rotation))
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
    ZStack {
        Color(hex: "0C4A6E")
        FloatingOrbsView(height: 300)
    }
    .environmentObject(AppState())
}
