import SwiftUI

// MARK: - Setup Step

enum SetupStep: Int, CaseIterable {
    case chooseHabits
    case configureHabits
    case setStakes
    case riskProfile
    case deposit
    case permissions
    case success
}

// MARK: - Habit Setup Config

struct HabitSetupConfig: Identifiable {
    let id = UUID()
    let type: HabitType
    var targetValue: Double
    var targetTimeHour: Int
    var targetTimeMinute: Int
    var schedule: Set<Int>
    var stakeAmount: Double

    init(type: HabitType) {
        self.type = type
        self.targetValue = type.defaultTarget
        self.targetTimeHour = type == .sleep ? 11 : 6
        self.targetTimeMinute = 0
        self.schedule = Set(1...7)
        self.stakeAmount = 10
    }
}

// MARK: - Target Config

struct TargetConfig {
    let label: String
    let unit: String
    let min: Double
    let max: Double
    let step: Double
}

// MARK: - Setup Flow State

@Observable class SetupFlowState {
    var currentStep: SetupStep = .chooseHabits
    var isNavigatingForward = true
    var selectedTypes: [HabitType] = []
    var configs: [HabitType: HabitSetupConfig] = [:]
    var selectedRiskProfile: RiskProfile = .moderate
    var depositAmount: Double = 0
    var configPageIndex: Int = 0

    // MARK: - Navigation

    func goForward() {
        guard let nextStep = SetupStep(rawValue: currentStep.rawValue + 1) else { return }
        isNavigatingForward = true
        currentStep = nextStep
    }

    func goBack() {
        guard let prevStep = SetupStep(rawValue: currentStep.rawValue - 1) else { return }
        isNavigatingForward = false
        currentStep = prevStep
    }

    // MARK: - Habit Selection

    func toggleHabit(_ type: HabitType) {
        if let index = selectedTypes.firstIndex(of: type) {
            selectedTypes.remove(at: index)
            configs.removeValue(forKey: type)
        } else if selectedTypes.count < 99 {
            selectedTypes.append(type)
            configs[type] = HabitSetupConfig(type: type)
        }
    }

    func isSelected(_ type: HabitType) -> Bool {
        selectedTypes.contains(type)
    }

    // MARK: - Summary Computed Properties

    var dailyExposure: Double {
        selectedTypes.compactMap { configs[$0]?.stakeAmount }.reduce(0, +)
    }

    var weeklyExposure: Double {
        selectedTypes.compactMap { type in
            guard let config = configs[type] else { return nil }
            return config.stakeAmount * Double(config.schedule.count)
        }.reduce(0, +)
    }

    var monthlyMax: Double {
        weeklyExposure * 4.33
    }
}

// MARK: - HabitType Extensions

extension HabitType {
    var defaultIcon: String {
        switch self {
        case .wakeUp: return "⏰"
        case .workout: return "🏋️"
        case .gym: return "🏋️"
        case .pushups: return "💪"
        case .pullUps: return "🏋️‍♂️"
        case .jumpingJacks: return "⭐"
        case .steps: return "👟"
        case .sleep: return "😴"
        case .meditate: return "🧘"
        case .screenTime: return "📱"
        case .read: return "📚"
        case .coldShower: return "🧊"
        case .journal: return "📝"
        }
    }

    var defaultTarget: Double {
        switch self {
        case .steps: return 10000
        case .sleep: return 7
        case .workout, .gym: return 30
        case .pushups: return 20
        case .pullUps: return 10
        case .jumpingJacks: return 20
        case .screenTime: return 2
        case .meditate: return 10
        case .read: return 30
        case .wakeUp: return 6
        default: return 0
        }
    }

    var defaultVerification: VerificationType {
        switch self {
        case .steps, .sleep, .workout, .gym: return .healthKit
        case .pushups, .pullUps, .jumpingJacks: return .vision
        case .screenTime, .wakeUp: return .manual
        case .coldShower, .meditate, .journal, .read: return .photo
        default: return .manual
        }
    }

    var verificationLabel: String {
        switch self {
        case .gym: return "Health + Location"
        default:
            switch defaultVerification {
            case .healthKit: return "Apple Health"
            case .manual: return "Self-report"
            case .photo: return "Photo proof"
            case .location: return "GPS location"
            case .vision: return "Camera tracking"
            case .screenTimeAPI: return "Screen Time"
            case .auto: return "Automatic"
            case .inApp: return "In-app"
            }
        }
    }

    var verificationIcon: String {
        switch self {
        case .gym: return "heart.fill"
        default:
            switch defaultVerification {
            case .healthKit: return "heart.fill"
            case .manual: return "hand.tap.fill"
            case .photo: return "camera.fill"
            case .location: return "location.fill"
            case .vision: return "figure.mixed.cardio"
            case .screenTimeAPI: return "hourglass"
            case .auto: return "gearshape.fill"
            case .inApp: return "iphone"
            }
        }
    }

    var accentColor: Color {
        switch self {
        case .wakeUp: return Color(hex: "F59E0B")
        case .workout: return Color(hex: "EF4444")
        case .gym: return Color(hex: "EF4444")
        case .pushups: return Color(hex: "F43F5E")
        case .pullUps: return Color(hex: "8B5CF6")
        case .jumpingJacks: return Color(hex: "F59E0B")
        case .steps: return Color(hex: "22C55E")
        case .sleep: return Color(hex: "6366F1")
        case .meditate: return Color(hex: "14B8A6")
        case .screenTime: return Color(hex: "F97316")
        case .read: return Color(hex: "3B82F6")
        case .coldShower: return Color(hex: "06B6D4")
        case .journal: return Color(hex: "A855F7")
        }
    }

    var targetConfig: TargetConfig? {
        switch self {
        case .steps:
            return TargetConfig(label: "Daily step goal", unit: "steps", min: 1000, max: 50000, step: 1000)
        case .sleep:
            return TargetConfig(label: "Hours of sleep", unit: "hours", min: 4, max: 12, step: 1)
        case .workout, .gym:
            return TargetConfig(label: "Workout duration", unit: "minutes", min: 10, max: 120, step: 5)
        case .pushups:
            return TargetConfig(label: "Pushup count", unit: "reps", min: 5, max: 200, step: 5)
        case .pullUps:
            return TargetConfig(label: "Pull-up count", unit: "reps", min: 1, max: 50, step: 1)
        case .jumpingJacks:
            return TargetConfig(label: "Jumping jack count", unit: "reps", min: 5, max: 200, step: 5)
        case .screenTime:
            return TargetConfig(label: "Max screen time", unit: "hours", min: 1, max: 12, step: 1)
        case .meditate:
            return TargetConfig(label: "Meditation duration", unit: "minutes", min: 5, max: 60, step: 5)
        case .read:
            return TargetConfig(label: "Reading time", unit: "minutes", min: 5, max: 120, step: 5)
        default:
            return nil
        }
    }

    var usesTimePicker: Bool {
        self == .wakeUp || self == .sleep
    }

    var isManualOnly: Bool {
        switch self {
        case .coldShower, .journal:
            return true
        default:
            return false
        }
    }

    var durationPresets: [Double]? {
        switch self {
        case .workout, .gym: return [15, 30, 45, 60]
        case .meditate: return [5, 10, 15, 30]
        case .read: return [15, 30, 45, 60]
        default: return nil
        }
    }
}
