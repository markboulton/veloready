import SwiftUI
import HealthKit
import CoreLocation

/// Shared activity row view used in both Today and Activities list
struct SharedActivityRowView: View {
    let activity: UnifiedActivity
    @State private var showingRPESheet = false
    @State private var hasRPE = false
    @State private var locationString: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity Details
            VStack(alignment: .leading, spacing: 4) {
                // Activity name
                Text(activity.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                // Date/time with icon and optional location
                HStack(spacing: 6) {
                    Image(systemName: activityIcon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatSmartDateWithLocation(activity.startDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Compact RPE indicator for strength workouts (always show for testing)
            if shouldShowRPEButton || true { // Always show for testing
                Button(action: { showingRPESheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: hasRPE ? "checkmark.circle.fill" : "plus.circle")
                            .font(.caption)
                        Text(hasRPE ? "RPE" : "Add")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(hasRPE ? ColorScale.greenAccent : ColorScale.gray600)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(hasRPE ? ColorScale.greenAccent.opacity(0.1) : ColorScale.gray200)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onAppear {
            checkRPEStatus()
            Task {
                await loadLocation()
            }
        }
        .sheet(isPresented: $showingRPESheet) {
            if let workout = activity.healthKitWorkout {
                RPEInputSheet(workout: workout) {
                    hasRPE = true
                }
            }
        }
    }
    
    // MARK: - Formatting Helpers
    
    private func formatSmartDateWithLocation(_ date: Date) -> String {
        let calendar = Calendar.current
        
        var dateString: String
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            dateString = "Today at \(timeFormatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            dateString = "Yesterday at \(timeFormatter.string(from: date))"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMM yyyy 'at' HH:mm"
            dateString = dateFormatter.string(from: date)
        }
        
        if let location = locationString {
            return "\(dateString) · \(location)"
        } else {
            return dateString
        }
    }
    
    private func loadLocation() async {
        // Try Strava first (has start_latlng)
        if let stravaActivity = activity.stravaActivity {
            if let location = await getStravaLocation(stravaActivity) {
                await MainActor.run {
                    locationString = location
                }
                return
            }
        }
        
        // Try Apple Health workout route
        if let workout = activity.healthKitWorkout {
            if let location = await getHealthKitLocation(workout) {
                await MainActor.run {
                    locationString = location
                }
                return
            }
        }
    }
    
    private func getStravaLocation(_ stravaActivity: StravaActivity) async -> String? {
        // Strava activities have start_latlng in the summary
        guard let latlng = stravaActivity.start_latlng,
              latlng.count == 2 else {
            return nil
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latlng[0], longitude: latlng[1])
        return await reverseGeocode(coordinate: coordinate)
    }
    
    private func getHealthKitLocation(_ workout: HKWorkout) async -> String? {
        let healthStore = HKHealthStore()
        
        // Query for workout route
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)
        
        return await withCheckedContinuation { continuation in
            let query = HKAnchoredObjectQuery(
                type: routeType,
                predicate: predicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit
            ) { _, samples, _, _, error in
                guard error == nil,
                      let routes = samples as? [HKWorkoutRoute],
                      let route = routes.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Query route data to get first location
                let routeQuery = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                    if let locations = locations, let firstLocation = locations.first {
                        // Reverse geocode the first location
                        Task {
                            let location = await self.reverseGeocode(coordinate: firstLocation.coordinate)
                            continuation.resume(returning: location)
                        }
                    } else if done {
                        continuation.resume(returning: nil)
                    }
                }
                
                healthStore.execute(routeQuery)
            }
            
            healthStore.execute(query)
        }
    }
    
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
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000.0
        return String(format: "%.1f km", km)
    }
    
    // MARK: - RPE Helpers
    
    private var shouldShowRPEButton: Bool {
        guard let workout = activity.healthKitWorkout else { return false }
        return workout.workoutActivityType == .traditionalStrengthTraining ||
               workout.workoutActivityType == .functionalStrengthTraining
    }
    
    private func checkRPEStatus() {
        guard let workout = activity.healthKitWorkout else { return }
        hasRPE = WorkoutMetadataService.shared.hasMetadata(for: workout)
    }
    
    // MARK: - Activity Icon & Color
    
    private var activityIcon: String {
        switch activity.type {
        case .cycling:
            return "bicycle"
        case .running:
            return "figure.run"
        case .swimming:
            return "figure.pool.swim"
        case .walking:
            return "figure.walk"
        case .hiking:
            return "figure.hiking"
        case .strength:
            return "dumbbell.fill"
        case .yoga:
            return "figure.yoga"
        case .hiit:
            return "flame.fill"
        case .other:
            return "figure.mixed.cardio"
        }
    }
    
}
