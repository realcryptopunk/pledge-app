import SwiftUI

// MARK: - Emboss Style

enum EmbossStyle {
    case raised
    case inset
}

// MARK: - Embossed Text Modifier

struct EmbossedModifier: ViewModifier {
    var style: EmbossStyle
    @Environment(\.colorScheme) var colorScheme

    private var isLight: Bool { colorScheme == .light }

    func body(content: Content) -> some View {
        switch style {
        case .raised:
            content
                .shadow(color: Color(isLight ? .black : .white).opacity(isLight ? 0.12 : 0.5), radius: 0, x: 0, y: 1)
                .shadow(color: Color(isLight ? .white : .black).opacity(isLight ? 0.8 : 0.3), radius: 0, x: 0, y: -0.5)
        case .inset:
            content
                .shadow(color: Color(isLight ? .white : .black).opacity(0.4), radius: 0, x: 0, y: 1)
                .shadow(color: Color(isLight ? .black : .white).opacity(0.3), radius: 0, x: 0, y: -0.5)
        }
    }
}

extension View {
    func embossed(_ style: EmbossStyle = .raised) -> some View {
        modifier(EmbossedModifier(style: style))
    }
}
