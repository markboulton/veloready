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
        
        // Enable automatic iCloud sync
        Task { @MainActor in
            iCloudSyncService.shared.enableAutomaticSync()
            Logger.debug("☁️ iCloud automatic sync initialized")
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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "house")
                }
                .tag(0)
            
            ActivitiesView()
                .tabItem {
                    Label("Activities", systemImage: "list.bullet")
                }
                .tag(1)
            
            TrendsView()
                .tabItem {
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            // TODO: Re-enable Reports tab post-MVP
            // ReportsView()
            //     .tabItem {
            //         Label("Reports", systemImage: "chart.bar.doc.horizontal")
            //     }
            //     .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
        .environmentObject(apiClient)
        .environmentObject(athleteZoneService)
        .onAppear {
            // Reduce tab bar icon size
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            
            // Smaller icons
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = UIColor.label
            itemAppearance.selected.iconColor = UIColor.label
            
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
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