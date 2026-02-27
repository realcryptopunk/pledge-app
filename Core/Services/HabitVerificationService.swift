import Foundation
import CoreLocation

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
    private let locationManager: LocationManager

    init(healthKitManager: HealthKitManager, locationManager: LocationManager) {
        self.healthKitManager = healthKitManager
        self.locationManager = locationManager
    }

    // MARK: - Single Habit Verification

    /// Verifies a single habit against its data source for the given date.
    func verifyHabit(_ habit: Habit, for date: Date) async -> VerificationResult {
        // Location-verified habits use geofence monitoring, not pull-based verification
        if habit.verificationType == .location {
            return verifyByLocation(habit)
        }

        // Vision-verified habits use camera pose detection (pushups, squats, etc.)
        if habit.verificationType == .vision {
            return VerificationResult(
                status: .pending,
                actualValue: nil,
                targetValue: habit.targetValue,
                detail: "Open camera to count reps"
            )
        }

        switch habit.type {
        case .steps:
            return await verifySteps(habit, for: date)
        case .sleep:
            return await verifySleep(habit, for: date)
        case .workout, .gym:
            return await verifyWorkout(habit, for: date)
        case .pushups:
            // Pushups use vision/camera verification — manual fallback
            return VerificationResult(
                status: .pending,
                actualValue: nil,
                targetValue: habit.targetValue,
                detail: "Open camera to count reps"
            )
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

    // MARK: - Location Verifier

    private func verifyByLocation(_ habit: Habit) -> VerificationResult {
        guard habit.hasLocation,
              let lat = habit.locationLatitude,
              let lon = habit.locationLongitude else {
            return VerificationResult(
                status: .pending,
                actualValue: nil,
                targetValue: habit.targetValue,
                detail: "Set a location to enable verification"
            )
        }

        // Ensure the region is being monitored
        let radius = habit.locationRadius ?? 150
        let region = locationManager.makeRegion(
            identifier: habit.geofenceIdentifier,
            latitude: lat,
            longitude: lon,
            radius: radius
        )
        locationManager.startMonitoring(region: region)

        let locationLabel = habit.locationName ?? "location"
        return VerificationResult(
            status: .pending,
            actualValue: nil,
            targetValue: habit.targetValue,
            detail: "Monitoring \(locationLabel)..."
        )
    }

    /// Handles a geofence event triggered by LocationManager notifications.
    /// - Parameters:
    ///   - regionIdentifier: The geofence region identifier (format: "habit-{uuid}")
    ///   - entered: true if the user entered the region, false if exited
    ///   - habits: Current list of habits to look up the matching habit
    /// - Returns: A tuple of (habitId, VerificationResult) if a matching habit was found, nil otherwise.
    func handleGeofenceEvent(regionIdentifier: String, entered: Bool, habits: [Habit]) -> (UUID, VerificationResult)? {
        // Parse habit ID from region identifier (format: "habit-{uuid}")
        guard regionIdentifier.hasPrefix("habit-") else { return nil }
        let uuidString = String(regionIdentifier.dropFirst(6)) // "habit-".count == 6
        guard let habitId = UUID(uuidString: uuidString) else { return nil }
        guard let habit = habits.first(where: { $0.id == habitId }) else { return nil }

        // Only process entry events for location verification
        if entered {
            if habit.type == .noJunkFood {
                // Entering a forbidden zone = FAILURE
                let locationLabel = habit.locationName ?? "restricted area"
                return (habitId, VerificationResult(
                    status: .failed,
                    actualValue: nil,
                    targetValue: habit.targetValue,
                    detail: "Entered \(locationLabel)"
                ))
            } else {
                // Entering target zone (gym, etc.) = SUCCESS
                let locationLabel = habit.locationName ?? "location"
                return (habitId, VerificationResult(
                    status: .verified,
                    actualValue: nil,
                    targetValue: habit.targetValue,
                    detail: "Arrived at \(locationLabel)"
                ))
            }
        }

        // Exit events: no action for now (outdoor time tracking deferred)
        return nil
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
