import Foundation
import SwiftUI
import Combine

/// ViewModel for the Today feature
@MainActor
class TodayViewModel: ObservableObject {
    static let shared = TodayViewModel()
    
    @Published var recentActivities: [IntervalsActivity] = [] // Keep for backwards compatibility
    @Published var unifiedActivities: [UnifiedActivity] = [] // New unified list
    @Published var wellnessData: [IntervalsWellness] = []
    @Published var isLoading = false
    @Published var isInitializing = true {
        didSet {
            Logger.debug("🔄 [SPINNER] isInitializing changed: \(oldValue) → \(isInitializing)")
            // Trigger ring animations when spinner disappears
            if !isInitializing && oldValue {
                animationTrigger = UUID()
                Logger.debug("🎬 [ANIMATION] Triggered ring animations after spinner")
            }
        }
    }
    @Published var isDataLoaded = false // Track when all initial data is ready
    @Published var errorMessage: String?
    @Published var animationTrigger = UUID() // Triggers ring animations on refresh
    
    // Track if initial UI has been loaded to prevent duplicate calls
    private var hasLoadedInitialUI = false
    
    // Health Status
    @Published var isHealthKitAuthorized = false
    
    // MARK: - Dependencies (via ServiceContainer)
    
    private let services = ServiceContainer.shared
    
    // Convenience accessors for frequently used services
    private var oauthManager: IntervalsOAuthManager { services.intervalsOAuthManager }
    private var apiClient: IntervalsAPIClient { services.intervalsAPIClient }
    private var intervalsCache: IntervalsCache { services.intervalsCache }
    private var healthKitCache: HealthKitCache { services.healthKitCache }
    private var healthKitManager: HealthKitManager { services.healthKitManager }
    private var stravaAuthService: StravaAuthService { services.stravaAuthService }
    private var stravaDataService: StravaDataService { services.stravaDataService }
    private var stravaAPIClient: StravaAPIClient { services.stravaAPIClient }
    private var cacheManager: CacheManager { services.cacheManager }
    private var deduplicationService: ActivityDeduplicationService { services.deduplicationService }
    
    let recoveryScoreService: RecoveryScoreService
    let sleepScoreService: SleepScoreService
    let strainScoreService: StrainScoreService
    
    // Observer for HealthKit authorization changes
    private var healthKitObserver: AnyCancellable?
    
    /// Clear baseline cache to force fresh calculation from HealthKit
    func clearBaselineCache() {
        recoveryScoreService.clearBaselineCache()
        Logger.debug("🗑️ Cleared baseline cache - will fetch fresh historical data from HealthKit")
    }
    
    /// Force refresh HealthKit workouts (clears cache)
    func forceRefreshHealthKitWorkouts() async {
        Logger.debug("🔄 Force refreshing HealthKit workouts...")
        healthKitCache.clearCache()
        await refreshData()
    }
    
    private init(container: ServiceContainer = .shared) {
        // Use score services from container
        self.recoveryScoreService = container.recoveryScoreService
        self.sleepScoreService = container.sleepScoreService
        self.strainScoreService = container.strainScoreService
        
        Logger.debug("🎬 [SPINNER] TodayViewModel init - isInitializing=\(isInitializing)")
        
        // Setup HealthKit observer
        healthKitObserver = container.healthKitManager.$isAuthorized
            .sink { [weak self] isAuthorized in
                DispatchQueue.main.async {
                    self?.isHealthKitAuthorized = isAuthorized
                }
            }
        
        // ULTRA-FAST initialization - no expensive operations
        loadInitialDataFast()
        Logger.debug("✅ [SPINNER] TodayViewModel init complete - isInitializing=\(isInitializing)")
    }
    
    func refreshData(forceRecoveryRecalculation: Bool = false) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        Logger.warning("️ Starting full data refresh...")
        
        isLoading = true
        isDataLoaded = false
        errorMessage = nil
        
        // Fetch activities from all connected sources
        
        // Try to fetch Intervals activities (optional)
        var intervalsActivities: [IntervalsActivity] = []
        var wellness: [IntervalsWellness] = []
        do {
            intervalsActivities = try await intervalsCache.getCachedActivities(apiClient: apiClient, forceRefresh: false)
            wellness = try await intervalsCache.getCachedWellness(apiClient: apiClient, forceRefresh: false)
            Logger.debug("✅ Loaded \(intervalsActivities.count) activities from Intervals.icu")
        } catch {
            Logger.warning("️ Intervals.icu not available: \(error.localizedDescription)")
        }
        
        // Fetch Strava activities using shared service
        await stravaDataService.fetchActivitiesIfNeeded()
        let stravaActivities = stravaDataService.activities
        
        // Always fetch Apple Health workouts
        let healthWorkouts = await healthKitCache.getCachedWorkouts(healthKitManager: healthKitManager, forceRefresh: false)
        Logger.debug("✅ Loaded \(healthWorkouts.count) workouts from Apple Health")
        
        // Keep backwards compatibility
        recentActivities = Array(intervalsActivities.prefix(15))
        wellnessData = wellness
        
        // Convert to unified format
        var intervalsUnified: [UnifiedActivity] = []
        var stravaFilteredCount = 0
        
        for intervalsActivity in intervalsActivities {
            // Skip Strava-sourced activities (we fetch them directly from Strava)
            if let source = intervalsActivity.source, source.uppercased() == "STRAVA" {
                stravaFilteredCount += 1
                continue
            }
            intervalsUnified.append(UnifiedActivity(from: intervalsActivity))
        }
        
        Logger.debug("🔍 Filtered Intervals activities: \(intervalsActivities.count) total → \(intervalsUnified.count) native (removed \(stravaFilteredCount) Strava)")
        
        let stravaUnified = stravaActivities.map { UnifiedActivity(from: $0) }
        let healthUnified = healthWorkouts.map { UnifiedActivity(from: $0) }
        
        // Deduplicate activities across all sources
        let deduplicated = deduplicationService.deduplicateActivities(
            intervalsActivities: intervalsUnified,
            stravaActivities: stravaUnified,
            appleHealthActivities: healthUnified
        )
        
        // Sort by date (most recent first) and take top 15
        unifiedActivities = deduplicated.sorted { $0.startDate > $1.startDate }.prefix(15).map { $0 }
        
        Logger.debug("🔍 Found \(intervalsUnified.count) Intervals + \(stravaActivities.count) Strava + \(healthWorkouts.count) Apple Health")
        Logger.debug("🔍 Showing \(unifiedActivities.count) unique unified activities (after deduplication)")
        for activity in unifiedActivities.prefix(5) {
            Logger.debug("🔍 Activity: \(activity.name) - Type: \(activity.type.rawValue) - Source: \(activity.source)")
        }
        Logger.debug("⚡ Starting parallel score calculations...")
        
        // Start sleep and strain calculations in parallel
        await sleepScoreService.calculateSleepScore()
        Logger.debug("✅ Sleep score calculated")
        
        // Start recovery and strain calculations in parallel
        async let recoveryCalculation: Void = {
            if forceRecoveryRecalculation {
                await recoveryScoreService.forceRefreshRecoveryScoreIgnoringDailyLimit()
            } else {
                await recoveryScoreService.calculateRecoveryScore()
            }
        }()
        async let strainCalculation: Void = strainScoreService.calculateStrainScore()
        
        // Wait for both to complete
        _ = await recoveryCalculation
        _ = await strainCalculation
        
        Logger.debug("✅ All score calculations completed")
        
        // Save to Core Data cache after scores are calculated
        do {
            try await cacheManager.refreshToday()
            Logger.debug("💾 Saved today's data to Core Data cache")
            
            // Backfill historical CTL/ATL/TSS data (runs once, then uses cache)
            await cacheManager.calculateMissingCTLATL()
            Logger.debug("✅ Historical CTL/ATL backfill complete")
        } catch {
            Logger.error("Failed to save to Core Data cache: \(error)")
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        Logger.warning("️ Total refresh time: \(String(format: "%.2f", totalTime))s")
        
        isLoading = false
        isDataLoaded = true
    }
    
    /// Sync athlete profile (FTP, weight) from Strava if not available from Intervals.icu
    private func syncAthleteProfileFromStrava() async {
        // Only sync if Intervals is not connected but Strava is
        guard !oauthManager.isAuthenticated,
              case .connected = stravaAuthService.connectionState else {
            return
        }
        
        do {
            let athlete = try await stravaAPIClient.fetchAthlete()
            Logger.data("Syncing athlete profile from Strava:")
            
            let profileManager = AthleteProfileManager.shared
            var updatedProfile = profileManager.profile
            var hasUpdates = false
            
            // Sync FTP if available
            if let ftp = athlete.ftp {
                let ftpDouble = Double(ftp)
                if updatedProfile.ftp != ftpDouble {
                    updatedProfile.ftp = ftpDouble
                    updatedProfile.ftpSource = .intervals // Mark as from external source
                    hasUpdates = true
                    Logger.debug("   FTP: \(ftp)W (synced from Strava)")
                }
            }
            
            // Sync weight if available
            if let weight = athlete.weight {
                if updatedProfile.weight != weight {
                    updatedProfile.weight = weight
                    hasUpdates = true
                    Logger.debug("   Weight: \(weight)kg (synced from Strava)")
                }
            }
            
            // Save updated profile if changes were made
            if hasUpdates {
                updatedProfile.lastUpdated = Date()
                profileManager.profile = updatedProfile
                profileManager.save()
                Logger.debug("✅ Athlete profile synced from Strava")
            }
        } catch {
            Logger.warning("️ Failed to sync athlete profile from Strava: \(error.localizedDescription)")
        }
    }
    
    /// Force refresh data from API (ignoring cache)
    func forceRefreshData() async {
        Logger.debug("🔄 Force refreshing data from API...")
        
        // Refresh Core Data cache
        do {
            try await cacheManager.refreshRecentDays(count: 7, force: true)
            Logger.debug("✅ Core Data cache refreshed")
        } catch {
            Logger.error("Failed to refresh cache: \(error)")
        }
        
        // Test alcohol detection algorithm
        await recoveryScoreService.testAlcoholDetection()
        
        // Then refresh our local data
        await refreshData()
        
        // Trigger ring animations after refresh completes
        animationTrigger = UUID()
    }
    
    func refreshHealthKitAuthorizationStatus() async {
        await healthKitManager.refreshAuthorizationStatus()
    }
    
    /// PHASE 1: 2-second branded loading - load critical data for rings
    func loadInitialUI() async {
        Logger.debug("🔄 [SPINNER] loadInitialUI called - hasLoadedInitialUI=\(hasLoadedInitialUI), isInitializing=\(isInitializing)")
        // Guard against multiple calls
        guard !hasLoadedInitialUI else {
            Logger.debug("⏭️ [SPINNER] Skipping loadInitialUI - already loaded")
            return
        }
        hasLoadedInitialUI = true
        
        let startTime = CFAbsoluteTimeGetCurrent()
        Logger.debug("🎯 PHASE 1: 2-second branded loading - loading critical data for rings")
        
        // Set HealthKit status immediately
        isHealthKitAuthorized = healthKitManager.isAuthorized
        
        // Load cached data first (instant)
        loadCachedDataOnly()
        
        // Calculate ONLY the critical scores for the rings (recovery, sleep, strain)
        // This should be fast if data is cached
        Logger.debug("⚡ Loading critical scores for rings...")
        async let sleepTask: Void = sleepScoreService.calculateSleepScore()
        async let recoveryTask: Void = recoveryScoreService.calculateRecoveryScore()
        async let strainTask: Void = strainScoreService.calculateStrainScore()
        
        // Wait for all three to complete
        _ = await sleepTask
        _ = await recoveryTask
        _ = await strainTask
        Logger.debug("✅ Critical scores loaded for rings")
        
        // Ensure minimum 2-second branded loading experience
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        let remainingTime = max(0, 2.0 - elapsed)
        if remainingTime > 0 {
            Logger.debug("⏰ Waiting \(String(format: "%.2f", remainingTime))s to complete 2-second branded loading")
            try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        Logger.debug("⚡ PHASE 1 complete in \(String(format: "%.2f", totalTime))s")
        
        // PHASE 2: Show UI with rings populated, skeletons for rest
        Logger.debug("🎬 [SPINNER] PHASE 2: Showing UI with rings populated")
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.3)) {
                isInitializing = false
                isDataLoaded = true
            }
        }
        Logger.debug("✅ PHASE 2: UI displayed with rings")
        
        // PHASE 3: Background refresh for everything else (activities, etc.)
        Task {
            Logger.debug("🎯 PHASE 3: Background refresh for activities and other data...")
            await refreshActivitiesAndOtherData()
            Logger.debug("✅ PHASE 3: Background refresh completed")
        }
    }
    
    /// Load activities and other non-critical data in background
    private func refreshActivitiesAndOtherData() async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Fetch activities from all connected sources
        var intervalsActivities: [IntervalsActivity] = []
        var wellness: [IntervalsWellness] = []
        do {
            intervalsActivities = try await intervalsCache.getCachedActivities(apiClient: apiClient, forceRefresh: false)
            wellness = try await intervalsCache.getCachedWellness(apiClient: apiClient, forceRefresh: false)
            Logger.debug("✅ Loaded \(intervalsActivities.count) activities from Intervals.icu")
        } catch {
            Logger.warning("️ Intervals.icu not available: \(error.localizedDescription)")
        }
        
        // Fetch Strava activities
        await stravaDataService.fetchActivitiesIfNeeded()
        let stravaActivities = stravaDataService.activities
        
        // Fetch Apple Health workouts
        let healthWorkouts = await healthKitCache.getCachedWorkouts(healthKitManager: healthKitManager, forceRefresh: false)
        Logger.debug("✅ Loaded \(healthWorkouts.count) workouts from Apple Health")
        
        // Update activities
        recentActivities = Array(intervalsActivities.prefix(15))
        wellnessData = wellness
        
        // Convert to unified format
        var intervalsUnified: [UnifiedActivity] = []
        var stravaFilteredCount = 0
        
        for intervalsActivity in intervalsActivities {
            if let source = intervalsActivity.source, source.uppercased() == "STRAVA" {
                stravaFilteredCount += 1
                continue
            }
            intervalsUnified.append(UnifiedActivity(from: intervalsActivity))
        }
        
        let stravaUnified = stravaActivities.map { UnifiedActivity(from: $0) }
        let healthUnified = healthWorkouts.map { UnifiedActivity(from: $0) }
        
        // Deduplicate activities
        let deduplicated = deduplicationService.deduplicateActivities(
            intervalsActivities: intervalsUnified,
            stravaActivities: stravaUnified,
            appleHealthActivities: healthUnified
        )
        
        // Sort and update
        unifiedActivities = deduplicated.sorted { $0.startDate > $1.startDate }.prefix(15).map { $0 }
        
        // Save to Core Data cache
        do {
            try await cacheManager.refreshToday()
            await cacheManager.calculateMissingCTLATL()
        } catch {
            Logger.error("Failed to save to Core Data cache: \(error)")
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        Logger.debug("⚡ Background refresh completed in \(String(format: "%.2f", totalTime))s")
    }
    
    /// Load only cached data without any network calls or heavy calculations
    private func loadCachedDataOnly() {
        Logger.debug("⚡ Loading cached data only for fast startup...")
        
        // Load from Core Data cache (instant)
        let cachedDays = cacheManager.fetchCachedDays(count: 7)
        Logger.debug("⚡ Loaded \(cachedDays.count) days from Core Data cache")
        
        // Debug: Print details of cached data
        if !cachedDays.isEmpty {
            for day in cachedDays {
                Logger.data("Core Data cached day: \(String(describing: day.date))")
                Logger.debug("   Recovery: \(day.recoveryScore), Sleep: \(day.sleepScore), Strain: \(day.strainScore)")
                Logger.debug("   HRV: \(day.physio?.hrv ?? 0), RHR: \(day.physio?.rhr ?? 0)")
                Logger.debug("   CTL: \(day.load?.ctl ?? 0), ATL: \(day.load?.atl ?? 0), TSS: \(day.load?.tss ?? 0)")
            }
        } else {
            Logger.warning("️ Core Data cache is empty - will populate on background refresh")
        }
        
        // Load cached activities from UserDefaults (fallback)
        if let cachedActivities = getCachedActivitiesSync() {
            recentActivities = Array(cachedActivities.prefix(15))
            Logger.debug("⚡ Loaded \(recentActivities.count) cached activities instantly")
        }
        
        // Set HealthKit status immediately
        isHealthKitAuthorized = healthKitManager.isAuthorized
    }
    
    /// Get cached activities synchronously (no network calls)
    private func getCachedActivitiesSync() -> [IntervalsActivity]? {
        guard let data = UserDefaults.standard.data(forKey: "intervals_activities") else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode([IntervalsActivity].self, from: data)
        } catch {
            Logger.error("Failed to decode cached activities: \(error)")
            return nil
        }
    }
    
    private func loadInitialDataFast() {
        // ULTRA-FAST initialization - just set defaults, no expensive operations
        recentActivities = []
        wellnessData = []
        
        // HealthKit status is now observed from HealthKitManager
        isHealthKitAuthorized = healthKitManager.isAuthorized
        
        Logger.debug("⚡ Ultra-fast initialization completed - no heavy operations")
    }
    
    // HealthKit data loading will be handled by new HealthKitManager
}

// MARK: - Activity Model

struct Activity: Identifiable, Codable {
    let id: UUID
    let title: String
    let date: Date
    let distance: String
    let duration: String
    let averageSpeed: String
    
    init(title: String, date: Date, distance: String, duration: String, averageSpeed: String) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.distance = distance
        self.duration = duration
        self.averageSpeed = averageSpeed
    }
    
    static let mockData: [Activity] = [
        Activity(
            title: "Morning Ride",
            date: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            distance: "15.2 km",
            duration: "45 min",
            averageSpeed: "20.3 km/h"
        ),
        Activity(
            title: "Evening Commute",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            distance: "8.7 km",
            duration: "25 min",
            averageSpeed: "20.9 km/h"
        ),
        Activity(
            title: "Weekend Adventure",
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            distance: "42.1 km",
            duration: "2h 15min",
            averageSpeed: "18.7 km/h"
        )
    ]
}