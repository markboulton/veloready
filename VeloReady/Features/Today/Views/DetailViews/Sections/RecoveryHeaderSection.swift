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
        .padding()
        .background(Color.recovery.sectionBackground)
        .cornerRadius(16)
    }
    
    private func colorForBand(_ band: RecoveryScore.RecoveryBand) -> Color {
        switch band {
        case .excellent: return .green
        case .good: return Color.health.recovery
        case .fair: return .orange
        case .poor: return .red
        }
    }
}
