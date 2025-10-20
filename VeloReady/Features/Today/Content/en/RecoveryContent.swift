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
        static let sleepDuration = CommonContent.Metrics.sleepDuration  /// Sleep duration label
        static let sleepTarget = CommonContent.Metrics.sleepTarget  /// Sleep target label
        static let hrvRMSSD = CommonContent.Metrics.hrvRMSSD  /// HRV RMSSD label
        static let restingHeartRate = CommonContent.Metrics.restingHeartRate  /// Resting heart rate label
        static let trainingLoadRatio = CommonContent.Metrics.trainingLoadRatio  /// Training load ratio label
        static let current = "Current:"  /// Current prefix
        static let baseline = "Baseline:"  /// Baseline prefix
        static let weight = "Weight:"  /// Weight prefix
        static let calculatingBaseline = "Calculating baseline..."  /// Calculating baseline message
        static let baselineAvailable = "Baseline will be available after 7 days"  /// Baseline availability message
    }
    
    // MARK: - Empty States
    static let noData = CommonContent.States.noData  /// No data message
    static let loading = CommonContent.States.loadingData
    static let calculating = CommonContent.States.computing  /// Computing message
    
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
        
        // Band Descriptions
        static let freshDescription = "No recovery debt - well rested"  /// Fresh
        static let accumulatingDescription = "Minor fatigue building - monitor closely"  /// Accumulating
        static let significantDescription = "Moderate fatigue - schedule recovery soon"  /// Significant
        static let criticalDescription = "Critical fatigue - stop training immediately"  /// Critical
        
        // Recommendations
        static let freshRecommendation = "Continue training as planned"  /// Fresh recommendation
        static let accumulatingRecommendation = "Consider an easy day within 24-48 hours"  /// Accumulating recommendation
        static let significantRecommendation = "Schedule rest day or very light activity"  /// Significant recommendation
        static let criticalRecommendation = "Immediate rest required to prevent overtraining"  /// Critical recommendation
    }
    
    // MARK: - Resilience
    enum Resilience {
        static let capacityLabel = "30-day recovery capacity"  /// Capacity label
        static let avgRecovery = "Avg Recovery:"  /// Average recovery label
        static let avgLoad = "Avg Load:"  /// Average load label
        static let description = "Analyzes your recovery capacity relative to training load over 30 days"  /// Resilience description
        
        // Band Descriptions
        static let highDescription = "Excellent recovery capacity"  /// High resilience
        static let goodDescription = "Good recovery capacity"  /// Good resilience
        static let fairDescription = "Average recovery capacity"  /// Fair/Moderate resilience
        static let lowDescription = "Below average recovery capacity"  /// Low resilience
        
        // Recommendations
        static let highRecommendation = "Excellent resilience - can handle high training loads"  /// High recommendation
        static let goodRecommendation = "Good recovery - maintain current training approach"  /// Good recommendation
        static let fairRecommendation = "Recovery is adequate - monitor closely"  /// Fair/Moderate recommendation
        static let lowRecommendation = "Recovery struggling - reduce training volume or intensity"  /// Low recommendation
    }
    
    // MARK: - Readiness
    enum Readiness {
        static let description = "Combines recovery, sleep, and training load for actionable training guidance"  /// Readiness description
        // Band Descriptions
        static let fullyReadyDescription = "Optimal readiness for training"  /// Fully ready
        static let readyDescription = "Good readiness - moderate intensity safe"  /// Ready
        static let compromisedDescription = "Reduced readiness - easy training only"  /// Compromised
        static let notReadyDescription = "Poor readiness - rest recommended"  /// Not ready
        
        // Training Recommendations
        static let fullyReadyTraining = "High intensity training recommended"  /// Fully ready training
        static let readyTraining = "Moderate to high intensity safe"  /// Ready training
        static let compromisedTraining = "Easy to moderate intensity only"  /// Compromised training
        static let notReadyTraining = "Rest day or very light activity"  /// Not ready training
        
        // Intensity Guidance
        static let fullyReadyGuidance = "Intervals, threshold work, or long rides"  /// Fully ready guidance
        static let readyGuidance = "Tempo, endurance, or moderate intensity"  /// Ready guidance
        static let compromisedGuidance = "Easy spin, recovery ride, or light cross-training"  /// Compromised guidance
        static let notReadyGuidance = "Complete rest or gentle stretching/walking"  /// Not ready guidance
        
        // Labels
        static let recovery = "Recovery:"  /// Recovery label
        static let sleep = "Sleep:"  /// Sleep label
        static let load = "Load:"  /// Load label
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
