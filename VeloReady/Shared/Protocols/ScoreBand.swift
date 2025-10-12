import SwiftUI

/// Protocol for score bands (recovery, sleep, etc.)
protocol ScoreBand {
    var colorToken: Color { get }
}

// MARK: - Recovery Score Band Conformance

extension RecoveryScore.RecoveryBand: ScoreBand {
    // Already has colorToken property
}

// MARK: - Sleep Score Band Conformance

extension SleepScore.SleepBand: ScoreBand {
    // Already has colorToken property
}

// MARK: - Strain Score Band Conformance

extension StrainScore.StrainBand: ScoreBand {
    // Already has colorToken property
}
