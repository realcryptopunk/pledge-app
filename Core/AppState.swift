import SwiftUI

@MainActor
class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("backgroundTheme") var backgroundTheme: BackgroundTheme = .aqua
    @Published var isAuthenticated = true
    @Published var userName = "Nav"
    @Published var userPhone = "+1 (555) 123-4567"
    @Published var habits: [Habit] = Habit.mockHabits
    @Published var vaultBalance: Double = 247.00
    @Published var streakCount: Int = 23
    @Published var investmentPoolValue: Double = 261.38
    @Published var investmentGrowth: Double = 5.8
    @Published var todayHabits: [TodayHabit] = TodayHabit.mockToday
    @Published var recentActivity: [ActivityItem] = ActivityItem.mockActivity

    var todayStakeTotal: Double {
        todayHabits.reduce(0) { $0 + $1.habit.stakeAmount }
    }

    var todayVerifiedCount: Int {
        todayHabits.filter { $0.status == .verified }.count
    }

    var todayChangePercent: Double {
        investmentGrowth
    }

    func addHabit(_ habit: Habit) {
        habits.append(habit)
    }

    func signOut() {
        hasCompletedOnboarding = false
        isAuthenticated = false
    }
}

// MARK: - BackgroundTheme @AppStorage Conformance

extension BackgroundTheme: RawRepresentable {
    // Already String-based via enum declaration, but we need explicit conformance for @AppStorage
}
