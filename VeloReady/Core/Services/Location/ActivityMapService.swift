import Foundation
import MapKit
import SwiftUI

/// Service for generating activity map snapshots (Phase 2 - Activities Refactor)
/// Extracts map generation logic from ActivityDetailViewModel
@MainActor
final class ActivityMapService {
    static let shared = ActivityMapService()

    private init() {}

    // MARK: - Map Snapshot Generation

    /// Generate a map snapshot with route overlay
    /// - Parameters:
    ///   - coordinates: GPS coordinates to plot
    ///   - size: Size of the snapshot image
    ///   - displayScale: Display scale (default 3.0 for retina)
    /// - Returns: UIImage of map with route overlay, or nil if generation fails
    func generateMapSnapshot(
        coordinates: [CLLocationCoordinate2D],
        size: CGSize = CGSize(width: 350, height: 200),
        displayScale: CGFloat = 3.0
    ) async -> UIImage? {
        guard !coordinates.isEmpty else {
            Logger.trace("ℹ️ [ActivityMap] No coordinates to generate map")
            return nil
        }

        Logger.debug("🗺️ [ActivityMap] Generating map snapshot for \(coordinates.count) coordinates...")

        let region = regionForCoordinates(coordinates)

        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size
        options.scale = displayScale
        if #available(iOS 17.0, *) {
            options.preferredConfiguration = MKStandardMapConfiguration()
        }

        let snapshotter = MKMapSnapshotter(options: options)

        do {
            let snapshot = try await snapshotter.start()
            let image = addRouteToSnapshot(snapshot: snapshot, coordinates: coordinates)
            Logger.debug("✅ [ActivityMap] Generated map snapshot with route overlay")
            return image
        } catch {
            Logger.error("❌ [ActivityMap] Failed to generate map snapshot: \(error)")
            return nil
        }
    }

    // MARK: - Region Calculation

    /// Calculate map region that fits all coordinates
    /// - Parameter coordinates: GPS coordinates to fit
    /// - Returns: MKCoordinateRegion that contains all coordinates with 30% padding
    func regionForCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
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
            latitudeDelta: (maxLat - minLat) * 1.3,  // 30% padding
            longitudeDelta: (maxLon - minLon) * 1.3
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    // MARK: - Route Overlay

    /// Add route line and start/end markers to map snapshot
    /// - Parameters:
    ///   - snapshot: Base map snapshot
    ///   - coordinates: GPS coordinates to plot
    /// - Returns: UIImage with route overlay
    private func addRouteToSnapshot(
        snapshot: MKMapSnapshotter.Snapshot,
        coordinates: [CLLocationCoordinate2D]
    ) -> UIImage {
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
            drawMarker(
                context: context,
                at: startPoint,
                fillColor: UIColor(Color.workout.startMarker),
                radius: 6
            )
        }

        // Draw end marker (red)
        if let lastCoordinate = coordinates.last, coordinates.count > 1 {
            let endPoint = snapshot.point(for: lastCoordinate)
            drawMarker(
                context: context,
                at: endPoint,
                fillColor: UIColor(Color.workout.endMarker),
                radius: 6
            )
        }

        let finalImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()

        return finalImage
    }

    /// Draw a circular marker with white outline
    /// - Parameters:
    ///   - context: Graphics context
    ///   - point: Center point of marker
    ///   - fillColor: Fill color
    ///   - radius: Marker radius
    private func drawMarker(
        context: CGContext,
        at point: CGPoint,
        fillColor: UIColor,
        radius: CGFloat
    ) {
        let rect = CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        // Fill circle
        context.setFillColor(fillColor.cgColor)
        context.fillEllipse(in: rect)

        // White outline
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2.0)
        context.strokeEllipse(in: rect)
    }
}
