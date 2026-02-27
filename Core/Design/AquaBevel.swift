import SwiftUI

// MARK: - Aqua Bevel Modifier

struct AquaBevelModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var isPressed: Bool = false

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.white.opacity(0.0)],
                            startPoint: .topLeading,
                            endPoint: .center
                        ),
                        lineWidth: 1.5
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.3)],
                            startPoint: .center,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: .black.opacity(isPressed ? 0.15 : 0.3),
                radius: isPressed ? 2 : 6,
                x: 0,
                y: isPressed ? 1 : 3
            )
    }
}

extension View {
    func aquaBevel(cornerRadius: CGFloat = 16, isPressed: Bool = false) -> some View {
        modifier(AquaBevelModifier(cornerRadius: cornerRadius, isPressed: isPressed))
    }
}
