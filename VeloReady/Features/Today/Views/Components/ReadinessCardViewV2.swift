import SwiftUI

/// Modernized Readiness Card using atomic components
/// Reduced from 130 lines to ~65 lines using CardContainer + CardMetric
struct ReadinessCardViewV2: View {
    let readinessScore: ReadinessScore
    let onTap: () -> Void
    
    private var badgeStyle: VRBadge.Style {
        switch readinessScore.band {
        case .fullyReady, .veryReady:
            return .success
        case .ready:
            return .info
        case .limited:
            return .warning
        case .notReady:
            return .error
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            CardContainer(
                header: CardHeader(
                    title: ReadinessContent.title,
                    subtitle: readinessScore.band.trainingRecommendation,
                    badge: .init(
                        text: readinessScore.band.rawValue.uppercased(),
                        style: badgeStyle
                    ),
                    action: .init(icon: Icons.System.chevronRight, action: onTap)
                )
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    // Main score with icon
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: Icons.Activity.running)
                            .font(.title)
                            .foregroundColor(readinessScore.band.colorToken)
                        
                        CardMetric(
                            value: "\(readinessScore.score)",
                            label: readinessScore.band.rawValue,
                            size: .large
                        )
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
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Small pill showing component score (reused from original)
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

#Preview("Fully Ready") {
    let mockReadiness = ReadinessScore(
        score: 92,
        band: .fullyReady,
        components: ReadinessScore.Components(
            recoveryScore: 95,
            sleepScore: 88,
            loadReadiness: 90,
            recoveryWeight: 0.4,
            sleepWeight: 0.35,
            loadWeight: 0.25
        ),
        calculatedAt: Date()
    )
    
    return ReadinessCardViewV2(readinessScore: mockReadiness, onTap: {})
        .padding()
}

#Preview("Ready") {
    let mockReadiness = ReadinessScore(
        score: 82,
        band: .ready,
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
    
    return ReadinessCardViewV2(readinessScore: mockReadiness, onTap: {})
        .padding()
}

#Preview("Limited") {
    let mockReadiness = ReadinessScore(
        score: 58,
        band: .limited,
        components: ReadinessScore.Components(
            recoveryScore: 65,
            sleepScore: 55,
            loadReadiness: 50,
            recoveryWeight: 0.4,
            sleepWeight: 0.35,
            loadWeight: 0.25
        ),
        calculatedAt: Date()
    )
    
    return ReadinessCardViewV2(readinessScore: mockReadiness, onTap: {})
        .padding()
}
