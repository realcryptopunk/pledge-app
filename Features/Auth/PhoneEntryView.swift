import SwiftUI

struct PhoneEntryView: View {
    @EnvironmentObject var appState: AppState
    @State private var phoneNumber = ""
    @State private var showOTP = false
    @FocusState private var isPhoneFocused: Bool
    @Environment(\.themeColors) var theme

    private var formattedPhone: String {
        let digits = phoneNumber.filter { $0.isNumber }
        var result = ""
        for (index, char) in digits.enumerated() {
            if index == 0 { result += "(" }
            if index == 3 { result += ") " }
            if index == 6 { result += "-" }
            result += String(char)
        }
        return result
    }

    private var isValid: Bool {
        phoneNumber.filter { $0.isNumber }.count >= 10
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()

                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    Text("Your phone number")
                        .pledgeHero(36)
                        .foregroundColor(.primary)
                        .embossed(.raised)

                    Spacer().frame(height: 8)

                    Text("We'll send you a verification code")
                        .pledgeBody()
                        .foregroundColor(.secondary)

                    Spacer().frame(height: 40)

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text("🇺🇸")
                            Text("+1")
                                .pledgeHeadline()
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [theme.buttonTop.opacity(0.4), theme.buttonBottom.opacity(0.3)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                )
                        )
                        .aquaBevel(cornerRadius: 14)

                        TextField("(555) 123-4567", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .pledgeHeadline()
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.black.opacity(0.05))
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(
                                        isPhoneFocused ? theme.surface : Color.primary.opacity(0.1),
                                        lineWidth: isPhoneFocused ? 2 : 0.5
                                    )
                            )
                            .shadow(color: isPhoneFocused ? theme.surface.opacity(0.3) : .clear, radius: 8)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .focused($isPhoneFocused)
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    VStack(spacing: 16) {
                        NumberPadView(value: $phoneNumber, maxDigits: 10, allowDecimal: false)
                            .padding(.horizontal, 8)

                        Button {
                            PPHaptic.medium()
                            showOTP = true
                        } label: {
                            Text("Continue")
                        }
                        .buttonStyle(PrimaryCapsuleStyle(isEnabled: isValid))
                        .disabled(!isValid)
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.4), Color.white.opacity(0.0)],
                                            startPoint: .top,
                                            endPoint: .center
                                        ),
                                        lineWidth: 0.5
                                    )
                            )
                            .shadow(color: .black.opacity(0.15), radius: 16, y: -4)
                            .ignoresSafeArea(edges: .bottom)
                    )

                    Spacer().frame(height: 8)

                    Text("By continuing, you agree to our [Terms](https://pledge.app/terms) & [Privacy Policy](https://pledge.app/privacy)")
                        .pledgeCaption()
                        .foregroundColor(.secondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }
            }
            .navigationDestination(isPresented: $showOTP) {
                OTPVerificationView()
            }
        }
    }
}

#Preview {
    PhoneEntryView()
        .environmentObject(AppState())
}
