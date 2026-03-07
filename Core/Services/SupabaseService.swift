import Foundation
import Supabase

// MARK: - DTOs (Database Transfer Objects)

/// Maps to the `habits` Postgres table. Handles snake_case ↔ camelCase conversion.
struct HabitDTO: Codable {
    let id: UUID
    let userId: UUID
    var name: String
    var icon: String
    var type: String
    var stakeAmount: Double
    var schedule: [Int]
    var targetValue: Double
    var verificationType: String
    var isActive: Bool
    var isPaused: Bool
    var currentStreak: Int
    var bestStreak: Int
    var successRate: Double
    var locationLatitude: Double?
    var locationLongitude: Double?
    var locationRadius: Double?
    var locationName: String?
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, icon, type, schedule
        case userId = "user_id"
        case stakeAmount = "stake_amount"
        case targetValue = "target_value"
        case verificationType = "verification_type"
        case isActive = "is_active"
        case isPaused = "is_paused"
        case currentStreak = "current_streak"
        case bestStreak = "best_streak"
        case successRate = "success_rate"
        case locationLatitude = "location_latitude"
        case locationLongitude = "location_longitude"
        case locationRadius = "location_radius"
        case locationName = "location_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Conversion

    /// Convert domain Habit to DTO for Supabase insert/update.
    init(from habit: Habit, userId: UUID) {
        self.id = habit.id
        self.userId = userId
        self.name = habit.name
        self.icon = habit.icon
        self.type = habit.type.rawValue
        self.stakeAmount = habit.stakeAmount
        self.schedule = habit.schedule
        self.targetValue = habit.targetValue
        self.verificationType = habit.verificationType.rawValue
        self.isActive = habit.isActive
        self.isPaused = habit.isPaused
        self.currentStreak = habit.currentStreak
        self.bestStreak = max(habit.currentStreak, 0) // track best streak
        self.successRate = habit.successRate
        self.locationLatitude = habit.locationLatitude
        self.locationLongitude = habit.locationLongitude
        self.locationRadius = habit.locationRadius
        self.locationName = habit.locationName
        self.createdAt = nil
        self.updatedAt = nil
    }

    /// Convert DTO back to domain Habit model.
    func toHabit() -> Habit {
        Habit(
            id: id,
            name: name,
            icon: icon,
            type: HabitType(rawValue: type) ?? .workout,
            stakeAmount: stakeAmount,
            schedule: schedule,
            targetValue: targetValue,
            verificationType: VerificationType(rawValue: verificationType) ?? .auto,
            isActive: isActive,
            isPaused: isPaused,
            currentStreak: currentStreak,
            successRate: successRate,
            locationLatitude: locationLatitude,
            locationLongitude: locationLongitude,
            locationRadius: locationRadius,
            locationName: locationName
        )
    }
}

/// DTO for inserting habits — excludes server-managed fields (created_at, updated_at).
struct HabitInsertDTO: Codable {
    let id: UUID
    let userId: UUID
    var name: String
    var icon: String
    var type: String
    var stakeAmount: Double
    var schedule: [Int]
    var targetValue: Double
    var verificationType: String
    var isActive: Bool
    var isPaused: Bool
    var currentStreak: Int
    var bestStreak: Int
    var successRate: Double
    var locationLatitude: Double?
    var locationLongitude: Double?
    var locationRadius: Double?
    var locationName: String?

    enum CodingKeys: String, CodingKey {
        case id, name, icon, type, schedule
        case userId = "user_id"
        case stakeAmount = "stake_amount"
        case targetValue = "target_value"
        case verificationType = "verification_type"
        case isActive = "is_active"
        case isPaused = "is_paused"
        case currentStreak = "current_streak"
        case bestStreak = "best_streak"
        case successRate = "success_rate"
        case locationLatitude = "location_latitude"
        case locationLongitude = "location_longitude"
        case locationRadius = "location_radius"
        case locationName = "location_name"
    }

    init(from habit: Habit, userId: UUID) {
        self.id = habit.id
        self.userId = userId
        self.name = habit.name
        self.icon = habit.icon
        self.type = habit.type.rawValue
        self.stakeAmount = habit.stakeAmount
        self.schedule = habit.schedule
        self.targetValue = habit.targetValue
        self.verificationType = habit.verificationType.rawValue
        self.isActive = habit.isActive
        self.isPaused = habit.isPaused
        self.currentStreak = habit.currentStreak
        self.bestStreak = max(habit.currentStreak, 0)
        self.successRate = habit.successRate
        self.locationLatitude = habit.locationLatitude
        self.locationLongitude = habit.locationLongitude
        self.locationRadius = habit.locationRadius
        self.locationName = habit.locationName
    }
}

/// DTO for updating habit fields — only mutable fields, no id/userId/timestamps.
struct HabitUpdateDTO: Codable {
    var name: String
    var icon: String
    var type: String
    var stakeAmount: Double
    var schedule: [Int]
    var targetValue: Double
    var verificationType: String
    var isActive: Bool
    var isPaused: Bool
    var currentStreak: Int
    var bestStreak: Int
    var successRate: Double
    var locationLatitude: Double?
    var locationLongitude: Double?
    var locationRadius: Double?
    var locationName: String?

    enum CodingKeys: String, CodingKey {
        case name, icon, type, schedule
        case stakeAmount = "stake_amount"
        case targetValue = "target_value"
        case verificationType = "verification_type"
        case isActive = "is_active"
        case isPaused = "is_paused"
        case currentStreak = "current_streak"
        case bestStreak = "best_streak"
        case successRate = "success_rate"
        case locationLatitude = "location_latitude"
        case locationLongitude = "location_longitude"
        case locationRadius = "location_radius"
        case locationName = "location_name"
    }

    init(from habit: Habit) {
        self.name = habit.name
        self.icon = habit.icon
        self.type = habit.type.rawValue
        self.stakeAmount = habit.stakeAmount
        self.schedule = habit.schedule
        self.targetValue = habit.targetValue
        self.verificationType = habit.verificationType.rawValue
        self.isActive = habit.isActive
        self.isPaused = habit.isPaused
        self.currentStreak = habit.currentStreak
        self.bestStreak = max(habit.currentStreak, 0)
        self.successRate = habit.successRate
        self.locationLatitude = habit.locationLatitude
        self.locationLongitude = habit.locationLongitude
        self.locationRadius = habit.locationRadius
        self.locationName = habit.locationName
    }
}

/// Maps to the `habit_logs` Postgres table.
struct HabitLogDTO: Codable {
    let id: UUID
    let habitId: UUID
    let userId: UUID
    let logDate: String // "YYYY-MM-DD" format for Postgres DATE column
    var status: String
    var verifiedAt: String?
    var penaltyAmount: Double
    var investedAmount: Double
    var feeAmount: Double

    enum CodingKeys: String, CodingKey {
        case id, status
        case habitId = "habit_id"
        case userId = "user_id"
        case logDate = "log_date"
        case verifiedAt = "verified_at"
        case penaltyAmount = "penalty_amount"
        case investedAmount = "invested_amount"
        case feeAmount = "fee_amount"
    }

    /// Convert domain HabitLog to DTO for Supabase insert.
    init(from log: HabitLog, userId: UUID) {
        self.id = log.id
        self.habitId = log.habitId
        self.userId = userId
        self.logDate = Self.dateFormatter.string(from: log.date)
        self.status = log.status.rawValue
        if let verifiedAt = log.verifiedAt {
            self.verifiedAt = Self.isoFormatter.string(from: verifiedAt)
        } else {
            self.verifiedAt = nil
        }
        self.penaltyAmount = log.penaltyAmount
        self.investedAmount = log.investedAmount
        self.feeAmount = log.feeAmount
    }

    /// Convert DTO back to domain HabitLog model.
    func toHabitLog() -> HabitLog {
        let date = Self.dateFormatter.date(from: logDate) ?? Date()
        let verified = verifiedAt.flatMap { Self.isoFormatter.date(from: $0) }
        return HabitLog(
            id: id,
            habitId: habitId,
            date: date,
            status: HabitStatus(rawValue: status) ?? .pending,
            verifiedAt: verified,
            penaltyAmount: penaltyAmount,
            investedAmount: investedAmount,
            feeAmount: feeAmount
        )
    }

    // MARK: - Formatters

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

/// Maps to the `user_profiles` Postgres table (read-only fields included).
struct UserProfileDTO: Codable {
    let id: UUID
    let privyUserId: String
    var phone: String?
    var walletAddress: String?
    var username: String?
    var displayName: String?
    var avatarUrl: String?
    var riskProfile: String
    var vaultBalance: Double
    var investmentPoolBalance: Double
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, phone, username
        case privyUserId = "privy_user_id"
        case walletAddress = "wallet_address"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case riskProfile = "risk_profile"
        case vaultBalance = "vault_balance"
        case investmentPoolBalance = "investment_pool_balance"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// DTO for updating user profile fields.
struct UserProfileUpdateDTO: Codable {
    var riskProfile: String?
    var vaultBalance: Double?
    var investmentPoolBalance: Double?
    var username: String?
    var displayName: String?

    enum CodingKeys: String, CodingKey {
        case riskProfile = "risk_profile"
        case vaultBalance = "vault_balance"
        case investmentPoolBalance = "investment_pool_balance"
        case username
        case displayName = "display_name"
    }
}

// MARK: - SupabaseService

@MainActor
class SupabaseService {
    private let client: SupabaseClient
    private let userId: UUID

    init(client: SupabaseClient, userId: String) throws {
        self.client = client
        guard let uuid = UUID(uuidString: userId) else {
            throw SupabaseServiceError.invalidUserId(userId)
        }
        self.userId = uuid
    }

    // MARK: - Habits

    /// Fetch all habits for the authenticated user, ordered by creation date.
    func fetchHabits() async throws -> [Habit] {
        let dtos: [HabitDTO] = try await client.from("habits")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at")
            .execute()
            .value
        return dtos.map { $0.toHabit() }
    }

    /// Create a new habit in Supabase.
    func createHabit(_ habit: Habit) async throws {
        let dto = HabitInsertDTO(from: habit, userId: userId)
        try await client.from("habits")
            .insert(dto)
            .execute()
    }

    /// Update an existing habit in Supabase.
    func updateHabit(_ habit: Habit) async throws {
        let dto = HabitUpdateDTO(from: habit)
        try await client.from("habits")
            .update(dto)
            .eq("id", value: habit.id.uuidString)
            .execute()
    }

    /// Delete a habit from Supabase.
    func deleteHabit(_ habitId: UUID) async throws {
        try await client.from("habits")
            .delete()
            .eq("id", value: habitId.uuidString)
            .execute()
    }

    // MARK: - User Profile

    /// Fetch the authenticated user's profile.
    func fetchUserProfile() async throws -> UserProfileDTO {
        let profiles: [UserProfileDTO] = try await client.from("user_profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        guard let profile = profiles.first else {
            throw SupabaseServiceError.profileNotFound
        }
        return profile
    }

    /// Update user profile fields. Only non-nil values are sent.
    func updateUserProfile(
        riskProfile: String? = nil,
        vaultBalance: Double? = nil,
        investmentPoolBalance: Double? = nil,
        username: String? = nil,
        displayName: String? = nil
    ) async throws {
        let dto = UserProfileUpdateDTO(
            riskProfile: riskProfile,
            vaultBalance: vaultBalance,
            investmentPoolBalance: investmentPoolBalance,
            username: username,
            displayName: displayName
        )
        try await client.from("user_profiles")
            .update(dto)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Habit Logs

    /// Record a habit log entry in Supabase.
    func recordHabitLog(_ log: HabitLog) async throws {
        let dto = HabitLogDTO(from: log, userId: userId)
        try await client.from("habit_logs")
            .upsert(dto)
            .execute()
    }

    /// Fetch today's habit logs for the authenticated user.
    func fetchTodayLogs() async throws -> [HabitLog] {
        let today = todayDateString()
        let dtos: [HabitLogDTO] = try await client.from("habit_logs")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("log_date", value: today)
            .execute()
            .value
        return dtos.map { $0.toHabitLog() }
    }

    /// Fetch habit logs for a specific habit within a date range.
    func fetchLogsForHabit(_ habitId: UUID, days: Int = 30) async throws -> [HabitLog] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let startDateString = Self.dateFormatter.string(from: startDate)
        let dtos: [HabitLogDTO] = try await client.from("habit_logs")
            .select()
            .eq("habit_id", value: habitId.uuidString)
            .gte("log_date", value: startDateString)
            .order("log_date", ascending: false)
            .execute()
            .value
        return dtos.map { $0.toHabitLog() }
    }

    // MARK: - Helpers

    private func todayDateString() -> String {
        Self.dateFormatter.string(from: Date())
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f
    }()
}

// MARK: - Errors

enum SupabaseServiceError: LocalizedError {
    case invalidUserId(String)
    case profileNotFound

    var errorDescription: String? {
        switch self {
        case .invalidUserId(let id):
            return "Invalid Supabase user ID: \(id)"
        case .profileNotFound:
            return "User profile not found in Supabase"
        }
    }
}
