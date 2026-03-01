import SwiftUI

@MainActor
class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("hasCompletedSetup") var hasCompletedSetup = false
    @AppStorage("backgroundTheme") var backgroundTheme: BackgroundTheme = .aqua
    @AppStorage("userName") var userName = "Nav"
    @Published var isAuthenticated = true
    @Published var userPhone = "+1 (555) 123-4567"
    @Published var habits: [Habit] = []
    @Published var vaultBalance: Double = 247.00
    @Published var streakCount: Int = 0
    @Published var investmentPoolValue: Double = 261.38
    @Published var investmentGrowth: Double = 5.8
    @Published var todayHabits: [TodayHabit] = []
    @Published var recentActivity: [ActivityItem] = []
    @Published var isVerifying = false

    // MARK: - Yield

    private var yieldTimer: Timer?

    // MARK: - Services

    let verificationService = HabitVerificationService(
        healthKitManager: HealthKitManager.shared,
        locationManager: LocationManager.shared
    )

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
        setupGeofenceMonitoring()
        observeGeofenceNotifications()
        startYieldTimer()
    }

    // MARK: - Yield Timer

    private func startYieldTimer() {
        yieldTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.applyYieldTick()
            }
        }
    }

    private func applyYieldTick() {
        vaultBalance += 0.01
        investmentPoolValue += 0.01
    }

    // MARK: - Habit CRUD

    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
        generateTodayHabits()
        updateStreakCount()
        // Start geofence monitoring if this is a location-verified habit
        if habit.verificationType == .location && habit.hasLocation {
            startGeofenceForHabit(habit)
        }
    }

    func updateHabit(_ updated: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == updated.id }) else { return }
        habits[index] = updated
        saveHabits()
        generateTodayHabits()
        updateStreakCount()
    }

    func togglePauseHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].isPaused.toggle()
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

    // MARK: - Health Permissions

    func requestHealthPermissions() async {
        // Only request if any habits use HealthKit verification
        let hasHealthKitHabits = habits.contains { habit in
            habit.verificationType == .healthKit ||
            habit.type == .steps || habit.type == .sleep || habit.type == .workout || habit.type == .gym
        }
        guard hasHealthKitHabits else { return }

        do {
            try await HealthKitManager.shared.requestAuthorization()
        } catch {
            // Permission denied or unavailable — verification will gracefully handle this
            print("HealthKit authorization failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Geofence Monitoring

    /// Sets up geofence monitoring for all active location-verified habits.
    private func setupGeofenceMonitoring() {
        let locationHabits = habits.filter {
            $0.isActive && $0.verificationType == .location && $0.hasLocation
        }
        for habit in locationHabits {
            startGeofenceForHabit(habit)
        }
    }

    /// Starts geofence monitoring for a single habit.
    private func startGeofenceForHabit(_ habit: Habit) {
        guard let lat = habit.locationLatitude,
              let lon = habit.locationLongitude else { return }
        let radius = habit.locationRadius ?? 150
        let region = LocationManager.shared.makeRegion(
            identifier: habit.geofenceIdentifier,
            latitude: lat,
            longitude: lon,
            radius: radius
        )
        LocationManager.shared.startMonitoring(region: region)
    }

    /// Observes geofence entry/exit notifications from LocationManager.
    private func observeGeofenceNotifications() {
        NotificationCenter.default.addObserver(
            forName: .geofenceEntry,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let regionId = notification.userInfo?["regionIdentifier"] as? String else { return }
            Task { @MainActor [weak self] in
                self?.handleGeofenceNotification(regionIdentifier: regionId, entered: true)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .geofenceExit,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let regionId = notification.userInfo?["regionIdentifier"] as? String else { return }
            Task { @MainActor [weak self] in
                self?.handleGeofenceNotification(regionIdentifier: regionId, entered: false)
            }
        }
    }

    /// Processes a geofence event by delegating to the verification service and updating state.
    private func handleGeofenceNotification(regionIdentifier: String, entered: Bool) {
        guard let (habitId, result) = verificationService.handleGeofenceEvent(
            regionIdentifier: regionIdentifier,
            entered: entered,
            habits: habits
        ) else { return }

        guard let index = todayHabits.firstIndex(where: { $0.habit.id == habitId }) else { return }

        // Only update if still pending
        guard todayHabits[index].status == .pending else { return }

        todayHabits[index].status = result.status
        todayHabits[index].detail = result.detail

        if result.status == .verified {
            todayHabits[index].verifiedAt = Date()
            if let habitIndex = habits.firstIndex(where: { $0.id == habitId }) {
                habits[habitIndex].currentStreak += 1
            }
            let activity = ActivityItem(
                icon: "✅",
                title: "\(todayHabits[index].habit.name) verified",
                detail: "$\(Int(todayHabits[index].habit.stakeAmount)) saved",
                isFailure: false
            )
            recentActivity.insert(activity, at: 0)
        } else if result.status == .failed {
            let stakeAmount = todayHabits[index].habit.stakeAmount
            investmentPoolValue += stakeAmount
            if let habitIndex = habits.firstIndex(where: { $0.id == habitId }) {
                habits[habitIndex].currentStreak = 0
            }
            let activity = ActivityItem(
                icon: "📈",
                title: "Stake invested",
                detail: "$\(Int(stakeAmount)) from \(todayHabits[index].habit.name)",
                isFailure: true
            )
            recentActivity.insert(activity, at: 0)
        }

        updateStreakCount()
        saveHabits()
    }

    // MARK: - Auto Verification

    func verifyTodayHabits() async {
        guard !todayHabits.isEmpty else { return }

        isVerifying = true
        defer { isVerifying = false }

        // Only verify habits that are still pending
        let pendingHabits = todayHabits.filter { $0.status == .pending }.map { $0.habit }
        guard !pendingHabits.isEmpty else { return }

        let results = await verificationService.verifyAllHabits(pendingHabits, for: Date())

        for (habitId, result) in results {
            guard let index = todayHabits.firstIndex(where: { $0.habit.id == habitId }) else { continue }
            // Only update if the result is definitive (.verified or .failed)
            // Leave .pending results alone so the user can still manually verify
            guard result.status == .verified || result.status == .failed else {
                // Update detail text even for pending (e.g., "Health data unavailable")
                todayHabits[index].detail = result.detail
                continue
            }

            todayHabits[index].status = result.status
            todayHabits[index].detail = result.detail

            if result.status == .verified {
                todayHabits[index].verifiedAt = Date()
                // Update streak
                if let habitIndex = habits.firstIndex(where: { $0.id == habitId }) {
                    habits[habitIndex].currentStreak += 1
                }
                // Create activity item
                let activity = ActivityItem(
                    icon: "✅",
                    title: "\(todayHabits[index].habit.name) verified",
                    detail: "$\(Int(todayHabits[index].habit.stakeAmount)) saved",
                    isFailure: false
                )
                recentActivity.insert(activity, at: 0)
            } else if result.status == .failed {
                // Miss your habit, fund your future
                let stakeAmount = todayHabits[index].habit.stakeAmount
                investmentPoolValue += stakeAmount
                // Reset streak
                if let habitIndex = habits.firstIndex(where: { $0.id == habitId }) {
                    habits[habitIndex].currentStreak = 0
                }
                // Create activity item
                let activity = ActivityItem(
                    icon: "📈",
                    title: "Stake invested",
                    detail: "$\(Int(stakeAmount)) from \(todayHabits[index].habit.name)",
                    isFailure: true
                )
                recentActivity.insert(activity, at: 0)
            }
        }

        updateStreakCount()
        saveHabits()
    }

    // MARK: - Manual Verification

    func manuallyVerifyHabit(_ todayHabitId: UUID) {
        guard let index = todayHabits.firstIndex(where: { $0.id == todayHabitId }) else { return }
        todayHabits[index].status = .verified
        todayHabits[index].verifiedAt = Date()
        todayHabits[index].detail = "Verified \(timeString(from: Date()))"

        // Update streak
        let habitId = todayHabits[index].habit.id
        if let habitIndex = habits.firstIndex(where: { $0.id == habitId }) {
            habits[habitIndex].currentStreak += 1
        }

        // Create activity item
        let activity = ActivityItem(
            icon: "✅",
            title: "\(todayHabits[index].habit.name) verified",
            detail: "$\(Int(todayHabits[index].habit.stakeAmount)) saved",
            isFailure: false
        )
        recentActivity.insert(activity, at: 0)

        updateStreakCount()
        saveHabits()
    }

    // MARK: - Today Habits Generation

    func generateTodayHabits() {
        let todayWeekday = currentWeekday()
        let activeHabits = habits.filter { $0.isActive && !$0.isPaused && $0.schedule.contains(todayWeekday) }

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
        case .workout, .gym:
            return "\(Int(habit.targetValue)) min goal"
        case .pushups:
            return "\(Int(habit.targetValue)) rep goal"
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
        // Clear persisted data
        UserDefaults.standard.removeObject(forKey: Self.savedHabitsKey)
        // Reset runtime state
        habits = []
        todayHabits = []
        recentActivity = []
        vaultBalance = 0
        investmentPoolValue = 0
        investmentGrowth = 0
        streakCount = 0
        userName = "Nav"
        // Reset flow state (triggers navigation back to onboarding)
        hasCompletedOnboarding = false
        hasCompletedSetup = false
        isAuthenticated = false
    }
}

// MARK: - BackgroundTheme @AppStorage Conformance

extension BackgroundTheme: RawRepresentable {
    // Already String-based via enum declaration, but we need explicit conformance for @AppStorage
}
