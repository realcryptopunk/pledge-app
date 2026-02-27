import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            HabitsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Habits")
                }
                .tag(1)

            PortfolioView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Portfolio")
                }
                .tag(2)

            SocialView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Social")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
        }
        .tint(theme.surface)
        .onChange(of: appState.backgroundTheme) { _, _ in
            updateTabBarAppearance()
        }
        .onAppear {
            updateTabBarAppearance()
        }
    }

    private func updateTabBarAppearance() {
        let tc = appState.backgroundTheme.colors
        let appearance = UITabBarAppearance()
        if tc.isLight {
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        } else {
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor(tc.deep.opacity(0.8))
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        }

        let normalColor = UIColor.secondaryLabel
        let selectedColor = UIColor(tc.surface)

        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
