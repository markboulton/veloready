import SwiftUI
import BackgroundTasks

@main
struct VeloReadyApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
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
            print("📱 Background refresh scheduled")
        } catch {
            print("❌ Failed to schedule background refresh: \(error)")
        }
    }
    
    private static func handleBackgroundRefresh(task: BGAppRefreshTask) {
        print("🔄 Background refresh started")
        
        task.expirationHandler = {
            print("⏰ Background refresh expired")
            task.setTaskCompleted(success: false)
        }
        
        Task {
            // Refresh Core Data cache first
            let cacheManager = await CacheManager.shared
            do {
                try await cacheManager.refreshToday()
                print("✅ Core Data cache refreshed in background")
            } catch {
                print("❌ Failed to refresh cache in background: \(error)")
            }
            
            // Refresh all scores
            let recoveryService = RecoveryScoreService.shared
            let sleepService = SleepScoreService.shared
            let strainService = StrainScoreService.shared
            
            // Update all scores
            await recoveryService.calculateRecoveryScore()
            await sleepService.calculateSleepScore()
            await strainService.calculateStrainScore()
            
            print("✅ Background refresh completed")
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
    
    var body: some View {
        Group {
            if onboardingManager.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingFlowView()
            }
        }
        .onOpenURL { url in
            // Handle OAuth callbacks
            print("🔗 App received URL: \(url.absoluteString)")
            print("🔗 URL scheme: \(url.scheme ?? "nil"), host: \(url.host ?? "nil")")
            
            // Handle Strava OAuth (Universal Link or custom scheme)
            if ((url.scheme == "https" && url.host == "veloready.app" && url.path.contains("/auth/strava")) ||
                (url.scheme == "veloready" && url.path.contains("/auth/strava"))) {
                print("✅ Strava OAuth callback detected")
                Task {
                    await stravaAuthService.handleCallback(url: url)
                }
                return
            }
            
            // Handle Intervals.icu OAuth
            if ((url.scheme == "veloready" && url.path.contains("/auth/intervals")) ||
                url.scheme == "com.veloready.app") {
                print("✅ Intervals.icu OAuth callback detected")
                Task {
                    await oauthManager.handleCallback(url: url)
                }
                return
            }
            
            print("❌ Unknown callback URL scheme")
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
            
            ProfileTabView(oauthManager: oauthManager)
                .tabItem {
                    Label("Profile", systemImage: "person")
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

struct ProfileTabView: View {
    @ObservedObject var oauthManager: IntervalsOAuthManager
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                if let user = oauthManager.user {
                    userInfoSection(user: user)
                } else {
                    ProgressView("Loading user info...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Settings Section
                Section {
                    NavigationLink(destination: SettingsView()) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(Color.button.primary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Settings")
                                    .font(.body)
                                
                                Text("Sleep, zones, and preferences")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                } header: {
                    Text("Preferences")
                }
                
                // Sign Out Section
                Section {
                    Button("Sign Out") {
                        showingSignOutAlert = true
                    }
                    .foregroundColor(Color.button.danger)
                } header: {
                    Text("Account")
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await oauthManager.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out? You'll need to authenticate again to access your data.")
            }
        }
    }
    
    private func userInfoSection(user: IntervalsUser) -> some View {
        Group {
            Section {
                HStack(spacing: 16) {
                    // Profile Image
                    AsyncImage(url: user.profileImageURL.flatMap(URL.init)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(ColorPalette.neutral400)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    
                    // User Details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let username = user.username {
                            Text("@\(username)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            } header: {
                Text("Profile")
            }
            
            Section {
                InfoRow(label: "User ID", value: String(user.id))
                InfoRow(label: "Member Since", value: formatDate(user.createdAt))
                InfoRow(label: "Last Updated", value: formatDate(user.updatedAt))
            } header: {
                Text("Account Information")
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}