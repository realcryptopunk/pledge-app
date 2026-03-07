import SwiftUI

// MARK: - Auth Step

private enum AuthStep {
    case phone
    case otp
}

// MARK: - PrivyAuthView

struct PrivyAuthView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme

    @State private var step: AuthStep = .phone
    @State private var phoneNumber: String = ""
    @State private var otpCode: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var shakeError: Bool = false
    @FocusState private var phoneFieldFocused: Bool
    @FocusState private var otpFieldFocused: Bool

    var body: some View {
        ZStack {
            WaterBackgroundView()

            // Fluid purple glow at top
            VStack {
                FluidPurpleGlow()
                Spacer()
            }
            .ignoresSafeArea()

            switch step {
            case .phone:
                phoneStepView
                    .transition(.slideIn)
            case .otp:
                otpStepView
                    .transition(.slideIn)
            }
        }
        .animation(.springBounce, value: step)
        .onChange(of: step) { _, newStep in
            if newStep == .otp {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    otpFieldFocused = true
                }
            }
        }
    }

    // MARK: - Phone Step

    private var phoneStepView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.surface, theme.light],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: theme.surface.opacity(0.4), radius: 20, y: 10)
                .staggerIn(index: 0)

            Spacer().frame(height: 24)

            // Header
            Text("Welcome to")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .staggerIn(index: 0)

            Text("Pledge")
                .pledgeHero(48)
                .foregroundColor(.primary)
                .embossed(.raised)
                .staggerIn(index: 0)

            Spacer().frame(height: 12)

            Text("Stake your habits.\nBuild your future.")
                .pledgeBody()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .staggerIn(index: 1)

            Spacer()

            // Phone Input Card
            VStack(spacing: 20) {
                // Phone number field
                HStack(spacing: 12) {
                    // Country code
                    Text("+1")
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)

                    // Divider line
                    Rectangle()
                        .fill(Color.primary.opacity(0.15))
                        .frame(width: 1, height: 28)

                    // Phone number input
                    TextField("(555) 555-1234", text: $phoneNumber)
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .keyboardType(.numberPad)
                        .textContentType(.telephoneNumber)
                        .focused($phoneFieldFocused)
                        .onChange(of: phoneNumber) { _, newValue in
                            phoneNumber = formatPhoneDisplay(newValue)
                        }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                .staggerIn(index: 2)
                .shakeAlert(trigger: $shakeError)

                // Error message
                if let errorMessage {
                    Text(errorMessage)
                        .pledgeCaption()
                        .foregroundColor(.pledgeRed)
                        .multilineTextAlignment(.center)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Continue button
                Button {
                    sendOTP()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Continue")
                    }
                }
                .buttonStyle(PrimaryCapsuleStyle(isEnabled: isPhoneValid && !isLoading))
                .disabled(!isPhoneValid || isLoading)
                .staggerIn(index: 3)

                // Skip for now
                Button {
                    appState.privyManager.signInAsGuest()
                } label: {
                    Text("Skip for now \u{2192}")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .disabled(isLoading)

                // Terms
                Text("By continuing, you agree to our Terms & Privacy Policy")
                    .pledgeCaption()
                    .foregroundColor(.secondary.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .staggerIn(index: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - OTP Step

    private var otpStepView: some View {
        VStack(spacing: 0) {
            // Top bar with back button
            HStack {
                Button {
                    withAnimation(.springBounce) {
                        step = .phone
                        otpCode = ""
                        errorMessage = nil
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()

            // Lock icon
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.surface, theme.light],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: theme.surface.opacity(0.4), radius: 16, y: 8)
                .staggerIn(index: 0)

            Spacer().frame(height: 24)

            // Header
            Text("Enter verification code")
                .pledgeDisplay(28)
                .foregroundColor(.primary)
                .embossed(.raised)
                .staggerIn(index: 0)

            Spacer().frame(height: 8)

            Text("Sent to \(formattedPhoneForDisplay)")
                .pledgeBody()
                .foregroundColor(.secondary)
                .staggerIn(index: 1)

            Spacer().frame(height: 40)

            // OTP Code Boxes
            otpCodeField
                .staggerIn(index: 2)

            Spacer().frame(height: 16)

            // Error message
            if let errorMessage {
                Text(errorMessage)
                    .pledgeCaption()
                    .foregroundColor(.pledgeRed)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer().frame(height: 24)

            // Verify button
            Button {
                verifyOTP()
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Verify")
                }
            }
            .buttonStyle(PrimaryCapsuleStyle(isEnabled: isOTPComplete && !isLoading))
            .disabled(!isOTPComplete || isLoading)
            .staggerIn(index: 3)

            Spacer().frame(height: 16)

            // Resend code
            Button {
                resendOTP()
            } label: {
                Text("Resend code")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.light)
            }
            .disabled(isLoading)
            .staggerIn(index: 4)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - OTP Code Field

    private var otpCodeField: some View {
        ZStack {
            // Hidden text field to capture keyboard input
            TextField("", text: $otpCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($otpFieldFocused)
                .foregroundColor(.clear)
                .tint(.clear)
                .accentColor(.clear)
                .frame(maxWidth: .infinity, maxHeight: 56)
                .onChange(of: otpCode) { _, newValue in
                    let filtered = String(newValue.filter { $0.isNumber }.prefix(6))
                    if filtered != newValue {
                        otpCode = filtered
                    }
                    if filtered.count == 6 {
                        verifyOTP()
                    }
                }

            // Visual digit boxes on top
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    otpDigitBox(at: index)
                }
            }
            .allowsHitTesting(false)
        }
        .onTapGesture {
            otpFieldFocused = true
        }
    }

    private func otpDigitBox(at index: Int) -> some View {
        let digit: String = {
            let chars = Array(otpCode)
            return index < chars.count ? String(chars[index]) : ""
        }()

        let isActive = index == otpCode.count
        let isFilled = index < otpCode.count

        return Text(digit)
            .font(.system(size: 28, weight: .bold, design: .monospaced))
            .foregroundColor(.primary)
            .frame(width: 48, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isActive ? theme.light :
                            (isFilled ? theme.surface.opacity(0.5) : Color.white.opacity(0.15)),
                        lineWidth: isActive ? 2 : 1
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.quickSnap, value: otpCode.count)
    }

    // MARK: - Phone Formatting

    /// Whether the phone number has 10 digits (valid US number)
    private var isPhoneValid: Bool {
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.count == 10
    }

    /// Format phone as (XXX) XXX-XXXX for display
    private func formatPhoneDisplay(_ input: String) -> String {
        let digits = String(input.filter { $0.isNumber }.prefix(10))
        let count = digits.count

        if count == 0 { return "" }
        if count <= 3 { return "(\(digits)" }

        let areaCode = digits.prefix(3)
        if count <= 6 {
            let middle = digits.dropFirst(3)
            return "(\(areaCode)) \(middle)"
        }

        let middle = digits.dropFirst(3).prefix(3)
        let last = digits.dropFirst(6)
        return "(\(areaCode)) \(middle)-\(last)"
    }

    /// E.164 format for sending: +1XXXXXXXXXX
    private var e164Phone: String {
        let digits = phoneNumber.filter { $0.isNumber }
        return "+1\(digits)"
    }

    /// Display format for OTP screen header
    private var formattedPhoneForDisplay: String {
        formatPhoneDisplay(phoneNumber.filter { $0.isNumber })
    }

    // MARK: - OTP Validation

    private var isOTPComplete: Bool {
        otpCode.count == 6
    }

    // MARK: - Actions

    private func sendOTP() {
        guard isPhoneValid else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await appState.privyManager.sendOTP(to: e164Phone)
                withAnimation(.springBounce) {
                    step = .otp
                }
                PPHaptic.success()
            } catch {
                errorMessage = error.localizedDescription
                shakeError = true
                PPHaptic.error()
            }
            isLoading = false
        }
    }

    private func verifyOTP() {
        guard isOTPComplete else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await appState.privyManager.verifyOTP(code: otpCode, phoneNumber: e164Phone)
                PPHaptic.success()
                // isAuthenticated will be set by PrivyManager -> AppState Combine pipeline
            } catch {
                errorMessage = error.localizedDescription
                shakeError = true
                PPHaptic.error()
            }
            isLoading = false
        }
    }

    private func resendOTP() {
        otpCode = ""
        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await appState.privyManager.sendOTP(to: e164Phone)
                PPHaptic.light()
            } catch {
                errorMessage = error.localizedDescription
                PPHaptic.error()
            }
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview {
    PrivyAuthView()
        .environmentObject(AppState())
}
