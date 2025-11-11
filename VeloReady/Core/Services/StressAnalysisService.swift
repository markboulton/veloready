import Foundation
import Combine
import SwiftUI

/// Service for stress analysis and monitoring
/// Provides mock data for testing until full implementation
class StressAnalysisService: ObservableObject {
    static let shared = StressAnalysisService()
    
    @Published private(set) var currentAlert: StressAlert?
    @Published private(set) var isAnalyzing = false
    
    private let logger = Logger.self
    
    private init() {
        // Initialize service
        logger.debug("🧠 [StressAnalysisService] Initialized")
    }
    
    // MARK: - Public Methods
    
    /// Analyze stress levels and generate alert if needed
    func analyzeStress() async {
        logger.debug("🧠 [StressAnalysisService] Starting stress analysis")
        
        await MainActor.run {
            isAnalyzing = true
        }
        
        // Simulate analysis delay
        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
        
        // TODO: Implement real stress calculation
        // For now, return nil (no alert)
        await MainActor.run {
            currentAlert = nil
            isAnalyzing = false
        }
        
        logger.debug("🧠 [StressAnalysisService] Analysis complete - no alert")
    }
    
    /// Get recovery factors for the factors card
    @MainActor
    func getRecoveryFactors() -> [RecoveryFactor] {
        // Get real data from services
        let recoveryService = RecoveryScoreService.shared
        let sleepService = SleepScoreService.shared
        
        var factors: [RecoveryFactor] = []
        
        // Add stress factor (highest priority - will appear at top)
        if let alert = currentAlert {
            // Calculate stress score (inverted - lower stress = higher score)
            let stressScore = 100 - alert.chronicStress
            factors.append(RecoveryFactor(
                type: .stress,
                value: stressScore,
                status: stressStatusForValue(stressScore),
                weight: 0.5 // Highest weight to appear first
            ))
        } else {
            // Default to good stress level when no alert
            factors.append(RecoveryFactor(
                type: .stress,
                value: 75,
                status: .good,
                weight: 0.5 // Highest weight to appear first
            ))
        }
        
        // Add HRV factor
        if let recovery = recoveryService.currentRecoveryScore {
            factors.append(RecoveryFactor(
                type: .hrv,
                value: recovery.subScores.hrv,
                status: statusForScore(recovery.subScores.hrv),
                weight: 0.4
            ))
            
            // Add RHR factor
            factors.append(RecoveryFactor(
                type: .rhr,
                value: recovery.subScores.rhr,
                status: statusForScore(recovery.subScores.rhr),
                weight: 0.3
            ))
            
            // Add Form factor
            factors.append(RecoveryFactor(
                type: .form,
                value: recovery.subScores.form,
                status: statusForScore(recovery.subScores.form),
                weight: 0.1
            ))
        }
        
        // Add sleep factor
        if let sleep = sleepService.currentSleepScore {
            factors.append(RecoveryFactor(
                type: .sleep,
                value: sleep.score,
                status: statusForScore(sleep.score),
                weight: 0.2
            ))
        }
        
        // Sort by weight (most important first)
        return factors.sorted { $0.weight > $1.weight }
    }
    
    // MARK: - Mock Data (for Debug Testing)
    
    /// Generate mock stress alert for testing
    func generateMockAlert() -> StressAlert {
        logger.debug("🧠 [StressAnalysisService] Generating mock stress alert")
        
        let contributors = [
            StressContributor(
                name: StressContent.Contributors.trainingLoad,
                type: .trainingLoad,
                value: 78,
                points: 28,
                description: StressContent.Contributors.trainingLoadDescription(atlCtlRatio: 1.3),
                status: .high
            ),
            StressContributor(
                name: StressContent.Contributors.sleepQuality,
                type: .sleepQuality,
                value: 65,
                points: 15,
                description: StressContent.Contributors.sleepQualityDescription(wakeEvents: 4, hours: 6.5),
                status: .elevated
            ),
            StressContributor(
                name: StressContent.Contributors.hrv,
                type: .hrv,
                value: 52,
                points: 12,
                description: StressContent.Contributors.hrvDescription(deviationPercent: -18),
                status: .elevated
            ),
            StressContributor(
                name: StressContent.Contributors.temperature,
                type: .temperature,
                value: 58,
                points: 8,
                description: StressContent.Contributors.temperatureDescription(deviationC: 0.6),
                status: .elevated
            )
        ]
        
        return StressAlert(
            severity: .elevated,
            acuteStress: 72,
            chronicStress: 78,
            trend: .increasing,
            contributors: contributors,
            recommendation: """
            You've completed a 3-week build phase with high training volume. \
            Your body is showing normal signs of accumulated training stress.
            """,
            detectedAt: Date()
        )
    }
    
    /// Enable mock alert for testing
    @MainActor
    func enableMockAlert() {
        logger.debug("🧠 [StressAnalysisService] Enabling mock stress alert")
        currentAlert = generateMockAlert()
    }
    
    /// Disable mock alert
    @MainActor
    func disableMockAlert() {
        logger.debug("🧠 [StressAnalysisService] Disabling mock stress alert")
        currentAlert = nil
    }
    
    // MARK: - Private Methods
    
    private func statusForScore(_ score: Int) -> RecoveryFactor.Status {
        switch score {
        case 80...100:
            return .optimal
        case 60..<80:
            return .good
        case 40..<60:
            return .fair
        default:
            return .low
        }
    }
    
    private func stressStatusForValue(_ value: Int) -> RecoveryFactor.Status {
        // Inverted scale for stress - lower stress = better status
        switch value {
        case 70...100:
            return .optimal  // Low stress (good)
        case 50..<70:
            return .good     // Moderate stress
        case 30..<50:
            return .fair     // Elevated stress
        default:
            return .low      // High stress (bad)
        }
    }
}

