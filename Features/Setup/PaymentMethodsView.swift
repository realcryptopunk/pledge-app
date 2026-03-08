import SwiftUI

struct PaymentMethodsView: View {
    let depositAmount: Double
    let onSelect: (PaymentMethod) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColors) var theme

    enum PaymentMethod: String, CaseIterable {
        case applePay
        case coinbase
        case robinhood
    }

    var body: some View {
        ZStack {
            WaterBackgroundView()

            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Payment Method")
                            .pledgeTitle()
                            .foregroundColor(.primary)
                            .embossed(.raised)
                        Text("Depositing $\(Int(depositAmount))")
                            .pledgeBody()
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer().frame(height: 32)

                VStack(spacing: 16) {
                    // Apple Pay
                    paymentButton(
                        icon: {
                            AnyView(
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.primary)
                            )
                        },
                        iconBg: Color.primary.opacity(0.08),
                        title: "Apple Pay",
                        subtitle: "Instant",
                        badge: nil,
                        badgeColor: .clear,
                        method: .applePay
                    )

                    // Coinbase
                    paymentButton(
                        icon: {
                            AnyView(
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(red: 0.0, green: 0.32, blue: 1.0))
                            )
                        },
                        iconBg: Color(red: 0.0, green: 0.32, blue: 1.0).opacity(0.12),
                        title: "Coinbase",
                        subtitle: "USDC on-chain",
                        badge: "Crypto",
                        badgeColor: Color(red: 0.0, green: 0.32, blue: 1.0),
                        method: .coinbase
                    )

                    // Robinhood
                    paymentButton(
                        icon: {
                            AnyView(
                                Image("RobinhoodLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            )
                        },
                        iconBg: Color.clear,
                        title: "Robinhood",
                        subtitle: "Robinhood Chain",
                        badge: "No Fees",
                        badgeColor: Color(red: 0.78, green: 1.0, blue: 0.0),
                        method: .robinhood
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // Security note
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 12))
                        Text("All payments are secured and encrypted")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.secondary.opacity(0.5))

                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 10))
                        Text("Funds deposited as USDC to your wallet")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.secondary.opacity(0.4))
                }
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Payment Button

    @ViewBuilder
    private func paymentButton(
        icon: () -> AnyView,
        iconBg: Color,
        title: String,
        subtitle: String,
        badge: String?,
        badgeColor: Color,
        method: PaymentMethod
    ) -> some View {
        Button {
            PPHaptic.medium()
            onSelect(method)
        } label: {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    if iconBg != .clear {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(iconBg)
                            .frame(width: 44, height: 44)
                    }
                    icon()
                }
                .frame(width: 44, height: 44)

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(badgeColor == Color(red: 0.78, green: 1.0, blue: 0.0) ? .black : badgeColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(badgeColor.opacity(badgeColor == Color(red: 0.78, green: 1.0, blue: 0.0) ? 0.8 : 0.12))
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

#Preview {
    PaymentMethodsView(depositAmount: 100) { method in
        print("Selected: \(method)")
    }
}
