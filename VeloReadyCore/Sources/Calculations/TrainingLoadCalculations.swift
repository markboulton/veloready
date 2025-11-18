import Foundation

/// Pure calculation logic for training load (CTL/ATL/TSB)
/// Consolidates 4 duplicate implementations into single source of truth
public struct TrainingLoadCalculations {
    
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
}
