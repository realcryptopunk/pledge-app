import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme
    @Environment(\.dismiss) var dismiss

    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var isAvailable: Bool? = nil
    @State private var isChecking = false
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var debounceTask: Task<Void, Never>? = nil

    private var originalUsername: String {
        appState.userName
    }

    // MARK: - Validation

    private var sanitizedUsername: String {
        username.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    private var isValidFormat: Bool {
        let pattern = "^[a-z0-9_]{3,20}$"
        return sanitizedUsername.range(of: pattern, options: .regularExpression) != nil
    }

    private var usernameChanged: Bool {
        sanitizedUsername != originalUsername.lowercased()
    }

    private var canSave: Bool {
        if usernameChanged {
            return isValidFormat && isAvailable == true && !isChecking && !isSaving
        }
        return !isSaving // Can always save display name changes
    }

    private var validationMessage: String? {
        if !usernameChanged { return nil }
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

    // MARK: - Body

    var body: some View {
        ZStack {
            WaterBackgroundView()

            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Avatar
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [theme.light, theme.buttonTop],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                                )

                            Text(String(appState.userName.prefix(1)).uppercased())
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .staggerIn(index: 0)
                    }

                    // MARK: - Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("USERNAME")
                            .pledgeCaption()
                            .foregroundColor(.secondary)
                            .tracking(1)

                        HStack(spacing: 4) {
                            Text("@")
                                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)

                            TextField("username", text: $username)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .onChange(of: username) { _, newValue in
                                    let sanitized = newValue.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
                                    if sanitized != newValue {
                                        username = sanitized
                                    }
                                    isAvailable = nil
                                    errorMessage = nil
                                    successMessage = nil
                                    if usernameChanged { debounceAvailabilityCheck() }
                                }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        // Validation
                        HStack(spacing: 6) {
                            if usernameChanged {
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
                            }

                            if let message = validationMessage {
                                Text(message)
                                    .pledgeCaption()
                                    .foregroundColor(isAvailable == true ? .pledgeGreen : isAvailable == false ? .pledgeRed : .secondary)
                            } else if usernameChanged && isAvailable == true && isValidFormat {
                                Text("Username is available!")
                                    .pledgeCaption()
                                    .foregroundColor(.pledgeGreen)
                            }

                            Spacer()
                        }
                        .frame(height: 14)
                    }
                    .cleanCard()
                    .staggerIn(index: 1)

                    // MARK: - Display Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DISPLAY NAME")
                            .pledgeCaption()
                            .foregroundColor(.secondary)
                            .tracking(1)

                        TextField("Display name", text: $displayName)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .cleanCard()
                    .staggerIn(index: 2)

                    // MARK: - Read-Only Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ACCOUNT")
                            .pledgeCaption()
                            .foregroundColor(.secondary)
                            .tracking(1)

                        VStack(spacing: 0) {
                            // Wallet address
                            if !appState.walletAddress.isEmpty {
                                HStack(spacing: 12) {
                                    Text("Wallet")
                                        .pledgeHeadline()
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Text(truncatedWallet)
                                        .pledgeMonoSmall()
                                        .foregroundColor(.secondary)

                                    Button {
                                        UIPasteboard.general.string = appState.walletAddress
                                        PPHaptic.light()
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 12)

                                StatRowDivider()
                            }

                            // Phone
                            if !appState.userPhone.isEmpty {
                                HStack(spacing: 12) {
                                    Text("Phone")
                                        .pledgeHeadline()
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Text(appState.userPhone)
                                        .pledgeCaption()
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 12)
                            }
                        }
                    }
                    .cleanCard()
                    .staggerIn(index: 3)

                    // MARK: - Feedback
                    if let error = errorMessage {
                        Text(error)
                            .pledgeCaption()
                            .foregroundColor(.pledgeRed)
                            .transition(.opacity)
                    }

                    if let success = successMessage {
                        Text(success)
                            .pledgeCaption()
                            .foregroundColor(.pledgeGreen)
                            .transition(.opacity)
                    }

                    // MARK: - Save Button
                    Button {
                        saveProfile()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Changes")
                        }
                    }
                    .buttonStyle(PrimaryCapsuleStyle(isEnabled: canSave))
                    .disabled(!canSave)
                    .staggerIn(index: 4)

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(theme.isLight ? .light : .dark, for: .navigationBar)
        .onAppear {
            username = appState.userName
            // Display name could be loaded from profile but for now use userName as fallback
            displayName = ""
        }
    }

    // MARK: - Helpers

    private var truncatedWallet: String {
        let addr = appState.walletAddress
        if addr.count > 12 {
            return "\(addr.prefix(6))...\(addr.suffix(4))"
        }
        return addr
    }

    // MARK: - Debounced Availability Check

    private func debounceAvailabilityCheck() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            guard isValidFormat && usernameChanged else { return }
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
            }
        }
        isChecking = false
    }

    // MARK: - Save

    private func saveProfile() {
        guard canSave else { return }
        isSaving = true
        errorMessage = nil
        successMessage = nil
        PPHaptic.medium()

        Task {
            do {
                let newUsername = usernameChanged ? sanitizedUsername : nil
                let trimmedDisplay = displayName.trimmingCharacters(in: .whitespaces)
                let newDisplay = trimmedDisplay.isEmpty ? nil : trimmedDisplay

                try await appState.updateProfile(
                    username: newUsername,
                    displayName: newDisplay
                )
                successMessage = "Profile updated!"
                PPHaptic.success()

                // Dismiss after a brief delay
                try? await Task.sleep(nanoseconds: 800_000_000)
                dismiss()
            } catch {
                errorMessage = "Failed to save changes. Please try again."
                PPHaptic.error()
            }
            isSaving = false
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
            .environmentObject(AppState())
    }
}
