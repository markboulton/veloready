import Foundation
import HealthKit
import CoreLocation

/// Service for loading HealthKit data for activities (Phase 2 - Activities Refactor)
/// Extracts HealthKit queries from ActivityDetailViewModel
@MainActor
final class ActivityHealthKitService {
    static let shared = ActivityHealthKitService()

    private let healthStore = HKHealthStore()

    private init() {}

    // MARK: - Heart Rate Data

    /// Load heart rate samples for a workout
    /// - Parameter workout: The HealthKit workout to query
    /// - Returns: Array of (time, heart rate) tuples with time relative to workout start
    func loadHeartRateData(for workout: HKWorkout) async -> [(time: TimeInterval, heartRate: Double)] {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            Logger.warning("⚠️ [ActivityHealthKit] Heart rate type not available")
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    Logger.error("❌ [ActivityHealthKit] Failed to fetch heart rate: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }

                guard let hrSamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let startTime = workout.startDate.timeIntervalSince1970
                let samples: [(time: TimeInterval, heartRate: Double)] = hrSamples.map { sample in
                    let time = sample.startDate.timeIntervalSince1970 - startTime
                    let hr = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    return (time: time, heartRate: hr)
                }

                Logger.debug("✅ [ActivityHealthKit] Loaded \(samples.count) heart rate samples")
                continuation.resume(returning: samples)
            }

            healthStore.execute(query)
        }
    }

    /// Calculate heart rate statistics from samples
    /// - Parameter samples: Heart rate samples
    /// - Returns: Tuple of (average, max) heart rates
    func calculateHeartRateStats(from samples: [(time: TimeInterval, heartRate: Double)]) -> (average: Double?, max: Double?) {
        guard !samples.isEmpty else { return (nil, nil) }

        let hrValues = samples.map { $0.heartRate }
        let average = hrValues.reduce(0, +) / Double(hrValues.count)
        let max = hrValues.max()

        return (average, max)
    }

    // MARK: - Route Data

    /// Route data structure
    struct RouteData {
        let coordinates: [CLLocationCoordinate2D]
        let paceSamples: [Double]  // pace in min/km
    }

    /// Load route data (GPS coordinates and pace) for a workout
    /// - Parameter workout: The HealthKit workout to query
    /// - Returns: RouteData with coordinates and pace samples
    func loadRouteData(for workout: HKWorkout) async -> RouteData {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { [weak self] _, samples, error in
                guard let self = self else {
                    continuation.resume(returning: RouteData(coordinates: [], paceSamples: []))
                    return
                }

                if let error = error {
                    Logger.error("❌ [ActivityHealthKit] Failed to fetch route: \(error.localizedDescription)")
                    continuation.resume(returning: RouteData(coordinates: [], paceSamples: []))
                    return
                }

                guard let routes = samples as? [HKWorkoutRoute], let route = routes.first else {
                    Logger.trace("ℹ️ [ActivityHealthKit] No route data available")
                    continuation.resume(returning: RouteData(coordinates: [], paceSamples: []))
                    return
                }

                Task {
                    let routeData = await self.loadRouteLocations(route: route)
                    continuation.resume(returning: routeData)
                }
            }

            healthStore.execute(query)
        }
    }

    private func loadRouteLocations(route: HKWorkoutRoute) async -> RouteData {
        await withCheckedContinuation { continuation in
            var coordinates: [CLLocationCoordinate2D] = []
            var paces: [Double] = []

            let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if let error = error {
                    Logger.error("❌ [ActivityHealthKit] Failed to load route locations: \(error.localizedDescription)")
                    continuation.resume(returning: RouteData(coordinates: [], paceSamples: []))
                    return
                }

                if let locations = locations {
                    coordinates.append(contentsOf: locations.map { $0.coordinate })

                    // Calculate pace from speed for walking workouts
                    for location in locations {
                        let speedMps = location.speed  // meters per second
                        if speedMps > 0 {
                            // Convert m/s to min/km
                            let paceMinPerKm = (1000.0 / speedMps) / 60.0
                            paces.append(paceMinPerKm)
                        } else {
                            paces.append(10.0)  // Default pace
                        }
                    }
                }

                if done {
                    if !coordinates.isEmpty {
                        Logger.debug("✅ [ActivityHealthKit] Loaded \(coordinates.count) route points with pace data")
                    }
                    continuation.resume(returning: RouteData(coordinates: coordinates, paceSamples: paces))
                }
            }

            self.healthStore.execute(query)
        }
    }

    // MARK: - Steps Data

    /// Load step count for a workout
    /// - Parameter workout: The HealthKit workout to query
    /// - Returns: Total step count
    func loadSteps(for workout: HKWorkout) async -> Int {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            Logger.warning("⚠️ [ActivityHealthKit] Step count type not available")
            return 0
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    Logger.error("❌ [ActivityHealthKit] Failed to fetch steps: \(error.localizedDescription)")
                    continuation.resume(returning: 0)
                    return
                }

                if let sum = statistics?.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: .count()))
                    Logger.debug("✅ [ActivityHealthKit] Loaded steps: \(steps)")
                    continuation.resume(returning: steps)
                } else {
                    continuation.resume(returning: 0)
                }
            }

            healthStore.execute(query)
        }
    }
}
