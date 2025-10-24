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
    @State private var isSleepBannerExpanded = true
    @State private var scrollOffset: CGFloat = 0
    @State private var sectionOrder: TodaySectionOrder = TodaySectionOrder.load()
    @State private var isViewActive = false
    @Binding var showInitialSpinner: Bool
    
    private let viewState = ViewStateManager.shared
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @ObservedObject private var stravaAuth = StravaAuthService.shared
    @ObservedObject private var intervalsAuth = IntervalsOAuthManager.shared
    
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
                        
                        // Missing sleep data warning
                        if healthKitManager.isAuthorized, 
                           let recoveryScore = viewModel.recoveryScoreService.currentRecoveryScore,
                           recoveryScore.inputs.sleepDuration == nil {
                            missingSleepDataBanner
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
                        
                        // Movable sections (ordered by user preference)
                        if healthKitManager.isAuthorized {
                            ForEach(sectionOrder.movableSections) { section in
                                movableSection(section)
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
                .refreshable {
                    await viewModel.forceRefreshData()
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
            handleViewAppear()
        }
        .onDisappear {
            Logger.debug("👋 [SPINNER] TodayView.onDisappear called - marking view as inactive")
            isViewActive = false
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
        .onReceive(NotificationCenter.default.publisher(for: .todaySectionOrderChanged)) { _ in
            sectionOrder = TodaySectionOrder.load()
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
        VStack(spacing: 12) {
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
            ], spacing: 12) {
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
    
    // MARK: - Missing Sleep Data Banner
    
    private var missingSleepDataBanner: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row - always visible
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSleepBannerExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: Icons.Health.sleepFill)
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    
                    Text(TodayContent.sleepDataMissing)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: Icons.System.chevronDown)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isSleepBannerExpanded ? 0 : -90))
                        .animation(.easeInOut(duration: 0.3), value: isSleepBannerExpanded)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable content
            if isSleepBannerExpanded {
                Text(TodayContent.recoveryLimitedMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .padding(.leading, 28) // Align with text above (icon width + spacing)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
    
    // MARK: - Movable Sections
    
    @ViewBuilder
    private func movableSection(_ section: TodaySection) -> some View {
        switch section {
        case .veloAI:
            // Unified component handles both Pro (AI) and Free (computed) briefs
            AIBriefView()
        case .latestActivity:
            if hasConnectedDataSource {
                if let latestActivity = getLatestActivity() {
                    LatestActivityCardV2(activity: latestActivity)
                } else if viewModel.isLoading {
                    SkeletonActivityCard()
                }
            }
        case .steps:
            StepsCardV2()
                .opacity(liveActivityService.isLoading ? 0 : 1)
                .overlay {
                    if liveActivityService.isLoading {
                        SkeletonStatsCard()
                    }
                }
        case .calories:
            if liveActivityService.isLoading {
                SkeletonStatsCard()
            } else {
                CaloriesCardV2()
            }
        case .stepsAndCalories, .dailyBrief:
            // Legacy - no longer used (dailyBrief unified with veloAI)
            EmptyView()
        case .recentActivities:
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
        // Reload section order in case it changed in settings
        sectionOrder = TodaySectionOrder.load()
        
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
            Task {
                // Start live activity updates immediately
                liveActivityService.startAutoUpdates()
                // Short delay before wellness analysis to avoid blocking UI
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await wellnessService.analyzeHealthTrends()
                // Run illness detection after wellness analysis
                await illnessService.analyzeHealthTrends()
            }
        }
        wasHealthKitAuthorized = healthKitManager.isAuthorized
    }
    
    private func handleHealthKitAuthChange(_ newValue: Bool) {
        if newValue && !wasHealthKitAuthorized {
            wasHealthKitAuthorized = true
            Task {
                viewModel.clearBaselineCache()
                await viewModel.refreshData(forceRecoveryRecalculation: true)
                liveActivityService.startAutoUpdates()
            }
        }
    }
    
    private func handleAppForeground() {
        Task {
            await healthKitManager.checkAuthorizationAfterSettingsReturn()
            liveActivityService.startAutoUpdates()
            if healthKitManager.isAuthorized {
                await viewModel.refreshData()
                // Re-analyze illness detection when app comes to foreground
                await illnessService.analyzeHealthTrends()
            }
        }
    }
    
    private func handleIntervalsConnection() {
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color.semantic.error)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 12) {
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
        VStack(alignment: .leading, spacing: 12) {
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
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
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
                    
                    HStack(spacing: 8) {
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
        VStack(alignment: .leading, spacing: 12) {
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