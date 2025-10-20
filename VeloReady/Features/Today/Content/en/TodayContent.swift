import Foundation

/// Content strings for the Today dashboard
enum TodayContent {
    // MARK: - Navigation
    static let title = "Today"  /// Navigation title
    
    // MARK: - Sections
    static let recoverySection = "Recovery"  /// Recovery section title
    static let sleepSection = "Sleep"  /// Sleep section title
    static let loadSection = "Load"  /// Load section title
    static let activitiesSection = "Recent Activities"  /// Activities section title
    static let aiBriefSection = "AI Brief"  /// AI Brief section title
    
    // MARK: - Empty States
    static let noActivities = "No activities today"  /// No activities message
    static let noRecentActivities = "No Recent Activities"  /// No recent activities title
    static let noRecoveryData = "Recovery data unavailable"  /// No recovery data
    static let noSleepData = "Sleep data unavailable"  /// No sleep data
    static let syncingData = "Syncing your data..."  /// Syncing message
    static let limitedData = "Limited Data"  /// Limited data label
    static let noData = "No Data"  /// No data label
    static let noDataInfo = "No Data ⓘ"  /// No data with info icon
    
    // MARK: - Actions
    static let viewDetails = "View Details"  /// View details button
    static let calculateRecovery = "Calculate Recovery"  /// Calculate recovery button
    static let refreshData = "Refresh Data"  /// Refresh button
    
    // MARK: - Health Kit
    static let healthKitRequired = "Health data access required"  /// HealthKit required message
    static let grantAccess = "Grant Access"  /// Grant access button
    static let enableHealthDescription = "Connect your Apple Health data to see personalized recovery scores, sleep analysis, and training insights."  /// Enable health description
    
    // HealthKit Benefits
    enum HealthKitBenefits {
        static let recoveryTitle = "Recovery Score"  /// Recovery benefit title
        static let recoveryDesc = "Track your readiness based on HRV, sleep, and training"  /// Recovery benefit description
        static let sleepTitle = "Sleep Analysis"  /// Sleep benefit title
        static let sleepDesc = "Understand your sleep quality and patterns"  /// Sleep benefit description
        static let trainingLoadTitle = "Training Load"  /// Training load benefit title
        static let trainingLoadDesc = "Monitor your training stress and recovery balance"  /// Training load benefit description
    }
    
    enum HealthKit {
        static let title = "Health Data"
        static let enableTitle = "Enable Health Data"
        static let description = "Connect your Apple Health data to see personalized recovery scores, sleep analysis, and training insights."
        static let weAccess = "We'll access:"
        static let whatYouGet = "What you'll get:"
        static let enableButton = "Enable Health Data"
        static let enabling = "Enabling..."
        static let skipButton = "Skip for now"
        static let privacyNote = "Your health data stays private and secure"
        static let cancel = "Cancel"
        
        // Data types
        static let sleepAnalysis = "Sleep Analysis"
        static let hrv = "Heart Rate Variability"
        static let restingHR = "Resting Heart Rate"
        static let respiratoryRate = "Respiratory Rate"
        static let stepsActivity = "Steps & Activity"
        
        // Benefits
        static let recoveryScoreTitle = "Recovery Score"
        static let recoveryScoreDesc = "Track your readiness based on HRV, sleep, and training"
        static let sleepAnalysisTitle = "Sleep Analysis"
        static let sleepAnalysisDesc = "Detailed sleep staging from Apple Watch"
        static let trainingLoadTitle = "Training Load"
        static let trainingLoadDesc = "Monitor daily strain and training stress"
        
        // Alert
        static let authorizationTitle = "HealthKit Authorization"
        static let successMessage = "HealthKit permissions are now enabled! Your data will be analyzed to provide personalized insights."
        static let instructionsMessage = "To enable HealthKit permissions:\n\n1. Tap 'Open Settings' below\n2. Scroll down and tap 'Privacy & Security'\n3. Tap 'Health'\n4. Find 'VeloReady' and enable the permissions\n\nThen return to the app to see your data."
        static let openSettings = "Open Settings"
        static let ok = "OK"
    }
    
    // MARK: - Scores
    enum Scores {
        static let recoveryScore = "Recovery"  /// Recovery score label
        static let sleepScore = "Sleep"  /// Sleep score label
        static let loadScore = "Load"  /// Load score label
    }
    
    // MARK: - AI Brief
    enum AIBrief {
        static let title = "VeloAI"  /// AI Brief section title
        static let loading = "Loading your daily brief..."  /// Loading message
        static let analyzing = "Analyzing your data..."  /// Analyzing message (loading state)
        static let tsb = "Training Stress Balance:"  /// TSB label
        static let targetTSS = "Target TSS Today:"  /// Target TSS label
        static let tssDescription = "Training Stress Score - aim for this range based on your fitness"  /// TSS description
        static let mlCollecting = "Collecting data to personalize your insights"  /// ML data collection message
        static let mlDaysRemaining = "days remaining"  /// ML days remaining label
        static let daysLabel = "days"  /// Days label
        static let hideDebugInfo = "Hide Debug Info"  /// Hide debug info button
        static let showDebugInfo = "Show Debug Info"  /// Show debug info button
    }
    
    // MARK: - Calories
    enum Calories {
        static let calories = "Calories"  /// Calories label
        static let goal = "Goal"  /// Goal label
        static let activeEnergy = "Active Energy"  /// Active energy label
        static let total = "Total"  /// Total label
        static let updated = "Updated"  /// Updated prefix
    }
    
    // MARK: - Readiness Components
    enum ReadinessComponents {
        static let recovery = "Recovery"  /// Recovery component
        static let sleep = "Sleep"  /// Sleep component
        static let load = "Load"  /// Load component
        static let outOf100 = "/100"  /// Out of 100 suffix
    }
    
    // MARK: - Debt Metrics
    enum DebtMetrics {
        static let recoveryDebt = "Recovery Debt"  /// Recovery debt title
        static let sleepDebt = "Sleep Debt"  /// Sleep debt title
        static let daysLabel = "days"  /// Days label
    }
}
