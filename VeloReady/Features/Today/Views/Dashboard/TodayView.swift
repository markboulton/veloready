import SwiftUI

/// Main Today view showing current activities and progress
struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var wellnessService = WellnessDetectionService.shared
    @StateObject private var liveActivityService: LiveActivityService
    @State private var showingDebugView = false
    @State private var showingHealthKitPermissionsSheet = false
    @State private var showingWellnessDetailSheet = false
    @State private var showMainSpinner = true
    @State private var wasHealthKitAuthorized = false
    
    init() {
        // Initialize LiveActivityService with shared OAuth manager to avoid creating new instances
        self._liveActivityService = StateObject(wrappedValue: LiveActivityService(oauthManager: IntervalsOAuthManager.shared))
        
        // Set main spinner to show immediately on app launch
        self.showMainSpinner = true
    }
    
    var body: some View {
        ZStack {
            // Main spinner overlay - shows immediately on app launch
            if showMainSpinner {
                VStack(spacing: 20) {
                    Spacer()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: ColorPalette.neutral400))
                    
                    Text(CommonContent.loading)
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .ignoresSafeArea(.all)
                .zIndex(999) // Ensure it's always on top
                .onAppear {
                    print("🎯 Main spinner is now visible - showMainSpinner = \(showMainSpinner)")
                    
                    // Hide main spinner after 4 seconds with smooth animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        print("🎯 Hiding main spinner after 4 seconds - showMainSpinner = \(showMainSpinner)")
                        withAnimation(.easeOut(duration: 0.3)) {
                            showMainSpinner = false
                        }
                    }
                }
            }
            
            // Only show NavigationView when main spinner is hidden
            if !showMainSpinner {
                NavigationView {
                ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Section
                       
                        
                        // Recovery Metrics (Three Graphs) - Lazy loaded
                        LazyVStack(spacing: 20) {
                            recoveryMetricsSection
                        }
                        
                        // Missing sleep data warning
                        if healthKitManager.isAuthorized, 
                           let recoveryScore = viewModel.recoveryScoreService.currentRecoveryScore,
                           recoveryScore.inputs.sleepDuration == nil {
                            missingSleepDataBanner
                        }
                        
                        // AI Daily Brief - Lazy loaded (only show when HealthKit authorized)
                        if healthKitManager.isAuthorized {
                            LazyVStack(spacing: 20) {
                                AIBriefView()
                            }
                        }
                        
                        // Wellness Alert Banner - shows below daily brief when health patterns detected
                        if healthKitManager.isAuthorized, let alert = wellnessService.currentAlert {
                            WellnessBanner(alert: alert) {
                                showingWellnessDetailSheet = true
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // HealthKit Enablement Section (only shown when not authorized)
                        if !viewModel.isHealthKitAuthorized {
                            healthKitEnablementSection
                        }
                        
                        // Latest Ride Panel - Lazy loaded (first cycling activity from any source)
                        if let latestCyclingActivity = viewModel.unifiedActivities.first(where: { $0.type == .cycling }) {
                            LazyVStack(spacing: 12) {
                                // Section heading
                                HStack {
                                    Text("Latest Ride")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                
                                // Show Intervals ride panel if available, otherwise show unified activity card
                                if let intervalsRide = latestCyclingActivity.intervalsActivity {
                                    latestRideSection(latestRide: intervalsRide)
                                } else {
                                    // Fallback for Strava/Health activities
                                    UnifiedActivityCard(activity: latestCyclingActivity)
                                }
                            }
                        }
                        
                        // Activity stats row (steps and calories) - Always show if HealthKit is authorized
                        if healthKitManager.isAuthorized {
                            ActivityStatsRow(liveActivityService: liveActivityService)
                        }
                        
                        // Recent Activities (excluding the latest one) - Lazy loaded
                        LazyVStack(spacing: 20) {
                            recentActivitiesSection
                        }
                    }
                    .padding()
                }
                
            }
            .navigationTitle("Today")
            .refreshable {
                await viewModel.forceRefreshData()
            }
            .onAppear {
                // ULTRA-FAST startup - instant UI, defer ALL heavy operations
                Task {
                    await viewModel.loadInitialUI()
                    // Defer live activity updates and wellness check to background
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
                        liveActivityService.startAutoUpdates() // This calls updateLiveDataImmediately internally
                        
                        // Analyze wellness trends after initial load
                        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 second delay
                        await wellnessService.analyzeHealthTrends()
                    }
                }
                // Track initial authorization state
                wasHealthKitAuthorized = healthKitManager.isAuthorized
            }
            .onChange(of: healthKitManager.isAuthorized) { newValue in
                // When HealthKit authorization changes from unauthorized to authorized
                if newValue && !wasHealthKitAuthorized {
                    print("✅ HealthKit just authorized - forcing recalculation with health metrics")
                    wasHealthKitAuthorized = true
                    Task {
                        // Clear baseline cache so we fetch fresh historical data from HealthKit
                        viewModel.clearBaselineCache()
                        // Force recovery recalculation to include newly available HealthKit data
                        await viewModel.refreshData(forceRecoveryRecalculation: true)
                        // Also update live activity data
                        liveActivityService.startAutoUpdates()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // When returning from Settings, refresh HealthKit status and live data
                Task {
                    print("🔄 App entering foreground - refreshing HealthKit status and live data")
                    await healthKitManager.checkAuthorizationAfterSettingsReturn()
                    
                    // Restart live activity updates (this handles the immediate update internally)
                    liveActivityService.startAutoUpdates()
                    
                    // If we're now authorized but weren't before, refresh all data
                    if healthKitManager.isAuthorized {
                        print("✅ HealthKit authorized - refreshing all data")
                        await viewModel.refreshData()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .refreshDataAfterIntervalsConnection)) { _ in
                // Automatically refresh data after successful Intervals.icu connection
                Task {
                    print("🔄 Intervals.icu connected - automatically refreshing data")
                    await viewModel.refreshData()
                    liveActivityService.startAutoUpdates()
                }
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
            
            // Full-screen loading spinner overlay (covers everything including nav bar)
            if viewModel.isInitializing {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: ColorPalette.neutral400))
                    Text(CommonContent.loading)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .ignoresSafeArea(.all) // Cover everything including nav bar and tab bar
            }
            }
            .transition(.opacity)
            }
        }
        .toolbar(showMainSpinner ? .hidden : .visible, for: .tabBar)
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Welcome back!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("How are you feeling today?")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    
    private var recoveryMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Show empty state rings when HealthKit is not authorized
            if !healthKitManager.isAuthorized {
                HStack(spacing: 12) {
                        // Recovery (left)
                        EmptyStateRingView(
                            title: "Recovery",
                            icon: "heart.fill",
                            animationDelay: 0.0
                        )
                        .frame(maxWidth: .infinity)
                        
                        // Sleep (center)
                        EmptyStateRingView(
                            title: "Sleep",
                            icon: "moon.fill",
                            animationDelay: 0.1
                        )
                        .frame(maxWidth: .infinity)
                        
                        // Load (right)
                        EmptyStateRingView(
                            title: "Load",
                            icon: "figure.walk",
                            animationDelay: 0.2
                        )
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    // Show actual data when HealthKit is authorized
                    HStack(spacing: 12) {
                        // Recovery Score (left)
                        if let recoveryScore = viewModel.recoveryScoreService.currentRecoveryScore {
                            NavigationLink(destination: RecoveryDetailView(recoveryScore: recoveryScore)) {
                                VStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Text(TodayContent.Scores.recoveryScore)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // Show warning icon if sleep data is missing
                                    if recoveryScore.inputs.sleepDuration == nil {
                                        CompactRingView(
                                            score: recoveryScore.score,
                                            title: "?",
                                            band: RecoveryScore.RecoveryBand.amber,
                                            animationDelay: 0.0
                                        ) {
                                            // Empty action - navigation handled by parent NavigationLink
                                        }
                                    } else {
                                        CompactRingView(
                                            score: recoveryScore.score,
                                            title: recoveryScore.bandDescription,
                                            band: recoveryScore.band,
                                            animationDelay: 0.0 // First graph - no delay
                                        ) {
                                            // Empty action - navigation handled by parent NavigationLink
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            VStack(spacing: 12) {
                                Text(TodayContent.Scores.recoveryScore)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text(CommonContent.loading)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 80, height: 80)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Sleep Score (center)
                        if let sleepScore = viewModel.sleepScoreService.currentSleepScore {
                            NavigationLink(destination: SleepDetailView(sleepScore: sleepScore)) {
                                VStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Text(TodayContent.Scores.sleepScore)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    CompactRingView(
                                        score: sleepScore.score,
                                        title: sleepScore.bandDescription,
                                        band: sleepScore.band,
                                        animationDelay: 0.1 // Second graph - slight delay
                                    ) {
                                        // Empty action - navigation handled by parent NavigationLink
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            VStack(spacing: 12) {
                                Text(TodayContent.Scores.sleepScore)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text(CommonContent.loading)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 80, height: 80)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Load Score (right) - changed from "Strain" to "Load"
                        if let strainScore = viewModel.strainScoreService.currentStrainScore {
                            NavigationLink(destination: StrainDetailView(strainScore: strainScore)) {
                                VStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Text(TodayContent.Scores.strainScore)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // Convert 0-18 score to 0-100 for ring display
                                    let ringScore = Int((strainScore.score / 18.0) * 100.0)
                                    CompactRingView(
                                        score: ringScore,
                                        title: strainScore.formattedScore, // Show 0-18 scale with decimal
                                        band: strainScore.band,
                                        animationDelay: 0.2 // Third graph - most delay
                                    ) {
                                        // Empty action - navigation handled by parent NavigationLink
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            VStack(spacing: 12) {
                                Text(TodayContent.Scores.strainScore)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text(CommonContent.loading)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 80, height: 80)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var healthKitEnablementSection: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 48))
                    .foregroundColor(ColorScale.pinkAccent)
                
                Text(TodayContent.healthKitRequired)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Connect your Apple Health data to see personalized recovery scores, sleep analysis, and training insights.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Benefits list
            VStack(spacing: 12) {
                HealthKitBenefitRow(
                    icon: "heart.circle.fill",
                    title: "Recovery Score",
                    description: "Track your readiness based on HRV, sleep, and training"
                )
                
                HealthKitBenefitRow(
                    icon: "moon.fill",
                    title: "Sleep Analysis",
                    description: "Detailed sleep staging from Apple Watch"
                )
                
                HealthKitBenefitRow(
                    icon: "figure.walk",
                    title: "Training Load",
                    description: "Monitor daily strain and training stress"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Enable button
            Button(action: { showingHealthKitPermissionsSheet = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                    Text(TodayContent.grantAccess)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.button.danger)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Text("Your health data stays private and secure")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.semantic.error.opacity(0.3), lineWidth: 2)
                )
        )
    }
    
    
    
    private var healthDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Health Today")
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func latestRideSection(latestRide: IntervalsActivity) -> some View {
        // Latest ride panel
        LatestRidePanel(activity: latestRide)
    }
    
    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(TodayContent.activitiesSection)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                ActivitySparkline(
                    dailyActivities: generateDailyActivityData(),
                    alignment: .trailing,
                    height: 24
                )
                .frame(width: 120)
            }
            
            // Use unified activities if available, otherwise fall back to Intervals only
            let activities = viewModel.unifiedActivities.isEmpty ? 
                viewModel.recentActivities.map { UnifiedActivity(from: $0) } :
                viewModel.unifiedActivities
            
            // Show all activities except the first cycling one (which is shown in latest ride panel)
            let firstCyclingIndex = activities.firstIndex(where: { $0.type == .cycling })
            let remainingActivities = firstCyclingIndex != nil ? 
                Array(activities.enumerated().filter { $0.offset != firstCyclingIndex }.map { $0.element }) : 
                activities
            
            if remainingActivities.isEmpty {
                Text(TodayContent.noActivities)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(remainingActivities) { activity in
                        UnifiedActivityCard(activity: activity)
                        
                        if activity.id != remainingActivities.last?.id {
                            Divider()
                                .background(Color(.systemGray4))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
                    } else if let intervalsActivity = activity.intervalsActivity {
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
            return "Connected"
        case .denied:
            return "Access Denied"
        case .notDetermined:
            return "Not Enabled"
        case .partial:
            return "Partial Access"
        case .notAvailable:
            return "Not Available"
        }
    }
    
    private var healthKitStatusIcon: String {
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                Image(systemName: "moon.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Sleep data missing")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Recovery is based only on waking HRV and resting HR. Wear your watch tonight for complete recovery analysis.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RideStatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
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
                                .background(Color(.systemGray5))
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        if let startDate = parseActivityDate(activity.startDateLocal) {
                            Text(formatActivityDate(startDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let duration = activity.duration {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(formatDuration(duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let distance = activity.distance {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", distance / 1000.0)) km")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron icon on the right
                Image(systemName: "chevron.right")
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
        .background(Color(.systemBackground))
        .cornerRadius(8)
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