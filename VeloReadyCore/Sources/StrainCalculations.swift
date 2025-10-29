import Foundation

/// Pure strain score calculation functions
/// These functions are extracted from the iOS app for independent testing
public struct StrainCalculations {
    
    // MARK: - Constants
    
    /// Scale factor for cardio load calculation
    public static let cardioScaleFactor = 35.0
    
    /// Scale factor for strength load calculation
    public static let strengthScaleFactor = 1.2
    
    /// Scale factor for non-exercise load calculation
    public static let nonExerciseScaleFactor = 25.0
    
    /// Daily cap for non-exercise MET-minutes
    public static let dailyCap = 20.0
    
    /// Recovery modulation range (±15%)
    public static let recoveryModulationRange = 0.15
    
    // MARK: - Strain Bands
    
    public enum StrainBand: String, CaseIterable {
        case light = "Light"
        case moderate = "Moderate"
        case hard = "Hard"
        case veryHard = "Very Hard"
        case allOut = "All Out"
        
        public var range: ClosedRange<Double> {
            switch self {
            case .light: return 0.0...5.0
            case .moderate: return 5.0...11.0
            case .hard: return 11.0...16.0
            case .veryHard: return 16.0...18.0
            case .allOut: return 18.0...21.0
            }
        }
        
        public var color: String {
            switch self {
            case .light: return "green"
            case .moderate: return "yellow"
            case .hard: return "orange"
            case .veryHard: return "red"
            case .allOut: return "purple"
            }
        }
    }
    
    // MARK: - Strain Score Result
    
    public struct StrainScore {
        public let score: Double
        public let band: StrainBand
        public let cardioLoad: Int
        public let strengthLoad: Int
        public let nonExerciseLoad: Int
        public let recoveryFactor: Double
        
        public init(score: Double, band: StrainBand, cardioLoad: Int, strengthLoad: Int, nonExerciseLoad: Int, recoveryFactor: Double) {
            self.score = score
            self.band = band
            self.cardioLoad = cardioLoad
            self.strengthLoad = strengthLoad
            self.nonExerciseLoad = nonExerciseLoad
            self.recoveryFactor = recoveryFactor
        }
    }
    
    // MARK: - Core Calculations
    
    /// Calculate strain score from individual components
    /// - Parameters:
    ///   - cardioTRIMP: Daily TRIMP from cardio activities
    ///   - cardioDuration: Duration of cardio in minutes
    ///   - intensityFactor: Average intensity factor (IF) for cardio
    ///   - strengthRPE: Session RPE for strength training (1-10)
    ///   - strengthDuration: Duration of strength training in minutes
    ///   - strengthVolume: Total volume (kg) lifted
    ///   - strengthSets: Number of sets performed
    ///   - bodyMass: User's body mass in kg
    ///   - steps: Daily step count
    ///   - activeCalories: Active calories burned
    ///   - hrvCurrent: Current HRV value
    ///   - hrvBaseline: Baseline HRV value
    ///   - rhrCurrent: Current resting heart rate
    ///   - rhrBaseline: Baseline resting heart rate
    ///   - sleepQuality: Sleep quality score (0-100)
    /// - Returns: StrainScore with final score and breakdown
    public static func calculateStrainScore(
        cardioTRIMP: Double?,
        cardioDuration: Double?,
        intensityFactor: Double?,
        strengthRPE: Double?,
        strengthDuration: Double?,
        strengthVolume: Double?,
        strengthSets: Int?,
        bodyMass: Double?,
        steps: Int?,
        activeCalories: Double?,
        hrvCurrent: Double?,
        hrvBaseline: Double?,
        rhrCurrent: Double?,
        rhrBaseline: Double?,
        sleepQuality: Int?
    ) -> StrainScore {
        // Calculate sub-components
        let cardioLoad = calculateCardioLoad(
            trimp: cardioTRIMP,
            duration: cardioDuration,
            intensityFactor: intensityFactor
        )
        
        let strengthLoad = calculateStrengthLoad(
            rpe: strengthRPE,
            duration: strengthDuration,
            volume: strengthVolume,
            sets: strengthSets,
            bodyMass: bodyMass
        )
        
        let nonExerciseLoad = calculateNonExerciseLoad(
            steps: steps,
            activeCalories: activeCalories
        )
        
        let recoveryFactor = calculateRecoveryFactor(
            hrvCurrent: hrvCurrent,
            hrvBaseline: hrvBaseline,
            rhrCurrent: rhrCurrent,
            rhrBaseline: rhrBaseline,
            sleepQuality: sleepQuality
        )
        
        // Combine loads with recovery modulation
        let rawScore = Double(cardioLoad + strengthLoad + nonExerciseLoad)
        let modulatedScore = rawScore * recoveryFactor
        
        // Clamp to 0-21 range (Whoop scale is 0-21)
        let finalScore = max(0.0, min(21.0, modulatedScore))
        let band = determineStrainBand(score: finalScore)
        
        return StrainScore(
            score: finalScore,
            band: band,
            cardioLoad: cardioLoad,
            strengthLoad: strengthLoad,
            nonExerciseLoad: nonExerciseLoad,
            recoveryFactor: recoveryFactor
        )
    }
    
    // MARK: - Cardio Load Calculation
    
    /// Calculate cardio load from TRIMP, duration, and intensity
    /// - Parameters:
    ///   - trimp: Daily TRIMP from cardio activities
    ///   - duration: Duration in minutes
    ///   - intensityFactor: Average intensity factor (0-1+)
    /// - Returns: Cardio load score (0-100)
    public static func calculateCardioLoad(
        trimp: Double?,
        duration: Double?,
        intensityFactor: Double?
    ) -> Int {
        guard let trimp = trimp, trimp > 0 else { return 0 }
        
        // Apply logarithmic compression: CardioLoad = k_c * log10(TRIMP_raw + 1)
        var compressedTRIMP = cardioScaleFactor * log10(trimp + 1.0)
        
        // Boost for sustained efforts (duration > 60 min)
        if let duration = duration, duration > 60 {
            let durationBonus = min(10.0, (duration - 60) * 0.1)
            compressedTRIMP += durationBonus
        }
        
        // Boost for high intensity efforts (IF > 0.8)
        if let intensity = intensityFactor, intensity > 0.8 {
            let intensityBonus = min(15.0, (intensity - 0.8) * 75.0)
            compressedTRIMP += intensityBonus
        }
        
        return max(0, min(100, Int(compressedTRIMP)))
    }
    
    // MARK: - Strength Load Calculation
    
    /// Calculate strength load from RPE and duration
    /// - Parameters:
    ///   - rpe: Session RPE (1-10)
    ///   - duration: Duration in minutes
    ///   - volume: Total volume in kg (optional)
    ///   - sets: Number of sets (optional)
    ///   - bodyMass: User's body mass in kg (optional)
    /// - Returns: Strength load score (0-100)
    public static func calculateStrengthLoad(
        rpe: Double?,
        duration: Double?,
        volume: Double?,
        sets: Int?,
        bodyMass: Double?
    ) -> Int {
        guard let rpe = rpe,
              let duration = duration,
              duration > 0,
              rpe >= 1.0 && rpe <= 10.0 else { return 0 }
        
        // Base calculation: StrengthLoad = k_s * (sRPE * minutes)
        var baseLoad = strengthScaleFactor * (rpe * duration)
        
        // Volume enhancement (if available)
        if let volume = volume,
           let bodyMass = bodyMass,
           bodyMass > 0 {
            let relativeVolume = volume / bodyMass
            let volumeTerm = min(2.0, pow(relativeVolume, 0.25))
            baseLoad *= (1.0 + 0.15 * volumeTerm)
        }
        
        // Sets enhancement (if available)
        if let sets = sets, sets > 0 {
            let setsMultiplier = min(1.3, 1.0 + (Double(sets - 1) * 0.05))
            baseLoad *= setsMultiplier
        }
        
        // Apply logarithmic compression
        let compressedLoad = cardioScaleFactor * 0.8 * log10(baseLoad + 1.0)
        
        return max(0, min(100, Int(compressedLoad)))
    }
    
    // MARK: - Non-Exercise Load Calculation
    
    /// Calculate non-exercise activity load from steps and active calories
    /// - Parameters:
    ///   - steps: Daily step count
    ///   - activeCalories: Active calories burned
    /// - Returns: Non-exercise load score (0-100)
    public static func calculateNonExerciseLoad(
        steps: Int?,
        activeCalories: Double?
    ) -> Int {
        var totalLoad: Double = 0
        
        // Steps contribution
        if let steps = steps, steps > 0 {
            let baseSteps = 2000.0
            let metMinutesBaseline = 20.0
            let metMinutes = metMinutesBaseline * (Double(steps) / baseSteps)
            totalLoad += metMinutes
        }
        
        // Active calories contribution
        if let activeCalories = activeCalories, activeCalories > 0 {
            let metMinutesFromCalories = activeCalories * 0.003
            totalLoad += metMinutesFromCalories
        }
        
        // Apply logarithmic compression with daily cap
        let cappedLoad = min(totalLoad, dailyCap * 1.5)
        let compressedLoad = nonExerciseScaleFactor * log1p(cappedLoad)
        
        return max(0, min(100, Int(compressedLoad)))
    }
    
    // MARK: - Recovery Factor Calculation
    
    /// Calculate recovery factor from HRV, RHR, and sleep quality
    /// This modulates strain based on recovery state
    /// - Parameters:
    ///   - hrvCurrent: Current HRV value
    ///   - hrvBaseline: Baseline HRV value
    ///   - rhrCurrent: Current resting heart rate
    ///   - rhrBaseline: Baseline resting heart rate
    ///   - sleepQuality: Sleep quality score (0-100)
    /// - Returns: Recovery factor (0.85-1.15, default 1.0)
    public static func calculateRecoveryFactor(
        hrvCurrent: Double?,
        hrvBaseline: Double?,
        rhrCurrent: Double?,
        rhrBaseline: Double?,
        sleepQuality: Int?
    ) -> Double {
        var zHRV: Double = 0
        var zRHR: Double = 0
        var zSleep: Double = 0
        
        // HRV z-score (higher is better)
        if let hrvCurrent = hrvCurrent,
           let hrvBaseline = hrvBaseline,
           hrvBaseline > 0 {
            zHRV = (hrvCurrent - hrvBaseline) / hrvBaseline
        }
        
        // RHR z-score (lower is better, so inverted)
        if let rhrCurrent = rhrCurrent,
           let rhrBaseline = rhrBaseline,
           rhrBaseline > 0 {
            zRHR = (rhrBaseline - rhrCurrent) / rhrBaseline
        }
        
        // Sleep quality z-score (centered around 75)
        if let sleepQuality = sleepQuality {
            zSleep = (Double(sleepQuality) - 75.0) / 25.0
        }
        
        // Blend recovery signals with weights
        let recoverySignal = (0.6 * zHRV) + (0.3 * zRHR) + (0.1 * zSleep)
        let clampedSignal = max(-1.0, min(1.0, recoverySignal))
        
        // Map to recovery factor: R = 1 + 0.15 * signal (range ~0.85-1.15)
        return 1.0 + (recoveryModulationRange * clampedSignal)
    }
    
    // MARK: - Helper Functions
    
    /// Determine strain band from score
    /// - Parameter score: Strain score (0-21)
    /// - Returns: Strain band
    public static func determineStrainBand(score: Double) -> StrainBand {
        switch score {
        case 0.0...5.0: return .light
        case 5.0...11.0: return .moderate
        case 11.0...16.0: return .hard
        case 16.0...18.0: return .veryHard
        default: return .allOut
        }
    }
}

