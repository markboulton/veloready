import Foundation

/// Pure calculation logic for baseline calculations
/// No dependencies on iOS frameworks or UI
public struct BaselineCalculations {
    
    // MARK: - HRV Baseline
    
    /// Calculate 7-day HRV baseline (rolling average)
    /// - Parameter hrvValues: Array of daily HRV values (ms)
    /// - Returns: HRV baseline or nil if insufficient data
    public static func calculateHRVBaseline(
        hrvValues: [Double]
    ) -> Double? {
        guard !hrvValues.isEmpty else { return nil }
        
        // Calculate mean
        let sum = hrvValues.reduce(0, +)
        let average = sum / Double(hrvValues.count)
        
        return average
    }
    
    // MARK: - RHR Baseline
    
    /// Calculate 7-day RHR baseline (rolling average)
    /// - Parameter rhrValues: Array of daily RHR values (bpm)
    /// - Returns: RHR baseline or nil if insufficient data
    public static func calculateRHRBaseline(
        rhrValues: [Double]
    ) -> Double? {
        guard !rhrValues.isEmpty else { return nil }
        
        // Calculate mean
        let sum = rhrValues.reduce(0, +)
        let average = sum / Double(rhrValues.count)
        
        return average
    }
    
    // MARK: - Sleep Baseline
    
    /// Calculate 7-day sleep baseline (rolling average duration in hours)
    /// - Parameter sleepDurations: Array of daily sleep durations (hours)
    /// - Returns: Sleep baseline or nil if insufficient data
    public static func calculateSleepBaseline(
        sleepDurations: [Double]
    ) -> Double? {
        guard !sleepDurations.isEmpty else { return nil }
        
        // Calculate mean
        let sum = sleepDurations.reduce(0, +)
        let average = sum / Double(sleepDurations.count)
        
        return average
    }
    
    // MARK: - Sleep Score Baseline
    
    /// Calculate 7-day sleep score baseline (rolling average of 0-100 scores)
    /// - Parameter sleepScores: Array of daily sleep scores (0-100)
    /// - Returns: Sleep score baseline or nil if insufficient data
    public static func calculateSleepScoreBaseline(
        sleepScores: [Double]
    ) -> Double? {
        guard !sleepScores.isEmpty else { return nil }
        
        // Calculate mean
        let sum = sleepScores.reduce(0, +)
        let average = sum / Double(sleepScores.count)
        
        return average
    }
    
    // MARK: - Respiratory Baseline
    
    /// Calculate 7-day respiratory rate baseline (rolling average)
    /// - Parameter respiratoryRates: Array of daily respiratory rates (breaths/min)
    /// - Returns: Respiratory baseline or nil if insufficient data
    public static func calculateRespiratoryBaseline(
        respiratoryRates: [Double]
    ) -> Double? {
        guard !respiratoryRates.isEmpty else { return nil }
        
        // Calculate mean
        let sum = respiratoryRates.reduce(0, +)
        let average = sum / Double(respiratoryRates.count)
        
        return average
    }
}
