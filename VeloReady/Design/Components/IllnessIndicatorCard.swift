import SwiftUI

/// Card component for displaying illness detection indicators
/// Uses design tokens for colors, spacing, and typography
struct IllnessIndicatorCard: View {
    let indicator: IllnessIndicator
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header with severity indicator
                HStack(spacing: Spacing.sm) {
                    Image(systemName: indicator.severity.icon)
                        .font(.title3)
                        .foregroundColor(severityColor)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(WellnessContent.IllnessDetection.title)
                            .font(.body.weight(.semibold))
                            .foregroundColor(ColorScale.labelPrimary)
                        
                        Text(severityText)
                            .font(.caption)
                            .foregroundColor(ColorScale.labelSecondary)
                    }
                    
                    Spacer()
                    
                    // Confidence badge
                    confidenceBadge
                }
                
                // Primary signal (most significant)
                if let primarySignal = indicator.primarySignal {
                    signalRow(signal: primarySignal)
                }
                
                // Recommendation preview
                Text(indicator.recommendation)
                    .font(.caption)
                    .foregroundColor(ColorScale.labelSecondary)
                    .lineLimit(2)
                
                // View details CTA
                HStack {
                    Spacer()
                    Text(WellnessContent.IllnessDetection.viewDetails)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(severityColor)
                    
                    Image(systemName: Icons.System.chevronRight)
                        .font(.caption)
                        .foregroundColor(severityColor)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                    .fill(ColorScale.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                            .stroke(severityColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Subviews
    
    private var confidenceBadge: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(severityColor)
                .frame(width: 6, height: 6)
            
            Text(confidenceText)
                .font(.caption)
                .foregroundColor(ColorScale.labelSecondary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            Capsule()
                .fill(severityColor.opacity(0.1))
        )
    }
    
    private func signalRow(signal: IllnessIndicator.Signal) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: signal.type.icon)
                .font(.body)
                .foregroundColor(severityColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(signal.type.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(ColorScale.labelPrimary)
                
                Text(deviationText(for: signal))
                    .font(.caption)
                    .foregroundColor(ColorScale.labelSecondary)
            }
            
            Spacer()
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Spacing.buttonCornerRadius)
                .fill(severityColor.opacity(0.05))
        )
    }
    
    // MARK: - Computed Properties
    
    private var severityColor: Color {
        switch indicator.severity {
        case .low:
            return ColorScale.yellowAccent
        case .moderate:
            return ColorScale.amberAccent
        case .high:
            return ColorScale.redAccent
        }
    }
    
    private var severityText: String {
        switch indicator.severity {
        case .low:
            return CommonContent.IllnessIndicators.lowSeverity + " " + CommonContent.IllnessIndicators.monitoring.lowercased()
        case .moderate:
            return CommonContent.IllnessIndicators.moderateSeverity + " " + CommonContent.IllnessIndicators.detected.lowercased()
        case .high:
            return CommonContent.IllnessIndicators.highSeverity + " " + CommonContent.IllnessIndicators.detected.lowercased()
        }
    }
    
    private var confidenceText: String {
        let percentage = Int(indicator.confidence * 100)
        if percentage >= 75 {
            return WellnessContent.IllnessDetection.highConfidence
        } else if percentage >= 50 {
            return WellnessContent.IllnessDetection.moderateConfidence
        } else {
            return WellnessContent.IllnessDetection.lowConfidence
        }
    }
    
    private func deviationText(for signal: IllnessIndicator.Signal) -> String {
        let percentChange = abs(signal.deviation)
        let direction = signal.deviation > 0 ? "↑" : "↓"
        
        if let baseline = signal.baseline {
            return "\(direction) \(String(format: "%.0f", percentChange))% from baseline (\(String(format: "%.1f", baseline)))"
        } else {
            return "\(direction) \(String(format: "%.0f", percentChange))% deviation"
        }
    }
}

// MARK: - Design Tokens
// Using global Spacing enum from Core/Design/Spacing.swift
// Using global Typography from Core/Design/Typography.swift

// MARK: - Preview

struct IllnessIndicatorCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Low severity
            IllnessIndicatorCard(
                indicator: IllnessIndicator(
                    date: Date(),
                    severity: .low,
                    confidence: 0.65,
                    signals: [
                        IllnessIndicator.Signal(
                            type: .hrvDrop,
                            deviation: -18.5,
                            value: 45.2,
                            baseline: 55.4
                        )
                    ],
                    recommendation: "Monitor how you're feeling over the next day or two"
                ),
                onTap: {}
            )
            
            // Moderate severity
            IllnessIndicatorCard(
                indicator: IllnessIndicator(
                    date: Date(),
                    severity: .moderate,
                    confidence: 0.78,
                    signals: [
                        IllnessIndicator.Signal(
                            type: .elevatedRHR,
                            deviation: 12.3,
                            value: 62.0,
                            baseline: 55.2
                        ),
                        IllnessIndicator.Signal(
                            type: .hrvDrop,
                            deviation: -22.1,
                            value: 42.0,
                            baseline: 53.9
                        )
                    ],
                    recommendation: "Take it easy with training - light activity or rest"
                ),
                onTap: {}
            )
            
            // High severity
            IllnessIndicatorCard(
                indicator: IllnessIndicator(
                    date: Date(),
                    severity: .high,
                    confidence: 0.89,
                    signals: [
                        IllnessIndicator.Signal(
                            type: .elevatedRHR,
                            deviation: 15.8,
                            value: 65.0,
                            baseline: 56.1
                        ),
                        IllnessIndicator.Signal(
                            type: .hrvDrop,
                            deviation: -28.4,
                            value: 38.5,
                            baseline: 53.8
                        ),
                        IllnessIndicator.Signal(
                            type: .respiratoryRate,
                            deviation: 14.2,
                            value: 18.5,
                            baseline: 16.2
                        )
                    ],
                    recommendation: "Rest is strongly recommended today"
                ),
                onTap: {}
            )
        }
        .padding()
        .background(ColorScale.backgroundPrimary)
    }
}
