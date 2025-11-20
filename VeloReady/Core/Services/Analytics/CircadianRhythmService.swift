import Foundation

/// Circadian rhythm data with sleep schedule consistency metrics
struct CircadianRhythmData {
    let avgBedtime: Double  // Fractional hours from midnight (e.g., 23.5 = 11:30 PM)
    let avgWakeTime: Double  // Fractional hours from midnight (e.g., 7.5 = 7:30 AM)
    let bedtimeVariance: Double  // Standard deviation in minutes
    let avgTrainingTime: Double?  // Average training time (hours from midnight), optional
    let consistency: Double  // Overall consistency score (0-100)
}

/// Service for analyzing circadian rhythm and sleep schedule patterns
///
/// **Bedtime Averaging:**
/// - Times before 6am are treated as "next day" for averaging purposes
/// - Example: 1:00 AM is treated as 25.0 hours (not 1.0) to avoid wraparound issues
/// - After averaging, results are normalized back to 0-24 range
///
/// **Wake Time Averaging:**
/// - Times are kept in their natural 0-24 hour range
/// - Early wake times (0-6am) are from previous night's sleep
///
/// **Variance Calculation:**
/// - Bedtime variance is standard deviation in minutes
/// - Lower variance = more consistent sleep schedule
@MainActor
final class CircadianRhythmService {
    static let shared = CircadianRhythmService()

    // MARK: - Constants

    private let earlyMorningThreshold: Double = 6.0  // Hours before which we treat as "next day"
    private let hoursPerDay: Double = 24.0

    // MARK: - Public API

    /// Calculate circadian rhythm from sleep architecture data
    /// - Parameters:
    ///   - sleepData: Array of sleep day data with bedtimes and wake times
    ///   - consistency: Overall sleep consistency score (from WellnessCalculationService)
    /// - Returns: Circadian rhythm data with averages and variance
    func calculateCircadianRhythm(
        from sleepData: [SleepDayData],
        consistency: Double
    ) -> CircadianRhythmData? {
        // Only use past sleep (not future)
        let now = Date()
        let pastSleep = sleepData.filter { sleep in
            guard let wakeTime = sleep.wakeTime else { return false }
            return wakeTime < now
        }

        guard !pastSleep.isEmpty else {
            Logger.warning("⚠️ [CircadianRhythmService] No past sleep data")
            return nil
        }

        let bedtimes = pastSleep.compactMap { $0.bedtime }
        let wakeTimes = pastSleep.compactMap { $0.wakeTime }

        guard !bedtimes.isEmpty && !wakeTimes.isEmpty else {
            Logger.warning("⚠️ [CircadianRhythmService] No valid bedtime/wake time data")
            return nil
        }

        // Calculate average bedtime with 24-hour wrapping
        let avgBedtime = calculateAverageBedtime(from: bedtimes)

        // Calculate average wake time
        let avgWakeTime = calculateAverageWakeTime(from: wakeTimes)

        // Calculate bedtime variance
        let bedtimeVariance = calculateBedtimeVariance(from: bedtimes, average: avgBedtime)

        Logger.debug("⏰ [CircadianRhythmService] Bedtime \(formatTime(avgBedtime)), Wake \(formatTime(avgWakeTime)), Variance ±\(Int(bedtimeVariance))min")

        return CircadianRhythmData(
            avgBedtime: avgBedtime,
            avgWakeTime: avgWakeTime,
            bedtimeVariance: bedtimeVariance,
            avgTrainingTime: nil,  // TODO: Calculate from training data
            consistency: consistency
        )
    }

    // MARK: - Private Helpers

    /// Calculate average bedtime with 24-hour wrapping logic
    /// Times before 6am are treated as "next day" (e.g., 1am = 25.0)
    private func calculateAverageBedtime(from bedtimes: [Date]) -> Double {
        let bedtimeHours = bedtimes.map { date -> Double in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            var hour = Double(components.hour ?? 0)
            let minute = Double(components.minute ?? 0) / 60.0

            // If bedtime is before 6am, treat as next day (e.g., 1am = 25.0)
            if hour < earlyMorningThreshold {
                hour += hoursPerDay
            }

            let fractionalHour = hour + minute
            Logger.debug("   [CircadianRhythmService] Bedtime: \(formatComponents(components)) = \(String(format: "%.1f", fractionalHour))h")
            return fractionalHour
        }

        let avgBedtimeRaw = bedtimeHours.reduce(0, +) / Double(bedtimeHours.count)

        // Normalize back to 0-24 range
        let avgBedtime = avgBedtimeRaw >= hoursPerDay ? avgBedtimeRaw - hoursPerDay : avgBedtimeRaw

        Logger.debug("   [CircadianRhythmService] Average bedtime: \(String(format: "%.1f", avgBedtime))h (raw: \(String(format: "%.1f", avgBedtimeRaw)))")

        return avgBedtime
    }

    /// Calculate average wake time
    /// Keep times in natural 0-24 hour range
    private func calculateAverageWakeTime(from wakeTimes: [Date]) -> Double {
        let wakeTimeHours = wakeTimes.map { date -> Double in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            let hour = Double(components.hour ?? 0)
            let minute = Double(components.minute ?? 0) / 60.0

            let fractionalHour = hour + minute
            Logger.debug("   [CircadianRhythmService] Wake: \(formatComponents(components)) = \(String(format: "%.1f", fractionalHour))h")
            return fractionalHour
        }

        let avgWakeTime = wakeTimeHours.reduce(0, +) / Double(wakeTimeHours.count)

        Logger.debug("   [CircadianRhythmService] Average wake time: \(String(format: "%.1f", avgWakeTime))h")

        return avgWakeTime
    }

    /// Calculate bedtime variance (standard deviation in minutes)
    private func calculateBedtimeVariance(from bedtimes: [Date], average avgBedtime: Double) -> Double {
        // Convert bedtimes to fractional hours (normalized to 0-24)
        let bedtimeHours = bedtimes.map { date -> Double in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            var hour = Double(components.hour ?? 0)
            let minute = Double(components.minute ?? 0) / 60.0

            // Apply same wrapping logic for consistency
            if hour < earlyMorningThreshold {
                hour += hoursPerDay
            }

            let fractionalHour = hour + minute

            // Normalize back to 0-24
            return fractionalHour >= hoursPerDay ? fractionalHour - hoursPerDay : fractionalHour
        }

        // Convert to minutes
        let avgBedtimeMinutes = avgBedtime * 60
        let bedtimeMinutes = bedtimeHours.map { $0 * 60 }

        // Calculate variance
        let varianceSum = bedtimeMinutes.map { pow($0 - avgBedtimeMinutes, 2) }.reduce(0, +)
        let variance = varianceSum / Double(bedtimeMinutes.count)
        let bedtimeVariance = sqrt(variance)

        return bedtimeVariance
    }

    // MARK: - Formatting Helpers

    /// Format time in HH:MM format from fractional hours
    private func formatTime(_ fractionalHours: Double) -> String {
        let hours = Int(fractionalHours)
        let minutes = Int((fractionalHours - Double(hours)) * 60)
        return String(format: "%02d:%02d", hours, minutes)
    }

    /// Format date components to HH:MM string
    private func formatComponents(_ components: DateComponents) -> String {
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
