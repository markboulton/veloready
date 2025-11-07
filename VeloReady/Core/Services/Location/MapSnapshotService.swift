import Foundation
import MapKit
import UIKit

/// Service for generating map snapshots from GPS coordinates
@MainActor
class MapSnapshotService {
    static let shared = MapSnapshotService()
    
    // MARK: - Cache
    private var snapshotCache: [String: UIImage] = [:]
    private let cacheLimit = 50 // Keep last 50 map snapshots in memory
    
    // MARK: - Concurrency Control
    // Limit concurrent map generations to prevent memory issues
    // Increased to 6 to improve responsiveness in lists with many activities
    private let maxConcurrentGenerations = 6
    private var activeGenerations = 0
    private var pendingGenerations: [(continuation: CheckedContinuation<Void, Never>, activityId: String)] = []
    
    private init() {}
    
    /// Generate a placeholder map with activity info (fast, non-blocking)
    /// Used during progressive loading to show immediate visual feedback
    func generatePlaceholder(
        activityType: String = "Activity",
        size: CGSize = CGSize(width: 400, height: 300)
    ) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        // Draw a gradient background
        let colors = [UIColor.systemGray5.cgColor, UIColor.systemGray6.cgColor]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil) else {
            UIGraphicsEndImageContext()
            return nil
        }
        context.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: 0, y: size.height), options: [])
        
        // Draw map icon placeholder
        let iconSize: CGFloat = 40
        let iconRect = CGRect(
            x: (size.width - iconSize) / 2,
            y: (size.height - iconSize) / 2 - 10,
            width: iconSize,
            height: iconSize
        )
        
        // Draw a simple map icon shape
        UIColor.systemGray3.setFill()
        context.fillEllipse(in: iconRect)
        
        // Draw "Loading map..." text
        let text = "Loading map..."
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.systemGray
        ]
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2 + 30,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attributes)
        
        let placeholder = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return placeholder
    }
    
    /// Generate a map snapshot from GPS coordinates with caching
    /// - Parameters:
    ///   - coordinates: Array of GPS coordinates for the route
    ///   - activityId: Unique identifier for caching
    ///   - size: Size of the snapshot image
    /// - Returns: UIImage of the map snapshot, or nil if generation fails
    func generateSnapshot(
        from coordinates: [CLLocationCoordinate2D],
        activityId: String? = nil,
        size: CGSize = CGSize(width: 400, height: 300)
    ) async -> UIImage? {
        guard !coordinates.isEmpty else {
            Logger.debug("🗺️ No coordinates provided for map snapshot")
            return nil
        }
        
        // Check cache first (progressive loading optimization)
        if let activityId = activityId, let cached = snapshotCache[activityId] {
            Logger.debug("🗺️ ⚡ Using cached map snapshot for activity \(activityId)")
            return cached
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
            
            // Cache the generated snapshot for future use
            if let activityId = activityId {
                snapshotCache[activityId] = image
                // Enforce cache limit (LRU-style: keep most recent)
                if snapshotCache.count > cacheLimit {
                    // Remove oldest entries (simplified approach)
                    let keysToRemove = Array(snapshotCache.keys.prefix(snapshotCache.count - cacheLimit))
                    keysToRemove.forEach { snapshotCache.removeValue(forKey: $0) }
                    Logger.debug("🗺️ 🧹 Pruned map cache - removed \(keysToRemove.count) old snapshots")
                }
            }
            
            return image
        } catch {
            Logger.error("🗺️ Failed to generate map snapshot: \(error)")
            return nil
        }
    }
    
    /// Generate map snapshot asynchronously on background thread
    /// - Parameters:
    ///   - coordinates: Array of GPS coordinates for the route
    ///   - activityId: Unique identifier for caching
    ///   - size: Size of the snapshot image
    /// - Returns: UIImage of the map snapshot, or nil if generation fails
    func generateMapAsync(
        coordinates: [CLLocationCoordinate2D],
        activityId: String? = nil,
        size: CGSize = CGSize(width: 400, height: 300)
    ) async -> UIImage? {
        guard !coordinates.isEmpty else {
            Logger.debug("🗺️ [Background] No coordinates provided for map snapshot")
            return nil
        }
        
        // Check cache first on main actor
        if let activityId = activityId {
            if let cached = getCachedSnapshot(activityId: activityId) {
                Logger.debug("🗺️ [Background] ⚡ Using cached map snapshot for activity \(activityId)")
                return cached
            }
        }
        
        // Wait for available slot if at max concurrent generations
        await acquireGenerationSlot(activityId: activityId ?? "unknown")
        defer { Task { await releaseGenerationSlot() } }
        
        // Run map generation on background thread to avoid blocking UI
        return await Task.detached(priority: .utility) {
            guard !coordinates.isEmpty else {
                await Logger.debug("🗺️ [Background] No coordinates provided for map snapshot")
                return nil
            }
            
            await Logger.debug("🗺️ [Background] Generating map snapshot from \(coordinates.count) coordinates")
            
            // Calculate the region
            guard let region = self.calculateRegionBackground(from: coordinates) else {
                await Logger.debug("🗺️ [Background] Failed to calculate region from coordinates")
                return nil
            }
            
            // Validate size to prevent 0-height/width image creation
            let validatedSize = CGSize(
                width: max(size.width, 100),  // Minimum 100pt width
                height: max(size.height, 100)  // Minimum 100pt height
            )
            
            if validatedSize != size {
                await Logger.warning("🗺️ [Background] Invalid size \(size), using \(validatedSize)")
            }
            
            // Create map snapshot options
            let options = MKMapSnapshotter.Options()
            options.region = region
            options.size = validatedSize
            options.scale = await UIScreen.main.scale
            options.mapType = .standard
            options.showsBuildings = true
            
            // Use adaptive color scheme
            if #available(iOS 13.0, *) {
                let config = MKStandardMapConfiguration()
                options.preferredConfiguration = config
            }
            
            // Create snapshotter and generate snapshot
            let snapshotter = MKMapSnapshotter(options: options)
            
            do {
                let snapshot = try await snapshotter.start()
                
                // Draw the route on the snapshot (also on background thread)
                let image = self.drawRouteBackground(
                    on: snapshot,
                    coordinates: coordinates
                )
                
                await Logger.debug("🗺️ [Background] ✅ Map snapshot generated successfully")
                
                // Cache the generated snapshot
                if let activityId = activityId {
                    await self.cacheSnapshot(image: image, activityId: activityId)
                }
                
                return image
            } catch {
                await Logger.error("🗺️ [Background] Failed to generate map snapshot: \(error)")
                return nil
            }
        }.value
    }
    
    /// Clear the map snapshot cache
    func clearCache() {
        snapshotCache.removeAll()
        Logger.debug("🗺️ 🗑️ Cleared map snapshot cache")
    }
    
    // MARK: - Cache Helpers
    
    private func getCachedSnapshot(activityId: String) -> UIImage? {
        return snapshotCache[activityId]
    }
    
    private func cacheSnapshot(image: UIImage, activityId: String) {
        snapshotCache[activityId] = image
        // Enforce cache limit
        if snapshotCache.count > cacheLimit {
            let keysToRemove = Array(snapshotCache.keys.prefix(snapshotCache.count - cacheLimit))
            keysToRemove.forEach { snapshotCache.removeValue(forKey: $0) }
            Logger.debug("🗺️ 🧹 Pruned map cache - removed \(keysToRemove.count) old snapshots")
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
    
    /// Background-thread safe version of calculateRegion
    private nonisolated func calculateRegionBackground(from coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
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
    
    /// Background-thread safe version of drawRoute
    private nonisolated func drawRouteBackground(
        on snapshot: MKMapSnapshotter.Snapshot,
        coordinates: [CLLocationCoordinate2D]
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
    
    // MARK: - Concurrency Control Methods
    
    /// Acquire a slot for map generation (limits concurrent operations)
    private func acquireGenerationSlot(activityId: String) async {
        // If under limit, proceed immediately
        guard activeGenerations >= maxConcurrentGenerations else {
            activeGenerations += 1
            Logger.debug("🗺️ [Concurrency] Acquired slot for \(activityId) (\(activeGenerations)/\(maxConcurrentGenerations))")
            return
        }
        
        // Wait for a slot to become available
        Logger.debug("🗺️ [Concurrency] Waiting for slot for \(activityId) (\(activeGenerations)/\(maxConcurrentGenerations))")
        await withCheckedContinuation { continuation in
            pendingGenerations.append((continuation: continuation, activityId: activityId))
        }
        activeGenerations += 1
        Logger.debug("🗺️ [Concurrency] Acquired slot for \(activityId) after wait (\(activeGenerations)/\(maxConcurrentGenerations))")
    }
    
    /// Release a slot after map generation completes
    private func releaseGenerationSlot() async {
        activeGenerations -= 1
        Logger.debug("🗺️ [Concurrency] Released slot (\(activeGenerations)/\(maxConcurrentGenerations))")
        
        // Resume next pending generation if any
        if !pendingGenerations.isEmpty {
            let next = pendingGenerations.removeFirst()
            Logger.debug("🗺️ [Concurrency] Resuming pending generation for \(next.activityId)")
            next.continuation.resume()
        }
    }
}
