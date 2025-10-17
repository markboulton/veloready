import Foundation

/// Centralized scoring terminology used across Recovery, Sleep, and Training Load
/// This ensures consistent language and makes localization easier
enum ScoringContent {
    // MARK: - Score Bands
    /// Universal score band labels used across all scoring systems
    enum Bands {
        static let optimal = "Optimal"       /// Top tier (80-100)
        static let good = "Good"             /// Second tier (60-79)
        static let fair = "Fair"             /// Third tier (40-59)
        static let payAttention = "Pay Attention"  /// Bottom tier (0-39)
    }
    
    // MARK: - Recovery Band Descriptions
    /// Descriptions specific to Recovery scoring
    enum RecoveryDescriptions {
        static let optimal = "Fully Recovered"        /// Optimal recovery description
        static let good = "Well Recovered"            /// Good recovery description
        static let fair = "Partially Recovered"       /// Fair recovery description
        static let payAttention = "Low Recovery"      /// Pay attention recovery description
    }
    
    // MARK: - Sleep Band Descriptions
    /// Descriptions specific to Sleep scoring
    enum SleepDescriptions {
        static let optimal = "Restorative Sleep"      /// Optimal sleep description
        static let good = "Quality Sleep"             /// Good sleep description
        static let fair = "Adequate Sleep"            /// Fair sleep description
        static let payAttention = "Poor Sleep"        /// Pay attention sleep description
    }
    
    // MARK: - Load Band Descriptions
    /// Descriptions specific to Training Load scoring
    enum LoadDescriptions {
        static let optimal = "Light Day"              /// Optimal (low) load description
        static let good = "Moderate Training"         /// Good (moderate) load description
        static let fair = "Hard Training"             /// Fair (high) load description
        static let payAttention = "Very Hard Training"  /// Pay attention (extreme) load description
    }
    
    // MARK: - Helper Functions
    
    /// Get the appropriate band label for a score (0-100)
    static func bandForScore(_ score: Int) -> String {
        switch score {
        case 80...100: return Bands.optimal
        case 60..<80: return Bands.good
        case 40..<60: return Bands.fair
        default: return Bands.payAttention
        }
    }
    
    /// Get recovery-specific description for a score
    static func recoveryDescriptionForScore(_ score: Int) -> String {
        switch score {
        case 80...100: return RecoveryDescriptions.optimal
        case 60..<80: return RecoveryDescriptions.good
        case 40..<60: return RecoveryDescriptions.fair
        default: return RecoveryDescriptions.payAttention
        }
    }
    
    /// Get sleep-specific description for a score
    static func sleepDescriptionForScore(_ score: Int) -> String {
        switch score {
        case 80...100: return SleepDescriptions.optimal
        case 60..<80: return SleepDescriptions.good
        case 40..<60: return SleepDescriptions.fair
        default: return SleepDescriptions.payAttention
        }
    }
    
    /// Get load-specific description for a score
    /// Note: Load scoring is inverted (low is good, high needs attention)
    static func loadDescriptionForScore(_ score: Int) -> String {
        switch score {
        case 0..<40: return LoadDescriptions.optimal
        case 40..<60: return LoadDescriptions.good
        case 60..<80: return LoadDescriptions.fair
        default: return LoadDescriptions.payAttention
        }
    }
}
