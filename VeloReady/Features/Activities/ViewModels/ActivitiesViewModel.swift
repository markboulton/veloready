import SwiftUI

// MARK: - View Model

@MainActor
class ActivitiesViewModel: ObservableObject {
    static let shared = ActivitiesViewModel()
    
    @Published var groupedActivities: [String: [UnifiedActivity]] = [:]
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasLoadedExtended = false
    @Published var error: String?
    @Published var selectedFilters: Set<UnifiedActivity.ActivityType> = []
    @Published var displayedActivities: [UnifiedActivity] = []
    
    // Pagination properties
    @Published var currentPage: Int = 0
    private let pageSize: Int = 15
    @Published private(set) var isLoadingPage: Bool = false
    
    var allActivities: [UnifiedActivity] = []
    private var proConfig = ProFeatureConfig.shared
    private var hasLoadedInitialData = false
    private let batchSize = 10 // Progressive loading: show 10 activities at a time
    private var currentBatchIndex = 0
    
    private init() {} // Private init for singleton
    
    /// Paginated activities based on current page
    var paginatedActivities: [UnifiedActivity] {
        let filteredActivities = selectedFilters.isEmpty ? allActivities : allActivities.filter { selectedFilters.contains($0.type) }
        let endIndex = min((currentPage + 1) * pageSize, filteredActivities.count)
        return Array(filteredActivities.prefix(endIndex))
    }
    
    /// Check if more pages are available
    var hasMorePages: Bool {
        let filteredActivities = selectedFilters.isEmpty ? allActivities : allActivities.filter { selectedFilters.contains($0.type) }
        return paginatedActivities.count < filteredActivities.count
    }
    
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
    
    /// Grouped activities from displayedActivities (respects progressive loading)
    var displayedGroupedActivities: [(key: String, value: [UnifiedActivity])] {
        // Group displayed activities by month
        let grouped = Dictionary(grouping: displayedActivities) { activity in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: activity.startDate)
        }
        
        // Sort by month (newest first)
        return grouped.sorted { month1, month2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            
            guard let date1 = formatter.date(from: month1.key),
                  let date2 = formatter.date(from: month2.key) else {
                return month1.key > month2.key
            }
            
            return date1 > date2
        }
    }
    
    func loadActivitiesIfNeeded(apiClient: IntervalsAPIClient) async {
        // Only load if we haven't loaded before
        guard !hasLoadedInitialData else {
            Logger.debug("ℹ️ [Activities] Already loaded, skipping")
            return
        }
        await loadActivities(apiClient: apiClient)
    }
    
    /// Force refresh activities (e.g., after Strava auth)
    func forceRefresh(apiClient: IntervalsAPIClient) async {
        Logger.debug("🔄 [Activities] Force refreshing activities (e.g., after Strava auth)")
        hasLoadedInitialData = false // Reset flag to force reload
        await loadActivities(apiClient: apiClient)
    }
    
    func loadActivities(apiClient: IntervalsAPIClient) async {
        // Prevent concurrent loads
        guard !isLoading else {
            Logger.warning("⚠️ [Activities] Already loading, skipping duplicate request")
            return
        }
        
        isLoading = true
        error = nil
        hasLoadedExtended = false
        hasLoadedInitialData = true
        
        // OPTIMIZATION: Reduce initial fetch from 200 → 50 for faster startup
        // FREE: 30 days, PRO: 30 days initially (can load 60 more)
        let daysBack = 30
        let initialFetchLimit = 50 // Reduced from 200 for faster initial load

        Logger.debug("📊 [Activities] Loading activities: \(daysBack) days, limit: \(initialFetchLimit) (PRO: \(proConfig.hasProAccess))")

        // Try to fetch activities from Intervals.icu (optional)
        var intervalsActivities: [Activity] = []
        do {
            intervalsActivities = try await apiClient.fetchRecentActivities(limit: initialFetchLimit, daysBack: daysBack)
            Logger.debug("✅ [Activities] Loaded \(intervalsActivities.count) activities from Intervals.icu")
        } catch {
            Logger.warning("⚠️ [Activities] Intervals.icu not available: \(error.localizedDescription)")
            Logger.debug("📱 [Activities] Continuing with HealthKit-only mode")
        }

        // Fetch Strava activities using shared service
        await StravaDataService.shared.fetchActivitiesIfNeeded()
        let stravaActivities = StravaDataService.shared.activities

        // Always fetch Apple Health workouts
        let healthWorkouts = await HealthKitManager.shared.fetchRecentWorkouts(limit: initialFetchLimit, daysBack: daysBack)
        Logger.debug("✅ [Activities] Loaded \(healthWorkouts.count) workouts from Apple Health")
        
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
        
        Logger.debug("🔍 [Activities] Filtered Intervals activities: \(intervalsActivities.count) total → \(intervalsUnified.count) native (removed \(stravaFilteredCount) Strava)")
        
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
        
        Logger.debug("📊 [Activities] Total unified activities: \(allActivities.count)")
        
        isLoading = false
    }
    
    func loadExtendedActivities(apiClient: IntervalsAPIClient) async {
        guard proConfig.hasProAccess else { return }

        isLoadingMore = true

        // OPTIMIZATION: Use consistent fetch limit (50 for extended data)
        let extendedFetchLimit = 50
        Logger.debug("📊 [Activities] Loading extended activities: 31-90 days, limit: \(extendedFetchLimit)")

        // Fetch activities from Intervals.icu if authenticated
        var intervalsActivities: [Activity] = []
        if IntervalsOAuthManager.shared.isAuthenticated {
            intervalsActivities = (try? await apiClient.fetchRecentActivities(limit: extendedFetchLimit, daysBack: 90)) ?? []
            Logger.debug("✅ [Activities] Loaded \(intervalsActivities.count) extended Intervals activities")
        }

        // Fetch Strava activities (if connected)
        var stravaActivities: [StravaActivity] = []
        let stravaAuthService = StravaAuthService.shared
        if case .connected = stravaAuthService.connectionState {
            let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())
            stravaActivities = (try? await StravaAPIClient.shared.fetchActivities(
                page: 1,
                perPage: extendedFetchLimit,
                after: ninetyDaysAgo
            )) ?? []
            Logger.debug("✅ [Activities] Loaded \(stravaActivities.count) extended Strava activities")
        }

        let healthWorkouts = await HealthKitManager.shared.fetchRecentWorkouts(limit: extendedFetchLimit, daysBack: 90)

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

        Logger.debug("🔍 [Activities] Extended activities (31-90 days): Intervals=\(intervalsUnified.count), Strava=\(stravaUnified.count), Health=\(healthUnified.count) (filtered \(stravaFilteredCount) Strava from Intervals)")

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

        Logger.debug("📊 [Activities] Loaded \(deduplicated.count) extended activities")
    }
    
    func applyFilters() {
        let filtered = selectedFilters.isEmpty ? allActivities : allActivities.filter { selectedFilters.contains($0.type) }
        
        groupedActivities = Dictionary(grouping: filtered) { activity in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: activity.startDate)
        }
        
        // Reset progressive loading when filters change
        currentBatchIndex = 0
        loadInitialBatch()
        Logger.debug("📊 [Activities] Filters applied - showing \(displayedActivities.count)/\(filtered.count) activities")
    }
    
    // MARK: - Progressive Loading
    
    /// Check if there are more activities to load
    var hasMoreToLoad: Bool {
        let filteredActivities = selectedFilters.isEmpty ? allActivities : allActivities.filter { selectedFilters.contains($0.type) }
        return displayedActivities.count < filteredActivities.count
    }
    
    /// Load initial batch of activities
    private func loadInitialBatch() {
        let filteredActivities = selectedFilters.isEmpty ? allActivities : allActivities.filter { selectedFilters.contains($0.type) }
        let endIndex = min(batchSize, filteredActivities.count)
        displayedActivities = Array(filteredActivities.prefix(endIndex))
        currentBatchIndex = 1
        Logger.debug("📊 [Activities] Initial batch loaded - \(displayedActivities.count)/\(filteredActivities.count) activities")
    }
    
    /// Load more activities when user scrolls (progressive loading)
    func loadMoreActivitiesIfNeeded() {
        guard hasMoreToLoad else {
            Logger.debug("📊 [Activities] No more activities to load")
            return
        }
        
        let filteredActivities = selectedFilters.isEmpty ? allActivities : allActivities.filter { selectedFilters.contains($0.type) }
        let startIndex = currentBatchIndex * batchSize
        let endIndex = min(startIndex + batchSize, filteredActivities.count)
        
        guard startIndex < filteredActivities.count else { return }
        
        let newBatch = Array(filteredActivities[startIndex..<endIndex])
        displayedActivities.append(contentsOf: newBatch)
        currentBatchIndex += 1
        
        Logger.debug("📊 [Activities] Loaded batch \(currentBatchIndex) - now showing \(displayedActivities.count)/\(filteredActivities.count)")
    }
    
    /// Load next page of activities (pagination)
    func loadNextPage() {
        guard !isLoadingPage && hasMorePages else {
            Logger.debug("📊 [Activities] Cannot load next page - loading: \(isLoadingPage), hasMore: \(hasMorePages)")
            return
        }
        
        isLoadingPage = true
        currentPage += 1
        
        // Brief delay to show loading indicator
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            await MainActor.run {
                isLoadingPage = false
                Logger.debug("📊 [Activities] Loaded page \(currentPage) - now showing \(paginatedActivities.count) activities")
            }
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
                                Image(systemName: Icons.Status.checkmark)
                                    .foregroundColor(Color.button.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(ActivitiesContent.Filter.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(ActivitiesContent.Filter.clearAll) {
                        viewModel.selectedFilters.removeAll()
                        viewModel.applyFilters()
                    }
                    .disabled(viewModel.selectedFilters.isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(ActivitiesContent.Filter.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}
