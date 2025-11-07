import Foundation
import HealthKit
import VeloReadyCore

/// Actor for recovery score data calculation
/// Handles heavy data fetching and coordinates with VeloReadyCore for scoring
actor RecoveryDataCalculator {
    private let healthKitManager = HealthKitManager.shared
    private let baselineCalculator = BaselineCalculator()
    
    // MARK: - Main Calculation
    
    func calculateRecoveryScore(
        sleepScore: SleepScore?
    ) async -> RecoveryScore? {
        Logger.debug("⚡ Starting parallel data fetching for recovery score...")
        
        // Get actual sleep times for overnight HRV window (physiologically correct)
        let sleepBedtime = sleepScore?.inputs.bedtime
        let sleepWakeTime = sleepScore?.inputs.wakeTime
        
        // Start all data fetching operations in parallel
        async let latestHRV = healthKitManager.fetchLatestHRVData()
        async let overnightHRV = healthKitManager.fetchOvernightHRVData(bedtime: sleepBedtime, wakeTime: sleepWakeTime)
        async let latestRHR = healthKitManager.fetchLatestRHRData()
        async let latestRespiratoryRate = healthKitManager.fetchLatestRespiratoryRateData()
        async let baselines = baselineCalculator.calculateAllBaselines()
        async let intervalsData = fetchTrainingLoads()
        async let recentStrain = fetchRecentStrain()
        
        // Wait for all parallel operations to complete
        let (hrv, overnightHrv, rhr, respiratoryRate) = await (latestHRV, overnightHRV, latestRHR, latestRespiratoryRate)
        
        let (hrvBaseline, rhrBaseline, sleepBaseline, respiratoryBaseline) = await baselines
        let (atl, ctl) = await intervalsData
        let strain = await recentStrain
        
        Logger.debug("⚡ All parallel data fetching completed")
        
        // Extract values for debugging
        let hrvValue = hrv.sample?.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
        let overnightHrvValue = overnightHrv.value
        let rhrValue = rhr.sample?.quantity.doubleValue(for: HKUnit(from: "count/min"))
        let respiratoryValue = respiratoryRate.sample?.quantity.doubleValue(for: HKUnit(from: "count/min"))
        
        Logger.debug("🔍 Recovery Score Inputs:")
        Logger.debug("   HRV: \(hrvValue?.description ?? "nil") ms (baseline: \(hrvBaseline?.description ?? "nil"))")
        Logger.debug("   Overnight HRV: \(overnightHrvValue?.description ?? "nil") ms")
        Logger.debug("   RHR: \(rhrValue?.description ?? "nil") bpm (baseline: \(rhrBaseline?.description ?? "nil"))")
        Logger.debug("   Sleep Score: \(sleepScore?.score.description ?? "nil")")
        Logger.debug("   Respiratory: \(respiratoryValue?.description ?? "nil") breaths/min")
        Logger.debug("   ATL: \(atl?.description ?? "nil"), CTL: \(ctl?.description ?? "nil")")
        Logger.debug("   Recent Strain: \(strain?.description ?? "nil")")
        
        // Create inputs for VeloReadyCore calculation (pure data)
        let coreInputs = VeloReadyCore.RecoveryCalculations.RecoveryInputs(
            hrv: hrvValue,
            overnightHrv: overnightHrvValue,
            hrvBaseline: hrvBaseline,
            rhr: rhrValue,
            rhrBaseline: rhrBaseline,
            sleepDuration: sleepScore?.inputs.sleepDuration,
            sleepBaseline: sleepBaseline,
            respiratoryRate: respiratoryValue,
            respiratoryBaseline: respiratoryBaseline,
            atl: atl,
            ctl: ctl,
            recentStrain: strain,
            sleepScore: sleepScore?.score
        )
        
        // Get current illness indicator
        let illnessIndicator = await IllnessDetectionService.shared.currentIndicator
        let hasIllness = illnessIndicator != nil
        let hasSleepData = sleepScore != nil
        
        // Call VeloReadyCore for pure calculation (runs on background thread)
        let result = VeloReadyCore.RecoveryCalculations.calculateScore(
            inputs: coreInputs,
            hasIllnessIndicator: hasIllness,
            hasSleepData: hasSleepData
        )
        
        // Map VeloReadyCore results back to iOS RecoveryScore model
        let modelInputs = RecoveryScore.RecoveryInputs(
            hrv: hrvValue,
            overnightHrv: overnightHrvValue,
            hrvBaseline: hrvBaseline,
            rhr: rhrValue,
            rhrBaseline: rhrBaseline,
            sleepDuration: sleepScore?.inputs.sleepDuration,
            sleepBaseline: sleepBaseline,
            respiratoryRate: respiratoryValue,
            respiratoryBaseline: respiratoryBaseline,
            atl: atl,
            ctl: ctl,
            recentStrain: strain,
            sleepScore: sleepScore
        )
        
        let modelSubScores = RecoveryScore.SubScores(
            hrv: result.subScores.hrv,
            rhr: result.subScores.rhr,
            sleep: result.subScores.sleep,
            form: result.subScores.form,
            respiratory: result.subScores.respiratory
        )
        
        let band = determineBand(score: result.score)
        
        return RecoveryScore(
            score: result.score,
            band: band,
            subScores: modelSubScores,
            inputs: modelInputs,
            calculatedAt: Date(),
            illnessDetected: hasIllness,
            illnessSeverity: illnessIndicator?.severity.rawValue
        )
    }
    
    // MARK: - Helper Methods
    
    private func fetchTrainingLoads() async -> (atl: Double?, ctl: Double?) {
        do {
            let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 500, daysBack: 90)
            
            if let latestActivity = activities.first, latestActivity.atl != nil, latestActivity.ctl != nil {
                Logger.data("Using Intervals.icu training loads: ATL=\(latestActivity.atl!), CTL=\(latestActivity.ctl!)")
                return (latestActivity.atl, latestActivity.ctl)
            }
        } catch {
            Logger.error("Failed to fetch Intervals data: \(error)")
        }
        
        // Fallback to HealthKit calculation
        let trainingLoadCalculator = TrainingLoadCalculator()
        let (ctl, atl) = await trainingLoadCalculator.calculateTrainingLoad()
        return (atl, ctl)
    }
    
    private func fetchRecentStrain() async -> Double? {
        // Get last 7 days of strain
        do {
            let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 50, daysBack: 7)
            let totalTSS = activities.compactMap { $0.tss }.reduce(0, +)
            return totalTSS
        } catch {
            Logger.debug("Could not fetch recent strain: \(error)")
            return nil
        }
    }
    
    private func determineBand(score: Int) -> RecoveryScore.RecoveryBand {
        switch score {
        case 75...100: return .optimal
        case 50..<75: return .good
        default: return .fair
        }
    }
}
