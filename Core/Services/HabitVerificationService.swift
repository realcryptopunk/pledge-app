import Foundation

// MARK: - Verification Result

struct VerificationResult {
    let status: HabitStatus       // .verified, .failed, or .pending
    let actualValue: Double?      // what was measured (nil for manual types)
    let targetValue: Double       // what was needed
    let detail: String            // human-readable (e.g., "8,432 / 10,000 steps")
}

// MARK: - HabitVerificationService

@MainActor
class HabitVerificationService {

    private let healthKitManager: HealthKitManager

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
    }

    // MARK: - Single Habit Verification

    /// Verifies a single habit against its data source for the given date.
    func verifyHabit(_ habit: Habit, for date: Date) async -> VerificationResult {
        switch habit.type {
        case .steps:
            return await verifySteps(habit, for: date)
        case .sleep:
            return await verifySleep(habit, for: date)
        case .workout:
            return await verifyWorkout(habit, for: date)
        case .wakeUp:
            // Wake up verification needs alarm/motion detection which is complex
            return VerificationResult(
                status: .pending,
                actualValue: nil,
                targetValue: habit.targetValue,
                detail: "Tap to verify"
            )
        case .screenTime:
            // Cannot auto-verify without Screen Time API entitlement
            return VerificationResult(
                status: .pending,
                actualValue: nil,
                targetValue: habit.targetValue,
                detail: "Tap to verify"
            )
        case .meditate, .read, .journal, .coldShower, .water, .noJunkFood, .noSocial:
            // Manual types require user self-report
            return VerificationResult(
                status: .pending,
                actualValue: nil,
                targetValue: habit.targetValue,
                detail: "Tap to verify"
            )
        }
    }

    // MARK: - Batch Verification

    /// Verifies all habits concurrently, returning results keyed by habit ID.
    func verifyAllHabits(_ habits: [Habit], for date: Date) async -> [UUID: VerificationResult] {
        await withTaskGroup(of: (UUID, VerificationResult).self, returning: [UUID: VerificationResult].self) { group in
            for habit in habits {
                group.addTask {
                    let result = await self.verifyHabit(habit, for: date)
                    return (habit.id, result)
                }
            }

            var results: [UUID: VerificationResult] = [:]
            for await (id, result) in group {
                results[id] = result
            }
            return results
        }
    }

    // MARK: - HealthKit Verifiers

    private func verifySteps(_ habit: Habit, for date: Date) async -> VerificationResult {
        do {
            let actual = try await healthKitManager.fetchSteps(for: date)
            let target = habit.targetValue
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let actualFormatted = formatter.string(from: NSNumber(value: Int(actual))) ?? "\(Int(actual))"
            let targetFormatted = formatter.string(from: NSNumber(value: Int(target))) ?? "\(Int(target))"

            if actual >= target {
                return VerificationResult(
                    status: .verified,
                    actualValue: actual,
                    targetValue: target,
                    detail: "\(actualFormatted) steps"
                )
            } else {
                return VerificationResult(
                    status: .failed,
                    actualValue: actual,
                    targetValue: target,
                    detail: "\(actualFormatted) / \(targetFormatted) steps"
                )
            }
        } catch {
            return VerificationResult(
                status: .pending,
                actualValue: nil,
                targetValue: habit.targetValue,
                detail: "Health data unavailable"
            )
        }
    }

    private func verifySleep(_ habit: Habit, for date: Date) async -> VerificationResult {
        do {
            let actual = try await healthKitManager.fetchSleepHours(for: date)
            let target = habit.targetValue
            let actualRounded = (actual * 10).rounded() / 10
            let targetRounded = (target * 10).rounded() / 10

            if actual >= target {
                return VerificationResult(
                    status: .verified,
                    actualValue: actual,
                    targetValue: target,
                    detail: "\(actualRounded)h sleep"
                )
            } else {
                return VerificationResult(
                    status: .failed,
                    actualValue: actual,
                    targetValue: target,
                    detail: "\(actualRounded)h / \(targetRounded)h sleep"
                )
            }
        } catch {
            return VerificationResult(
                status: .pending,
                actualValue: nil,
                targetValue: habit.targetValue,
                detail: "Health data unavailable"
            )
        }
    }

    private func verifyWorkout(_ habit: Habit, for date: Date) async -> VerificationResult {
        do {
            let actual = try await healthKitManager.fetchWorkoutMinutes(for: date)
            let target = habit.targetValue
            let actualInt = Int(actual)
            let targetInt = Int(target)

            if actual >= target {
                return VerificationResult(
                    status: .verified,
                    actualValue: actual,
                    targetValue: target,
                    detail: "\(actualInt) min workout"
                )
            } else {
                return VerificationResult(
                    status: .failed,
                    actualValue: actual,
                    targetValue: target,
                    detail: "\(actualInt) / \(targetInt) min"
                )
            }
        } catch {
            return VerificationResult(
                status: .pending,
                actualValue: nil,
                targetValue: habit.targetValue,
                detail: "Health data unavailable"
            )
        }
    }
}
