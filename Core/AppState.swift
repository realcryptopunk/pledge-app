import SwiftUI
import Combine
import Supabase

@MainActor
class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("hasCompletedSetup") var hasCompletedSetup = false
    @AppStorage("backgroundTheme") var backgroundTheme: BackgroundTheme = .aqua
    @AppStorage("userName") var userName = ""
    @AppStorage("walletAddress") var walletAddress: String = ""
    @AppStorage("riskProfile") var riskProfile: RiskProfile = .moderate
    @Published var isAuthenticated = false
    @Published var userPhone: String = ""
    @Published var habits: [Habit] = []
    @Published var vaultBalance: Double = 0
    @Published var streakCount: Int = 0
    @Published var investmentPoolValue: Double = 0
    @Published var investmentGrowth: Double = 0
    @Published var todayHabits: [TodayHabit] = []
    @Published var recentActivity: [ActivityItem] = []
    @Published var isVerifying = false
    @Published var needsUsername = false

    // Per-stock positions (symbol -> USDC value invested)
    @Published var stockPositions: [String: Double] = [:]
    // Transaction history for portfolio
    @Published var investmentTransactions: [InvestmentTransaction] = []
    // Toast message shown after a habit miss invests into stocks
    @Published var investmentToast: String?

    // MARK: - Auth

    let authService = AuthService()
    let privyManager = PrivyManager.shared
    private var authCancellable: AnyCancellable?
    private var privyAuthCancellable: AnyCancellable?
    private var privyWalletCancellable: AnyCancellable?

    // MARK: - Supabase

    /// Authenticated Supabase client, created after auth bridge returns a JWT.
    /// Use this for all RLS-protected database operations.
    @Published var supabaseClient: SupabaseClient?

    /// The Supabase user profile UUID (maps to user_profiles.id and auth.uid() in RLS).
    @Published var supabaseUserId: String?

    private var supabaseTokenCancellable: AnyCancellable?
    private var supabaseUserIdCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Supabase Service

    /// Cloud persistence service, created when both supabaseClient and supabaseUserId are available.
    /// Nil for guest mode — falls back to UserDefaults.
    private var supabaseService: SupabaseService?

    // MARK: - Supabase Realtime

    /// Realtime channel for listening to habits table changes.
    private var habitsChannel: RealtimeChannelV2?

    /// Subscription handle for postgres changes callback on habits channel.
    private var habitsChangeSubscription: RealtimeSubscription?

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

        // Initialize Privy SDK
        privyManager.initialize()

        // Drive isAuthenticated from PrivyManager (replacing authService)
        privyAuthCancellable = privyManager.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isAuthenticated = value
            }

        // Sync wallet address from PrivyManager to persisted @AppStorage
        privyWalletCancellable = privyManager.$walletAddress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.walletAddress = value ?? ""
            }

        // Keep authService subscription for backward compatibility (not driving routing)
        authCancellable = authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { _ in }

        // Create authenticated Supabase client when token arrives from auth bridge
        privyManager.$supabaseAccessToken
            .receive(on: DispatchQueue.main)
            .sink { [weak self] token in
                guard let self else { return }
                if let token {
                    self.supabaseClient = SupabaseConfig.authenticatedClient {
                        return token
                    }
                    print("[AppState] Authenticated Supabase client created")
                } else {
                    self.supabaseClient = nil
                    self.supabaseService = nil
                }
            }
            .store(in: &cancellables)

        // Propagate Supabase user ID for use in queries
        privyManager.$supabaseUserId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userId in
                self?.supabaseUserId = userId
            }
            .store(in: &cancellables)

        // Create SupabaseService, load data, and start Realtime when both client and userId are available
        $supabaseClient
            .combineLatest($supabaseUserId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] client, userId in
                guard let self else { return }
                if let client, let userId {
                    do {
                        self.supabaseService = try SupabaseService(client: client, userId: userId)
                        print("[AppState] SupabaseService created, loading data from cloud")
                        Task {
                            await self.loadFromSupabase()
                            self.setupRealtimeSubscriptions()
                        }
                    } catch {
                        print("[AppState] Failed to create SupabaseService: \(error)")
                        self.supabaseService = nil
                    }
                } else {
                    self.supabaseService = nil
                    self.teardownRealtimeSubscriptions()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Habit CRUD

    func addHabit(_ habit: Habit) {
        habits.append(habit)
        generateTodayHabits()
        updateStreakCount()
        // Start geofence monitoring if this is a location-verified habit
        if habit.verificationType == .location && habit.hasLocation {
            startGeofenceForHabit(habit)
        }
        // Persist: cloud if authenticated, local otherwise
        if let service = supabaseService {
            Task { try? await service.createHabit(habit) }
        } else {
            saveHabitsLocally()
        }
    }

    func updateHabit(_ updated: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == updated.id }) else { return }
        habits[index] = updated
        generateTodayHabits()
        updateStreakCount()
        if let service = supabaseService {
            Task { try? await service.updateHabit(updated) }
        } else {
            saveHabitsLocally()
        }
    }

    func togglePauseHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].isPaused.toggle()
        generateTodayHabits()
        updateStreakCount()
        let updatedHabit = habits[index]
        if let service = supabaseService {
            Task { try? await service.updateHabit(updatedHabit) }
        } else {
            saveHabitsLocally()
        }
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        todayHabits.removeAll { $0.habit.id == habit.id }
        updateStreakCount()
        if let service = supabaseService {
            Task { try? await service.deleteHabit(habit.id) }
        } else {
            saveHabitsLocally()
        }
    }

    func deleteHabit(at offsets: IndexSet) {
        let habitsToDelete = offsets.map { habits[$0] }
        for habit in habitsToDelete {
            todayHabits.removeAll { $0.habit.id == habit.id }
        }
        habits.remove(atOffsets: offsets)
        updateStreakCount()
        if let service = supabaseService {
            for habit in habitsToDelete {
                Task { try? await service.deleteHabit(habit.id) }
            }
        } else {
            saveHabitsLocally()
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
            let stakeAmount = min(todayHabits[index].habit.stakeAmount, vaultBalance)
            if stakeAmount > 0 {
                investmentPoolValue += stakeAmount
                vaultBalance -= stakeAmount
                allocateStakeToStocks(stakeAmount: stakeAmount, habitName: todayHabits[index].habit.name)
            }
            if let habitIndex = habits.firstIndex(where: { $0.id == habitId }) {
                habits[habitIndex].currentStreak = 0
            }
            let investAmount = stakeAmount * 0.98
            let topStock = riskProfile.allocations.max(by: { $0.percentage < $1.percentage })?.symbol ?? "stocks"
            let activity = ActivityItem(
                icon: "📈",
                title: "$\(Int(investAmount)) \u{2192} \(topStock) & more",
                detail: "From missed \(todayHabits[index].habit.name)",
                isFailure: true
            )
            recentActivity.insert(activity, at: 0)
        }

        // Record habit log and sync updates to Supabase
        recordHabitLog(for: todayHabits[index], status: result.status)
        syncHabitAfterVerification(habitId: habitId, status: result.status)

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
                let stakeAmount = min(todayHabits[index].habit.stakeAmount, vaultBalance)
                if stakeAmount > 0 {
                    investmentPoolValue += stakeAmount
                    vaultBalance -= stakeAmount
                    allocateStakeToStocks(stakeAmount: stakeAmount, habitName: todayHabits[index].habit.name)
                }
                // Reset streak
                if let habitIndex = habits.firstIndex(where: { $0.id == habitId }) {
                    habits[habitIndex].currentStreak = 0
                }
                // Create activity item
                let investAmount = stakeAmount * 0.98
                let topStock = riskProfile.allocations.max(by: { $0.percentage < $1.percentage })?.symbol ?? "stocks"
                let activity = ActivityItem(
                    icon: "📈",
                    title: "$\(Int(investAmount)) \u{2192} \(topStock) & more",
                    detail: "From missed \(todayHabits[index].habit.name)",
                    isFailure: true
                )
                recentActivity.insert(activity, at: 0)
            }

            // Record habit log and sync updates to Supabase
            recordHabitLog(for: todayHabits[index], status: result.status)
            syncHabitAfterVerification(habitId: habitId, status: result.status)
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

        // Record habit log and sync to Supabase
        recordHabitLog(for: todayHabits[index], status: .verified)
        syncHabitAfterVerification(habitId: habitId, status: .verified)

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

    // MARK: - Habit Log Recording (Supabase)

    /// Records a habit log entry to Supabase after verification.
    private func recordHabitLog(for todayHabit: TodayHabit, status: HabitStatus) {
        guard let service = supabaseService else { return }
        let stakeAmount = todayHabit.habit.stakeAmount
        let isFailed = status == .failed

        let log = HabitLog(
            id: UUID(),
            habitId: todayHabit.habit.id,
            date: Date(),
            status: status,
            verifiedAt: status == .verified ? Date() : nil,
            penaltyAmount: isFailed ? stakeAmount : 0,
            investedAmount: isFailed ? stakeAmount * 0.98 : 0,
            feeAmount: isFailed ? stakeAmount * 0.02 : 0
        )
        Task {
            do {
                try await service.recordHabitLog(log)
                print("[AppState] Recorded habit log: \(status.rawValue) for \(todayHabit.habit.name)")
            } catch {
                print("[AppState] Failed to record habit log: \(error)")
            }
        }
    }

    /// Syncs habit streak/success_rate and user profile balances to Supabase after verification.
    private func syncHabitAfterVerification(habitId: UUID, status: HabitStatus) {
        guard let service = supabaseService else { return }

        // Sync updated habit (streak, success_rate)
        if let habit = habits.first(where: { $0.id == habitId }) {
            Task { try? await service.updateHabit(habit) }
        }

        // Sync user profile balances on failure (stake moves from vault to investment pool)
        if status == .failed {
            Task {
                try? await service.updateUserProfile(
                    vaultBalance: vaultBalance,
                    investmentPoolBalance: investmentPoolValue
                )
            }
        }
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

    /// Save habits and state: prefers Supabase if authenticated, else UserDefaults.
    private func saveHabits() {
        if supabaseService != nil {
            // Cloud persistence handled by individual CRUD methods (local-first pattern)
            return
        }
        saveHabitsLocally()
    }

    /// Save habits to UserDefaults (guest mode / offline fallback).
    private func saveHabitsLocally() {
        guard let data = try? JSONEncoder().encode(habits) else { return }
        UserDefaults.standard.set(data, forKey: Self.savedHabitsKey)
    }

    /// Load habits from UserDefaults (guest mode / initial boot before auth).
    private func loadHabitsLocally() {
        guard let data = UserDefaults.standard.data(forKey: Self.savedHabitsKey),
              let decoded = try? JSONDecoder().decode([Habit].self, from: data) else {
            habits = []
            return
        }
        habits = decoded
    }

    /// Load habits and profile from Supabase (authenticated users).
    func loadFromSupabase() async {
        guard let service = supabaseService else {
            loadHabitsLocally()
            return
        }
        do {
            let cloudHabits = try await service.fetchHabits()
            habits = cloudHabits

            let profile = try await service.fetchUserProfile()
            vaultBalance = profile.vaultBalance
            investmentPoolValue = profile.investmentPoolBalance
            // Sync risk profile from server if it differs
            if let serverProfile = RiskProfile(rawValue: profile.riskProfile) {
                riskProfile = serverProfile
            }
            // Sync username if available, or flag that username is needed
            if let serverUsername = profile.username, !serverUsername.isEmpty {
                userName = serverUsername
                needsUsername = false
            } else {
                needsUsername = true
            }

            generateTodayHabits()
            updateStreakCount()
            setupGeofenceMonitoring()
            print("[AppState] Loaded \(habits.count) habits from Supabase")
        } catch {
            print("[AppState] Supabase load failed, falling back to local: \(error)")
            loadHabitsLocally()
            generateTodayHabits()
            updateStreakCount()
        }
    }

    /// Initial load: use local data first, cloud data will overwrite when auth completes.
    private func loadHabits() {
        loadHabitsLocally()
        loadStockData()
    }

    // MARK: - Realtime Subscriptions

    /// Sets up Supabase Realtime subscriptions for the habits table.
    /// Any INSERT, UPDATE, or DELETE on the habits table triggers a full reload.
    /// Must be called after supabaseClient is available (i.e., after SupabaseService creation).
    func setupRealtimeSubscriptions() {
        guard let client = supabaseClient else { return }

        // Tear down any existing subscription before creating a new one
        teardownRealtimeSubscriptions()

        let channel = client.realtimeV2.channel("habits-changes")

        // Register postgres change listener BEFORE subscribing (SDK requirement)
        habitsChangeSubscription = channel.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "habits"
        ) { [weak self] _ in
            // Any change to habits table -> reload all habits from Supabase
            Task { @MainActor [weak self] in
                await self?.handleRealtimeHabitChange()
            }
        }

        // Subscribe to the channel asynchronously
        Task {
            do {
                try await channel.subscribeWithError()
                print("[AppState] Realtime subscribed to habits-changes channel")
            } catch {
                print("[AppState] Realtime subscription failed: \(error)")
            }
        }

        habitsChannel = channel
    }

    /// Handles a Realtime change event on the habits table by reloading all habits.
    private func handleRealtimeHabitChange() async {
        guard let service = supabaseService else { return }
        do {
            let updatedHabits = try await service.fetchHabits()
            self.habits = updatedHabits
            self.generateTodayHabits()
            self.updateStreakCount()
            self.setupGeofenceMonitoring()
            print("[AppState] Realtime: reloaded \(updatedHabits.count) habits")
        } catch {
            print("[AppState] Realtime habit refresh failed: \(error)")
        }
    }

    /// Unsubscribes from Realtime channels and cleans up subscriptions.
    func teardownRealtimeSubscriptions() {
        habitsChangeSubscription?.cancel()
        habitsChangeSubscription = nil

        if let channel = habitsChannel {
            Task {
                await channel.unsubscribe()
                print("[AppState] Realtime unsubscribed from habits-changes channel")
            }
            habitsChannel = nil
        }
    }

    // MARK: - Stock Allocation on Miss

    /// Allocates a missed habit's stake across stocks based on risk profile,
    /// records the transaction, and shows a toast.
    private func allocateStakeToStocks(stakeAmount: Double, habitName: String) {
        let fee = stakeAmount * 0.02
        let investAmount = stakeAmount * 0.98
        let allocs = riskProfile.allocations

        var purchases: [InvestmentTransaction.StockPurchase] = []
        for alloc in allocs {
            let stockAmount = investAmount * alloc.percentage
            stockPositions[alloc.symbol, default: 0] += stockAmount
            purchases.append(InvestmentTransaction.StockPurchase(
                symbol: alloc.symbol,
                name: alloc.name,
                amount: stockAmount,
                percentage: alloc.percentage
            ))
        }

        // Generate mock tx hash (64 hex chars)
        let txHash = "0x" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(32)

        let tx = InvestmentTransaction(
            id: UUID(),
            date: Date(),
            habitName: habitName,
            totalAmount: stakeAmount,
            feeAmount: fee,
            investedAmount: investAmount,
            allocations: purchases,
            txHash: String(txHash.prefix(66))
        )
        investmentTransactions.insert(tx, at: 0)

        // Show toast
        let topStocks = purchases.sorted { $0.amount > $1.amount }.prefix(2).map { $0.symbol }
        investmentToast = "$\(Int(investAmount)) invested into \(topStocks.joined(separator: ", ")) & more on Robinhood Chain"

        // Auto-dismiss toast after 4 seconds
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            await MainActor.run {
                self.investmentToast = nil
            }
        }

        saveStockData()
    }

    // MARK: - Stock Data Persistence

    private static let stockPositionsKey = "savedStockPositions"
    private static let investmentTransactionsKey = "savedInvestmentTransactions"

    private func saveStockData() {
        if let posData = try? JSONEncoder().encode(stockPositions) {
            UserDefaults.standard.set(posData, forKey: Self.stockPositionsKey)
        }
        if let txData = try? JSONEncoder().encode(investmentTransactions) {
            UserDefaults.standard.set(txData, forKey: Self.investmentTransactionsKey)
        }
    }

    private func loadStockData() {
        if let posData = UserDefaults.standard.data(forKey: Self.stockPositionsKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: posData) {
            stockPositions = decoded
        }
        if let txData = UserDefaults.standard.data(forKey: Self.investmentTransactionsKey),
           let decoded = try? JSONDecoder().decode([InvestmentTransaction].self, from: txData) {
            investmentTransactions = decoded
        }
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
        case .pushups, .pullUps, .jumpingJacks:
            return "\(Int(habit.targetValue)) rep goal"
        case .steps:
            return "\(Int(habit.targetValue)) step goal"
        case .screenTime:
            return "Max \(Int(habit.targetValue))h screen time"
        case .sleep:
            return "\(Int(habit.targetValue))h sleep goal"
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

    // MARK: - Username & Profile

    /// Complete the username setup flow. Persists to Supabase and updates local state.
    func completeUsernameSetup(username: String, displayName: String?) async throws {
        guard let service = supabaseService else { return }
        try await service.setUsername(username, displayName: displayName)
        userName = username
        needsUsername = false
    }

    /// Check if a username is available via Supabase.
    func checkUsernameAvailable(_ username: String) async throws -> Bool {
        guard let service = supabaseService else { return false }
        return try await service.checkUsernameAvailable(username)
    }

    /// Update user profile (username, display name, avatar).
    func updateProfile(username: String?, displayName: String?, avatarUrl: String? = nil) async throws {
        guard let service = supabaseService else { return }
        try await service.updateProfile(username: username, displayName: displayName, avatarUrl: avatarUrl)
        if let username { userName = username }
    }

    /// Get the current Supabase service for direct use by views (e.g., friend search, leaderboard).
    var currentSupabaseService: SupabaseService? {
        supabaseService
    }

    // MARK: - Auth

    func signOut() async {
        // Tear down Realtime subscriptions before clearing state
        teardownRealtimeSubscriptions()
        await privyManager.signOut()
        await authService.signOut()
        // Clear persisted data
        UserDefaults.standard.removeObject(forKey: Self.savedHabitsKey)
        UserDefaults.standard.removeObject(forKey: Self.stockPositionsKey)
        UserDefaults.standard.removeObject(forKey: Self.investmentTransactionsKey)
        // Reset runtime state
        habits = []
        todayHabits = []
        recentActivity = []
        vaultBalance = 0
        investmentPoolValue = 0
        investmentGrowth = 0
        streakCount = 0
        stockPositions = [:]
        investmentTransactions = []
        investmentToast = nil
        userName = ""
        walletAddress = ""
        userPhone = ""
        needsUsername = false
        supabaseService = nil
        supabaseClient = nil
        supabaseUserId = nil
        // Reset flow state (triggers navigation back to sign-in)
        hasCompletedOnboarding = false
        hasCompletedSetup = false
    }
}

// MARK: - BackgroundTheme @AppStorage Conformance

extension BackgroundTheme: RawRepresentable {
    // Already String-based via enum declaration, but we need explicit conformance for @AppStorage
}

// MARK: - RiskProfile @AppStorage Conformance

extension RiskProfile: RawRepresentable {
    // Already String-based via enum declaration, but we need explicit conformance for @AppStorage
}
