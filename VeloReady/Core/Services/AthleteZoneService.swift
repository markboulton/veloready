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
    private let userSettings = UserSettings.shared
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
            
            // Update user settings with zone data
            await updateUserSettingsWithZones(athleteData)
            
            Logger.debug("✅ Successfully fetched athlete data: \(athleteData.id)")
            Logger.debug("🔍 Power zones: \(athleteData.powerZones?.zones ?? [])")
            Logger.debug("🔍 HR zones: \(athleteData.heartRateZones?.zones ?? [])")
            
        } catch {
            Logger.error("Failed to fetch athlete data: \(error)")
            lastError = "Failed to fetch athlete data: \(error.localizedDescription)"
        }
    }
    
    /// Update UserSettings with zone boundaries from Intervals.icu
    private func updateUserSettingsWithZones(_ athlete: IntervalsAthlete) async {
        // Update power zones if available
        if let powerZones = athlete.powerZones,
           let zones = powerZones.zones,
           zones.count >= 5 {
            Logger.debug("🔍 Updating power zones from Intervals.icu: \(zones)")
            
            // Intervals.icu zones are typically boundaries, we need to convert to max values
            // Assuming zones are [0, zone1_max, zone2_max, zone3_max, zone4_max, zone5_max]
            if zones.count >= 6 {
                userSettings.powerZone1Max = Int(zones[1])
                userSettings.powerZone2Max = Int(zones[2])
                userSettings.powerZone3Max = Int(zones[3])
                userSettings.powerZone4Max = Int(zones[4])
                userSettings.powerZone5Max = Int(zones[5])
            }
        }
        
        // Update heart rate zones if available
        if let hrZones = athlete.heartRateZones,
           let zones = hrZones.zones,
           zones.count >= 5 {
            Logger.debug("🔍 Updating HR zones from Intervals.icu: \(zones)")
            
            // Intervals.icu zones are typically boundaries, we need to convert to max values
            // Assuming zones are [0, zone1_max, zone2_max, zone3_max, zone4_max, zone5_max]
            if zones.count >= 6 {
                userSettings.hrZone1Max = Int(zones[1])
                userSettings.hrZone2Max = Int(zones[2])
                userSettings.hrZone3Max = Int(zones[3])
                userSettings.hrZone4Max = Int(zones[4])
                userSettings.hrZone5Max = Int(zones[5])
            }
        }
    }
    
    /// Check if we need to refresh athlete data
    var shouldRefreshAthleteData: Bool {
        guard let lastFetch = lastFetchDate else { return true }
        return Date().timeIntervalSince(lastFetch) > 3600 // Refresh every hour
    }
    
    /// Get zone boundaries for display
    func getPowerZoneBoundaries() -> [Int] {
        return [
            userSettings.powerZone1Max,
            userSettings.powerZone2Max,
            userSettings.powerZone3Max,
            userSettings.powerZone4Max,
            userSettings.powerZone5Max
        ]
    }
    
    func getHeartRateZoneBoundaries() -> [Int] {
        return [
            userSettings.hrZone1Max,
            userSettings.hrZone2Max,
            userSettings.hrZone3Max,
            userSettings.hrZone4Max,
            userSettings.hrZone5Max
        ]
    }
}
