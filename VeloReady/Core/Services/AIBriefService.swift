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
        print("🆔 Generated new anonymous user ID: \(newId.prefix(8))...")
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
            print("📦 Using cached AI brief from Core Data")
            return
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
            
            print("✅ AI brief updated (\(response.cached ?? false ? "cached" : "fresh"))")
        } catch let briefError as AIBriefError {
            error = briefError
            briefText = getFallbackMessage()
            isCached = false
            print("❌ AI brief error: \(briefError)")
        } catch {
            self.error = .networkError(error.localizedDescription)
            briefText = getFallbackMessage()
            isCached = false
            print("❌ AI brief error: \(error.localizedDescription)")
        }
    }
    
    /// Refresh brief (bypass cache)
    func refresh() async {
        print("🔄 Refreshing AI brief (bypass cache)")
        await fetchBrief(bypassCache: true)
    }
    
    private func buildRequest() throws -> AIBriefRequest {
        // Get current recovery score and inputs
        guard let recovery = recoveryService.currentRecoveryScore else {
            throw AIBriefError.networkError("Recovery score not available")
        }
        
        // Calculate deltas from baselines
        let sleepDelta = calculateSleepDelta(recovery: recovery)
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
        
        let request = AIBriefRequest(
            recovery: recovery.score,
            sleepDelta: sleepDelta,
            hrvDelta: hrvDelta,
            rhrDelta: rhrDelta,
            tsb: tsb,
            tssLow: tssLow,
            tssHigh: tssHigh,
            plan: plan
        )
        
        print("📊 ========================================")
        print("📊 AI BRIEF REQUEST DATA:")
        print("📊   Recovery: \(request.recovery)")
        print("📊   Sleep Delta: \(String(format: "%.1f", request.sleepDelta))h")
        print("📊   HRV Delta: \(String(format: "%.1f", request.hrvDelta))%")
        print("📊   RHR Delta: \(String(format: "%.1f", request.rhrDelta))%")
        print("📊   TSB: \(String(format: "%.1f", request.tsb))")
        print("📊   TSS Range: \(request.tssLow)-\(request.tssHigh)")
        print("📊   Plan: \(request.plan ?? "none")")
        
        // Show what AI will recommend based on recovery
        let recoveryBand = request.recovery >= 70 ? "GREEN" : request.recovery >= 40 ? "AMBER" : "RED"
        print("📊   Expected Recommendation: \(recoveryBand) zone training")
        print("📊 ========================================")
        
        return request
    }
    
    private func calculateSleepDelta(recovery: RecoveryScore) -> Double {
        guard let sleep = recovery.inputs.sleepDuration,
              let baseline = recovery.inputs.sleepBaseline,
              baseline > 0 else {
            return 0.0
        }
        
        // Return delta in hours
        return (sleep - baseline) / 3600.0
    }
    
    private func calculateHRVDelta(recovery: RecoveryScore) -> Double {
        guard let hrv = recovery.inputs.hrv,
              let baseline = recovery.inputs.hrvBaseline,
              baseline > 0 else {
            return 0.0
        }
        
        // Return percentage change
        return ((hrv - baseline) / baseline) * 100.0
    }
    
    private func calculateRHRDelta(recovery: RecoveryScore) -> Double {
        guard let rhr = recovery.inputs.rhr,
              let baseline = recovery.inputs.rhrBaseline,
              baseline > 0 else {
            return 0.0
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
            print("⚠️ No DailyScores found for today - AI brief not saved")
            return
        }
        
        scores.aiBriefText = text
        persistence.save()
        print("💾 Saved AI brief to Core Data")
    }
}
