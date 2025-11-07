import SwiftUI

/// Alert banner showing illness indicator when detected
struct IllnessAlertBanner: View {
    @ObservedObject private var illnessService = IllnessDetectionService.shared
    
    var body: some View {
        if let indicator = illnessService.currentIndicator, indicator.isSignificant {
            VStack(spacing: Spacing.xs / 2) {
                HStack(spacing: Spacing.xs) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(severityColor(indicator.severity).opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: indicator.severity.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(severityColor(indicator.severity))
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text("Body Stress Detected")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("\(indicator.severity.rawValue)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(severityColor(indicator.severity))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(severityColor(indicator.severity).opacity(0.15))
                                .cornerRadius(4)
                        }
                        
                        Text(indicator.recommendation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Show signals
                        if !indicator.signals.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(indicator.signals.prefix(3)) { signal in
                                    HStack(spacing: Spacing.xs) {
                                        Image(systemName: signal.type.icon)
                                            .font(.caption2)
                                        Text(signal.type.rawValue)
                                            .font(.caption2)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                
                                if indicator.signals.count > 3 {
                                    Text("+\(indicator.signals.count - 3)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding()
                .background(severityColor(indicator.severity).opacity(0.05))
                .overlay(
                    Rectangle()
                        .frame(width: 4)
                        .foregroundColor(severityColor(indicator.severity)),
                    alignment: .leading
                )
            }
        }
    }
    
    private func severityColor(_ severity: IllnessIndicator.Severity) -> Color {
        switch severity {
        case .low: return ColorScale.yellowAccent
        case .moderate: return ColorScale.amberAccent
        case .high: return ColorScale.redAccent
        }
    }
}

// MARK: - Preview

struct IllnessAlertBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            IllnessAlertBanner()
                .onAppear {
                    // Mock high severity indicator
                    IllnessDetectionService.shared.currentIndicator = IllnessIndicator(
                        date: Date(),
                        severity: .high,
                        confidence: 0.82,
                        signals: [
                            IllnessIndicator.Signal(
                                type: .hrvSpike,
                                deviation: 220,
                                value: 141,
                                baseline: 44
                            ),
                            IllnessIndicator.Signal(
                                type: .sleepDisruption,
                                deviation: -5,
                                value: 80,
                                baseline: 84
                            )
                        ],
                        recommendation: "Significant body stress detected. Rest is strongly recommended. Consult a healthcare provider if you feel unwell."
                    )
                }
            
            Spacer()
        }
        .padding()
    }
}
