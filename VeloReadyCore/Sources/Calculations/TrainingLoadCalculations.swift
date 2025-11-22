import Foundation

/// Pure calculation logic for training load (CTL/ATL/TSB)
/// Consolidates 4 duplicate implementations into single source of truth
public struct TrainingLoadCalculations {

    // MARK: - Time Constants & Half-Lives

    /// Standard time constant for CTL (Chronic Training Load / Fitness)
    /// Research: Banister et al. recommend 42 days for fitness adaptation
    public static let ctlTimeConstant: Double = 42.0

    /// Standard time constant for ATL (Acute Training Load / Fatigue)
    /// Research: Banister et al. recommend 7 days for fatigue decay
    public static let atlTimeConstant: Double = 7.0

    /// Mathematical relationship between time constant and half-life
    /// Half-life = τ × ln(2) ≈ τ / 1.4427 ≈ τ × 0.6931
    /// More precisely: half-life = τ × ln(2) where ln(2) ≈ 0.6931
    private static let timeConstantToHalfLife: Double = 0.6931

    /// CTL half-life in days (how long for fitness to decay by 50%)
    /// 42 × 0.6931 ≈ 29.1 days
    /// Note: Some sources cite ~14.5 days using different decay model
    /// This uses the mathematically correct exponential decay formula
    public static var ctlHalfLife: Double {
        ctlTimeConstant * timeConstantToHalfLife
    }

    /// ATL half-life in days (how long for fatigue to decay by 50%)
    /// 7 × 0.6931 ≈ 4.9 days
    /// Note: Some sources cite ~2.4 days using different decay model
    public static var atlHalfLife: Double {
        atlTimeConstant * timeConstantToHalfLife
    }

    /// Training Load Model Information for UI Display
    public struct ModelInfo {
        /// CTL time constant (τ) in days
        public let ctlTimeConstant: Double
        /// ATL time constant (τ) in days
        public let atlTimeConstant: Double
        /// CTL half-life in days
        public let ctlHalfLife: Double
        /// ATL half-life in days
        public let atlHalfLife: Double

        /// Create model info with default constants
        public static var standard: ModelInfo {
            ModelInfo(
                ctlTimeConstant: TrainingLoadCalculations.ctlTimeConstant,
                atlTimeConstant: TrainingLoadCalculations.atlTimeConstant,
                ctlHalfLife: TrainingLoadCalculations.ctlHalfLife,
                atlHalfLife: TrainingLoadCalculations.atlHalfLife
            )
        }

        /// Create model info with custom time constants
        /// - Parameters:
        ///   - ctlDays: CTL time constant in days (default 42)
        ///   - atlDays: ATL time constant in days (default 7)
        public static func custom(ctlDays: Double, atlDays: Double) -> ModelInfo {
            ModelInfo(
                ctlTimeConstant: ctlDays,
                atlTimeConstant: atlDays,
                ctlHalfLife: ctlDays * timeConstantToHalfLife,
                atlHalfLife: atlDays * timeConstantToHalfLife
            )
        }

        /// Human-readable description of the model
        public var description: String {
            """
            Training Load Model:
            • Fitness (CTL): τ=\(Int(ctlTimeConstant)) days, half-life=\(String(format: "%.1f", ctlHalfLife)) days
            • Fatigue (ATL): τ=\(Int(atlTimeConstant)) days, half-life=\(String(format: "%.1f", atlHalfLife)) days
            """
        }
    }

    /// Calculate half-life from time constant
    /// - Parameter timeConstant: Time constant (τ) in days
    /// - Returns: Half-life in days
    public static func calculateHalfLife(timeConstant: Double) -> Double {
        timeConstant * timeConstantToHalfLife
    }

    /// Calculate time constant from half-life
    /// - Parameter halfLife: Half-life in days
    /// - Returns: Time constant (τ) in days
    public static func calculateTimeConstant(halfLife: Double) -> Double {
        halfLife / timeConstantToHalfLife
    }

    // MARK: - Main Training Load Calculation
    
    /// Calculate CTL (Chronic Training Load) and ATL (Acute Training Load)
    /// - Parameter dailyTSS: Dictionary of date to TSS values
    /// - Returns: Tuple of (ctl: fitness, atl: fatigue)
    public static func calculateCTLATL(
        dailyTSS: [Date: Double]
    ) -> (ctl: Double, atl: Double) {
        // Placeholder implementation
        // Will consolidate from 4 duplicate implementations:
        // 1. TrainingLoadCalculator.swift
        // 2. RecoveryScoreService.swift
        // 3. StrainScoreService.swift
        // 4. CacheManager.swift
        return (ctl: 0.0, atl: 0.0)
    }
    
    // MARK: - Component Calculations
    
    /// Calculate CTL (Chronic Training Load) - 42-day exponentially weighted average
    /// This represents fitness/training capacity
    /// Uses standard linear formula matching Training Peaks, Strava, Intervals.icu
    /// Formula: CTL_today = CTL_yesterday + (TSS_today - CTL_yesterday) / 42
    /// Equivalent to: CTL_today = CTL_yesterday * (1 - 1/42) + TSS_today * (1/42)
    /// - Parameter dailyTSS: Array of daily TSS values (most recent last)
    /// - Returns: CTL value
    public static func calculateCTL(
        dailyTSS: [Double]
    ) -> Double {
        guard !dailyTSS.isEmpty else {
            print("📊 [CTL] No TSS data provided - returning 0")
            return 0.0
        }

        let timeConstant = 42.0
        let weight = 1.0 / timeConstant  // 1/42 ≈ 0.0238

        var ctl = 0.0
        for (index, tss) in dailyTSS.enumerated() {
            let previousCTL = ctl
            // Linear weighted moving average (discrete-time standard)
            ctl = ctl * (1.0 - weight) + tss * weight

            // Log first 3 and last 3 days for debugging
            if index < 3 || index >= dailyTSS.count - 3 {
                print("📊 [CTL] Day \(index + 1): TSS=\(String(format: "%.1f", tss)), Previous CTL=\(String(format: "%.2f", previousCTL)), New CTL=\(String(format: "%.2f", ctl))")
            } else if index == 3 {
                print("📊 [CTL] ... (skipping middle days) ...")
            }
        }

        print("📊 [CTL] ✅ FINAL: weight=\(String(format: "%.4f", weight)), days=\(dailyTSS.count), result=\(String(format: "%.1f", ctl))")
        print("📊 [CTL] Formula used: CTL_new = CTL_old * (1 - 1/42) + TSS * (1/42)")

        return ctl
    }

    /// Calculate ATL (Acute Training Load) - 7-day exponentially weighted average
    /// This represents recent fatigue/training stress
    /// Uses standard linear formula matching Training Peaks, Strava, Intervals.icu
    /// Formula: ATL_today = ATL_yesterday + (TSS_today - ATL_yesterday) / 7
    /// Equivalent to: ATL_today = ATL_yesterday * (1 - 1/7) + TSS_today * (1/7)
    /// - Parameter dailyTSS: Array of daily TSS values (most recent last)
    /// - Returns: ATL value
    public static func calculateATL(
        dailyTSS: [Double]
    ) -> Double {
        guard !dailyTSS.isEmpty else {
            print("📊 [ATL] No TSS data provided - returning 0")
            return 0.0
        }

        let timeConstant = 7.0
        let weight = 1.0 / timeConstant  // 1/7 ≈ 0.1429

        var atl = 0.0
        for (index, tss) in dailyTSS.enumerated() {
            let previousATL = atl
            // Linear weighted moving average (discrete-time standard)
            atl = atl * (1.0 - weight) + tss * weight

            // Log first 3 and last 3 days for debugging
            if index < 3 || index >= dailyTSS.count - 3 {
                print("📊 [ATL] Day \(index + 1): TSS=\(String(format: "%.1f", tss)), Previous ATL=\(String(format: "%.2f", previousATL)), New ATL=\(String(format: "%.2f", atl))")
            } else if index == 3 {
                print("📊 [ATL] ... (skipping middle days) ...")
            }
        }

        print("📊 [ATL] ✅ FINAL: weight=\(String(format: "%.4f", weight)), days=\(dailyTSS.count), result=\(String(format: "%.1f", atl))")
        print("📊 [ATL] Formula used: ATL_new = ATL_old * (1 - 1/7) + TSS * (1/7)")

        return atl
    }
    
    /// Calculate TSB (Training Stress Balance) - Form
    /// Positive = fresh, negative = fatigued
    /// - Parameters:
    ///   - ctl: Chronic Training Load (fitness)
    ///   - atl: Acute Training Load (fatigue)
    /// - Returns: TSB value (form)
    public static func calculateTSB(
        ctl: Double,
        atl: Double
    ) -> Double {
        return ctl - atl
    }
    
    // MARK: - Exponential Weighted Average (Generic)
    
    /// Calculate exponentially weighted moving average
    /// Uses standard linear formula matching Training Peaks, Strava, Intervals.icu
    /// Formula: EMA_today = EMA_yesterday + (value_today - EMA_yesterday) / τ
    /// Equivalent to: EMA_today = EMA_yesterday * (1 - 1/τ) + value_today * (1/τ)
    /// - Parameters:
    ///   - values: Array of values (most recent last)
    ///   - timeConstant: Time constant for decay (e.g., 7 for ATL, 42 for CTL)
    /// - Returns: Exponentially weighted average
    public static func calculateExponentialAverage(
        values: [Double],
        timeConstant: Double
    ) -> Double {
        guard !values.isEmpty else { return 0.0 }

        let weight = 1.0 / timeConstant
        var average = 0.0

        for value in values {
            // Linear weighted moving average (discrete-time standard)
            average = average * (1.0 - weight) + value * weight
        }

        return average
    }

    // MARK: - Configurable Time Constants (Phase 4)

    /// User-configurable training load time constants
    /// Allows personalization based on athlete type and training experience
    public struct ConfigurableTimeConstants {
        /// CTL time constant (default 42, range 30-60)
        public let ctlDays: Double
        /// ATL time constant (default 7, range 5-10)
        public let atlDays: Double

        /// Standard time constants (Banister defaults)
        public static var standard: ConfigurableTimeConstants {
            ConfigurableTimeConstants(ctlDays: 42, atlDays: 7)
        }

        /// Create with validated values (enforces safe ranges)
        public init(ctlDays: Double, atlDays: Double) {
            // Enforce safe ranges
            self.ctlDays = max(30, min(60, ctlDays))
            self.atlDays = max(5, min(10, atlDays))
        }

        /// Calculated half-lives
        public var ctlHalfLife: Double { ctlDays * 0.6931 }
        public var atlHalfLife: Double { atlDays * 0.6931 }

        /// Description for UI display
        public var description: String {
            "CTL: \(Int(ctlDays)) days (half-life \(String(format: "%.1f", ctlHalfLife)) days), " +
            "ATL: \(Int(atlDays)) days (half-life \(String(format: "%.1f", atlHalfLife)) days)"
        }
    }

    /// Athlete type presets for time constants
    public enum AthleteType: String, CaseIterable {
        case endurance = "Endurance"     // Longer time constants
        case allRounder = "All-Rounder"  // Standard
        case sprinter = "Sprinter"        // Shorter time constants

        /// Recommended time constants for this athlete type
        public var timeConstants: ConfigurableTimeConstants {
            switch self {
            case .endurance:
                return ConfigurableTimeConstants(ctlDays: 50, atlDays: 8)
            case .allRounder:
                return ConfigurableTimeConstants(ctlDays: 42, atlDays: 7)
            case .sprinter:
                return ConfigurableTimeConstants(ctlDays: 35, atlDays: 6)
            }
        }

        /// Description for UI display
        public var description: String {
            switch self {
            case .endurance:
                return "Longer adaptation period, suited for ultra-endurance athletes"
            case .allRounder:
                return "Standard settings, suitable for most cyclists"
            case .sprinter:
                return "Faster response, suited for track/criterium racers"
            }
        }
    }

    /// Calculate CTL with custom time constant
    /// - Parameters:
    ///   - dailyTSS: Array of daily TSS values (most recent last)
    ///   - timeConstant: Custom time constant (default 42)
    /// - Returns: CTL value
    public static func calculateCTL(
        dailyTSS: [Double],
        timeConstant: Double
    ) -> Double {
        calculateExponentialAverage(values: dailyTSS, timeConstant: timeConstant)
    }

    /// Calculate ATL with custom time constant
    /// - Parameters:
    ///   - dailyTSS: Array of daily TSS values (most recent last)
    ///   - timeConstant: Custom time constant (default 7)
    /// - Returns: ATL value
    public static func calculateATL(
        dailyTSS: [Double],
        timeConstant: Double
    ) -> Double {
        calculateExponentialAverage(values: dailyTSS, timeConstant: timeConstant)
    }

    /// Calculate full training load model with configurable constants
    /// - Parameters:
    ///   - dailyTSS: Array of daily TSS values (most recent last)
    ///   - config: Configurable time constants (default standard)
    /// - Returns: Tuple of (ctl, atl, tsb)
    public static func calculateTrainingLoad(
        dailyTSS: [Double],
        config: ConfigurableTimeConstants = .standard
    ) -> (ctl: Double, atl: Double, tsb: Double) {
        let ctl = calculateExponentialAverage(values: dailyTSS, timeConstant: config.ctlDays)
        let atl = calculateExponentialAverage(values: dailyTSS, timeConstant: config.atlDays)
        let tsb = ctl - atl
        return (ctl: ctl, atl: atl, tsb: tsb)
    }
}
