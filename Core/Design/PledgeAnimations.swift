import SwiftUI

// MARK: - Animation Presets

extension Animation {
    static let springBounce = Animation.spring(response: 0.5, dampingFraction: 0.75)
    static let quickSnap = Animation.spring(response: 0.3, dampingFraction: 0.85)
    static let heroCountUp = Animation.easeOut(duration: 1.2)
}

// MARK: - Stagger In Modifier

struct StaggerInModifier: ViewModifier {
    let index: Int
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isVisible ? 0 : 20)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.springBounce.delay(Double(index) * 0.08)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Card Press Modifier

struct CardPressModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.quickSnap, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Badge Scale Modifier

struct BadgeScaleModifier: ViewModifier {
    @State private var scale: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    scale = 1.0
                }
            }
    }
}

// MARK: - Shake Alert Modifier

struct ShakeAlertModifier: ViewModifier {
    @Binding var trigger: Bool
    @State private var offset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    shake()
                }
            }
    }
    
    private func shake() {
        let sequence: [(CGFloat, Double)] = [
            (8, 0.05), (-8, 0.05), (6, 0.05), (-6, 0.05), (0, 0.05)
        ]
        var totalDelay: Double = 0
        for (value, duration) in sequence {
            totalDelay += duration
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                withAnimation(.linear(duration: duration)) {
                    offset = value
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay + 0.1) {
            trigger = false
        }
    }
}

// MARK: - View Extensions

extension View {
    func staggerIn(index: Int) -> some View {
        modifier(StaggerInModifier(index: index))
    }
    
    func cardPress() -> some View {
        modifier(CardPressModifier())
    }
    
    func badgeScale() -> some View {
        modifier(BadgeScaleModifier())
    }
    
    func shakeAlert(trigger: Binding<Bool>) -> some View {
        modifier(ShakeAlertModifier(trigger: trigger))
    }
}

// MARK: - Slide Transitions

extension AnyTransition {
    static let slideIn = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    
    static let slideBack = AnyTransition.asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity),
        removal: .move(edge: .trailing).combined(with: .opacity)
    )
}
