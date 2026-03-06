import Foundation

// MARK: - Habit

struct Habit: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var type: HabitType
    var stakeAmount: Double
    var schedule: [Int] // 1=Mon, 7=Sun
    var targetValue: Double
    var verificationType: VerificationType
    var isActive: Bool
    var isPaused: Bool
    var currentStreak: Int
    var successRate: Double

    // MARK: - Location Fields (optional for backward compatibility)

    var locationLatitude: Double?
    var locationLongitude: Double?
    var locationRadius: Double?    // meters, default 150
    var locationName: String?      // "Planet Fitness", "Home", etc.

    // MARK: - Location Computed Properties

    var hasLocation: Bool {
        locationLatitude != nil && locationLongitude != nil
    }

    var geofenceIdentifier: String {
        "habit-\(id.uuidString)"
    }

    init(id: UUID = UUID(), name: String, icon: String, type: HabitType, stakeAmount: Double = 10, schedule: [Int] = [1,2,3,4,5,6,7], targetValue: Double = 0, verificationType: VerificationType = .auto, isActive: Bool = true, isPaused: Bool = false, currentStreak: Int = 0, successRate: Double = 0, locationLatitude: Double? = nil, locationLongitude: Double? = nil, locationRadius: Double? = nil, locationName: String? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.type = type
        self.stakeAmount = stakeAmount
        self.schedule = schedule
        self.targetValue = targetValue
        self.verificationType = verificationType
        self.isActive = isActive
        self.isPaused = isPaused
        self.currentStreak = currentStreak
        self.successRate = successRate
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.locationRadius = locationRadius
        self.locationName = locationName
    }

    // MARK: - Backward-compatible Codable

    enum CodingKeys: String, CodingKey {
        case id, name, icon, type, stakeAmount, schedule, targetValue
        case verificationType, isActive, isPaused, currentStreak, successRate
        case locationLatitude, locationLongitude, locationRadius, locationName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        type = try container.decode(HabitType.self, forKey: .type)
        stakeAmount = try container.decode(Double.self, forKey: .stakeAmount)
        schedule = try container.decode([Int].self, forKey: .schedule)
        targetValue = try container.decode(Double.self, forKey: .targetValue)
        verificationType = try container.decode(VerificationType.self, forKey: .verificationType)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        isPaused = try container.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        successRate = try container.decode(Double.self, forKey: .successRate)
        locationLatitude = try container.decodeIfPresent(Double.self, forKey: .locationLatitude)
        locationLongitude = try container.decodeIfPresent(Double.self, forKey: .locationLongitude)
        locationRadius = try container.decodeIfPresent(Double.self, forKey: .locationRadius)
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
    }
}

enum HabitType: String, Codable, CaseIterable {
    case wakeUp = "Wake Up Early"
    case workout = "Daily Workout"
    case gym = "Go to Gym"
    case pushups = "Pushups"
    case pullUps = "Pull-Ups"
    case jumpingJacks = "Jumping Jacks"
    case steps = "Step Goal"
    case screenTime = "Screen Time"
    case sleep = "Sleep On Time"
    case meditate = "Meditate"
    case read = "Read"
    case coldShower = "Cold Shower"
    case journal = "Journal"

    /// Habits that don't have auto-verification yet — shown as "Upcoming"
    var isUpcoming: Bool {
        return false
    }
}

enum VerificationType: String, Codable {
    case auto
    case healthKit
    case screenTimeAPI = "screenTime"
    case photo
    case location
    case vision
    case manual
    case inApp
}

// MARK: - Habit Log

struct HabitLog: Identifiable, Codable {
    let id: UUID
    let habitId: UUID
    let date: Date
    var status: HabitStatus
    var verifiedAt: Date?
    var penaltyAmount: Double
    var investedAmount: Double
    var feeAmount: Double
    
    init(id: UUID = UUID(), habitId: UUID, date: Date = Date(), status: HabitStatus, verifiedAt: Date? = nil, penaltyAmount: Double = 0, investedAmount: Double = 0, feeAmount: Double = 0) {
        self.id = id
        self.habitId = habitId
        self.date = date
        self.status = status
        self.verifiedAt = verifiedAt
        self.penaltyAmount = penaltyAmount
        self.investedAmount = investedAmount
        self.feeAmount = feeAmount
    }
}

enum HabitStatus: String, Codable {
    case verified
    case failed
    case skipped
    case pending
}

// MARK: - Today Habit (View Model)

struct TodayHabit: Identifiable, Codable {
    let id: UUID
    let habit: Habit
    var status: HabitStatus
    var detail: String
    var verifiedAt: Date?
    var progress: Double? // 0-1 for screen time etc
}

// MARK: - Activity Item

struct ActivityItem: Identifiable, Codable {
    let id: UUID
    let icon: String
    let title: String
    let detail: String
    let isFailure: Bool
    let date: Date
    
    init(id: UUID = UUID(), icon: String, title: String, detail: String, isFailure: Bool, date: Date = Date()) {
        self.id = id
        self.icon = icon
        self.title = title
        self.detail = detail
        self.isFailure = isFailure
        self.date = date
    }
}

// MARK: - Photo Verification Result

struct PhotoVerificationResult {
    let isVerified: Bool
    let confidence: Double  // 0-1
    let reason: String
}

// MARK: - Mock Data

extension Habit {
    static let mockHabits: [Habit] = [
        Habit(name: "Wake Up 6:00 AM", icon: "⏰", type: .wakeUp, stakeAmount: 10, schedule: [1,2,3,4,5,6,7], targetValue: 6, verificationType: .auto, currentStreak: 23, successRate: 0.87),
        Habit(name: "Gym Session (30+ min)", icon: "🏋️", type: .workout, stakeAmount: 10, schedule: [1,2,3,4,5], targetValue: 30, verificationType: .healthKit, currentStreak: 8, successRate: 0.72),
        Habit(name: "Screen Time < 3hrs", icon: "📵", type: .screenTime, stakeAmount: 25, schedule: [1,2,3,4,5,6,7], targetValue: 3, verificationType: .screenTimeAPI, currentStreak: 5, successRate: 0.65),
        Habit(name: "Sleep by 11:00 PM", icon: "😴", type: .sleep, stakeAmount: 10, schedule: [1,2,3,4,5,6,7], targetValue: 23, verificationType: .auto, currentStreak: 14, successRate: 0.80),
    ]
}

extension TodayHabit {
    static let mockToday: [TodayHabit] = [
        TodayHabit(id: UUID(), habit: Habit.mockHabits[0], status: .verified, detail: "Verified 5:47 AM", verifiedAt: Date()),
        TodayHabit(id: UUID(), habit: Habit.mockHabits[1], status: .pending, detail: "Closes 11:59 PM"),
        TodayHabit(id: UUID(), habit: Habit.mockHabits[2], status: .pending, detail: "1h 47m used", progress: 0.58),
        TodayHabit(id: UUID(), habit: Habit.mockHabits[3], status: .pending, detail: "Verifies tomorrow AM"),
    ]
}

extension ActivityItem {
    static let mockActivity: [ActivityItem] = [
        ActivityItem(icon: "❌", title: "Missed gym · yesterday", detail: "$10 → Investment Pool", isFailure: true),
        ActivityItem(icon: "✅", title: "Woke up 5:52 AM · yesterday", detail: "$10 saved", isFailure: false),
        ActivityItem(icon: "✅", title: "Screen < 3hrs · yesterday", detail: "$25 saved", isFailure: false),
    ]
}
