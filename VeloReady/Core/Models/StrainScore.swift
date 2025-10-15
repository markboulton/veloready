import Foundation
import HealthKit
import SwiftUI

/// Muscle groups and workout patterns for strength training tracking
enum MuscleGroup: String, Codable, CaseIterable {
    // Specific muscle groups
    case legs = "Legs"
    case back = "Back"
    case chest = "Chest"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case core = "Core"
    
    // Workout patterns (research-backed categories)
    case push = "Push"           // Chest, shoulders, triceps
    case pull = "Pull"           // Back, biceps, rear delts
    case fullBody = "Full Body"  // Multiple muscle groups, compound movements
    case conditioning = "Conditioning" // HIIT, circuits, metabolic work
    
    /// Base recovery time needed after training this muscle group (in hours)
    var baseRecoveryHours: Double {
        switch self {
        case .legs: return 72  // 72h - largest muscle groups, most systemic fatigue
        case .back: return 48  // 48h - large muscle group
        case .chest: return 48  // 48h - large muscle group
        case .shoulders: return 36  // 36h - medium muscle group
        case .arms: return 36  // 36h - smaller muscle group
        case .core: return 24  // 24h - recovers faster, frequent training possible
        case .push: return 48  // 48h - multiple pressing muscle groups
        case .pull: return 48  // 48h - multiple pulling muscle groups
        case .fullBody: return 72  // 72h - entire body taxed
        case .conditioning: return 36  // 36h - metabolic stress, faster recovery
        }
    }
    
    /// Multiplier for systemic fatigue impact
    /// Based on research: larger muscle mass + compound movements = higher systemic stress
    var systemicFatigueFactor: Double {
        switch self {
        case .legs: return 1.5  // Highest - largest muscle group
        case .back: return 1.2  // High - large pulling muscles
        case .chest: return 1.0  // Baseline - large pressing muscles
        case .shoulders: return 0.9
        case .arms: return 0.7
        case .core: return 0.8
        case .push: return 1.1  // Moderate-high - multiple pressing muscles
        case .pull: return 1.2  // High - back dominant, large muscle mass
        case .fullBody: return 1.4  // Very high - entire body, most demanding
        case .conditioning: return 1.3  // High - metabolic + cardiovascular stress
        }
    }
    
    /// Category for intelligent grouping
    var category: WorkoutCategory {
        switch self {
        case .legs, .back, .chest, .shoulders, .arms, .core:
            return .specificMuscle
        case .push, .pull:
            return .movementPattern
        case .fullBody:
            return .compound
        case .conditioning:
            return .metabolic
        }
    }
}

/// Workout category for intelligent multi-selection handling
enum WorkoutCategory {
    case specificMuscle  // Individual muscle groups
    case movementPattern // Push/Pull patterns
    case compound        // Full body
    case metabolic       // Conditioning
}

/// Strain/Load Score calculation and data model
/// Implements a Whoop-like strain scoring algorithm that combines cardio, strength, and daily activity
/// Score is on a 0-18 scale with decimals (similar to perceived exertion but more granular)
struct StrainScore: Codable {
    let score: Double // 0-18 scale with decimals
    let band: StrainBand
    let subScores: SubScores
    let inputs: StrainInputs
    let calculatedAt: Date
    
    enum StrainBand: String, CaseIterable, Codable {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case extreme = "Extreme"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .moderate: return "blue"
            case .high: return "orange"
            case .extreme: return "red"
            }
        }
        
        /// Get the SwiftUI Color token for this strain band
        var colorToken: Color {
            switch self {
            case .low: return ColorScale.greenAccent
            case .moderate: return ColorScale.blueAccent
            case .high: return ColorScale.amberAccent
            case .extreme: return ColorScale.redAccent
            }
        }
        
        var description: String {
            switch self {
            case .low: return "Low Strain"
            case .moderate: return "Moderate Strain"
            case .high: return "High Strain"
            case .extreme: return "Extreme Strain"
            }
        }
    }
    
    struct SubScores: Codable {
        let cardioLoad: Int // 0-100 (cycling TRIMP-based)
        let strengthLoad: Int // 0-100 (resistance training)
        let nonExerciseLoad: Int // 0-100 (daily activity)
        let recoveryFactor: Double // 0.85-1.15 (recovery modulation)
    }
    
    struct StrainInputs: Codable {
        // Continuous HR data (Whoop-like approach)
        let continuousHRData: [HRDataPoint]? // Continuous HR throughout day
        let dailyTRIMP: Double? // Total daily TRIMP from continuous HR
        
        // Cardio inputs (workout-specific)
        let cardioDailyTRIMP: Double? // Raw TRIMP from cycling
        let cardioDurationMinutes: Double? // Total cardio duration
        let averageIntensityFactor: Double? // IF from cycling
        let workoutTypes: [String]? // HealthKit workout types for the day
        
        // Strength inputs
        let strengthSessionRPE: Double? // sRPE (1-10)
        let strengthDurationMinutes: Double? // Strength training duration
        let strengthVolume: Double? // Total volume (weight × reps)
        let strengthSets: Int? // Number of working sets
        let muscleGroupsTrained: [MuscleGroup]? // Which muscle groups were trained
        let isEccentricFocused: Bool? // Was it eccentric-focused (e.g., heavy negatives)
        
        // Non-exercise inputs
        let dailySteps: Int? // Total steps
        let activeEnergyCalories: Double? // Active calories burned
        let nonWorkoutMETmin: Double? // MET-minutes outside workouts
        
        // Recovery inputs
        let hrvOvernight: Double? // Last night's HRV
        let hrvBaseline: Double? // 7-day HRV baseline
        let rmrToday: Double? // Today's resting HR
        let rmrBaseline: Double? // 7-day RHR baseline
        let sleepQuality: Int? // Sleep score (0-100)
        
        // User settings
        let userFTP: Double? // Functional Threshold Power
        let userMaxHR: Double? // Max heart rate
        let userRestingHR: Double? // Resting heart rate
        let userBodyMass: Double? // Body weight (kg)
    }
    
    struct HRDataPoint: Codable {
        let time: TimeInterval
        let hr: Double
    }
}

// MARK: - Strain Score Calculator

class StrainScoreCalculator {
    
    // MARK: - Constants
    private static let cardioScaleFactor: Double = 18.0 // k_c for cardio load
    private static let strengthScaleFactor: Double = 2.0 // k_s for strength load (increased from 1.5)
    private static let nonExerciseScaleFactor: Double = 12.0 // k_n for non-exercise load (increased from 8.0)
    private static let intensityBlendPower: Double = 0.6 // HR vs Power blend ratio
    private static let zoneWeightExponent: Double = 2.2 // Exponent for intensity weight
    private static let dailyCap: Double = 30.0 // Max points from non-exercise activity (increased from 20.0)
    private static let recoveryModulationRange: Double = 0.15 // ±15% recovery modulation
    
    /// Calculate strain score from inputs using Whoop-like algorithm
    static func calculate(inputs: StrainScore.StrainInputs) -> StrainScore {
        let subScores = calculateSubScores(inputs: inputs)
        let recoveryFactor = subScores.recoveryFactor
        
        // Primary approach: Use continuous HR data if available (Whoop-like)
        if let continuousHR = inputs.continuousHRData,
           let restingHR = inputs.userRestingHR,
           let maxHR = inputs.userMaxHR,
           !continuousHR.isEmpty {
            
            // Calculate daily TRIMP from continuous HR
            let dailyTRIMP = calculateTRIMP(
                heartRateData: continuousHR,
                restingHR: restingHR,
                maxHR: maxHR
            )
            
            // Convert TRIMP to EPOC estimate (Whoop-like)
            let epoc = convertTRIMPToEPOC(trimp: dailyTRIMP)
            
            // Apply Whoop's logarithmic strain formula
            let strain = calculateWhoopStrain(epoc: epoc)
            
            // Apply recovery modulation
            let adjustedStrain = strain * recoveryFactor
            
            // Convert from 0-100 to 0-18 scale
            let scaledStrain = (adjustedStrain / 100.0) * 18.0
            let finalScore = max(0.0, min(18.0, scaledStrain))
            let band = determineBand(score: finalScore)
            
            return StrainScore(
                score: finalScore,
                band: band,
                subScores: subScores,
                inputs: inputs,
                calculatedAt: Date()
            )
        }
        
        // Fallback approach: Use Whoop-style TRIMP from workout data + daily activity
        let whoopStyleScore = calculateWhoopStyleStrain(inputs: inputs, recoveryFactor: recoveryFactor)
        
        return StrainScore(
            score: whoopStyleScore.score,
            band: whoopStyleScore.band,
            subScores: subScores,
            inputs: inputs,
            calculatedAt: Date()
        )
    }
    
    // MARK: - Sub-Score Calculations
    
    private static func calculateSubScores(inputs: StrainScore.StrainInputs) -> StrainScore.SubScores {
        let cardioScore = calculateCardioLoad(inputs: inputs)
        let strengthScore = calculateStrengthLoad(inputs: inputs)
        let nonExerciseScore = calculateNonExerciseLoad(inputs: inputs)
        let recoveryFactor = calculateRecoveryFactor(inputs: inputs)
        
        return StrainScore.SubScores(
            cardioLoad: cardioScore,
            strengthLoad: strengthScore,
            nonExerciseLoad: nonExerciseScore,
            recoveryFactor: recoveryFactor
        )
    }
    
    // MARK: - Cardio Load Calculation (TRIMP-based)
    
    private static func calculateCardioLoad(inputs: StrainScore.StrainInputs) -> Int {
        guard let dailyTRIMP = inputs.cardioDailyTRIMP,
              dailyTRIMP > 0 else { return 0 }
        
        // Apply logarithmic compression: CardioLoad = k_c * log10(TRIMP_raw + 1)
        // This mimics the diminishing returns at higher intensities
        let compressedTRIMP = cardioScaleFactor * log10(dailyTRIMP + 1.0)
        
        // Additional scaling based on duration and intensity
        var scaledScore = compressedTRIMP
        
        // Boost for sustained efforts (duration component)
        if let duration = inputs.cardioDurationMinutes, duration > 60 {
            let durationBonus = min(10.0, (duration - 60) * 0.1) // Up to 10 point bonus for long rides
            scaledScore += durationBonus
        }
        
        // Boost for high intensity efforts (IF component)
        if let intensity = inputs.averageIntensityFactor, intensity > 0.8 {
            let intensityBonus = min(15.0, (intensity - 0.8) * 75.0) // Up to 15 point bonus for high IF
            scaledScore += intensityBonus
        }
        
        return max(0, min(100, Int(scaledScore)))
    }
    
    // MARK: - Strength Load Calculation (sRPE + sensor-based)
    
    private static func calculateStrengthLoad(inputs: StrainScore.StrainInputs) -> Int {
        guard let rpe = inputs.strengthSessionRPE,
              let duration = inputs.strengthDurationMinutes,
              duration > 0,
              rpe >= 1.0 && rpe <= 10.0 else { return 0 }
        
        // Base calculation: StrengthLoad = k_s * (sRPE * minutes)
        var baseLoad = strengthScaleFactor * (rpe * duration)
        
        // Volume enhancement (if available)
        if let volume = inputs.strengthVolume,
           let bodyMass = inputs.userBodyMass,
           bodyMass > 0 {
            
            // Volume term: (volume_kg / body_mass)^0.25 (capped)
            let relativeVolume = volume / bodyMass
            let volumeTerm = min(2.0, pow(relativeVolume, 0.25)) // Cap at 2x multiplier
            
            baseLoad *= (1.0 + 0.15 * volumeTerm)
        }
        
        // Sets enhancement (if available)
        if let sets = inputs.strengthSets, sets > 0 {
            let setsMultiplier = min(1.3, 1.0 + (Double(sets - 1) * 0.05)) // Up to 30% bonus for high volume
            baseLoad *= setsMultiplier
        }
        
        // Apply logarithmic compression for diminishing returns
        let compressedLoad = cardioScaleFactor * 0.8 * log10(baseLoad + 1.0) // Slightly lower scale than cardio
        
        return max(0, min(100, Int(compressedLoad)))
    }
    
    // MARK: - Non-Exercise Load Calculation
    
    private static func calculateNonExerciseLoad(inputs: StrainScore.StrainInputs) -> Int {
        var totalLoad: Double = 0
        
        // Steps contribution - more generous calculation for regular users
        if let steps = inputs.dailySteps, steps > 0 {
            // More generous baseline: 2000 steps = ~20 MET-minutes (increased from 15)
            // This better reflects the effort of daily walking/activity
            let baseSteps = 2000.0
            let metMinutesBaseline = 20.0 // Increased from 15.0 for better sensitivity
            let metMinutes = metMinutesBaseline * (Double(steps) / baseSteps)
            
            totalLoad += metMinutes
        }
        
        // Active energy contribution - more generous conversion
        if let activeCalories = inputs.activeEnergyCalories, activeCalories > 0 {
            // More generous conversion: 1 calorie ≈ 0.003 MET-minutes (increased from 0.002)
            let metMinutesFromCalories = activeCalories * 0.003
            totalLoad += metMinutesFromCalories
        }
        
        // Direct MET-minutes (if available)
        if let metmin = inputs.nonWorkoutMETmin {
            totalLoad += metmin
        }
        
        // Apply logarithmic compression with higher daily cap
        let cappedLoad = min(totalLoad, dailyCap * 1.5) // Increased cap from 20 to 30
        let compressedLoad = nonExerciseScaleFactor * log1p(cappedLoad)
        
        return max(0, min(100, Int(compressedLoad)))
    }
    
    // MARK: - Recovery Factor Calculation
    
    private static func calculateRecoveryFactor(inputs: StrainScore.StrainInputs) -> Double {
        var zHRV: Double = 0
        var zRHR: Double = 0
        var zSleep: Double = 0
        
        // HRV z-score
        if let hrvToday = inputs.hrvOvernight,
           let hrvBase = inputs.hrvBaseline,
           hrvBase > 0 {
            zHRV = (hrvToday - hrvBase) / hrvBase // Simple percentage change
        }
        
        // RHR z-score (inverted - lower RHR is better)  
        if let rhrToday = inputs.rmrToday,
           let rhrBase = inputs.rmrBaseline,
           rhrBase > 0 {
            zRHR = (rhrBase - rhrToday) / rhrBase // Lower today = positive
        }
        
        // Sleep quality z-score
        if let sleepQuality = inputs.sleepQuality {
            zSleep = (Double(sleepQuality) - 75.0) / 25.0 // Center around 75
        }
        
        // Blend recovery signals with weights
        let recoverySignal = (0.6 * zHRV) + (0.3 * zRHR) + (0.1 * zSleep)
        let clampedSignal = max(-1.0, min(1.0, recoverySignal))
        
        // Map to recovery factor: R = 1 + 0.15 * signal (range ~0.85-1.15)
        return 1.0 + (recoveryModulationRange * clampedSignal)
    }
    
    // MARK: - Non-Linear Compression
    
    private enum CompressionType {
        case cardio
        case strength
        case nonExercise
    }
    
    private static func applyNonLinearCompression(_ rawScore: Double, type: CompressionType) -> Double {
        // Apply different compression curves for different load types
        switch type {
        case .cardio:
            // Cardio has relatively linear scaling at low values, exponential compression at high
            return rawScore * (1.0 - pow(rawScore / 100.0, 1.5))
        case .strength:
            // Strength compresses more aggressively (weight lifting fatigue is non-linear)
            return rawScore * (1.0 - pow(rawScore / 100.0, 2.0))
        case .nonExercise:
            // Non-exercise compresses moderately
            return rawScore * (1.0 - pow(rawScore / 100.0, 1.8))
        }
    }
    
    // MARK: - Whoop-Style Strain Calculation
    
    /// Get workout type multiplier based on metabolic cost research
    private static func getWorkoutTypeMultiplier(workoutTypes: [String]?) -> Double {
        guard let types = workoutTypes, !types.isEmpty else { return 1.0 }
        
        // Find the highest multiplier from all workout types
        var maxMultiplier: Double = 1.0
        
        for type in types {
            let multiplier: Double
            switch type.lowercased() {
            case let t where t.contains("run"):
                multiplier = 1.2  // Running: higher impact than cycling
            case let t where t.contains("swim"):
                multiplier = 1.3  // Swimming: full body, very demanding
            case let t where t.contains("cycle"), let t where t.contains("bike"):
                multiplier = 1.0  // Cycling: baseline
            case let t where t.contains("walk"):
                multiplier = 0.6  // Walking: lower intensity
            case let t where t.contains("hik"):
                multiplier = 0.9  // Hiking: moderate
            case let t where t.contains("row"):
                multiplier = 1.15 // Rowing: full body cardio
            default:
                multiplier = 1.0
            }
            maxMultiplier = max(maxMultiplier, multiplier)
        }
        
        return maxMultiplier
    }
    
    /// Calculate training load for a single strength workout
    /// Returns a score representing the physiological demand
    public static func calculateWorkoutLoad(
        duration: TimeInterval,
        rpe: Double,
        muscleGroups: [MuscleGroup]?,
        isEccentricFocused: Bool = false
    ) -> Double {
        let durationMinutes = duration / 60.0
        
        // Apply intelligent muscle group multiplier
        var muscleGroupFactor: Double = 1.0
        if let muscleGroups = muscleGroups, !muscleGroups.isEmpty {
            muscleGroupFactor = calculateMultiSelectionFactor(muscleGroups: muscleGroups)
        }
        
        // Calculate TRIMP (same formula as strain calculation)
        let estimatedHRFraction = max(0.5, (rpe - 1.0) / 9.0)
        var load = estimatedHRFraction * durationMinutes * 120 * muscleGroupFactor
        
        // Apply eccentric multiplier if focused on negatives
        if isEccentricFocused {
            load *= 1.3
        }
        
        return load
    }
    
    /// Calculate intelligent multiplier for multiple muscle group selections
    /// Research-backed approach: compound movements and multiple muscle groups = higher systemic stress
    private static func calculateMultiSelectionFactor(muscleGroups: [MuscleGroup]) -> Double {
        // Single selection - use that factor
        if muscleGroups.count == 1 {
            return muscleGroups[0].systemicFatigueFactor
        }
        
        // Multiple selections - intelligent compounding
        let hasFullBody = muscleGroups.contains(.fullBody)
        let hasConditioning = muscleGroups.contains(.conditioning)
        let hasLegs = muscleGroups.contains(.legs)
        let hasPush = muscleGroups.contains(.push) || muscleGroups.contains(.chest) || muscleGroups.contains(.shoulders)
        let hasPull = muscleGroups.contains(.pull) || muscleGroups.contains(.back)
        
        // Full body is inherently max - don't compound further
        if hasFullBody {
            let baseFactor = MuscleGroup.fullBody.systemicFatigueFactor
            // Add conditioning on top if present
            return hasConditioning ? baseFactor + 0.1 : baseFactor
        }
        
        // Upper/Lower split (very common): Push/Pull + Legs
        if hasLegs && (hasPush || hasPull) {
            // Research: upper+lower same session = high systemic stress
            // Use legs base (1.5) + 10% for upper body volume
            return 1.6
        }
        
        // Push + Pull (common full upper body day)
        if hasPush && hasPull {
            // Take average of push/pull + bonus for volume
            let pushFactor = muscleGroups.first(where: { $0 == .push || $0 == .chest || $0 == .shoulders })?.systemicFatigueFactor ?? 1.1
            let pullFactor = muscleGroups.first(where: { $0 == .pull || $0 == .back })?.systemicFatigueFactor ?? 1.2
            return ((pushFactor + pullFactor) / 2) + 0.15  // +15% volume bonus
        }
        
        // Multiple specific muscles from same category
        let specificMuscles = muscleGroups.filter { $0.category == .specificMuscle }
        if specificMuscles.count >= 2 {
            // Take max + bonus for volume (10%)
            let maxFactor = specificMuscles.map { $0.systemicFatigueFactor }.max() ?? 1.0
            return maxFactor + 0.1
        }
        
        // Conditioning adds metabolic stress
        if hasConditioning {
            let baseFactor = muscleGroups.filter { $0 != .conditioning }.map { $0.systemicFatigueFactor }.max() ?? 1.0
            return baseFactor + 0.2  // +20% for metabolic component
        }
        
        // Default: take max factor + small bonus for multi-group
        let maxFactor = muscleGroups.map { $0.systemicFatigueFactor }.max() ?? 1.0
        return maxFactor + 0.05
    }
    
    /// Calculate strain using Whoop-style approach: TRIMP backbone + daily activity adjustments
    private static func calculateWhoopStyleStrain(inputs: StrainScore.StrainInputs, recoveryFactor: Double) -> (score: Double, band: StrainScore.StrainBand) {
        
        // 1. Calculate TRIMP from workout data (if available)
        var workoutTRIMP: Double = 0
        
        if let cardioTRIMP = inputs.cardioDailyTRIMP, cardioTRIMP > 0 {
            // Apply workout type multiplier
            let typeMultiplier = getWorkoutTypeMultiplier(workoutTypes: inputs.workoutTypes)
            workoutTRIMP += cardioTRIMP * typeMultiplier
            
            Logger.debug("   Workout type multiplier: \(String(format: "%.2f", typeMultiplier))")
        }
        
        // Add strength training as equivalent TRIMP
        var strengthTRIMP: Double = 0
        var hasBothCardioAndStrength = false
        
        if let strengthDuration = inputs.strengthDurationMinutes,
           strengthDuration > 0 {
            
            // Convert strength to equivalent TRIMP
            // Use RPE if available, otherwise assume moderate intensity (RPE 6-7)
            let rpe = inputs.strengthSessionRPE ?? 6.5 // Default to moderate-hard
            
            // Apply intelligent muscle group multiplier
            var muscleGroupFactor: Double = 1.0
            if let muscleGroups = inputs.muscleGroupsTrained, !muscleGroups.isEmpty {
                muscleGroupFactor = calculateMultiSelectionFactor(muscleGroups: muscleGroups)
            }
            
            // More generous strength TRIMP calculation
            // Strength training is metabolically demanding even at lower heart rates
            let estimatedHRFraction = max(0.5, (rpe - 1.0) / 9.0) // Minimum 50% intensity
            strengthTRIMP = estimatedHRFraction * strengthDuration * 120 * muscleGroupFactor
            
            // Apply eccentric multiplier if focused on negatives
            if let isEccentric = inputs.isEccentricFocused, isEccentric {
                strengthTRIMP *= 1.3  // 30% more demanding
            }
            
            workoutTRIMP += strengthTRIMP
            
            // Detect concurrent training
            if let cardioTRIMP = inputs.cardioDailyTRIMP, cardioTRIMP > 0 {
                hasBothCardioAndStrength = true
            }
        }
        
        // Apply concurrent training interference penalty
        // Research shows cardio + strength same day increases total stress
        if hasBothCardioAndStrength {
            let interferenceFactor = 1.15  // 15% penalty for concurrent training
            workoutTRIMP *= interferenceFactor
            Logger.debug("   Concurrent training detected: +15% interference penalty")
        }
        
        // 2. Add daily activity with intelligent calorie-step blending
        var dailyActivityAdjustment: Double = 0
        
        // Calculate base from steps
        var stepBasedStrain: Double = 0
        if let steps = inputs.dailySteps, steps > 0 {
            stepBasedStrain = Double(steps) / 1000.0 * 0.5
        }
        
        // Calculate from active calories (better captures intensity)
        var calorieBasedStrain: Double = 0
        if let activeCalories = inputs.activeEnergyCalories, activeCalories > 0 {
            // ~7.5 cal/min = moderate-vigorous activity mix
            let estimatedMinutes = activeCalories / 7.5
            calorieBasedStrain = estimatedMinutes * 0.6 * 0.1 // Scale to match step-based
        }
        
        // Use whichever is higher (more generous)
        dailyActivityAdjustment = max(stepBasedStrain, calorieBasedStrain)
        
        // Detect high-intensity activity by comparing actual vs expected calories
        if let steps = inputs.dailySteps, let activeCalories = inputs.activeEnergyCalories,
           steps > 0, activeCalories > 0 {
            let expectedCaloriesFromSteps = Double(steps) * 0.04 // ~0.04 cal/step
            let intensityRatio = activeCalories / expectedCaloriesFromSteps
            
            // High intensity beyond just walking
            if intensityRatio > 1.5 {
                let bonusStrain = min(2.0, (intensityRatio - 1.0) * 1.5)
                dailyActivityAdjustment += bonusStrain
            }
        }
        
        // Apply recovery-adjusted perception
        // Poor recovery makes daily activity feel harder
        if recoveryFactor < 0.95 {
            let amplification = 1.0 + (0.95 - recoveryFactor) * 2.0
            dailyActivityAdjustment *= amplification
        }
        
        // Cap at reasonable maximum
        dailyActivityAdjustment = min(7.0, dailyActivityAdjustment)
        
        // 3. Calculate total TRIMP
        let totalTRIMP = workoutTRIMP + dailyActivityAdjustment
        
        // 4. Convert TRIMP to EPOC estimate
        let epoc = convertTRIMPToEPOC(trimp: totalTRIMP)
        
        // 5. Apply Whoop's logarithmic strain formula
        let strain = calculateWhoopStrain(epoc: epoc)
        
        // 6. Apply recovery modulation
        let adjustedStrain = strain * recoveryFactor
        
        // 7. Scale to 0-18 range and determine band
        // Convert from 0-100 to 0-18 scale
        let scaledStrain = (adjustedStrain / 100.0) * 18.0
        let finalScore = max(0.0, min(18.0, scaledStrain))
        let band = determineBand(score: finalScore)
        
        Logger.debug("🏃 Whoop-Style Strain Calculation:")
        Logger.debug("   Workout TRIMP: \(workoutTRIMP)")
        Logger.debug("   Daily Activity Adjustment: \(dailyActivityAdjustment)")
        Logger.debug("   Total TRIMP: \(totalTRIMP)")
        Logger.debug("   EPOC: \(epoc)")
        Logger.debug("   Raw Strain: \(strain)")
        Logger.debug("   Recovery Factor: \(recoveryFactor)")
        Logger.debug("   Final Score: \(finalScore)")
        
        return (score: finalScore, band: band)
    }
    
    // MARK: - Whoop-like Helper Functions
    
    /// Convert TRIMP to EPOC estimate (Whoop-like approach)
    private static func convertTRIMPToEPOC(trimp: Double) -> Double {
        // EPOC estimation based on research: EPOC ≈ 0.15 * TRIMP^1.2
        // This creates a non-linear relationship where higher TRIMP leads to exponentially higher EPOC
        return 0.15 * pow(trimp, 1.2)
    }
    
    /// Calculate strain using Whoop's logarithmic formula
    private static func calculateWhoopStrain(epoc: Double) -> Double {
        // Whoop's formula: Strain = 21 × log(EPOC + 1) / log(EPOC_max + 1)
        // We'll use a reasonable EPOC_max based on research (typically 200-400 ml/kg)
        let epocMax: Double = 300.0 // Reasonable maximum EPOC for most people
        
        let strain = 21.0 * log(epoc + 1.0) / log(epocMax + 1.0)
        
        // Scale to 0-18 range (similar to RPE but more granular)
        return strain * (18.0 / 21.0)
    }
    
    // MARK: - Helper Functions
    
    private static func determineBand(score: Double) -> StrainScore.StrainBand {
        // Updated bands for 0-18 scale
        switch score {
        case 0..<4.5: return .low      // 0-4.4 (light activity)
        case 4.5..<9.0: return .moderate  // 4.5-8.9 (moderate activity)
        case 9.0..<14.4: return .high     // 9.0-14.3 (high activity)
        default: return .extreme        // 14.4-18.0 (extreme activity)
        }
    }
    
    // MARK: - TRIMP Calculation Helper
    
    /// Calculate TRIMP from heart rate data points
    static func calculateTRIMP(heartRateData: [StrainScore.HRDataPoint], 
                              restingHR: Double, 
                              maxHR: Double) -> Double {
        guard !heartRateData.isEmpty,
              maxHR > restingHR,
              restingHR > 0 else { return 0 }
        
        var trimpSum: Double = 0
        let maxMinusRest = maxHR - restingHR
        
        for (index, dataPoint) in heartRateData.enumerated() {
            let hrRR = max(0, min(1, (dataPoint.hr - restingHR) / maxMinusRest))
            let intensityWeight = pow(hrRR, zoneWeightExponent)
            
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
    
    /// Calculate TRIMP with power data (blended HR + Power)
    static func calculateBlendedTRIMP(heartRateData: [(time: TimeInterval, hr: Double, power: Double)],
                                     restingHR: Double,
                                     maxHR: Double,
                                     ftp: Double) -> Double {
        guard !heartRateData.isEmpty,
              maxHR > restingHR,
              ftp > 0 else { return 0 }
        
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
            
            let intensityWeight = pow(clampedIntensity, zoneWeightExponent)
            
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
}

// MARK: - Strain Score Extensions

extension StrainScore {
    /// Generate AI daily brief based on strain score and inputs
    var dailyBrief: String {
        switch band {
        case .low:
            return generateLowBrief()
        case .moderate:
            return generateModerateBrief()
        case .high:
            return generateHighBrief()
        case .extreme:
            return generateExtremeBrief()
        }
    }
    
    private func generateLowBrief() -> String {
        var brief = "Low strain day"
        
        if let cardio = inputs.cardioDurationMinutes, cardio > 0 {
            brief += " — \(Int(cardio)) min cardio"
        }
        
        if inputs.strengthSessionRPE != nil {
            brief += " — some strength work"
        }
        
        brief += ". Recovery-focussed approach."
        return brief
    }
    
    private func generateModerateBrief() -> String {
        return "Moderate strain — good balance of training and recovery."
    }
    
    private func generateHighBrief() -> String {
        var brief = "High strain day"
        
        if let cardio = inputs.cardioDurationMinutes, cardio > 120 {
            brief += " — long endurance session"
        }
        
        if let strength = inputs.strengthSessionRPE, strength >= 8 {
            brief += " — intense strength work"
        }
        
        brief += ". Prioritize recovery tomorrow."
        return brief
    }
    
    private func generateExtremeBrief() -> String {
        return "Extreme strain — consider additional recovery time. Monitor fatigue levels."
    }
    
    /// Formatted score for display (0-18 scale with 1 decimal)
    var formattedScore: String {
        return String(format: "%.1f", score)
    }
    
    /// Color for the score band
    var bandColor: String {
        return band.color
    }
    
    /// Description of the strain band
    var bandDescription: String {
        return band.description
    }
    
    /// Detailed breakdown of sub-scores
    var scoreBreakdown: String {
        return "Cardio: \(subScores.cardioLoad), Strength: \(subScores.strengthLoad), Activity: \(subScores.nonExerciseLoad), Recovery Factor: \(String(format: "%.2f", subScores.recoveryFactor))"
    }
    
}
