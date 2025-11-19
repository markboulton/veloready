import SwiftUI
import BackgroundTasks

@main
struct VeloReadyApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Log version information at startup
        AppVersion.logVersionInfo()

        // OPTIMIZATION: Consolidate critical tasks (8 → 3)
        // Run ONLY critical tasks immediately, defer others to after UI loads

        // CRITICAL TASK 1: Core infrastructure (runs sequentially for safety)
        Task { @MainActor in
            // 1a. Verify cache version synchronization
            _ = CacheVersion.verifySynchronization()

            // 1b. Refresh Supabase token
            await SupabaseClient.shared.refreshOnAppLaunch()

            // 1c. Initialize service container
            ServiceContainer.shared.initialize()

            // 1d. Register Today view components (Phase 2 - Component Migration)
            TodayComponentRegistry.shared.register(RecoveryMetricsComponent.self)
            TodayComponentRegistry.shared.register(HealthWarningsComponent.self)
            TodayComponentRegistry.shared.register(LatestActivityComponent.self)
            TodayComponentRegistry.shared.register(StepsComponent.self)
            TodayComponentRegistry.shared.register(CaloriesComponent.self)

            // 1e. Configure AI Brief
            AIBriefConfig.configure()

            Logger.debug("✅ [APP LAUNCH] Core infrastructure initialized")
        }

        // CRITICAL TASK 2: Background task registration (sync, no Task needed)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.veloready.app.refresh", using: nil) { task in
            Self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }

        // CRITICAL TASK 3: Deferred non-critical tasks (runs after 3s delay)
        Task.detached {
            // Wait for UI to render and settle
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

            await MainActor.run {
                Logger.debug("🔄 [APP LAUNCH] Starting deferred tasks...")

                // Deferred: Workout metadata migration
                WorkoutMetadataService.shared.migrateAllLegacyData()

                // Deferred: Legacy cleanup
                Self.cleanupLegacyStravaStreams()

                // Deferred: iCloud sync
                iCloudSyncService.shared.enableAutomaticSync()

                Logger.debug("✅ [APP LAUNCH] Deferred tasks complete")
            }
        }

        // NOTE: Historical physio backfill removed from automatic startup
        // Users can manually trigger via Settings → Debug → "Sync Historical Data"
        // This prevents potential 60-day backfill from slowing first launch
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // Clear runtime flag so next launch will show branding (if app was killed)
                    UserDefaults.standard.set(false, forKey: "app_was_running_flag")
                    Logger.debug("🎬 [BRANDING] Cleared runtime flag - app going to background")
                    
                    Self.scheduleBackgroundRefresh()
                }
        }
    }
    
    private static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.veloready.app.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.debug("📱 Background refresh scheduled")
        } catch {
            Logger.error("Failed to schedule background refresh: \(error)")
        }
    }
    
    private static func handleBackgroundRefresh(task: BGAppRefreshTask) {
        Logger.debug("🔄 Background refresh started")
        
        task.expirationHandler = {
            Logger.debug("⏰ Background refresh expired")
            task.setTaskCompleted(success: false)
        }
        
        Task {
            Logger.debug("🔄 [BACKGROUND] Prefetching critical data...")
            
            // Refresh Core Data cache first
            let cacheManager = DailyDataService.shared
            do {
                try await cacheManager.refreshToday()
                Logger.debug("✅ [BACKGROUND] Core Data cache refreshed")
            } catch {
                Logger.error("❌ [BACKGROUND] Failed to refresh cache: \(error)")
            }
            
            // Prefetch today's activities (low bandwidth, high value)
            // Using UnifiedActivityService (replaces IntervalsCache)
            do {
                let _ = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 100, daysBack: 90)
                Logger.debug("✅ [BACKGROUND] Activities prefetched")
            } catch {
                Logger.debug("⚠️ [BACKGROUND] Could not prefetch activities: \(error.localizedDescription)")
            }
            
            // Prefetch HealthKit data (replaces HealthKitCache)
            let healthKitManager = HealthKitManager.shared
            let _ = await healthKitManager.fetchRecentWorkouts(daysBack: 90)
            Logger.debug("✅ [BACKGROUND] HealthKit data prefetched")
            
            // Refresh all scores
            let recoveryService = RecoveryScoreService.shared
            let sleepService = SleepScoreService.shared
            let strainService = StrainScoreService.shared
            
            // Update all scores in parallel
            await recoveryService.calculateRecoveryScore()
            await sleepService.calculateSleepScore()
            await strainService.calculateStrainScore()
            
            Logger.debug("✅ [BACKGROUND] All scores calculated and cached")
            task.setTaskCompleted(success: true)
            
            // Schedule next refresh
            scheduleBackgroundRefresh()
        }
    }
    
    /// Clean up legacy stream data from UserDefaults (one-time migration)
    private static func cleanupLegacyStravaStreams() {
        let defaults = UserDefaults.standard
        let dict = defaults.dictionaryRepresentation()
        var removedCount = 0
        var totalBytes = 0
        
        for key in dict.keys {
            // Clean up both Strava and Intervals.icu streams
            if key.hasPrefix("stream_strava_") || key.hasPrefix("stream_i") {
                if let data = dict[key] as? Data {
                    totalBytes += data.count
                }
                defaults.removeObject(forKey: key)
                removedCount += 1
            }
        }
        
        if removedCount > 0 {
            Logger.debug("🧹 Cleaned up \(removedCount) legacy streams (~\(totalBytes / 1024)KB)")
        }
    }
}

struct RootView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @ObservedObject private var oauthManager = IntervalsOAuthManager.shared
    @ObservedObject private var stravaAuthService = StravaAuthService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    
    var body: some View {
        Group {
            if onboardingManager.hasCompletedOnboarding {
                MainTabView()
                    .onAppear {
                        // OPTIMIZATION: Run HealthKit check in background (non-blocking)
                        // UI renders immediately with cached scores
                        // Fresh scores calculate once HealthKit check completes
                        Task { @MainActor in
                            Logger.info("🚀 [ROOT] Running HealthKit check in background...")
                            await HealthKitManager.shared.checkAuthorizationAfterSettingsReturn()
                            Logger.info("✅ [ROOT] HealthKit check complete - isAuthorized: \(HealthKitManager.shared.isAuthorized)")
                        }
                    }
            } else {
                OnboardingFlowView()
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .onOpenURL { url in
            // Handle OAuth callbacks
            Logger.debug("🔗 App received URL: \(url.absoluteString)")
            Logger.debug("🔗 URL scheme: \(url.scheme ?? "nil"), host: \(url.host ?? "nil")")
            
            // Handle Strava OAuth (Universal Link or custom scheme)
            if ((url.scheme == "https" && url.host == "veloready.app" && url.path.contains("/auth/strava")) ||
                (url.scheme == "veloready" && url.path.contains("/auth/strava"))) {
                Logger.debug("✅ Strava OAuth callback detected")
                Task {
                    await stravaAuthService.handleCallback(url: url)
                }
                return
            }
            
            // Handle Intervals.icu OAuth
            if ((url.scheme == "veloready" && url.path.contains("/auth/intervals")) ||
                url.scheme == "com.veloready.app") {
                Logger.debug("✅ Intervals.icu OAuth callback detected")
                Task {
                    await oauthManager.handleCallback(url: url)
                }
                return
            }
            
            Logger.error("Unknown callback URL scheme")
        }
    }
}

struct MainTabView: View {
    @ObservedObject private var oauthManager = IntervalsOAuthManager.shared
    @StateObject private var apiClient = IntervalsAPIClient.shared
    @StateObject private var athleteZoneService = AthleteZoneService()
    @ObservedObject private var scoresCoordinator = ServiceContainer.shared.scoresCoordinator // Observe scores for smart hiding
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var showInitialSpinner: Bool
    @State private var brandingOpacity: Double = 0.0  // Start at 0 for fade-in animation
    @State private var minimumBrandingElapsed = false  // Track if 3s minimum has passed
    
    // UserDefaults key for tracking app lifecycle
    private static let hasShownBrandingKey = "hasShownBrandingAnimation"
    private static let lastSessionDateKey = "lastSessionDate"
    
    private let tabs = [
        TabItem(title: CommonContent.TabLabels.today, icon: "house.fill"),
        TabItem(title: CommonContent.TabLabels.activities, icon: "figure.run"),
        TabItem(title: CommonContent.TabLabels.trends, icon: "chart.xyaxis.line"),
        TabItem(title: CommonContent.TabLabels.settings, icon: "gearshape.fill")
    ]
    
    init() {
        // BRANDING LOGIC:
        // - ALWAYS show on fresh app launch (after kill/rebuild)
        // - DON'T show when returning from background (if < 1 hour)
        //
        // We use a runtime-only flag to detect fresh launches
        let defaults = UserDefaults.standard
        let wasRunningKey = "app_was_running_flag"
        let lastSessionDateKey = Self.lastSessionDateKey
        let now = Date()
        
        // Check if app was running in memory (this flag only exists if app wasn't killed)
        let wasRunning = defaults.bool(forKey: wasRunningKey)
        
        let shouldShowBranding: Bool
        if wasRunning {
            // App was backgrounded, not killed - check if enough time passed
            if let lastDate = defaults.object(forKey: lastSessionDateKey) as? Date {
                let timeSinceLastSession = now.timeIntervalSince(lastDate)
                shouldShowBranding = timeSinceLastSession > 3600 // 1 hour
                Logger.info("🎬 [BRANDING] App backgrounded - time since last: \(String(format: "%.1f", timeSinceLastSession))s - showing: \(shouldShowBranding)")
            } else {
                // No session date but was running? Show branding to be safe
                shouldShowBranding = true
                Logger.info("🎬 [BRANDING] App was running but no session date - showing branding")
            }
        } else {
            // App was killed/rebuilt - ALWAYS show branding
            shouldShowBranding = true
            Logger.info("🎬 [BRANDING] Fresh app launch (killed/rebuilt) - showing branding")
        }
        
        // Set runtime flag to indicate app is now running
        defaults.set(true, forKey: wasRunningKey)
        defaults.set(now, forKey: lastSessionDateKey)
        
        _showInitialSpinner = State(initialValue: shouldShowBranding)
    }
    
    var body: some View {
        return Group {
            if #available(iOS 26.0, *) {
                // iOS 26+ - Use native TabView with automatic Liquid Glass
                nativeTabView
            } else {
                // iOS 25 and earlier - Use custom FloatingTabBar
                customTabView
            }
        }
    }
    
    // MARK: - iOS 26+ Native TabView
    
    @available(iOS 26.0, *)
    private var nativeTabView: some View {
        ZStack {
            if showInitialSpinner {
                // During branding animation: Show ONLY black screen + overlay
                // Don't render TabView at all to prevent tab bar flash
                Color.black
                    .ignoresSafeArea()
                    .onAppear {
                        Logger.info("📱 [MAINTABVIEW] Showing black screen for branding (iOS 26+)")
                    }

                LoadingOverlay()
                    .opacity(brandingOpacity)
                    .zIndex(999)
                    .onAppear {
                        Logger.info("🎬 [BRANDING] Central animation APPEARED - showInitialSpinner: \(showInitialSpinner)")
                        Logger.info("🔵 [BRANDING] Starting fade-in animation")

                        // Phase 1: Fade in immediately (0.3s)
                        withAnimation(.easeIn(duration: 0.3)) {
                            brandingOpacity = 1.0
                        }

                        Task { @MainActor in
                            Logger.info("🎬 [BRANDING] Starting smart branding sequence...")

                            // PHASE 1 V2: Start background loading DURING animation (0ms to cached content)
                            // This is the key change - we use the 3-second animation time productively
                            if FeatureFlags.shared.useTodayViewV2 {
                                Task {
                                    Logger.info("📦 [V2] Starting TodayViewState background load during branding...")
                                    await TodayViewState.shared.load()
                                    Logger.info("✅ [V2] TodayViewState load complete")
                                }
                            }

                            // Phase 2: Wait minimum 3 seconds for branding
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            minimumBrandingElapsed = true
                            Logger.info("✅ [BRANDING] Minimum 3s elapsed - now waiting for scores...")

                            // Phase 3: Wait for scores to be ready (with 3s timeout)
                            let scoresReadyStart = Date()
                            while !scoresCoordinator.state.allCoreScoresAvailable {
                                // Check timeout - if scores aren't ready within 3s, proceed anyway
                                if Date().timeIntervalSince(scoresReadyStart) > 3.0 {
                                    Logger.warning("⏱️ [BRANDING] Scores not ready after 3s timeout - proceeding anyway")
                                    break
                                }
                                // Check every 100ms
                                try? await Task.sleep(nanoseconds: 100_000_000)
                            }

                            let waitDuration = Date().timeIntervalSince(scoresReadyStart)
                            Logger.info("✅ [BRANDING] Scores ready in \(String(format: "%.2f", waitDuration))s - phase: \(scoresCoordinator.state.phase.description)")

                            // Phase 4: Fade out (0.5s)
                            Logger.info("🎬 [BRANDING] Starting fade-out")
                            withAnimation(.easeOut(duration: 0.5)) {
                                brandingOpacity = 0.0
                            }

                            // Wait for fade-out to complete before removing from hierarchy
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            Logger.info("🟢 [BRANDING] Fade-out complete - removing from hierarchy")
                            showInitialSpinner = false
                            Logger.info("✅ [BRANDING] Branding sequence complete")
                        }
                    }
                    .onChange(of: scoresCoordinator.state.allCoreScoresAvailable) { _, isReady in
                        if minimumBrandingElapsed && isReady {
                            Logger.info("🚀 [BRANDING] Scores became ready after minimum time - will fade out soon")
                        }
                    }
            } else {
                // After branding animation: Show TabView with content
                TabView(selection: $selectedTab) {
                    TodayView(showInitialSpinner: $showInitialSpinner)
                        .tabItem {
                            Label(CommonContent.TabLabels.today, systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    ActivitiesView()
                        .tabItem {
                            Label(CommonContent.TabLabels.activities, systemImage: "figure.run")
                        }
                        .tag(1)
                    
                    TrendsView()
                        .tabItem {
                            Label(CommonContent.TabLabels.trends, systemImage: "chart.xyaxis.line")
                        }
                        .tag(2)
                    
                    SettingsView()
                        .tabItem {
                            Label(CommonContent.TabLabels.settings, systemImage: "gearshape.fill")
                        }
                        .tag(3)
                }
                .environmentObject(apiClient)
                .environmentObject(athleteZoneService)
                .onChange(of: selectedTab) { oldValue, newValue in
                    if oldValue == newValue {
                        NotificationCenter.default.post(name: .popToRootView, object: nil)
                    }
                    previousTab = oldValue
                }
                .onAppear {
                    Logger.info("📱 [MAINTABVIEW] TabView appeared after branding")
                }
            }
        }
    }
    
    // MARK: - Custom FloatingTabBar (iOS < 26)
    
    private var customTabView: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case 0:
                    TodayView(showInitialSpinner: $showInitialSpinner)
                case 1:
                    ActivitiesView()
                case 2:
                    TrendsView()
                case 3:
                    SettingsView()
                default:
                    TodayView(showInitialSpinner: $showInitialSpinner)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(apiClient)
            .environmentObject(athleteZoneService)
            
            // Central branding animation - shows on app launch
            if showInitialSpinner {
                LoadingOverlay()
                    .opacity(brandingOpacity)
                    .zIndex(999)
                    .onAppear {
                        Logger.info("🎬 [BRANDING] Central animation APPEARED - showInitialSpinner: \(showInitialSpinner)")
                        Logger.info("🔵 [BRANDING] Starting fade-in animation")

                        // Phase 1: Fade in immediately (0.3s)
                        withAnimation(.easeIn(duration: 0.3)) {
                            brandingOpacity = 1.0
                        }

                        Task { @MainActor in
                            Logger.info("🎬 [BRANDING] Starting smart branding sequence...")

                            // PHASE 1 V2: Start background loading DURING animation (0ms to cached content)
                            // This is the key change - we use the 3-second animation time productively
                            if FeatureFlags.shared.useTodayViewV2 {
                                Task {
                                    Logger.info("📦 [V2] Starting TodayViewState background load during branding...")
                                    await TodayViewState.shared.load()
                                    Logger.info("✅ [V2] TodayViewState load complete")
                                }
                            }

                            // Phase 2: Wait minimum 3 seconds for branding
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            minimumBrandingElapsed = true
                            Logger.info("✅ [BRANDING] Minimum 3s elapsed - now waiting for scores...")

                            // Phase 3: Wait for scores to be ready (with 3s timeout)
                            let scoresReadyStart = Date()
                            while !scoresCoordinator.state.allCoreScoresAvailable {
                                // Check timeout - if scores aren't ready within 3s, proceed anyway
                                if Date().timeIntervalSince(scoresReadyStart) > 3.0 {
                                    Logger.warning("⏱️ [BRANDING] Scores not ready after 3s timeout - proceeding anyway")
                                    break
                                }
                                // Check every 100ms
                                try? await Task.sleep(nanoseconds: 100_000_000)
                            }

                            let waitDuration = Date().timeIntervalSince(scoresReadyStart)
                            Logger.info("✅ [BRANDING] Scores ready in \(String(format: "%.2f", waitDuration))s - phase: \(scoresCoordinator.state.phase.description)")

                            // Phase 4: Fade out (0.5s)
                            Logger.info("🎬 [BRANDING] Starting fade-out")
                            withAnimation(.easeOut(duration: 0.5)) {
                                brandingOpacity = 0.0
                            }

                            // Wait for fade-out to complete before removing from hierarchy
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            Logger.info("🟢 [BRANDING] Fade-out complete - removing from hierarchy")
                            showInitialSpinner = false
                            Logger.info("✅ [BRANDING] Branding sequence complete")
                        }
                    }
                    .onChange(of: scoresCoordinator.state.allCoreScoresAvailable) { _, isReady in
                        if minimumBrandingElapsed && isReady {
                            Logger.info("🚀 [BRANDING] Scores became ready after minimum time - will fade out soon")
                        }
                    }
            }
            
            // Floating Tab Bar - only show after initial spinner
            if !showInitialSpinner {
                FloatingTabBar(selectedTab: $selectedTab, tabs: tabs)
                    .animation(FluidAnimation.flow, value: selectedTab)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue == newValue {
                NotificationCenter.default.post(name: .popToRootView, object: nil)
            }
            previousTab = oldValue
        }
    }
}

// Notification for popping to root
extension Notification.Name {
    static let popToRootView = Notification.Name("popToRootView")
    static let refreshDataAfterIntervalsConnection = Notification.Name("refreshDataAfterIntervalsConnection")
    static let todayDataRefreshed = Notification.Name("todayDataRefreshed")
    static let refreshHealthWarnings = Notification.Name("refreshHealthWarnings")
}

// ProfileTabView removed - now using SettingsView with ProfileSection