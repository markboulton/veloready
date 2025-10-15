import SwiftUI

/// Header section showing recovery ring and description
struct RecoveryHeaderSection: View {
    let recoveryScore: RecoveryScore
    
    var body: some View {
        VStack(spacing: 16) {
            RecoveryRingView(score: recoveryScore.score, band: recoveryScore.band)
            
            Text(recoveryScore.bandDescription)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(colorForBand(recoveryScore.band))
            
            Text(recoveryScore.dailyBrief)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private func colorForBand(_ band: RecoveryScore.RecoveryBand) -> Color {
        switch band {
        case .excellent: return ColorScale.greenAccent
        case .good: return ColorScale.yellowAccent
        case .fair: return ColorScale.amberAccent
        case .poor: return ColorScale.redAccent
        }
    }
}
