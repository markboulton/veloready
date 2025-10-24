import Foundation
import HealthKit
import MapKit
import SwiftUI

@MainActor
class ActivityDetailViewModel: ObservableObject {
    let activityData: UnifiedActivityData
    
    // Map
    @Published var mapSnapshot: UIImage?
    @Published var isLoadingMap = false
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    
    // Charts - downsampled for performance
    @Published var chartSamples: [Any] = []
    @Published var workoutSamples: [WorkoutSample] = []
    @Published var heartRateSamples: [(time: TimeInterval, heartRate: Double)] = []
    @Published var paceSamples: [Double] = []  // Pace in min/km for walking workouts
    
    // Cache for raw (non-downsampled) data
    private var rawWorkoutSamples: [WorkoutSample] = []
    private var rawHeartRateSamples: [(time: TimeInterval, heartRate: Double)] = []
    
    // Metrics
    @Published var steps: Int = 0
    @Published var averageHeartRate: Double?
    @Published var maxHeartRate: Double?
    @Published var ftp: Double?
    
    private let healthStore = HKHealthStore()
    private let apiClient: IntervalsAPIClient
    private let athleteZoneService: AthleteZoneService
    
    init(activityData: UnifiedActivityData) {
        self.activityData = activityData
        self.apiClient = IntervalsAPIClient.shared
        self.athleteZoneService = AthleteZoneService.shared
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
        await generateMapFromSamples()
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
    
    private func generateMapFromSamples() async {
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
    
    // MARK: - HealthKit Data
    
    private func loadHealthKitData() async {
        guard let workout = activityData.healthKitWorkout else { return }
        
        // Load heart rate
        await loadHeartRateData(for: workout)
        
        // Load route
        await loadRouteData(for: workout)
        
        // Load steps
        await loadSteps(for: workout)
    }
    
    private func loadHeartRateData(for workout: HKWorkout) async {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return
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
        
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                if let error = error {
                    Logger.error("Failed to fetch heart rate: \(error.localizedDescription)")
                    continuation.resume()
                    return
                }
                
                guard let hrSamples = samples as? [HKQuantitySample] else {
                    continuation.resume()
                    return
                }
                
                Task { @MainActor in
                    let startTime = workout.startDate.timeIntervalSince1970
                    var samples: [(time: TimeInterval, heartRate: Double)] = []
                    var hrValues: [Double] = []
                    
                    for sample in hrSamples {
                        let time = sample.startDate.timeIntervalSince1970 - startTime
                        let hr = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                        samples.append((time: time, heartRate: hr))
                        hrValues.append(hr)
                    }
                    
                    self.rawHeartRateSamples = samples
                    
                    // Downsample for chart performance
                    let downsampled = DataSmoothing.downsampleHeartRateSamples(
                        samples,
                        targetPoints: 500
                    )
                    
                    self.heartRateSamples = downsampled
                    self.chartSamples = downsampled
                    
                    if !hrValues.isEmpty {
                        self.averageHeartRate = hrValues.reduce(0, +) / Double(hrValues.count)
                        self.maxHeartRate = hrValues.max()
                    }
                    
                    Logger.debug("✅ Loaded \(samples.count) heart rate samples (downsampled to \(downsampled.count))")
                    
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func loadRouteData(for workout: HKWorkout) async {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)
        
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { [weak self] _, samples, error in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                if let error = error {
                    Logger.error("Failed to fetch route: \(error.localizedDescription)")
                    continuation.resume()
                    return
                }
                
                guard let routes = samples as? [HKWorkoutRoute], let route = routes.first else {
                    Logger.warning("️ No route data available")
                    continuation.resume()
                    return
                }
                
                Task {
                    await self.loadRouteLocations(route: route)
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func loadRouteLocations(route: HKWorkoutRoute) async {
        await withCheckedContinuation { continuation in
            var coordinates: [CLLocationCoordinate2D] = []
            var paces: [Double] = []
            
            let query = HKWorkoutRouteQuery(route: route) { [weak self] _, locations, done, error in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                if let error = error {
                    Logger.error("Failed to load route locations: \(error.localizedDescription)")
                    continuation.resume()
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
                    Task { @MainActor in
                        if !coordinates.isEmpty {
                            Logger.debug("✅ Loaded \(coordinates.count) route points with pace data")
                            self.routeCoordinates = coordinates
                            self.paceSamples = paces
                        }
                        continuation.resume()
                    }
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func loadSteps(for workout: HKWorkout) async {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )
        
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, statistics, error in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                if let error = error {
                    Logger.error("Failed to fetch steps: \(error.localizedDescription)")
                    continuation.resume()
                    return
                }
                
                if let sum = statistics?.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: .count()))
                    Task { @MainActor in
                        self.steps = steps
                        Logger.debug("✅ Loaded steps: \(steps)")
                        continuation.resume()
                    }
                } else {
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Map Generation
    
    private func generateMapSnapshot(coordinates: [CLLocationCoordinate2D]) async {
        guard !coordinates.isEmpty else { return }
        
        isLoadingMap = true
        defer { isLoadingMap = false }
        
        let region = regionForCoordinates(coordinates)
        
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = CGSize(width: 350, height: 200)
        options.scale = UIScreen.main.scale
        if #available(iOS 17.0, *) {
            options.preferredConfiguration = MKStandardMapConfiguration()
        }
        
        let snapshotter = MKMapSnapshotter(options: options)
        
        do {
            let snapshot = try await snapshotter.start()
            let image = addRouteToSnapshot(snapshot: snapshot, coordinates: coordinates)
            self.mapSnapshot = image
            Logger.debug("✅ Generated map snapshot with route overlay")
        } catch {
            Logger.error("Failed to generate map snapshot: \(error)")
        }
    }
    
    private func regionForCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    private func addRouteToSnapshot(snapshot: MKMapSnapshotter.Snapshot, coordinates: [CLLocationCoordinate2D]) -> UIImage {
        let image = snapshot.image
        
        UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
        image.draw(at: .zero)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return image
        }
        
        // Draw route polyline
        context.setStrokeColor(UIColor(Color.workout.route).cgColor)
        context.setLineWidth(3.0)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        for (index, coordinate) in coordinates.enumerated() {
            let point = snapshot.point(for: coordinate)
            
            if index == 0 {
                context.move(to: point)
            } else {
                context.addLine(to: point)
            }
        }
        
        context.strokePath()
        
        // Draw start marker (green)
        if let firstCoordinate = coordinates.first {
            let startPoint = snapshot.point(for: firstCoordinate)
            context.setFillColor(UIColor(Color.workout.startMarker).cgColor)
            context.fillEllipse(in: CGRect(x: startPoint.x - 6, y: startPoint.y - 6, width: 12, height: 12))
            context.setStrokeColor(UIColor.white.cgColor)
            context.setLineWidth(2.0)
            context.strokeEllipse(in: CGRect(x: startPoint.x - 6, y: startPoint.y - 6, width: 12, height: 12))
        }
        
        // Draw end marker (red)
        if let lastCoordinate = coordinates.last, coordinates.count > 1 {
            let endPoint = snapshot.point(for: lastCoordinate)
            context.setFillColor(UIColor(Color.workout.endMarker).cgColor)
            context.fillEllipse(in: CGRect(x: endPoint.x - 6, y: endPoint.y - 6, width: 12, height: 12))
            context.setStrokeColor(UIColor.white.cgColor)
            context.setLineWidth(2.0)
            context.strokeEllipse(in: CGRect(x: endPoint.x - 6, y: endPoint.y - 6, width: 12, height: 12))
        }
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return finalImage
    }
}
