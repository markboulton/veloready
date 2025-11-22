import Foundation

/// Pure calculation logic for strain scores
/// Extracted from StrainScoreCalculator in iOS app
/// No dependencies on iOS frameworks or UI
public struct StrainCalculations {

    // MARK: - Gender Enum

    /// Biological sex for physiologically-accurate TRIMP calculation
    /// Research: Banister's original TRIMP uses gender-specific exponents
    /// - Female: 1.67 (lower lactate response at given HR%)
    /// - Male: 1.92 (higher lactate response at given HR%)
    public enum BiologicalSex {
        case female
        case male
        case unspecified
    }

    // MARK: - Constants

    /// Zone weight exponents for TRIMP calculation (research-based)
    /// Banister's original research used gender-specific values
    /// The exponent models the exponential relationship between HR% and blood lactate
    public struct ZoneExponents {
        /// Female exponent from Banister's research
        public static let female: Double = 1.67
        /// Male exponent from Banister's research
        public static let male: Double = 1.92
        /// Default/unspecified (average of male/female, slightly weighted toward male for cycling)
        public static let unspecified: Double = 1.85

        /// Get the appropriate exponent for a given sex
        public static func forSex(_ sex: BiologicalSex) -> Double {
            switch sex {
            case .female: return female
            case .male: return male
            case .unspecified: return unspecified
            }
        }
    }

    /// Legacy zone weight exponent (kept for backward compatibility)
    /// Note: 2.2 was slightly aggressive; research suggests 1.67-1.92 range
    private static let zoneWeightExponent: Double = 2.2
    private static let intensityBlendPower: Double = 0.6
    
    // MARK: - TRIMP Calculations

    /// Calculate TRIMP from heart rate data points using research-based gender-specific exponents
    /// - Parameters:
    ///   - heartRateData: Array of (time, heartRate) tuples
    ///   - restingHR: Resting heart rate
    ///   - maxHR: Maximum heart rate
    ///   - sex: Biological sex for accurate exponent selection (optional)
    ///   - customExponent: Override exponent if provided (for advanced users)
    /// - Returns: TRIMP value
    ///
    /// Research: Banister's original TRIMP uses gender-specific weighting exponents
    /// - Female: y = 0.86 × e^(1.67x) where x = HR reserve fraction
    /// - Male: y = 0.64 × e^(1.92x)
    /// The exponent models the exponential relationship between %HRR and blood lactate
    public static func calculateTRIMP(
        heartRateData: [(time: TimeInterval, hr: Double)],
        restingHR: Double,
        maxHR: Double,
        sex: BiologicalSex = .unspecified,
        customExponent: Double? = nil
    ) -> Double {
        guard !heartRateData.isEmpty,
              maxHR > restingHR,
              restingHR > 0 else { return 0 }

        // Use custom exponent if provided, otherwise use gender-specific value
        let exponent = customExponent ?? ZoneExponents.forSex(sex)

        var trimpSum: Double = 0
        let maxMinusRest = maxHR - restingHR

        for (index, dataPoint) in heartRateData.enumerated() {
            let hrRR = max(0, min(1, (dataPoint.hr - restingHR) / maxMinusRest))
            let intensityWeight = pow(hrRR, exponent)

            // Calculate time difference (duration in seconds)
            let timeDelta: TimeInterval
            if index == 0 {
                timeDelta = 1.0 // Assume 1 second for first point
            } else {
                timeDelta = dataPoint.time - heartRateData[index - 1].time
            }

            trimpSum += intensityWeight * timeDelta
        }

        return trimpSum
    }
    
    /// Calculate blended TRIMP (heart rate + power) with gender-aware exponent
    /// - Parameters:
    ///   - heartRateData: Array of (time, heartRate, power) tuples
    ///   - restingHR: Resting heart rate
    ///   - maxHR: Maximum heart rate
    ///   - ftp: Functional Threshold Power
    ///   - sex: Biological sex for accurate exponent selection (optional)
    ///   - customExponent: Override exponent if provided (for advanced users)
    /// - Returns: Blended TRIMP value
    public static func calculateBlendedTRIMP(
        heartRateData: [(time: TimeInterval, hr: Double, power: Double)],
        restingHR: Double,
        maxHR: Double,
        ftp: Double,
        sex: BiologicalSex = .unspecified,
        customExponent: Double? = nil
    ) -> Double {
        guard !heartRateData.isEmpty,
              maxHR > restingHR,
              ftp > 0 else { return 0 }

        // Use custom exponent if provided, otherwise use gender-specific value
        let exponent = customExponent ?? ZoneExponents.forSex(sex)

        var trimpSum: Double = 0
        let maxMinusRest = maxHR - restingHR

        for (index, dataPoint) in heartRateData.enumerated() {
            // Heart rate component
            let hrRR = max(0, min(1, (dataPoint.hr - restingHR) / maxMinusRest))

            // Power component
            let powerFraction = max(0, dataPoint.power / ftp)

            // Blend components
            let blendedIntensity = (intensityBlendPower * hrRR) + ((1.0 - intensityBlendPower) * powerFraction)
            let clampedIntensity = max(0, min(1, blendedIntensity))

            let intensityWeight = pow(clampedIntensity, exponent)

            // Calculate time difference
            let timeDelta: TimeInterval
            if index == 0 {
                timeDelta = 1.0
            } else {
                timeDelta = dataPoint.time - heartRateData[index - 1].time
            }

            trimpSum += intensityWeight * timeDelta
        }

        return trimpSum
    }
    
    // MARK: - Whoop-Like Calculations
    
    /// Convert TRIMP to EPOC estimate (Whoop-like approach)
    /// - Parameter trimp: TRIMP value
    /// - Returns: EPOC estimate
    public static func convertTRIMPToEPOC(trimp: Double) -> Double {
        // EPOC estimation - adjusted for better sensitivity
        return 0.25 * pow(trimp, 1.1)
    }
    
    /// Calculate strain using Whoop's logarithmic formula
    /// - Parameter epoc: EPOC value
    /// - Returns: Strain score (0-18)
    public static func calculateWhoopStrain(epoc: Double) -> Double {
        // Whoop's formula: Strain = 18 × ln(EPOC + 1) / ln(EPOC_max + 1)
        // Calibrated for realistic TSS-to-strain mapping
        let epocMax: Double = 1_200.0
        
        let strain = 18.0 * log(epoc + 1.0) / log(epocMax + 1.0)
        
        return max(0.0, min(18.0, strain))
    }
    
    // MARK: - Sub-Score Calculations
    
    /// Calculate cardio load score from TRIMP
    /// - Parameters:
    ///   - dailyTRIMP: Daily TRIMP value
    ///   - durationMinutes: Workout duration in minutes (optional)
    ///   - intensityFactor: Average intensity factor (optional)
    /// - Returns: Cardio load score (0-100)
    public static func calculateCardioLoad(
        dailyTRIMP: Double,
        durationMinutes: Double? = nil,
        intensityFactor: Double? = nil
    ) -> Int {
        guard dailyTRIMP > 0 else { return 0 }
        
        let cardioScaleFactor: Double = 18.0
        
        // Apply logarithmic compression
        var scaledScore = cardioScaleFactor * log10(dailyTRIMP + 1.0)
        
        // Boost for sustained efforts (duration component)
        if let duration = durationMinutes, duration > 60 {
            let durationBonus = min(10.0, (duration - 60) * 0.1)
            scaledScore += durationBonus
        }
        
        // Boost for high intensity efforts (IF component)
        if let intensity = intensityFactor, intensity > 0.8 {
            let intensityBonus = min(15.0, (intensity - 0.8) * 75.0)
            scaledScore += intensityBonus
        }
        
        return max(0, min(100, Int(scaledScore)))
    }
    
    /// Calculate strength load score from RPE and duration
    /// - Parameters:
    ///   - rpe: Session RPE (1-10 scale)
    ///   - durationMinutes: Session duration in minutes
    ///   - volume: Total volume in kg (optional)
    ///   - bodyMass: User body mass in kg (optional)
    ///   - sets: Number of sets (optional)
    /// - Returns: Strength load score (0-100)
    public static func calculateStrengthLoad(
        rpe: Double,
        durationMinutes: Double,
        volume: Double? = nil,
        bodyMass: Double? = nil,
        sets: Int? = nil
    ) -> Int {
        guard durationMinutes > 0,
              rpe >= 1.0 && rpe <= 10.0 else { return 0 }
        
        let strengthScaleFactor: Double = 3.5
        let cardioScaleFactor: Double = 18.0
        
        // Base calculation
        var baseLoad = strengthScaleFactor * (rpe * durationMinutes)
        
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
    
    /// Calculate non-exercise activity load
    /// - Parameters:
    ///   - steps: Daily steps count (optional)
    ///   - activeCalories: Active energy calories (optional)
    ///   - metMinutes: Direct MET-minutes (optional)
    /// - Returns: Non-exercise load score (0-100)
    public static func calculateNonExerciseLoad(
        steps: Int? = nil,
        activeCalories: Double? = nil,
        metMinutes: Double? = nil
    ) -> Int {
        var totalLoad: Double = 0
        let nonExerciseScaleFactor: Double = 16.0
        let dailyCap: Double = 40.0
        
        // Steps contribution
        if let steps = steps, steps > 0 {
            let baseSteps = 2000.0
            let metMinutesBaseline = 20.0
            let metMins = metMinutesBaseline * (Double(steps) / baseSteps)
            totalLoad += metMins
        }
        
        // Active energy contribution
        if let activeCalories = activeCalories, activeCalories > 0 {
            let metMinutesFromCalories = activeCalories * 0.003
            totalLoad += metMinutesFromCalories
        }
        
        // Direct MET-minutes
        if let metmin = metMinutes {
            totalLoad += metmin
        }
        
        // Apply logarithmic compression
        let cappedLoad = min(totalLoad, dailyCap * 1.5)
        let compressedLoad = nonExerciseScaleFactor * log1p(cappedLoad)
        
        return max(0, min(100, Int(compressedLoad)))
    }
    
    /// Calculate recovery factor modulation
    /// - Parameters:
    ///   - hrvToday: Today's HRV value (optional)
    ///   - hrvBaseline: HRV baseline (optional)
    ///   - rhrToday: Today's RHR value (optional)
    ///   - rhrBaseline: RHR baseline (optional)
    ///   - sleepQuality: Sleep quality score 0-100 (optional)
    /// - Returns: Recovery factor (typically 0.85-1.15)
    public static func calculateRecoveryFactor(
        hrvToday: Double? = nil,
        hrvBaseline: Double? = nil,
        rhrToday: Double? = nil,
        rhrBaseline: Double? = nil,
        sleepQuality: Int? = nil
    ) -> Double {
        let recoveryModulationRange: Double = 0.15
        var zHRV: Double = 0
        var zRHR: Double = 0
        var zSleep: Double = 0
        
        // HRV z-score
        if let hrvToday = hrvToday,
           let hrvBase = hrvBaseline,
           hrvBase > 0 {
            zHRV = (hrvToday - hrvBase) / hrvBase
        }
        
        // RHR z-score (inverted - lower RHR is better)
        if let rhrToday = rhrToday,
           let rhrBase = rhrBaseline,
           rhrBase > 0 {
            zRHR = (rhrBase - rhrToday) / rhrBase
        }
        
        // Sleep quality z-score
        if let sleepQuality = sleepQuality {
            zSleep = (Double(sleepQuality) - 75.0) / 25.0
        }
        
        // Blend recovery signals with weights
        let recoverySignal = (0.6 * zHRV) + (0.3 * zRHR) + (0.1 * zSleep)
        let clampedSignal = max(-1.0, min(1.0, recoverySignal))
        
        // Map to recovery factor: R = 1 + 0.15 * signal (range ~0.85-1.15)
        return 1.0 + (recoveryModulationRange * clampedSignal)
    }
    
    // MARK: - Band Determination
    
    /// Determine strain band from score (0-18 scale)
    /// - Parameter score: Strain score (0-18)
    /// - Returns: Band name as string
    public static func determineBand(score: Double) -> String {
        switch score {
        case 0..<6.0: return "light"
        case 6.0..<11.0: return "moderate"
        case 11.0..<16.0: return "hard"
        default: return "veryHard"
        }
    }
}
