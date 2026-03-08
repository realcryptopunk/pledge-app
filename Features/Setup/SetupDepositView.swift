import SwiftUI

struct SetupDepositView: View {
    @Bindable var flowState: SetupFlowState
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme
    @State private var depositString = ""
    @State private var isFetchingToken = false
    @State private var showOnramp = false
    @State private var sessionToken: String?
    @State private var showError = false
    @State private var errorMessage = ""

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

            // MARK: - Fund Button
            Button {
                PPHaptic.heavy()
                fundWithCoinbase()
            } label: {
                HStack(spacing: 8) {
                    if isFetchingToken {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 18))
                    }
                    Text(isFetchingToken ? "Connecting..." : "Fund with Coinbase")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.32, blue: 1.0), Color(red: 0.0, green: 0.25, blue: 0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .clipShape(Capsule())
                .shadow(color: Color(red: 0.0, green: 0.32, blue: 1.0).opacity(0.3), radius: 8, y: 4)
            }
            .disabled(!canDeposit || isFetchingToken)
            .opacity(canDeposit && !isFetchingToken ? 1.0 : 0.35)
            .padding(.horizontal, 20)

            // Robinhood deposit option
            Button {
                PPHaptic.heavy()
                flowState.depositAmount = depositValue
                flowState.goForward()
            } label: {
                HStack(spacing: 10) {
                    // Robinhood green feather icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(red: 0.0, green: 0.82, blue: 0.33).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.33))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Robinhood")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        HStack(spacing: 6) {
                            Text("No Fees")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.33))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(red: 0.0, green: 0.82, blue: 0.33).opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("No Limits")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Unlimited Deposit")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(red: 0.0, green: 0.82, blue: 0.33).opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .disabled(!canDeposit)
            .opacity(canDeposit ? 1.0 : 0.35)
            .padding(.horizontal, 20)

            // Or pay with card
            Button {
                PPHaptic.light()
                flowState.depositAmount = depositValue
                flowState.goForward()
            } label: {
                Text("Or pay with card")
            }
            .buttonStyle(GhostButtonStyle())
            .disabled(!canDeposit || isFetchingToken)
            .opacity(canDeposit && !isFetchingToken ? 1.0 : 0.35)
            .padding(.top, 8)

            // Security note
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                Text("Powered by Coinbase. Funds sent as USDC to your wallet.")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.secondary.opacity(0.6))
            .padding(.top, 8)

            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.33))
                Text("Powered by Robinhood Chain")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .sheet(isPresented: $showOnramp) {
            if let token = sessionToken {
                CoinbaseOnrampView(
                    walletAddress: appState.walletAddress,
                    amount: depositValue,
                    sessionToken: token,
                    onDismiss: {
                        showOnramp = false
                        flowState.depositAmount = depositValue
                        flowState.goForward()
                    }
                )
            }
        }
        .alert("Deposit Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
            #if DEBUG
            Button("Use Simulated Deposit") {
                flowState.depositAmount = depositValue
                flowState.goForward()
            }
            #endif
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Fund with Coinbase

    private func fundWithCoinbase() {
        #if DEBUG
        // In debug builds, if wallet address is empty, use simulated deposit
        if appState.walletAddress.isEmpty {
            flowState.depositAmount = depositValue
            flowState.goForward()
            return
        }
        #endif

        isFetchingToken = true
        Task {
            do {
                let token = try await OnrampService.fetchSessionToken(
                    walletAddress: appState.walletAddress,
                    amount: depositValue
                )
                await MainActor.run {
                    sessionToken = token
                    isFetchingToken = false
                    showOnramp = true
                }
            } catch {
                await MainActor.run {
                    isFetchingToken = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
