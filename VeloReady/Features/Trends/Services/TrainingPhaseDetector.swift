import Foundation

/// Detects training phases from intensity distribution and volume patterns
struct TrainingPhaseDetector {
    
    // MARK: - Training Phase
    
    enum TrainingPhase: String {
        case base = "Base"
        case build = "Build"
        case peak = "Peak"
        case recovery = "Recovery"
        case transition = "Transition"
        
        var description: String {
            switch self {
            case .base:
                return TrendsContent.TrainingPhases.baseDescription
            case .build:
                return TrendsContent.TrainingPhases.buildDescription
            case .peak:
                return TrendsContent.TrainingPhases.peakDescription
            case .recovery:
                return TrendsContent.TrainingPhases.recoveryDescription
            case .transition:
                return TrendsContent.TrainingPhases.transitionDescription
            }
        }
        
        var icon: String {
            switch self {
            case .base: return "arrow.up.circle.fill"
            case .build: return "figure.strengthtraining.traditional"
            case .peak: return "bolt.fill"
            case .recovery: return "bed.double.fill"
            case .transition: return "arrow.triangle.2.circlepath"
            }
        }
        
        var color: String {
            switch self {
            case .base: return "chart.primary"
            case .build: return "workout.tss"
            case .peak: return "strain.extreme"
            case .recovery: return "recovery.green"
            case .transition: return "text.secondary"
            }
        }
    }
    
    struct PhaseDetectionResult {
        let phase: TrainingPhase
        let confidence: Double  // 0-1
        let weeklyTSS: Double
        let lowIntensityPercent: Double  // Z1-Z2
        let highIntensityPercent: Double // Z4-Z7
        let recommendation: String
    }
    
    // MARK: - Detection Logic
    
    /// Detect current training phase from recent activity data
    static func detectPhase(
        weeklyTSS: Double,
        lowIntensityPercent: Double,  // % of time in Z1-Z2
        highIntensityPercent: Double  // % of time in Z4-Z7
    ) -> PhaseDetectionResult {
        
        // Base Phase: High volume, mostly easy
        if lowIntensityPercent > 70 && weeklyTSS > 300 {
            return PhaseDetectionResult(
                phase: .base,
                confidence: min(lowIntensityPercent / 100, 0.95),
                weeklyTSS: weeklyTSS,
                lowIntensityPercent: lowIntensityPercent,
                highIntensityPercent: highIntensityPercent,
                recommendation: TrendsContent.TrainingPhases.baseRecommendation
            )
        }
        
        // Recovery Phase: Low volume
        if weeklyTSS < 200 {
            return PhaseDetectionResult(
                phase: .recovery,
                confidence: 0.8,
                weeklyTSS: weeklyTSS,
                lowIntensityPercent: lowIntensityPercent,
                highIntensityPercent: highIntensityPercent,
                recommendation: TrendsContent.TrainingPhases.recoveryRecommendation
            )
        }
        
        // Peak Phase: High intensity
        if highIntensityPercent > 25 {
            return PhaseDetectionResult(
                phase: .peak,
                confidence: min(highIntensityPercent / 40, 0.9),
                weeklyTSS: weeklyTSS,
                lowIntensityPercent: lowIntensityPercent,
                highIntensityPercent: highIntensityPercent,
                recommendation: TrendsContent.TrainingPhases.peakRecommendation
            )
        }
        
        // Build Phase: Balanced intensity
        if highIntensityPercent >= 15 && highIntensityPercent <= 25 && weeklyTSS >= 300 {
            return PhaseDetectionResult(
                phase: .build,
                confidence: 0.75,
                weeklyTSS: weeklyTSS,
                lowIntensityPercent: lowIntensityPercent,
                highIntensityPercent: highIntensityPercent,
                recommendation: TrendsContent.TrainingPhases.buildRecommendation
            )
        }
        
        // Transition: Everything else
        return PhaseDetectionResult(
            phase: .transition,
            confidence: 0.5,
            weeklyTSS: weeklyTSS,
            lowIntensityPercent: lowIntensityPercent,
            highIntensityPercent: highIntensityPercent,
            recommendation: TrendsContent.TrainingPhases.transitionRecommendation
        )
    }
}
