import Foundation

/// Content strings for Load feature
enum StrainContent {
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
    /// Use intensity-based terminology from ScoringContent for load scoring
    enum Bands {
        static let light = ScoringContent.LoadBands.light  /// Light (low) load (0-39)
        static let moderate = ScoringContent.LoadBands.moderate  /// Moderate load (40-59)
        static let hard = ScoringContent.LoadBands.hard  /// Hard (high) load (60-79)
        static let veryHard = ScoringContent.LoadBands.veryHard  /// Very hard (extreme) load (80-100)
    }
    
    // MARK: - Band Descriptions
    /// Use centralized load descriptions from ScoringContent
    enum BandDescriptions {
        static let light = ScoringContent.LoadDescriptions.light  /// Light description
        static let moderate = ScoringContent.LoadDescriptions.moderate  /// Moderate description
        static let hard = ScoringContent.LoadDescriptions.hard  /// Hard description
        static let veryHard = ScoringContent.LoadDescriptions.veryHard  /// Very hard description
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
    
    // MARK: - Section Titles
    static let loadComponents = "Load Components"  /// Load components section
    static let activitySummary = "Activity Summary"  /// Activity summary section
    static let dailyBreakdown = "Daily Breakdown"  /// Daily breakdown section
}
