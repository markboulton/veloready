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
    @StateObject private var viewModel = TodayViewModel()
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var wellnessService = WellnessDetectionService.shared
    @StateObject private var liveActivityService: LiveActivityService
    @State private var showingDebugView = false
    @State private var showingHealthKitPermissionsSheet = false
    @State private var showingWellnessDetailSheet = false
    @State private var missingSleepBannerDismissed = UserDefaults.standard.bool(forKey: "missingSleepBannerDismissed")
    @State private var showMissingSleepInfo = false
    @State private var showMainSpinner = true
    @State private var wasHealthKitAuthorized = false
    @State private var isSleepBannerExpanded = true
    
    init() {
        // Initialize LiveActivityService with shared OAuth manager to avoid creating new instances
        self._liveActivityService = StateObject(wrappedValue: LiveActivityService(oauthManager: IntervalsOAuthManager.shared))
        
        // Set main spinner to show immediately on app launch
        self.showMainSpinner = true
    }
    
    var body: some View {
        ZStack {
            if showMainSpinner {
                loadingSpinner
            }
            
            // Only show NavigationView when main spinner is hidden
            if !showMainSpinner {
                NavigationView {
                ZStack {
                    // Gradient background
                    GradientBackground()
                    
                ScrollView {
                    
                    VStack(spacing: 20) {
                        // Recovery Metrics (Three Graphs) - Lazy loaded
                        // Missing sleep data warning (collapsible, above metrics)
                        if healthKitManager.isAuthorized, 
                           let recoveryScore = viewModel.recoveryScoreService.currentRecoveryScore,
                           recoveryScore.inputs.sleepDuration == nil {
                            missingSleepDataBanner
                        }
                        
                        LazyVStack(spacing: 20) {
                            RecoveryMetricsSection(
                                recoveryScoreService: viewModel.recoveryScoreService,
                                sleepScoreService: viewModel.sleepScoreService,
                                strainScoreService: viewModel.strainScoreService,
                                isHealthKitAuthorized: healthKitManager.isAuthorized,
                                missingSleepBannerDismissed: $missingSleepBannerDismissed
                            )
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
                            HealthKitEnablementSection(
                                showingHealthKitPermissionsSheet: $showingHealthKitPermissionsSheet
                            )
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
                                        .padding(16)
                                        .background(Color(.systemBackground).opacity(0.6))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        
                        // Activity stats row (steps and calories) - Always show if HealthKit is authorized
                        if healthKitManager.isAuthorized {
                            ActivityStatsRow(liveActivityService: liveActivityService)
                        }
                        
                        // Recent Activities (excluding the latest one) - Lazy loaded
                        LazyVStack(spacing: 20) {
                            RecentActivitiesSection(
                                allActivities: viewModel.unifiedActivities.isEmpty ?
                                    viewModel.recentActivities.map { UnifiedActivity(from: $0) } :
                                    viewModel.unifiedActivities,
                                dailyActivityData: generateDailyActivityData()
                            )
                        }
                    }
                    .padding()
                }
                .coordinateSpace(name: "scroll")
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.automatic, for: .navigationBar)
            .refreshable {
                await viewModel.forceRefreshData()
            }
            .onAppear {
                handleViewAppear()
            }
            .onChange(of: healthKitManager.isAuthorized) { newValue in
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
    
    // MARK: - Loading Spinner
    
    private var loadingSpinner: some View {
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
        .zIndex(999)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showMainSpinner = false
                }
            }
        }
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func latestRideSection(latestRide: IntervalsActivity) -> some View {
        // Latest ride panel
        LatestRidePanel(activity: latestRide)
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
        VStack(alignment: .leading, spacing: 0) {
            // Header row - always visible
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSleepBannerExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    
                    Text("Sleep data missing")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isSleepBannerExpanded ? 0 : -90))
                        .animation(.easeInOut(duration: 0.3), value: isSleepBannerExpanded)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable content
            if isSleepBannerExpanded {
                Text("Recovery is based only on waking HRV and resting HR. Wear your watch tonight for complete recovery analysis.")
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
    
    // MARK: - Event Handlers
    
    private func handleViewAppear() {
        Task {
            await viewModel.loadInitialUI()
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                liveActivityService.startAutoUpdates()
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await wellnessService.analyzeHealthTrends()
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
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