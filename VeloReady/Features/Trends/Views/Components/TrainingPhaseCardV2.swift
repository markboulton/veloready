import SwiftUI

/// Training Phase card using atomic CardContainer wrapper
/// Auto-detects training phase (Base/Build/Peak/Recovery/Transition)
/// Shows confidence, metrics, intensity breakdown, and recommendations
struct TrainingPhaseCardV2: View {
    let phase: TrainingPhaseDetector.PhaseDetectionResult?
    
    private var badge: CardHeader.Badge? {
        guard let phase = phase else { return nil }
        
        if phase.confidence > 0.75 {
            return .init(text: "HIGH", style: .success)
        } else if phase.confidence > 0.5 {
            return .init(text: "MODERATE", style: .info)
        } else {
            return .init(text: "LOW", style: .warning)
        }
    }
    
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: TrendsContent.Cards.trainingPhase,
                subtitle: phase?.phase.rawValue ?? CommonContent.States.detecting,
                badge: badge
            ),
            style: .standard
        ) {
            if let phase = phase {
                phaseContentView(phase)
            } else {
                emptyStateView
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: Icons.Activity.runningCircle)
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                VRText(
                    TrendsContent.TrainingPhase.noData,
                    style: .body,
                    color: Color.text.secondary
                )
                .multilineTextAlignment(.center)
                
                VRText(
                    TrendsContent.TrainingPhase.fourWeeks,
                    style: .caption,
                    color: Color.text.tertiary
                )
                
                VRText(
                    TrendsContent.TrainingPhase.requires,
                    style: .caption,
                    color: Color.text.tertiary
                )
                .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.TrainingPhase.consistentTraining, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.TrainingPhase.powerOrHR, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.TrainingPhase.varietyIntensities, style: .caption, color: Color.text.tertiary)
                    }
                }
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Phase Content
    
    private func phaseContentView(_ phase: TrainingPhaseDetector.PhaseDetectionResult) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Phase description
            VRText(
                phase.phase.description,
                style: .body,
                color: Color.text.secondary
            )
            
            // Metrics panel
            metricsPanel(phase)
            
            // Confidence indicator
            confidenceIndicator(phase.confidence)
            
            Divider()
            
            // Recommendation
            VStack(alignment: .leading, spacing: Spacing.xs) {
                VRText(
                    TrendsContent.recommendation,
                    style: .caption,
                    color: Color.text.secondary
                )
                
                VRText(
                    phase.recommendation,
                    style: .body,
                    color: Color.text.secondary
                )
            }
        }
    }
    
    // MARK: - Metrics Panel
    
    private func metricsPanel(_ phase: TrainingPhaseDetector.PhaseDetectionResult) -> some View {
        HStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                VRText(
                    TrendsContent.TrainingLoad.weeklyTSS,
                    style: .caption,
                    color: Color.text.secondary
                )
                
                VRText(
                    "\(Int(phase.weeklyTSS))",
                    style: .headline,
                    color: Color.text.primary
                )
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                VRText(
                    CommonContent.Intensity.low,
                    style: .caption,
                    color: Color.text.secondary
                )
                
                VRText(
                    "\(Int(phase.lowIntensityPercent))%",
                    style: .headline,
                    color: Color.text.primary
                )
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                VRText(
                    CommonContent.Intensity.high,
                    style: .caption,
                    color: Color.text.secondary
                )
                
                VRText(
                    "\(Int(phase.highIntensityPercent))%",
                    style: .headline,
                    color: Color.text.primary
                )
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(Color.background.secondary)
        .cornerRadius(Spacing.buttonCornerRadius)
    }
    
    // MARK: - Confidence Indicator
    
    private func confidenceIndicator(_ confidence: Double) -> some View {
        HStack {
            VRText(
                CommonContent.Labels.confidence,
                style: .caption,
                color: Color.text.secondary
            )
            
            VRText(
                "\(Int(confidence * 100))%",
                style: .caption,
                color: confidenceColor(confidence)
            )
            
            Spacer()
            
            // Confidence bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.background.secondary)
                        .frame(height: 2)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(confidenceColor(confidence))
                        .frame(width: geometry.size.width * confidence, height: 2)
                        .cornerRadius(2)
                }
            }
            .frame(height: 2)
            .frame(width: 80)
        }
    }
    
    // MARK: - Helper Methods
    
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

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // Build phase - high confidence
            TrainingPhaseCardV2(
                phase: TrainingPhaseDetector.PhaseDetectionResult(
                    phase: .build,
                    confidence: 0.85,
                    weeklyTSS: 450,
                    lowIntensityPercent: 65,
                    highIntensityPercent: 20,
                    recommendation: "Build phase: Good mix of volume and intensity. Maintain consistency."
                )
            )
            
            // Peak phase - moderate confidence
            TrainingPhaseCardV2(
                phase: TrainingPhaseDetector.PhaseDetectionResult(
                    phase: .peak,
                    confidence: 0.62,
                    weeklyTSS: 380,
                    lowIntensityPercent: 45,
                    highIntensityPercent: 35,
                    recommendation: "Peak phase: High intensity work. Ensure adequate recovery between sessions."
                )
            )
            
            // Recovery phase - high confidence
            TrainingPhaseCardV2(
                phase: TrainingPhaseDetector.PhaseDetectionResult(
                    phase: .recovery,
                    confidence: 0.78,
                    weeklyTSS: 180,
                    lowIntensityPercent: 85,
                    highIntensityPercent: 5,
                    recommendation: "Recovery phase: Prioritize easy efforts and allow adaptation."
                )
            )
            
            // Empty
            TrainingPhaseCardV2(phase: nil)
        }
        .padding()
    }
    .background(Color.background.primary)
}
