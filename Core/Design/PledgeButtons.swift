import SwiftUI

// MARK: - Primary Black Capsule

struct PrimaryCapsuleStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.pledgeBlackAdaptive)
            .clipShape(Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1.0) : 0.35)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

// MARK: - Accent Blue Capsule

struct AccentCapsuleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.pledgeBlue)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

// MARK: - Secondary Gray Capsule

struct SecondaryCapsuleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Color.pledgeBlackAdaptive)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.pledgeGrayUltraAdaptive)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

// MARK: - Destructive Red Tint Capsule

struct DestructiveCapsuleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.pledgeRed)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.pledgeRed.opacity(0.12))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

// MARK: - Ghost Button

struct GhostButtonStyle: ButtonStyle {
    var color: Color = .pledgeGray
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(color)
            .opacity(configuration.isPressed ? 0.5 : 1.0)
    }
}

// MARK: - Small Capsule (for inline actions like "Verify Now")

struct SmallCapsuleStyle: ButtonStyle {
    var color: Color = .pledgeBlue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

// MARK: - Dual CTA View

struct DualCTAView: View {
    let leftTitle: String
    let rightTitle: String
    let leftAction: () -> Void
    let rightAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: leftAction) {
                Text(leftTitle)
            }
            .buttonStyle(PrimaryCapsuleStyle())
            
            Button(action: rightAction) {
                Text(rightTitle)
            }
            .buttonStyle(AccentCapsuleStyle())
        }
    }
}

// MARK: - Pill Toggle

struct PillToggle: View {
    let options: [String]
    @Binding var selected: Int
    @Namespace private var pillNS
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        selected = index
                    }
                    PPHaptic.selection()
                } label: {
                    Text(option)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selected == index ? .white : .pledgeGray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if selected == index {
                                Capsule()
                                    .fill(Color.pledgeBlackAdaptive)
                                    .matchedGeometryEffect(id: "pill", in: pillNS)
                            }
                        }
                }
            }
        }
        .padding(4)
        .background(Color.pledgeGrayUltraAdaptive)
        .clipShape(Capsule())
    }
}
