import Foundation

/// Pure training load calculation functions
/// These functions are extracted from the iOS app for independent testing
public struct TrainingLoadCalculations {
    
    // MARK: - Constants
    
    /// 42-day time constant for CTL (Chronic Training Load)
    public static let ctlAlpha = 2.0 / 43.0
    
    /// 7-day time constant for ATL (Acute Training Load)
    public static let atlAlpha = 2.0 / 8.0
    
    /// Multiplier for estimating initial CTL from early training pattern
    public static let baselineCTLMultiplier = 0.7
    
    /// Multiplier for estimating initial ATL from early training pattern
    public static let baselineATLMultiplier = 0.4
    
    // MARK: - Core Calculations
    
    /// Calculate CTL (Chronic Training Load) - 42-day exponentially weighted average
    /// This represents your fitness/training capacity
    /// - Parameter dailyValues: Array of daily TSS/TRIMP values (chronological order)
    /// - Returns: CTL value
    public static func calculateCTL(from dailyValues: [Double]) -> Double {
        return calculateExponentialAverage(values: dailyValues, days: 42)
    }
    
    /// Calculate ATL (Acute Training Load) - 7-day exponentially weighted average
    /// This represents your recent fatigue/training stress
    /// - Parameter dailyValues: Array of daily TSS/TRIMP values (chronological order)
    /// - Returns: ATL value
    public static func calculateATL(from dailyValues: [Double]) -> Double {
        let last7Days = Array(dailyValues.suffix(7))
        return calculateExponentialAverage(values: last7Days, days: 7)
    }
    
    /// Calculate TSB (Training Stress Balance) - difference between CTL and ATL
    /// This represents your form/readiness
    /// - Parameters:
    ///   - ctl: Chronic Training Load (fitness)
    ///   - atl: Acute Training Load (fatigue)
    /// - Returns: TSB value (positive = fresh, negative = fatigued)
    public static func calculateTSB(ctl: Double, atl: Double) -> Double {
        return ctl - atl
    }
    
    /// Calculate exponentially weighted average
    /// Recent values have more weight than older values
    /// - Parameters:
    ///   - values: Array of daily values (chronological order)
    ///   - days: Time constant for the exponential average
    /// - Returns: Exponentially weighted average
    public static func calculateExponentialAverage(values: [Double], days: Int) -> Double {
        guard !values.isEmpty else { return 0 }
        
        // Lambda (smoothing factor) = 2 / (N + 1)
        // This gives more weight to recent values
        let lambda = 2.0 / (Double(days) + 1.0)
        
        // Start with first value
        var ewa = values.first!
        
        // Apply exponential weighting to subsequent values
        for value in values.dropFirst() {
            ewa = (value * lambda) + (ewa * (1 - lambda))
        }
        
        return ewa
    }
    
    // MARK: - Progressive Load Calculation
    
    /// Calculate progressive CTL/ATL values day-by-day
    /// - Parameters:
    ///   - dailyTSS: Dictionary mapping dates to TSS values
    ///   - startDate: Starting date for calculation
    ///   - endDate: Ending date for calculation
    ///   - calendar: Calendar to use for date arithmetic
    /// - Returns: Dictionary mapping dates to (ctl, atl) tuples
    public static func calculateProgressiveLoad(
        dailyTSS: [Date: Double],
        startDate: Date,
        endDate: Date,
        calendar: Calendar = .current
    ) -> [Date: (ctl: Double, atl: Double)] {
        guard startDate <= endDate else { return [:] }
        
        // Estimate baseline from first 2 weeks
        let baseline = estimateBaseline(dailyTSS: dailyTSS, startDate: startDate, calendar: calendar)
        
        var result: [Date: (ctl: Double, atl: Double)] = [:]
        var currentCTL = baseline.ctl
        var currentATL = baseline.atl
        var currentDate = startDate
        
        while currentDate <= endDate {
            let tss = dailyTSS[currentDate] ?? 0
            
            // Incremental EMA update
            currentCTL = (tss * ctlAlpha) + (currentCTL * (1 - ctlAlpha))
            currentATL = (tss * atlAlpha) + (currentATL * (1 - atlAlpha))
            
            result[currentDate] = (ctl: currentCTL, atl: currentATL)
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return result
    }
    
    // MARK: - Helper Functions
    
    /// Estimate baseline CTL/ATL from early training pattern
    /// - Parameters:
    ///   - dailyTSS: Dictionary mapping dates to TSS values
    ///   - startDate: Starting date for baseline estimation
    ///   - calendar: Calendar to use for date arithmetic
    /// - Returns: Tuple of (ctl, atl) baseline estimates
    public static func estimateBaseline(
        dailyTSS: [Date: Double],
        startDate: Date,
        calendar: Calendar
    ) -> (ctl: Double, atl: Double) {
        // Get first 2 weeks of data
        var firstTwoWeeks: [Date] = []
        var currentDate = startDate
        
        for _ in 0..<14 {
            if dailyTSS[currentDate] != nil {
                firstTwoWeeks.append(currentDate)
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        guard !firstTwoWeeks.isEmpty else {
            return (ctl: 0, atl: 0)
        }
        
        // Calculate average TSS per activity day
        let totalTSS = firstTwoWeeks.compactMap { dailyTSS[$0] }.reduce(0.0, +)
        let avgTSSPerActivity = totalTSS / Double(firstTwoWeeks.count)
        
        // Estimate CTL and ATL
        // At steady state with 3-4 activities/week: CTL ≈ avgTSS * ~0.7
        // ATL is shorter window, so start lower
        let ctl = avgTSSPerActivity * baselineCTLMultiplier
        let atl = avgTSSPerActivity * baselineATLMultiplier
        
        return (ctl: ctl, atl: atl)
    }
    
    /// Group activities by date and sum TSS/TRIMP values
    /// - Parameters:
    ///   - activities: Array of activities with TSS values and dates
    ///   - calendar: Calendar to use for date grouping
    /// - Returns: Dictionary mapping dates to total TSS for that day
    public static func groupByDate(
        activities: [(date: Date, value: Double)],
        calendar: Calendar = .current
    ) -> [Date: Double] {
        var dailyTSS: [Date: Double] = [:]
        
        for activity in activities {
            let day = calendar.startOfDay(for: activity.date)
            dailyTSS[day, default: 0] += activity.value
        }
        
        return dailyTSS
    }
}

