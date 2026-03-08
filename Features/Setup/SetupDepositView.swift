import SwiftUI

struct SetupDepositView: View {
    @Bindable var flowState: SetupFlowState
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme
    @State private var depositString = ""
    @State private var isFetchingToken = false
    @State private var showPaymentMethods = false
    @State private var showOnramp = false
    @State private var sessionToken: String?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var pendingPaymentMethod: PaymentMethodsView.PaymentMethod?

    private let quickAmounts = ["50", "100", "200", "500"]

    private var depositValue: Double {
        Double(depositString) ?? 0
    }

    private var canDeposit: Bool {
        depositValue >= 1
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

                Text("No minimum deposit")
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

            Spacer().frame(height: 24)

            // MARK: - Deposit Button
            Button {
                PPHaptic.heavy()
                showPaymentMethods = true
            } label: {
                Text("Deposit")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [theme.buttonTop, theme.buttonBottom],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .clipShape(Capsule())
                    .shadow(color: theme.surface.opacity(0.3), radius: 8, y: 4)
            }
            .disabled(!canDeposit)
            .opacity(canDeposit ? 1.0 : 0.35)
            .padding(.horizontal, 20)

            // Security note
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 10))
                Text("Secured & encrypted · Powered by Robinhood Chain")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.secondary.opacity(0.5))
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showPaymentMethods, onDismiss: {
            if let method = pendingPaymentMethod {
                pendingPaymentMethod = nil
                handlePayment(method)
            }
        }) {
            PaymentMethodsView(depositAmount: depositValue) { method in
                pendingPaymentMethod = method
                showPaymentMethods = false
            }
            .presentationDetents([.medium])
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

    // MARK: - Handle Payment Method Selection

    private func handlePayment(_ method: PaymentMethodsView.PaymentMethod) {
        switch method {
        case .applePay:
            // For now, simulate deposit
            flowState.depositAmount = depositValue
            flowState.goForward()

        case .coinbase:
            fundWithCoinbase()

        case .robinhood:
            // Robinhood Chain direct deposit
            flowState.depositAmount = depositValue
            flowState.goForward()
        }
    }

    // MARK: - Fund with Coinbase

    private func fundWithCoinbase() {
        #if DEBUG
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
