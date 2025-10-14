import Foundation

/// Content strings for the Today dashboard
enum TodayContent {
    // MARK: - Navigation
    static let title = "Today"  /// Navigation title
    
    // MARK: - Sections
    static let recoverySection = "Recovery"  /// Recovery section title
    static let sleepSection = "Sleep"  /// Sleep section title
    static let loadSection = "Load"  /// Load section title
    static let activitiesSection = "Activities"  /// Activities section title
    static let aiBriefSection = "AI Brief"  /// AI Brief section title
    
    // MARK: - Empty States
    static let noActivities = "No activities today"  /// No activities message
    static let noRecoveryData = "Recovery data unavailable"  /// No recovery data
    static let noSleepData = "Sleep data unavailable"  /// No sleep data
    static let syncingData = "Syncing your data..."  /// Syncing message
    
    // MARK: - Actions
    static let viewDetails = "View Details"  /// View details button
    static let calculateRecovery = "Calculate Recovery"  /// Calculate recovery button
    static let refreshData = "Refresh Data"  /// Refresh button
    
    // MARK: - Health Kit
    static let healthKitRequired = "Health data access required"  /// HealthKit required message
    static let grantAccess = "Grant Access"  /// Grant access button
    
    // MARK: - Scores
    enum Scores {
        static let recoveryScore = "Recovery"  /// Recovery score label
        static let sleepScore = "Sleep"  /// Sleep score label
        static let loadScore = "Load"  /// Load score label
    }
    
    // MARK: - AI Brief
    enum AIBrief {
        static let title = "Daily Brief"  /// AI Brief section title
        static let loading = "Loading your daily brief..."  /// Loading message
        static let tsb = "Training Stress Balance:"  /// TSB label
        static let targetTSS = "Target TSS Today:"  /// Target TSS label
        static let tssDescription = "Training Stress Score - aim for this range based on your fitness"  /// TSS description
    }
}
