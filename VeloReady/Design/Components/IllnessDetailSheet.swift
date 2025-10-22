import SwiftUI

/// Detailed sheet view for illness indicators
/// Shows comprehensive information about detected patterns and recommendations
struct IllnessDetailSheet: View {
    let indicator: IllnessIndicator
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    // Header with severity and confidence
                    headerSection
                    
                    // Medical disclaimer
                    disclaimerSection
                    
                    // What we detected
                    detectedPatternsSection
                    
                    // All affected signals
                    allSignalsSection
                    
                    // Recommendations
                    recommendationsSection
                    
                    // When to seek medical advice
                    medicalAdviceSection
                }
                .padding(Spacing.lg)
            }
            .background(ColorScale.backgroundPrimary)
            .navigationTitle(WellnessContent.IllnessDetection.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticFeedback.light()
                        dismiss()
                    }) {
                        Image(systemName: Icons.Navigation.close)
                            .foregroundColor(ColorScale.labelSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        HStack(spacing: Spacing.md) {
            // Severity icon
            ZStack {
                Circle()
                    .fill(severityColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: indicator.severity.icon)
                    .font(.title2)
                    .foregroundColor(severityColor)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(severityTitle)
                    .font(.title3.weight(.bold))
                    .foregroundColor(ColorScale.labelPrimary)
                
                Text(confidenceText)
                    .font(.body)
                    .foregroundColor(ColorScale.labelSecondary)
                
                Text("Detected \(timeAgoText)")
                    .font(.caption)
                    .foregroundColor(ColorScale.labelTertiary)
            }
            
            Spacer()
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                .fill(severityColor.opacity(0.08))
        )
    }
    
    private var disclaimerSection: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: Icons.Status.info)
                .font(.title3)
                .foregroundColor(ColorScale.labelSecondary)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Important")
                    .font(.body.weight(.semibold))
                    .foregroundColor(ColorScale.labelPrimary)
                
                Text(WellnessContent.IllnessDetection.notMedicalDiagnosis)
                    .font(.caption)
                    .foregroundColor(ColorScale.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                .fill(ColorScale.backgroundSecondary)
        )
    }
    
    private var detectedPatternsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("What We Detected")
                .font(.title3.weight(.bold))
                .foregroundColor(ColorScale.labelPrimary)
            
            Text(WellnessContent.IllnessDetection.patternsDetected)
                .font(.body)
                .foregroundColor(ColorScale.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            if indicator.signals.count >= 2 {
                Text(WellnessContent.IllnessDetection.multiDayTrend)
                    .font(.body)
                    .foregroundColor(ColorScale.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var allSignalsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Affected Metrics (\(indicator.signals.count))")
                .font(.title3.weight(.bold))
                .foregroundColor(ColorScale.labelPrimary)
            
            VStack(spacing: Spacing.sm) {
                ForEach(indicator.signals) { signal in
                    signalDetailCard(signal: signal)
                }
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recommendations")
                .font(.title3.weight(.bold))
                .foregroundColor(ColorScale.labelPrimary)
            
            let recommendations = WellnessContent.IllnessDetection.recommendations(for: indicator.severity.rawValue)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: Icons.Status.checkmark)
                            .font(.caption)
                            .foregroundColor(severityColor)
                            .padding(.top, 2)
                        
                        Text(recommendation)
                            .font(.body)
                            .foregroundColor(ColorScale.labelPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                    .fill(ColorScale.backgroundSecondary)
            )
        }
    }
    
    private var medicalAdviceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: Icons.Status.warning)
                    .foregroundColor(ColorScale.redAccent)
                
                Text("When to Seek Medical Advice")
                    .font(.body.weight(.semibold))
                    .foregroundColor(ColorScale.labelPrimary)
            }
            
            Text(WellnessContent.Recommendations.medicalDisclaimer)
                .font(.caption)
                .foregroundColor(ColorScale.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if indicator.severity == .high {
                Text("Given the significance of these changes, we recommend consulting a healthcare provider if you're feeling unwell.")
                    .font(.caption)
                    .foregroundColor(ColorScale.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                .fill(ColorScale.redAccent.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                        .stroke(ColorScale.redAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Views
    
    private func signalDetailCard(signal: IllnessIndicator.Signal) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: signal.type.icon)
                    .font(.title3)
                    .foregroundColor(severityColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(signal.type.rawValue)
                        .font(.body.weight(.semibold))
                        .foregroundColor(ColorScale.labelPrimary)
                    
                    Text(deviationText(for: signal))
                        .font(.caption)
                        .foregroundColor(severityColor)
                }
                
                Spacer()
            }
            
            Text(detailDescription(for: signal.type))
                .font(.caption)
                .foregroundColor(ColorScale.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                .fill(ColorScale.backgroundSecondary)
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
    
    private var severityTitle: String {
        switch indicator.severity {
        case .low:
            return "Low Severity Indicators"
        case .moderate:
            return "Moderate Body Stress"
        case .high:
            return "Significant Stress Signals"
        }
    }
    
    private var confidenceText: String {
        let percentage = Int(indicator.confidence * 100)
        return "\(percentage)% confidence in detection"
    }
    
    private var timeAgoText: String {
        let interval = Date().timeIntervalSince(indicator.date)
        let hours = Int(interval / 3600)
        
        if hours < 1 {
            return "just now"
        } else if hours == 1 {
            return "1 hour ago"
        } else if hours < 24 {
            return "\(hours) hours ago"
        } else {
            let days = hours / 24
            return days == 1 ? "1 day ago" : "\(days) days ago"
        }
    }
    
    private func deviationText(for signal: IllnessIndicator.Signal) -> String {
        let percentChange = abs(signal.deviation)
        let direction = signal.deviation > 0 ? "↑" : "↓"
        return "\(direction) \(String(format: "%.1f", percentChange))% from baseline"
    }
    
    private func detailDescription(for signalType: IllnessIndicator.Signal.SignalType) -> String {
        switch signalType {
        case .hrvDrop:
            return WellnessContent.IllnessDetection.hrvDropDetail
        case .hrvSpike:
            return "Unusually elevated HRV may indicate your body is responding to stress or inflammation. This can occur when the body is fighting infection."
        case .elevatedRHR:
            return WellnessContent.IllnessDetection.elevatedRHRDetail
        case .respiratoryRate:
            return WellnessContent.IllnessDetection.respiratoryChangeDetail
        case .sleepDisruption:
            return WellnessContent.IllnessDetection.sleepDisruptionDetail
        case .activityDrop:
            return WellnessContent.IllnessDetection.activityDropDetail
        case .temperatureElevation:
            return WellnessContent.IllnessDetection.temperatureElevationDetail
        }
    }
}

// MARK: - Design Tokens
// Using global Spacing enum from Core/Design/Spacing.swift
// Using global Typography from Core/Design/Typography.swift

// MARK: - Preview

struct IllnessDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        IllnessDetailSheet(
            indicator: IllnessIndicator(
                date: Date().addingTimeInterval(-7200), // 2 hours ago
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
                    ),
                    IllnessIndicator.Signal(
                        type: .sleepDisruption,
                        deviation: -25.5,
                        value: 65.0,
                        baseline: 87.2
                    )
                ],
                recommendation: "Take it easy with training - light activity or rest"
            )
        )
    }
}
