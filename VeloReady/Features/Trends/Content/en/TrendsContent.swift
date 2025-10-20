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
    static let noDataFound = "No data"  /// No data found
    static let loadingData = "Loading trend data..."  /// Loading message
    static let requiresData = "This analysis requires:"  /// Requires data prefix
    static let whatYouNeed = "What you need:"  /// What you need label
    static let toTrack = "To track"  /// To track prefix
    
    // FTP Card
    enum FTP {
        static let trackingComingSoon = "FTP tracking coming soon"  /// FTP tracking message
        static let currentFTP = "Current FTP"  /// Current FTP label
        static let historicalTracking = "Historical FTP tracking coming soon"  /// Historical tracking message
        static let completePowerRides = "Complete rides with power meter"  /// Power meter requirement
        static let uploadToIntervals = "Upload to Intervals.icu"  /// Upload requirement
        static let autoDetected = "FTP will be auto-detected over time"  /// Auto-detect message
        static let checkToday = "Check Today tab to view your current FTP"  /// Check today message
        static let trackChanges = "Track your FTP changes over time to see fitness progression."  /// Track changes description
    }
    
    // HRV Card
    enum HRV {
        static let noDataFound = "No HRV data found"  /// No HRV data
        static let wearWatch = "Wear Apple Watch during sleep"  /// Wear watch instruction
        static let grantPermission = "Grant HRV permission in Settings"  /// Grant permission
        static let measureConsistently = "Measure consistently for 7+ days"  /// Measure consistently
        static let baselineCalculated = "Baseline calculated after 7 days"  /// Baseline message
        static let bestIndicator = "HRV is your best recovery indicator"  /// Best indicator message
        static let baseline = "baseline"  /// Baseline label
    }
    
    // MARK: - Insights
    static let insight = "Insight"  /// Insight label
    static let uniqueInsight = "Unique Insight"  /// Unique insight label
    static let actionRequired = "Action Required"  /// Action required label
    static let recommendation = "Recommendation"  /// Recommendation label
    
    // MARK: - PRO Feature
    static let proFeature = "PRO"  /// PRO badge text
    static let proRequired = "PRO feature"  /// PRO required message
    static let unlockTrends = "Unlock Performance Trends"  /// Unlock trends title
    static let upgradeToPro = "Upgrade to VeloReady PRO"  /// Upgrade button
    static let bulletPoint = "•"  /// Bullet point
    
    // MARK: - Weekly Report
    enum WeeklyReport {
        static let title = "Weekly Performance Report"  /// Weekly report title
        static let dateRange = "Week of"  /// Week range prefix
        static let nextReport = "Next report:"  /// Next report prefix
        static let generatedToday = "Generated today"  /// Generated today message
        static let daysPlural = "days"  /// Days plural
        static let daySingular = "day"  /// Day singular
        
        // AI Summary
        static let analyzing = "Analyzing your week..."  /// AI loading message
        static let unableToGenerate = "Unable to generate analysis"  /// Error message
        
        // Fitness Trajectory
        static let fitnessTrajectory = "Fitness Trajectory (7 Days)"  /// Fitness trajectory title
        static let ctlLabel = "CTL"  /// CTL label
        static let atlLabel = "ATL"  /// ATL label
        static let formLabel = "Form"  /// Form/TSB label
        static let fitnessLabel = "Fitness"  /// Fitness label for legend
        static let fatigueLabel = "Fatigue"  /// Fatigue label for legend
        
        // Interpretations
        static let fatigued = "Fatigued - prioritize recovery"  /// Fatigued interpretation
        static let optimalTraining = "Optimal training zone"  /// Optimal interpretation
        static let fresh = "Fresh - ready for hard efforts"  /// Fresh interpretation
        static let veryFresh = "Very fresh - consider increasing load"  /// Very fresh interpretation
        
        // Wellness Foundation
        static let wellnessFoundation = "Wellness Foundation"  /// Wellness foundation title
        static let overallScore = "Overall Score:"  /// Overall score label
        static let strongFoundation = "Strong wellness foundation supporting your training"  /// Good wellness message
        static let sleepNeedsAttention = "Sleep quality needs attention"  /// Sleep warning
        static let stressElevated = "Stress levels elevated (lower is better)"  /// Stress warning
        static let consistencyImprove = "Consistency could improve"  /// Consistency warning
        
        // Wellness Metrics
        static let sleepMetric = "Sleep"  /// Sleep metric
        static let recoveryMetric = "Recovery"  /// Recovery metric
        static let hrvMetric = "HRV"  /// HRV metric
        static let lowStressMetric = "Low Stress"  /// Low stress metric
        static let consistentMetric = "Consistent"  /// Consistent metric
        static let fuelingMetric = "Fueling"  /// Fueling metric
        
        // Recovery Capacity
        static let recoveryCapacity = "Recovery Capacity"  /// Recovery capacity title
        static let avgRecovery = "Avg Recovery"  /// Average recovery label
        static let hrvTrend = "HRV Trend"  /// HRV trend label
        static let sleepLabel = "Sleep"  /// Sleep label
        static let excellentCapacity = "Excellent capacity - ready for challenging training"  /// Excellent capacity
        static let goodCapacity = "Good capacity - can handle moderate training load"  /// Good capacity
        static let adequateCapacity = "Adequate - maintain current training level"  /// Adequate capacity
        static let lowCapacity = "Low capacity - prioritize recovery before increasing load"  /// Low capacity
        
        // Training Load
        static let trainingLoadSummary = "Training Load Summary"  /// Training load title
        static let totalTSS = "Total TSS"  /// Total TSS label
        static let trainingTime = "Training Time"  /// Training time label
        static let workouts = "Workouts"  /// Workouts label
        static let trainingPattern = "Training Pattern"  /// Training pattern label
        static let optimalDays = "Optimal"  /// Optimal days
        static let hardDays = "Hard"  /// Hard days
        static let easyRestDays = "Easy/Rest"  /// Easy/rest days
        static let intensityDistribution = "Intensity Distribution"  /// Intensity distribution title
        static let easyZone = "Easy (Z1-2)"  /// Easy zone
        static let tempoZone = "Tempo (Z3-4)"  /// Tempo zone
        static let hardZone = "Hard (Z5+)"  /// Hard zone
        static let polarization = "Polarization:"  /// Polarization label
        static let wellPolarized = "Well polarized"  /// Well polarized message
        static let couldBePolarized = "Could be more polarized"  /// Could improve message
        static let goodBalance = "Good balance of training stress and recovery"  /// Good balance
        static let highStress = "High training stress - monitor recovery closely"  /// High stress
        static let lightWeek = "Light training week - good for recovery or taper"  /// Light week
        
        // Sleep
        static let weeklySleep = "Weekly Sleep"  /// Weekly sleep title
        static let nightDuration = "Night Duration"  /// Night duration label
        
        // Sleep Schedule
        static let sleepSchedule = "Sleep Schedule"  /// Sleep schedule title
        static let avgBedtime = "Avg Bedtime"  /// Average bedtime label
        static let avgWake = "Avg Wake"  /// Average wake label
        static let consistency = "Consistency"  /// Consistency label
        static let excellentConsistency = "Excellent schedule consistency - supports recovery and adaptation"  /// Excellent consistency
        static let goodConsistency = "Good consistency - small variations are normal"  /// Good consistency
        static let variableSchedule = "Variable schedule - more consistency could improve recovery"  /// Variable schedule
        
        // Week-over-Week
        static let weekOverWeek = "Week-over-Week Changes"  /// Week-over-week title
        static let recoveryLabel = "Recovery"  /// Recovery label
        static let tssLabel = "TSS"  /// TSS label
        static let timeLabel = "Training Time"  /// Training time label
        static let ctlChange = "CTL"  /// CTL change label
        
        // No Data
        static let noTrainingData = "No training load data available"  /// No training data
        static let noSleepData = "No sleep data available"  /// No sleep data
    }
    
    // MARK: - Chart Labels
    enum ChartLabels {
        static let fitnessTrajectory = "Fitness Trajectory"  /// Fitness trajectory chart title
    }
}
