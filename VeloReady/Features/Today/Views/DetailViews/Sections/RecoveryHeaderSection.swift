import SwiftUI

/// Header section showing recovery ring and description
struct RecoveryHeaderSection: View {
    let recoveryScore: RecoveryScore
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            RecoveryRingView(
                score: recoveryScore.score,
                band: recoveryScore.band,
                isPersonalized: recoveryScore.isPersonalized
            )
            
            VStack(spacing: Spacing.xs / 2) {
                Text(recoveryScore.bandDescription)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForBand(recoveryScore.band))
                
                Text(RecoveryContent.timeframe)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(recoveryScore.dailyBrief)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private func colorForBand(_ band: RecoveryScore.RecoveryBand) -> Color {
        switch band {
        case .optimal: return ColorScale.greenAccent
        case .good: return ColorScale.yellowAccent
        case .fair: return ColorScale.amberAccent
        case .payAttention: return ColorScale.redAccent
        }
    }
}
