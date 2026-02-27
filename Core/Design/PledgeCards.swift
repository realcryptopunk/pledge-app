import SwiftUI

// MARK: - Accent Card (solid color fill)

struct AccentCardModifier: ViewModifier {
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(color)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Clean Card (white + shadow)

struct CleanCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.pledgeBgAdaptive)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Flat Card (gray bg, no shadow)

struct FlatCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.pledgeGrayUltraAdaptive)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
    var valueColor: Color = .pledgeBlackAdaptive
    var showChevron: Bool = false
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.system(size: 16))
            Text(label)
                .pledgeHeadline()
                .foregroundColor(.pledgeBlackAdaptive)
            Spacer()
            Text(value)
                .pledgeMono()
                .foregroundColor(valueColor)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.pledgeGrayLight)
            }
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Stat Row Divider

struct StatRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.pledgeGrayLight)
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
