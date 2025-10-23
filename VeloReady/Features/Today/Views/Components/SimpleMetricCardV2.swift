import SwiftUI

/// Simple metric card using new atomic components
/// Reduces from 153 lines to ~80 lines using CardContainer
struct SimpleMetricCardV2: View {
    enum MetricType {
        case sleepConsistency(SleepConsistency)
        case resilience(ResilienceScore)
        
        var title: String {
            switch self {
            case .sleepConsistency: return "Sleep Consistency"
            case .resilience: return "Resilience"
            }
        }
        
        var icon: String {
            switch self {
            case .sleepConsistency: return "clock.fill"
            case .resilience: return "figure.strengthtraining.traditional"
            }
        }
        
        var score: Int {
            switch self {
            case .sleepConsistency(let consistency): return consistency.score
            case .resilience(let resilience): return resilience.score
            }
        }
        
        var color: Color {
            switch self {
            case .sleepConsistency(let consistency): return consistency.band.colorToken
            case .resilience(let resilience): return resilience.band.colorToken
            }
        }
        
        var bandName: String {
            switch self {
            case .sleepConsistency(let consistency): return consistency.band.rawValue
            case .resilience(let resilience): return resilience.band.rawValue
            }
        }
        
        var badgeStyle: VRBadge.Style {
            // Map band to badge style
            let band = bandName.lowercased()
            if band.contains("excellent") || band.contains("optimal") {
                return .success
            } else if band.contains("good") {
                return .info
            } else if band.contains("fair") {
                return .warning
            } else {
                return .error
            }
        }
        
        var description: String {
            switch self {
            case .sleepConsistency(let consistency): return consistency.band.description
            case .resilience(let resilience): return resilience.band.description
            }
        }
        
        var detailText: String {
            switch self {
            case .sleepConsistency(let consistency):
                return "±\(Int(consistency.bedtimeVariability))min variability"
            case .resilience(let resilience):
                return String(format: "%.1f avg recovery", resilience.averageRecovery)
            }
        }
    }
    
    let metricType: MetricType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            CardContainer(
                header: CardHeader(
                    title: metricType.title,
                    badge: .init(
                        text: metricType.bandName.uppercased(),
                        style: metricType.badgeStyle
                    ),
                    action: .init(icon: Icons.System.chevronRight, action: onTap)
                ),
                footer: CardFooter(text: metricType.detailText)
            ) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Score with icon
                    HStack(alignment: .center, spacing: Spacing.sm) {
                        Image(systemName: metricType.icon)
                            .font(.title)
                            .foregroundColor(metricType.color)
                        
                        CardMetric(
                            value: "\(metricType.score)",
                            label: metricType.description,
                            size: .large
                        )
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Sleep Consistency") {
    let consistency = SleepConsistency(
        score: 85,
        band: .excellent,
        bedtimeVariability: 25.0,
        wakeTimeVariability: 20.0,
        calculatedAt: Date()
    )
    
    return SimpleMetricCardV2(
        metricType: .sleepConsistency(consistency),
        onTap: {}
    )
    .padding()
}

#Preview("Resilience") {
    let resilience = ResilienceScore(
        score: 72,
        band: .good,
        averageRecovery: 68.5,
        averageLoad: 8.2,
        recoveryEfficiency: 1.2,
        calculatedAt: Date()
    )
    
    return SimpleMetricCardV2(
        metricType: .resilience(resilience),
        onTap: {}
    )
    .padding()
}

#Preview("Both Metrics") {
    VStack(spacing: Spacing.lg) {
        let consistency = SleepConsistency(
            score: 85,
            band: .excellent,
            bedtimeVariability: 25.0,
            wakeTimeVariability: 20.0,
            calculatedAt: Date()
        )
        
        let resilience = ResilienceScore(
            score: 72,
            band: .good,
            averageRecovery: 68.5,
            averageLoad: 8.2,
            recoveryEfficiency: 1.2,
            calculatedAt: Date()
        )
        
        SimpleMetricCardV2(metricType: .sleepConsistency(consistency), onTap: {})
        SimpleMetricCardV2(metricType: .resilience(resilience), onTap: {})
    }
    .padding()
}
