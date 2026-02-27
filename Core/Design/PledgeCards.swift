import SwiftUI

// MARK: - Accent Card (glass + tinted overlay)

struct AccentCardModifier: ViewModifier {
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    private var tintOpacity: Double {
        colorScheme == .light ? 0.45 : 0.25
    }

    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(color.opacity(tintOpacity))
                    )
            )
            .foregroundColor(colorScheme == .light ? .black : .white)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.white.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Clean Card (glass panel)

struct CleanCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .aquaGlass(cornerRadius: 16)
    }
}

// MARK: - Flat Card (lighter glass)

struct FlatCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
    }
}

extension View {
    func accentCard(_ color: Color) -> some View {
        modifier(AccentCardModifier(color: color))
    }

    func cleanCard() -> some View {
        modifier(CleanCardModifier())
    }

    func flatCard() -> some View {
        modifier(FlatCardModifier())
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .primary
    var showChevron: Bool = false

    var body: some View {
        HStack {
            Text(icon)
                .font(.system(size: 16))
            Text(label)
                .pledgeHeadline()
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .pledgeMono()
                .foregroundColor(valueColor)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Stat Row Divider

struct StatRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(height: 1)
    }
}

// MARK: - Stat Row List

struct StatRowList<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
    }
}
