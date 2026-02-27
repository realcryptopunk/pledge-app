import HealthKit

// MARK: - HealthKit Errors

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationFailed
    case queryFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .authorizationFailed:
            return "HealthKit authorization was denied."
        case .queryFailed(let error):
            return "HealthKit query failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - HealthKitManager

@MainActor
class HealthKitManager: ObservableObject {

    static let shared = HealthKitManager()

    let healthStore = HKHealthStore()

    @Published var isAuthorized = false

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.appleExerciseTime)
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
        } catch {
            throw HealthKitError.authorizationFailed
        }
    }

    // MARK: - Fetch Steps

    /// Fetches total step count for a given date (midnight to midnight).
    func fetchSteps(for date: Date) async throws -> Double {
        let quantityType = HKQuantityType(.stepCount)
        let (startOfDay, endOfDay) = dayBounds(for: date)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: steps)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Sleep Hours

    /// Fetches total sleep hours for a given date.
    /// Queries from 8 PM the previous day to noon on the given date to capture overnight sleep.
    func fetchSleepHours(for date: Date) async throws -> Double {
        let categoryType = HKCategoryType(.sleepAnalysis)
        let calendar = Calendar.current

        // Sleep window: 8 PM previous day to noon current day
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: date)),
              let sleepWindowStart = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: previousDay),
              let sleepWindowEnd = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) else {
            return 0
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: sleepWindowStart,
            end: sleepWindowEnd,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: categoryType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                guard let categorySamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }

                // Filter for actual sleep states (not .inBed)
                let sleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]

                let totalSeconds = categorySamples
                    .filter { sleepValues.contains($0.value) }
                    .reduce(0.0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    }

                let hours = totalSeconds / 3600.0
                continuation.resume(returning: hours)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Workout Minutes

    /// Fetches total exercise/workout minutes for a given date (midnight to midnight).
    func fetchWorkoutMinutes(for date: Date) async throws -> Double {
        let quantityType = HKQuantityType(.appleExerciseTime)
        let (startOfDay, endOfDay) = dayBounds(for: date)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                let minutes = statistics?.sumQuantity()?.doubleValue(for: .minute()) ?? 0
                continuation.resume(returning: minutes)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Helpers

    /// Returns (startOfDay, startOfNextDay) for a given date.
    private func dayBounds(for date: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        return (startOfDay, endOfDay)
    }
}
