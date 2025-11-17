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
    /// Uses standard Banister/Coggan exponential decay formula matching Training Peaks, Strava, Intervals.icu
    /// Formula: CTL_today = CTL_yesterday * exp(-1/42) + TSS_today * (1 - exp(-1/42))
    /// - Parameter dailyTSS: Array of daily TSS values (most recent last)
    /// - Returns: CTL value
    public static func calculateCTL(
        dailyTSS: [Double]
    ) -> Double {
        guard !dailyTSS.isEmpty else { return 0.0 }

        let timeConstant = 42.0
        let decay = exp(-1.0 / timeConstant)  // e^(-1/42) ≈ 0.9763

        var ctl = 0.0
        for tss in dailyTSS {
            // Exponential weighted moving average (Banister/Coggan formula)
            ctl = ctl * decay + tss * (1.0 - decay)
        }
        
        // Debug: Log calculation details for verification
        #if DEBUG
        print("📊 CTL Calculation: decay=\(String(format: "%.4f", decay)), days=\(dailyTSS.count), result=\(String(format: "%.1f", ctl))")
        #endif

        return ctl
    }

    /// Calculate ATL (Acute Training Load) - 7-day exponentially weighted average
    /// This represents recent fatigue/training stress
    /// Uses standard Banister/Coggan exponential decay formula matching Training Peaks, Strava, Intervals.icu
    /// Formula: ATL_today = ATL_yesterday * exp(-1/7) + TSS_today * (1 - exp(-1/7))
    /// - Parameter dailyTSS: Array of daily TSS values (most recent last)
    /// - Returns: ATL value
    public static func calculateATL(
        dailyTSS: [Double]
    ) -> Double {
        guard !dailyTSS.isEmpty else { return 0.0 }

        let timeConstant = 7.0
        let decay = exp(-1.0 / timeConstant)  // e^(-1/7) ≈ 0.8668

        var atl = 0.0
        for tss in dailyTSS {
            // Exponential weighted moving average (Banister/Coggan formula)
            atl = atl * decay + tss * (1.0 - decay)
        }
        
        // Debug: Log calculation details for verification
        #if DEBUG
        print("📊 ATL Calculation: decay=\(String(format: "%.4f", decay)), days=\(dailyTSS.count), result=\(String(format: "%.1f", atl))")
        #endif

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
    /// Uses standard exponential decay formula matching Training Peaks, Strava, Intervals.icu
    /// Formula: EMA_today = EMA_yesterday * exp(-1/τ) + value_today * (1 - exp(-1/τ))
    /// - Parameters:
    ///   - values: Array of values (most recent last)
    ///   - timeConstant: Time constant for decay (e.g., 7 for ATL, 42 for CTL)
    /// - Returns: Exponentially weighted average
    public static func calculateExponentialAverage(
        values: [Double],
        timeConstant: Double
    ) -> Double {
        guard !values.isEmpty else { return 0.0 }

        let decay = exp(-1.0 / timeConstant)
        var average = 0.0

        for value in values {
            // Exponential weighted moving average (Banister/Coggan formula)
            average = average * decay + value * (1.0 - decay)
        }

        return average
    }
}
