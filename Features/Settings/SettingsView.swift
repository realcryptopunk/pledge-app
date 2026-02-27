import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var faceIDEnabled = true
    @State private var appearance = 0 // 0=Auto, 1=Light, 2=Dark
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile card
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.pledgeBlue)
                                .frame(width: 56, height: 56)
                            Text("N")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appState.userName)
                                .pledgeHeadline()
                                .foregroundColor(.pledgeBlackAdaptive)
                            Text("@nav · Joined Feb 2026")
                                .pledgeCaption()
                                .foregroundColor(.pledgeGray)
                        }
                        
                        Spacer()
                        
                        Button("Edit") { }
                            .buttonStyle(GhostButtonStyle(color: .pledgeBlue))
                    }
                    .cleanCard()
                    
                    // Account
                    settingsSection("ACCOUNT") {
                        settingsRow(icon: "💳", label: "Payment Methods")
                        StatRowDivider()
                        settingsRow(icon: "💰", label: "Deposit / Withdraw")
                        StatRowDivider()
                        settingsRow(icon: "📊", label: "Pledge History")
                    }
                    
                    // Preferences
                    settingsSection("PREFERENCES") {
                        settingsRow(icon: "🔔", label: "Notifications")
                        StatRowDivider()
                        HStack {
                            Text("🔒")
                            Text("Face ID")
                                .pledgeHeadline()
                                .foregroundColor(.pledgeBlackAdaptive)
                            Spacer()
                            Toggle("", isOn: $faceIDEnabled)
                                .tint(.pledgeBlue)
                        }
                        .padding(.vertical, 10)
                        StatRowDivider()
                        settingsRow(icon: "🌙", label: "Appearance", value: "Auto")
                        StatRowDivider()
                        settingsRow(icon: "💵", label: "Default Stake", value: "$10")
                        StatRowDivider()
                        settingsRow(icon: "🛡️", label: "Weekly Cap", value: "$200")
                    }
                    
                    // Premium
                    settingsSection("PREMIUM") {
                        HStack(spacing: 12) {
                            Text("⭐")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upgrade to Premium")
                                    .pledgeHeadline()
                                    .foregroundColor(.pledgeBlackAdaptive)
                                Text("Unlimited habits, custom strategies, and more")
                                    .pledgeCaption()
                                    .foregroundColor(.pledgeGray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.pledgeGrayLight)
                        }
                        .padding(.vertical, 10)
                    }
                    
                    // Safety
                    settingsSection("SAFETY") {
                        settingsRow(icon: "⏸️", label: "Pause All Pledges")
                        StatRowDivider()
                        settingsRow(icon: "🚫", label: "Self-Exclusion")
                        StatRowDivider()
                        settingsRow(icon: "📉", label: "Reduce My Stakes")
                    }
                    
                    // About
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
                                .foregroundColor(.pledgeBlackAdaptive)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                    
                    // Sign Out / Delete
                    VStack(spacing: 0) {
                        Button { } label: {
                            Text("Sign Out")
                                .pledgeHeadline()
                                .foregroundColor(.pledgeGray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        StatRowDivider()
                        Button { } label: {
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
            .background(Color.pledgeBgAdaptive)
            .navigationTitle("Settings")
        }
    }
    
    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .pledgeCaption()
                .foregroundColor(.pledgeGray)
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
                    .foregroundColor(.pledgeBlackAdaptive)
                Spacer()
                if let value {
                    Text(value)
                        .pledgeCaption()
                        .foregroundColor(.pledgeGray)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.pledgeGrayLight)
            }
            .padding(.vertical, 10)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
