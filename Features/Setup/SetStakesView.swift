import SwiftUI

struct SetStakesView: View {
    @Bindable var flowState: SetupFlowState
    @Environment(\.themeColors) var theme

    private let stakePresets: [Double] = [5, 10, 25]

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Top Bar
            HStack {
                Button {
                    PPHaptic.light()
                    flowState.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // MARK: - Header
                    Text("Put money\non it.")
                        .pledgeHero(40)
                        .foregroundColor(.primary)
                        .embossed(.raised)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                    // MARK: - Per-Habit Stake Rows
                    VStack(spacing: 12) {
                        ForEach(Array(flowState.selectedTypes.enumerated()), id: \.element) { index, type in
                            habitStakeRow(type: type)
                                .staggerIn(index: index)
                        }
                    }

                    // MARK: - Summary Card
                    VStack(spacing: 0) {
                        StatRow(
                            icon: "💰",
                            label: "Daily exposure",
                            value: "$\(Int(flowState.dailyExposure))"
                        )
                        StatRowDivider()
                        StatRow(
                            icon: "📅",
                            label: "Weekly exposure",
                            value: "$\(Int(flowState.weeklyExposure))"
                        )
                        StatRowDivider()
                        StatRow(
                            icon: "📊",
                            label: "Monthly max",
                            value: "$\(Int(flowState.monthlyMax))"
                        )
                        StatRowDivider()
                        StatRow(
                            icon: "🎫",
                            label: "Free passes",
                            value: "1 per week"
                        )
                    }
                    .cleanCard()
                    .staggerIn(index: flowState.selectedTypes.count)

                    // MARK: - Explanatory Text
                    Text("You keep everything when you succeed. Miss a habit and it's invested for you.")
                        .pledgeCallout()
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 20)
            }

            // MARK: - Bottom Button
            Button {
                PPHaptic.medium()
                flowState.goForward()
            } label: {
                Text("Fund Your Account \u{2192}")
            }
            .buttonStyle(PrimaryCapsuleStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Habit Stake Row

    private func habitStakeRow(type: HabitType) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Emoji + name
            HStack(spacing: 10) {
                Text(type.defaultIcon)
                    .font(.system(size: 22))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(type.accentColor.opacity(0.2))
                    )

                Text(type.rawValue)
                    .pledgeHeadline()
                    .foregroundColor(.primary)
            }

            // Stake pills
            HStack(spacing: 10) {
                ForEach(stakePresets, id: \.self) { amount in
                    let isSelected = (flowState.configs[type]?.stakeAmount ?? 10) == amount
                    Button {
                        PPHaptic.light()
                        withAnimation(.quickSnap) {
                            flowState.configs[type]?.stakeAmount = amount
                        }
                    } label: {
                        Text("$\(Int(amount))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isSelected ? .white : .primary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(isSelected
                                          ? LinearGradient(colors: [theme.buttonTop, theme.buttonBottom], startPoint: .top, endPoint: .bottom)
                                          : LinearGradient(colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.primary.opacity(isSelected ? 0.3 : 0.1), lineWidth: 0.5)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .cleanCard()
    }
}
