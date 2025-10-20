import Foundation

/// Content strings for Recovery feature
enum RecoveryContent {
    // MARK: - Navigation
    static let title = "Recovery Details"  /// Navigation title
    
    // MARK: - Sections
    static let factorsTitle = "Recovery Factors"  /// Factors section title
    static let metricsTitle = "Health Metrics"  /// Metrics section title
    static let trendTitle = "Recovery Trend"  /// Trend chart title (period shown in selector)
    static let appleHealthTitle = "Apple Health Data"  /// Apple Health section title
    
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
    
    // MARK: - Band Descriptions (Enhanced with actionable guidance)
    /// Use centralized recovery descriptions from ScoringContent
    enum BandDescriptions {
        static let optimal = "Fully Recovered - Ready for High Intensity"
        static let good = "Well Recovered - Moderate to High Intensity Safe"
        static let fair = "Partially Recovered - Easy to Moderate Only"
        static let payAttention = "Low Recovery - Rest or Very Light Activity"
    }
    
    // MARK: - New Metrics
    enum NewMetrics {
        static let recoveryDebt = "Recovery Debt"
        static let readiness = "Readiness"
        static let resilience = "Resilience"
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
        static let hrvRMSSD = "HRV (RMSSD)"  /// HRV RMSSD label
        static let restingHeartRate = "Resting Heart Rate"  /// Resting heart rate label
        static let trainingLoadRatio = "Training Load Ratio"  /// Training load ratio label
        static let current = "Current:"  /// Current prefix
        static let baseline = "Baseline:"  /// Baseline prefix
        static let weight = "Weight:"  /// Weight prefix
        static let calculatingBaseline = "Calculating baseline..."  /// Calculating baseline message
        static let baselineAvailable = "Baseline will be available after 7 days"  /// Baseline availability message
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
    
    // MARK: - Recovery Debt
    enum RecoveryDebt {
        static let consecutiveDays = "consecutive days below 60"  /// Consecutive days label
        static let description = "Tracks consecutive days of suboptimal recovery to prevent overtraining"  /// Recovery debt description
    }
    
    // MARK: - Resilience
    enum Resilience {
        static let capacityLabel = "30-day recovery capacity"  /// Capacity label
        static let avgRecovery = "Avg Recovery:"  /// Average recovery label
        static let avgLoad = "Avg Load:"  /// Average load label
        static let description = "Analyzes your recovery capacity relative to training load over 30 days"  /// Resilience description
    }
    
    // MARK: - Readiness
    enum Readiness {
        static let description = "Combines recovery, sleep, and training load for actionable training guidance"  /// Readiness description
        static let recovery = "Recovery"  /// Recovery component
        static let sleep = "Sleep"  /// Sleep component
        static let load = "Load"  /// Load component
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
    }
}
