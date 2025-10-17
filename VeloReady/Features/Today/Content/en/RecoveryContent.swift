import Foundation

/// Content strings for Recovery feature
enum RecoveryContent {
    // MARK: - Navigation
    static let title = "Recovery Details"  /// Navigation title
    
    // MARK: - Sections
    static let factorsTitle = "Recovery Factors"  /// Factors section title
    static let metricsTitle = "Health Metrics"  /// Metrics section title
    static let trendTitle = "Recovery Trend"  /// Trend chart title (period shown in selector)
    
    // MARK: - Metrics
    enum Metrics {
        static let hrv = "Heart Rate Variability"  /// HRV label
        static let rhr = "Resting Heart Rate"  /// RHR label
        static let sleep = "Sleep Quality"  /// Sleep label
        static let load = "Training Load"  /// Load label
    }
    
    // MARK: - Weights
    enum Weights {
        static let hrvWeight = "40%"  /// HRV weight
        static let rhrWeight = "30%"  /// RHR weight
        static let sleepWeight = "20%"  /// Sleep weight
        static let loadWeight = "10%"  /// Load weight
    }
    
    // MARK: - Bands
    /// Use centralized scoring terminology from ScoringContent
    enum Bands {
        static let optimal = ScoringContent.Bands.optimal  /// Optimal band (80-100)
        static let good = ScoringContent.Bands.good  /// Good band (60-79)
        static let fair = ScoringContent.Bands.fair  /// Fair band (40-59)
        static let payAttention = ScoringContent.Bands.payAttention  /// Pay attention band (0-39)
    }
    
    // MARK: - Band Descriptions
    /// Use centralized recovery descriptions from ScoringContent
    enum BandDescriptions {
        static let optimal = ScoringContent.RecoveryDescriptions.optimal  /// Optimal description
        static let good = ScoringContent.RecoveryDescriptions.good  /// Good description
        static let fair = ScoringContent.RecoveryDescriptions.fair  /// Fair description
        static let payAttention = ScoringContent.RecoveryDescriptions.payAttention  /// Pay attention description
    }
    
    // MARK: - Messages
    static func dailyBrief(score: Int) -> String {  /// Dynamic daily brief based on score
        switch score {
        case 80...100: return "You're fully recovered and ready to train hard!"
        case 60..<80: return "Good recovery. You can handle moderate training."
        case 40..<60: return "Partial recovery. Consider an easy day."
        default: return "Low recovery. Rest is recommended."
        }
    }
    
    // MARK: - Health Metrics
    enum HealthMetrics {
        static let currentHRV = "Current HRV"  /// Current HRV label
        static let baselineHRV = "Baseline HRV"  /// Baseline HRV label
        static let currentRHR = "Current RHR"  /// Current RHR label
        static let baselineRHR = "Baseline RHR"  /// Baseline RHR label
        static let sleepDuration = "Sleep Duration"  /// Sleep duration label
        static let sleepTarget = "Sleep Target"  /// Sleep target label
    }
    
    // MARK: - Alerts
    enum Alerts {
        static let alcoholDetected = "Alcohol Detected"  /// Alcohol alert title
        static let alcoholMessage = "Overnight HRV significantly lower than daytime average"  /// Alcohol message
        static let lowHRV = "Low HRV"  /// Low HRV alert
        static let highRHR = "Elevated RHR"  /// High RHR alert
        static let poorSleep = "Poor Sleep"  /// Poor sleep alert
    }
    
    // MARK: - Pro Features
    static let weeklyTrendFeature = "Weekly Recovery Trend"  /// Pro feature name
    static let weeklyTrendDescription = "Track your recovery score over the past 7 days"  /// Pro feature description
}
