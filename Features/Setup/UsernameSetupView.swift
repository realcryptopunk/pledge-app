import SwiftUI
import Combine

struct UsernameSetupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme
    @FocusState private var usernameFocused: Bool

    @State private var username = ""
    @State private var displayName = ""
    @State private var isAvailable: Bool? = nil
    @State private var isChecking = false
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var debounceTask: Task<Void, Never>? = nil

    // MARK: - Validation

    private var sanitizedUsername: String {
        username.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    private var isValidLength: Bool {
        sanitizedUsername.count >= 3 && sanitizedUsername.count <= 20
    }

    private var isValidFormat: Bool {
        let pattern = "^[a-z0-9_]{3,20}$"
        return sanitizedUsername.range(of: pattern, options: .regularExpression) != nil
    }

    private var canContinue: Bool {
        isValidFormat && isAvailable == true && !isChecking && !isSaving
    }

    private var validationMessage: String? {
        if sanitizedUsername.isEmpty { return nil }
        if sanitizedUsername.count < 3 { return "Must be at least 3 characters" }
        if sanitizedUsername.count > 20 { return "Must be 20 characters or less" }
        if !isValidFormat { return "Only lowercase letters, numbers, and underscores" }
        if isChecking { return "Checking availability..." }
        if let isAvailable {
            return isAvailable ? nil : "Username is already taken"
        }
        return nil
    }

    private var usernameFieldBorderColor: Color {
        if isAvailable == true && isValidFormat { return .pledgeGreen.opacity(0.5) }
        if isAvailable == false { return .pledgeRed.opacity(0.5) }
        return Color.white.opacity(0.2)
    }

    private var validationColor: Color {
        if isChecking { return .secondary }
        if isAvailable == true && isValidFormat { return .pledgeGreen }
        if isAvailable == false || (sanitizedUsername.count > 0 && !isValidFormat) { return .pledgeRed }
        return .secondary
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            WaterBackgroundView()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                Image(systemName: "at.circle.fill")
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

                Text("Choose your username")
                    .pledgeDisplay(28)
                    .foregroundColor(.primary)
                    .embossed(.raised)
                    .staggerIn(index: 0)

                Spacer().frame(height: 8)

                Text("This is how you'll appear on leaderboards")
                    .pledgeBody()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .staggerIn(index: 1)

                Spacer()

                // Input fields
                VStack(spacing: 16) {
                    // Username field
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Text("@")
                                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)

                            TextField("username", text: $username)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($usernameFocused)
                                .onChange(of: username) { _, newValue in
                                    // Auto-sanitize: lowercase and valid chars only
                                    let sanitized = newValue.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
                                    if sanitized != newValue {
                                        username = sanitized
                                    }
                                    // Reset availability and debounce check
                                    isAvailable = nil
                                    errorMessage = nil
                                    debounceAvailabilityCheck()
                                }
                                .onSubmit {
                                    if canContinue { saveUsername() }
                                }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(usernameFieldBorderColor, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)

                        // Validation feedback
                        HStack(spacing: 6) {
                            if isChecking {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else if isAvailable == true && isValidFormat {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.pledgeGreen)
                                    .font(.system(size: 12))
                            } else if isAvailable == false {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.pledgeRed)
                                    .font(.system(size: 12))
                            }

                            if let message = validationMessage {
                                Text(message)
                                    .pledgeCaption()
                                    .foregroundColor(validationColor)
                            } else if isAvailable == true && isValidFormat {
                                Text("Username is available!")
                                    .pledgeCaption()
                                    .foregroundColor(.pledgeGreen)
                            }

                            Spacer()

                            Text("\(sanitizedUsername.count)/20")
                                .pledgeCaption()
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 4)
                        .frame(height: 16)
                    }
                    .staggerIn(index: 2)

                    // Display name field (optional)
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Display name (optional)", text: $displayName)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
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
                    }
                    .staggerIn(index: 3)

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .pledgeCaption()
                            .foregroundColor(.pledgeRed)
                            .transition(.opacity)
                    }

                    // Continue button
                    Button {
                        saveUsername()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Continue")
                        }
                    }
                    .buttonStyle(PrimaryCapsuleStyle(isEnabled: canContinue))
                    .disabled(!canContinue)
                    .staggerIn(index: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                usernameFocused = true
            }
        }
    }

    // MARK: - Debounced Availability Check

    private func debounceAvailabilityCheck() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
            guard !Task.isCancelled else { return }
            guard isValidFormat else { return }
            await checkAvailability()
        }
    }

    @MainActor
    private func checkAvailability() async {
        isChecking = true
        do {
            let available = try await appState.checkUsernameAvailable(sanitizedUsername)
            if !Task.isCancelled {
                isAvailable = available
            }
        } catch {
            if !Task.isCancelled {
                isAvailable = nil
                errorMessage = "Could not check availability"
            }
        }
        isChecking = false
    }

    // MARK: - Save

    private func saveUsername() {
        guard canContinue else { return }
        isSaving = true
        errorMessage = nil
        PPHaptic.medium()

        Task {
            do {
                let trimmedDisplay = displayName.trimmingCharacters(in: .whitespaces)
                try await appState.completeUsernameSetup(
                    username: sanitizedUsername,
                    displayName: trimmedDisplay.isEmpty ? nil : trimmedDisplay
                )
                PPHaptic.success()
            } catch {
                errorMessage = "Failed to save username. Please try again."
                PPHaptic.error()
            }
            isSaving = false
        }
    }
}

#Preview {
    UsernameSetupView()
        .environmentObject(AppState())
}
