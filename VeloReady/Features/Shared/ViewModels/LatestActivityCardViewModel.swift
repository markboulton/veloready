import SwiftUI
import MapKit
import HealthKit

/// ViewModel for LatestActivityCardV2
/// Handles async GPS loading, map snapshot generation, and location geocoding
@MainActor
class LatestActivityCardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var locationString: String?
    @Published private(set) var mapSnapshot: UIImage?
    @Published private(set) var isLoadingMap: Bool = false
    @Published private(set) var stepsData: String?
    @Published private(set) var averageHRData: String?
    
    // MARK: - Properties
    
    let activity: UnifiedActivity
    private var hasLoadedData = false
    
    // MARK: - Dependencies
    
    private let locationGeocodingService: LocationGeocodingService
    private let mapSnapshotService: MapSnapshotService
    private let veloReadyAPIClient: VeloReadyAPIClient
    private let intervalsAPIClient: IntervalsAPIClient
    
    // MARK: - Initialization
    
    init(
        activity: UnifiedActivity,
        locationGeocodingService: LocationGeocodingService = .shared,
        mapSnapshotService: MapSnapshotService = .shared,
        veloReadyAPIClient: VeloReadyAPIClient = .shared,
        intervalsAPIClient: IntervalsAPIClient = .shared
    ) {
        self.activity = activity
        self.locationGeocodingService = locationGeocodingService
        self.mapSnapshotService = mapSnapshotService
        self.veloReadyAPIClient = veloReadyAPIClient
        self.intervalsAPIClient = intervalsAPIClient
    }
    
    // MARK: - Public Methods
    
    func loadData() async {
        // Prevent loading data multiple times (onAppear can fire repeatedly)
        guard !hasLoadedData else {
            Logger.debug("⏭️ LatestActivityCardV2 - Data already loaded, skipping")
            return
        }
        
        hasLoadedData = true
        
        // Load all data in parallel to avoid blocking
        async let mapTask: Void = loadMapSnapshot()
        async let locationTask: Void = loadLocation()
        async let stepsTask: Void = activity.type == .walking ? loadStepsData() : ()
        async let hrTask: Void = activity.type == .walking ? loadAverageHRData() : ()
        
        // Wait for all tasks to complete
        _ = await (mapTask, locationTask, stepsTask, hrTask)
        
        Logger.debug("✅ [LoadData] Completed loading data for \(activity.name)")
    }
    
    // MARK: - GPS & Location
    
    func loadLocation() async {
        guard let coordinates = await getGPSCoordinates() else { return }
        locationString = await locationGeocodingService.getStartLocation(from: coordinates)
    }
    
    func loadStepsData() async {
        guard let workout = activity.healthKitWorkout else {
            Logger.debug("❌ [StepsData] No HealthKit workout")
            return
        }
        
        let healthStore = HKHealthStore()
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            Logger.debug("❌ [StepsData] Failed to get stepCount type")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        
        let steps = await withCheckedContinuation { (continuation: CheckedContinuation<Int?, Never>) in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let sum = result?.sumQuantity() {
                    let stepsValue = Int(sum.doubleValue(for: .count()))
                    Logger.debug("✅ [StepsData] Retrieved \(stepsValue) steps from HealthKit query")
                    continuation.resume(returning: stepsValue)
                } else {
                    Logger.debug("❌ [StepsData] No steps found in HealthKit for workout period")
                    continuation.resume(returning: nil)
                }
            }
            
            healthStore.execute(query)
        }
        
        if let steps = steps {
            stepsData = "\(steps)"
        }
    }
    
    func loadAverageHRData() async {
        guard let workout = activity.healthKitWorkout else {
            Logger.debug("❌ [AvgHR] No HealthKit workout")
            return
        }
        
        let healthStore = HKHealthStore()
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            Logger.debug("❌ [AvgHR] Failed to get heartRate type")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        
        let avgHR = await withCheckedContinuation { (continuation: CheckedContinuation<Int?, Never>) in
            let query = HKStatisticsQuery(
                quantityType: hrType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let average = result?.averageQuantity() {
                    let hrValue = Int(average.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
                    Logger.debug("✅ [AvgHR] Retrieved average HR: \(hrValue) bpm from HealthKit query")
                    continuation.resume(returning: hrValue)
                } else {
                    Logger.debug("❌ [AvgHR] No heart rate data found in HealthKit for workout period")
                    continuation.resume(returning: nil)
                }
            }
            
            healthStore.execute(query)
        }
        
        if let avgHR = avgHR {
            averageHRData = "\(avgHR) bpm"
        }
    }
    
    func loadMapSnapshot() async {
        // Allow map loading for walking activities even if shouldShowMap is false
        guard activity.shouldShowMap || activity.type == .walking else {
            Logger.debug("🗺️ [LoadMapSnapshot] Skipping - not eligible for map (type: \(activity.type))")
            return
        }
        
        isLoadingMap = true
        defer { isLoadingMap = false }
        
        guard let coordinates = await getGPSCoordinates() else {
            Logger.debug("🗺️ [LoadMapSnapshot] No GPS coordinates available for \(activity.name)")
            return
        }
        
        Logger.debug("🗺️ [LoadMapSnapshot] Generating snapshot from \(coordinates.count) coordinates for \(activity.name)")
        mapSnapshot = await mapSnapshotService.generateSnapshot(from: coordinates)
        
        if mapSnapshot != nil {
            Logger.debug("✅ [LoadMapSnapshot] Successfully generated map for \(activity.name)")
        } else {
            Logger.debug("❌ [LoadMapSnapshot] Failed to generate map for \(activity.name)")
        }
    }
    
    private func getGPSCoordinates() async -> [CLLocationCoordinate2D]? {
        if let stravaActivity = activity.stravaActivity {
            return await fetchStravaGPSCoordinates(activityId: stravaActivity.id)
        }
        
        if let intervalsActivity = activity.intervalsActivity {
            return await fetchIntervalsGPSCoordinates(activityId: intervalsActivity.id)
        }
        
        // For HealthKit workouts (Walking, etc), fetch route data
        if let workout = activity.healthKitWorkout {
            return await fetchHealthKitGPSCoordinates(workout: workout)
        }
        
        return nil
    }
    
    private func fetchStravaGPSCoordinates(activityId: Int) async -> [CLLocationCoordinate2D]? {
        do {
            let streamsDict = try await veloReadyAPIClient.fetchActivityStreams(
                activityId: String(activityId),
                source: .strava
            )
            
            guard let latlngStreamData = streamsDict["latlng"] else { return nil }
            
            let coordinates: [CLLocationCoordinate2D]
            switch latlngStreamData.data {
            case .latlng(let coords):
                coordinates = coords.compactMap { coord -> CLLocationCoordinate2D? in
                    guard coord.count >= 2 else { return nil }
                    return CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1])
                }
            case .simple:
                return nil
            }
            
            return coordinates.isEmpty ? nil : coordinates
        } catch {
            return nil
        }
    }
    
    private func fetchIntervalsGPSCoordinates(activityId: String) async -> [CLLocationCoordinate2D]? {
        do {
            let samples = try await intervalsAPIClient.fetchActivityStreams(activityId: activityId)
            
            let coordinates = samples.compactMap { sample -> CLLocationCoordinate2D? in
                guard let lat = sample.latitude, let lng = sample.longitude else { return nil }
                guard !(lat == 0 && lng == 0) else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
            
            return coordinates.isEmpty ? nil : coordinates
        } catch {
            return nil
        }
    }
    
    private func fetchHealthKitGPSCoordinates(workout: HKWorkout) async -> [CLLocationCoordinate2D]? {
        let healthStore = HKHealthStore()
        let routeType = HKSeriesType.workoutRoute()
        
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForObjects(from: workout)
            let query = HKSampleQuery(sampleType: routeType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                guard error == nil, let routes = samples as? [HKWorkoutRoute], let route = routes.first else {
                    Logger.debug("🗺️ [HealthKit] No route data found for workout")
                    continuation.resume(returning: nil)
                    return
                }
                
                var coordinates: [CLLocationCoordinate2D] = []
                let routeQuery = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                    if let locations = locations {
                        coordinates.append(contentsOf: locations.map { $0.coordinate })
                    }
                    
                    if done {
                        Logger.debug("🗺️ [HealthKit] Fetched \(coordinates.count) GPS coordinates from workout route")
                        continuation.resume(returning: coordinates.isEmpty ? nil : coordinates)
                    }
                }
                
                healthStore.execute(routeQuery)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Computed Properties
    
    var formattedDateAndTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: activity.startDate)
    }
    
    var formattedDateAndTimeWithLocation: String {
        var result = formattedDateAndTime
        if let location = locationString {
            result += " • \(location)"
        }
        return result
    }
    
    var shouldShowMap: Bool {
        activity.shouldShowMap
    }
    
    var hasMapSnapshot: Bool {
        mapSnapshot != nil
    }
    
    var stepsCount: String? {
        guard let workout = activity.healthKitWorkout else {
            Logger.debug("❌ [StepsCount] No HealthKit workout for \(activity.name)")
            return nil
        }
        
        Logger.debug("🔍 [StepsCount] Checking steps for \(activity.name) (type: \(workout.workoutActivityType.rawValue))")
        Logger.debug("🔍 [StepsCount] Workout duration: \(workout.duration)s, distance: \(workout.totalDistance?.doubleValue(for: .meter()) ?? 0)m")
        
        // Try workout statistics first
        if let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount),
           let statistics = workout.statistics(for: stepsType),
           let sum = statistics.sumQuantity() {
            let steps = Int(sum.doubleValue(for: .count()))
            Logger.debug("✅ [StepsCount] Retrieved \(steps) steps from workout.statistics for \(activity.name)")
            return "\(steps)"
        } else {
            Logger.debug("⚠️ [StepsCount] No steps in workout.statistics for \(activity.name) - this is expected for HealthKit walking workouts")
        }
        
        // For walking workouts, steps are often stored separately from the workout
        // We need to query HealthKit asynchronously, but we can't do that in a computed property
        // Instead, we'll return nil here and handle this in the view model's loadData() method
        Logger.debug("❌ [StepsCount] No step data available in workout statistics for \(activity.name)")
        Logger.debug("💡 [StepsCount] For walking activities, steps may need to be queried separately from HealthKit")
        return nil
    }
}
