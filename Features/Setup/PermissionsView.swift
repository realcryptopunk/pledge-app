import SwiftUI

struct PermissionsView: View {
    let flowState: SetupFlowState

    @Environment(\.themeColors) var theme
    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var location = LocationManager.shared
    @StateObject private var notifications = NotificationManager.shared
    @State private var buttonVisible = false

    // MARK: - Permission Requirements

    private var needsHealthKit: Bool {
        flowState.selectedTypes.contains { type in
            type.defaultVerification == .healthKit
        }
    }

    private var needsLocation: Bool {
        flowState.selectedTypes.contains { type in
            type == .gym || type.defaultVerification == .location
        }
    }

    // MARK: - Permission Cards Data

    private var permissionCards: [(id: String, icon: String, title: String, description: String, isGranted: Bool, action: () async -> Void)] {
        var cards: [(id: String, icon: String, title: String, description: String, isGranted: Bool, action: () async -> Void)] = []

        if needsHealthKit {
            cards.append((
                id: "healthkit",
                icon: "heart.fill",
                title: "Apple Health",
                description: "Verify steps, sleep, and workouts automatically",
                isGranted: healthKit.isAuthorized,
                action: {
                    try? await HealthKitManager.shared.requestAuthorization()
                }
            ))
        }

        if needsLocation {
            cards.append((
                id: "location",
                icon: "location.fill",
                title: "Location",
                description: "Verify gym visits with geofence check-ins",
                isGranted: location.isAuthorized,
                action: {
                    await LocationManager.shared.requestAuthorization()
                }
            ))
        }

        // Notifications always shown
        cards.append((
            id: "notifications",
            icon: "bell.fill",
            title: "Notifications",
            description: "Get reminders before your habits are due so you never miss a pledge",
            isGranted: notifications.isAuthorized,
            action: {
                await NotificationManager.shared.requestAuthorization()
            }
        ))

        return cards
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 8) {
                Text("Permissions")
                    .pledgeHero()
                    .foregroundColor(.primary)
                Text("Enable these to get the most out of Pledge")
                    .pledgeBody()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)

            // Permission cards
            VStack(spacing: 12) {
                ForEach(Array(permissionCards.enumerated()), id: \.element.id) { index, card in
                    PermissionCardView(
                        icon: card.icon,
                        title: card.title,
                        description: card.description,
                        isGranted: card.isGranted,
                        action: card.action
                    )
                    .staggerIn(index: index)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            Button {
                PPHaptic.medium()
                flowState.goForward()
            } label: {
                Text("Continue")
            }
            .buttonStyle(PrimaryCapsuleStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(buttonVisible ? 1 : 0)
            .offset(y: buttonVisible ? 0 : 10)
            .onAppear {
                withAnimation(.springBounce.delay(0.3)) {
                    buttonVisible = true
                }
            }
        }
    }
}

// MARK: - Permission Card

private struct PermissionCardView: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () async -> Void

    @Environment(\.themeColors) var theme
    @State private var isRequesting = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.light.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(theme.light)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .pledgeHeadline()
                    .foregroundColor(.primary)
                Text(description)
                    .pledgeCaption()
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.pledgeGreen)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    guard !isRequesting else { return }
                    isRequesting = true
                    PPHaptic.light()
                    Task {
                        await action()
                        isRequesting = false
                    }
                } label: {
                    Text("Enable")
                        .pledgeCaption()
                        .foregroundColor(theme.light)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(theme.light.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .aquaGlass(cornerRadius: 16)
        .animation(.springBounce, value: isGranted)
    }
}

#Preview {
    ZStack {
        WaterBackgroundView()
        PermissionsView(flowState: {
            let state = SetupFlowState()
            state.selectedTypes = [.steps, .gym]
            return state
        }())
    }
    .environmentObject(AppState())
}
