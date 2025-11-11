import Foundation
import Combine
import SwiftUI
import CoreData
import VeloReadyCore

/// Service for stress analysis and monitoring
/// This service orchestrates data fetching and delegates calculation logic to VeloReadyCore
/// for testability and reusability (matches RecoveryScoreService pattern)
@MainActor
class StressAnalysisService: ObservableObject {
    static let shared = StressAnalysisService()
    
    @Published private(set) var currentAlert: StressAlert?
    @Published private(set) var isAnalyzing = false
    
    private let logger = Logger.self
    private let persistence = PersistenceController.shared
    private let cacheManager = CacheManager.shared
    
    private init() {
        // Initialize service
        logger.debug("🧠 [StressAnalysisService] Initialized")
    }
    
    // MARK: - Public Methods
    
    /// Analyze stress levels and generate alert if needed
    func analyzeStress() async {
        logger.debug("🧠 [StressAnalysisService] Starting stress analysis")
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Calculate real stress score
        let stressScore = await calculateStressScore()
        
        // Save to Core Data
        await saveStressScore(stressScore)
        
        // Check if alert should be generated using smart thresholds
        let threshold = await calculateSmartThreshold()
        
        if stressScore.acuteStress > threshold {
            currentAlert = generateAlertFrom(stressScore)
            logger.debug("🧠 [StressAnalysisService] Generated stress alert - Acute: \(stressScore.acuteStress), Chronic: \(stressScore.chronicStress), Threshold: \(threshold)")
        } else {
            currentAlert = nil
            logger.debug("🧠 [StressAnalysisService] No alert - stress within normal range (\(stressScore.acuteStress) < threshold \(threshold))")
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
    func getStressTrendData(for period: TrendPeriod) -> [TrendDataPoint] {
        let days = period.days
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Fetch historical stress scores from Core Data
        guard let startDate = calendar.date(byAdding: .day, value: -days + 1, to: today) else {
            return []
        }
        
        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, today as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        let historicalScores = persistence.fetch(request)
        
        // Convert to TrendDataPoint
        var dataPoints: [TrendDataPoint] = []
        
        for score in historicalScores where score.date != nil {
            let stressValue = score.stressScore > 0 ? score.stressScore : nil
            if let value = stressValue, let date = score.date {
                dataPoints.append(TrendDataPoint(
                    date: date,
                    value: value
                ))
            }
        }
        
        // Fill in missing days with nil (chart will interpolate or show gaps)
        if dataPoints.count < days {
            logger.debug("🧠 [StressAnalysisService] Only \(dataPoints.count) days of historical stress data available")
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
    
    /// Calculate stress score from multiple inputs
    /// Delegates calculation to VeloReadyCore.StressCalculations
    private func calculateStressScore() async -> StressScoreResult {
        // Get services
        let recoveryService = RecoveryScoreService.shared
        let sleepService = SleepScoreService.shared
        
        // Get current scores
        let recovery = recoveryService.currentRecoveryScore
        let sleep = sleepService.currentSleepScore
        
        // Extract inputs for VeloReadyCore calculation
        let hrv = recovery?.inputs.hrv
        let hrvBaseline = recovery?.inputs.hrvBaseline
        let rhr = recovery?.inputs.rhr
        let rhrBaseline = recovery?.inputs.rhrBaseline
        let recoveryScore = recovery?.score ?? 50
        let sleepScore = sleep?.score ?? 50
        let atl = recovery?.inputs.atl
        let ctl = recovery?.inputs.ctl
        
        // Delegate to VeloReadyCore for pure calculation
        let coreResult = VeloReadyCore.StressCalculations.calculateAcuteStress(
            hrv: hrv,
            hrvBaseline: hrvBaseline,
            rhr: rhr,
            rhrBaseline: rhrBaseline,
            recoveryScore: recoveryScore,
            sleepScore: sleepScore,
            atl: atl,
            ctl: ctl
        )
        
        // Convert VeloReadyCore result to iOS model
        let contributors: [StressScoreResult.ContributorData] = coreResult.contributors.map { coreContributor in
            StressScoreResult.ContributorData(
                type: convertContributorType(coreContributor.type),
                value: coreContributor.value,
                points: coreContributor.points,
                description: coreContributor.description,
                status: convertContributorStatus(coreContributor.status)
            )
        }
        
        return StressScoreResult(
            acuteStress: coreResult.acuteStress,
            chronicStress: coreResult.chronicStress,
            physiologicalStress: coreResult.physiologicalStress,
            recoveryDeficit: coreResult.recoveryDeficit,
            sleepDisruption: coreResult.sleepDisruption,
            contributors: contributors
        )
    }
    
    /// Convert VeloReadyCore ContributorType to iOS model
    private func convertContributorType(_ coreType: VeloReadyCore.ContributorType) -> StressContributor.ContributorType {
        switch coreType {
        case .hrv: return .hrv
        case .rhr: return .hrv  // Note: .rhr doesn't exist in iOS model, map to .hrv
        case .recovery: return .recovery
        case .sleepQuality: return .sleepQuality
        case .trainingLoad: return .trainingLoad
        }
    }
    
    /// Convert VeloReadyCore ContributorStatus to iOS model
    private func convertContributorStatus(_ coreStatus: VeloReadyCore.ContributorStatus) -> StressContributor.Status {
        switch coreStatus {
        case .optimal: return .good
        case .good: return .good
        case .elevated: return .elevated
        }
    }
    
    /// Calculate chronic stress from 7-day rolling average
    /// Fetches historical data and delegates calculation to VeloReadyCore
    private func calculateChronicStress(todayStress: Int) async -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Fetch last 6 days of stress scores (not including today)
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: today) else {
            return todayStress // Fallback to today's stress
        }
        
        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, today as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        let historicalScores = persistence.fetch(request)
        
        // Collect stress scores from past 6 days (today will be added by VeloReadyCore)
        let stressValues: [Double] = historicalScores.compactMap { score in
            score.stressScore > 0 ? score.stressScore : nil
        }
        
        // Delegate to VeloReadyCore for calculation
        let chronic = VeloReadyCore.StressCalculations.calculateChronicStress(
            historicalScores: stressValues,
            todayStress: todayStress
        )
        
        logger.debug("🧠 [StressAnalysisService] Chronic stress calculated from \(stressValues.count + 1) days: \(chronic)")
        
        return chronic
    }
    
    /// Calculate smart threshold based on athlete profile and historical patterns
    /// Fetches historical data and delegates calculation to VeloReadyCore
    private func calculateSmartThreshold() async -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Fetch last 30 days of stress scores for baseline calculation
        guard let startDate = calendar.date(byAdding: .day, value: -29, to: today) else {
            return 50 // Default threshold
        }
        
        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@ AND stressScore > 0", 
                                       startDate as NSDate, today as NSDate)
        
        let historicalScores = persistence.fetch(request)
        
        // Collect historical stress values
        let stressValues = historicalScores.map { $0.stressScore }
        
        // Get current CTL for fitness adjustment
        let recovery = await MainActor.run {
            RecoveryScoreService.shared.currentRecoveryScore
        }
        let ctl = recovery?.inputs.ctl ?? 70
        
        // Delegate to VeloReadyCore for calculation
        let smartThreshold = VeloReadyCore.StressCalculations.calculateSmartThreshold(
            historicalScores: stressValues,
            ctl: ctl
        )
        
        logger.debug("🧠 [StressAnalysisService] Smart threshold: \(smartThreshold) (from \(stressValues.count) days, CTL: \(Int(ctl)))")
        
        return smartThreshold
    }
    
    /// Save stress score to Core Data
    private func saveStressScore(_ result: StressScoreResult) async {
        let context = persistence.newBackgroundContext()
        
        await context.perform { [weak self] in
            guard let self = self else { return }
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            // Fetch or create DailyScores for today
            let request = DailyScores.fetchRequest()
            request.predicate = NSPredicate(format: "date == %@", today as NSDate)
            request.fetchLimit = 1
            
            let scores = (try? context.fetch(request).first) ?? DailyScores(context: context)
            if scores.date == nil {
                scores.date = today
            }
            
            // Save stress data
            scores.stressScore = Double(result.acuteStress)
            scores.chronicStress = Double(result.chronicStress)
            scores.physiologicalStress = result.physiologicalStress
            scores.recoveryDeficit = result.recoveryDeficit
            scores.sleepDisruption = result.sleepDisruption
            
            // Determine trend
            let trend: String
            if result.acuteStress > result.chronicStress + 5 {
                trend = "increasing"
            } else if result.acuteStress < result.chronicStress - 5 {
                trend = "decreasing"
            } else {
                trend = "stable"
            }
            scores.stressTrend = trend
            
            scores.lastUpdated = Date()
            
            // Save context
            do {
                try context.save()
                self.logger.debug("💾 [StressAnalysisService] Saved stress score to Core Data - Acute: \(result.acuteStress), Chronic: \(result.chronicStress)")
            } catch {
                self.logger.error("❌ [StressAnalysisService] Failed to save stress score: \(error.localizedDescription)")
            }
        }
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

