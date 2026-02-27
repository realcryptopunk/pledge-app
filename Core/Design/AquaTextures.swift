import SwiftUI

// MARK: - Caustic Light Element

struct CausticLight: Identifiable {
    let id = UUID()
    let width: CGFloat
    let height: CGFloat
    let startX: CGFloat
    let startY: CGFloat
    let driftX: CGFloat
    let driftY: CGFloat
    let rotation: Double
    let rotationDrift: Double
    let duration: Double
    let opacity: Double
    let colorIndex: Int
}

// MARK: - Water Background View

struct WaterBackgroundView: View {
    @Environment(\.themeColors) var theme
    @EnvironmentObject var appState: AppState
    @State private var animate = false

    private static let causticData: [CausticLight] = [
        CausticLight(width: 180, height: 80, startX: 0.15, startY: 0.1, driftX: 20, driftY: 15, rotation: 15, rotationDrift: 30, duration: 9, opacity: 0.12, colorIndex: 0),
        CausticLight(width: 120, height: 200, startX: 0.75, startY: 0.15, driftX: -15, driftY: 10, rotation: -20, rotationDrift: 25, duration: 11, opacity: 0.10, colorIndex: 1),
        CausticLight(width: 160, height: 60, startX: 0.4, startY: 0.25, driftX: 12, driftY: -18, rotation: 40, rotationDrift: -20, duration: 8, opacity: 0.14, colorIndex: 2),
        CausticLight(width: 90, height: 150, startX: 0.85, startY: 0.4, driftX: -18, driftY: 12, rotation: -10, rotationDrift: 35, duration: 12, opacity: 0.08, colorIndex: 3),
        CausticLight(width: 200, height: 70, startX: 0.2, startY: 0.45, driftX: 15, driftY: -10, rotation: 25, rotationDrift: -15, duration: 10, opacity: 0.11, colorIndex: 4),
        CausticLight(width: 100, height: 180, startX: 0.6, startY: 0.35, driftX: -10, driftY: 20, rotation: -35, rotationDrift: 20, duration: 13, opacity: 0.09, colorIndex: 5),
        CausticLight(width: 140, height: 55, startX: 0.3, startY: 0.6, driftX: 18, driftY: 8, rotation: 10, rotationDrift: -25, duration: 9.5, opacity: 0.13, colorIndex: 6),
        CausticLight(width: 80, height: 160, startX: 0.9, startY: 0.65, driftX: -12, driftY: -15, rotation: -45, rotationDrift: 30, duration: 11.5, opacity: 0.07, colorIndex: 7),
        CausticLight(width: 170, height: 65, startX: 0.1, startY: 0.75, driftX: 14, driftY: 12, rotation: 30, rotationDrift: -20, duration: 8.5, opacity: 0.10, colorIndex: 8),
        CausticLight(width: 110, height: 140, startX: 0.5, startY: 0.7, driftX: -16, driftY: -8, rotation: -15, rotationDrift: 25, duration: 10.5, opacity: 0.12, colorIndex: 9),
        CausticLight(width: 150, height: 50, startX: 0.7, startY: 0.85, driftX: 10, driftY: 15, rotation: 20, rotationDrift: -30, duration: 12.5, opacity: 0.08, colorIndex: 10),
        CausticLight(width: 95, height: 170, startX: 0.25, startY: 0.9, driftX: -14, driftY: -12, rotation: -25, rotationDrift: 20, duration: 14, opacity: 0.09, colorIndex: 11),
        CausticLight(width: 130, height: 75, startX: 0.55, startY: 0.55, driftX: 16, driftY: -14, rotation: 35, rotationDrift: -15, duration: 7.5, opacity: 0.11, colorIndex: 12),
    ]

    private var isLight: Bool { theme.isLight }
    private var causticColors: [Color] { appState.backgroundTheme.causticColors }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Theme gradient base
                LinearGradient(
                    colors: [theme.deep, theme.deep.opacity(0.85), theme.mid, theme.light.opacity(isLight ? 0.3 : 0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Caustic light ellipses
                ForEach(Self.causticData) { caustic in
                    Ellipse()
                        .fill(causticColors[caustic.colorIndex % causticColors.count])
                        .frame(width: caustic.width, height: caustic.height)
                        .blur(radius: isLight ? 40 : 30)
                        .opacity(isLight ? caustic.opacity * 0.6 : caustic.opacity)
                        .blendMode(isLight ? .normal : .screen)
                        .rotationEffect(.degrees(animate ? caustic.rotation + caustic.rotationDrift : caustic.rotation))
                        .position(
                            x: geo.size.width * caustic.startX + (animate ? caustic.driftX : -caustic.driftX),
                            y: geo.size.height * caustic.startY + (animate ? caustic.driftY : -caustic.driftY)
                        )
                        .scaleEffect(animate ? 1.08 : 0.92)
                        .animation(
                            .easeInOut(duration: caustic.duration)
                            .repeatForever(autoreverses: true),
                            value: animate
                        )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Aqua Background Modifier

struct AquaBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            WaterBackgroundView()
            content
        }
    }
}

extension View {
    func aquaBackground() -> some View {
        modifier(AquaBackgroundModifier())
    }
}
