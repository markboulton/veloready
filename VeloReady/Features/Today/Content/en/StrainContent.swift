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
    enum Bands {
        static let low = "Low"  /// Low load (0-39)
        static let moderate = "Moderate"  /// Moderate load (40-59)
        static let high = "High"  /// High load (60-79)
        static let extreme = "Extreme"  /// Extreme load (80-100)
    }
    
    // MARK: - Band Descriptions
    enum BandDescriptions {
        static let low = "Light Day"  /// Low description
        static let moderate = "Moderate Training"  /// Moderate description
        static let high = "Hard Training"  /// High description
        static let extreme = "Very Hard Training"  /// Extreme description
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
