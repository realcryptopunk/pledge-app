import SwiftUI

struct RiskProfileView: View {
    @Bindable var flowState: SetupFlowState
    @Environment(\.themeColors) var theme

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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose your\nstrategy.")
                            .pledgeHero(40)
                            .foregroundColor(.primary)
                            .embossed(.raised)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Where should failed stakes earn yield?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    // MARK: - Risk Tier Cards
                    VStack(spacing: 12) {
                        ForEach(Array(RiskProfile.allCases.enumerated()), id: \.element) { index, profile in
                            riskTierCard(profile: profile)
                                .staggerIn(index: index)
                        }
                    }

                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 20)
            }

            // MARK: - Continue Button
            VStack(spacing: 0) {
                Divider().opacity(0.2)
                Button {
                    PPHaptic.medium()
                    flowState.goForward()
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [theme.buttonTop, theme.buttonBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Risk Tier Card

    @ViewBuilder
    private func riskTierCard(profile: RiskProfile) -> some View {
        let isSelected = flowState.selectedRiskProfile == profile

        Button {
            PPHaptic.medium()
            withAnimation(.quickSnap) {
                flowState.selectedRiskProfile = profile
            }
        } label: {
            HStack(spacing: 14) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(profile.color.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: profile.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(profile.color)
                }

                // Center content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(profile.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        // Risk level pill
                        Text(profile.riskLevel)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(profile.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(profile.color.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Text(profile.subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "percent")
                                .font(.system(size: 9, weight: .bold))
                            Text(profile.expectedReturn)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        }
                        .foregroundColor(.pledgeGreen)

                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text(profile.lockPeriod)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Radio indicator
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? profile.color : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(profile.color)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground).opacity(0.6))
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected
                            ? LinearGradient(
                                colors: [theme.buttonTop, theme.buttonBottom],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color.secondary.opacity(0.15), Color.secondary.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .cardPress()
    }
}
