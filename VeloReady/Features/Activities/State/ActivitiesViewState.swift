import SwiftUI
import Combine

/// Unified state container for Activities view (Phase 1 - Activities Refactor)
/// Single source of truth for activities list state management
@MainActor
final class ActivitiesViewState: ObservableObject {
    static let shared = ActivitiesViewState()

    // MARK: - Loading Phase

    enum LoadingPhase: Equatable {
        case notStarted
        case loading               // Initial load in progress
        case loadingMore           // Loading extended activities (31-90 days)
        case complete
        case error(Error)
        case refreshing            // Pull-to-refresh in progress

        var isLoading: Bool {
            switch self {
            case .loading, .loadingMore, .refreshing:
                return true
            default:
                return false
            }
        }

        var description: String {
            switch self {
            case .notStarted: return "notStarted"
            case .loading: return "loading"
            case .loadingMore: return "loadingMore"
            case .complete: return "complete"
            case .error(let error): return "error(\(error.localizedDescription))"
            case .refreshing: return "refreshing"
            }
        }

        // Equatable conformance
        static func == (lhs: LoadingPhase, rhs: LoadingPhase) -> Bool {
            switch (lhs, rhs) {
            case (.notStarted, .notStarted),
                 (.loading, .loading),
                 (.loadingMore, .loadingMore),
                 (.complete, .complete),
                 (.refreshing, .refreshing):
                return true
            case (.error, .error):
                // Consider all error states as equal
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Lifecycle Events

    /// Lifecycle events that can occur in Activities view
    enum LifecycleEvent: CustomStringConvertible {
        case viewAppeared
        case pullToRefresh
        case loadExtended          // Pro user loads 31-90 days
        case stravaAuthChanged     // Strava connection changed
        case intervalsAuthChanged  // Intervals.icu auth changed

        var description: String {
            switch self {
            case .viewAppeared: return "viewAppeared"
            case .pullToRefresh: return "pullToRefresh"
            case .loadExtended: return "loadExtended"
            case .stravaAuthChanged: return "stravaAuthChanged"
            case .intervalsAuthChanged: return "intervalsAuthChanged"
            }
        }
    }

    // MARK: - Published State

    @Published var phase: LoadingPhase = .notStarted
    @Published var lastUpdated: Date?

    // MARK: - Activities State

    @Published var allActivities: [UnifiedActivity] = []
    @Published var displayedActivities: [UnifiedActivity] = []
    @Published var selectedFilters: Set<UnifiedActivity.ActivityType> = []

    // MARK: - Grouping State

    @Published var groupedActivities: [String: [UnifiedActivity]] = [:]

    // MARK: - Loading State

    @Published var hasLoadedExtended: Bool = false
    @Published var hasMoreToLoad: Bool = true
    @Published var daysLoaded: Int = 0

    // MARK: - Progressive Loading State

    private var currentBatchIndex: Int = 0
    private let batchSize: Int = 10
    var canLoadMoreBatches: Bool {
        displayedActivities.count < filteredActivities.count
    }

    // MARK: - Error State

    @Published var errorMessage: String?

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()
    private let loader: ActivitiesDataLoader
    private let proConfig: ProFeatureConfig

    // Lifecycle tracking
    private var hasLoadedOnce = false

    // MARK: - Initialization

    private init() {
        self.loader = ActivitiesDataLoader()
        self.proConfig = .shared
    }

    // MARK: - Public API

    /// Load activities (initial 30 days)
    func load() async {
        // Prevent duplicate loads
        guard !hasLoadedOnce else {
            Logger.debug("ℹ️ [ActivitiesViewState] Already loaded, skipping")
            return
        }

        Logger.info("📦 [ActivitiesViewState] Starting load (30 days)...")
        phase = .loading
        errorMessage = nil

        do {
            let data = try await loader.loadInitialActivities()

            // Update state
            allActivities = data.activities
            daysLoaded = data.daysLoaded
            hasMoreToLoad = data.hasMore

            // Apply filters and progressive loading
            applyFilters()

            phase = .complete
            lastUpdated = Date()
            hasLoadedOnce = true

            Logger.info("✅ [ActivitiesViewState] Loaded \(allActivities.count) activities")

        } catch {
            Logger.error("❌ [ActivitiesViewState] Load failed: \(error)")
            phase = .error(error)
            errorMessage = error.localizedDescription
        }
    }

    /// Load extended activities (31-90 days) for Pro users
    func loadExtended() async {
        guard !hasLoadedExtended else {
            Logger.debug("ℹ️ [ActivitiesViewState] Extended already loaded, skipping")
            return
        }

        guard proConfig.hasProAccess else {
            Logger.warning("⚠️ [ActivitiesViewState] Extended load requires Pro")
            return
        }

        Logger.info("📦 [ActivitiesViewState] Loading extended activities (31-90 days)...")
        phase = .loadingMore
        errorMessage = nil

        do {
            let data = try await loader.loadExtendedActivities(existingActivities: allActivities)

            // Update state
            allActivities = data.activities
            daysLoaded = data.daysLoaded
            hasMoreToLoad = data.hasMore
            hasLoadedExtended = true

            // Apply filters and progressive loading
            applyFilters()

            phase = .complete
            lastUpdated = Date()

            Logger.info("✅ [ActivitiesViewState] Total: \(allActivities.count) activities (0-90 days)")

        } catch {
            Logger.error("❌ [ActivitiesViewState] Extended load failed: \(error)")
            phase = .error(error)
            errorMessage = error.localizedDescription
        }
    }

    /// Force refresh activities (ignores cache)
    func forceRefresh() async {
        Logger.info("🔄 [ActivitiesViewState] Force refreshing...")
        phase = .refreshing
        errorMessage = nil
        hasLoadedOnce = false // Reset to allow reload
        hasLoadedExtended = false

        do {
            let data = try await loader.forceRefreshActivities()

            // Update state
            allActivities = data.activities
            daysLoaded = data.daysLoaded
            hasMoreToLoad = data.hasMore

            // Apply filters and progressive loading
            applyFilters()

            phase = .complete
            lastUpdated = Date()
            hasLoadedOnce = true

            Logger.info("✅ [ActivitiesViewState] Force refreshed \(allActivities.count) activities")

        } catch {
            Logger.error("❌ [ActivitiesViewState] Force refresh failed: \(error)")
            phase = .error(error)
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Filtering

    /// Apply activity type filters
    func applyFilters() {
        Logger.debug("📊 [ActivitiesViewState] Applying filters: \(selectedFilters.map { $0.rawValue })")

        let filtered = loader.filterActivities(allActivities, by: selectedFilters)

        // Reset progressive loading
        currentBatchIndex = 0

        // Load initial batch
        let initialBatch = loader.applyProgressiveLoading(filtered, batchSize: batchSize)
        displayedActivities = initialBatch
        currentBatchIndex = 1

        // Update grouping
        updateGrouping()

        Logger.debug("📊 [ActivitiesViewState] Showing \(displayedActivities.count)/\(filtered.count) activities")
    }

    /// Toggle filter for activity type
    func toggleFilter(_ type: UnifiedActivity.ActivityType) {
        if selectedFilters.contains(type) {
            selectedFilters.remove(type)
        } else {
            selectedFilters.insert(type)
        }
        applyFilters()
    }

    /// Clear all filters
    func clearFilters() {
        selectedFilters.removeAll()
        applyFilters()
    }

    // MARK: - Progressive Loading

    /// Load next batch of activities (progressive loading)
    func loadMoreActivitiesIfNeeded() {
        guard canLoadMoreBatches else {
            Logger.debug("📊 [ActivitiesViewState] No more batches to load")
            return
        }

        let filtered = filteredActivities
        let nextBatch = loader.getNextBatch(
            from: filtered,
            currentCount: displayedActivities.count,
            batchSize: batchSize
        )

        displayedActivities.append(contentsOf: nextBatch)
        currentBatchIndex += 1

        // Update grouping
        updateGrouping()

        Logger.debug("📊 [ActivitiesViewState] Loaded batch \(currentBatchIndex) - now showing \(displayedActivities.count)/\(filtered.count)")
    }

    // MARK: - Grouping

    /// Update grouped activities for display
    private func updateGrouping() {
        groupedActivities = loader.groupActivitiesByMonth(displayedActivities)
    }

    /// Get sorted month keys (newest first)
    var sortedMonthKeys: [String] {
        loader.sortedMonthKeys(groupedActivities)
    }

    /// Grouped activities for display (sorted by month)
    var displayedGroupedActivities: [(key: String, value: [UnifiedActivity])] {
        let sorted = sortedMonthKeys
        return sorted.compactMap { key in
            guard let activities = groupedActivities[key] else { return nil }
            return (key: key, value: activities)
        }
    }

    // MARK: - Computed Properties

    /// Get filtered activities (respecting selected filters)
    private var filteredActivities: [UnifiedActivity] {
        loader.filterActivities(allActivities, by: selectedFilters)
    }

    /// Available activity types in loaded activities
    var availableActivityTypes: [UnifiedActivity.ActivityType] {
        let types = Set(allActivities.map { $0.type })
        return Array(types).sorted { $0.rawValue < $1.rawValue }
    }

    // MARK: - Lifecycle Event Handling

    /// Handle lifecycle events (state machine)
    func handle(_ event: LifecycleEvent) async {
        Logger.info("🔄 [ActivitiesViewState] Handling event: \(event) (current phase: \(phase.description))")

        switch event {
        case .viewAppeared:
            // Load activities if not already loaded
            if !hasLoadedOnce {
                await load()
            }

        case .pullToRefresh:
            // Force refresh activities
            await forceRefresh()

        case .loadExtended:
            // Load extended activities (31-90 days)
            await loadExtended()

        case .stravaAuthChanged, .intervalsAuthChanged:
            // Auth changed - force refresh to get new data
            await forceRefresh()
        }
    }
}
