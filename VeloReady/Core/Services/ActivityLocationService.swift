import Foundation
import HealthKit
import CoreLocation

/// Errors that can occur during location fetching
enum LocationError: Error {
    case timeout
    case networkUnavailable
    case rateLimitExceeded
    case invalidCoordinate
    case noRouteData
}

/// Service for extracting and formatting location data from activities
class ActivityLocationService {
    static let shared = ActivityLocationService()
    
    // Reuse health store instance for performance
    private let healthStore: HKHealthStore
    
    // Cache locations to avoid repeated queries and geocoding
    private var locationCache: [UUID: String] = [:]
    private let cacheQueue = DispatchQueue(label: "com.veloready.locationCache")
    
    // Rate limiting for geocoding (Apple has undocumented limits)
    private var lastGeocodingTime: Date?
    private let minimumGeocodingInterval: TimeInterval = 1.0
    
    // Timeout for HealthKit queries
    private let queryTimeout: TimeInterval = 10.0
    
    private init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }
    
    /// Get location string for a Strava activity
    func getStravaLocation(_ stravaActivity: StravaActivity) async -> String? {
        guard let latlng = stravaActivity.start_latlng,
              latlng.count == 2 else {
            return nil
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latlng[0], longitude: latlng[1])
        return await reverseGeocode(coordinate: coordinate)
    }
    
    /// Get location string for an Apple Health workout with timeout
    func getHealthKitLocation(_ workout: HKWorkout) async -> String? {
        // Check cache first
        let cachedLocation = cacheQueue.sync { locationCache[workout.uuid] }
        if let cached = cachedLocation {
            return cached
        }
        
        // Add timeout to prevent hanging
        do {
            return try await withThrowingTaskGroup(of: String?.self) { group in
                // Add timeout task
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(self.queryTimeout * 1_000_000_000))
                    throw LocationError.timeout
                }
                
                // Add actual work
                group.addTask {
                    return await self.fetchHealthKitLocationInternal(workout)
                }
                
                // Return first result (either location or timeout)
                if let result = try await group.next() {
                    group.cancelAll()
                    return result
                }
                return nil
            }
        } catch {
            Logger.debug("Location fetch failed: \(error.localizedDescription)", category: .location)
            return nil
        }
    }
    
    /// Internal method to fetch location from HealthKit (no timeout)
    private func fetchHealthKitLocationInternal(_ workout: HKWorkout) async -> String? {
        
        // Query for workout route
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            
            let query = HKAnchoredObjectQuery(
                type: routeType,
                predicate: predicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit
            ) { _, samples, _, _, error in
                guard !hasResumed else { return }
                
                guard error == nil,
                      let routes = samples as? [HKWorkoutRoute],
                      let route = routes.first else {
                    hasResumed = true
                    continuation.resume(returning: nil)
                    return
                }
                
                // Query route data to get first location
                let routeQuery = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                    guard !hasResumed else { return }
                    
                    if let locations = locations, let firstLocation = locations.first {
                        hasResumed = true
                        // Reverse geocode the first location
                        Task {
                            let location = await self.reverseGeocode(coordinate: firstLocation.coordinate)
                            // Cache the result
                            if let location = location {
                                self.cacheQueue.async {
                                    self.locationCache[workout.uuid] = location
                                }
                            }
                            continuation.resume(returning: location)
                        }
                    } else if done {
                        hasResumed = true
                        continuation.resume(returning: nil)
                    }
                }
                
                self.healthStore.execute(routeQuery)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    /// Get location for a unified activity (tries all sources) with timeout
    func getActivityLocation(_ activity: UnifiedActivity) async -> String? {
        // Try Strava first
        if let stravaActivity = activity.stravaActivity {
            if let location = await getStravaLocation(stravaActivity) {
                return location
            }
        }
        
        // Try Apple Health workout route
        if let workout = activity.healthKitWorkout {
            if let location = await getHealthKitLocation(workout) {
                return location
            }
        }
        
        return nil
    }
    
    /// Reverse geocode a coordinate to "City, Country" format with rate limiting
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> String? {
        // Rate limiting - Apple has undocumented geocoding limits
        if let lastTime = lastGeocodingTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minimumGeocodingInterval {
                let delay = minimumGeocodingInterval - elapsed
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        lastGeocodingTime = Date()
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            
            // Format as "City, Country" (e.g., "Llantwit Major, UK")
            var components: [String] = []
            
            if let locality = placemark.locality {
                components.append(locality)
            } else if let subLocality = placemark.subLocality {
                components.append(subLocality)
            }
            
            if let countryCode = placemark.isoCountryCode {
                components.append(countryCode)
            }
            
            return components.isEmpty ? nil : components.joined(separator: ", ")
        } catch {
            // Silent failure - location is nice-to-have, not critical
            Logger.debug("Reverse geocoding failed: \(error.localizedDescription)", category: .location)
            return nil
        }
    }
    
    /// Clear the location cache (useful for testing or memory pressure)
    func clearCache() {
        cacheQueue.async {
            self.locationCache.removeAll()
        }
    }
}
