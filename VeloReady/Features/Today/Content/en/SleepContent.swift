import Foundation

/// Content strings for Sleep feature
enum SleepContent {
    // MARK: - Actions
    static let viewDetails = CommonContent.Actions.viewDetails
    
    // MARK: - Navigation
    static let title = "Sleep Analysis"  /// Navigation title
    
    // MARK: - Sections
    static let breakdownTitle = "Sleep Score Breakdown"  /// Breakdown section title
    static let metricsTitle = "Sleep Metrics"  /// Metrics section title
    static let stagesTitle = "Sleep Stages"  /// Stages section title
    static let recommendationsTitle = "Recommendations"  /// Recommendations section title
    static let trendTitle = "Sleep Trend"  /// Trend chart title (period shown in selector)
    static let hypnogramTitle = "Sleep Stages Over Time"  /// Hypnogram chart title
    
    // MARK: - Bands
    /// Use centralized scoring terminology from ScoringContent
    enum Bands {
        static let optimal = ScoringContent.Bands.optimal  /// Optimal sleep (80-100)
        static let good = ScoringContent.Bands.good  /// Good sleep (60-79)
        static let fair = ScoringContent.Bands.fair  /// Fair sleep (40-59)
        static let payAttention = ScoringContent.Bands.payAttention  /// Pay attention sleep (0-39)
    }
    
    // MARK: - Band Descriptions (Enhanced with recovery context)
    /// Use centralized sleep descriptions from ScoringContent
    enum BandDescriptions {
        static let optimal = "Restorative Sleep - Full Physical & Mental Recovery"
        static let good = "Quality Sleep - Good Recovery Achieved"
        static let fair = "Adequate Sleep - Partial Recovery"
        static let payAttention = "Poor Sleep - Recovery Compromised"
    }
    
    // MARK: - New Metrics
    enum NewMetrics {
        static let sleepDebt = "Sleep Debt"
        static let consistency = "Sleep Consistency"
        static let latency = "Sleep Latency"
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
        static let sleepNeed = "Sleep Need"  /// Sleep need label
        static let wakeEvents = "Wake Events"  /// Wake events label
        static let deepSleep = CommonContent.Metrics.deepSleep  /// Deep sleep label
    }
    
    // MARK: - Sleep Stages
    enum Stages {
        static let deep = CommonContent.Stages.deep  /// Deep sleep stage
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
        static let targetSleep = "Try to get closer to your sleep target of"  /// Target sleep recommendation prefix
        static let focusOnStages = "Focus on getting more deep and REM sleep through better sleep hygiene"  /// Stage quality recommendation
        static let reduceDisturbances = "Reduce sleep disturbances by creating a more comfortable sleep environment"  /// Disturbance recommendation
    }
    
    // MARK: - Pro Features
    static let weeklyTrendFeature = "Weekly Sleep Trend"  /// Pro feature name
    static let weeklyTrendDescription = "Track your sleep quality over the past 7 days"  /// Pro feature description
    
    // MARK: - Warnings & Empty States
    enum Warnings {
        static let noSleepDataTitle = "No sleep data from last night"  /// Missing sleep data title
        static let noSleepDataMessage = "Sleep score is unavailable. Wear your Apple Watch tonight to track sleep and get complete recovery analysis tomorrow."  /// Missing sleep data message
        static let noDetailedData = "No detailed sleep stage data available"  /// No hypnogram data
        static let noStageData = "No sleep stage data available"  /// No stage data
    }
    
    // MARK: - Component Descriptions
    enum ComponentDescriptions {
        static let performance = "Actual sleep vs. sleep need"  /// Performance description
        static let efficiency = "Time asleep vs. time in bed"  /// Efficiency description
        static let stageQuality = "Deep + REM sleep percentage"  /// Stage quality description
        static let disturbances = "Number of wake events"  /// Disturbances description
        static let timing = "Bedtime/wake time consistency"  /// Timing description
    }
    
    // MARK: - Sleep Debt
    enum SleepDebt {
        static let cumulativeDeficit = "7-day cumulative deficit"  /// Cumulative deficit label
        static let avgSleep = "Avg sleep:"  /// Average sleep label
        static let need = "Need:"  /// Need label
        static let trendTitle = "7-Day Sleep Quality Trend"  /// Trend chart title
        static let optimal = "Optimal"  /// Optimal legend
        static let good = "Good"  /// Good legend
        static let fair = "Fair"  /// Fair legend
    }
    
    // MARK: - Sleep Consistency
    enum Consistency {
        static let circadianHealth = "Circadian rhythm health"  /// Circadian health label
        static let scheduleVariability = "Schedule Variability: Bedtime"  /// Schedule variability prefix
        static let wake = "Wake"  /// Wake label
        static let patternTitle = "7-Day Sleep Score Pattern"  /// Pattern chart title
        static let deviationNote = "Dots show deviation from average score"  /// Chart note
        // Band Descriptions
        static let excellentDescription = "Highly consistent sleep schedule"  /// Excellent consistency
        static let goodDescription = "Generally consistent sleep schedule"  /// Good consistency
        static let fairDescription = "Moderately inconsistent sleep schedule"  /// Fair consistency
        static let poorDescription = "Highly irregular sleep schedule"  /// Poor consistency
        
        // Recommendations
        static let excellentRecommendation = "Maintain current sleep schedule"  /// Excellent recommendation
        static let goodRecommendation = "Try to keep bedtime within 30 minutes"  /// Good recommendation
        static let fairRecommendation = "Establish more regular sleep/wake times"  /// Fair recommendation
        static let poorRecommendation = "Prioritize consistent sleep schedule - critical for recovery"  /// Poor recommendation
    }
    
    // MARK: - Data Availability
    enum DataAvailability {
        static let pullToRefresh = "Pull to refresh"  /// Pull to refresh message
        static let youHave = "You have"  /// You have prefix
        static let daysOfData = "days of data."  /// Days of data suffix
        static let checkBackIn = "Check back in"  /// Check back prefix
        static let day = "day"  /// Singular day
        static let days = "days"  /// Plural days
        static let of = "of"  /// Of label (e.g., "5 of 7 days")
        static let sleepDebtDescription = "Tracks cumulative sleep deficit to identify recovery needs"  /// Sleep debt description
        static let consistencyDescription = "Measures circadian rhythm health via sleep schedule variability"  /// Consistency description
    }
}
