import Foundation
import SwiftUI

/// Service for fetching and managing AI-generated ride summaries
@MainActor
class RideSummaryService: ObservableObject {
    static let shared = RideSummaryService()
    
    @Published var currentSummary: RideSummaryResponse?
    @Published var isLoading = false
    @Published var error: RideSummaryError?
    
    private let client: RideSummaryClientProtocol
    
    // Anonymous user ID (shared with AI Brief)
    private let userIdKey = "ai_brief_user_id"
    private let overrideKey = "ride_summary_user_override"
    private let overrideEnabledKey = "ride_summary_user_override_enabled"
    
    var userId: String {
        // Check for debug override first
        if UserDefaults.standard.bool(forKey: overrideEnabledKey),
           let override = UserDefaults.standard.string(forKey: overrideKey) {
            return override
        }
        
        if let existing = UserDefaults.standard.string(forKey: userIdKey) {
            return existing
        }
        
        // Generate new anonymous ID
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: userIdKey)
        Logger.debug("🆔 Generated new anonymous user ID: \(newId.prefix(8))...")
        return newId
    }
    
    init(client: RideSummaryClientProtocol = RideSummaryClient.shared) {
        self.client = client
    }
    
    /// Fetch AI summary for a ride
    func fetchSummary(for activity: Activity, bypassCache: Bool = false) async {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let request = buildRequest(from: activity)
            let response = try await client.fetchSummary(request: request, userId: userId, bypassCache: bypassCache)
            currentSummary = response
            
            Logger.debug("✅ Ride summary updated (\(response.cached ?? false ? "cached" : "fresh"))")
        } catch let summaryError as RideSummaryError {
            error = summaryError
            currentSummary = nil
            Logger.error("Ride summary error: \(summaryError)")
        } catch {
            self.error = .networkError(error.localizedDescription)
            currentSummary = nil
            Logger.error("Ride summary error: \(error.localizedDescription)")
        }
    }
    
    /// Refresh summary (bypass cache)
    func refresh(for activity: Activity) async {
        Logger.debug("🔄 Refreshing ride summary (bypass cache)")
        await fetchSummary(for: activity, bypassCache: true)
    }
    
    private func buildRequest(from activity: Activity) -> RideSummaryRequest {
        // Get recovery data if available
        let recoveryService = RecoveryScoreService.shared
        let recovery = recoveryService.currentRecoveryScore
        
        // Get FTP from profile manager
        let profileManager = AthleteProfileManager.shared
        let ftp = profileManager.profile.ftp
        
        // Calculate TSB if we have CTL/ATL
        let tsb: Double? = {
            if let ctl = activity.ctl, let atl = activity.atl {
                return ctl - atl
            }
            return nil
        }()
        
        // Calculate HR drift (pacing quality indicator)
        let hrDrift: Double? = calculateHRDrift(activity: activity)
        
        // Calculate power variability (pacing smoothness indicator)
        let powerVariability: Double? = calculatePowerVariability(activity: activity)
        
        // Build HR data object
        let hrData: RideSummaryRequest.HRData? = {
            if activity.averageHeartRate != nil || activity.maxHeartRate != nil {
                return RideSummaryRequest.HRData(
                    avg: activity.averageHeartRate,
                    max: activity.maxHeartRate,
                    lfhddriftPct: hrDrift
                )
            }
            return nil
        }()
        
        // Build cadence data object
        let cadenceData: RideSummaryRequest.CadenceData? = {
            if let cadence = activity.averageCadence {
                return RideSummaryRequest.CadenceData(avg: cadence)
            }
            return nil
        }()
        
        // Build context object
        let contextData: RideSummaryRequest.ContextData? = {
            if recovery?.score != nil || tsb != nil {
                return RideSummaryRequest.ContextData(
                    recoveryPct: recovery?.score,
                    tsb: tsb
                )
            }
            return nil
        }()
        
        let request = RideSummaryRequest(
            rideId: activity.id,
            title: activity.name ?? "Untitled Ride",
            startTimeUtc: activity.startDateLocal,  // ISO format from server
            durationSec: activity.duration != nil ? Int(activity.duration!) : nil,
            distanceKm: activity.distance != nil ? activity.distance! / 1000.0 : nil,
            elevationGainM: activity.elevationGain,
            tss: activity.tss,
            if: activity.intensityFactor,
            np: activity.normalizedPower,
            avgPower: activity.averagePower,
            powerVariabilityPct: powerVariability,
            ftp: ftp,
            hr: hrData,
            cadence: cadenceData,
            timeInZonesSec: activity.icuZoneTimes,  // Power zone times
            intervals: nil,
            fueling: nil,
            rpe: nil,
            notes: activity.description,
            context: contextData,
            goal: nil
        )
        
        #if DEBUG
        Logger.data("Ride Summary Request Data:")
        Logger.debug("   Ride ID: \(request.rideId)")
        Logger.debug("   Title: \(request.title)")
        Logger.debug("   Duration: \(request.durationSec?.description ?? "nil")s")
        Logger.debug("   Distance: \(request.distanceKm?.description ?? "nil")km")
        Logger.debug("   TSS: \(request.tss?.description ?? "nil")")
        Logger.debug("   IF: \(request.if?.description ?? "nil")")
        Logger.debug("   NP: \(request.np?.description ?? "nil")")
        Logger.debug("   Avg Power: \(request.avgPower?.description ?? "nil")")
        Logger.debug("   FTP: \(request.ftp?.description ?? "nil")")
        Logger.debug("   Power Variability: \(request.powerVariabilityPct?.description ?? "nil")%")
        Logger.debug("   HR: avg=\(request.hr?.avg?.description ?? "nil"), max=\(request.hr?.max?.description ?? "nil"), drift=\(request.hr?.lfhddriftPct?.description ?? "nil")%")
        Logger.debug("   Cadence: avg=\(request.cadence?.avg?.description ?? "nil")")
        Logger.debug("   Context: recovery=\(request.context?.recoveryPct?.description ?? "nil")%, tsb=\(request.context?.tsb?.description ?? "nil")")
        #endif
        
        return request
    }
    
    /// Clear current summary
    func clearSummary() {
        currentSummary = nil
        error = nil
    }
    
    // Debug helper
    func getDebugInfo() -> String {
        var info = "Ride Summary Service:\n"
        info += "  User ID: \(userId.prefix(8))...\n"
        info += "  Loading: \(isLoading)\n"
        info += "  Error: \(error?.localizedDescription ?? "none")\n"
        info += "  Current summary: \(currentSummary != nil ? "loaded" : "none")\n"
        
        if let client = client as? RideSummaryClient {
            info += "\n"
            info += client.cache.getCacheInfo()
        }
        
        return info
    }
    
    // MARK: - Metric Calculations
    
    /// Calculate HR drift percentage (first half vs second half)
    /// Positive drift indicates fatigue/poor pacing, negative indicates warm-up effect
    private func calculateHRDrift(activity: Activity) -> Double? {
        // Check if we have HR zone times data (as a proxy for HR stream availability)
        guard let hrZoneTimes = activity.icuHrZoneTimes,
              !hrZoneTimes.isEmpty,
              let avgHR = activity.averageHeartRate,
              let _ = activity.maxHeartRate,
              avgHR > 0 else {
            return nil
        }
        
        // For now, use a simplified drift estimation based on zone distribution
        // In a future version, we can fetch actual HR stream data from the API
        
        // Simplified drift estimation: If high-zone time is back-loaded, assume positive drift
        // This is a heuristic until we have actual stream data
        
        // If we have enough data points in zones, estimate drift
        let totalTime = hrZoneTimes.reduce(0, +)
        guard totalTime > 600 else { return nil } // Need at least 10 minutes
        
        // For now, return nil and wait for actual HR stream data integration
        // This will be implemented in a future PR when we add HR stream fetching
        return nil
    }
    
    /// Calculate power variability (Variability Index - 1, as percentage)
    /// Higher values indicate more variable/erratic pacing
    private func calculatePowerVariability(activity: Activity) -> Double? {
        guard let avgPower = activity.averagePower,
              let normalizedPower = activity.normalizedPower,
              avgPower > 0 else {
            return nil
        }
        
        // Variability Index (VI) = NP / avgPower
        // We return (VI - 1) * 100 as a percentage
        // 0% = perfectly smooth, 10% = moderately variable, 20%+ = very erratic
        let variabilityIndex = normalizedPower / avgPower
        return (variabilityIndex - 1.0) * 100.0
    }
}

// MARK: - Extension for RideSummaryClient access

extension RideSummaryService {
    var cache: RideSummaryCache? {
        (client as? RideSummaryClient)?.cache
    }
    
    func clearCache() {
        (client as? RideSummaryClient)?.clearCache()
    }
}
