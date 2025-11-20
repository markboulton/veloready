import Foundation

/// Standard trend data point for time-series analysis
struct TrendDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

/// HRV trend data point with baseline for stress calculation
struct HRVTrendDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let baseline: Double?
}

/// Service for synthesizing stress scores from multiple health metrics
///
/// Stress is calculated using a 5-factor weighted formula:
/// - Recovery (30%): Low recovery indicates high stress
/// - HRV (25%): Low HRV relative to baseline indicates high stress
/// - RHR (20%): Elevated resting heart rate indicates high stress
/// - Sleep (15%): Poor sleep quality indicates high stress
/// - Daily Load (10%): High training load contributes to stress
///
/// Stress scores range from 0-100, where:
/// - 0-30: Low stress (optimal recovery state)
/// - 31-60: Moderate stress (manageable)
/// - 61-100: High stress (recovery needed)
@MainActor
final class StressSynthesisService {
    static let shared = StressSynthesisService()

    // MARK: - Weight Constants

    private let recoveryWeight: Double = 0.30
    private let hrvWeight: Double = 0.25
    private let rhrWeight: Double = 0.20
    private let sleepWeight: Double = 0.15
    private let loadWeight: Double = 0.10

    // MARK: - Baseline Constants

    private let baselineStress: Double = 50.0
    private let rhrBaselineBPM: Double = 60.0
    private let rhrStressMultiplier: Double = 2.0  // Each 1 bpm above baseline = 2 stress points

    // MARK: - Public API

    /// Synthesize stress trend from multiple health metrics
    /// - Parameters:
    ///   - recovery: Recovery score data points (0-100, higher is better)
    ///   - hrv: Heart rate variability data points with baselines
    ///   - rhr: Resting heart rate data points (bpm)
    ///   - sleep: Sleep quality score data points (0-100, higher is better)
    ///   - dailyLoad: Training load data points (TSS or equivalent)
    /// - Returns: Array of stress data points (0-100, higher = more stress)
    func synthesizeStress(
        recovery: [TrendDataPoint],
        hrv: [HRVTrendDataPoint],
        rhr: [TrendDataPoint],
        sleep: [TrendDataPoint],
        dailyLoad: [TrendDataPoint]
    ) -> [TrendDataPoint] {
        let calendar = Calendar.current
        var stressByDate: [Date: Double] = [:]

        // Create unified date index from all data sources
        let allDates = createDateIndex(
            recovery: recovery,
            hrv: hrv,
            rhr: rhr,
            sleep: sleep,
            dailyLoad: dailyLoad,
            calendar: calendar
        )

        // Calculate stress for each date
        for date in allDates {
            if let stressScore = calculateDailyStress(
                date: date,
                recovery: recovery,
                hrv: hrv,
                rhr: rhr,
                sleep: sleep,
                dailyLoad: dailyLoad,
                calendar: calendar
            ) {
                stressByDate[date] = stressScore
            }
        }

        // Convert to sorted data points
        let data = stressByDate.map { date, value in
            TrendDataPoint(date: date, value: value)
        }.sorted { $0.date < $1.date }

        Logger.debug("📈 [StressSynthesisService] Synthesized \(data.count) stress points from 5 sources")
        return data
    }

    // MARK: - Private Helpers

    /// Create unified date index from all data sources
    private func createDateIndex(
        recovery: [TrendDataPoint],
        hrv: [HRVTrendDataPoint],
        rhr: [TrendDataPoint],
        sleep: [TrendDataPoint],
        dailyLoad: [TrendDataPoint],
        calendar: Calendar
    ) -> Set<Date> {
        var allDates = Set<Date>()
        allDates.formUnion(recovery.map { calendar.startOfDay(for: $0.date) })
        allDates.formUnion(hrv.map { calendar.startOfDay(for: $0.date) })
        allDates.formUnion(rhr.map { calendar.startOfDay(for: $0.date) })
        allDates.formUnion(sleep.map { calendar.startOfDay(for: $0.date) })
        allDates.formUnion(dailyLoad.map { calendar.startOfDay(for: $0.date) })
        return allDates
    }

    /// Calculate stress score for a single day
    /// Returns nil if insufficient data (need at least 2 factors)
    private func calculateDailyStress(
        date: Date,
        recovery: [TrendDataPoint],
        hrv: [HRVTrendDataPoint],
        rhr: [TrendDataPoint],
        sleep: [TrendDataPoint],
        dailyLoad: [TrendDataPoint],
        calendar: Calendar
    ) -> Double? {
        var stress: Double = baselineStress
        var factorCount = 0

        // Recovery (30% weight) - inverse
        // Low recovery → high stress
        if let recoveryPoint = recovery.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            let recoveryStress = (100 - recoveryPoint.value) * recoveryWeight
            stress += recoveryStress
            factorCount += 1
        }

        // HRV (25% weight) - inverse deviation from baseline
        // HRV below baseline → high stress
        if let hrvPoint = hrv.first(where: { calendar.isDate($0.date, inSameDayAs: date) }),
           let baseline = hrvPoint.baseline {
            let deviation = ((baseline - hrvPoint.value) / baseline) * 100
            let hrvStress = deviation * hrvWeight
            stress += hrvStress
            factorCount += 1
        }

        // RHR (20% weight) - elevated RHR indicates stress
        // Each 1 bpm above 60 = 2 stress points
        if let rhrPoint = rhr.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            let rhrElevation = rhrPoint.value - rhrBaselineBPM
            let rhrStress = max(0, rhrElevation * rhrStressMultiplier) * rhrWeight
            stress += rhrStress
            factorCount += 1
        }

        // Sleep (15% weight) - inverse
        // Poor sleep → high stress
        if let sleepPoint = sleep.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            let sleepStress = (100 - sleepPoint.value) * sleepWeight
            stress += sleepStress
            factorCount += 1
        }

        // Daily load (10% weight)
        // High training load → stress
        if let loadPoint = dailyLoad.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            let loadStress = loadPoint.value * loadWeight
            stress += loadStress
            factorCount += 1
        }

        // Only return stress if we have at least 2 factors
        // Single-factor stress is unreliable
        guard factorCount >= 2 else {
            return nil
        }

        // Clamp to 0-100 range
        return max(0, min(100, stress))
    }
}
