import SwiftUI

@main
struct PledgeApp: App {
    @StateObject private var appState = AppState()
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                } else if !appState.hasCompletedOnboarding {
                    OnboardingContainerView()
                        .transition(.opacity)
                } else if !appState.isAuthenticated {
                    PhoneEntryView()
                        .transition(.slideIn)
                } else {
                    MainTabView()
                        .transition(.opacity)
                }
            }
            .environmentObject(appState)
            .animation(.easeInOut(duration: 0.4), value: showSplash)
            .animation(.springBounce, value: appState.hasCompletedOnboarding)
            .animation(.springBounce, value: appState.isAuthenticated)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showSplash = false
                }
            }
        }
    }
}
