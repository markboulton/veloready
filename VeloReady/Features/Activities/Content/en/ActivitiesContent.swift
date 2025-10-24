import Foundation

/// Content strings for the Activities view
enum ActivitiesContent {
    // MARK: - Navigation
    static let title = "Activities"
    static let filterButton = "Filter"
    
    // MARK: - Empty States
    static let noActivities = "No Activities"
    static let noActivitiesMessage = "Your activities from the last 60 days will appear here."
    static let refreshButton = "Refresh"
    
    // MARK: - Section Headers
    static let recentActivities = "Recent Activities"
    static let activitiesByMonth = "Activities by Month"
    
    /// Format a date as a month/year section header (e.g., "October 2024")
    static func monthYearHeader(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    // MARK: - Loading
    static let loadingActivities = "Loading activities..."
    
    // MARK: - Errors
    static let errorTitle = "Error Loading Activities"
    static let retryButton = "Retry"
    
    // MARK: - Load More
    static let loadMore60Days = "Load More Activities (60 days)"  /// Load more button for 60 days
    
    // MARK: - Pro Features
    enum Pro {
        static let upgradeTitle = "Upgrade to Pro for More Activities"  /// Pro upgrade title
        static let upgradeDescription = "Access up to 90 days of activity history with PRO"  /// Pro upgrade description
        static let upgradeButton = "Upgrade Now"  /// Upgrade button
    }
    
    // MARK: - Filter
    enum Filter {
        static let navigationTitle = "Filter Activities"  /// Filter navigation title
        static let clearAll = "Clear All"  /// Clear all button
        static let done = "Done"  /// Done button
    }
}

