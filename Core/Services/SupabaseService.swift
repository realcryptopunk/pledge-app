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

    // MARK: - Username & Profile

    /// Check if a username is available (not taken by another user).
    func checkUsernameAvailable(_ username: String) async throws -> Bool {
        let profiles: [UserProfileDTO] = try await client.from("user_profiles")
            .select("id")
            .eq("username", value: username)
            .limit(1)
            .execute()
            .value
        // Available if no other user has it, or the only match is the current user
        if let match = profiles.first {
            return match.id == userId
        }
        return true
    }

    /// Set the username (and optional display name) for the current user.
    func setUsername(_ username: String, displayName: String?) async throws {
        var dto = UserProfileUpdateDTO()
        dto.username = username
        dto.displayName = displayName
        try await client.from("user_profiles")
            .update(dto)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    /// Update profile fields. Only non-nil values are sent.
    func updateProfile(username: String?, displayName: String?, avatarUrl: String?) async throws {
        // Build a minimal update with only the fields being changed
        var updates: [String: String] = [:]
        if let username { updates["username"] = username }
        if let displayName { updates["display_name"] = displayName }
        if let avatarUrl { updates["avatar_url"] = avatarUrl }
        guard !updates.isEmpty else { return }
        try await client.from("user_profiles")
            .update(updates)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Friends

    /// Search user profiles by username prefix (for adding friends).
    func searchUsers(prefix: String) async throws -> [UserProfileDTO] {
        let profiles: [UserProfileDTO] = try await client.from("user_profiles")
            .select()
            .ilike("username", pattern: "\(prefix)%")
            .neq("id", value: userId.uuidString)
            .limit(10)
            .execute()
            .value
        return profiles
    }

    /// Fetch accepted friendships for the current user.
    func fetchFriends() async throws -> [FriendshipDTO] {
        let friendships: [FriendshipDTO] = try await client.from("friendships")
            .select("*, friend:friend_id(id, username, display_name, avatar_url), user:user_id(id, username, display_name, avatar_url)")
            .or("user_id.eq.\(userId.uuidString),friend_id.eq.\(userId.uuidString)")
            .execute()
            .value
        return friendships
    }

    /// Send a friend request to another user.
    func sendFriendRequest(to friendId: UUID) async throws {
        let dto = FriendshipInsertDTO(userId: userId, friendId: friendId)
        try await client.from("friendships")
            .insert(dto)
            .execute()
    }

    /// Accept a pending friend request.
    func acceptFriendRequest(_ friendshipId: UUID) async throws {
        try await client.from("friendships")
            .update(["status": "accepted"])
            .eq("id", value: friendshipId.uuidString)
            .execute()
    }

    /// Decline a pending friend request (deletes the row).
    func declineFriendRequest(_ friendshipId: UUID) async throws {
        try await client.from("friendships")
            .delete()
            .eq("id", value: friendshipId.uuidString)
            .execute()
    }

    // MARK: - Leaderboard

    /// Fetch leaderboard data from the edge function.
    func fetchLeaderboard(type: String, limit: Int = 50, period: Int = 30) async throws -> [LeaderboardEntry] {
        let url = SupabaseConfig.url
            .appendingPathComponent("functions/v1/leaderboard")

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "period", value: String(period)),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SupabaseServiceError.leaderboardFetchFailed
        }

        let decoded = try JSONDecoder().decode(LeaderboardResponse.self, from: data)
        return decoded.entries
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

// MARK: - Leaderboard Models

struct LeaderboardEntry: Codable, Identifiable {
    let rank: Int
    let userId: UUID
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let value: Double
    let label: String

    var id: UUID { userId }

    enum CodingKeys: String, CodingKey {
        case rank, username, value, label
        case userId = "user_id"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

struct LeaderboardResponse: Codable {
    let type: String
    let entries: [LeaderboardEntry]
}

// MARK: - Friendship DTOs

struct FriendshipDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let friendId: UUID
    let status: String
    let createdAt: String?
    let friend: FriendProfileDTO?
    let user: FriendProfileDTO?

    enum CodingKeys: String, CodingKey {
        case id, status, friend, user
        case userId = "user_id"
        case friendId = "friend_id"
        case createdAt = "created_at"
    }
}

struct FriendProfileDTO: Codable {
    let id: UUID
    let username: String?
    let displayName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

struct FriendshipInsertDTO: Codable {
    let userId: UUID
    let friendId: UUID
    let status: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case friendId = "friend_id"
        case status
    }

    init(userId: UUID, friendId: UUID) {
        self.userId = userId
        self.friendId = friendId
        self.status = "pending"
    }
}

// MARK: - Errors

enum SupabaseServiceError: LocalizedError {
    case invalidUserId(String)
    case profileNotFound
    case leaderboardFetchFailed

    var errorDescription: String? {
        switch self {
        case .invalidUserId(let id):
            return "Invalid Supabase user ID: \(id)"
        case .profileNotFound:
            return "User profile not found in Supabase"
        case .leaderboardFetchFailed:
            return "Failed to fetch leaderboard data"
        }
    }
}
