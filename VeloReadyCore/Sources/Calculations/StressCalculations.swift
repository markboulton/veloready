import Foundation

/// Pure stress calculation logic extracted from iOS app
/// All methods are static and stateless for easy testing
public struct StressCalculations {
    
    // MARK: - Main Calculation
    
    /// Calculate acute stress score from all input factors
    public static func calculateAcuteStress(
        hrv: Double?,
        hrvBaseline: Double?,
        rhr: Double?,
        rhrBaseline: Double?,
        recoveryScore: Int,
        sleepScore: Int,
        atl: Double?,
        ctl: Double?
    ) -> StressScoreResult {
        
        var physiologicalStress: Double = 0
        var contributors: [ContributorData] = []
        
        // 1. HRV Deviation Component (0-15 points)
        if let hrvValue = hrv, let hrvBase = hrvBaseline, hrvBase > 0 {
            let hrvDeviation = ((hrvBase - hrvValue) / hrvBase) * 100
            let hrvStress = max(0, min(15, hrvDeviation * 0.3))
            physiologicalStress += hrvStress
            
            let hrvScore = Int(100 - (hrvDeviation * 2))
            contributors.append(ContributorData(
                type: .hrv,
                value: max(0, min(100, hrvScore)),
                points: Int(hrvStress),
                description: String(format: "HRV: %.1f ms (baseline: %.1f ms)", hrvValue, hrvBase),
                status: hrvScore >= 80 ? .optimal : hrvScore >= 60 ? .good : .elevated
            ))
        }
        
        // 2. RHR Deviation Component (0-15 points)
        if let rhrValue = rhr, let rhrBase = rhrBaseline, rhrBase > 0 {
            let rhrDeviation = ((rhrValue - rhrBase) / rhrBase) * 100
            let rhrStress = max(0, min(15, rhrDeviation * 0.5))
            physiologicalStress += rhrStress
            
            let rhrScore = Int(100 - (rhrDeviation * 2))
            contributors.append(ContributorData(
                type: .rhr,
                value: max(0, min(100, rhrScore)),
                points: Int(rhrStress),
                description: String(format: "RHR: %.0f bpm (baseline: %.0f bpm)", rhrValue, rhrBase),
                status: rhrScore >= 80 ? .optimal : rhrScore >= 60 ? .good : .elevated
            ))
        }
        
        // 3. Recovery Deficit Component (0-30 points)
        let recoveryDeficit = max(0, Double(100 - recoveryScore) * 0.3)
        if recoveryScore < 80 {
            contributors.append(ContributorData(
                type: .recovery,
                value: recoveryScore,
                points: Int(recoveryDeficit),
                description: "Recovery score: \(recoveryScore)%",
                status: recoveryScore >= 80 ? .optimal : recoveryScore >= 60 ? .good : .elevated
            ))
        }
        
        // 4. Sleep Disruption Component (0-20 points)
        let sleepDisruption = max(0, Double(100 - sleepScore) * 0.2)
        if sleepScore < 80 {
            contributors.append(ContributorData(
                type: .sleepQuality,
                value: sleepScore,
                points: Int(sleepDisruption),
                description: "Sleep score: \(sleepScore)%",
                status: sleepScore >= 80 ? .optimal : sleepScore >= 60 ? .good : .elevated
            ))
        }
        
        // 5. Training Load Component (0-30 points)
        let (trainingLoadStress, trainingLoadScore, trainingLoadDescription) =
            calculateTrainingLoadStress(atl: atl, ctl: ctl)
        
        if trainingLoadScore < 80 {
            contributors.append(ContributorData(
                type: .trainingLoad,
                value: trainingLoadScore,
                points: Int(trainingLoadStress),
                description: trainingLoadDescription,
                status: trainingLoadScore >= 70 ? .good : .elevated
            ))
        }
        
        physiologicalStress += trainingLoadStress
        
        // Calculate total acute stress
        let acuteStress = Int(min(100, physiologicalStress + recoveryDeficit + sleepDisruption))
        
        return StressScoreResult(
            acuteStress: acuteStress,
            chronicStress: acuteStress, // Will be updated with historical data
            physiologicalStress: physiologicalStress,
            recoveryDeficit: recoveryDeficit,
            sleepDisruption: sleepDisruption,
            contributors: contributors
        )
    }
    
    // MARK: - Training Load Stress
    
    /// Calculate training load stress from ATL/CTL ratio
    private static func calculateTrainingLoadStress(
        atl: Double?,
        ctl: Double?
    ) -> (stress: Double, score: Int, description: String) {
        
        guard let atl = atl, let ctl = ctl, ctl > 0 else {
            return (0, 70, "Training load normal")
        }
        
        let ratio = atl / ctl
        let stress: Double
        let score: Int
        let description: String
        
        if ratio < 0.8 {
            stress = 0
            score = 100
            description = String(format: "ATL/CTL: %.2f - Well recovered", ratio)
        } else if ratio < 1.0 {
            stress = (ratio - 0.8) * 75 // Range: 0-15
            score = Int(100 - stress)
            description = String(format: "ATL/CTL: %.2f - Moderate load", ratio)
        } else if ratio < 1.3 {
            stress = 15 + ((ratio - 1.0) * 50) // Range: 15-30
            score = Int(100 - stress)
            description = String(format: "ATL/CTL: %.2f - High load", ratio)
        } else {
            stress = 30
            score = 40
            description = String(format: "ATL/CTL: %.2f - Overreaching", ratio)
        }
        
        return (stress, score, description)
    }
    
    // MARK: - Chronic Stress
    
    /// Calculate chronic stress from historical scores (7-day rolling average)
    public static func calculateChronicStress(
        historicalScores: [Double],
        todayStress: Int
    ) -> Int {
        
        var scores = historicalScores
        scores.append(Double(todayStress))
        
        guard !scores.isEmpty else {
            return todayStress
        }
        
        let average = scores.reduce(0, +) / Double(scores.count)
        return Int(average)
    }
    
    // MARK: - Smart Threshold
    
    /// Calculate personalized threshold based on athlete profile and history
    public static func calculateSmartThreshold(
        historicalScores: [Double],
        ctl: Double
    ) -> Int {
        
        // Default threshold if insufficient data
        guard historicalScores.count >= 7 else {
            return 50
        }
        
        // Calculate statistical baseline
        let average = historicalScores.reduce(0, +) / Double(historicalScores.count)
        let variance = historicalScores.map { pow($0 - average, 2) }.reduce(0, +) / Double(historicalScores.count)
        let stdDev = sqrt(variance)
        
        // Personal baseline + 1.5 standard deviations
        let personalBaseline = average + (stdDev * 1.5)
        
        // Fitness adjustment: Higher CTL = can handle more stress
        // CTL 40 (beginner) = -10 points, CTL 100 (pro) = +10 points
        let fitnessAdjustment = ((ctl - 70) / 60) * 10
        
        // Smart threshold (clamped 40-70)
        let threshold = Int(max(40, min(70, personalBaseline + fitnessAdjustment)))
        
        return threshold
    }
}

// MARK: - Result Types

public struct StressScoreResult {
    public let acuteStress: Int
    public let chronicStress: Int
    public let physiologicalStress: Double
    public let recoveryDeficit: Double
    public let sleepDisruption: Double
    public let contributors: [ContributorData]
    
    public init(
        acuteStress: Int,
        chronicStress: Int,
        physiologicalStress: Double,
        recoveryDeficit: Double,
        sleepDisruption: Double,
        contributors: [ContributorData]
    ) {
        self.acuteStress = acuteStress
        self.chronicStress = chronicStress
        self.physiologicalStress = physiologicalStress
        self.recoveryDeficit = recoveryDeficit
        self.sleepDisruption = sleepDisruption
        self.contributors = contributors
    }
}

public struct ContributorData {
    public let type: ContributorType
    public let value: Int
    public let points: Int
    public let description: String
    public let status: ContributorStatus
    
    public init(
        type: ContributorType,
        value: Int,
        points: Int,
        description: String,
        status: ContributorStatus
    ) {
        self.type = type
        self.value = value
        self.points = points
        self.description = description
        self.status = status
    }
}

public enum ContributorType {
    case hrv
    case rhr
    case recovery
    case sleepQuality
    case trainingLoad
}

public enum ContributorStatus {
    case optimal
    case good
    case elevated
}

