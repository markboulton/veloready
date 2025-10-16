import SwiftUI

// MARK: - Shimmer Extension

extension View {
    func shimmerActivityList() -> some View {
        self.modifier(ShimmerActivityListModifier())
    }
}

struct ShimmerActivityListModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.2),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

struct ActivitiesView: View {
    @StateObject private var viewModel = ActivitiesViewModel()
    @EnvironmentObject var apiClient: IntervalsAPIClient
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @ObservedObject private var stravaAuthService = StravaAuthService.shared
    @State private var showingFilterSheet = false
    @State private var showPaywall = false
    @State private var lastStravaConnectionState: StravaConnectionState = .disconnected
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                GradientBackground()
                
                Group {
                    if viewModel.isLoading && viewModel.groupedActivities.isEmpty {
                        ActivitiesLoadingView()
                    } else if viewModel.groupedActivities.isEmpty {
                        ActivitiesEmptyStateView(onRefresh: {
                            await viewModel.loadActivities(apiClient: apiClient)
                        })
                    } else {
                        activitiesList
                    }
                }
            }
            .navigationTitle(ActivitiesContent.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.automatic, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilterSheet = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(Color.button.primary)
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                ActivityFilterSheet(viewModel: viewModel)
            }
            .refreshable {
                await viewModel.loadActivities(apiClient: apiClient)
            }
            .task {
                // Only load once on first appearance
                await viewModel.loadActivitiesIfNeeded(apiClient: apiClient)
            }
            .onChange(of: stravaAuthService.connectionState) { _, newState in
                // Force refresh when Strava connects
                if case .connected = newState, case .disconnected = lastStravaConnectionState {
                    Logger.debug("🔄 Strava connected - forcing activities refresh")
                    Task {
                        await viewModel.forceRefresh(apiClient: apiClient)
                    }
                }
                lastStravaConnectionState = newState
            }
        }
    }
    
    
    // MARK: - Activities List
    
    private var activitiesList: some View {
        List {
            // Sparkline header (full width, before first section)
            Section {
                ActivitySparkline(
                    dailyActivities: generateDailyActivityData(),
                    alignment: .leading,
                    height: 32
                )
                .listRowInsets(EdgeInsets(top: 24, leading: 0, bottom: 16, trailing: 16))
                .listRowBackground(Color.clear)
            } header: {
                EmptyView()
            }
            .listSectionSpacing(0)
            
            ForEach(viewModel.sortedMonthKeys, id: \.self) { monthKey in
                Section {
                    ForEach(viewModel.groupedActivities[monthKey] ?? []) { activity in
                        ZStack {
                            NavigationLink(destination: activityDestination(for: activity)) {
                                EmptyView()
                            }
                            .opacity(0)
                            
                            SharedActivityRowView(activity: activity)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(
                            Color(.systemBackground).opacity(0.6)
                        )
                    }
                } header: {
                    Text(monthKey)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.leading, -16)
                        .listRowBackground(Color.clear)
                }
            }
            
            // Load More button for PRO users
            if proConfig.hasProAccess && !viewModel.isLoadingMore && !viewModel.hasLoadedExtended {
                Section {
                    Button(action: {
                        Task {
                            await viewModel.loadExtendedActivities(apiClient: apiClient)
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Load More Activities (60 days)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(Color.button.primary)
                    .listRowBackground(
                        Color(.systemBackground).opacity(0.6)
                    )
                }
            }
            
            // Upgrade CTA for FREE users
            if !proConfig.hasProAccess {
                Section {
                    Button(action: { showPaywall = true }) {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(ColorScale.purpleAccent)
                                Text("Upgrade to Pro for More Activities")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            Text("Access up to 90 days of activity history with PRO")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text("Upgrade Now")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(ColorScale.purpleAccent)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(
                        Color(.systemBackground).opacity(0.6)
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Helper Functions
    
    private func generateDailyActivityData() -> [DailyActivityData] {
        // Get all activities
        let allActivities = viewModel.groupedActivities.values.flatMap { $0 }
        
        // Group activities by day
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Create dictionary of day offset -> activities
        var dailyMap: [Int: [ActivityBarData]] = [:]
        
        for activity in allActivities {
            let activityDay = calendar.startOfDay(for: activity.startDate)
            let dayOffset = calendar.dateComponents([.day], from: activityDay, to: today).day ?? 0
            
            // Include last 30 days for Activities page sparkline
            if dayOffset >= 0 && dayOffset <= 29 {
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
                
                // Use duration if available, otherwise use a fixed height for Intervals activities
                let duration: Double = {
                    if let dur = activity.duration, dur > 0 {
                        return dur / 60.0 // Convert seconds to minutes
                    } else if activity.intervalsActivity != nil {
                        // For Intervals activities without duration, use fixed height
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
        for dayOffset in (-29)...0 {
            let activities = dailyMap[dayOffset] ?? []
            dailyActivities.append(DailyActivityData(dayOffset: dayOffset, activities: activities))
        }
        
        return dailyActivities
    }
    
    @ViewBuilder
    private func activityDestination(for activity: UnifiedActivity) -> some View {
        switch activity.source {
        case .intervalsICU:
            if let intervalsActivity = activity.intervalsActivity {
                RideDetailSheet(activity: intervalsActivity)
            }
        case .strava:
            if let stravaActivity = activity.stravaActivity {
                // TODO: Create StravaActivityDetailView
                RideDetailSheet(activity: ActivityConverter.stravaToIntervals(stravaActivity))
            }
        case .appleHealth:
            if let healthWorkout = activity.healthKitWorkout {
                WalkingDetailView(workout: healthWorkout)
            }
        }
    }
    
    // Conversion now handled by unified ActivityConverter utility
}


// MARK: - View Model

@MainActor
class ActivitiesViewModel: ObservableObject {
    @Published var groupedActivities: [String: [UnifiedActivity]] = [:]
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasLoadedExtended = false
    @Published var error: String?
    @Published var selectedFilters: Set<UnifiedActivity.ActivityType> = []
    
    var allActivities: [UnifiedActivity] = []
    private var proConfig = ProFeatureConfig.shared
    private var hasLoadedInitialData = false
    
    var sortedMonthKeys: [String] {
        // Sort month keys chronologically (newest first)
        groupedActivities.keys.sorted { month1, month2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            
            guard let date1 = formatter.date(from: month1),
                  let date2 = formatter.date(from: month2) else {
                return month1 > month2 // Fallback to string comparison
            }
            
            return date1 > date2 // Newest first
        }
    }
    
    func loadActivitiesIfNeeded(apiClient: IntervalsAPIClient) async {
        // Only load if we haven't loaded before
        guard !hasLoadedInitialData else {
            Logger.debug("ℹ️ Activities already loaded, skipping")
            return
        }
        await loadActivities(apiClient: apiClient)
    }
    
    /// Force refresh activities (e.g., after Strava auth)
    func forceRefresh(apiClient: IntervalsAPIClient) async {
        Logger.debug("🔄 Force refreshing activities (e.g., after Strava auth)")
        hasLoadedInitialData = false // Reset flag to force reload
        await loadActivities(apiClient: apiClient)
    }
    
    func loadActivities(apiClient: IntervalsAPIClient) async {
        // Prevent concurrent loads
        guard !isLoading else {
            Logger.warning("️ Activities already loading, skipping duplicate request")
            return
        }
        
        isLoading = true
        error = nil
        hasLoadedExtended = false
        hasLoadedInitialData = true
        
        // FREE: 30 days, PRO: 30 days initially (can load 60 more)
        let daysBack = 30
        
        Logger.data("Loading activities: \(daysBack) days (PRO: \(proConfig.hasProAccess))")
        
        // Try to fetch activities from Intervals.icu (optional)
        var intervalsActivities: [IntervalsActivity] = []
        do {
            intervalsActivities = try await apiClient.fetchRecentActivities(limit: 200, daysBack: daysBack)
            Logger.debug("✅ Loaded \(intervalsActivities.count) activities from Intervals.icu")
        } catch {
            Logger.warning("️ Intervals.icu not available: \(error.localizedDescription)")
            Logger.debug("📱 Continuing with HealthKit-only mode")
        }
        
        // Fetch Strava activities using shared service
        await StravaDataService.shared.fetchActivitiesIfNeeded()
        let stravaActivities = StravaDataService.shared.activities
        
        // Always fetch Apple Health workouts (this is our primary source now)
        let healthWorkouts = await HealthKitManager.shared.fetchRecentWorkouts(limit: 200, daysBack: daysBack)
        Logger.debug("✅ Loaded \(healthWorkouts.count) workouts from Apple Health")
        
        // Convert to unified format and filter Strava-sourced activities from Intervals
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
        
        let stravaUnified = stravaActivities.map { UnifiedActivity(from: $0) }
        let healthUnified = healthWorkouts.map { UnifiedActivity(from: $0) }
        
        Logger.debug("🔍 Filtered Intervals activities: \(intervalsActivities.count) total → \(intervalsUnified.count) native (removed \(stravaFilteredCount) Strava)")
        
        // Deduplicate activities across all sources
        let deduplicationService = ActivityDeduplicationService.shared
        let deduplicated = deduplicationService.deduplicateActivities(
            intervalsActivities: intervalsUnified,
            stravaActivities: stravaUnified,
            appleHealthActivities: healthUnified
        )
        
        // Sort by date (newest first)
        let unifiedActivities = deduplicated.sorted { $0.startDate > $1.startDate }
        
        // Store all activities
        allActivities = unifiedActivities
        
        // Apply filters and group
        applyFilters()
        
        Logger.data("Total unified activities: \(allActivities.count)")
        
        isLoading = false
    }
    
    func loadExtendedActivities(apiClient: IntervalsAPIClient) async {
        guard proConfig.hasProAccess else { return }
        
        isLoadingMore = true
        
        do {
            Logger.data("Loading extended activities: 31-90 days")
            
            // Fetch activities from Intervals.icu if authenticated
            var intervalsActivities: [IntervalsActivity] = []
            if IntervalsOAuthManager.shared.isAuthenticated {
                intervalsActivities = (try? await apiClient.fetchRecentActivities(limit: 200, daysBack: 90)) ?? []
                Logger.debug("✅ Loaded \(intervalsActivities.count) extended Intervals activities")
            }
            
            // Fetch Strava activities (if connected)
            var stravaActivities: [StravaActivity] = []
            let stravaAuthService = StravaAuthService.shared
            if case .connected = stravaAuthService.connectionState {
                let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())
                stravaActivities = (try? await StravaAPIClient.shared.fetchActivities(
                    page: 1,
                    perPage: 200,
                    after: ninetyDaysAgo
                )) ?? []
                Logger.debug("✅ Loaded \(stravaActivities.count) extended Strava activities")
            }
            
            let healthWorkouts = await HealthKitManager.shared.fetchRecentWorkouts(limit: 200, daysBack: 90)
            
            // Filter to only activities from day 31-90 (exclude first 30 days already loaded)
            let calendar = Calendar.current
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
            
            // Filter Intervals activities (only older than 30 days, exclude Strava-sourced)
            var intervalsUnified: [UnifiedActivity] = []
            var stravaFilteredCount = 0
            
            for activity in intervalsActivities {
                if activity.startDateLocal < thirtyDaysAgo.ISO8601Format() {
                    // Skip Strava-sourced activities
                    if let source = activity.source, source.uppercased() == "STRAVA" {
                        stravaFilteredCount += 1
                        continue
                    }
                    intervalsUnified.append(UnifiedActivity(from: activity))
                }
            }
            
            // Filter Strava activities (only older than 30 days)
            let stravaUnified = stravaActivities
                .filter { $0.start_date_local < thirtyDaysAgo.ISO8601Format() }
                .map { UnifiedActivity(from: $0) }
            
            // Filter Health workouts (only older than 30 days)
            let healthUnified = healthWorkouts
                .filter { $0.startDate < thirtyDaysAgo }
                .map { UnifiedActivity(from: $0) }
            
            Logger.debug("🔍 Extended activities (31-90 days): Intervals=\(intervalsUnified.count), Strava=\(stravaUnified.count), Health=\(healthUnified.count) (filtered \(stravaFilteredCount) Strava from Intervals)")
            
            // Deduplicate extended activities
            let deduplicationService = ActivityDeduplicationService.shared
            let deduplicated = deduplicationService.deduplicateActivities(
                intervalsActivities: intervalsUnified,
                stravaActivities: stravaUnified,
                appleHealthActivities: healthUnified
            )
            
            // Append to existing activities
            allActivities.append(contentsOf: deduplicated)
            
            // Sort by date (newest first)
            allActivities.sort { $0.startDate > $1.startDate }
            
            // Apply filters and group
            applyFilters()
            
            hasLoadedExtended = true
            isLoadingMore = false
            
            Logger.data("Loaded \(deduplicated.count) extended activities")
        } catch {
            self.error = error.localizedDescription
            isLoadingMore = false
            Logger.error("Error loading extended activities: \(error)")
        }
    }
    
    func applyFilters() {
        let filtered = selectedFilters.isEmpty ? allActivities : allActivities.filter { selectedFilters.contains($0.type) }
        
        groupedActivities = Dictionary(grouping: filtered) { activity in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: activity.startDate)
        }
    }
}

// MARK: - Filter Sheet

struct ActivityFilterSheet: View {
    @ObservedObject var viewModel: ActivitiesViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Dynamically show only activity types that exist in the loaded activities
    var availableTypes: [UnifiedActivity.ActivityType] {
        let types = Set(viewModel.allActivities.map { $0.type })
        return Array(types).sorted { $0.rawValue < $1.rawValue }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableTypes, id: \.self) { type in
                    Button(action: {
                        if viewModel.selectedFilters.contains(type) {
                            viewModel.selectedFilters.remove(type)
                        } else {
                            viewModel.selectedFilters.insert(type)
                        }
                        viewModel.applyFilters()
                    }) {
                        HStack {
                            Text(type.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if viewModel.selectedFilters.contains(type) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.button.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Activities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        viewModel.selectedFilters.removeAll()
                        viewModel.applyFilters()
                    }
                    .disabled(viewModel.selectedFilters.isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

