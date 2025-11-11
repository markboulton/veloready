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
        
        // Calculate real stress score
        let stressScore = await calculateStressScore()
        
        await MainActor.run {
            // Generate alert if stress is elevated or high
            if stressScore.acuteStress > 50 {  // Elevated threshold
                currentAlert = generateAlertFrom(stressScore)
                logger.debug("🧠 [StressAnalysisService] Generated stress alert - Acute: \(stressScore.acuteStress), Chronic: \(stressScore.chronicStress)")
            } else {
                currentAlert = nil
                logger.debug("🧠 [StressAnalysisService] No alert - stress within normal range (\(stressScore.acuteStress))")
            }
            isAnalyzing = false
        }
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
    
    /// Get stress trend data for chart
    @MainActor
    func getStressTrendData(for period: TrendPeriod) -> [TrendDataPoint] {
        // Generate mock trend data showing increasing stress
        let days = period.days
        var dataPoints: [TrendDataPoint] = []
        let calendar = Calendar.current
        
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: -days + i + 1, to: Date()) ?? Date()
            // Simulate increasing stress trend
            let base: Double = 30.0
            let increment: Double = Double(i) * (40.0 / Double(days))
            let noise: Double = Double.random(in: -5...5)
            let value = min(100, max(0, base + increment + noise))
            
            dataPoints.append(TrendDataPoint(
                date: date,
                value: value
            ))
        }
        
        return dataPoints
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
    
    // MARK: - Real Stress Calculations
    
    /// Internal struct to hold calculated stress scores before alert generation
    private struct StressScoreResult {
        let acuteStress: Int
        let chronicStress: Int
        let physiologicalStress: Double
        let recoveryDeficit: Double
        let sleepDisruption: Double
        let contributors: [ContributorData]
        
        struct ContributorData {
            let type: StressContributor.ContributorType
            let value: Int
            let points: Int
            let description: String
            let status: StressContributor.Status
        }
    }
    
    /// Calculate real stress score based on physiological metrics
    private func calculateStressScore() async -> StressScoreResult {
        // Get services - these are main actor isolated
        let recovery = await MainActor.run {
            RecoveryScoreService.shared.currentRecoveryScore
        }
        let sleep = await MainActor.run {
            SleepScoreService.shared.currentSleepScore
        }
        
        var contributors: [StressScoreResult.ContributorData] = []
        
        // COMPONENT 1: Physiological Stress (0-40 points)
        var physiologicalStress: Double = 0.0
        
        // HRV Stress (0-15 points)
        if let recovery = recovery,
           let hrvBaseline = recovery.inputs.hrvBaseline,
           let hrv = recovery.inputs.hrv,
           hrvBaseline > 0 {
            let hrvDeviation = (hrvBaseline - hrv) / hrvBaseline * 100 // Percentage drop
            let hrvStress = min(15.0, hrvDeviation * 0.5)
            physiologicalStress += hrvStress
            
            let hrvScore = 100 - Int(hrvDeviation)
            contributors.append(StressScoreResult.ContributorData(
                type: .hrv,
                value: max(0, hrvScore),
                points: Int(hrvStress),
                description: StressContent.Contributors.hrvDescription(deviationPercent: Int(-hrvDeviation)),
                status: hrvScore >= 70 ? .optimal : hrvScore >= 50 ? .good : .elevated
            ))
        }
        
        // RHR Stress (0-15 points)
        if let recovery = recovery,
           let rhrBaseline = recovery.inputs.rhrBaseline,
           let rhr = recovery.inputs.rhr,
           rhrBaseline > 0 {
            let rhrDeviation = (rhr - rhrBaseline) / rhrBaseline * 100 // Percentage increase
            let rhrStress = min(15.0, rhrDeviation * 1.5)
            physiologicalStress += rhrStress
            
            let rhrScore = 100 - Int(rhrDeviation * 2)
            contributors.append(StressScoreResult.ContributorData(
                type: .hrv,  // Changed from .rhr to .hrv since .rhr doesn't exist in ContributorType
                value: max(0, rhrScore),
                points: Int(rhrStress),
                description: "RHR \(Int(rhr)) bpm (baseline: \(Int(rhrBaseline)) bpm)",
                status: rhrScore >= 70 ? .optimal : rhrScore >= 50 ? .good : .elevated
            ))
        }
        
        // COMPONENT 2: Recovery Deficit (0-30 points)
        var recoveryDeficit: Double = 0.0
        var recoveryScore: Int = 70
        
        if let recovery = recovery {
            recoveryScore = recovery.score
            if recoveryScore < 70 {
                recoveryDeficit = min(30.0, Double(70 - recoveryScore) * 0.5)
            }
        }
        
        // COMPONENT 3: Sleep Disruption (0-30 points)
        var sleepDisruption: Double = 0.0
        var sleepScore: Int = 100
        var wakeEvents: Int = 0
        
        if let sleep = sleep {
            sleepScore = sleep.score
            wakeEvents = sleep.inputs.wakeEvents ?? 0
            
            let sleepBase = Double(100 - sleepScore) * 0.2 // Max 20 points
            let wakeEventsPenalty = min(10.0, Double(wakeEvents) * 2.0)
            sleepDisruption = sleepBase + wakeEventsPenalty
            
            let sleepDurationHours = (sleep.inputs.sleepDuration ?? 0) / 3600.0
            contributors.append(StressScoreResult.ContributorData(
                type: .sleepQuality,
                value: sleepScore,
                points: Int(sleepDisruption),
                description: StressContent.Contributors.sleepQualityDescription(
                    wakeEvents: wakeEvents,
                    hours: sleepDurationHours
                ),
                status: sleepScore >= 80 ? .optimal : sleepScore >= 60 ? .good : .elevated
            ))
        }
        
        // Calculate Training Load contribution (mock for now, will use real ATL/CTL when available)
        // TODO: Get real ATL/CTL from Intervals.icu
        let trainingLoadScore = 65
        contributors.append(StressScoreResult.ContributorData(
            type: .trainingLoad,
            value: trainingLoadScore,
            points: Int((100.0 - Double(trainingLoadScore)) * 0.3),
            description: "Recent training load is moderate",
            status: trainingLoadScore >= 70 ? .good : .elevated
        ))
        
        // Calculate Acute Stress (today's stress)
        let acuteStress = Int(min(100, physiologicalStress + recoveryDeficit + sleepDisruption))
        
        // Calculate Chronic Stress (7-day average - for now, use acute * 0.9 as approximation)
        // TODO: Implement real 7-day rolling average from historical data
        let chronicStress = Int(Double(acuteStress) * 0.9)
        
        return StressScoreResult(
            acuteStress: acuteStress,
            chronicStress: chronicStress,
            physiologicalStress: physiologicalStress,
            recoveryDeficit: recoveryDeficit,
            sleepDisruption: sleepDisruption,
            contributors: contributors
        )
    }
    
    /// Generate StressAlert from calculated scores
    private func generateAlertFrom(_ result: StressScoreResult) -> StressAlert {
        // Determine severity
        let severity: StressAlert.Severity
        if result.acuteStress >= 71 {
            severity = .high
        } else {
            severity = .elevated
        }
        
        // Determine trend (for now, assume increasing if chronic < acute)
        let trend: StressAlert.Trend
        if result.acuteStress > result.chronicStress + 5 {
            trend = .increasing
        } else if result.acuteStress < result.chronicStress - 5 {
            trend = .decreasing
        } else {
            trend = .stable
        }
        
        // Convert contributors
        let stressContributors = result.contributors.sorted { $0.points > $1.points }.map { data in
            StressContributor(
                name: data.type.label,
                type: data.type,
                value: data.value,
                points: data.points,
                description: data.description,
                status: data.status
            )
        }
        
        // Generate recommendation based on severity
        let recommendation: String
        if severity == .high {
            recommendation = """
            Significant stress detected. Your body is showing multiple signs of accumulated fatigue. \
            Rest is strongly recommended. Avoid hard training until recovery improves.
            """
        } else {
            recommendation = """
            Elevated stress detected. Your body is showing signs of accumulated training stress. \
            Consider lighter training or active recovery today.
            """
        }
        
        return StressAlert(
            severity: severity,
            acuteStress: result.acuteStress,
            chronicStress: result.chronicStress,
            trend: trend,
            contributors: stressContributors,
            recommendation: recommendation,
            detectedAt: Date()
        )
    }
}

