import SwiftUI
import MapKit

/// ViewModel for LatestActivityCardV2
/// Handles async GPS loading, map snapshot generation, and location geocoding
@MainActor
class LatestActivityCardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var locationString: String?
    @Published private(set) var mapSnapshot: UIImage?
    @Published private(set) var isLoadingMap: Bool = false
    
    // MARK: - Properties
    
    let activity: UnifiedActivity
    private var hasLoadedData = false
    
    // MARK: - Dependencies
    
    private let locationGeocodingService: LocationGeocodingService
    private let mapSnapshotService: MapSnapshotService
    private let veloReadyAPIClient: VeloReadyAPIClient
    private let intervalsAPIClient: IntervalsAPIClient
    
    // MARK: - Initialization
    
    init(
        activity: UnifiedActivity,
        locationGeocodingService: LocationGeocodingService = .shared,
        mapSnapshotService: MapSnapshotService = .shared,
        veloReadyAPIClient: VeloReadyAPIClient = .shared,
        intervalsAPIClient: IntervalsAPIClient = .shared
    ) {
        self.activity = activity
        self.locationGeocodingService = locationGeocodingService
        self.mapSnapshotService = mapSnapshotService
        self.veloReadyAPIClient = veloReadyAPIClient
        self.intervalsAPIClient = intervalsAPIClient
    }
    
    // MARK: - Public Methods
    
    func loadData() async {
        // Prevent loading data multiple times (onAppear can fire repeatedly)
        guard !hasLoadedData else {
            Logger.debug("⏭️ LatestActivityCardV2 - Data already loaded, skipping")
            return
        }
        
        hasLoadedData = true
        await loadLocation()
        if activity.shouldShowMap {
            await loadMapSnapshot()
        }
    }
    
    // MARK: - GPS & Location
    
    func loadLocation() async {
        guard let coordinates = await getGPSCoordinates() else { return }
        locationString = await locationGeocodingService.getStartLocation(from: coordinates)
    }
    
    func loadMapSnapshot() async {
        guard activity.shouldShowMap else { return }
        
        isLoadingMap = true
        defer { isLoadingMap = false }
        
        guard let coordinates = await getGPSCoordinates() else { return }
        mapSnapshot = await mapSnapshotService.generateSnapshot(from: coordinates)
    }
    
    private func getGPSCoordinates() async -> [CLLocationCoordinate2D]? {
        if let stravaActivity = activity.stravaActivity {
            return await fetchStravaGPSCoordinates(activityId: stravaActivity.id)
        }
        
        if let intervalsActivity = activity.intervalsActivity {
            return await fetchIntervalsGPSCoordinates(activityId: intervalsActivity.id)
        }
        
        return nil
    }
    
    private func fetchStravaGPSCoordinates(activityId: Int) async -> [CLLocationCoordinate2D]? {
        do {
            let streamsDict = try await veloReadyAPIClient.fetchActivityStreams(
                activityId: String(activityId),
                source: .strava
            )
            
            guard let latlngStreamData = streamsDict["latlng"] else { return nil }
            
            let coordinates: [CLLocationCoordinate2D]
            switch latlngStreamData.data {
            case .latlng(let coords):
                coordinates = coords.compactMap { coord -> CLLocationCoordinate2D? in
                    guard coord.count >= 2 else { return nil }
                    return CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1])
                }
            case .simple:
                return nil
            }
            
            return coordinates.isEmpty ? nil : coordinates
        } catch {
            return nil
        }
    }
    
    private func fetchIntervalsGPSCoordinates(activityId: String) async -> [CLLocationCoordinate2D]? {
        do {
            let samples = try await intervalsAPIClient.fetchActivityStreams(activityId: activityId)
            
            let coordinates = samples.compactMap { sample -> CLLocationCoordinate2D? in
                guard let lat = sample.latitude, let lng = sample.longitude else { return nil }
                guard !(lat == 0 && lng == 0) else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
            
            return coordinates.isEmpty ? nil : coordinates
        } catch {
            return nil
        }
    }
    
    // MARK: - Computed Properties
    
    var formattedDateAndTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: activity.startDate)
    }
    
    var formattedDateAndTimeWithLocation: String {
        var result = formattedDateAndTime
        if let location = locationString {
            result += " • \(location)"
        }
        return result
    }
    
    var shouldShowMap: Bool {
        activity.shouldShowMap
    }
    
    var hasMapSnapshot: Bool {
        mapSnapshot != nil
    }
    
    var isVirtualRide: Bool {
        // Check if activity type indicates virtual/indoor ride
        if let intervalsType = activity.intervalsActivity?.type {
            let lower = intervalsType.lowercased()
            return lower.contains("virtual") || lower.contains("indoor")
        }
        if let stravaType = activity.stravaActivity?.type {
            let lower = stravaType.lowercased()
            return lower.contains("virtual") || lower.contains("indoor")
        }
        return false
    }
}
