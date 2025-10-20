import SwiftUI

/// Compact card view for Readiness Score
struct ReadinessCardView: View {
    let readinessScore: ReadinessScore
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "figure.run")
                        .font(.title3)
                        .foregroundColor(readinessScore.band.colorToken)
                    
                    Text(ReadinessContent.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ColorPalette.labelSecondary)
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Score
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(readinessScore.score)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(readinessScore.band.colorToken)
                    
                    Text(TodayContent.ReadinessComponents.outOf100)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.labelTertiary)
                }
                
                // Band and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(readinessScore.band.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(readinessScore.band.colorToken)
                    
                    Text(readinessScore.band.trainingRecommendation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Divider()
                
                // Component breakdown
                HStack(spacing: 16) {
                    ComponentPill(
                        label: TodayContent.ReadinessComponents.recovery,
                        value: readinessScore.components.recoveryScore,
                        color: .blue
                    )
                    
                    ComponentPill(
                        label: TodayContent.ReadinessComponents.sleep,
                        value: readinessScore.components.sleepScore,
                        color: .purple
                    )
                    
                    ComponentPill(
                        label: TodayContent.ReadinessComponents.load,
                        value: readinessScore.components.loadReadiness,
                        color: .orange
                    )
                }
            }
            .padding()
            .background(ColorPalette.backgroundSecondary)
            .cornerRadius(0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Small pill showing component score
private struct ComponentPill: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct ReadinessCardView_Previews: PreviewProvider {
    static var previews: some View {
        let mockReadiness = ReadinessScore(
            score: 82,
            band: .fullyReady,
            components: ReadinessScore.Components(
                recoveryScore: 85,
                sleepScore: 88,
                loadReadiness: 70,
                recoveryWeight: 0.4,
                sleepWeight: 0.35,
                loadWeight: 0.25
            ),
            calculatedAt: Date()
        )
        
        ReadinessCardView(readinessScore: mockReadiness, onTap: {})
            .padding()
    }
}
