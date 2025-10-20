import SwiftUI

/// Simple metric card for consistency and resilience scores
struct SimpleMetricCard: View {
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
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: metricType.icon)
                        .font(.title3)
                        .foregroundColor(metricType.color)
                    
                    Text(metricType.title)
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
                    Text("\(metricType.score)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(metricType.color)
                    
                    Text(CommonContent.Formatting.outOf100)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.labelTertiary)
                }
                
                // Band
                Text(metricType.bandName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(metricType.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(metricType.color.opacity(0.1))
                    .cornerRadius(4)
                
                // Description
                Text(metricType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Detail
                Text(metricType.detailText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ColorPalette.backgroundSecondary)
            .cornerRadius(0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct SimpleMetricCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
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
            
            SimpleMetricCard(metricType: .sleepConsistency(consistency), onTap: {})
            SimpleMetricCard(metricType: .resilience(resilience), onTap: {})
        }
        .padding()
    }
}
