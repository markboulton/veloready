import Foundation

/// Content strings for the Trends feature
enum TrendsContent {
    // MARK: - Navigation
    static let title = "Trends"  /// Navigation title
    
    // MARK: - Time Ranges
    enum TimeRanges {
        static let days30 = "30 Days"  /// 30 days range
        static let days90 = "90 Days"  /// 90 days range
        static let days180 = "180 Days"  /// 180 days range
        static let year = "1 Year"  /// 1 year range
    }
    
    // MARK: - Cards
    enum Cards {
        static let performanceOverview = "Performance Overview"  /// Performance overview card title
        static let recoveryTrend = "Recovery Trend"  /// Recovery trend card title
        static let hrvTrend = "HRV Trend"  /// HRV trend card title
        static let restingHR = "Resting Heart Rate"  /// Resting HR card title
        static let ftpTrend = "FTP Trend"  /// FTP trend card title
        static let trainingLoad = "Training Load"  /// Training load card title
        static let weeklyTSS = "Weekly TSS"  /// Weekly TSS card title
        static let stressLevel = "Inferred Stress Level"  /// Stress level card title
        static let overtrainingRisk = "Overtraining Risk"  /// Overtraining risk card title
        static let trainingPhase = "Training Phase"  /// Training phase card title
        static let recoveryVsPower = "Recovery vs Power"  /// Recovery vs power card title
    }
    
    // MARK: - Metrics
    enum Metrics {
        static let recovery = "Recovery"  /// Recovery metric
        static let load = "Load"  /// Load metric
        static let sleep = "Sleep"  /// Sleep metric
        static let hrv = "HRV"  /// HRV metric
        static let restingHR = "Resting HR"  /// Resting HR metric
        static let ftp = "FTP"  /// FTP metric
        static let ctl = "CTL (Fitness)"  /// CTL metric
        static let atl = "ATL (Fatigue)"  /// ATL metric
        static let tsb = "TSB (Form)"  /// TSB metric
        static let avgStress = "Avg Stress"  /// Average stress
        static let level = "Level"  /// Level label
        static let correlation = "Correlation"  /// Correlation label
        static let rSquared = "R² (Variance)"  /// R-squared label
        static let activities = "Activities"  /// Activities count
    }
    
    // MARK: - Empty States
    static let noData = "Not enough data"  /// No data message
    static let loadingData = "Loading trend data..."  /// Loading message
    static let requiresData = "This analysis requires:"  /// Requires data prefix
    
    // MARK: - Insights
    static let insight = "Insight"  /// Insight label
    static let uniqueInsight = "Unique Insight"  /// Unique insight label
    static let actionRequired = "Action Required"  /// Action required label
    static let recommendation = "Recommendation"  /// Recommendation label
    
    // MARK: - PRO Feature
    static let proFeature = "PRO"  /// PRO badge text
    static let proRequired = "PRO feature"  /// PRO required message
}
