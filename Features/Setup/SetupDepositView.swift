import SwiftUI

struct SetupDepositView: View {
    @Bindable var flowState: SetupFlowState
    @Environment(\.themeColors) var theme
    @State private var depositString = ""

    private let quickAmounts = ["50", "100", "200", "500"]

    private var depositValue: Double {
        Double(depositString) ?? 0
    }

    private var canDeposit: Bool {
        depositValue >= 50
    }

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

            Spacer()

            // MARK: - Amount Display
            VStack(spacing: 8) {
                Text("Fund your pledge")
                    .pledgeCaption()
                    .foregroundColor(.secondary)
                    .tracking(1)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text(depositString.isEmpty ? "0" : depositString)
                        .pledgeXL(72)
                        .foregroundColor(depositString.isEmpty ? .secondary.opacity(0.3) : .primary)
                        .embossed(.raised)
                        .contentTransition(.numericText())
                        .animation(.quickSnap, value: depositString)
                }

                Text("Minimum deposit: $50")
                    .pledgeCaption()
                    .foregroundColor(.secondary.opacity(0.6))
            }

            Spacer().frame(height: 24)

            // MARK: - Quick Amount Pills
            HStack(spacing: 10) {
                ForEach(quickAmounts, id: \.self) { amount in
                    Button {
                        PPHaptic.light()
                        withAnimation(.quickSnap) {
                            depositString = amount
                        }
                    } label: {
                        Text("$\(amount)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(depositString == amount ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(depositString == amount
                                          ? LinearGradient(colors: [theme.buttonTop, theme.buttonBottom], startPoint: .top, endPoint: .bottom)
                                          : LinearGradient(colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.primary.opacity(depositString == amount ? 0.3 : 0.1), lineWidth: 0.5)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 20)

            // MARK: - Number Pad
            NumberPadView(value: $depositString, maxDigits: 5, allowDecimal: false)
                .padding(.horizontal, 20)

            Spacer().frame(height: 20)

            // MARK: - Apple Pay Button
            Button {
                PPHaptic.heavy()
                flowState.depositAmount = depositValue
                flowState.goForward()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18))
                    Text("Pay")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(Color.black)
                )
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            }
            .disabled(!canDeposit)
            .opacity(canDeposit ? 1.0 : 0.35)
            .padding(.horizontal, 20)

            // Or pay with card
            Button {
                // Visual only
                PPHaptic.light()
                flowState.depositAmount = depositValue
                flowState.goForward()
            } label: {
                Text("Or pay with card")
            }
            .buttonStyle(GhostButtonStyle())
            .disabled(!canDeposit)
            .opacity(canDeposit ? 1.0 : 0.35)
            .padding(.top, 8)

            // Security note
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                Text("Funds held securely. Withdraw anytime.")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.secondary.opacity(0.6))
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }
}
