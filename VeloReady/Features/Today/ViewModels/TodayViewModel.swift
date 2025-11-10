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
    
    // Loading state management
    @ObservedObject var loadingStateManager = LoadingStateManager()
    
    // Track if initial UI has been loaded to prevent duplicate calls
    private var hasLoadedInitialUI = false
    
    // Health Status
    @Published var isHealthKitAuthorized = false
    
    // MARK: - Dependencies (via ServiceContainer)
    
    private let services = ServiceContainer.shared
    
    // Convenience accessors for frequently used services
    private var oauthManager: IntervalsOAuthManager { services.intervalsOAuthManager }
    private var apiClient: IntervalsAPIClient { services.intervalsAPIClient }
    private var healthKitManager: HealthKitManager { services.healthKitManager }
    private var stravaAuthService: StravaAuthService { services.stravaAuthService }
    private var stravaDataService: StravaDataService { services.stravaDataService }
    private var stravaAPIClient: StravaAPIClient { services.stravaAPIClient }
    private var cacheManager: CacheManager { services.cacheManager }
    private var deduplicationService: ActivityDeduplicationService { services.deduplicationService }
    
    let recoveryScoreService: RecoveryScoreService
    let sleepScoreService: SleepScoreService
    let strainScoreService: StrainScoreService
    let scoresCoordinator: ScoresCoordinator  // NEW: Week 2 - Single source of truth for scores
    
    // Observer for HealthKit authorization changes
    private var healthKitObserver: AnyCancellable?

    // Observer for network state changes
    private var networkObserver: AnyCancellable?
    private var wasOffline = false

    // PERFORMANCE FIX: Track background tasks for cancellation
    private var backgroundTasks: [Task<Void, Never>] = []
    
    /// Cancel all background tasks (call when view disappears or on memory warning)
    func cancelBackgroundTasks() {
        Logger.debug("🛑 Cancelling \(backgroundTasks.count) background tasks")
        backgroundTasks.forEach { $0.cancel() }
        backgroundTasks.removeAll()
    }
    
    deinit {
        // Directly cancel tasks (can't call @MainActor method from deinit)
        Logger.debug("🗑️ TodayViewModel deinit - cancelling \(backgroundTasks.count) background tasks")
        backgroundTasks.forEach { $0.cancel() }
    }
    
    /// Clear baseline cache to force fresh calculation from HealthKit
    func clearBaselineCache() {
        Task { await recoveryScoreService.clearBaselineCache() }
        Logger.debug("🗑️ Cleared baseline cache - will fetch fresh historical data from HealthKit")
    }
    
    /// Force refresh HealthKit workouts
    func forceRefreshHealthKitWorkouts() async {
        Logger.debug("🔄 Force refreshing HealthKit workouts...")
        // HealthKitCache deleted - refresh happens automatically in refreshData()
        await refreshData()
    }
    
    private init(container: ServiceContainer = .shared) {
        // Use score services from container
        self.recoveryScoreService = container.recoveryScoreService
        self.sleepScoreService = container.sleepScoreService
        self.strainScoreService = container.strainScoreService
        self.scoresCoordinator = container.scoresCoordinator  // NEW: Week 2
        
        Logger.debug("🎬 [SPINNER] TodayViewModel init - isInitializing=\(isInitializing)")
        
        // Setup HealthKit observer
        healthKitObserver = container.healthKitManager.$isAuthorized
            .sink { [weak self] isAuthorized in
                DispatchQueue.main.async {
                    self?.isHealthKitAuthorized = isAuthorized
                }
            }

        // Setup network state observer to show syncing status when coming back online
        setupNetworkObserver()

        // ULTRA-FAST initialization - no expensive operations
        loadInitialDataFast()
        Logger.debug("✅ [SPINNER] TodayViewModel init complete - isInitializing=\(isInitializing)")
    }

    /// Setup observer for network state changes to show offline/syncing status
    private func setupNetworkObserver() {
        // Check initial network state immediately
        let initialState = NetworkMonitor.shared.isConnected
        Logger.debug("🌐 [NETWORK] Initial network state: \(initialState ? "ONLINE" : "OFFLINE")")
        if !initialState {
            Logger.debug("📡 [Network] Initial state: offline - showing offline status")
            loadingStateManager.forceState(.offline)
        }
        wasOffline = !initialState

        networkObserver = NetworkMonitor.shared.$isConnected
            .sink { [weak self] isConnected in
                guard let self = self else { return }

                Task { @MainActor in
                    Logger.debug("🌐 [NETWORK] Network state changed: \(isConnected ? "ONLINE" : "OFFLINE") (wasOffline: \(self.wasOffline))")
                    
                    // CRITICAL: Check score services BEFORE any state changes
                    Logger.debug("🌐 [NETWORK] Score state BEFORE handling network change:")
                    Logger.debug("   Recovery: \(self.recoveryScoreService.currentRecoveryScore?.score ?? -999)")
                    Logger.debug("   Sleep: \(self.sleepScoreService.currentSleepScore?.score ?? -999)")
                    Logger.debug("   Strain: \(self.strainScoreService.currentStrainScore?.score ?? -999)")
                    
                    if !isConnected {
                        // Device went offline - show offline status
                        Logger.debug("📡 [Network] Device offline - showing offline status (scores should REMAIN)")
                        self.loadingStateManager.forceState(.offline)
                        
                        // Check scores AFTER going offline
                        Logger.debug("🌐 [NETWORK] Score state AFTER going offline:")
                        Logger.debug("   Recovery: \(self.recoveryScoreService.currentRecoveryScore?.score ?? -999)")
                        Logger.debug("   Sleep: \(self.sleepScoreService.currentSleepScore?.score ?? -999)")
                        Logger.debug("   Strain: \(self.strainScoreService.currentStrainScore?.score ?? -999)")
                    } else if self.wasOffline && isConnected {
                        // Detect offline → online transition - show syncing status then refresh
                        Logger.debug("📡 [Network] Came back online - showing syncing status (scores should REMAIN)")
                        
                        // Show syncing state with rotating icon (green)
                        self.loadingStateManager.updateState(.syncingData)
                        
                        // Check scores AFTER showing syncing state
                        Logger.debug("🌐 [NETWORK] Score state AFTER showing syncing state:")
                        Logger.debug("   Recovery: \(self.recoveryScoreService.currentRecoveryScore?.score ?? -999)")
                        Logger.debug("   Sleep: \(self.sleepScoreService.currentSleepScore?.score ?? -999)")
                        Logger.debug("   Strain: \(self.strainScoreService.currentStrainScore?.score ?? -999)")
                        
                        // Small delay to ensure syncing state is visible
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                        
                        Logger.debug("🌐 [NETWORK] About to call refreshData()")
                        // Actually refresh the data (this will update loading states naturally)
                        await self.refreshData()
                        
                        // Check scores AFTER refresh
                        Logger.debug("🌐 [NETWORK] Score state AFTER refreshData():")
                        Logger.debug("   Recovery: \(self.recoveryScoreService.currentRecoveryScore?.score ?? -999)")
                        Logger.debug("   Sleep: \(self.sleepScoreService.currentSleepScore?.score ?? -999)")
                        Logger.debug("   Strain: \(self.strainScoreService.currentStrainScore?.score ?? -999)")
                    }

                    self.wasOffline = !isConnected
                    Logger.debug("🌐 [NETWORK] Network state handling complete. wasOffline now: \(!isConnected)")
                }
            }
    }

    func refreshData(forceRecoveryRecalculation: Bool = false) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        Logger.warning("️ [REFRESH] Starting full data refresh...")
        
        // CRITICAL: Check scores at START of refresh
        Logger.debug("🔍 [REFRESH] Score state at START of refreshData():")
        Logger.debug("   Recovery: \(recoveryScoreService.currentRecoveryScore?.score ?? -999)")
        Logger.debug("   Sleep: \(sleepScoreService.currentSleepScore?.score ?? -999)")
        Logger.debug("   Strain: \(strainScoreService.currentStrainScore?.score ?? -999)")
        
        // OPTIMIZATION: Check cache validity before showing "contacting integrations"
        let activeSources = getActiveIntegrations()
        let cacheKey = CacheKey.stravaActivities(daysBack: 7)
        let cacheTTL: TimeInterval = 3600 // 1 hour
        let hasFreshCache = await UnifiedCacheManager.shared.isCacheValid(key: cacheKey, ttl: cacheTTL)
        
        if !hasFreshCache && !activeSources.isEmpty {
            // Cache is stale/missing - we'll need to contact integrations
            Logger.debug("📡 Cache stale - showing 'contacting integrations' message")
            loadingStateManager.updateState(.contactingIntegrations(sources: activeSources))
        } else {
            // Cache is fresh - just show checking for updates
            Logger.debug("⚡ Cache fresh (age: \(hasFreshCache ? "valid" : "missing")) - skipping 'contacting integrations' message")
            loadingStateManager.updateState(.checkingForUpdates)
        }
        
        isLoading = true
        // CRITICAL FIX: DON'T clear isDataLoaded during refresh!
        // This prevents scores from disappearing when returning to app after offline/online
        // isDataLoaded = false  // ❌ REMOVED - causes scores to disappear
        errorMessage = nil
        
        // Fetch activities from all connected sources
        
        // Try to fetch Intervals activities (optional)
        var intervalsActivities: [IntervalsActivity] = []
        var wellness: [IntervalsWellness] = []
        do {
            // Use UnifiedActivityService for activities (replaces IntervalsCache)
            intervalsActivities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 100, daysBack: 90)
            wellness = []
            Logger.debug("✅ Loaded \(intervalsActivities.count) activities from Intervals.icu")
        } catch {
            Logger.warning("️ Intervals.icu not available: \(error.localizedDescription)")
        }
        
        // Fetch Strava activities using shared service
        await stravaDataService.fetchActivitiesIfNeeded()
        let stravaActivities = stravaDataService.activities
        
        // Always fetch Apple Health workouts (replaces HealthKitCache)
        let healthWorkouts = await healthKitManager.fetchRecentWorkouts(daysBack: 90)
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
        Logger.debug("⚡ Starting score calculations via ScoresCoordinator...")
        
        // NEW: Use ScoresCoordinator for orchestrated score calculation
        // This replaces 3 separate service calls with a single coordinated call
        await scoresCoordinator.calculateAll(forceRefresh: forceRecoveryRecalculation)
        
        Logger.debug("✅ All score calculations completed via coordinator")
        
        // Save to Core Data cache after scores are calculated
        do {
            try await cacheManager.refreshToday()
            Logger.debug("💾 Saved today's data to Core Data cache")
            
            // Move heavy CTL/ATL backfill to background (14+ seconds, non-blocking)
            Task.detached(priority: .background) {
                await CacheManager.shared.calculateMissingCTLATL()
                await MainActor.run {
                    Logger.debug("✅ Historical CTL/ATL backfill complete (background)")
                }
            }
        } catch {
            Logger.error("Failed to save to Core Data cache: \(error)")
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        Logger.warning("️ [REFRESH] Total refresh time: \(String(format: "%.2f", totalTime))s")
        
        // CRITICAL: Check scores BEFORE marking complete
        Logger.debug("🔍 [REFRESH] Score state BEFORE marking complete:")
        Logger.debug("   Recovery: \(recoveryScoreService.currentRecoveryScore?.score ?? -999)")
        Logger.debug("   Sleep: \(sleepScoreService.currentSleepScore?.score ?? -999)")
        Logger.debug("   Strain: \(strainScoreService.currentStrainScore?.score ?? -999)")
        
        // Mark loading as complete
        loadingStateManager.updateState(.complete)
        
        isLoading = false
        isDataLoaded = true
        
        // CRITICAL: Check scores at END of refresh
        Logger.debug("🔍 [REFRESH] Score state at END of refreshData():")
        Logger.debug("   Recovery: \(recoveryScoreService.currentRecoveryScore?.score ?? -999)")
        Logger.debug("   Sleep: \(sleepScoreService.currentSleepScore?.score ?? -999)")
        Logger.debug("   Strain: \(strainScoreService.currentStrainScore?.score ?? -999)")
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
        
        // DON'T set isDataLoaded = false during pull-to-refresh
        // Keep content visible while refreshing
        
        // Update loading state
        let activeSources = getActiveIntegrations()
        loadingStateManager.updateState(.contactingIntegrations(sources: activeSources))
        
        isLoading = true
        errorMessage = nil
        
        // Refresh Core Data cache
        do {
            try await cacheManager.refreshRecentDays(count: 7, force: true)
            Logger.debug("✅ Core Data cache refreshed")
        } catch {
            Logger.error("Failed to refresh cache: \(error)")
        }
        
        // Test alcohol detection algorithm
        await recoveryScoreService.testAlcoholDetection()
        
        // Refresh activities (this will show various loading states)
        await refreshActivitiesAndOtherData()
        
        // Show calculating scores status (overrides the .complete state from refreshActivitiesAndOtherData)
        let hasSleepData = sleepScoreService.currentSleepScore != nil
        loadingStateManager.updateState(.calculatingScores(hasHealthKit: true, hasSleepData: hasSleepData))
        
        // NEW: Use ScoresCoordinator for orchestrated refresh
        await scoresCoordinator.refresh()
        
        isLoading = false
        
        // Show brief complete state
        loadingStateManager.updateState(.complete)
        
        // Then show persistent "Updated just now" status
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        loadingStateManager.updateState(.updated(Date()))
        
        // Trigger ring animations after refresh completes
        animationTrigger = UUID()
    }
    
    func refreshHealthKitAuthorizationStatus() async {
        await healthKitManager.refreshAuthorizationStatus()
    }
    
    /// Retry loading after an error
    func retryLoading() {
        loadingStateManager.reset()
        Task {
            await loadInitialUI()
        }
    }
    
    /// PHASE 1: Instant Display (<200ms) - Show cached/yesterday's data immediately
    func loadInitialUI() async {
        Logger.debug("🔄 [SPINNER] loadInitialUI called - hasLoadedInitialUI=\(hasLoadedInitialUI), isInitializing=\(isInitializing)")
        // Guard against multiple calls
        guard !hasLoadedInitialUI else {
            Logger.debug("⏭️ [SPINNER] Skipping loadInitialUI - already loaded")
            return
        }
        hasLoadedInitialUI = true
        
        let startTime = CFAbsoluteTimeGetCurrent()
        Logger.debug("🎯 PHASE 1: Instant Display (<200ms) - showing cached/yesterday's data")
        
        // Set HealthKit status immediately
        isHealthKitAuthorized = healthKitManager.isAuthorized
        
        // Load cached data first (instant)
        loadCachedDataOnly()
        
        // OPTIMIZATION: Show UI with cached data, but maintain 2-second brand spinner
        let phase1Time = CFAbsoluteTimeGetCurrent() - startTime
        Logger.debug("⚡ PHASE 1 complete in \(String(format: "%.3f", phase1Time))s - cached data ready")
        
        // Mark data as loaded so UI content is ready (will show after spinner)
        await MainActor.run {
            isDataLoaded = true
        }
        Logger.debug("✅ Cached data loaded after \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - startTime))s")
        
        // PHASE 2: Brand Spinner (2s) + Background Score Calculations
        // Start score calculations immediately in background (don't wait for spinner)
        let scoreCalculationTask = Task {
            // CRITICAL FIX: Wait for token refresh to complete before Phase 2
            await SupabaseClient.shared.waitForRefreshIfNeeded()
            
            let phase2Start = CFAbsoluteTimeGetCurrent()
            Logger.debug("🎯 PHASE 2 (Background): Starting parallel score calculations during spinner")
            
            // NEW: Use ScoresCoordinator for orchestrated initial calculation
            await self.scoresCoordinator.calculateAll()
            
            let phase2Time = CFAbsoluteTimeGetCurrent() - phase2Start
            Logger.debug("✅ PHASE 2 complete in \(String(format: "%.2f", phase2Time))s - all scores ready via coordinator")
        }
        
        // Show brand spinner for exactly 2 seconds (brand experience)
        let minimumSpinnerTime: TimeInterval = 2.0
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        let remainingTime = max(0, minimumSpinnerTime - elapsedTime)
        
        if remainingTime > 0 {
            Logger.debug("🎨 [BRAND] Showing animated logo for \(String(format: "%.2f", remainingTime))s (brand experience)")
            try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
        }
        
        // Hide spinner and show UI (with skeletons if scores not ready yet)
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.3)) {
                isInitializing = false
            }
        }
        Logger.debug("✅ UI displayed after \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - startTime))s")
        Logger.debug("🎨 [BRAND] Spinner hidden - UI shows with progressive score population")
        
        // Wait for scores to finish calculating (if not done already)
        await scoreCalculationTask.value
        
        // Scores populate progressively as they become available
        // UI already shows skeleton/compact rings, will update automatically via @Published
        Logger.debug("✅ PHASE 2/3 complete - UI showing with progressive score population")
        
        // Trigger ring animations and haptic feedback when all scores are ready
        await MainActor.run {
            animationTrigger = UUID()
            
            // Subtle haptic feedback when scores complete
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            Logger.debug("📳 Haptic feedback triggered - all scores populated")
        }
        
        // PHASE 4: Background Updates (4-5s) - Non-blocking
        // Activities, trends, training load - happens in background
        Task.detached(priority: .background) {
            let phase4Start = CFAbsoluteTimeGetCurrent()
            await Logger.debug("🎯 PHASE 4: Background Updates - activities, trends, training load")
            
            // CRITICAL: Wait for token refresh before API calls
            await SupabaseClient.shared.waitForRefreshIfNeeded()
            
            // Update loading state: checking for updates (generic)
            await MainActor.run {
                self.loadingStateManager.updateState(.checkingForUpdates)
            }
            
            // Fetch activities and other non-critical data
            await self.refreshActivitiesAndOtherData()
            
            let phase4Time = CFAbsoluteTimeGetCurrent() - phase4Start
            await Logger.debug("✅ PHASE 4 complete in \(String(format: "%.2f", phase4Time))s - background work done")
            
            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            await Logger.debug("✅ ALL PHASES complete in \(String(format: "%.2f", totalTime))s")
        }
    }
    
    /// Load activities and other non-critical data in background
    /// SIMPLIFIED: Single fetch of 90 days (covers all use cases), then filter as needed
    private func refreshActivitiesAndOtherData() async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // PERFORMANCE FIX: Cancel any existing background tasks before starting new ones
        backgroundTasks.forEach { $0.cancel() }
        backgroundTasks.removeAll()
        
        // OPTIMIZATION: Check cache validity BEFORE showing "contacting integrations"
        // Only show loading state if we'll actually make network requests
        let activeSources = getActiveIntegrations()
        let cacheKey = CacheKey.stravaActivities(daysBack: 90)
        let cacheTTL: TimeInterval = 3600 // 1 hour
        let hasFreshCache = await UnifiedCacheManager.shared.isCacheValid(key: cacheKey, ttl: cacheTTL)
        
        if !hasFreshCache && !activeSources.isEmpty {
            // Cache is stale/missing - we'll need to contact integrations
            Logger.debug("📡 Cache stale - showing 'contacting integrations' message")
            loadingStateManager.updateState(.contactingIntegrations(sources: activeSources))
        } else {
            // Cache is fresh - just show checking for updates (brief)
            Logger.debug("⚡ Cache fresh - skipping 'contacting integrations' message")
            loadingStateManager.updateState(.checkingForUpdates)
        }
        
        // SIMPLIFIED: Single fetch of 90 days (covers all use cases)
        // Benefits: 1 network request, no race conditions, cache-friendly, simpler code
        Logger.debug("📊 [SINGLE FETCH] Fetching 90 days of activities...")
        loadingStateManager.updateState(.downloadingActivities(count: nil, source: nil))
        await fetchAndUpdateActivities(daysBack: 90)
        Logger.debug("✅ [SINGLE FETCH] Activities loaded (\(unifiedActivities.count) shown)")
        
        // Optional: Fetch full 365-day history in background for trends/analytics
        // This is truly optional and doesn't affect the Today page UI
        Logger.debug("📊 [BACKGROUND] Fetching full 365-day history for analytics...")
        let historyTask = Task.detached(priority: .utility) {
            guard !Task.isCancelled else {
                await Logger.debug("🛑 [TASK] Full history fetch cancelled")
                return
            }
            // Fetch 365 days in background for trends/FTP calculation
            await self.stravaDataService.fetchActivities(daysBack: 365)
            await MainActor.run {
                Logger.debug("✅ [BACKGROUND] Full history loaded (\(self.stravaDataService.activities.count) activities)")
            }
        }
        backgroundTasks.append(historyTask)
        
        // Also fetch wellness data (non-blocking)
        // PERFORMANCE FIX: Track task for cancellation
        let wellnessTask = Task.detached(priority: .background) {
            do {
                let wellness: [IntervalsWellness] = []
                await MainActor.run {
                    self.wellnessData = wellness
                    Logger.debug("✅ Loaded wellness data")
                }
            } catch {
                await Logger.error("❌ Failed to load wellness: \(error.localizedDescription)")
            }
        }
        backgroundTasks.append(wellnessTask)
        
        // User-visible refresh should complete in <3s, background work continues silently
        
        // Show saving state before background work
        loadingStateManager.updateState(.savingToICloud)
        
        // Background task: Core Data save + CTL/ATL calculation
        let coreDataTask = Task.detached(priority: .utility) {
            guard !Task.isCancelled else {
                await Logger.debug("🛑 [TASK] Core Data save cancelled")
                return
            }
            do {
                try await self.cacheManager.refreshToday()
                
                // CTL/ATL backfill (heavy computation)
                await CacheManager.shared.calculateMissingCTLATL()
                await MainActor.run {
                    Logger.debug("☁️ Core Data + CTL/ATL complete (background)")
                }
            } catch {
                Logger.error("Failed to save to Core Data cache: \(error)")
            }
        }
        backgroundTasks.append(coreDataTask)
        
        // Background task: Training load fetch (week/month/3-month data)
        let trainingLoadTask = Task.detached(priority: .utility) {
            guard !Task.isCancelled else {
                await Logger.debug("🛑 [TASK] Training load fetch cancelled")
                return
            }
            await TrainingLoadService.shared.fetchAllData()
            await MainActor.run {
                Logger.debug("📊 Training load data fetched (background)")
            }
        }
        backgroundTasks.append(trainingLoadTask)
        
        // CRITICAL: Wait for savingToICloud to display (min 0.6s) before showing complete
        // This ensures the user sees the "Saving to iCloud" status
        try? await Task.sleep(nanoseconds: 700_000_000) // 0.7s (gives savingToICloud time to show)
        
        // Mark user-visible work as COMPLETE (no processingData/syncingData delay)
        // Background tasks continue without blocking UI
        loadingStateManager.updateState(.complete)
        
        // After brief complete state, show persistent "Updated just now" status
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay
        loadingStateManager.updateState(.updated(Date()))
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        Logger.debug("⚡ Background refresh completed in \(String(format: "%.2f", totalTime))s")
        
        // Notify that Today data has been refreshed (for ML progress bar, etc.)
        NotificationCenter.default.post(name: .todayDataRefreshed, object: nil)
    }
    
    /// Fetch and update activities for a specific time range
    /// - Parameter daysBack: Number of days to fetch
    private func fetchAndUpdateActivities(daysBack: Int) async {
        // Fetch activities from all connected sources
        var intervalsActivities: [IntervalsActivity] = []
        do {
            // Use UnifiedActivityService (replaces IntervalsCache)
            intervalsActivities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 500, daysBack: daysBack)
            Logger.debug("✅ Loaded \(intervalsActivities.count) activities from Intervals.icu")
        } catch {
            Logger.warning("️ Intervals.icu not available: \(error.localizedDescription)")
        }
        
        // Fetch Strava activities for specific time range
        await stravaDataService.fetchActivities(daysBack: daysBack)
        let stravaActivities = stravaDataService.activities
        
        // Fetch Apple Health workouts (replaces HealthKitCache)
        let healthWorkouts = await healthKitManager.fetchRecentWorkouts(daysBack: daysBack)
        Logger.debug("✅ Loaded \(healthWorkouts.count) workouts from Apple Health")
        
        // Update activities
        recentActivities = Array(intervalsActivities.prefix(15))
        
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
        
        // Deduplicate activities across all sources
        let deduplicated = deduplicationService.deduplicateActivities(
            intervalsActivities: intervalsUnified,
            stravaActivities: stravaUnified,
            appleHealthActivities: healthUnified
        )
        
        // Sort by date and take top 15 for display
        unifiedActivities = deduplicated.sorted { $0.startDate > $1.startDate }.prefix(15).map { $0 }
        Logger.debug("📊 Showing \(unifiedActivities.count) unified activities from \(daysBack) days")
    }
    
    /// Load only cached data without any network calls or heavy calculations
    private func loadCachedDataOnly() {
        Logger.debug("⚡ Loading cached data only for fast startup...")
        
        // Load from Core Data cache (instant)
        let cachedDays = cacheManager.fetchCachedDays(count: 7)
        Logger.debug("⚡ Loaded \(cachedDays.count) days from Core Data cache")
        
        // Find today's cached data, or yesterday's as fallback
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Try to load today's scores from Core Data cache
        let todayCache = cachedDays.first { day in
            guard let date = day.date else { return false }
            return calendar.isDate(date, inSameDayAs: today)
        }
        
        // Try yesterday's cache as fallback
        let yesterdayCache = cachedDays.first { day in
            guard let date = day.date else { return false }
            return calendar.isDate(date, inSameDayAs: yesterday)
        }
        
        // Use today's cache if available, otherwise yesterday's
        if let cache = todayCache {
            Logger.debug("✅ Using today's cached scores")
            // Scores will be loaded by score services from their own caches
        } else if let cache = yesterdayCache {
            Logger.debug("⚡ No today's cache - using yesterday's scores as placeholder")
            // Show yesterday's scores as stale placeholders
            // The score services will replace these with today's values in Phase 2
        } else {
            Logger.warning("️ No cached scores (today or yesterday) - UI will show empty rings")
        }
        
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
    
    // MARK: - Integration Detection Helpers
    
    /// Detect which external integrations are currently active
    private func getActiveIntegrations() -> [LoadingState.DataSource] {
        var sources: [LoadingState.DataSource] = []
        
        // Check Strava connection
        if case .connected = stravaAuthService.connectionState {
            sources.append(.strava)
        }
        
        // Check Intervals.icu connection
        if oauthManager.isAuthenticated {
            sources.append(.intervalsIcu)
        }
        
        return sources
    }
    
    /// Check if sleep data is available
    private func hasSleepData() async -> Bool {
        // Check if we have recent sleep data (last 24 hours)
        guard healthKitManager.isAuthorized else { return false }
        
        // Simple check: if sleep score service has current sleep score
        return sleepScoreService.currentSleepScore != nil
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