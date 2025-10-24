import SwiftUI
import MapKit

/// Data type for gradient coloring
enum GradientDataType {
    case heartRate([Double])  // HR values in bpm
    case pace([Double])       // Pace values in min/km
    case none
}

/// Interactive map view that allows pinch-to-zoom and panning with gradient coloring
struct InteractiveMapView: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]
    let gradientData: GradientDataType
    @Environment(\.colorScheme) var colorScheme
    @State private var isLocked: Bool = true  // Start locked
    
    init(coordinates: [CLLocationCoordinate2D], heartRates: [Double]? = nil, paces: [Double]? = nil) {
        // Downsample for performance if needed (max 500 segments)
        let maxSegments = 500
        if coordinates.count > maxSegments {
            let step = coordinates.count / maxSegments
            self.coordinates = stride(from: 0, to: coordinates.count, by: max(step, 1)).map { coordinates[$0] }
            
            // Downsample gradient data to match
            if let unwrappedPaces = paces, !unwrappedPaces.isEmpty {
                let downsampledPaces = stride(from: 0, to: unwrappedPaces.count, by: max(step, 1)).map { unwrappedPaces[$0] }
                self.gradientData = .pace(downsampledPaces)
            } else if let unwrappedHRs = heartRates, !unwrappedHRs.isEmpty {
                let downsampledHRs = stride(from: 0, to: unwrappedHRs.count, by: max(step, 1)).map { unwrappedHRs[$0] }
                self.gradientData = .heartRate(downsampledHRs)
            } else {
                self.gradientData = .none
            }
            
            print("🗺️ [Performance] Downsampled \(coordinates.count) → \(self.coordinates.count) coordinates for map rendering")
        } else {
            self.coordinates = coordinates
            if let paces = paces, !paces.isEmpty {
                self.gradientData = .pace(paces)
            } else if let hrs = heartRates, !hrs.isEmpty {
                self.gradientData = .heartRate(hrs)
            } else {
                self.gradientData = .none
            }
        }
    }
    
    func makeUIView(context: Context) -> UIView {
        print("🗺️ [InteractiveMapView] makeUIView called")
        print("🗺️ [InteractiveMapView] Coordinates count: \(coordinates.count)")
        
        switch gradientData {
        case .heartRate(let hrs):
            let avgHR = hrs.reduce(0, +) / Double(hrs.count)
            print("🗺️ [InteractiveMapView] Using HR gradient: \(hrs.count) samples, avg \(avgHR) bpm")
        case .pace(let paces):
            let avgPace = paces.reduce(0, +) / Double(paces.count)
            print("🗺️ [InteractiveMapView] Using pace gradient: \(paces.count) samples, avg \(avgPace) min/km")
        case .none:
            print("🗺️ [InteractiveMapView] No gradient data - using default blue")
        }
        
        let containerView = UIView()
        
        let mapView = MKMapView()
        mapView.isZoomEnabled = false  // Start locked
        mapView.isScrollEnabled = false  // Start locked
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        // Use adaptive color scheme (light/dark based on system appearance)
        if #available(iOS 13.0, *) {
            let config = MKStandardMapConfiguration()
            mapView.preferredConfiguration = config
        }
        
        // Add route overlay(s) - segmented for gradient
        if !coordinates.isEmpty {
            let overlays = createGradientOverlays(coordinates: coordinates, gradientData: gradientData)
            mapView.addOverlays(overlays)
            
            // Fit region to show entire route
            let region = regionForCoordinates(coordinates)
            mapView.setRegion(region, animated: false)
            
            // Add start/end annotations
            if let first = coordinates.first {
                let startAnnotation = MKPointAnnotation()
                startAnnotation.coordinate = first
                startAnnotation.title = CommonContent.MapAnnotations.start
                mapView.addAnnotation(startAnnotation)
            }
            
            if let last = coordinates.last, coordinates.count > 1 {
                let endAnnotation = MKPointAnnotation()
                endAnnotation.coordinate = last
                endAnnotation.title = CommonContent.MapAnnotations.end
                mapView.addAnnotation(endAnnotation)
            }
        }
        
        mapView.delegate = context.coordinator
        containerView.addSubview(mapView)
        
        // Add lock/unlock button
        let button = UIButton(type: .system)
        // Reduce icon size by 50%
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        button.setImage(UIImage(systemName: Icons.System.lock, withConfiguration: config), for: .normal)
        
        // Adaptive colors for dark/light mode
        if #available(iOS 13.0, *) {
            button.tintColor = UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? .white : .black
            }
            button.backgroundColor = UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? .black : .white
            }
        } else {
            button.tintColor = .white
            button.backgroundColor = .black
        }
        
        button.layer.cornerRadius = 15  // 75% smaller (was 20, now 30x30)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(context.coordinator, action: #selector(Coordinator.toggleLock), for: .touchUpInside)
        containerView.addSubview(button)
        
        context.coordinator.lockButton = button
        context.coordinator.mapView = mapView
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: containerView.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            button.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            button.widthAnchor.constraint(equalToConstant: 30),  // 75% smaller
            button.heightAnchor.constraint(equalToConstant: 30)  // 75% smaller
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update map configuration when color scheme changes
        guard let mapView = context.coordinator.mapView else { return }
        
        let config = MKStandardMapConfiguration()
        mapView.preferredConfiguration = config
        
        // Update lock button colors
        if let button = context.coordinator.lockButton {
            button.tintColor = colorScheme == .dark ? .white : .black
            button.backgroundColor = colorScheme == .dark ? .black : .white
        }
        
        // Store current color scheme in coordinator
        context.coordinator.currentColorScheme = colorScheme
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(gradientData: gradientData)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        weak var mapView: MKMapView?
        weak var lockButton: UIButton?
        var isLocked = true
        var currentColorScheme: ColorScheme = .light
        let gradientData: GradientDataType
        
        init(gradientData: GradientDataType) {
            self.gradientData = gradientData
            super.init()
        }
        
        @objc func toggleLock() {
            isLocked.toggle()
            mapView?.isZoomEnabled = !isLocked
            mapView?.isScrollEnabled = !isLocked
            
            let iconName = isLocked ? "lock.fill" : "lock.open.fill"
            let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
            lockButton?.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let coloredPolyline = overlay as? ColoredPolyline {
                let renderer = MKPolylineRenderer(polyline: coloredPolyline)
                renderer.strokeColor = coloredPolyline.color
                renderer.lineWidth = 4.0
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = CommonContent.MapAnnotations.routePoint
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }
            
            // Custom marker based on title
            if annotation.title == CommonContent.MapAnnotations.start {
                let size: CGFloat = 12
                let view = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
                view.backgroundColor = .systemGreen
                view.layer.cornerRadius = size / 2
                view.layer.borderWidth = 2
                view.layer.borderColor = UIColor.white.cgColor
                
                UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
                view.layer.render(in: UIGraphicsGetCurrentContext()!)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                annotationView?.image = image
                annotationView?.centerOffset = CGPoint(x: 0, y: -size/2)
            } else if annotation.title == CommonContent.MapAnnotations.end {
                let size: CGFloat = 12
                let view = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
                view.backgroundColor = .systemRed
                view.layer.cornerRadius = size / 2
                view.layer.borderWidth = 2
                view.layer.borderColor = UIColor.white.cgColor
                
                UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
                view.layer.render(in: UIGraphicsGetCurrentContext()!)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                annotationView?.image = image
                annotationView?.centerOffset = CGPoint(x: 0, y: -size/2)
            }
            
            return annotationView
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
    
    /// Create gradient overlays by segmenting the route
    private func createGradientOverlays(coordinates: [CLLocationCoordinate2D], gradientData: GradientDataType) -> [MKOverlay] {
        guard coordinates.count > 1 else { return [] }
        
        switch gradientData {
        case .heartRate(let hrs):
            return createHRGradientSegments(coordinates: coordinates, heartRates: hrs)
        case .pace(let paces):
            return createPaceGradientSegments(coordinates: coordinates, paces: paces)
        case .none:
            // Single blue polyline
            return [MKPolyline(coordinates: coordinates, count: coordinates.count)]
        }
    }
    
    /// Create HR gradient segments
    private func createHRGradientSegments(coordinates: [CLLocationCoordinate2D], heartRates: [Double]) -> [MKOverlay] {
        guard coordinates.count == heartRates.count, coordinates.count > 1 else {
            return [MKPolyline(coordinates: coordinates, count: coordinates.count)]
        }
        
        var segments: [MKOverlay] = []
        
        // Create segments between each pair of points
        for i in 0..<(coordinates.count - 1) {
            let segmentCoords = [coordinates[i], coordinates[i + 1]]
            let avgHR = (heartRates[i] + heartRates[i + 1]) / 2
            let color = colorForHeartRate(avgHR)
            
            let polyline = ColoredPolyline(coordinates: segmentCoords, count: 2)
            polyline.color = color
            segments.append(polyline)
        }
        
        print("🗺️ [Gradient] Created \(segments.count) HR gradient segments")
        return segments
    }
    
    /// Create pace gradient segments
    private func createPaceGradientSegments(coordinates: [CLLocationCoordinate2D], paces: [Double]) -> [MKOverlay] {
        guard coordinates.count == paces.count, coordinates.count > 1 else {
            return [MKPolyline(coordinates: coordinates, count: coordinates.count)]
        }
        
        var segments: [MKOverlay] = []
        
        // Create segments between each pair of points
        for i in 0..<(coordinates.count - 1) {
            let segmentCoords = [coordinates[i], coordinates[i + 1]]
            let avgPace = (paces[i] + paces[i + 1]) / 2
            let color = colorForPace(avgPace)
            
            let polyline = ColoredPolyline(coordinates: segmentCoords, count: 2)
            polyline.color = color
            segments.append(polyline)
        }
        
        print("🗺️ [Gradient] Created \(segments.count) pace gradient segments")
        return segments
    }
    
    /// Get color for heart rate value (green → yellow → orange → red)
    private func colorForHeartRate(_ hr: Double) -> UIColor {
        let estimatedMaxHR = 185.0
        let hrPercent = (hr / estimatedMaxHR) * 100
        
        switch hrPercent {
        case ..<70:
            return UIColor.systemGreen
        case 70..<80:
            return UIColor.systemYellow
        case 80..<90:
            return UIColor.systemOrange
        default:
            return UIColor.systemRed
        }
    }
    
    /// Get color for pace value (green = fast → red = slow)
    private func colorForPace(_ pace: Double) -> UIColor {
        // Pace in min/km
        // Fast: <5:00/km, Medium: 5:00-6:30/km, Slow: >6:30/km
        switch pace {
        case ..<5.0:
            return UIColor.systemGreen  // Fast
        case 5.0..<5.75:
            return UIColor.systemYellow  // Medium-fast
        case 5.75..<6.5:
            return UIColor.systemOrange  // Medium-slow
        default:
            return UIColor.systemRed  // Slow
        }
    }
}

/// Custom polyline that stores its color
class ColoredPolyline: MKPolyline {
    var color: UIColor = .systemBlue
}
