import SwiftUI

@MainActor
class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("backgroundTheme") var backgroundTheme: BackgroundTheme = .aqua
    @Published var isAuthenticated = true
    @Published var userName = "Nav"
    @Published var userPhone = "+1 (555) 123-4567"
    @Published var habits: [Habit] = []
    @Published var vaultBalance: Double = 247.00
    @Published var streakCount: Int = 0
    @Published var investmentPoolValue: Double = 261.38
    @Published var investmentGrowth: Double = 5.8
    @Published var todayHabits: [TodayHabit] = []
    @Published var recentActivity: [ActivityItem] = []

    // MARK: - Computed Properties

    var todayStakeTotal: Double {
        todayHabits.reduce(0) { $0 + $1.habit.stakeAmount }
    }

    var todayVerifiedCount: Int {
        todayHabits.filter { $0.status == .verified }.count
    }

    var todayChangePercent: Double {
        investmentGrowth
    }

    // MARK: - Init

    init() {
        loadHabits()
        generateTodayHabits()
        updateStreakCount()
    }

    // MARK: - Habit CRUD

    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
        generateTodayHabits()
        updateStreakCount()
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        todayHabits.removeAll { $0.habit.id == habit.id }
        saveHabits()
        updateStreakCount()
    }

    func deleteHabit(at offsets: IndexSet) {
        let habitsToDelete = offsets.map { habits[$0] }
        for habit in habitsToDelete {
            todayHabits.removeAll { $0.habit.id == habit.id }
        }
        habits.remove(atOffsets: offsets)
        saveHabits()
        updateStreakCount()
    }

    // MARK: - Verification

    func verifyHabit(_ todayHabitId: UUID) {
        guard let index = todayHabits.firstIndex(where: { $0.id == todayHabitId }) else { return }
        todayHabits[index].status = .verified
        todayHabits[index].verifiedAt = Date()
        todayHabits[index].detail = "Verified \(timeString(from: Date()))"
    }

    // MARK: - Today Habits Generation

    func generateTodayHabits() {
        let todayWeekday = currentWeekday()
        let activeHabits = habits.filter { $0.isActive && $0.schedule.contains(todayWeekday) }

        // Preserve existing verified/failed states for habits already in todayHabits
        var updatedTodayHabits: [TodayHabit] = []
        for habit in activeHabits {
            if let existing = todayHabits.first(where: { $0.habit.id == habit.id }) {
                updatedTodayHabits.append(existing)
            } else {
                let todayHabit = TodayHabit(
                    id: UUID(),
                    habit: habit,
                    status: .pending,
                    detail: detailString(for: habit),
                    verifiedAt: nil,
                    progress: nil
                )
                updatedTodayHabits.append(todayHabit)
            }
        }
        todayHabits = updatedTodayHabits
    }

    // MARK: - Streak

    private func updateStreakCount() {
        if habits.isEmpty {
            streakCount = 0
        } else {
            // Use the longest current streak among active habits
            streakCount = habits.filter { $0.isActive }.map { $0.currentStreak }.max() ?? 0
        }
    }

    // MARK: - Persistence

    private static let savedHabitsKey = "savedHabits"

    private func saveHabits() {
        guard let data = try? JSONEncoder().encode(habits) else { return }
        UserDefaults.standard.set(data, forKey: Self.savedHabitsKey)
    }

    private func loadHabits() {
        guard let data = UserDefaults.standard.data(forKey: Self.savedHabitsKey),
              let decoded = try? JSONDecoder().decode([Habit].self, from: data) else {
            habits = []
            return
        }
        habits = decoded
    }

    // MARK: - Helpers

    private func currentWeekday() -> Int {
        // Calendar weekday: 1=Sun, 2=Mon ... 7=Sat
        // Our model: 1=Mon ... 7=Sun
        let calendarWeekday = Calendar.current.component(.weekday, from: Date())
        // Convert: Sun(1)->7, Mon(2)->1, Tue(3)->2, ... Sat(7)->6
        return calendarWeekday == 1 ? 7 : calendarWeekday - 1
    }

    private func detailString(for habit: Habit) -> String {
        switch habit.type {
        case .wakeUp:
            let hour = Int(habit.targetValue)
            let minute = Int((habit.targetValue - Double(hour)) * 60)
            return "Wake by \(hour):\(String(format: "%02d", minute)) AM"
        case .workout:
            return "\(Int(habit.targetValue)) min goal"
        case .steps:
            return "\(Int(habit.targetValue)) step goal"
        case .screenTime:
            return "Max \(Int(habit.targetValue))h screen time"
        case .sleep:
            return "\(Int(habit.targetValue))h sleep goal"
        case .water:
            return "\(Int(habit.targetValue)) glasses"
        case .meditate:
            return "\(Int(habit.targetValue)) min meditation"
        case .read:
            return "\(Int(habit.targetValue)) min reading"
        default:
            return "Closes 11:59 PM"
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    // MARK: - Auth

    func signOut() {
        hasCompletedOnboarding = false
        isAuthenticated = false
    }
}

// MARK: - BackgroundTheme @AppStorage Conformance

extension BackgroundTheme: RawRepresentable {
    // Already String-based via enum declaration, but we need explicit conformance for @AppStorage
}
