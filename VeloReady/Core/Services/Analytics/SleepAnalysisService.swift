import Foundation
import HealthKit

/// Sleep data for a single day with stage breakdown
struct SleepDayData {
    let date: Date
    let deep: Double  // hours
    let rem: Double  // hours
    let core: Double  // hours
    let awake: Double  // hours
    let bedtime: Date?
    let wakeTime: Date?
}

/// Sleep night data with hypnogram samples
struct SleepNightData {
    let date: Date
    let samples: [SleepHypnogramChart.SleepStageSample]
    let bedtime: Date
    let wakeTime: Date
}

/// Service for analyzing sleep sessions and extracting sleep architecture
///
/// **Sleep Session Grouping:**
/// - Samples within 2 hours are considered part of the same sleep session
/// - Sleep sessions span midnight, so we look back 12 hours to capture the full session
/// - We attribute the sleep session to the day it ended (wake time), not started
///
/// **Sleep Stage Extraction:**
/// - Deep sleep: HKCategoryValueSleepAnalysis.asleepDeep
/// - REM sleep: HKCategoryValueSleepAnalysis.asleepREM
/// - Core sleep: HKCategoryValueSleepAnalysis.asleepCore + asleepUnspecified
/// - Awake: HKCategoryValueSleepAnalysis.awake
@MainActor
final class SleepAnalysisService {
    static let shared = SleepAnalysisService()

    // MARK: - Constants

    private let sessionGapThreshold: TimeInterval = 7200  // 2 hours in seconds
    private let lookbackHours: Int = 12  // Look back 12 hours before day start to capture full session

    // MARK: - Public API

    /// Group sleep samples into sessions
    /// Samples within 2 hours are considered part of the same session
    /// - Parameter samples: Array of HealthKit sleep samples
    /// - Returns: Array of sleep sessions (each session is an array of samples)
    func groupSleepSessions(from samples: [HKCategorySample]) -> [[HKCategorySample]] {
        var sessions: [[HKCategorySample]] = []
        var currentSession: [HKCategorySample] = []

        for sample in samples.sorted(by: { $0.startDate < $1.startDate }) {
            if let lastSample = currentSession.last {
                let gap = sample.startDate.timeIntervalSince(lastSample.endDate)
                if gap > sessionGapThreshold {
                    // Gap > 2 hours = new session
                    sessions.append(currentSession)
                    currentSession = []
                }
            }
            currentSession.append(sample)
        }

        if !currentSession.isEmpty {
            sessions.append(currentSession)
        }

        Logger.debug("💤 [SleepAnalysisService] Grouped \(samples.count) samples into \(sessions.count) sessions")
        return sessions
    }

    /// Find the sleep session that ended (woke up) during the specified day
    /// - Parameters:
    ///   - sessions: Array of sleep sessions
    ///   - date: Target date
    ///   - calendar: Calendar for date calculations
    /// - Returns: The sleep session that woke up during this day, or nil
    func findSessionForDay(
        sessions: [[HKCategorySample]],
        date: Date,
        calendar: Calendar = .current
    ) -> [HKCategorySample]? {
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return nil
        }

        return sessions.first { session in
            guard let wakeTime = session.max(by: { $0.endDate < $1.endDate })?.endDate else {
                return false
            }
            return wakeTime >= dayStart && wakeTime < dayEnd
        }
    }

    /// Extract sleep architecture from a sleep session
    /// - Parameter session: Array of sleep samples from a single session
    /// - Returns: Breakdown of sleep stages in hours, bedtime, and wake time
    func extractSleepArchitecture(
        from session: [HKCategorySample]
    ) -> (deep: Double, rem: Double, core: Double, awake: Double, bedtime: Date?, wakeTime: Date?) {
        var deep: TimeInterval = 0
        var rem: TimeInterval = 0
        var core: TimeInterval = 0
        var awake: TimeInterval = 0
        var earliestBedtime: Date?
        var latestWakeTime: Date?

        for sample in session {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)

            // Track bedtime and wake time
            if earliestBedtime == nil || sample.startDate < earliestBedtime! {
                earliestBedtime = sample.startDate
            }
            if latestWakeTime == nil || sample.endDate > latestWakeTime! {
                latestWakeTime = sample.endDate
            }

            // Categorize by sleep stage
            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deep += duration
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                rem += duration
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                core += duration
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                awake += duration
            default:
                break
            }
        }

        return (
            deep: deep / 3600.0,
            rem: rem / 3600.0,
            core: core / 3600.0,
            awake: awake / 3600.0,
            bedtime: earliestBedtime,
            wakeTime: latestWakeTime
        )
    }

    /// Create hypnogram samples from sleep session
    /// - Parameter session: Array of sleep samples from a single session
    /// - Returns: Array of hypnogram samples for visualization
    func createHypnogramSamples(from session: [HKCategorySample]) -> [SleepHypnogramChart.SleepStageSample] {
        var hypnogramSamples: [SleepHypnogramChart.SleepStageSample] = []

        for sample in session {
            if let hypnogramSample = SleepHypnogramChart.SleepStageSample(from: sample) {
                hypnogramSamples.append(hypnogramSample)
            }
        }

        return hypnogramSamples
    }

    /// Analyze sleep for a specific day
    /// Fetches sleep samples, groups into sessions, finds the session for this day, and extracts architecture
    /// - Parameters:
    ///   - date: The day to analyze
    ///   - healthKitManager: HealthKit manager for fetching sleep data
    /// - Returns: Sleep day data with stage breakdown and hypnogram data
    func analyzeSleepForDay(
        date: Date,
        healthKitManager: HealthKitManager
    ) async throws -> (sleepData: SleepDayData?, hypnogramData: SleepNightData?) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        // Look back 12 hours to capture full sleep session
        guard let fetchStart = calendar.date(byAdding: .hour, value: -lookbackHours, to: dayStart),
              let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return (nil, nil)
        }

        // Fetch sleep data
        let allSamples = try await healthKitManager.fetchSleepData(from: fetchStart, to: dayEnd)

        // Group into sessions
        let sessions = groupSleepSessions(from: allSamples)

        // Find session for this day
        guard let mainSession = findSessionForDay(sessions: sessions, date: date) else {
            return (nil, nil)
        }

        // Extract sleep architecture
        let (deep, rem, core, awake, bedtime, wakeTime) = extractSleepArchitecture(from: mainSession)

        // Only create data if we have meaningful sleep stages
        guard deep > 0 || rem > 0 || core > 0 else {
            return (nil, nil)
        }

        let sleepData = SleepDayData(
            date: date,
            deep: deep,
            rem: rem,
            core: core,
            awake: awake,
            bedtime: bedtime,
            wakeTime: wakeTime
        )

        // Create hypnogram data
        var hypnogramData: SleepNightData?
        if let bedtime = bedtime, let wakeTime = wakeTime {
            let hypnogramSamples = createHypnogramSamples(from: mainSession)
            if !hypnogramSamples.isEmpty {
                hypnogramData = SleepNightData(
                    date: date,
                    samples: hypnogramSamples,
                    bedtime: bedtime,
                    wakeTime: wakeTime
                )
            }
        }

        Logger.debug("💤 [SleepAnalysisService] Analyzed sleep for \(date): \(String(format: "%.1fh deep, %.1fh REM, %.1fh core", deep, rem, core))")

        return (sleepData, hypnogramData)
    }
}
