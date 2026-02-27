import SwiftUI

// MARK: - Primary Capsule (theme button gradient + bevel)

struct PrimaryCapsuleStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        PrimaryCapsuleBody(configuration: configuration, isEnabled: isEnabled)
    }
}

private struct PrimaryCapsuleBody: View {
    let configuration: ButtonStyleConfiguration
    let isEnabled: Bool
    @Environment(\.themeColors) var theme

    var body: some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .embossed(.raised)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: configuration.isPressed
                        ? [theme.buttonBottom, theme.buttonBottom.opacity(0.9)]
                        : [theme.buttonTop, theme.buttonBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .aquaBevel(cornerRadius: 26, isPressed: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.35)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.aquaPress, value: configuration.isPressed)
    }
}

// MARK: - Accent Capsule (theme light→mid gradient + bevel)

struct AccentCapsuleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        AccentCapsuleBody(configuration: configuration)
    }
}

private struct AccentCapsuleBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.themeColors) var theme

    var body: some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .embossed(.raised)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: configuration.isPressed
                        ? [theme.buttonTop.opacity(0.8), theme.buttonBottom]
                        : [theme.light, theme.buttonTop],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .aquaBevel(cornerRadius: 26, isPressed: configuration.isPressed)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.aquaPress, value: configuration.isPressed)
    }
}

// MARK: - Secondary Capsule (glass treatment)

struct SecondaryCapsuleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(.ultraThinMaterial)
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.aquaPress, value: configuration.isPressed)
    }
}

// MARK: - Destructive Capsule (red gradient + bevel)

struct DestructiveCapsuleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .embossed(.raised)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: configuration.isPressed
                        ? [Color.pledgeRed.opacity(0.7), Color(hex: "991B1B")]
                        : [Color.pledgeRed, Color(hex: "991B1B")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .aquaBevel(cornerRadius: 26, isPressed: configuration.isPressed)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.aquaPress, value: configuration.isPressed)
    }
}

// MARK: - Ghost Button

struct GhostButtonStyle: ButtonStyle {
    var color: Color = .secondary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(color)
            .opacity(configuration.isPressed ? 0.5 : 1.0)
    }
}

// MARK: - Small Capsule (smaller beveled)

struct SmallCapsuleStyle: ButtonStyle {
    var color: Color? = nil

    func makeBody(configuration: Configuration) -> some View {
        SmallCapsuleBody(configuration: configuration, overrideColor: color)
    }
}

private struct SmallCapsuleBody: View {
    let configuration: ButtonStyleConfiguration
    let overrideColor: Color?
    @Environment(\.themeColors) var theme

    private var fillColor: Color {
        overrideColor ?? theme.buttonTop
    }

    var body: some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .embossed(.raised)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [fillColor, fillColor.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .aquaBevel(cornerRadius: 20, isPressed: configuration.isPressed)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.aquaPress, value: configuration.isPressed)
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

// MARK: - Pill Toggle (recessed track + raised theme thumb)

struct PillToggle: View {
    let options: [String]
    @Binding var selected: Int
    @Namespace private var pillNS
    @Environment(\.themeColors) var theme

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
                        .foregroundColor(selected == index ? .white : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if selected == index {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.buttonTop, theme.buttonBottom],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                                    .matchedGeometryEffect(id: "pill", in: pillNS)
                            }
                        }
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
        )
    }
}
