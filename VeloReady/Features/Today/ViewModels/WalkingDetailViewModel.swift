import Foundation
import HealthKit
import MapKit
import SwiftUI

@MainActor
@Observable
final class WalkingDetailViewModel {
    var heartRateSamples: [(time: TimeInterval, heartRate: Double)] = []
    var routeCoordinates: [CLLocationCoordinate2D]?
    var paceSamples: [Double] = []  // Pace in min/km for each GPS point
    var hasRoute = false
    var mapSnapshot: UIImage?
    var isLoadingMap = false
    var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var steps: Int = 0
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var averagePace: String?
    var elevationGain: Double?
    var weather: String?
    
    private let healthStore = HKHealthStore()
    
    func loadWorkoutData(workout: HKWorkout) async {
        Logger.debug("🏃 Loading workout data for: \(workout.workoutActivityType.name)")
        
        // Load heart rate data
        await loadHeartRateData(for: workout)
        
        // Load route data
        await loadRouteData(for: workout)
        
        // Load steps
        await loadSteps(for: workout)
        
        // Calculate derived metrics
        calculateDerivedMetrics(workout: workout)
        
        // Generate map snapshot with route overlay
        if hasRoute, let coordinates = routeCoordinates {
            await generateMapSnapshot(coordinates: coordinates)
        }
    }
    
    // MARK: - Heart Rate Data
    
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
                    
                    self.heartRateSamples = samples
                    
                    if !hrValues.isEmpty {
                        self.averageHeartRate = hrValues.reduce(0, +) / Double(hrValues.count)
                        self.maxHeartRate = hrValues.max()
                    }
                    
                    Logger.debug("✅ Loaded \(samples.count) heart rate samples")
                    Logger.debug("   Avg HR: \(self.averageHeartRate ?? 0), Max HR: \(self.maxHeartRate ?? 0)")
                    
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Route Data
    
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
                
                // Load route locations
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
                    
                    // Calculate pace from speed (m/s to min/km)
                    for location in locations {
                        let speedMps = location.speed  // meters per second
                        if speedMps > 0 {
                            // Convert m/s to min/km: (1000m / speed) / 60s
                            let paceMinPerKm = (1000.0 / speedMps) / 60.0
                            paces.append(paceMinPerKm)
                        } else {
                            // Default to 10 min/km if speed is 0 or negative
                            paces.append(10.0)
                        }
                    }
                }
                
                if done {
                    Task { @MainActor in
                        self.routeCoordinates = coordinates
                        self.paceSamples = paces
                        self.hasRoute = !coordinates.isEmpty
                        
                        if let first = coordinates.first {
                            self.mapRegion = MKCoordinateRegion(
                                center: first,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        }
                        
                        Logger.debug("✅ Loaded \(coordinates.count) route points with pace data")
                        if !paces.isEmpty {
                            let avgPace = paces.reduce(0, +) / Double(paces.count)
                            Logger.debug("   Average pace: \(String(format: "%.2f", avgPace)) min/km")
                        }
                        continuation.resume()
                    }
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Steps Data
    
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
    
    // MARK: - Derived Metrics
    
    private func calculateDerivedMetrics(workout: HKWorkout) {
        // Calculate average pace (min/km)
        if let distance = workout.totalDistance?.doubleValue(for: .meter()), distance > 0 {
            let km = distance / 1000.0
            let minutes = workout.duration / 60.0
            let paceMinPerKm = minutes / km
            
            let mins = Int(paceMinPerKm)
            let secs = Int((paceMinPerKm - Double(mins)) * 60)
            averagePace = String(format: "%d:%02d /km", mins, secs)
        }
        
        // Elevation gain (if available from metadata)
        if let metadata = workout.metadata,
           let elevation = metadata[HKMetadataKeyElevationAscended] as? HKQuantity {
            elevationGain = elevation.doubleValue(for: .meter())
        }
        
        // Weather (if available from metadata)
        if let metadata = workout.metadata,
           let temp = metadata[HKMetadataKeyWeatherTemperature] as? HKQuantity {
            let celsius = temp.doubleValue(for: .degreeCelsius())
            weather = String(format: "%.0f°C", celsius)
        }
    }
    
    // MARK: - Map Snapshot Generation
    
    private func generateMapSnapshot(coordinates: [CLLocationCoordinate2D], displayScale: CGFloat = 3.0) async {
        guard !coordinates.isEmpty else { return }

        isLoadingMap = true
        defer { isLoadingMap = false }

        // Calculate region to fit all coordinates
        let region = regionForCoordinates(coordinates)

        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = CGSize(width: 350, height: 200)
        options.scale = displayScale
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
