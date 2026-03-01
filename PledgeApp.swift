import SwiftUI

@main
struct PledgeApp: App {
    @StateObject private var appState = AppState()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash || appState.authService.isLoading {
                    SplashView()
                        .transition(.opacity)
                } else if !appState.hasCompletedOnboarding {
                    OnboardingContainerView()
                        .transition(.opacity)
                } else if !appState.isAuthenticated {
                    SignInWithAppleView()
                        .transition(.slideIn)
                } else if !appState.hasCompletedSetup {
                    SetupContainerView()
                        .transition(.slideIn)
                } else {
                    MainTabView()
                        .transition(.opacity)
                }
            }
            .environmentObject(appState)
            .environment(\.themeColors, appState.backgroundTheme.colors)
            .preferredColorScheme(appState.backgroundTheme.isLight ? .light : .dark)
            .animation(.easeInOut(duration: 0.4), value: showSplash)
            .animation(.easeInOut(duration: 0.4), value: appState.authService.isLoading)
            .animation(.springBounce, value: appState.hasCompletedOnboarding)
            .animation(.springBounce, value: appState.isAuthenticated)
            .animation(.springBounce, value: appState.hasCompletedSetup)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showSplash = false
                }
            }
            .task {
                // Run initial verification after auth (permissions are handled in setup flow)
                guard appState.isAuthenticated else { return }
                await appState.verifyTodayHabits()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Re-verify habits when app returns from background
                guard appState.isAuthenticated else { return }
                Task {
                    await appState.verifyTodayHabits()
                }
            }
        }
    }
}
