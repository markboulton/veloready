import Foundation
import CoreLocation

/// Service for reverse geocoding GPS coordinates to location names
@MainActor
class LocationGeocodingService {
    static let shared = LocationGeocodingService()

    private var cache: [String: String] = [:]
    private let geocoder = CLGeocoder()

    private init() {}

    /// Get location name from GPS coordinates (with caching)
    /// - Parameter coordinate: GPS coordinate to geocode
    /// - Returns: Location string (e.g., "Cardiff, Wales") or nil if geocoding fails
    func getLocationName(from coordinate: CLLocationCoordinate2D) async -> String? {
        let cacheKey = "\(coordinate.latitude),\(coordinate.longitude)"

        // Check cache first
        if let cached = cache[cacheKey] {
            Logger.debug("🗺️ Location cache hit: \(cached)")
            return cached
        }

        Logger.debug("🗺️ Geocoding location: \(coordinate.latitude), \(coordinate.longitude)")

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)

            guard let placemark = placemarks.first else {
                Logger.debug("🗺️ No placemark found")
                return nil
            }

            let locationString = formatPlacemark(placemark)

            // Cache the result
            cache[cacheKey] = locationString

            Logger.debug("🗺️ ✅ Geocoded location: \(locationString)")
            return locationString
        } catch {
            Logger.error("🗺️ Geocoding failed: \(error)")
            return nil
        }
    }
    
    /// Get location name from the start of a route
    /// - Parameter coordinates: Array of GPS coordinates
    /// - Returns: Location string for the start point
    func getStartLocation(from coordinates: [CLLocationCoordinate2D]) async -> String? {
        guard let firstCoordinate = coordinates.first else { return nil }
        return await getLocationName(from: firstCoordinate)
    }
    
    // MARK: - Private Helpers
    
    /// Format placemark into a readable location string
    private func formatPlacemark(_ placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        // Priority order: locality (city), administrativeArea (state/region), country
        let locality = placemark.locality
        if let locality = locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            // Only add if different from locality
            if locality != administrativeArea {
                components.append(administrativeArea)
            }
        }
        
        // Only add country if we don't have enough detail
        if components.isEmpty, let country = placemark.country {
            components.append(country)
        }
        
        // Fallback to subLocality or name
        if components.isEmpty {
            if let subLocality = placemark.subLocality {
                components.append(subLocality)
            } else if let name = placemark.name {
                components.append(name)
            }
        }
        
        return components.joined(separator: ", ")
    }
    
    /// Clear the geocoding cache
    func clearCache() {
        cache.removeAll()
        Logger.debug("🗺️ Geocoding cache cleared")
    }
}
