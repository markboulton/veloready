import SwiftUI
import BackgroundTasks

@main
struct VeloReadyApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Log version information at startup
        AppVersion.logVersionInfo()
        
        // Initialize service container early for optimal performance
        Task { @MainActor in
            ServiceContainer.shared.initialize()
        }
        
        // Configure AI Brief
        Task { @MainActor in
            AIBriefConfig.configure()
        }
        
        // Migrate workout metadata from UserDefaults to Core Data
        Task { @MainActor in
            WorkoutMetadataService.shared.migrateAllLegacyData()
        }
        
        // Clean up legacy Strava stream data from UserDefaults
        Task { @MainActor in
            Self.cleanupLegacyStravaStreams()
        }
        
        // Enable automatic iCloud sync
        Task { @MainActor in
            iCloudSyncService.shared.enableAutomaticSync()
            Logger.debug("☁️ iCloud automatic sync initialized")
        }
        
        // Backfill historical physio data for charts (one-time on first launch)
        Task {
            let hasBackfilled = UserDefaults.standard.bool(forKey: "hasBackfilledPhysioData")
            if !hasBackfilled {
                Logger.data("📊 [PHYSIO BACKFILL] First launch - backfilling historical data...")
                await CacheManager.shared.backfillHistoricalPhysioData(days: 60)
                UserDefaults.standard.set(true, forKey: "hasBackfilledPhysioData")
            }
        }
        
        // Register background task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.veloready.app.refresh", using: nil) { task in
            Self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
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
            // Refresh Core Data cache first
            let cacheManager = await CacheManager.shared
            do {
                try await cacheManager.refreshToday()
                Logger.debug("✅ Core Data cache refreshed in background")
            } catch {
                Logger.error("Failed to refresh cache in background: \(error)")
            }
            
            // Refresh all scores
            let recoveryService = RecoveryScoreService.shared
            let sleepService = SleepScoreService.shared
            let strainService = StrainScoreService.shared
            
            // Update all scores
            await recoveryService.calculateRecoveryScore()
            await sleepService.calculateSleepScore()
            await strainService.calculateStrainScore()
            
            Logger.debug("✅ Background refresh completed")
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
    
    var body: some View {
        Group {
            if onboardingManager.hasCompletedOnboarding {
                MainTabView()
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
    @State private var selectedTab = 0
    @State private var previousTab = 0
    
    private let tabs = [
        TabItem(title: CommonContent.TabLabels.today, icon: "house.fill"),
        TabItem(title: CommonContent.TabLabels.activities, icon: "figure.run"),
        TabItem(title: CommonContent.TabLabels.trends, icon: "chart.xyaxis.line"),
        TabItem(title: CommonContent.TabLabels.settings, icon: "gearshape.fill")
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case 0:
                    TodayView()
                case 1:
                    ActivitiesView()
                case 2:
                    TrendsView()
                case 3:
                    SettingsView()
                default:
                    TodayView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(apiClient)
            .environmentObject(athleteZoneService)
            
            // Floating Tab Bar
            FloatingTabBar(selectedTab: $selectedTab, tabs: tabs)
                .animation(FluidAnimation.flow, value: selectedTab)
        }
        .ignoresSafeArea(.keyboard) // Allow tab bar to stay on screen with keyboard
        .onChange(of: selectedTab) { oldValue, newValue in
            // When tapping the same tab again, post notification to pop to root
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
}

// ProfileTabView removed - now using SettingsView with ProfileSection