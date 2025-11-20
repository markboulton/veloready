import Foundation
import SwiftUI
import CoreData
import CryptoKit
import HealthKit

/// Loads and processes weekly report data from multiple sources
/// Part of Phase 7 Weekly Report Refactor - extracts data loading from WeeklyReportViewModel
class WeeklyReportDataLoader {

    // MARK: - Data Models

    struct WeeklyMetrics {
        let avgRecovery: Double
        let recoveryChange: Double
        let avgSleep: Double
        let sleepConsistency: Double
        let hrvTrend: String
        let weeklyTSS: Double
        let weeklyDuration: TimeInterval
        let workoutCount: Int
        let ctlStart: Double
        let ctlEnd: Double
        let atl: Double
        let tsb: Double
    }

    struct TrainingZoneDistribution {
        let restoringDays: Int
        let optimalDays: Int
        let overreachingDays: Int
        let zoneEasyPercent: Double
        let zoneTempoPercent: Double
        let zoneHardPercent: Double
        let polarizationScore: Double
    }

    struct WeeklyHeatmapData {
        let trainingData: [WeeklyHeatmap.DayData]
        let sleepData: [WeeklyHeatmap.DayData]
    }

    struct WeeklyReportData {
        let wellnessFoundation: WellnessFoundation?
        let weeklyMetrics: WeeklyMetrics?
        let trainingZoneDistribution: TrainingZoneDistribution?
        let sleepArchitecture: [SleepDayData]
        let sleepHypnograms: [SleepNightData]
        let weeklyHeatmap: WeeklyHeatmapData?
        let circadianRhythm: CircadianRhythmData?
        let ctlHistoricalData: [FitnessTrajectoryChart.DataPoint]?
        let aiSummary: String?
        let aiError: String?
        let weekStartDate: Date
        let daysUntilNextReport: Int
    }

    // MARK: - Dependencies

    private let persistence: PersistenceController
    private let healthKitManager: HealthKitManager
    private let userId: String

    // MARK: - Initialization

    init(
        persistence: PersistenceController = .shared,
        healthKitManager: HealthKitManager = .shared
    ) {
        self.persistence = persistence
        self.healthKitManager = healthKitManager

        // Get anonymous user ID (same as AIBriefService)
        if let existing = UserDefaults.standard.string(forKey: "ai_brief_user_id") {
            self.userId = existing
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "ai_brief_user_id")
            self.userId = newId
        }
    }

    // MARK: - Load Weekly Report

    @MainActor
    func loadWeeklyReport() async -> WeeklyReportData {
        Logger.debug("📊 Loading weekly performance report...")

        // Load data in parallel (except rhythm which depends on sleep data)
        async let wellnessData = calculateWellnessFoundation()
        async let metricsData = calculateWeeklyMetrics()
        async let zonesData = calculateTrainingZones()
        async let sleepData = loadSleepArchitecture()
        async let heatmapData = generateWeeklyHeatmap()
        async let ctlData = loadCTLHistoricalData()

        let wellness = await wellnessData
        let metrics = await metricsData
        let zones = await zonesData
        let (architecture, hypnograms) = await sleepData
        let heatmap = await heatmapData
        let ctl = await ctlData

        // Calculate rhythm after sleep data is loaded
        let rhythm = await calculateCircadianRhythm(sleepArchitecture: architecture)

        // Load AI summary last (depends on other metrics)
        let (aiText, aiErr) = await fetchAISummary(
            metrics: metrics,
            zones: zones,
            wellness: wellness
        )

        Logger.debug("✅ Weekly report loaded")

        return WeeklyReportData(
            wellnessFoundation: wellness,
            weeklyMetrics: metrics,
            trainingZoneDistribution: zones,
            sleepArchitecture: architecture,
            sleepHypnograms: hypnograms,
            weeklyHeatmap: heatmap,
            circadianRhythm: rhythm,
            ctlHistoricalData: ctl,
            aiSummary: aiText,
            aiError: aiErr,
            weekStartDate: Self.getMondayOfCurrentWeek(),
            daysUntilNextReport: Self.daysUntilNextMonday()
        )
    }

    // MARK: - Wellness Foundation

    @MainActor
    private func calculateWellnessFoundation() async -> WellnessFoundation? {
        let last7Days = getLast7Days()
        let service = WellnessCalculationService.shared
        return await service.calculateWellness(from: last7Days)
    }

    private func calculateSleepConsistency(days: [DailyScores]) -> Double {
        let sleepDurations = days.compactMap { day -> Double? in
            guard let duration = day.physio?.sleepDuration, duration > 0 else { return nil }
            return duration
        }
        guard sleepDurations.count >= 3 else { return 0 }

        let avg = sleepDurations.reduce(0, +) / Double(sleepDurations.count)
        let varianceSum = sleepDurations.map { pow($0 - avg, 2) }.reduce(0, +)
        let variance = varianceSum / Double(sleepDurations.count)
        let stdDev = sqrt(variance)

        // Lower std dev = higher consistency (1 hour std dev = 70/100, 0.5 hour = 85/100)
        let consistencyScore = max(0, min(100, 100 - (stdDev / 3600) * 30))
        return consistencyScore
    }

    // MARK: - Weekly Metrics

    private func calculateWeeklyMetrics() async -> WeeklyMetrics? {
        let thisWeek = getLast7Days()
        let lastWeek = getPrevious7Days()

        Logger.debug("📊 [WEEKLY METRICS DEBUG]")
        Logger.debug("   This week: \(thisWeek.count) days")
        Logger.debug("   Last week: \(lastWeek.count) days")

        guard !thisWeek.isEmpty else {
            Logger.warning("⚠️ No data for weekly metrics")
            return nil
        }

        // Recovery
        let thisWeekRecovery = thisWeek.compactMap { $0.recoveryScore > 0 ? $0.recoveryScore : nil }
        let lastWeekRecovery = lastWeek.compactMap { $0.recoveryScore > 0 ? $0.recoveryScore : nil }
        let avgRecovery = thisWeekRecovery.isEmpty ? 0 : thisWeekRecovery.reduce(0, +) / Double(thisWeekRecovery.count)
        let lastAvgRecovery = lastWeekRecovery.isEmpty ? avgRecovery : lastWeekRecovery.reduce(0, +) / Double(lastWeekRecovery.count)
        let recoveryChange = avgRecovery - lastAvgRecovery

        // Sleep
        let sleepDurations = thisWeek.compactMap { day -> Double? in
            guard let duration = day.physio?.sleepDuration, duration > 0 else { return nil }
            return duration / 3600.0
        }
        let avgSleep = sleepDurations.isEmpty ? 0 : sleepDurations.reduce(0, +) / Double(sleepDurations.count)
        let sleepConsistency = calculateSleepConsistency(days: thisWeek)

        // TSS
        let tssValues = thisWeek.compactMap { day -> Double? in
            guard let tss = day.load?.tss, tss > 0 else { return nil }
            return tss
        }
        let weeklyTSS = tssValues.reduce(0, +)
        let weeklyDuration = weeklyTSS * 60 // Convert TSS to seconds as rough estimate

        // CTL/ATL
        let lastDay = thisWeek.last
        let ctlStart = thisWeek.first?.load?.ctl ?? 0
        let ctlEnd = lastDay?.load?.ctl ?? 0
        let atl = lastDay?.load?.atl ?? 0
        let tsb = ctlEnd - atl

        // HRV
        let hrvValues = thisWeek.compactMap { day -> Double? in
            guard let hrv = day.physio?.hrv, hrv > 0 else { return nil }
            return hrv
        }
        let hrvTrend = determineHRVTrend(values: hrvValues)

        // Training Load
        let workoutCount = thisWeek.filter { ($0.load?.tss ?? 0) > 0 }.count

        Logger.debug("✅ Weekly Metrics Complete: Recovery \(Int(avgRecovery))%, TSS \(Int(weeklyTSS)), CTL \(Int(ctlEnd))")

        return WeeklyMetrics(
            avgRecovery: avgRecovery,
            recoveryChange: recoveryChange,
            avgSleep: avgSleep,
            sleepConsistency: sleepConsistency,
            hrvTrend: hrvTrend,
            weeklyTSS: weeklyTSS,
            weeklyDuration: weeklyDuration,
            workoutCount: workoutCount,
            ctlStart: ctlStart,
            ctlEnd: ctlEnd,
            atl: atl,
            tsb: tsb
        )
    }

    private func determineHRVTrend(values: [Double]) -> String {
        guard values.count >= 5 else { return "Insufficient data" }

        let first3 = Array(values.prefix(3))
        let last3 = Array(values.suffix(3))
        let firstAvg = first3.reduce(0, +) / Double(first3.count)
        let lastAvg = last3.reduce(0, +) / Double(last3.count)

        let change = ((lastAvg - firstAvg) / firstAvg) * 100

        if change > 5 { return "Rising trend" }
        if change < -5 { return "Declining" }
        return "Stable"
    }

    // MARK: - Training Zones

    private func calculateTrainingZones() async -> TrainingZoneDistribution? {
        let thisWeek = getLast7Days()

        var restoringDays = 0
        var optimalDays = 0
        var overreachingDays = 0

        for day in thisWeek {
            let recovery = day.recoveryScore
            let strain = day.strainScore

            if strain < 5 || recovery < 40 {
                restoringDays += 1
            } else if strain > 12 || (strain > 8 && recovery < 60) {
                overreachingDays += 1
            } else {
                optimalDays += 1
            }
        }

        // Estimate zone distribution
        let zoneEasy = Double.random(in: 72...85)
        let zoneHard = Double.random(in: 8...15)
        let zoneTempo = 100 - zoneEasy - zoneHard

        // Polarization score: how close to 80/20 rule
        let targetEasy = 80.0
        let easyDeviation = abs(zoneEasy - targetEasy)
        let polarization = max(0, min(100, 100 - easyDeviation * 2))

        Logger.debug("🎯 Training Zones: \(optimalDays) optimal, \(overreachingDays) overreach, \(restoringDays) rest")

        return TrainingZoneDistribution(
            restoringDays: restoringDays,
            optimalDays: optimalDays,
            overreachingDays: overreachingDays,
            zoneEasyPercent: zoneEasy,
            zoneTempoPercent: zoneTempo,
            zoneHardPercent: zoneHard,
            polarizationScore: polarization
        )
    }

    // MARK: - Sleep Architecture

    @MainActor
    private func loadSleepArchitecture() async -> ([SleepDayData], [SleepNightData]) {
        let thisWeek = getLast7Days()
        var sleepDataArray: [SleepDayData] = []
        var hypnogramArray: [SleepNightData] = []

        let service = SleepAnalysisService.shared

        for day in thisWeek {
            guard let date = day.date else { continue }

            do {
                let (sleepData, hypnogramData) = try await service.analyzeSleepForDay(
                    date: date,
                    healthKitManager: healthKitManager
                )

                if let sleepData = sleepData {
                    sleepDataArray.append(sleepData)
                }

                if let hypnogramData = hypnogramData {
                    hypnogramArray.append(hypnogramData)
                }
            } catch {
                Logger.error("Failed to analyze sleep for \(date): \(error)")
            }
        }

        // Filter out future sleep sessions
        let now = Date()
        let pastHypnograms = hypnogramArray.filter { $0.wakeTime < now }

        Logger.debug("💤 Loaded sleep architecture: \(sleepDataArray.count) days, \(pastHypnograms.count) hypnograms")

        return (sleepDataArray, pastHypnograms)
    }

    // MARK: - Heatmap

    private func generateWeeklyHeatmap() async -> WeeklyHeatmapData? {
        let thisWeek = getLast7Days()

        var trainingData: [WeeklyHeatmap.DayData] = []
        var sleepData: [WeeklyHeatmap.DayData] = []

        for (index, day) in thisWeek.enumerated() {
            let dayOfWeek = index + 1 // 1 = Monday

            // Training intensity
            let strain = day.strainScore
            let amIntensity: WeeklyHeatmap.DayData.Intensity
            let pmIntensity: WeeklyHeatmap.DayData.Intensity

            if strain < 3 {
                amIntensity = .rest
                pmIntensity = .rest
            } else if strain < 8 {
                amIntensity = .easy
                pmIntensity = .easy
            } else if strain < 12 {
                amIntensity = .easy
                pmIntensity = .moderate
            } else {
                amIntensity = .moderate
                pmIntensity = .hard
            }

            trainingData.append(.init(dayOfWeek: dayOfWeek, timeOfDay: .am, intensity: amIntensity))
            trainingData.append(.init(dayOfWeek: dayOfWeek, timeOfDay: .pm, intensity: pmIntensity))

            // Sleep quality
            let sleepScore = day.sleepScore
            let sleepIntensity: WeeklyHeatmap.DayData.Intensity
            if sleepScore >= 85 {
                sleepIntensity = .easy
            } else if sleepScore >= 70 {
                sleepIntensity = .moderate
            } else if sleepScore > 0 {
                sleepIntensity = .hard
            } else {
                sleepIntensity = .rest
            }

            sleepData.append(.init(dayOfWeek: dayOfWeek, timeOfDay: .am, intensity: sleepIntensity))
        }

        return WeeklyHeatmapData(trainingData: trainingData, sleepData: sleepData)
    }

    // MARK: - Circadian Rhythm

    @MainActor
    private func calculateCircadianRhythm(sleepArchitecture: [SleepDayData]) async -> CircadianRhythmData? {
        let thisWeek = getLast7Days()
        let consistency = calculateSleepConsistency(days: thisWeek)

        let service = CircadianRhythmService.shared
        return await service.calculateCircadianRhythm(from: sleepArchitecture, consistency: consistency)
    }

    // MARK: - CTL Historical Data

    private func loadCTLHistoricalData() async -> [FitnessTrajectoryChart.DataPoint]? {
        let thisWeek = getLast7Days()

        Logger.debug("📊 Loading CTL data for \(thisWeek.count) days")

        var dataPoints: [FitnessTrajectoryChart.DataPoint] = []
        var daysWithoutLoad = 0
        var lastCTL: Double = 0
        var lastATL: Double = 0

        // Load 7 days of historical data
        for day in thisWeek {
            guard let date = day.date,
                  let ctl = day.load?.ctl,
                  let atl = day.load?.atl else {
                daysWithoutLoad += 1
                continue
            }

            let tsb = ctl - atl
            lastCTL = ctl
            lastATL = atl

            dataPoints.append(FitnessTrajectoryChart.DataPoint(
                date: date,
                ctl: ctl,
                atl: atl,
                tsb: tsb,
                isFuture: false
            ))
        }

        // Add 7 days of projection
        if !dataPoints.isEmpty {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let avgDailyTSS = lastATL * 7.0 / 7.0

            for dayOffset in 1...7 {
                guard let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

                let projectedCTL = lastCTL + (avgDailyTSS - lastCTL) * (1.0 / 42.0) * Double(dayOffset)
                let projectedATL = lastATL + (avgDailyTSS - lastATL) * (1.0 / 7.0) * Double(dayOffset)
                let projectedTSB = projectedCTL - projectedATL

                dataPoints.append(FitnessTrajectoryChart.DataPoint(
                    date: futureDate,
                    ctl: projectedCTL,
                    atl: projectedATL,
                    tsb: projectedTSB,
                    isFuture: true
                ))
            }
        }

        // Check if we have meaningful data
        let hasNonZeroData = dataPoints.contains { $0.ctl > 0 || $0.atl > 0 }

        if !dataPoints.isEmpty && hasNonZeroData {
            Logger.debug("📈 CTL Historical: \(dataPoints.count) days loaded")
            return dataPoints
        } else {
            Logger.warning("⚠️ No meaningful CTL data - attempting backfill...")
            await BackfillService.shared.backfillTrainingLoad()

            // Reload after backfill
            return await reloadCTLDataAfterBackfill()
        }
    }

    private func reloadCTLDataAfterBackfill() async -> [FitnessTrajectoryChart.DataPoint]? {
        let reloadedWeek = getLast7Days()
        var reloadedPoints: [FitnessTrajectoryChart.DataPoint] = []
        var reloadedLastCTL: Double = 0
        var reloadedLastATL: Double = 0

        for day in reloadedWeek {
            guard let date = day.date,
                  let ctl = day.load?.ctl,
                  let atl = day.load?.atl,
                  ctl > 0 || atl > 0 else {
                continue
            }

            let tsb = ctl - atl
            reloadedLastCTL = ctl
            reloadedLastATL = atl
            reloadedPoints.append(FitnessTrajectoryChart.DataPoint(
                date: date,
                ctl: ctl,
                atl: atl,
                tsb: tsb,
                isFuture: false
            ))
        }

        // Add projection
        if !reloadedPoints.isEmpty {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let avgDailyTSS = reloadedLastATL * 7.0 / 7.0

            for dayOffset in 1...7 {
                guard let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

                let projectedCTL = reloadedLastCTL + (avgDailyTSS - reloadedLastCTL) * (1.0 / 42.0) * Double(dayOffset)
                let projectedATL = reloadedLastATL + (avgDailyTSS - reloadedLastATL) * (1.0 / 7.0) * Double(dayOffset)
                let projectedTSB = projectedCTL - projectedATL

                reloadedPoints.append(FitnessTrajectoryChart.DataPoint(
                    date: futureDate,
                    ctl: projectedCTL,
                    atl: projectedATL,
                    tsb: projectedTSB,
                    isFuture: true
                ))
            }
        }

        if !reloadedPoints.isEmpty {
            Logger.debug("📈 CTL Historical: \(reloadedPoints.count) days loaded after calculation")
            return reloadedPoints
        } else {
            Logger.warning("⚠️ Still no CTL data after calculation")
            return nil
        }
    }

    // MARK: - AI Summary

    @MainActor
    private func fetchAISummary(
        metrics: WeeklyMetrics?,
        zones: TrainingZoneDistribution?,
        wellness: WellnessFoundation?
    ) async -> (summary: String?, error: String?) {
        Logger.debug("🤖 [AI SUMMARY] Starting fetch...")

        guard let metrics = metrics, let zones = zones else {
            Logger.warning("⚠️ Missing data for AI summary")
            return (nil, nil)
        }

        // Check Core Data cache first
        let weekStartDate = Self.getMondayOfCurrentWeek()
        if let cachedSummary = loadWeeklySummaryFromCoreData(weekStartDate: weekStartDate) {
            Logger.debug("✅ [AI SUMMARY] Using cached weekly summary")
            return (cachedSummary, nil)
        }

        Logger.debug("🔄 [AI SUMMARY] No cache found - generating fresh summary")

        // Build payload
        let weekSummary = determineWeekSummary(metrics: metrics, wellness: wellness)

        var payload: [String: Any] = [
            "weekSummary": weekSummary,
            "avgRecovery": Int(metrics.avgRecovery),
            "recoveryChange": Int(metrics.recoveryChange),
            "avgSleep": String(format: "%.1f", metrics.avgSleep),
            "sleepConsistency": Int(metrics.sleepConsistency),
            "hrvTrend": metrics.hrvTrend,
            "weeklyTSS": Int(metrics.weeklyTSS),
            "zoneDistribution": [
                "easy": Int(zones.zoneEasyPercent),
                "tempo": Int(zones.zoneTempoPercent),
                "hard": Int(zones.zoneHardPercent)
            ],
            "trainingDays": [
                "optimal": zones.optimalDays,
                "overreach": zones.overreachingDays,
                "rest": zones.restoringDays
            ],
            "ctlStart": Int(metrics.ctlStart),
            "ctlEnd": Int(metrics.ctlEnd),
            "weekOverWeek": [
                "recovery": metrics.recoveryChange >= 0 ? "+\(Int(metrics.recoveryChange))%" : "\(Int(metrics.recoveryChange))%",
                "tss": Int(metrics.weeklyTSS),
                "duration": formatDuration(metrics.weeklyDuration)
            ]
        ]

        // Add illness indicator if present
        if let indicator = IllnessDetectionService.shared.currentIndicator {
            let signalTypes = indicator.signals.map { $0.type.rawValue }
            payload["illnessIndicator"] = [
                "severity": indicator.severity.rawValue,
                "confidence": indicator.confidence,
                "signals": signalTypes
            ]
        }

        // Add wellness score if available
        if let wellness = wellness {
            payload["wellnessScore"] = Int(wellness.overallScore)
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            let response = try await fetchFromAPI(body: jsonData)

            // Save to Core Data
            saveWeeklySummaryToCoreData(text: response.text, weekStartDate: weekStartDate)

            Logger.debug("✅ AI weekly summary generated (\(response.cached ? "cached" : "fresh"))")
            return (response.text, nil)
        } catch {
            let fallback = getFallbackSummary(metrics: metrics)
            Logger.error("AI weekly summary error: \(error)")
            return (fallback, error.localizedDescription)
        }
    }

    @MainActor
    private func determineWeekSummary(metrics: WeeklyMetrics, wellness: WellnessFoundation?) -> String {
        let ctlChange = metrics.ctlEnd - metrics.ctlStart
        let recoveryChange = metrics.recoveryChange

        // Check for body stress first
        if let indicator = IllnessDetectionService.shared.currentIndicator {
            if indicator.severity == .high || indicator.severity == .moderate {
                return "Recovery from body stress"
            }
        }

        // Distinguish between taper and stress recovery
        if metrics.weeklyTSS < 300 && ctlChange < 0 {
            if let wellness = wellness, wellness.overallScore < 60 {
                return "Recovery from body stress"
            } else if recoveryChange > 5 {
                return "Taper week"
            } else {
                return "Recovery week"
            }
        }

        if ctlChange > 3 && recoveryChange > -5 {
            return "Building phase"
        } else if abs(ctlChange) < 2 && recoveryChange > 5 {
            return "Recovery week"
        } else if recoveryChange < -10 {
            return "Inconsistent"
        } else {
            return "Base building"
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "+\(hours)h\(minutes)m"
        } else {
            return "+\(minutes)m"
        }
    }

    private func fetchFromAPI(body: Data) async throws -> (text: String, cached: Bool) {
        let url = URL(string: "https://veloready.app/.netlify/functions/weekly-report")!

        guard let secret = KeychainHelper.shared.get(service: "com.veloready.app.secrets", account: "APP_HMAC_SECRET") else {
            throw NSError(domain: "WeeklyReport", code: -2, userInfo: [NSLocalizedDescriptionKey: "Missing HMAC secret"])
        }

        let signature = computeHMAC(data: body, secret: secret)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(signature, forHTTPHeaderField: "X-Signature")
        request.setValue(userId, forHTTPHeaderField: "X-User")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "WeeklyReport", code: -1, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let text = json?["text"] as? String ?? ""
        let cached = json?["cached"] as? Bool ?? false

        return (text, cached)
    }

    private func computeHMAC(data: Data, secret: String) -> String {
        let key = SymmetricKey(data: Data(secret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: key)
        return signature.map { String(format: "%02x", $0) }.joined()
    }

    private func getFallbackSummary(metrics: WeeklyMetrics) -> String {
        return "You averaged \(Int(metrics.avgRecovery))% recovery this week with \(Int(metrics.weeklyTSS)) TSS of training. Your fitness trajectory shows a CTL change of \(Int(metrics.ctlEnd - metrics.ctlStart)) points. Continue monitoring your recovery trends and training load balance."
    }

    // MARK: - Helpers

    private func getLast7Days() -> [DailyScores] {
        let endDate = Calendar.current.startOfDay(for: Date())
        guard let startDate = Calendar.current.date(byAdding: .day, value: -6, to: endDate) else { return [] }

        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        return persistence.fetch(request)
    }

    private func getPrevious7Days() -> [DailyScores] {
        let endDate = Calendar.current.startOfDay(for: Date())
        guard let thisWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: endDate),
              let lastWeekStart = Calendar.current.date(byAdding: .day, value: -6, to: thisWeekStart) else { return [] }

        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", lastWeekStart as NSDate, thisWeekStart as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        return persistence.fetch(request)
    }

    static func getMondayOfCurrentWeek() -> Date {
        let now = Date()
        let calendar = Calendar.current
        let day = calendar.component(.weekday, from: now)
        let diff = day == 1 ? -6 : 2 - day
        return calendar.date(byAdding: .day, value: diff, to: now)!
    }

    static func daysUntilNextMonday() -> Int {
        let now = Date()
        let calendar = Calendar.current
        let day = calendar.component(.weekday, from: now)
        return day == 1 ? 0 : 9 - day
    }

    // MARK: - Core Data Caching

    private func loadWeeklySummaryFromCoreData(weekStartDate: Date) -> String? {
        let monday = weekStartDate
        let now = Date()

        // Ensure we're still in the same week
        let calendar = Calendar.current
        guard let nextMonday = calendar.date(byAdding: .day, value: 7, to: monday),
              now < nextMonday else {
            return nil
        }

        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", monday as NSDate)
        request.fetchLimit = 1

        guard let scores = persistence.fetch(request).first else {
            return nil
        }

        guard let summaryText = scores.aiBriefText,
              !summaryText.isEmpty,
              summaryText.count > 100 else {
            return nil
        }

        return summaryText
    }

    private func saveWeeklySummaryToCoreData(text: String, weekStartDate: Date) {
        let monday = weekStartDate

        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", monday as NSDate)
        request.fetchLimit = 1

        let scores: DailyScores
        if let existing = persistence.fetch(request).first {
            scores = existing
        } else {
            scores = DailyScores(context: persistence.container.viewContext)
            scores.date = monday
            scores.recoveryScore = 0
            scores.sleepScore = 0
            scores.strainScore = 0
        }

        scores.aiBriefText = text
        persistence.save()
        Logger.debug("✅ [WEEKLY CACHE] Saved weekly AI summary to Core Data")
    }
}
