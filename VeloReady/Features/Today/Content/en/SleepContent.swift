import Foundation

/// Content strings for Sleep feature
enum SleepContent {
    // MARK: - Navigation
    static let title = "Sleep Analysis"  /// Navigation title
    
    // MARK: - Sections
    static let breakdownTitle = "Sleep Score Breakdown"  /// Breakdown section title
    static let metricsTitle = "Sleep Metrics"  /// Metrics section title
    static let stagesTitle = "Sleep Stages"  /// Stages section title
    static let recommendationsTitle = "Recommendations"  /// Recommendations section title
    static let trendTitle = "Sleep Trend"  /// Trend chart title (period shown in selector)
    
    // MARK: - Bands
    /// Use centralized scoring terminology from ScoringContent
    enum Bands {
        static let optimal = ScoringContent.Bands.optimal  /// Optimal sleep (80-100)
        static let good = ScoringContent.Bands.good  /// Good sleep (60-79)
        static let fair = ScoringContent.Bands.fair  /// Fair sleep (40-59)
        static let payAttention = ScoringContent.Bands.payAttention  /// Pay attention sleep (0-39)
    }
    
    // MARK: - Band Descriptions
    /// Use centralized sleep descriptions from ScoringContent
    enum BandDescriptions {
        static let optimal = ScoringContent.SleepDescriptions.optimal  /// Optimal description
        static let good = ScoringContent.SleepDescriptions.good  /// Good description
        static let fair = ScoringContent.SleepDescriptions.fair  /// Fair description
        static let payAttention = ScoringContent.SleepDescriptions.payAttention  /// Pay attention description
    }
    
    // MARK: - Components
    enum Components {
        static let performance = "Performance"  /// Performance component
        static let efficiency = "Efficiency"  /// Efficiency component
        static let stageQuality = "Stage Quality"  /// Stage quality component
        static let disturbances = "Disturbances"  /// Disturbances component
        static let timing = "Timing"  /// Timing component
        static let latency = "Latency"  /// Latency component
    }
    
    // MARK: - Component Weights
    enum Weights {
        static let performance = "40%"  /// Performance weight
        static let efficiency = "15%"  /// Efficiency weight
        static let stageQuality = "20%"  /// Stage quality weight
        static let disturbances = "10%"  /// Disturbances weight
        static let timing = "10%"  /// Timing weight
        static let latency = "5%"  /// Latency weight
    }
    
    // MARK: - Metrics
    enum Metrics {
        static let duration = "Duration"  /// Duration label
        static let efficiency = "Efficiency"  /// Efficiency label
        static let timeInBed = "Time in Bed"  /// Time in bed label
        static let timeAsleep = "Time Asleep"  /// Time asleep label
        static let awakenings = "Awakenings"  /// Awakenings label
        static let sleepLatency = "Sleep Latency"  /// Sleep latency label
    }
    
    // MARK: - Sleep Stages
    enum Stages {
        static let deep = "Deep Sleep"  /// Deep sleep stage
        static let core = "Core Sleep"  /// Core sleep stage
        static let rem = "REM Sleep"  /// REM sleep stage
        static let awake = "Awake"  /// Awake time
    }
    
    // MARK: - Recommendations
    enum Recommendations {
        static let increaseDeep = "Try to increase deep sleep for better recovery"  /// Increase deep sleep
        static let improveEfficiency = "Improve sleep efficiency by reducing time awake in bed"  /// Improve efficiency
        static let reduceLatency = "Reduce sleep latency with a consistent bedtime routine"  /// Reduce latency
        static let consistentTiming = "Maintain consistent bedtime and wake times for better sleep quality"  /// Consistent timing
        static let goodQuality = "Great sleep quality! Keep up the good sleep habits."  /// Good quality message
    }
    
    // MARK: - Pro Features
    static let weeklyTrendFeature = "Weekly Sleep Trend"  /// Pro feature name
    static let weeklyTrendDescription = "Track your sleep quality over the past 7 days"  /// Pro feature description
}
