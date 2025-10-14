import Foundation
import SwiftUI
import Combine

/// ViewModel for the Today feature
@MainActor
class TodayViewModel: ObservableObject {
    @Published var recentActivities: [IntervalsActivity] = [] // Keep for backwards compatibility
    @Published var unifiedActivities: [UnifiedActivity] = [] // New unified list
    @Published var wellnessData: [IntervalsWellness] = []
    @Published var isLoading = false
    @Published var isInitializing = true
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
        print("🗑️ Cleared baseline cache - will fetch fresh historical data from HealthKit")
    }
    
    /// Force refresh HealthKit workouts (clears cache)
    func forceRefreshHealthKitWorkouts() async {
        print("🔄 Force refreshing HealthKit workouts...")
        healthKitCache.clearCache()
        await refreshData()
    }
    
    init(container: ServiceContainer = .shared) {
        // Use score services from container
        self.recoveryScoreService = container.recoveryScoreService
        self.sleepScoreService = container.sleepScoreService
        self.strainScoreService = container.strainScoreService
        
        // Setup HealthKit observer
        healthKitObserver = container.healthKitManager.$isAuthorized
            .sink { [weak self] isAuthorized in
                DispatchQueue.main.async {
                    self?.isHealthKitAuthorized = isAuthorized
                }
            }
        
        // ULTRA-FAST initialization - no expensive operations
        loadInitialDataFast()
    }
    
    func refreshData(forceRecoveryRecalculation: Bool = false) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        print("⏱️ Starting full data refresh...")
        
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
            print("✅ Loaded \(intervalsActivities.count) activities from Intervals.icu")
        } catch {
            print("⚠️ Intervals.icu not available: \(error.localizedDescription)")
        }
        
        // Fetch Strava activities using shared service
        await stravaDataService.fetchActivitiesIfNeeded()
        let stravaActivities = stravaDataService.activities
        
        // Always fetch Apple Health workouts
        let healthWorkouts = await healthKitCache.getCachedWorkouts(healthKitManager: healthKitManager, forceRefresh: false)
        print("✅ Loaded \(healthWorkouts.count) workouts from Apple Health")
        
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
        
        print("🔍 Filtered Intervals activities: \(intervalsActivities.count) total → \(intervalsUnified.count) native (removed \(stravaFilteredCount) Strava)")
        
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
        
        print("🔍 Found \(intervalsUnified.count) Intervals + \(stravaActivities.count) Strava + \(healthWorkouts.count) Apple Health")
        print("🔍 Showing \(unifiedActivities.count) unique unified activities (after deduplication)")
        for activity in unifiedActivities.prefix(5) {
            print("🔍 Activity: \(activity.name) - Type: \(activity.type.rawValue) - Source: \(activity.source)")
        }
        print("⚡ Starting parallel score calculations...")
        
        async let sleepTask = sleepScoreService.calculateSleepScore()
        async let strainTask = strainScoreService.calculateStrainScore()
        
        // Wait for sleep score first (needed for recovery)
        await sleepTask
        print("✅ Sleep score calculated")
        
        // Start recovery calculation after sleep is done
        // Use force refresh if HealthKit was just authorized to get fresh health data
        let recoveryTask = Task {
            if forceRecoveryRecalculation {
                await recoveryScoreService.forceRefreshRecoveryScoreIgnoringDailyLimit()
            } else {
                await recoveryScoreService.calculateRecoveryScore()
            }
        }
        
        // Wait for all remaining calculations
        await strainTask
        await recoveryTask.value
        
        print("✅ All score calculations completed")
        
        // Save to Core Data cache after scores are calculated
        do {
            try await cacheManager.refreshToday()
            print("💾 Saved today's data to Core Data cache")
        } catch {
            print("❌ Failed to save to Core Data cache: \(error)")
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        print("⏱️ Total refresh time: \(String(format: "%.2f", totalTime))s")
        
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
            print("📊 Syncing athlete profile from Strava:")
            
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
                    print("   FTP: \(ftp)W (synced from Strava)")
                }
            }
            
            // Sync weight if available
            if let weight = athlete.weight {
                if updatedProfile.weight != weight {
                    updatedProfile.weight = weight
                    hasUpdates = true
                    print("   Weight: \(weight)kg (synced from Strava)")
                }
            }
            
            // Save updated profile if changes were made
            if hasUpdates {
                updatedProfile.lastUpdated = Date()
                profileManager.profile = updatedProfile
                profileManager.save()
                print("✅ Athlete profile synced from Strava")
            }
        } catch {
            print("⚠️ Failed to sync athlete profile from Strava: \(error.localizedDescription)")
        }
    }
    
    /// Force refresh data from API (ignoring cache)
    func forceRefreshData() async {
        print("🔄 Force refreshing data from API...")
        
        // Refresh Core Data cache
        do {
            try await cacheManager.refreshRecentDays(count: 7, force: true)
            print("✅ Core Data cache refreshed")
        } catch {
            print("❌ Failed to refresh cache: \(error)")
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
    
    /// PHASE 2: Load UI framework only (skeleton/empty state) - no heavy operations
    func loadInitialUI() async {
        // Guard against multiple calls
        guard !hasLoadedInitialUI else {
            return
        }
        hasLoadedInitialUI = true
        
        let startTime = CFAbsoluteTimeGetCurrent()
        print("🎯 PHASE 2: Loading UI framework (skeleton/empty state)")
        
        // Set HealthKit status immediately (lightweight)
        isHealthKitAuthorized = healthKitManager.isAuthorized
        
        // Load only cached data for instant UI (no network calls)
        loadCachedDataOnly()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let startupTime = endTime - startTime
        print("⚡ PHASE 2: UI framework loaded in \(String(format: "%.3f", startupTime))s")
        
        // PHASE 3: Defer ALL heavy operations to background
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            print("🎯 PHASE 3: Starting background data refresh...")
            await refreshData()
            
            // Mark as initialized and data loaded with smooth transition
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    isInitializing = false
                    isDataLoaded = true
                }
            }
            print("✅ PHASE 3: Background data refresh completed")
        }
    }
    
    /// Load only cached data without any network calls or heavy calculations
    private func loadCachedDataOnly() {
        print("⚡ Loading cached data only for fast startup...")
        
        // Load from Core Data cache (instant)
        let cachedDays = cacheManager.fetchCachedDays(count: 7)
        print("⚡ Loaded \(cachedDays.count) days from Core Data cache")
        
        // Debug: Print details of cached data
        if !cachedDays.isEmpty {
            for day in cachedDays {
                print("📊 Core Data cached day: \(day.date)")
                print("   Recovery: \(day.recoveryScore), Sleep: \(day.sleepScore), Strain: \(day.strainScore)")
                print("   HRV: \(day.physio?.hrv ?? 0), RHR: \(day.physio?.rhr ?? 0)")
                print("   CTL: \(day.load?.ctl ?? 0), ATL: \(day.load?.atl ?? 0), TSS: \(day.load?.tss ?? 0)")
            }
        } else {
            print("⚠️ Core Data cache is empty - will populate on background refresh")
        }
        
        // Load cached activities from UserDefaults (fallback)
        if let cachedActivities = getCachedActivitiesSync() {
            recentActivities = Array(cachedActivities.prefix(15))
            print("⚡ Loaded \(recentActivities.count) cached activities instantly")
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
            print("❌ Failed to decode cached activities: \(error)")
            return nil
        }
    }
    
    private func loadInitialDataFast() {
        // ULTRA-FAST initialization - just set defaults, no expensive operations
        recentActivities = []
        wellnessData = []
        
        // HealthKit status is now observed from HealthKitManager
        isHealthKitAuthorized = healthKitManager.isAuthorized
        
        print("⚡ Ultra-fast initialization completed - no heavy operations")
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