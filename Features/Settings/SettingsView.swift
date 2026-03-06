import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var faceIDEnabled = true
    @State private var showEditProfile = false
    @State private var editingName = ""
    @State private var showSignOutConfirmation = false
    @State private var showDeleteConfirmation = false
    @Environment(\.themeColors) var theme

    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Profile Header
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.light, theme.buttonTop],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                                    )
                                Text(String(appState.userName.prefix(1)).uppercased())
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.userName)
                                    .pledgeHeadline()
                                    .foregroundColor(.primary)
                                Text("@\(appState.userName.lowercased()) · Joined Feb 2026")
                                    .pledgeCaption()
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button("Edit") {
                                editingName = appState.userName
                                showEditProfile = true
                            }
                            .buttonStyle(GhostButtonStyle(color: theme.surface))
                        }
                        .cleanCard()

                        // MARK: - Background Theme
                        settingsSection("BACKGROUND") {
                            ThemePickerView()
                        }

                        // MARK: - Account
                        settingsSection("ACCOUNT") {
                            settingsRow(icon: "💳", label: "Payment Methods")
                            StatRowDivider()
                            settingsRow(icon: "💰", label: "Deposit / Withdraw")
                            StatRowDivider()
                            settingsRow(icon: "📊", label: "Pledge History")
                        }

                        // MARK: - Preferences
                        settingsSection("PREFERENCES") {
                            NavigationLink {
                                NotificationSettingsView()
                            } label: {
                                HStack(spacing: 12) {
                                    Text("\u{1F514}")
                                    Text("Notifications")
                                        .pledgeHeadline()
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary.opacity(0.5))
                                }
                                .padding(.vertical, 10)
                            }
                            StatRowDivider()
                            HStack {
                                Text("🔒")
                                Text("Face ID")
                                    .pledgeHeadline()
                                    .foregroundColor(.primary)
                                Spacer()
                                Toggle("", isOn: $faceIDEnabled)
                                    .tint(theme.light)
                            }
                            .padding(.vertical, 10)
                            StatRowDivider()
                            settingsRow(icon: "💵", label: "Default Stake", value: "$10")
                            StatRowDivider()
                            settingsRow(icon: "🛡️", label: "Weekly Cap", value: "$200")
                        }

                        // MARK: - Premium
                        settingsSection("PREMIUM") {
                            HStack(spacing: 12) {
                                Text("⭐")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upgrade to Premium")
                                        .pledgeHeadline()
                                        .foregroundColor(.primary)
                                    Text("Unlimited habits, custom strategies, and more")
                                        .pledgeCaption()
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            .padding(.vertical, 10)
                        }

                        // MARK: - Safety
                        settingsSection("SAFETY") {
                            settingsRow(icon: "⏸️", label: "Pause All Pledges")
                            StatRowDivider()
                            settingsRow(icon: "🚫", label: "Self-Exclusion")
                            StatRowDivider()
                            settingsRow(icon: "📉", label: "Reduce My Stakes")
                        }

                        // MARK: - About
                        settingsSection("ABOUT") {
                            settingsRow(icon: "❓", label: "Help & Support")
                            StatRowDivider()
                            settingsRow(icon: "📄", label: "Terms of Service")
                            StatRowDivider()
                            settingsRow(icon: "🔐", label: "Privacy Policy")
                            StatRowDivider()
                            HStack {
                                Text("ℹ️")
                                Text("Version 1.0.0")
                                    .pledgeHeadline()
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 10)
                        }

                        // MARK: - Sign Out / Delete
                        VStack(spacing: 0) {
                            Button {
                                PPHaptic.warning()
                                showSignOutConfirmation = true
                            } label: {
                                Text("Sign Out")
                                    .pledgeHeadline()
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            StatRowDivider()
                            Button {
                                PPHaptic.warning()
                                showDeleteConfirmation = true
                            } label: {
                                Text("Delete Account")
                                    .pledgeHeadline()
                                    .foregroundColor(.pledgeRed)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                        }
                        .cleanCard()

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(theme.isLight ? .light : .dark, for: .navigationBar)
            .alert("Edit Name", isPresented: $showEditProfile) {
                TextField("Name", text: $editingName)
                Button("Save") {
                    let trimmed = editingName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        appState.userName = trimmed
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter your display name")
            }
            .alert(
                "Sign Out",
                isPresented: $showSignOutConfirmation
            ) {
                Button("Sign Out", role: .destructive) {
                    PPHaptic.medium()
                    Task {
                        await appState.signOut()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to sign out? Your habits and data will be cleared from this device.")
            }
            .confirmationDialog(
                "Delete Account",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    PPHaptic.heavy()
                    Task {
                        await appState.signOut()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. All your data, habits, and investment history will be permanently deleted.")
            }
        }
    }

    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .pledgeCaption()
                .foregroundColor(.secondary)
                .tracking(1)

            VStack(spacing: 0) {
                content()
            }
            .cleanCard()
        }
    }

    private func settingsRow(icon: String, label: String, value: String? = nil) -> some View {
        Button { } label: {
            HStack(spacing: 12) {
                Text(icon)
                Text(label)
                    .pledgeHeadline()
                    .foregroundColor(.primary)
                Spacer()
                if let value {
                    Text(value)
                        .pledgeCaption()
                        .foregroundColor(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.vertical, 10)
        }
    }
}

struct ThemePickerView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(BackgroundTheme.allCases) { bgTheme in
                        ThemeOptionView(
                            theme: bgTheme,
                            isSelected: appState.backgroundTheme == bgTheme
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                appState.backgroundTheme = bgTheme
                            }
                            PPHaptic.selection()
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ThemeOptionView: View {
    let theme: BackgroundTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.colors.deep, theme.colors.mid, theme.colors.light],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.primary : Color.primary.opacity(0.15),
                                    lineWidth: isSelected ? 2.5 : 0.5
                                )
                        )
                        .shadow(
                            color: isSelected ? theme.colors.surface.opacity(0.5) : .clear,
                            radius: 8
                        )

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(theme.isLight ? .black : .white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                }

                Text(theme.displayName)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)

                Image(systemName: theme.icon)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? theme.colors.surface : .secondary.opacity(0.5))
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
