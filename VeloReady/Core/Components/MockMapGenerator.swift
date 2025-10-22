import UIKit
import MapKit
import CoreLocation

#if DEBUG
/// Generates mock map snapshots for preview/debug purposes
class MockMapGenerator {
    static let shared = MockMapGenerator()
    
    private init() {}
    
    /// Generate a mock map snapshot for a given location
    func generateMockMap(
        center: CLLocationCoordinate2D,
        routeCoordinates: [CLLocationCoordinate2D],
        size: CGSize = CGSize(width: 400, height: 120)
    ) async -> UIImage? {
        let mapSnapshotOptions = MKMapSnapshotter.Options()
        
        // Calculate region from coordinates
        let latitudes = routeCoordinates.map { $0.latitude }
        let longitudes = routeCoordinates.map { $0.longitude }
        
        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else { return nil }
        
        let centerCoord = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )
        
        mapSnapshotOptions.region = MKCoordinateRegion(center: centerCoord, span: span)
        mapSnapshotOptions.size = size
        mapSnapshotOptions.scale = UIScreen.main.scale
        
        let snapshotter = MKMapSnapshotter(options: mapSnapshotOptions)
        
        do {
            let snapshot = try await snapshotter.start()
            
            // Draw route on snapshot
            let image = UIGraphicsImageRenderer(size: size).image { context in
                snapshot.image.draw(at: .zero)
                
                let path = UIBezierPath()
                if let firstCoord = routeCoordinates.first {
                    let firstPoint = snapshot.point(for: firstCoord)
                    path.move(to: firstPoint)
                    
                    for coordinate in routeCoordinates.dropFirst() {
                        let point = snapshot.point(for: coordinate)
                        path.addLine(to: point)
                    }
                }
                
                UIColor.systemBlue.setStroke()
                path.lineWidth = 3
                path.stroke()
            }
            
            return image
        } catch {
            print("Failed to generate mock map: \(error)")
            return nil
        }
    }
    
    /// Generate mock route coordinates for a ride
    static func mockRideRoute() -> [CLLocationCoordinate2D] {
        // Cardiff to Llantwit Major route (approximate)
        let start = CLLocationCoordinate2D(latitude: 51.4816, longitude: -3.1791)
        let waypoint1 = CLLocationCoordinate2D(latitude: 51.4700, longitude: -3.2500)
        let waypoint2 = CLLocationCoordinate2D(latitude: 51.4500, longitude: -3.3200)
        let waypoint3 = CLLocationCoordinate2D(latitude: 51.4200, longitude: -3.4000)
        let end = CLLocationCoordinate2D(latitude: 51.4082, longitude: -3.4847)
        
        // Interpolate points between waypoints for smoother route
        var coordinates: [CLLocationCoordinate2D] = []
        
        let waypoints = [start, waypoint1, waypoint2, waypoint3, end]
        for i in 0..<(waypoints.count - 1) {
            let from = waypoints[i]
            let to = waypoints[i + 1]
            
            // Add 20 interpolated points between each waypoint
            for j in 0...20 {
                let ratio = Double(j) / 20.0
                let lat = from.latitude + (to.latitude - from.latitude) * ratio
                let lon = from.longitude + (to.longitude - from.longitude) * ratio
                coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
        
        return coordinates
    }
    
    /// Generate mock route coordinates for a walk
    static func mockWalkRoute() -> [CLLocationCoordinate2D] {
        // Shorter local walk route
        let start = CLLocationCoordinate2D(latitude: 51.4816, longitude: -3.1791)
        let waypoint1 = CLLocationCoordinate2D(latitude: 51.4830, longitude: -3.1750)
        let waypoint2 = CLLocationCoordinate2D(latitude: 51.4850, longitude: -3.1780)
        let end = CLLocationCoordinate2D(latitude: 51.4820, longitude: -3.1800)
        
        var coordinates: [CLLocationCoordinate2D] = []
        
        let waypoints = [start, waypoint1, waypoint2, end]
        for i in 0..<(waypoints.count - 1) {
            let from = waypoints[i]
            let to = waypoints[i + 1]
            
            for j in 0...15 {
                let ratio = Double(j) / 15.0
                let lat = from.latitude + (to.latitude - from.latitude) * ratio
                let lon = from.longitude + (to.longitude - from.longitude) * ratio
                coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
        
        return coordinates
    }
}
#endif
