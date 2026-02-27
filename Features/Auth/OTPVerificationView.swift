import SwiftUI

struct OTPVerificationView: View {
    @EnvironmentObject var appState: AppState
    @State private var digits: [String] = Array(repeating: "", count: 6)
    @State private var focusedIndex = 0
    @State private var isVerifying = false
    @State private var showError = false
    @State private var showSuccess = false
    @State private var shakeError = false
    @State private var resendTimer = 30
    @FocusState private var isFieldFocused: Bool
    @Environment(\.themeColors) var theme

    @State private var hiddenText = ""

    var body: some View {
        ZStack {
            WaterBackgroundView()

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("Enter the code")
                    .pledgeHero(36)
                    .foregroundColor(.primary)
                    .embossed(.raised)

                Spacer().frame(height: 8)

                Text("Sent to +1 (555) 123-4567")
                    .pledgeBody()
                    .foregroundColor(.secondary)

                Spacer().frame(height: 48)

                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { index in
                        OTPBox(
                            digit: digitAt(index),
                            isFocused: focusedIndex == index && !showSuccess,
                            isSuccess: showSuccess,
                            isError: showError,
                            themeSurface: theme.surface
                        )
                    }
                }
                .shakeAlert(trigger: $shakeError)
                .padding(.horizontal, 24)

                TextField("", text: $hiddenText)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isFieldFocused)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .onChange(of: hiddenText) { _, newValue in
                        let filtered = String(newValue.prefix(6).filter { $0.isNumber })
                        hiddenText = filtered
                        updateDigits(from: filtered)
                        focusedIndex = min(filtered.count, 5)

                        if filtered.count == 6 {
                            verifyCode(filtered)
                        }
                    }

                if showError {
                    Text("Invalid code. Please try again.")
                        .pledgeCaption()
                        .foregroundColor(.pledgeRed)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                if resendTimer > 0 {
                    Text("Resend code in \(resendTimer)s")
                        .pledgeCallout()
                        .foregroundColor(.secondary)
                } else {
                    Button("Resend code") {
                        resendTimer = 30
                        startTimer()
                    }
                    .buttonStyle(GhostButtonStyle(color: theme.surface))
                }

                Spacer().frame(height: 32)
            }
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
            isFieldFocused = true
            startTimer()
        }
    }

    private func digitAt(_ index: Int) -> String {
        guard index < hiddenText.count else { return "" }
        let i = hiddenText.index(hiddenText.startIndex, offsetBy: index)
        return String(hiddenText[i])
    }

    private func updateDigits(from text: String) {
        for i in 0..<6 {
            digits[i] = i < text.count ? String(text[text.index(text.startIndex, offsetBy: i)]) : ""
        }
    }

    private func verifyCode(_ code: String) {
        isVerifying = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.quickSnap) { showSuccess = true }
            PPHaptic.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.springBounce) { appState.isAuthenticated = true }
            }
        }
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if resendTimer > 0 { resendTimer -= 1 } else { timer.invalidate() }
        }
    }
}

struct OTPBox: View {
    let digit: String
    let isFocused: Bool
    let isSuccess: Bool
    let isError: Bool
    var themeSurface: Color = .poolSurface

    var borderColor: Color {
        if isSuccess { return .pledgeGreen }
        if isError { return .pledgeRed }
        if isFocused { return themeSurface }
        return .primary.opacity(0.15)
    }

    var body: some View {
        Text(digit)
            .pledgeDisplay(24)
            .foregroundColor(.primary)
            .embossed(.raised)
            .frame(width: 48, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.black.opacity(0.05))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: isFocused || isSuccess || isError ? 2 : 0.5)
            )
            .shadow(color: isFocused ? themeSurface.opacity(0.4) : .clear, radius: 8)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .animation(.quickSnap, value: isFocused)
            .animation(.quickSnap, value: isSuccess)
    }
}

#Preview {
    NavigationStack {
        OTPVerificationView()
            .environmentObject(AppState())
    }
}
