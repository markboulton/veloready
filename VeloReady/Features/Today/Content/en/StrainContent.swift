import Foundation

/// Content strings for Load feature
enum LoadContent {
    // MARK: - Navigation
    static let title = "Load Analysis"  /// Navigation title
    
    // MARK: - Sections
    static let breakdownTitle = "Load Breakdown"  /// Breakdown section title
    static let componentsTitle = "Load Components"  /// Components section title
    static let activitiesTitle = "Activities"  /// Activities section title
    static let modulationTitle = "Recovery Modulation"  /// Modulation section title
    static let recommendationsTitle = "Recommendations"  /// Recommendations section title
    static let trendTitle = "Load Trend"  /// Trend chart title (period shown in selector)
    
    // MARK: - Bands
    /// Use centralized scoring terminology from ScoringContent
    /// Note: Load bands are inverted (low load = optimal, high load = pay attention)
    enum Bands {
        static let optimal = ScoringContent.Bands.optimal  /// Optimal (low) load (0-39)
        static let good = ScoringContent.Bands.good  /// Good (moderate) load (40-59)
        static let fair = ScoringContent.Bands.fair  /// Fair (high) load (60-79)
        static let payAttention = ScoringContent.Bands.payAttention  /// Pay attention (extreme) load (80-100)
    }
    
    // MARK: - Band Descriptions
    /// Use centralized load descriptions from ScoringContent
    enum BandDescriptions {
        static let optimal = ScoringContent.LoadDescriptions.optimal  /// Optimal description
        static let good = ScoringContent.LoadDescriptions.good  /// Good description
        static let fair = ScoringContent.LoadDescriptions.fair  /// Fair description
        static let payAttention = ScoringContent.LoadDescriptions.payAttention  /// Pay attention description
    }
    
    // MARK: - Components
    enum Components {
        static let tss = "TSS"  /// Training Stress Score
        static let trimp = "TRIMP"  /// Training Impulse
        static let duration = "Duration"  /// Duration component
        static let intensity = "Intensity"  /// Intensity component
    }
    
    // MARK: - Component Weights
    enum Weights {
        static let tss = "40%"  /// TSS weight
        static let trimp = "30%"  /// TRIMP weight
        static let duration = "20%"  /// Duration weight
        static let intensity = "10%"  /// Intensity weight
    }
    
    // MARK: - Metrics
    enum Metrics {
        static let totalTSS = "Total TSS"  /// Total TSS label
        static let totalTRIMP = "Total TRIMP"  /// Total TRIMP label
        static let totalDuration = "Total Duration"  /// Total duration label
        static let avgIntensity = "Avg Intensity"  /// Average intensity label
        static let ctl = "CTL"  /// Chronic Training Load
        static let atl = "ATL"  /// Acute Training Load
        static let tsb = "TSB"  /// Training Stress Balance
    }
    
    // MARK: - Activity Types
    enum ActivityTypes {
        static let cycling = "Cycling"  /// Cycling activity
        static let running = "Running"  /// Running activity
        static let walking = "Walking"  /// Walking activity
        static let strength = "Strength"  /// Strength training
        static let other = "Other"  /// Other activity
    }
    
    // MARK: - Recommendations
    enum Recommendations {
        static let lowLoad = "Consider increasing training load for adaptation"  /// Low load recommendation
        static let moderateLoad = "Good training load. Maintain consistency."  /// Moderate load recommendation
        static let highLoad = "High training load. Ensure adequate recovery."  /// High load recommendation
        static let extremeLoad = "Very high load. Recovery day recommended tomorrow."  /// Extreme load recommendation
    }
    
    // MARK: - Pro Features
    static let weeklyTrendFeature = "Weekly Load Trend"  /// Pro feature name
    static let weeklyTrendDescription = "Track your training load over the past 7 days"  /// Pro feature description
}
