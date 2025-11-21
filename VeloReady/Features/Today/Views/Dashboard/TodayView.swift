import SwiftUI

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Today View

/// Main Today view showing current activities and progress
struct TodayView: View {
    @ObservedObject private var todayState = TodayViewState.shared  // V2 Architecture - Primary state
    @ObservedObject private var loadingStateManager = ServiceContainer.shared.loadingStateManager  // Loading UI state
    @ObservedObject private var healthKitManager = HealthKitManager.shared  // CRITICAL: Must be @ObservedObject not @StateObject!
    @ObservedObject private var wellnessService = WellnessDetectionService.shared  // CRITICAL: Observe shared instance
    @ObservedObject private var illnessService = IllnessDetectionService.shared  // CRITICAL: Observe shared instance
    @ObservedObject private var stressService = StressAnalysisService.shared  // CRITICAL: Observe shared instance
    @ObservedObject private var liveActivityService = LiveActivityService.shared
    @State private var showingDebugView = false
    @State private var showingHealthKitPermissionsSheet = false
    @State private var showingWellnessDetailSheet = false
    @State private var showingIllnessDetailSheet = false
    @State private var showingStressDetailSheet = false
    @State private var showMissingSleepInfo = false
    @State private var wasHealthKitAuthorized = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isViewActive = false
    @State private var hasCompletedInitialLoad = false
    @Binding var showInitialSpinner: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var previousScenePhase: ScenePhase = .inactive
    
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @ObservedObject private var stravaAuth = StravaAuthService.shared
    @ObservedObject private var intervalsAuth = IntervalsOAuthManager.shared
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    init(showInitialSpinner: Binding<Bool> = .constant(true)) {
        self._showInitialSpinner = showInitialSpinner
    }

    // MARK: - Computed Properties (V2 Architecture Helpers)

    /// Whether we're in the initial loading phase (showing spinner)
    private var isInitializing: Bool {
        switch todayState.phase {
        case .loadingCache, .notStarted:
            return true
        default:
            return false
        }
    }

    /// Whether any loading is in progress
    private var isLoading: Bool {
        todayState.phase.isLoading
    }

    var body: some View {
        // Don't render NavigationStack at all until branding animation is done
        // This prevents the navigation bar from flashing before the overlay appears
        let _ = Logger.trace("🏠 [TodayView] BODY EVALUATED - showInitialSpinner: \(showInitialSpinner)")
        
        if showInitialSpinner {
            // Black screen while branding animation shows (overlay is in MainTabView)
            Color.black
                .ignoresSafeArea()
                .onAppear {
                    Logger.info("🏠 [TodayView] Black screen APPEARED")
                }
        } else {
            NavigationStack {
                ZStack(alignment: .top) {
                    // Adaptive background (light grey in light mode, black in dark mode)
                    Color.background.app
                        .ignoresSafeArea()
                        .onAppear {
                            Logger.trace("🏠 [TodayView] BODY RENDERING - healthKitManager.isAuthorized: \(healthKitManager.isAuthorized)")
                        }
                    
                    ScrollView {
                    // Use LazyVStack as main container for better performance
                    LazyVStack(spacing: Spacing.md) {
                        // Invisible geometry reader to track scroll offset
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                        }
                        .frame(height: 0)
                        
                        // Loading status - scrolls with content, appears at top during pull-to-refresh
                        // Always visible to show loading state updates
                        HStack {
                            LoadingStatusView(
                                state: loadingStateManager.currentState,
                                onErrorTap: {
                                    Task {
                                        await todayState.load()
                                    }
                                }
                            )
                            Spacer()
                        }
                        .padding(.leading, 0)
                        .padding(.trailing, 0)
                        .padding(.top, 0)
                        .padding(.bottom, Spacing.sm)
                        
                        // Recovery Metrics (Three Graphs)
                        // Wait for auth check to complete, then show rings (with loading state if calculating)
                        if healthKitManager.authorizationCoordinator.hasCompletedInitialCheck {
                            RecoveryMetricsComponent()
                        }
                        
                        // Stress Alert Banner (appears under rings when elevated)
                        if healthKitManager.isAuthorized,
                           let alert = stressService.currentAlert,
                           alert.isSignificant {
                            StressBanner(alert: alert) {
                                showingStressDetailSheet = true
                            }
                            .padding(.top, Spacing.md)
                        }
                        
                        // HealthKit Enablement Section (only when not authorized)
                        // Wait for initial auth check AND verify coordinator also says not authorized
                        // This prevents race condition where hasCompletedInitialCheck=true but isAuthorized hasn't synced yet
                        if healthKitManager.authorizationCoordinator.hasCompletedInitialCheck 
                            && !healthKitManager.authorizationCoordinator.isAuthorized {
                            HealthKitEnablementSection(
                                showingHealthKitPermissionsSheet: $showingHealthKitPermissionsSheet
                            )
                        }
                        
                        // Health Warnings (Illness & Wellness alerts)
                        if healthKitManager.isAuthorized {
                            HealthWarningsComponent()
                        }
                        
                        // Fixed Today page sections
                        if healthKitManager.isAuthorized {
                            // Unified AI Brief (Pro) or Computed Brief (Free)
                            AIBriefComponent()
                            
                            // Latest Activity from Strava/Intervals
                            LatestActivityComponent()
                            
                            // Training Load Graph (full width)
                            TodayTrainingLoadComponent()

                            // Steps card (full width with left/right split)
                            if liveActivityService.isLoading {
                                SkeletonStatsCard()
                            } else {
                                StepsComponent()
                            }

                            // Calories card (full width with left/right split)
                            if liveActivityService.isLoading {
                                SkeletonStatsCard()
                            } else {
                                CaloriesComponent()
                            }

                            // FTP card (full width with left/right split)
                            HapticNavigationLink(destination: AdaptivePerformanceDetailView(initialMetric: .ftp)) {
                                FTPComponent()
                            }

                            // VO2 Max card (full width with left/right split)
                            HapticNavigationLink(destination: AdaptivePerformanceDetailView(initialMetric: .vo2max)) {
                                VO2MaxComponent()
                            }
                        }
                        
                        // Pro upgrade CTA (only for free users)
                        if !ProFeatureConfig.shared.hasProAccess {
                            ProUpgradeCard(
                                content: .unlockProFeatures,
                                showBenefits: true
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.tabBarBottomPadding)
                }
                .coordinateSpace(name: "scroll")
                .if(networkMonitor.isConnected) { view in
                    view.refreshable {
                        // User-triggered refresh action (pull-to-refresh)
                        // LoadingStatusView provides visual feedback (no blocking spinner)
                        if FeatureFlags.shared.useTodayViewV2 {
                            Logger.info("🔄 [V2] Pull-to-refresh using TodayViewState")
                            await todayState.refresh()
                        } else {
                            await todayState.refresh()
                        }
                    }
                }
                
                // No loading overlay needed - content shows immediately with cached scores
                // Rings handle their own loading/shimmer states
                
                // Navigation gradient mask (iOS Mail style)
                // Always show to prevent layout shift
                NavigationGradientMask()
                    .opacity(isInitializing ? 0 : 1)
                }
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
                .navigationTitle(TodayContent.title)
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar(.visible, for: .navigationBar) // Always visible to prevent layout shift
                #if DEBUG
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingDebugView = true
                        } label: {
                            Image(systemName: "ladybug")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                #endif
            }
            .toolbar(.visible, for: .tabBar) // Always visible to prevent layout shift
            .onAppear {
            Logger.debug("👁 [SPINNER] NavigationStack.onAppear called - isInitializing=\(isInitializing)")
            Logger.debug("📋 SPACING DEBUG:")
            Logger.debug("📋   LazyVStack spacing: Spacing.md = \(Spacing.md)pt")
            Logger.debug("📋   Each card .padding(.vertical, Spacing.xxl / 2) = \(Spacing.xxl / 2)pt")
            Logger.debug("📋   Total between cards: \(Spacing.md) + \(Spacing.xxl / 2) + \(Spacing.xxl / 2) = \(Spacing.md + Spacing.xxl)pt")
            handleViewAppear()
        }
        .onDisappear {
            Logger.debug("👋 [SPINNER] TodayView.onDisappear called - marking view as inactive")
            isViewActive = false
            Task { await todayState.handle(.viewDisappeared) }
        }
        .onChange(of: showInitialSpinner) { oldValue, newValue in
            // CRITICAL FIX: Trigger initial load when branding animation completes
            // The NavigationStack isn't rendered during the branding animation (showInitialSpinner=true),
            // so .onAppear doesn't fire until after the animation ends. But we want to START loading
            // as soon as the animation completes, not when onAppear eventually fires.
            if oldValue == true && newValue == false {
                Logger.info("🎬 [SPINNER] Branding animation completed - triggering handleViewAppear()")
                handleViewAppear()
            }
        }
        .onChange(of: isInitializing) { oldValue, newValue in
            Logger.debug("🔄 [SPINNER] isInitializing changed: \(oldValue) → \(newValue)")
            // Note: showInitialSpinner is controlled by MainTabView's 3-second timer
            // Don't set it here to avoid interrupting the branding animation
        }
        .onChange(of: healthKitManager.isAuthorized) { _, newValue in
            handleHealthKitAuthChange(newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            handleAppForeground()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshDataAfterIntervalsConnection)) { _ in
            handleIntervalsConnection()
        }
        .sheet(isPresented: $showingDebugView) {
            DebugDataView()
        }
        .sheet(isPresented: $showingHealthKitPermissionsSheet) {
            HealthKitPermissionsSheet()
        }
        .sheet(isPresented: $showingWellnessDetailSheet) {
            if let alert = wellnessService.currentAlert {
                WellnessDetailSheet(alert: alert)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingIllnessDetailSheet) {
            if let indicator = illnessService.currentIndicator {
                IllnessDetailSheet(indicator: indicator)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingStressDetailSheet) {
            if let alert = stressService.currentAlert {
                StressAnalysisSheet(alert: alert)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        } // End of else (NavigationStack content)
    }
    
    // MARK: - Loading Spinner
    
    private var loadingSpinner: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            
            // Temporary icon (to be replaced with logo)
            Image(systemName: Icons.Activity.cycling)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(ColorScale.blueAccent)
                .padding(.bottom, Spacing.md)
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: ColorPalette.neutral400))
            
            Text(CommonContent.loading)
                .font(.headline)
                .fontWeight(.regular)
                .foregroundColor(.text.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background.primary)
        .ignoresSafeArea(.all)
        .zIndex(999)
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            Text(TodayContent.welcomeBack)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(TodayContent.howFeeling)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.background.secondary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    
    
    
    private var healthDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(TodayContent.healthToday)
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                // Sleep Data
                TodayHealthDataCard(
                    title: "Sleep",
                    value: "No data",
                    subtitle: nil,
                    icon: "moon.fill",
                    color: .blue
                )
                
                // HRV Data
                TodayHealthDataCard(
                    title: "HRV",
                    value: "No data",
                    subtitle: nil,
                    icon: "heart.fill",
                    color: .green
                )
                
                // RHR Data
                TodayHealthDataCard(
                    title: "Resting HR",
                    value: "No data",
                    subtitle: nil,
                    icon: "heart.circle.fill",
                    color: .red
                )
                
                // Placeholder for even grid - always show for now since data is not implemented
                if true {
                    TodayHealthDataCard(
                        title: "Health Data",
                        value: "No recent data",
                        subtitle: nil,
                        icon: "heart.text.square",
                        color: .gray
                    )
                }
            }
        }
        .padding()
        .background(Color.background.secondary)
        .cornerRadius(12)
        .overlay(
            Rectangle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func parseActivityDate(_ dateString: String) -> Date? {
        // Try ISO8601 first (with timezone)
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Try local format without timezone (2025-10-02T06:11:37)
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.timeZone = TimeZone.current
        return localFormatter.date(from: dateString)
    }
    
    private func generateDailyActivityData() -> [DailyActivityData] {
        let activities = todayState.recentActivities.map { UnifiedActivity(from: $0) }.isEmpty ? 
            todayState.recentActivities.map { UnifiedActivity(from: $0) } :
            todayState.recentActivities.map { UnifiedActivity(from: $0) }
        
        // Group activities by day
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Create dictionary of day offset -> activities
        var dailyMap: [Int: [ActivityBarData]] = [:]
        
        for activity in activities {
            let activityDay = calendar.startOfDay(for: activity.startDate)
            let dayOffset = calendar.dateComponents([.day], from: activityDay, to: today).day ?? 0
            
            // Only include last 14 days for Today sparkline
            if dayOffset >= 0 && dayOffset <= 13 {
                let activityType: SparklineActivityType = {
                    switch activity.type {
                    case .cycling: return .cycling
                    case .running: return .running
                    case .walking: return .walking
                    case .swimming: return .swimming
                    case .strength: return .strength
                    default: return .other
                    }
                }()
                
                // Use duration if available, otherwise calculate from activity model or use a default
                let duration: Double = {
                    if let dur = activity.duration, dur > 0 {
                        return dur / 60.0 // Convert seconds to minutes
                    } else if activity.activity != nil {
                        // For Activity models, use TSS as a proxy for duration/intensity
                        // TSS roughly correlates to workout duration and intensity
                        // Use a fixed height for visibility (e.g., 60 minutes)
                        return 60.0
                    } else {
                        return 0.0
                    }
                }()
                
                let barData = ActivityBarData(type: activityType, duration: duration)
                let key = -dayOffset
                
                if dailyMap[key] != nil {
                    dailyMap[key]?.append(barData)
                } else {
                    dailyMap[key] = [barData]
                }
            }
        }
        
        // Create array for all days in range
        var dailyActivities: [DailyActivityData] = []
        for dayOffset in (-13)...0 {
            let activities = dailyMap[dayOffset] ?? []
            dailyActivities.append(DailyActivityData(dayOffset: dayOffset, activities: activities))
        }
        
        return dailyActivities
    }
    
    // MARK: - Computed Properties
    
    private var healthKitStatusDescription: String {
        switch healthKitManager.authorizationState {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "exclamationmark.triangle.fill"
        case .notDetermined:
            return "questionmark.circle"
        case .partial:
            return "warning.sign"
        case .notAvailable:
            return "gear"
        }
    }
    // MARK: - Helper Computed Properties
    
    private var hasConnectedDataSource: Bool {
        let stravaConnected = stravaAuth.connectionState.isConnected
        let intervalsConnected = intervalsAuth.isAuthenticated
        let result = stravaConnected || intervalsConnected
        
        Logger.debug("🔍 [TodayView] hasConnectedDataSource check:")
        Logger.debug("   - Strava connected: \(stravaConnected)")
        Logger.debug("   - Intervals connected: \(intervalsConnected)")
        Logger.debug("   - Result: \(result)")
        
        return result
    }
    
    private func getLatestActivity() -> UnifiedActivity? {
        let activities = todayState.recentActivities.map { UnifiedActivity(from: $0) }.isEmpty ?
            todayState.recentActivities.map { UnifiedActivity(from: $0) } :
            todayState.recentActivities.map { UnifiedActivity(from: $0) }
        
        Logger.debug("🔍 [LatestActivity] Total activities: \(activities.count)")
        
        // Prefer Strava/Intervals activities, but allow Apple Health strength workouts
        let result = activities.first { activity in
            activity.source == .strava || activity.source == .intervalsICU ||
            (activity.source == .appleHealth && activity.type == .strength)
        }
        
        if let activity = result {
            Logger.debug("✅ [LatestActivity] Found: \(activity.name) (source: \(activity.source), shouldShowMap: \(activity.shouldShowMap))")
        } else {
            Logger.debug("❌ [LatestActivity] No Strava/Intervals activity found")
        }
        
        return result
    }
    
    /// Get activities for Recent Activities section, excluding the one already shown in Latest Activity card
    private func getActivitiesForSection() -> [UnifiedActivity] {
        let activities = todayState.recentActivities.map { UnifiedActivity(from: $0) }.isEmpty ?
            todayState.recentActivities.map { UnifiedActivity(from: $0) } :
            todayState.recentActivities.map { UnifiedActivity(from: $0) }
        
        // If we're showing a latest activity card, exclude that activity from the list
        if let latestActivity = getLatestActivity() {
            return activities.filter { $0.id != latestActivity.id }
        } else {
            return activities
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleViewAppear() {
        Logger.debug("👁 [SPINNER] handleViewAppear - hasLoadedInitialData=\(hasCompletedInitialLoad), isViewActive=\(isViewActive), isInitializing=\(isInitializing)")
        
        // Check if we're returning from navigation (was inactive, now becoming active)
        let wasInactive = !isViewActive
        isViewActive = true
        
        // If returning to page (already loaded data + was inactive + spinner done), trigger ring animations
        if hasCompletedInitialLoad && wasInactive && !isInitializing {
            Logger.debug("🔄 [ANIMATION] Returning to Today page (wasInactive=true) - triggering ring animations")
            
            // Reset scroll state for sparklines so they can animate again
            ScrollStateManager.shared.reset()
            Logger.debug("🔄 [ANIMATION] Reset scroll state for sparklines")
            
            // Small delay to ensure views are created before triggering animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                todayState.animationTrigger = UUID()
                Logger.debug("🎬 [ANIMATION] Ring animation trigger fired")
            }
        }
        
        // Only do full refresh on first appear
        guard !hasCompletedInitialLoad else {
            Logger.debug("⏭️ [SPINNER] Skipping handleViewAppear - already loaded")
            return
        }
        hasCompletedInitialLoad = true

        Task {
            if FeatureFlags.shared.useTodayViewV2 {
                // V2 Architecture: TodayViewState.load() was already called during branding animation
                // Just verify it's complete and trigger animations
                Logger.info("🎬 [V2] Using TodayViewState (already loaded during branding)")

                // Wait for load to complete if still in progress
                while todayState.phase.isLoading {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                }

                // Trigger ring animations with fresh data
                todayState.animationTrigger = UUID()
                Logger.info("✅ [V2] TodayViewState ready - animations triggered")
            } else {
                // Original Phase 3 Architecture
                Logger.debug("🎬 [SPINNER] Calling todayState.handle(.viewAppeared)")
                await todayState.handle(.viewAppeared)
                Logger.debug("✅ [SPINNER] todayState.handle(.viewAppeared) completed")
            }

            // Start live activity updates immediately
            liveActivityService.startAutoUpdates()

            // PERFORMANCE: Run illness/wellness AFTER Phase 2 completes
            // Wait a moment to let Phase 2 finish, then run in background
            Task.detached(priority: .background) {
                // Wait for Phase 2 to complete (it takes ~5-10s)
                // This prevents resource contention with strain calculation
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 second delay
                Logger.debug("🔍 [PHASE 3] Starting illness/wellness analysis in background")
                await wellnessService.analyzeHealthTrends()
                await illnessService.analyzeHealthTrends()
                Logger.debug("✅ [PHASE 3] Illness/wellness analysis complete")
            }
        }
        wasHealthKitAuthorized = healthKitManager.isAuthorized
    }
    
    private func handleHealthKitAuthChange(_ newValue: Bool) {
        guard hasCompletedInitialLoad else { return }

        if newValue && !wasHealthKitAuthorized {
            wasHealthKitAuthorized = true
            Task {
                if FeatureFlags.shared.useTodayViewV2 {
                    Logger.info("🔄 [V2] HealthKit authorized - refreshing TodayViewState")
                    await todayState.refresh()
                } else {
                    await todayState.handle(.healthKitAuthorized) // Phase 3: Delegate to coordinator
                }
                liveActivityService.startAutoUpdates()
            }
        }
    }
    
    private func handleAppForeground() {
        Logger.debug("🔄 [FOREGROUND] App entering foreground")

        Task {
            await healthKitManager.checkAuthorizationAfterSettingsReturn()

            if healthKitManager.isAuthorized {
                if FeatureFlags.shared.useTodayViewV2 {
                    Logger.info("🔄 [V2] App foreground - invalidating caches and refreshing")
                    await todayState.invalidateShortLivedCaches()
                    await todayState.refresh()
                } else {
                    await invalidateShortLivedCaches()
                    await todayState.handle(.appForegrounded) // Phase 3: Delegate to coordinator
                }
                liveActivityService.startAutoUpdates()
            }
        }
    }
    
    /// Invalidate short-lived caches when app returns to foreground
    /// Only invalidates HealthKit caches (no API rate limit concerns)
    private func invalidateShortLivedCaches() async {
        let today = Calendar.current.startOfDay(for: Date())
        let todayTimestamp = today.timeIntervalSince1970
        
        // ALWAYS invalidate HealthKit caches (no API cost, no rate limits)
        let healthKitCaches = [
            "healthkit:steps:\(todayTimestamp)",
            "healthkit:active_calories:\(todayTimestamp)",
            "healthkit:walking_distance:\(todayTimestamp)"
        ]
        
        let cacheManager = UnifiedCacheManager.shared
        for key in healthKitCaches {
            await cacheManager.invalidate(key: key)
        }
        
        Logger.debug("🗑️ Invalidated HealthKit caches for foreground refresh")
        
        // NOTE: Strava cache kept at 1 hour to respect API rate limits
        // Pull-to-refresh can force Strava refresh if needed
    }
    
    private func handleIntervalsConnection() {
        guard hasCompletedInitialLoad else { return }

        Task {
            if FeatureFlags.shared.useTodayViewV2 {
                Logger.info("🔄 [V2] Intervals connected - refreshing TodayViewState")
                await todayState.refresh()
            } else {
                await todayState.handle(.intervalsAuthChanged) // Phase 3: Delegate to coordinator
            }
            liveActivityService.startAutoUpdates()
        }
    }
    
    /// Handle scene phase changes (background → active transitions)
    /// CRITICAL: Only triggers after initial load is complete to prevent cancellation errors
    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        Logger.debug("🔄 [SCENE] Scene phase: \(String(describing: oldPhase)) → \(String(describing: newPhase))")
        
        // CRITICAL GUARDS to prevent triggering during initialization:
        // 1. Must have completed initial load
        guard hasCompletedInitialLoad else {
            Logger.debug("⏭️ [SCENE] Skipping - initial load not complete")
            previousScenePhase = newPhase
            return
        }
        
        // 2. View must be active (prevents triggering when navigating away)
        guard isViewActive else {
            Logger.debug("⏭️ [SCENE] Skipping - view not active")
            previousScenePhase = newPhase
            return
        }
        
        // 3. Must not already be loading (prevents cancelling ongoing calculations)
        guard !isLoading else {
            Logger.debug("⏭️ [SCENE] Skipping - already loading")
            previousScenePhase = newPhase
            return
        }
        
        // 4. Only handle background → active transition
        guard oldPhase == .background && newPhase == .active else {
            previousScenePhase = newPhase
            return
        }
        
        Logger.debug("✅ [SCENE] App became active from background - triggering refresh")

        Task {
            if FeatureFlags.shared.useTodayViewV2 {
                Logger.info("🔄 [V2] Scene active from background - refreshing TodayViewState")
                // Invalidate short-lived caches for fresh data
                await todayState.invalidateShortLivedCaches()

                // Refresh data (this will recalculate scores with new activities)
                await todayState.refresh()

                // Trigger ring animations to show updated values
                todayState.animationTrigger = UUID()
                Logger.debug("🎬 [V2] Ring animations triggered after background refresh")
            } else {
                // Invalidate short-lived caches for fresh data
                await invalidateShortLivedCaches()

                // Refresh data (this will recalculate scores with new activities)
                await todayState.refresh()

                // Trigger ring animations to show updated values
                todayState.animationTrigger = UUID()
                Logger.debug("🎬 [SCENE] Ring animations triggered after background refresh")
            }
        }

        previousScenePhase = newPhase
    }
}

// MARK: - Supporting Views

struct HealthKitBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(Color.semantic.error)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(icon == "checkmark.circle.fill" ? .green : .primary)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.background.secondary)
        .overlay(
            Rectangle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

struct RecentActivityCard: View {
    let activity: Activity
    
    var body: some View {
        NavigationLink(destination: RideDetailSheet(activity: activity)) {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: 6) {
                        Text(activity.name ?? "Unnamed Activity")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        if let type = activity.type {
                            Text(type.uppercased())
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.background.tertiary)
                        }
                    }
                    
                    HStack(spacing: Spacing.sm) {
                        if let startDate = parseActivityDate(activity.startDateLocal) {
                            Text(formatActivityDate(startDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let duration = activity.duration {
                            Text(CommonContent.Formatting.bulletPoint)
                                .foregroundColor(.secondary)
                            Text(formatDuration(duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let distance = activity.distance {
                            Text(CommonContent.Formatting.bulletPoint)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", distance / 1000.0)) \(CommonContent.Units.kilometers))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron icon on the right
                Image(systemName: Icons.System.chevronRight)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle()) // Make entire row tappable
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func parseActivityDate(_ dateString: String) -> Date? {
        // Try ISO8601 first (with timezone)
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Try local format without timezone (2025-10-02T06:11:37)
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.timeZone = TimeZone.current
        return localFormatter.date(from: dateString)
    }
    
    private func formatActivityDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct TodayHealthDataCard: View {
    let title: String
    let value: String
    let subtitle: Date?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let subtitle = subtitle {
                Text(formatHealthDate(subtitle))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.background.card)
    }
    
    private func formatHealthDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct TodayView_Previews: PreviewProvider {
    static var previews: some View {
        TodayView()
    }
}