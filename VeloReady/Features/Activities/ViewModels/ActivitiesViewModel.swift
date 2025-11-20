import SwiftUI
import Combine

// MARK: - View Model (Refactored - Thin Wrapper over ActivitiesViewState)

@MainActor
final class ActivitiesViewModel: ObservableObject {
    static let shared = ActivitiesViewModel()

    // Delegate to ActivitiesViewState for all state management
    @ObservedObject private var state = ActivitiesViewState.shared

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Forward state changes to trigger view updates
        state.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }

    // MARK: - Public Properties (Delegated to State)

    var groupedActivities: [String: [UnifiedActivity]] {
        state.groupedActivities
    }

    var isLoading: Bool {
        state.phase.isLoading
    }

    var isLoadingMore: Bool {
        state.phase == .loadingMore
    }

    var hasLoadedExtended: Bool {
        state.hasLoadedExtended
    }

    var error: String? {
        state.errorMessage
    }

    var selectedFilters: Set<UnifiedActivity.ActivityType> {
        get { state.selectedFilters }
        set { state.selectedFilters = newValue }
    }

    var displayedActivities: [UnifiedActivity] {
        state.displayedActivities
    }

    var allActivities: [UnifiedActivity] {
        state.allActivities
    }

    var sortedMonthKeys: [String] {
        state.sortedMonthKeys
    }

    var displayedGroupedActivities: [(key: String, value: [UnifiedActivity])] {
        state.displayedGroupedActivities
    }

    // MARK: - Progressive Loading

    var hasMoreToLoad: Bool {
        state.canLoadMoreBatches
    }

    func loadMoreActivitiesIfNeeded() {
        state.loadMoreActivitiesIfNeeded()
    }

    // MARK: - Public Methods (Delegated to State)

    /// Load activities if not already loaded
    /// - Parameter apiClient: No longer needed (kept for backward compatibility)
    func loadActivitiesIfNeeded(apiClient: IntervalsAPIClient) async {
        await state.handle(.viewAppeared)
    }

    /// Force refresh activities (e.g., after Strava auth)
    /// - Parameter apiClient: No longer needed (kept for backward compatibility)
    func forceRefresh(apiClient: IntervalsAPIClient) async {
        await state.handle(.pullToRefresh)
    }

    /// Load activities (delegates to state)
    /// - Parameter apiClient: No longer needed (kept for backward compatibility)
    func loadActivities(apiClient: IntervalsAPIClient) async {
        await state.load()
    }

    /// Load extended activities (31-90 days) for Pro users
    /// - Parameter apiClient: No longer needed (kept for backward compatibility)
    func loadExtendedActivities(apiClient: IntervalsAPIClient) async {
        await state.handle(.loadExtended)
    }

    /// Apply filters
    func applyFilters() {
        state.applyFilters()
    }

    /// Toggle filter for activity type
    func toggleFilter(_ type: UnifiedActivity.ActivityType) {
        state.toggleFilter(type)
    }

    /// Clear all filters
    func clearFilters() {
        state.clearFilters()
    }

    /// Available activity types
    var availableTypes: [UnifiedActivity.ActivityType] {
        state.availableActivityTypes
    }
}

// MARK: - Filter Sheet

struct ActivityFilterSheet: View {
    @ObservedObject var viewModel: ActivitiesViewModel
    @Environment(\.dismiss) private var dismiss

    // Dynamically show only activity types that exist in the loaded activities
    var availableTypes: [UnifiedActivity.ActivityType] {
        viewModel.availableTypes
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(availableTypes, id: \.self) { type in
                    Button(action: {
                        viewModel.toggleFilter(type)
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
                        viewModel.clearFilters()
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
