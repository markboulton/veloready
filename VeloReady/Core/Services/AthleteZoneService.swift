import Foundation
import SwiftUI

/// Service to manage athlete data and zone settings from Intervals.icu
@MainActor
class AthleteZoneService: ObservableObject {
    static let shared: AthleteZoneService = {
        let instance = AthleteZoneService()
        return instance
    }()
    
    @Published var athlete: IntervalsAthlete?
    @Published var isLoading = false
    var lastFetchDate: Date?
    @Published var lastError: String?

    private let apiClient: IntervalsAPIClient
    private var lastFetchAttempt: Date?
    private let minimumFetchInterval: TimeInterval = 300 // 5 minutes between attempts
    private let cacheExpirationInterval: TimeInterval = 7 * 24 * 60 * 60 // 1 week in seconds
    
    init(apiClient: IntervalsAPIClient? = nil) {
        self.apiClient = apiClient ?? IntervalsAPIClient.shared
    }
    
    /// Fetch athlete data from Intervals.icu
    func fetchAthleteData() async {
        // Check if we have valid cached data
        if let lastFetch = lastFetchDate {
            let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
            if timeSinceLastFetch < cacheExpirationInterval {
                Logger.debug("✅ Using cached athlete data (age: \(Int(timeSinceLastFetch/3600)) hours)")
                return
            }
        }
        
        // Rate limiting protection
        if let lastAttempt = lastFetchAttempt {
            let timeSinceLastAttempt = Date().timeIntervalSince(lastAttempt)
            if timeSinceLastAttempt < minimumFetchInterval {
                let remainingTime = Int(minimumFetchInterval - timeSinceLastAttempt)
                lastError = "Please wait \(remainingTime) seconds before trying again"
                Logger.warning("️ Rate limited: Please wait \(remainingTime) seconds")
                return
            }
        }
        
        guard !isLoading else { 
            Logger.warning("️ Already loading athlete data")
            return 
        }
        
        isLoading = true
        lastFetchAttempt = Date()
        lastError = nil
        defer { isLoading = false }
        
        do {
            Logger.debug("🔍 Fetching athlete data from Intervals.icu...")
            let athleteData = try await apiClient.fetchAthleteData()
            self.athlete = athleteData
            self.lastFetchDate = Date()
            
            // Debug: Print raw athlete data
            Logger.debug("🔍 Raw athlete data: \(athleteData)")
            Logger.debug("🔍 Power zones: \(athleteData.powerZones?.zones ?? [])")
            Logger.debug("🔍 HR zones: \(athleteData.heartRateZones?.zones ?? [])")

            Logger.debug("✅ Successfully fetched athlete data: \(athleteData.id)")

        } catch {
            Logger.error("Failed to fetch athlete data: \(error)")
            lastError = "Failed to fetch athlete data: \(error.localizedDescription)"
        }
    }

    /// Extract zone data from athlete data (no longer modifies UserSettings directly)
    /// Returns nil if zone data is not available
    func extractZoneData() -> (hrZones: [Int], powerZones: [Int])? {
        guard let athlete = athlete else {
            Logger.debug("⚠️ No athlete data available for zone extraction")
            return nil
        }

        var hrZones: [Int] = []
        var powerZones: [Int] = []

        // Extract power zones if available
        if let pz = athlete.powerZones,
           let zones = pz.zones,
           zones.count >= 6 {
            // Intervals.icu zones are boundaries [0, zone1_max, zone2_max, ...]
            powerZones = [
                Int(zones[1]),
                Int(zones[2]),
                Int(zones[3]),
                Int(zones[4]),
                Int(zones[5])
            ]
            Logger.debug("🔍 Extracted power zones from Intervals.icu: \(powerZones)")
        }

        // Extract heart rate zones if available
        if let hrz = athlete.heartRateZones,
           let zones = hrz.zones,
           zones.count >= 6 {
            // Intervals.icu zones are boundaries [0, zone1_max, zone2_max, ...]
            hrZones = [
                Int(zones[1]),
                Int(zones[2]),
                Int(zones[3]),
                Int(zones[4]),
                Int(zones[5])
            ]
            Logger.debug("🔍 Extracted HR zones from Intervals.icu: \(hrZones)")
        }

        // Only return if we have at least one set of zones
        if !hrZones.isEmpty || !powerZones.isEmpty {
            return (hrZones: hrZones, powerZones: powerZones)
        }

        return nil
    }
    
    /// Check if we need to refresh athlete data
    var shouldRefreshAthleteData: Bool {
        guard let lastFetch = lastFetchDate else { return true }
        return Date().timeIntervalSince(lastFetch) > 3600 // Refresh every hour
    }
}
