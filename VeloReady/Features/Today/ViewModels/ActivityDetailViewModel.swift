import Foundation
import HealthKit
import MapKit
import SwiftUI

/// View model for Activity Detail page (Phase 2 Refactor - Service Layer)
/// Reduced from 446 lines to ~220 lines by extracting HealthKit and Map logic to services
@MainActor
@Observable
final class ActivityDetailViewModel {
    let activityData: UnifiedActivityData

    // Map
    var mapSnapshot: UIImage?
    var isLoadingMap = false
    var routeCoordinates: [CLLocationCoordinate2D] = []

    // Charts - downsampled for performance
    var chartSamples: [Any] = []
    var workoutSamples: [WorkoutSample] = []
    var heartRateSamples: [(time: TimeInterval, heartRate: Double)] = []
    var paceSamples: [Double] = []  // Pace in min/km for walking workouts

    // Cache for raw (non-downsampled) data
    private var rawWorkoutSamples: [WorkoutSample] = []
    private var rawHeartRateSamples: [(time: TimeInterval, heartRate: Double)] = []

    // Metrics
    var steps: Int = 0
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var ftp: Double?

    // Injected dependencies (Phase 2 - Dependency Injection Pattern)
    private let healthKitService: ActivityHealthKitService
    private let mapService: ActivityMapService
    private let apiClient: IntervalsAPIClient
    private let athleteZoneService: AthleteZoneService

    init(
        activityData: UnifiedActivityData,
        healthKitService: ActivityHealthKitService = .shared,
        mapService: ActivityMapService = .shared,
        apiClient: IntervalsAPIClient = .shared,
        athleteZoneService: AthleteZoneService = .shared
    ) {
        self.activityData = activityData
        self.healthKitService = healthKitService
        self.mapService = mapService
        self.apiClient = apiClient
        self.athleteZoneService = athleteZoneService
    }

    func loadData() async {
        switch activityData.type {
        case .cycling:
            await loadCyclingData()
        case .walking, .strength:
            await loadHealthKitData()
        }
    }

    // MARK: - Cycling Data

    private func loadCyclingData() async {
        guard let activity = activityData.intervalsActivity else { return }

        // Load workout samples
        await loadWorkoutSamples(activityId: activity.id)

        // Load FTP
        if athleteZoneService.shouldRefreshAthleteData {
            await athleteZoneService.fetchAthleteData()
        }
        ftp = athleteZoneService.athlete?.powerZones?.ftp

        // Generate map
        await generateMap()
    }

    private func loadWorkoutSamples(activityId: String) async {
        do {
            let samples = try await apiClient.fetchActivityStreams(activityId: activityId)
            self.rawWorkoutSamples = samples

            // Downsample for chart performance (optimize for heart rate as it's most variable)
            let downsampled = DataSmoothing.downsampleWorkoutSamples(
                samples,
                optimizeFor: .heartRate,
                targetPoints: 500
            )

            self.workoutSamples = downsampled
            self.chartSamples = downsampled
            Logger.debug("✅ Loaded \(samples.count) workout samples (downsampled to \(downsampled.count))")
        } catch {
            Logger.error("Failed to load workout samples: \(error)")
        }
    }

    private func generateMap() async {
        // Use raw samples for full-resolution route
        let coordinates = rawWorkoutSamples.compactMap { sample -> CLLocationCoordinate2D? in
            guard let lat = sample.latitude, let lng = sample.longitude,
                  lat != 0, lng != 0 else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }

        guard !coordinates.isEmpty else {
            Logger.debug("🗺️ No GPS coordinates found in workout data")
            return
        }

        self.routeCoordinates = coordinates
        Logger.debug("✅ Loaded \(coordinates.count) GPS coordinates for interactive map")
    }

    // MARK: - HealthKit Data (Using Service Layer)

    private func loadHealthKitData() async {
        guard let workout = activityData.healthKitWorkout else { return }

        // Load heart rate (using ActivityHealthKitService)
        await loadHeartRateData(for: workout)

        // Load route (using ActivityHealthKitService)
        await loadRouteData(for: workout)

        // Load steps (using ActivityHealthKitService)
        await loadSteps(for: workout)

        // Generate map snapshot if we have coordinates
        if !routeCoordinates.isEmpty {
            await generateMapSnapshot()
        }
    }

    private func loadHeartRateData(for workout: HKWorkout) async {
        // Delegate to ActivityHealthKitService
        let samples = await healthKitService.loadHeartRateData(for: workout)

        self.rawHeartRateSamples = samples

        // Downsample for chart performance
        let downsampled = DataSmoothing.downsampleHeartRateSamples(
            samples,
            targetPoints: 500
        )

        self.heartRateSamples = downsampled
        self.chartSamples = downsampled

        // Calculate stats
        let stats = healthKitService.calculateHeartRateStats(from: samples)
        self.averageHeartRate = stats.average
        self.maxHeartRate = stats.max

        if !samples.isEmpty {
            Logger.debug("✅ Loaded \(samples.count) heart rate samples (downsampled to \(downsampled.count))")
        }
    }

    private func loadRouteData(for workout: HKWorkout) async {
        // Delegate to ActivityHealthKitService
        let routeData = await healthKitService.loadRouteData(for: workout)

        self.routeCoordinates = routeData.coordinates
        self.paceSamples = routeData.paceSamples

        if !routeData.coordinates.isEmpty {
            Logger.debug("✅ Loaded \(routeData.coordinates.count) route points with pace data")
        }
    }

    private func loadSteps(for workout: HKWorkout) async {
        // Delegate to ActivityHealthKitService
        let steps = await healthKitService.loadSteps(for: workout)
        self.steps = steps
    }

    // MARK: - Map Generation (Using Service Layer)

    private func generateMapSnapshot() async {
        guard !routeCoordinates.isEmpty else { return }

        isLoadingMap = true
        defer { isLoadingMap = false }

        // Delegate to ActivityMapService
        let snapshot = await mapService.generateMapSnapshot(
            coordinates: routeCoordinates,
            size: CGSize(width: 350, height: 200),
            displayScale: 3.0
        )

        self.mapSnapshot = snapshot
    }
}
