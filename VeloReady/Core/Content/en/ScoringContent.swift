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
    
    // MARK: - Load Band Labels
    /// Labels specific to Training Load scoring (intensity-based)
    enum LoadBands {
        static let light = "Light"                    /// Light (low) load
        static let moderate = "Moderate"              /// Moderate load
        static let hard = "Hard"                      /// Hard (high) load
        static let veryHard = "Very Hard"             /// Very hard (extreme) load
    }
    
    // MARK: - Load Band Descriptions
    /// Descriptions specific to Training Load scoring
    enum LoadDescriptions {
        static let light = "Easy Day"                 /// Light load description
        static let moderate = "Standard Training"     /// Moderate load description
        static let hard = "Challenging Session"       /// Hard load description
        static let veryHard = "Extreme Training Load" /// Very hard load description
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
    
    /// Get load-specific band label for a score
    static func loadBandForScore(_ score: Int) -> String {
        switch score {
        case 0..<40: return LoadBands.light
        case 40..<60: return LoadBands.moderate
        case 60..<80: return LoadBands.hard
        default: return LoadBands.veryHard
        }
    }
    
    /// Get load-specific description for a score
    static func loadDescriptionForScore(_ score: Int) -> String {
        switch score {
        case 0..<40: return LoadDescriptions.light
        case 40..<60: return LoadDescriptions.moderate
        case 60..<80: return LoadDescriptions.hard
        default: return LoadDescriptions.veryHard
        }
    }
}
