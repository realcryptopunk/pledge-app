import SwiftUI

struct ChooseHabitsView: View {
    @Bindable var flowState: SetupFlowState
    @Environment(\.themeColors) var theme
    @State private var shakeCounter = false

    // Show gym + pushups instead of the generic workout type
    private let setupHabitTypes: [HabitType] = HabitType.allCases.filter { $0 != .workout }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // MARK: - Header
                    VStack(spacing: 8) {
                        Text("What will you\npledge?")
                            .pledgeHero(36)
                            .foregroundColor(.primary)
                            .embossed(.raised)
                            .multilineTextAlignment(.center)

                        Text("Select your habits")
                            .pledgeBody()
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // MARK: - Habit Grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(setupHabitTypes.enumerated()), id: \.element) { index, type in
                            habitCard(type: type, index: index)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 180)
            }

            // MARK: - Bottom Bar (overlaid)
            VStack(spacing: 12) {
                // Counter pill
                HStack(spacing: 6) {
                    Text("\(flowState.selectedTypes.count)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("selected")
                        .pledgeCallout()
                }
                .foregroundColor(flowState.selectedTypes.isEmpty ? .secondary : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .flatCard()
                .shakeAlert(trigger: $shakeCounter)

                Button {
                    PPHaptic.medium()
                    flowState.configPageIndex = 0
                    flowState.goForward()
                } label: {
                    Text("Continue")
                }
                .buttonStyle(PrimaryCapsuleStyle(isEnabled: !flowState.selectedTypes.isEmpty))
                .disabled(flowState.selectedTypes.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .padding(.top, 12)
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground).opacity(0), Color(.systemBackground).opacity(0.95), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }

    // MARK: - Habit Card

    private func habitCard(type: HabitType, index: Int) -> some View {
        let isSelected = flowState.isSelected(type)
        let isPhoto = type.defaultVerification == .photo

        return Button {
            PPHaptic.selection()
            withAnimation(.quickSnap) {
                flowState.toggleHabit(type)
            }
        } label: {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    // Emoji circle
                    Text(type.defaultIcon)
                        .font(.system(size: 26))
                        .frame(width: 52, height: 52)
                        .background(
                            Circle()
                                .fill(type.accentColor.opacity(0.25))
                        )

                    // Checkmark badge
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [theme.buttonTop, theme.buttonBottom],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .background(Circle().fill(.white).padding(2))
                            .offset(x: 6, y: -6)
                            .badgeScale()
                    }
                }

                // Name
                Text(type.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                // Verification badge
                if isPhoto {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 9))
                        Text("Photo Verify")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.pledgeViolet)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.pledgeViolet.opacity(0.12))
                    )
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: type.verificationIcon)
                            .font(.system(size: 9))
                        Text(type.verificationLabel)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.primary.opacity(0.06))
                    )
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected
                            ? LinearGradient(colors: [theme.buttonTop, theme.buttonBottom], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                        lineWidth: isSelected ? 2 : 0.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .cardPress()
        .staggerIn(index: index)
    }
}
