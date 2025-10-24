import SwiftUI
import MapKit

/// Interactive map view that allows pinch-to-zoom and panning
struct InteractiveMapView: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]
    let heartRates: [Double]?  // Optional heart rate data for gradient
    @Environment(\.colorScheme) var colorScheme
    @State private var isLocked: Bool = true  // Start locked
    
    init(coordinates: [CLLocationCoordinate2D], heartRates: [Double]? = nil) {
        self.coordinates = coordinates
        self.heartRates = heartRates
    }
    
    func makeUIView(context: Context) -> UIView {
        print("🗺️ [InteractiveMapView] makeUIView called")
        print("🗺️ [InteractiveMapView] Coordinates count: \(coordinates.count)")
        print("🗺️ [InteractiveMapView] Heart rates count: \(heartRates?.count ?? 0)")
        if let hrs = heartRates, !hrs.isEmpty {
            let avgHR = hrs.reduce(0, +) / Double(hrs.count)
            print("🗺️ [InteractiveMapView] Average HR: \(avgHR) bpm")
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
        
        // Add route overlay
        if !coordinates.isEmpty {
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
            
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
        Coordinator(heartRates: heartRates)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        weak var mapView: MKMapView?
        weak var lockButton: UIButton?
        var isLocked = true
        var currentColorScheme: ColorScheme = .light
        let heartRates: [Double]?
        
        init(heartRates: [Double]?) {
            self.heartRates = heartRates
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
            print("🗺️ [Coordinator] rendererFor overlay called")
            
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                print("🗺️ [Coordinator] Heart rates available: \(heartRates != nil)")
                print("🗺️ [Coordinator] Heart rates count: \(heartRates?.count ?? 0)")
                
                // If we have heart rate data, use gradient coloring
                if let heartRates = heartRates, !heartRates.isEmpty {
                    // Use gradient from green (low HR) to red (high HR)
                    // For now, use average HR to determine color
                    let avgHR = heartRates.reduce(0, +) / Double(heartRates.count)
                    let color = colorForHeartRate(avgHR)
                    print("🗺️ [Coordinator] ✅ Using HR gradient - Avg HR: \(avgHR) bpm, Color: \(color)")
                    renderer.strokeColor = color
                } else {
                    // Default blue color
                    print("🗺️ [Coordinator] ❌ No HR data - using default blue")
                    renderer.strokeColor = .systemBlue
                }
                
                renderer.lineWidth = 4.0
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        /// Get color for heart rate value (green → yellow → amber → red)
        /// Uses standard HR zones: Z1-Z2 green, Z3 yellow, Z4 orange, Z5 red
        private func colorForHeartRate(_ hr: Double) -> UIColor {
            // Estimate max HR if not known (220 - age, assume age 35 = 185 max HR)
            let estimatedMaxHR = 185.0
            let hrPercent = (hr / estimatedMaxHR) * 100
            
            // HR Zones based on % of max HR:
            // Z1-Z2 (50-70%): Green (easy/recovery)
            // Z3 (70-80%): Yellow (tempo)
            // Z4 (80-90%): Orange (threshold)
            // Z5 (90-100%): Red (VO2 max)
            
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
}
