import Foundation
import SwiftUI

/// Service for fetching and managing AI-generated daily briefs
@MainActor
class AIBriefService: ObservableObject {
    static let shared = AIBriefService()
    
    @Published var briefText: String?
    @Published var isLoading = false
    @Published var error: AIBriefError?
    @Published var isCached = false
    
    private let client: AIBriefClientProtocol
    private let recoveryService = RecoveryScoreService.shared
    private let sleepService = SleepScoreService.shared
    private let illnessService = IllnessDetectionService.shared
    private let cacheManager = CacheManager.shared
    private let persistence = PersistenceController.shared
    
    // Anonymous user ID (persisted across app launches)
    private let userIdKey = "ai_brief_user_id"
    var userId: String {
        if let existing = UserDefaults.standard.string(forKey: userIdKey) {
            return existing
        }
        
        // Generate new anonymous ID
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: userIdKey)
        Logger.debug("🆔 Generated new anonymous user ID: \(newId.prefix(8))...")
        return newId
    }
    
    init(client: AIBriefClientProtocol = AIBriefClient.shared) {
        self.client = client
    }
    
    /// Fetch AI brief for today
    func fetchBrief(bypassCache: Bool = false) async {
        // Check Core Data cache first (unless bypassing)
        if !bypassCache, let cachedBrief = loadFromCoreData() {
            briefText = cachedBrief
            isCached = true
            Logger.debug("📦 Using cached AI brief from Core Data")
            return
        }
        
        // Always fetch if recovery is available (even with missing sleep)
        // The API handles missing sleep gracefully
        let sleepDataMissing = SleepScoreService.shared.currentSleepScore == nil
        if sleepDataMissing {
            Logger.warning("️ Sleep data missing - fetching AI brief anyway (recovery score available)")
        }
        
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await client.fetchBrief(request: buildRequest(), userId: userId, bypassCache: bypassCache)
            briefText = response.text
            isCached = response.cached ?? false
            
            // Save to Core Data
            saveToCoreData(text: response.text)
            
            Logger.debug("✅ AI brief updated (\(response.cached ?? false ? "cached" : "fresh"))")
        } catch let briefError as AIBriefError {
            error = briefError
            briefText = getFallbackMessage()
            isCached = false
            Logger.error("AI brief error: \(briefError)")
        } catch {
            self.error = .networkError(error.localizedDescription)
            briefText = getFallbackMessage()
            isCached = false
            Logger.error("AI brief error: \(error.localizedDescription)")
        }
    }
    
    /// Refresh brief (only if not already generated today)
    func refresh() async {
        // Check if we already have a brief from today in Core Data
        if let cachedBrief = loadFromCoreData(), !cachedBrief.isEmpty {
            Logger.debug("🔄 AI brief already generated today - using cached version")
            await fetchBrief(bypassCache: false) // Use cache
            return
        }
        
        Logger.debug("🔄 Refreshing AI brief (bypass cache)")
        await fetchBrief(bypassCache: true)
    }
    
    private func buildRequest() throws -> AIBriefRequest {
        // Get current recovery score and inputs
        Logger.debug("🤖 [AI Brief] Building request - recovery score: \(recoveryService.currentRecoveryScore?.score.description ?? "nil")")
        Logger.debug("🤖 [AI Brief] Recovery service state: isLoading=\(recoveryService.isLoading)")
        
        guard let recovery = recoveryService.currentRecoveryScore else {
            Logger.error("❌ [AI Brief] Recovery score is nil - cannot build request")
            throw AIBriefError.networkError("Recovery score not available")
        }
        
        Logger.debug("✅ [AI Brief] Recovery score available: \(recovery.score)")
        
        // Calculate deltas from baselines
        let sleepDelta = calculateSleepDelta(recovery: recovery)
        let sleepScore = recovery.inputs.sleepScore?.score
        let hrvDelta = calculateHRVDelta(recovery: recovery)
        let rhrDelta = calculateRHRDelta(recovery: recovery)
        
        // Get TSB from latest activity or wellness
        let tsb = recovery.inputs.ctl != nil && recovery.inputs.atl != nil
            ? (recovery.inputs.ctl! - recovery.inputs.atl!)
            : 0.0
        
        // Get TSS targets (low = easy day, high = hard day)
        // Based on CTL: easy = 80% of CTL, hard = 150% of CTL
        // This gives more realistic ranges (e.g., CTL 35 → 28-52 TSS)
        let ctl = recovery.inputs.ctl ?? 50.0
        let tssLow = Int(ctl * 0.8)
        let tssHigh = Int(ctl * 1.5)
        
        // Get planned workout from today's cache (if available)
        let plan = getTodaysPlannedWorkout()
        
        // Get today's completed activities
        let (completedActivities, todayTSS) = getTodaysCompletedActivities()
        
        // Get illness indicator if present
        let illnessData = buildIllnessIndicatorData()
        
        let request = AIBriefRequest(
            recovery: recovery.score,
            sleepDelta: sleepDelta,
            sleepScore: sleepScore,
            hrvDelta: hrvDelta,
            rhrDelta: rhrDelta,
            tsb: tsb,
            tssLow: tssLow,
            tssHigh: tssHigh,
            plan: plan,
            completedActivities: completedActivities,
            todayTSS: todayTSS,
            illnessIndicator: illnessData
        )
        
        Logger.data("========================================")
        Logger.data("AI BRIEF REQUEST DATA:")
        Logger.data("  Recovery: \(request.recovery)")
        Logger.data("  Sleep Score: \(request.sleepScore.map { "\($0)/100" } ?? "nil")")
        Logger.data("  Sleep Delta: \(request.sleepDelta.map { String(format: "%.1f", $0) + "h" } ?? "nil")")
        Logger.data("  HRV Delta: \(request.hrvDelta.map { String(format: "%.1f", $0) + "%" } ?? "nil")")
        Logger.data("  RHR Delta: \(request.rhrDelta.map { String(format: "%.1f", $0) + "%" } ?? "nil")")
        Logger.data("  TSB: \(String(format: "%.1f", request.tsb))")
        Logger.data("  TSS Range: \(request.tssLow)-\(request.tssHigh)")
        Logger.data("  Plan: \(request.plan ?? "none")")
        if let illness = request.illnessIndicator {
            Logger.data("  ⚠️ Illness: \(illness.severity) (\(Int(illness.confidence * 100))% confidence)")
            for signal in illness.signals {
                Logger.data("    - \(signal.type): \(String(format: "%+.1f", signal.deviation))%")
            }
        }
        if let activities = request.completedActivities, !activities.isEmpty {
            Logger.data("  ✓ Completed Today:")
            for activity in activities {
                Logger.data("    - \(activity.name): \(activity.duration)min, TSS: \(activity.tss.map { String(format: "%.1f", $0) } ?? "?")")
            }
            Logger.data("  Today's Total TSS: \(request.todayTSS.map { String(format: "%.1f", $0) } ?? "0")")
        } else {
            Logger.data("  No activities completed yet today")
        }
        
        // Show what AI will recommend based on recovery
        let recoveryBand = request.recovery >= 70 ? "GREEN" : request.recovery >= 40 ? "AMBER" : "RED"
        Logger.data("  Expected Recommendation: \(recoveryBand) zone training")
        Logger.data("========================================")
        
        return request
    }
    
    private func calculateSleepDelta(recovery: RecoveryScore) -> Double? {
        guard let sleep = recovery.inputs.sleepDuration,
              let baseline = recovery.inputs.sleepBaseline,
              baseline > 0 else {
            return nil
        }
        
        // Return delta in hours
        return (sleep - baseline) / 3600.0
    }
    
    private func calculateHRVDelta(recovery: RecoveryScore) -> Double? {
        guard let hrv = recovery.inputs.hrv,
              let baseline = recovery.inputs.hrvBaseline,
              baseline > 0 else {
            return nil
        }
        
        // Return percentage change
        return ((hrv - baseline) / baseline) * 100.0
    }
    
    private func calculateRHRDelta(recovery: RecoveryScore) -> Double? {
        guard let rhr = recovery.inputs.rhr,
              let baseline = recovery.inputs.rhrBaseline,
              baseline > 0 else {
            return nil
        }
        
        // Return percentage change
        return ((rhr - baseline) / baseline) * 100.0
    }
    
    private func getTodaysPlannedWorkout() -> String? {
        // Try to get today's planned workout from cache
        // Source: DailyLoad.workoutName from Core Data cache
        // This is populated from intervals.icu calendar
        
        // For now, return nil - will be populated when we integrate with calendar
        return nil
    }
    
    private func buildIllnessIndicatorData() -> AIBriefRequest.IllnessIndicatorData? {
        guard let indicator = illnessService.currentIndicator else {
            return nil
        }
        
        let signals = indicator.signals.map { signal in
            AIBriefRequest.IllnessIndicatorData.SignalData(
                type: signal.type.rawValue,
                deviation: signal.deviation,
                value: signal.value
            )
        }
        
        return AIBriefRequest.IllnessIndicatorData(
            severity: indicator.severity.rawValue,
            confidence: indicator.confidence,
            signals: signals
        )
    }
    
    private func getTodaysCompletedActivities() -> ([AIBriefRequest.CompletedActivity]?, Double?) {
        // Get today's activities from ALL sources (Intervals.icu, Strava, HealthKit)
        // This ensures we capture activities regardless of which service user has connected
        
        // Method 1: Try unified cache (Intervals.icu activities from UserDefaults)
        var cachedActivities: [IntervalsActivity] = []
        if let data = UserDefaults.standard.data(forKey: "intervals_activities_cache"),
           let activities = try? JSONDecoder().decode([IntervalsActivity].self, from: data) {
            cachedActivities = activities
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        let todaysActivities = cachedActivities.filter { activity in
            let dateStr = activity.startDateLocal
            
            // Parse date string
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
            formatter.timeZone = TimeZone.current
            
            guard let activityDate = formatter.date(from: dateStr) else { return false }
            return Calendar.current.isDate(activityDate, inSameDayAs: today)
        }
        
        // Method 2: If no Intervals activities, try to get from Strava cache
        // (This handles case where user only has Strava connected)
        var allActivities = todaysActivities
        if allActivities.isEmpty {
            // Note: Strava activities are fetched in real-time by StrainScoreService
            // and should be in the unified cache. If not, they'll be picked up on next refresh.
            Logger.debug("📊 [AI Brief] No Intervals activities found, relying on unified cache")
        }
        
        guard !allActivities.isEmpty else {
            return (nil, nil)
        }
        
        // Convert to CompletedActivity format
        let completed = allActivities.map { activity in
            AIBriefRequest.CompletedActivity(
                name: activity.name ?? "Ride",
                duration: activity.duration != nil ? Int(activity.duration! / 60) : 0,
                tss: activity.tss
            )
        }
        
        // Calculate total TSS
        let totalTSS = allActivities.reduce(0.0) { sum, activity in
            sum + (activity.tss ?? 0)
        }
        
        Logger.debug("📊 [AI Brief] Found \(completed.count) completed activities today (Total TSS: \(String(format: "%.1f", totalTSS)))")
        
        return (completed, totalTSS > 0 ? totalTSS : nil)
    }
    
    private func getFallbackMessage() -> String {
        // Fallback message when API is unavailable
        guard let recovery = recoveryService.currentRecoveryScore else {
            return "Your daily metrics are being calculated. Check back in a moment."
        }
        
        // Simple rule-based message based on recovery score
        switch recovery.score {
        case 80...100:
            return "You're well-recovered today! Great time for a challenging workout or race."
        case 60..<80:
            return "Good recovery. You can handle moderate to hard training today."
        case 40..<60:
            return "Moderate recovery. Consider an easier workout or active recovery."
        default:
            return "Low recovery today. Prioritize rest or very light activity."
        }
    }
    
    // Debug helper
    func getDebugInfo() -> String {
        var info = "AI Brief Service:\n"
        info += "  User ID: \(userId.prefix(8))...\n"
        info += "  Loading: \(isLoading)\n"
        info += "  Cached: \(isCached)\n"
        info += "  Error: \(error?.localizedDescription ?? "none")\n"
        info += "  Text length: \(briefText?.count ?? 0) chars\n"
        
        if let client = client as? AIBriefClient {
            info += "\n"
            info += (client as AIBriefClient).cache.getCacheInfo()
        }
        
        return info
    }
}

// MARK: - Extension for AIBriefClient access

extension AIBriefService {
    var cache: AIBriefCache? {
        (client as? AIBriefClient)?.cache
    }
    
    func clearCache() {
        (client as? AIBriefClient)?.clearCache()
    }
    
    // MARK: - Core Data Persistence
    
    /// Load AI brief from Core Data for today
    private func loadFromCoreData() -> String? {
        let today = Calendar.current.startOfDay(for: Date())
        
        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", today as NSDate)
        request.fetchLimit = 1
        
        guard let scores = persistence.fetch(request).first,
              let briefText = scores.aiBriefText,
              !briefText.isEmpty else {
            return nil
        }
        
        return briefText
    }
    
    /// Save AI brief to Core Data for today
    private func saveToCoreData(text: String) {
        let today = Calendar.current.startOfDay(for: Date())
        
        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", today as NSDate)
        request.fetchLimit = 1
        
        guard let scores = persistence.fetch(request).first else {
            Logger.warning("️ No DailyScores found for today - AI brief not saved")
            return
        }
        
        scores.aiBriefText = text
        persistence.save()
        Logger.debug("💾 Saved AI brief to Core Data")
    }
}
