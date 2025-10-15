import Foundation
import HealthKit
import CoreLocation

/// Service for extracting and formatting location data from activities
class ActivityLocationService {
    static let shared = ActivityLocationService()
    
    private init() {}
    
    /// Get location string for a Strava activity
    func getStravaLocation(_ stravaActivity: StravaActivity) async -> String? {
        guard let latlng = stravaActivity.start_latlng,
              latlng.count == 2 else {
            return nil
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latlng[0], longitude: latlng[1])
        return await reverseGeocode(coordinate: coordinate)
    }
    
    /// Get location string for an Apple Health workout
    func getHealthKitLocation(_ workout: HKWorkout) async -> String? {
        let healthStore = HKHealthStore()
        
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
                            continuation.resume(returning: location)
                        }
                    } else if done {
                        hasResumed = true
                        continuation.resume(returning: nil)
                    }
                }
                
                healthStore.execute(routeQuery)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Get location for a unified activity (tries all sources)
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
    
    /// Reverse geocode a coordinate to "City, Country" format
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> String? {
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
            print("⚠️ Reverse geocoding failed: \(error)")
            return nil
        }
    }
}
