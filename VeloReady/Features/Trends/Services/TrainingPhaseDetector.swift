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
                return "Base phase detected: High volume, low intensity (>70% Zone 1-2)"
            case .build:
                return "Build phase detected: Mixed intensity with threshold work (15-25% Zone 4-5)"
            case .peak:
                return "Peak phase detected: High intensity, reduced volume (>25% Zone 4-7)"
            case .recovery:
                return "Recovery phase detected: Low volume and intensity"
            case .transition:
                return "Transition phase: Mixed training without clear pattern"
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
                recommendation: "Continue building aerobic base. Keep 70%+ time in Zone 1-2."
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
                recommendation: "Recovery phase active. Consider increasing volume gradually if rested."
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
                recommendation: "Peak phase: Race-specific intensity. Ensure adequate recovery between hard sessions."
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
                recommendation: "Build phase: Good mix of volume and intensity. Maintain consistency."
            )
        }
        
        // Transition: Everything else
        return PhaseDetectionResult(
            phase: .transition,
            confidence: 0.5,
            weeklyTSS: weeklyTSS,
            lowIntensityPercent: lowIntensityPercent,
            highIntensityPercent: highIntensityPercent,
            recommendation: "No clear training phase detected. Consider following a structured training plan."
        )
    }
}
