import Foundation

/// Content strings for AI Ride Summary
enum RideSummaryContent {
    // MARK: - Header
    static let title = "Ride Summary"  /// Panel title
    static let proBadge = "PRO"  /// PRO badge text
    
    // MARK: - Execution Score
    enum ExecutionScore {
        static let title = "Execution Score"  /// Execution score title
        static let subtitle = "Pacing, power & effort"  /// Execution score subtitle
        static let excellent = "Excellent"  /// Excellent rating
        static let good = "Good"  /// Good rating
        static let fair = "Fair"  /// Fair rating
        static let needsWork = "Needs Work"  /// Needs work rating
    }
    
    // MARK: - Sections
    static let strengths = "Strengths"  /// Strengths section title
    static let areasToImprove = "Areas to Improve"  /// Limiters section title
    static let nextSteps = "Next Steps"  /// Next steps section title
    
    // MARK: - States
    static let loading = "Generating AI insights..."  /// Loading message
    static let error = "Failed to generate summary"  /// Error message
    static let retry = "Retry"  /// Retry button
    
    // MARK: - Empty State
    static let noSummary = "No summary available"  /// No summary message
}
