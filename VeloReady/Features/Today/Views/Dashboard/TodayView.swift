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
    @ObservedObject private var viewModel = TodayViewModel.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var wellnessService = WellnessDetectionService.shared
    @StateObject private var illnessService = IllnessDetectionService.shared
    @ObservedObject private var liveActivityService = LiveActivityService.shared
    @State private var showingDebugView = false
    @State private var showingHealthKitPermissionsSheet = false
    @State private var showingWellnessDetailSheet = false
    @State private var showingIllnessDetailSheet = false
    @State private var showMissingSleepInfo = false
    @State private var wasHealthKitAuthorized = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isViewActive = false
    @Binding var showInitialSpinner: Bool
    
    private let viewState = ViewStateManager.shared
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @ObservedObject private var stravaAuth = StravaAuthService.shared
    @ObservedObject private var intervalsAuth = IntervalsOAuthManager.shared
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    init(showInitialSpinner: Binding<Bool> = .constant(true)) {
        self._showInitialSpinner = showInitialSpinner
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                    // Adaptive background (light grey in light mode, black in dark mode)
                    Color.background.app
                        .ignoresSafeArea()

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
                        if !viewModel.isInitializing {
                            LoadingStatusView(
                                state: viewModel.loadingStateManager.currentState,
                                onErrorTap: {
                                    viewModel.retryLoading()
                                }
                            )
                            .padding(.leading, 0)
                            .padding(.top, 0)
                            .padding(.bottom, Spacing.sm)
                        }
                        
                        // Recovery Metrics (Three Graphs)
                        RecoveryMetricsSection(
                            isHealthKitAuthorized: healthKitManager.isAuthorized,
                            animationTrigger: viewModel.animationTrigger,
                            hideBottomDivider: true
                        )
                        
                        // HealthKit Enablement Section (only when not authorized)
                        if !viewModel.isHealthKitAuthorized {
                            HealthKitEnablementSection(
                                showingHealthKitPermissionsSheet: $showingHealthKitPermissionsSheet
                            )
                        }
                        
                        // Health Warnings (Illness & Wellness alerts)
                        if healthKitManager.isAuthorized {
                            HealthWarningsCardV2()
                        }
                        
                        // Fixed Today page sections
                        if healthKitManager.isAuthorized {
                            // Unified AI Brief (Pro) or Computed Brief (Free)
                            AIBriefView()
                            
                            // Latest Activity from Strava/Intervals
                            if hasConnectedDataSource {
                                if let latestActivity = getLatestActivity() {
                                    LatestActivityCardV2(activity: latestActivity)
                                        .id(latestActivity.id)
                                } else {
                                    SkeletonActivityCard()
                                }
                            }
                            
                            // Steps
                            StepsCardV2()
                                .opacity(liveActivityService.isLoading ? 0 : 1)
                                .overlay {
                                    if liveActivityService.isLoading {
                                        SkeletonStatsCard()
                                    }
                                }
                            
                            // Calories
                            if liveActivityService.isLoading {
                                SkeletonStatsCard()
                            } else {
                                CaloriesCardV2()
                            }
                            
                            // Recent Activities
                            if viewModel.isLoading && viewModel.unifiedActivities.isEmpty {
                                SkeletonRecentActivities()
                            } else {
                                RecentActivitiesSection(
                                    allActivities: viewModel.unifiedActivities.isEmpty ?
                                        viewModel.recentActivities.map { UnifiedActivity(from: $0) } :
                                        viewModel.unifiedActivities,
                                    dailyActivityData: generateDailyActivityData()
                                )
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
                    .padding(.bottom, 120)
                }
                .coordinateSpace(name: "scroll")
                .if(networkMonitor.isConnected) { view in
                    view.refreshable {
                        // User-triggered refresh action (pull-to-refresh)
                        // LoadingStatusView provides visual feedback (no blocking spinner)
                        await viewModel.refreshData()
                    }
                }
                
                // Loading overlay - shows on top of content
                if viewModel.isInitializing {
                    LoadingOverlay()
                        .transition(.opacity)
                }
                
                // Navigation gradient mask (iOS Mail style)
                if !viewModel.isInitializing {
                    NavigationGradientMask()
                }
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .navigationTitle(TodayContent.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar(viewModel.isInitializing ? .hidden : .visible, for: .navigationBar)
        }
        .toolbar(viewModel.isInitializing ? .hidden : .visible, for: .tabBar)
        .onAppear {
            Logger.debug("👁 [SPINNER] TodayView.onAppear called - isInitializing=\(viewModel.isInitializing)")
            Logger.debug("📋 SPACING DEBUG:")
            Logger.debug("📋   LazyVStack spacing: Spacing.md = \(Spacing.md)pt")
            Logger.debug("📋   Each card .padding(.vertical, Spacing.xxl / 2) = \(Spacing.xxl / 2)pt")
            Logger.debug("📋   Total between cards: \(Spacing.md) + \(Spacing.xxl / 2) + \(Spacing.xxl / 2) = \(Spacing.md + Spacing.xxl)pt")
            handleViewAppear()
        }
        .onDisappear {
            Logger.debug("👋 [SPINNER] TodayView.onDisappear called - marking view as inactive")
            isViewActive = false
            viewModel.cancelBackgroundTasks()
        }
        .onChange(of: viewModel.isInitializing) { oldValue, newValue in
            Logger.debug("🔄 [SPINNER] TabBar visibility changed - isInitializing: \(oldValue) → \(newValue), toolbar: \(newValue ? ".hidden" : ".visible")")
            if !newValue {
                Logger.debug("🔄 [SPINNER] Setting showInitialSpinner = false to show FloatingTabBar")
                showInitialSpinner = false
            }
        }
        .onChange(of: healthKitManager.isAuthorized) { _, newValue in
            handleHealthKitAuthChange(newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            handleAppForeground()
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
                    value: "No data", // TODO: Implement sleep data fetching
                    subtitle: nil,
                    icon: "moon.fill",
                    color: .blue
                )
                
                // HRV Data
                TodayHealthDataCard(
                    title: "HRV",
                    value: "No data", // TODO: Implement HRV data fetching
                    subtitle: nil,
                    icon: "heart.fill",
                    color: .green
                )
                
                // RHR Data
                TodayHealthDataCard(
                    title: "Resting HR",
                    value: "No data", // TODO: Implement RHR data fetching
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
        let activities = viewModel.unifiedActivities.isEmpty ? 
            viewModel.recentActivities.map { UnifiedActivity(from: $0) } :
            viewModel.unifiedActivities
        
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
                
                // Use duration if available, otherwise calculate from intervalsActivity or use a default
                let duration: Double = {
                    if let dur = activity.duration, dur > 0 {
                        return dur / 60.0 // Convert seconds to minutes
                    } else if activity.intervalsActivity != nil {
                        // For Intervals activities, use TSS as a proxy for duration/intensity
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
        stravaAuth.connectionState.isConnected || intervalsAuth.isAuthenticated
    }
    
    private func getLatestActivity() -> UnifiedActivity? {
        let activities = viewModel.unifiedActivities.isEmpty ?
            viewModel.recentActivities.map { UnifiedActivity(from: $0) } :
            viewModel.unifiedActivities
        
        // Filter to only Strava/Intervals activities (not Apple Health)
        return activities.first { activity in
            activity.source == .strava || activity.source == .intervalsICU
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleViewAppear() {
        Logger.debug("👁 [SPINNER] handleViewAppear - hasLoadedInitialData=\(viewState.hasCompletedTodayInitialLoad), isViewActive=\(isViewActive), isInitializing=\(viewModel.isInitializing)")
        
        // Check if we're returning from navigation (was inactive, now becoming active)
        let wasInactive = !isViewActive
        isViewActive = true
        
        // If returning to page (already loaded data + was inactive + spinner done), trigger ring animations
        if viewState.hasCompletedTodayInitialLoad && wasInactive && !viewModel.isInitializing {
            Logger.debug("🔄 [ANIMATION] Returning to Today page (wasInactive=true) - triggering ring animations")
            
            // Reset scroll state for sparklines so they can animate again
            ScrollStateManager.shared.reset()
            Logger.debug("🔄 [ANIMATION] Reset scroll state for sparklines")
            
            // Small delay to ensure views are created before triggering animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.animationTrigger = UUID()
                Logger.debug("🎬 [ANIMATION] Ring animation trigger fired")
            }
        }
        
        // Only do full refresh on first appear
        guard !viewState.hasCompletedTodayInitialLoad else {
            Logger.debug("⏭️ [SPINNER] Skipping handleViewAppear - already loaded")
            return
        }
        viewState.hasCompletedTodayInitialLoad = true
        Logger.debug("🎬 [SPINNER] Calling viewModel.loadInitialUI()")
        
        Task {
            await viewModel.loadInitialUI()
            Logger.debug("✅ [SPINNER] viewModel.loadInitialUI() completed")
            
            // Start live activity updates immediately
            liveActivityService.startAutoUpdates()
            
            // PERFORMANCE: Run illness/wellness AFTER Phase 2 completes
            // Wait a moment to let Phase 2 finish, then run in background
            Task.detached(priority: .background) {
                // Wait for Phase 2 to complete (it takes ~5-10s)
                // This prevents resource contention with strain calculation
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 second delay
                await Logger.debug("🔍 [PHASE 3] Starting illness/wellness analysis in background")
                await wellnessService.analyzeHealthTrends()
                await illnessService.analyzeHealthTrends()
                await Logger.debug("✅ [PHASE 3] Illness/wellness analysis complete")
            }
        }
        wasHealthKitAuthorized = healthKitManager.isAuthorized
    }
    
    private func handleHealthKitAuthChange(_ newValue: Bool) {
        // Skip if initial load hasn't completed yet (prevents duplicate refresh on startup)
        guard viewState.hasCompletedTodayInitialLoad else {
            Logger.debug("⏭️ [SPINNER] Skipping HealthKit auth change handler - initial load not complete")
            return
        }
        
        if newValue && !wasHealthKitAuthorized {
            wasHealthKitAuthorized = true
            Task {
                await viewModel.recoveryScoreService.clearBaselineCache()
                await viewModel.refreshData(forceRecoveryRecalculation: true)
                liveActivityService.startAutoUpdates()
            }
        }
    }
    
    private func handleAppForeground() {
        Logger.debug("🔄 [FOREGROUND] App entering foreground - preparing fresh data fetch")
        
        Task {
            // Check scores BEFORE doing anything
            Logger.debug("🔄 [FOREGROUND] Score state BEFORE handleAppForeground:")
            Logger.debug("   Recovery: \(viewModel.recoveryScoreService.currentRecoveryScore?.score ?? -999)")
            Logger.debug("   Sleep: \(viewModel.sleepScoreService.currentSleepScore?.score ?? -999)")
            Logger.debug("   Strain: \(viewModel.strainScoreService.currentStrainScore?.score ?? -999)")
            
            await healthKitManager.checkAuthorizationAfterSettingsReturn()
            
            if healthKitManager.isAuthorized {
                Logger.debug("🔄 [FOREGROUND] HealthKit authorized - starting refresh")
                
                // Invalidate short-lived caches for fresh data
                await invalidateShortLivedCaches()
                
                // Check scores AFTER cache invalidation
                Logger.debug("🔄 [FOREGROUND] Score state AFTER cache invalidation:")
                Logger.debug("   Recovery: \(viewModel.recoveryScoreService.currentRecoveryScore?.score ?? -999)")
                Logger.debug("   Sleep: \(viewModel.sleepScoreService.currentSleepScore?.score ?? -999)")
                Logger.debug("   Strain: \(viewModel.strainScoreService.currentStrainScore?.score ?? -999)")
                
                // Now refresh will get fresh data
                liveActivityService.startAutoUpdates()
                
                Logger.debug("🔄 [FOREGROUND] About to call viewModel.refreshData()")
                await viewModel.refreshData()
                
                // Check scores AFTER refresh
                Logger.debug("🔄 [FOREGROUND] Score state AFTER viewModel.refreshData():")
                Logger.debug("   Recovery: \(viewModel.recoveryScoreService.currentRecoveryScore?.score ?? -999)")
                Logger.debug("   Sleep: \(viewModel.sleepScoreService.currentSleepScore?.score ?? -999)")
                Logger.debug("   Strain: \(viewModel.strainScoreService.currentStrainScore?.score ?? -999)")
                
                // PERFORMANCE: Run illness detection in background (don't block refresh)
                Task.detached(priority: .background) {
                    await illnessService.analyzeHealthTrends()
                }
            } else {
                Logger.debug("🔄 [FOREGROUND] HealthKit NOT authorized - skipping refresh")
            }
            
            Logger.debug("🔄 [FOREGROUND] handleAppForeground complete")
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
            cacheManager.invalidate(key: key)
        }
        
        Logger.debug("🗑️ Invalidated HealthKit caches for foreground refresh")
        
        // NOTE: Strava cache kept at 1 hour to respect API rate limits
        // Pull-to-refresh can force Strava refresh if needed
    }
    
    private func handleIntervalsConnection() {
        // Skip if initial load hasn't completed yet (prevents duplicate refresh on startup)
        guard viewState.hasCompletedTodayInitialLoad else {
            Logger.debug("⏭️ [SPINNER] Skipping Intervals connection handler - initial load not complete")
            return
        }
        
        Task {
            await viewModel.refreshData()
            liveActivityService.startAutoUpdates()
        }
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
    let activity: IntervalsActivity
    
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