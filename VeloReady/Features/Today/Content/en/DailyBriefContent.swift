import Foundation

/// Content strings for Daily Brief card (free users)
enum DailyBriefContent {
    // MARK: - Header
    static let title = "Daily Focus"  /// Card title
    
    // MARK: - Sections
    static let trainingStressBalance = "Training Stress Balance"  /// TSB section label
    static let recommendedTraining = "Recommended Training Today"  /// Training recommendation label
    
    // MARK: - Recovery Messages
    enum Recovery {
        static let optimal = "You're well recovered and ready for hard training"  /// High recovery (80+)
        static let moderate = "Moderate recovery - consider lighter training"  /// Medium recovery (60-79)
        static let low = "Low recovery - prioritize rest and easy sessions"  /// Low recovery (<60)
    }
    
    // MARK: - TSB Labels
    enum TSB {
        static let fatigued = "Fatigued"  /// TSB < -10
        static let optimal = "Optimal"  /// TSB -10 to 5
        static let fresh = "Fresh"  /// TSB 5 to 15
        static let veryFresh = "Very Fresh"  /// TSB > 15
    }
    
    // MARK: - Training Recommendations
    enum TrainingRecommendation {
        static let highIntensity = "High intensity or long duration workouts"  /// High recovery (80+)
        static let moderate = "Moderate intensity, shorter duration"  /// Medium recovery (60-79)
        static let easy = "Easy recovery rides or rest day"  /// Low recovery (<60)
    }
    
    // MARK: - Upgrade Prompt
    static let upgradePrompt = "Upgrade to Pro for Intelligent Insights with VeloAI >"  /// PRO upgrade message
}
