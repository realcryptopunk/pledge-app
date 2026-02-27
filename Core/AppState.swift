import SwiftUI

@MainActor
class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @Published var isAuthenticated = false
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
}
