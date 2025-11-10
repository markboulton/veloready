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
        print("🔄 [LoadData] ENTRY for activity: \(activity.name)")
        Logger.debug("🔄 [LoadData] ENTRY for activity: \(activity.name)")
        print("🔄 [LoadData] Activity details - type: \(activity.type), shouldShowMap: \(activity.shouldShowMap), isIndoorRide: \(activity.isIndoorRide)")
        Logger.debug("🔄 [LoadData] Activity details - type: \(activity.type), shouldShowMap: \(activity.shouldShowMap), isIndoorRide: \(activity.isIndoorRide)")
        print("🔄 [LoadData] Activity sources - strava: \(activity.stravaActivity != nil), intervals: \(activity.intervalsActivity != nil), healthkit: \(activity.healthKitWorkout != nil)")
        Logger.debug("🔄 [LoadData] Activity sources - strava: \(activity.stravaActivity != nil), intervals: \(activity.intervalsActivity != nil), healthkit: \(activity.healthKitWorkout != nil)")
        
        // Mark as loaded to track state
        hasLoadedData = true
        
        // Load all data in parallel to avoid blocking
        print("🔄 [LoadData] Starting parallel tasks...")
        Logger.debug("🔄 [LoadData] Starting parallel tasks...")
        async let mapTask: Void = loadMapSnapshot()
        async let locationTask: Void = loadLocation()
        async let stepsTask: Void = activity.type == .walking ? loadStepsData() : ()
        async let hrTask: Void = activity.type == .walking ? loadAverageHRData() : ()
        
        // Wait for all tasks to complete
        _ = await (mapTask, locationTask, stepsTask, hrTask)
        
        print("✅ [LoadData] Completed loading data for \(activity.name)")
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
        print("🗺️ [LoadMapSnapshot] ENTRY - Starting for activity: \(activity.name)")
        Logger.debug("🗺️ [LoadMapSnapshot] ENTRY - Starting for activity: \(activity.name) (type: \(activity.type), source: \(activity.source))")
        
        // Allow map loading for walking activities even if shouldShowMap is false
        if !activity.shouldShowMap && activity.type != .walking {
            print("🗺️ [LoadMapSnapshot] ❌ SKIPPING - not eligible")
            Logger.debug("🗺️ [LoadMapSnapshot] ❌ SKIPPING - not eligible for map (shouldShowMap=false, type=\(activity.type))")
            return
        }
        
        print("🗺️ [LoadMapSnapshot] ✅ Map loading eligible, proceeding...")
        Logger.debug("🗺️ [LoadMapSnapshot] ✅ Map loading eligible, proceeding...")
        
        isLoadingMap = true
        defer { isLoadingMap = false }
        
        print("🗺️ [LoadMapSnapshot] Fetching GPS coordinates...")
        Logger.debug("🗺️ [LoadMapSnapshot] Fetching GPS coordinates...")
        guard let coordinates = await getGPSCoordinates() else {
            print("❌ [LoadMapSnapshot] No GPS coordinates available for \(activity.name)")
            Logger.debug("❌ [LoadMapSnapshot] No GPS coordinates available for \(activity.name)")
            return
        }
        
        print("✅ [LoadMapSnapshot] Got \(coordinates.count) GPS coordinates")
        Logger.debug("✅ [LoadMapSnapshot] Got \(coordinates.count) GPS coordinates")
        print("🗺️ [LoadMapSnapshot] Generating snapshot from \(coordinates.count) coordinates")
        Logger.debug("🗺️ [LoadMapSnapshot] Generating snapshot from \(coordinates.count) coordinates on background thread for \(activity.name)")
        
        // Use background thread method for better performance
        mapSnapshot = await mapSnapshotService.generateMapAsync(
            coordinates: coordinates,
            activityId: activity.id
        )
        
        if mapSnapshot != nil {
            print("✅ [LoadMapSnapshot] Successfully generated map!")
            Logger.debug("✅ [LoadMapSnapshot] Successfully generated map on background thread for \(activity.name)")
        } else {
            print("❌ [LoadMapSnapshot] Failed to generate map")
            Logger.debug("❌ [LoadMapSnapshot] Failed to generate map for \(activity.name)")
        }
    }
    
    private func getGPSCoordinates() async -> [CLLocationCoordinate2D]? {
        print("🗺️ [GPS] Getting coordinates - strava: \(activity.stravaActivity != nil), intervals: \(activity.intervalsActivity != nil)")
        
        // Try Strava first if available
        if let stravaActivity = activity.stravaActivity {
            print("🗺️ [GPS] Using Strava activity ID: \(stravaActivity.id)")
            return await fetchStravaGPSCoordinates(activityId: stravaActivity.id)
        }
        
        // If Intervals activity, check if it's from Strava
        if let intervalsActivity = activity.intervalsActivity {
            print("🗺️ [GPS] Have Intervals activity - source: \(intervalsActivity.source ?? "nil"), id: \(intervalsActivity.id)")
            
            // Check if ID has "strava_" prefix (indicates synced from Strava)
            let isFromStrava = intervalsActivity.source?.uppercased() == "STRAVA" || 
                              intervalsActivity.id.hasPrefix("strava_")
            
            if isFromStrava {
                // Extract Strava ID from the ID string (format: "strava_16403607746")
                let stravaIdString = intervalsActivity.id.replacingOccurrences(of: "strava_", with: "")
                if let stravaId = Int(stravaIdString) {
                    print("🗺️ [GPS] Activity from Strava (ID: \(stravaId)), fetching GPS from Strava API")
                    let coords = await fetchStravaGPSCoordinates(activityId: stravaId)
                    if coords != nil {
                        print("✅ [GPS] Got \(coords!.count) coordinates from Strava")
                        return coords
                    }
                    print("⚠️ [GPS] Strava fetch failed, falling back to Intervals")
                }
            }
            
            // Fallback to Intervals API
            print("🗺️ [GPS] Fetching from Intervals API")
            return await fetchIntervalsGPSCoordinates(activityId: intervalsActivity.id)
        }
        
        // For HealthKit workouts (Walking, etc), fetch route data
        if let workout = activity.healthKitWorkout {
            print("🗺️ [GPS] Using HealthKit workout")
            return await fetchHealthKitGPSCoordinates(workout: workout)
        }
        
        print("❌ [GPS] No valid activity source found")
        return nil
    }
    
    private func fetchStravaGPSCoordinates(activityId: Int) async -> [CLLocationCoordinate2D]? {
        Logger.debug("🗺️ [GPS] Fetching Strava GPS for activity \(activityId)")
        do {
            let streamsDict = try await veloReadyAPIClient.fetchActivityStreams(
                activityId: String(activityId),
                source: .strava
            )
            
            Logger.debug("🗺️ [GPS] Got stream data with keys: \(streamsDict.keys.joined(separator: ", "))")
            
            guard let latlngStreamData = streamsDict["latlng"] else {
                Logger.debug("❌ [GPS] No latlng stream in response")
                return nil
            }
            
            let coordinates: [CLLocationCoordinate2D]
            switch latlngStreamData.data {
            case .latlng(let coords):
                coordinates = coords.compactMap { coord -> CLLocationCoordinate2D? in
                    guard coord.count >= 2 else { return nil }
                    return CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1])
                }
                Logger.debug("✅ [GPS] Extracted \(coordinates.count) coordinates from latlng stream")
            case .simple:
                Logger.debug("❌ [GPS] Stream data is simple type, not latlng")
                return nil
            }
            
            return coordinates.isEmpty ? nil : coordinates
        } catch {
            Logger.debug("❌ [GPS] Failed to fetch Strava streams: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func fetchIntervalsGPSCoordinates(activityId: String) async -> [CLLocationCoordinate2D]? {
        print("🗺️ [GPS] Fetching Intervals GPS for activity \(activityId)")
        do {
            let samples = try await intervalsAPIClient.fetchActivityStreams(activityId: activityId)
            print("🗺️ [GPS] Got \(samples.count) samples from Intervals")
            
            let coordinates = samples.compactMap { sample -> CLLocationCoordinate2D? in
                guard let lat = sample.latitude, let lng = sample.longitude else { return nil }
                guard !(lat == 0 && lng == 0) else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
            
            print("🗺️ [GPS] Extracted \(coordinates.count) valid coordinates from Intervals")
            return coordinates.isEmpty ? nil : coordinates
        } catch {
            print("❌ [GPS] Failed to fetch Intervals streams: \(error.localizedDescription)")
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
