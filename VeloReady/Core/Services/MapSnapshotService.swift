import Foundation
import MapKit
import UIKit

/// Service for generating map snapshots from GPS coordinates
@MainActor
class MapSnapshotService {
    static let shared = MapSnapshotService()
    
    private init() {}
    
    /// Generate a map snapshot from GPS coordinates
    /// - Parameters:
    ///   - coordinates: Array of GPS coordinates for the route
    ///   - size: Size of the snapshot image
    /// - Returns: UIImage of the map snapshot, or nil if generation fails
    func generateSnapshot(
        from coordinates: [CLLocationCoordinate2D],
        size: CGSize = CGSize(width: 400, height: 300)
    ) async -> UIImage? {
        guard !coordinates.isEmpty else {
            Logger.debug("🗺️ No coordinates provided for map snapshot")
            return nil
        }
        
        Logger.debug("🗺️ Generating map snapshot from \(coordinates.count) coordinates")
        
        // Calculate the region that encompasses all coordinates
        guard let region = calculateRegion(from: coordinates) else {
            Logger.debug("🗺️ Failed to calculate region from coordinates")
            return nil
        }
        
        // Create map snapshot options
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size
        options.scale = UIScreen.main.scale
        options.mapType = .standard
        options.showsBuildings = true
        
        // Use adaptive color scheme (light/dark based on system appearance)
        if #available(iOS 13.0, *) {
            let config = MKStandardMapConfiguration()
            options.preferredConfiguration = config
        }
        
        // Create snapshotter
        let snapshotter = MKMapSnapshotter(options: options)
        
        do {
            let snapshot = try await snapshotter.start()
            
            // Draw the route on the snapshot
            let image = drawRoute(
                on: snapshot,
                coordinates: coordinates,
                mapRect: snapshot.image.size
            )
            
            Logger.debug("🗺️ ✅ Map snapshot generated successfully")
            return image
        } catch {
            Logger.error("🗺️ Failed to generate map snapshot: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Helpers
    
    /// Calculate the map region that encompasses all coordinates
    private func calculateRegion(from coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }
        
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
            latitudeDelta: (maxLat - minLat) * 1.3, // Add 30% padding
            longitudeDelta: (maxLon - minLon) * 1.3
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    /// Draw the route polyline on the snapshot image
    private func drawRoute(
        on snapshot: MKMapSnapshotter.Snapshot,
        coordinates: [CLLocationCoordinate2D],
        mapRect: CGSize
    ) -> UIImage {
        let image = snapshot.image
        
        UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
        image.draw(at: .zero)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return image
        }
        
        // Convert coordinates to points on the image
        var points: [CGPoint] = []
        for coordinate in coordinates {
            let point = snapshot.point(for: coordinate)
            points.append(point)
        }
        
        // Draw the route
        if points.count > 1 {
            context.setStrokeColor(UIColor.systemBlue.cgColor)
            context.setLineWidth(3.0)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            
            context.move(to: points[0])
            for i in 1..<points.count {
                context.addLine(to: points[i])
            }
            context.strokePath()
            
            // Draw start marker (green circle)
            let startPoint = points[0]
            context.setFillColor(UIColor.systemGreen.cgColor)
            context.fillEllipse(in: CGRect(
                x: startPoint.x - 6,
                y: startPoint.y - 6,
                width: 12,
                height: 12
            ))
            context.setStrokeColor(UIColor.white.cgColor)
            context.setLineWidth(2.0)
            context.strokeEllipse(in: CGRect(
                x: startPoint.x - 6,
                y: startPoint.y - 6,
                width: 12,
                height: 12
            ))
            
            // Draw end marker (red circle)
            let endPoint = points[points.count - 1]
            context.setFillColor(UIColor.systemRed.cgColor)
            context.fillEllipse(in: CGRect(
                x: endPoint.x - 6,
                y: endPoint.y - 6,
                width: 12,
                height: 12
            ))
            context.setStrokeColor(UIColor.white.cgColor)
            context.setLineWidth(2.0)
            context.strokeEllipse(in: CGRect(
                x: endPoint.x - 6,
                y: endPoint.y - 6,
                width: 12,
                height: 12
            ))
        }
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resultImage
    }
}
