import SwiftUI

/// Card displaying auto-detected training phase
struct TrainingPhaseCard: View {
    let phase: TrainingPhaseDetector.PhaseDetectionResult?
    
    var body: some View {
        Card(style: .elevated) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(TrendsContent.Cards.trainingPhase)
                            .font(.heading)
                            .foregroundColor(.text.primary)
                        
                        if let phase = phase {
                            Text(phase.phase.rawValue)
                                .font(.title)
                                .foregroundColor(phaseColor(phase.phase))
                        } else {
                            Text(CommonContent.States.detecting)
                                .font(.body)
                                .foregroundColor(.text.secondary)
                        }
                    }
                    
                    Spacer()
                    
                }
                
                if let phase = phase {
                    phaseContent(phase)
                } else {
                    emptyState
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 40))
                .foregroundColor(.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                Text(TrendsContent.TrainingPhase.noData)
                    .font(.body)
                    .foregroundColor(.text.secondary)
                
                Text(TrendsContent.TrainingPhase.fourWeeks)
                    .font(.caption)
                    .foregroundColor(.text.tertiary)
                
                Text(TrendsContent.TrainingPhase.requires)
                    .font(.caption)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.TrainingPhase.consistentTraining)
                    }
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.TrainingPhase.powerOrHR)
                    }
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.TrainingPhase.varietyIntensities)
                    }
                }
                .font(.caption)
                .foregroundColor(.text.tertiary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    private func phaseContent(_ phase: TrainingPhaseDetector.PhaseDetectionResult) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Phase description
            Text(phase.phase.description)
                .font(.body)
                .foregroundColor(.text.secondary)
            
            // Metrics
            HStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(TrendsContent.TrainingLoad.weeklyTSS)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    
                    Text("\(Int(phase.weeklyTSS))")
                        .font(.heading)
                        .foregroundColor(.text.primary)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Low Intensity")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    
                    Text("\(Int(phase.lowIntensityPercent))%")
                        .font(.heading)
                        .foregroundColor(.text.primary)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("High Intensity")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    
                    Text("\(Int(phase.highIntensityPercent))%")
                        .font(.heading)
                        .foregroundColor(.text.primary)
                }
                
                Spacer()
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(Color.background.secondary)
            .cornerRadius(Spacing.buttonCornerRadius)
            
            // Confidence
            HStack {
                Text("Confidence:")
                    .font(.caption)
                    .foregroundColor(.text.secondary)
                
                Text("\(Int(phase.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(confidenceColor(phase.confidence))
                
                Spacer()
                
                // Confidence bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.background.secondary)
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(confidenceColor(phase.confidence))
                            .frame(width: geometry.size.width * phase.confidence, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
                .frame(width: 80)
            }
            
            Divider()
            
            // Recommendation
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(TrendsContent.recommendation)
                    .font(.caption)
                    .foregroundColor(.text.secondary)
                
                Text(phase.recommendation)
                    .font(.body)
                    .foregroundColor(.text.secondary)
            }
        }
    }
    
    private func phaseColor(_ phase: TrainingPhaseDetector.TrainingPhase) -> Color {
        switch phase {
        case .base:
            return ColorScale.blueAccent
        case .build:
            return ColorScale.purpleAccent
        case .peak:
            return ColorScale.redAccent
        case .recovery:
            return ColorScale.greenAccent
        case .transition:
            return Color.text.secondary
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence > 0.75 {
            return Color.semantic.success
        } else if confidence > 0.5 {
            return Color.semantic.warning
        } else {
            return Color.text.tertiary
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // Build phase
            TrainingPhaseCard(
                phase: TrainingPhaseDetector.PhaseDetectionResult(
                    phase: .build,
                    confidence: 0.75,
                    weeklyTSS: 450,
                    lowIntensityPercent: 65,
                    highIntensityPercent: 20,
                    recommendation: "Build phase: Good mix of volume and intensity. Maintain consistency."
                )
            )
            
            // Empty
            TrainingPhaseCard(phase: nil)
        }
        .padding()
    }
    .background(Color.background.primary)
}
