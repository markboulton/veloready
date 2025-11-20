import Foundation
import SwiftUI
import Combine

/// Unified state container for Trends view (Phase 1 Refactor)
/// Single source of truth for trends state management
/// Follows the pattern established in TodayViewState and ActivitiesViewState
@MainActor
final class TrendsViewState: ObservableObject {
    static let shared = TrendsViewState()

    // MARK: - Loading Phase

    enum LoadingPhase: Equatable {
        case notStarted
        case loading(progress: Double)  // 0.0 - 1.0
        case complete
        case error(Error)
        case refreshing

        var isLoading: Bool {
            switch self {
            case .loading, .refreshing:
                return true
            default:
                return false
            }
        }

        var description: String {
            switch self {
            case .notStarted: return "notStarted"
            case .loading(let progress): return "loading(\(Int(progress * 100))%)"
            case .complete: return "complete"
            case .error(let error): return "error(\(error.localizedDescription))"
            case .refreshing: return "refreshing"
            }
        }

        // Equatable conformance
        static func == (lhs: LoadingPhase, rhs: LoadingPhase) -> Bool {
            switch (lhs, rhs) {
            case (.notStarted, .notStarted),
                 (.complete, .complete),
                 (.refreshing, .refreshing):
                return true
            case (.loading(let p1), .loading(let p2)):
                return p1 == p2
            case (.error, .error):
                // Consider all error states as equal (error details not compared)
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Time Range

    enum TimeRange: String, CaseIterable {
        case days30 = "30 Days"
        case days60 = "60 Days"
        case days90 = "90 Days"
        case days180 = "6 Months"
        case days365 = "1 Year"

        var days: Int {
            switch self {
            case .days30: return 30
            case .days60: return 60
            case .days90: return 90
            case .days180: return 180
            case .days365: return 365
            }
        }

        var startDate: Date {
            Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        }
    }

    // MARK: - Published State (6 properties instead of 21)

    @Published var phase: LoadingPhase = .notStarted
    @Published var selectedTimeRange: TimeRange = .days90
    @Published var lastUpdated: Date?

    @Published var scoresData: TrendsDataLoader.TrendsScoresData?
    @Published var fitnessData: TrendsDataLoader.TrendsFitnessData?
    @Published var analyticsData: TrendsDataLoader.TrendsAnalyticsData?

    // MARK: - Dependencies

    private let loader: TrendsDataLoader
    private var cancellables = Set<AnyCancellable>()

    // Notification observer
    private var backfillObserver: NSObjectProtocol?

    private init() {
        self.loader = TrendsDataLoader()

        // Setup notification observer for backfill completion
        setupBackfillObserver()

        Logger.debug("📊 [TrendsViewState] Initialized with backfill observer")
    }

    deinit {
        if let observer = backfillObserver {
            NotificationCenter.default.removeObserver(observer)
            Logger.debug("📊 [TrendsViewState] Removed backfill observer")
        }
    }

    // MARK: - Public API

    /// Load trend data (cache-first strategy)
    func load() async {
        Logger.info("📊 [TrendsViewState] Starting load...")
        phase = .loading(progress: 0)

        // 1. Load cached data first (instant)
        if let cached = await loader.loadCachedTrends(timeRange: selectedTimeRange) {
            Logger.debug("📊 [TrendsViewState] Loaded cached data")
            scoresData = cached.scores
            fitnessData = cached.fitness
            analyticsData = cached.analytics
        }

        // 2. Load fresh data
        do {
            phase = .loading(progress: 0.3)
            let fresh = try await loader.loadFreshTrends(timeRange: selectedTimeRange)

            phase = .loading(progress: 0.9)
            scoresData = fresh.scores
            fitnessData = fresh.fitness
            analyticsData = fresh.analytics

            phase = .complete
            lastUpdated = Date()

            Logger.info("📊 [TrendsViewState] Load complete")
        } catch {
            Logger.error("❌ [TrendsViewState] Load failed: \(error)")
            phase = .error(error)
        }
    }

    /// Refresh trend data (force reload)
    func refresh() async {
        Logger.info("📊 [TrendsViewState] Refreshing...")
        phase = .refreshing

        do {
            let fresh = try await loader.loadFreshTrends(timeRange: selectedTimeRange)

            scoresData = fresh.scores
            fitnessData = fresh.fitness
            analyticsData = fresh.analytics

            phase = .complete
            lastUpdated = Date()

            Logger.info("📊 [TrendsViewState] Refresh complete")
        } catch {
            Logger.error("❌ [TrendsViewState] Refresh failed: \(error)")
            phase = .error(error)
        }
    }

    /// Change time range and reload
    func changeTimeRange(_ newRange: TimeRange) async {
        Logger.info("📊 [TrendsViewState] Changing time range to \(newRange.rawValue)")
        selectedTimeRange = newRange
        await load()
    }

    // MARK: - Notification Observer

    private func setupBackfillObserver() {
        backfillObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("BackfillComplete"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Logger.info("📢 [TrendsViewState] Received BackfillComplete notification - reloading")
            Task { @MainActor in
                await self?.load()
            }
        }
    }
}
