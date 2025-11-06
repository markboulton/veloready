import Foundation

/// Extensions for RecoveryScoreService helper methods
extension RecoveryScoreService {
    
    /// Determine recovery band from score (0-100)
    func determineBand(score: Int) -> RecoveryScore.RecoveryBand {
        switch score {
        case 80...100: return .optimal
        case 60..<80: return .good
        case 40..<60: return .fair
        default: return .payAttention
        }
    }
}
