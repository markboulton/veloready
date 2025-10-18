import Foundation
import SwiftUI
import CoreData
import CryptoKit
import HealthKit

/// ViewModel for Weekly Performance Report
/// Generates comprehensive weekly analysis with holistic health metrics
@MainActor
class WeeklyReportViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var aiSummary: String?
    @Published var isLoadingAI = false
    @Published var aiError: String?
    @Published var weekStartDate: Date
    @Published var daysUntilNextReport: Int = 0
    
    // Wellness Foundation
    @Published var wellnessFoundation: WellnessFoundation?
    
    // Weekly Metrics
    @Published var weeklyMetrics: WeeklyMetrics?
    @Published var trainingZoneDistribution: TrainingZoneDistribution?
    @Published var sleepArchitecture: [SleepDayData] = []
    @Published var sleepHypnograms: [SleepNightData] = []
    @Published var weeklyHeatmap: WeeklyHeatmapData?
    @Published var circadianRhythm: CircadianRhythmData?
    @Published var ctlHistoricalData: [FitnessTrajectoryChart.DataPoint]?
    
    // MARK: - Data Models
    
    struct SleepNightData: Identifiable {
        let id = UUID()
        let date: Date
        let samples: [SleepHypnogramChart.SleepStageSample]
        let bedtime: Date
        let wakeTime: Date
    }
    
    struct WellnessFoundation {
        let sleepQuality: Double
        let recoveryCapacity: Double
        let hrvStatus: Double
        let stressLevel: Double
        let consistency: Double
        let nutrition: Double
        let overallScore: Double
    }
    
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
    
    struct SleepDayData: Identifiable {
        let id = UUID()
        let date: Date
        let deep: Double
        let rem: Double
        let core: Double
        let awake: Double
        let bedtime: Date?
        let wakeTime: Date?
    }
    
    struct WeeklyHeatmapData {
        let trainingData: [WeeklyHeatmap.DayData]
        let sleepData: [WeeklyHeatmap.DayData]
    }
    
    struct CircadianRhythmData {
        let avgBedtime: Double // fractional hour
        let avgWakeTime: Double
        let bedtimeVariance: Double // minutes
        let avgTrainingTime: Double?
        let consistency: Double
    }
    
    // MARK: - Services
    
    private let persistence = PersistenceController.shared
    private let healthKitManager = HealthKitManager.shared
    private let userId: String
    
    // MARK: - Initialization
    
    init() {
        // Get anonymous user ID (same as AIBriefService)
        if let existing = UserDefaults.standard.string(forKey: "ai_brief_user_id") {
            self.userId = existing
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "ai_brief_user_id")
            self.userId = newId
        }
        
        // Calculate Monday of current week
        self.weekStartDate = Self.getMondayOfCurrentWeek()
        self.daysUntilNextReport = Self.daysUntilNextMonday()
    }
    
    // MARK: - Load Data
    
    func loadWeeklyReport() async {
        Logger.debug("📊 Loading weekly performance report...")
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.calculateWellnessFoundation() }
            group.addTask { await self.calculateWeeklyMetrics() }
            group.addTask { await self.calculateTrainingZones() }
            group.addTask { await self.loadSleepArchitecture() }
            group.addTask { await self.generateWeeklyHeatmap() }
            group.addTask { await self.calculateCircadianRhythm() }
            group.addTask { await self.loadCTLHistoricalData() }
        }
        
        // Load AI summary last (depends on other metrics)
        await fetchAISummary()
        
        Logger.debug("✅ Weekly report loaded")
    }
    
    // MARK: - Wellness Foundation Calculation
    
    private func calculateWellnessFoundation() async {
        let last7Days = getLast7Days()
        
        guard !last7Days.isEmpty else {
            Logger.warning("️ No data for wellness foundation")
            return
        }
        
        // Sleep Quality: avg sleep score + consistency
        let sleepScores = last7Days.compactMap { $0.sleepScore > 0 ? $0.sleepScore : nil }
        let avgSleepScore = sleepScores.isEmpty ? 0 : sleepScores.reduce(0, +) / Double(sleepScores.count)
        let sleepConsistency = calculateSleepConsistency(days: last7Days)
        let sleepQuality = (avgSleepScore * 0.7 + sleepConsistency * 0.3)
        
        // Recovery Capacity: avg recovery - recovery debt penalty
        let recoveryScores = last7Days.compactMap { $0.recoveryScore > 0 ? $0.recoveryScore : nil }
        let avgRecovery = recoveryScores.isEmpty ? 0 : recoveryScores.reduce(0, +) / Double(recoveryScores.count)
        let lowRecoveryDays = recoveryScores.filter { $0 < 60 }.count
        let recoveryCapacity = max(0, avgRecovery - Double(lowRecoveryDays) * 3)
        
        // HRV Status: trend + stability
        let hrvValues = last7Days.compactMap { $0.physio?.hrv ?? 0 > 0 ? $0.physio?.hrv : nil }
        let hrvStatus = calculateHRVStatus(values: hrvValues)
        
        // Stress Level: inferred from RHR elevation + low recovery days
        let rhrValues = last7Days.compactMap { $0.physio?.rhr ?? 0 > 0 ? $0.physio?.rhr : nil }
        let stressLevel = calculateStressLevel(rhrValues: rhrValues, lowRecoveryDays: lowRecoveryDays)
        
        // Consistency: sleep + training schedule regularity
        let consistency = sleepConsistency
        
        // Nutrition: inferred from recovery pattern + workout completion
        // High recovery + completed workouts = good nutrition
        let nutrition = min(100, avgRecovery * 1.1)
        
        // Overall: weighted average
        let overall = (sleepQuality * 0.25 + recoveryCapacity * 0.25 + hrvStatus * 0.2 +
                      (100 - stressLevel) * 0.15 + consistency * 0.1 + nutrition * 0.05)
        
        wellnessFoundation = WellnessFoundation(
            sleepQuality: sleepQuality,
            recoveryCapacity: recoveryCapacity,
            hrvStatus: hrvStatus,
            stressLevel: stressLevel,
            consistency: consistency,
            nutrition: nutrition,
            overallScore: overall
        )
        
        Logger.debug("💚 Wellness Foundation: \(Int(overall))/100")
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
        
        // Lower std dev = higher consistency
        // 1 hour std dev = 70/100, 0.5 hour = 85/100
        let consistencyScore = max(0, min(100, 100 - (stdDev / 3600) * 30))
        return consistencyScore
    }
    
    private func calculateHRVStatus(values: [Double]) -> Double {
        guard values.count >= 3 else { return 50 }
        
        let avg = values.reduce(0, +) / Double(values.count)
        let recent = Array(values.suffix(3))
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        
        // Compare recent to overall average
        let change = ((recentAvg - avg) / avg) * 100
        
        // Rising HRV = good (up to 100), falling = poor (down to 0)
        return min(100, max(0, 70 + change))
    }
    
    private func calculateStressLevel(rhrValues: [Double], lowRecoveryDays: Int) -> Double {
        guard !rhrValues.isEmpty else { return 50 }
        
        let avg = rhrValues.reduce(0, +) / Double(rhrValues.count)
        let recent = Array(rhrValues.suffix(3))
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        
        // Elevated RHR = stress
        let rhrElevation = max(0, ((recentAvg - avg) / avg) * 100)
        
        // Low recovery days = stress
        let recoveryStress = Double(lowRecoveryDays) * 10
        
        return min(100, rhrElevation * 2 + recoveryStress)
    }
    
    // MARK: - Weekly Metrics
    
    private func calculateWeeklyMetrics() async {
        let thisWeek = getLast7Days()
        let lastWeek = getPrevious7Days()
        
        Logger.debug("📊 [WEEKLY METRICS DEBUG]")
        Logger.debug("   This week: \(thisWeek.count) days")
        Logger.debug("   Last week: \(lastWeek.count) days")
        
        guard !thisWeek.isEmpty else {
            Logger.warning("⚠️ No data for weekly metrics")
            return
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
        
        Logger.debug("   📊 Checking TSS data...")
        for (index, day) in thisWeek.enumerated() {
            let tss = day.load?.tss ?? 0
            let ctl = day.load?.ctl ?? 0
            let atl = day.load?.atl ?? 0
            Logger.debug("      Day \(index): TSS=\(tss), CTL=\(ctl), ATL=\(atl)")
        }
        
        let tssValues = thisWeek.compactMap { day -> Double? in
            guard let tss = day.load?.tss, tss > 0 else { return nil }
            return tss
        }
        let weeklyTSS = tssValues.reduce(0, +)
        Logger.debug("   📊 Weekly TSS: \(weeklyTSS) from \(tssValues.count) days")
        
        // Calculate duration from TSS (rough estimate: TSS ≈ intensity × duration in hours)
        // For now, use TSS as proxy for training time (1 TSS ≈ 1 minute of moderate effort)
        let weeklyDuration = weeklyTSS * 60 // Convert TSS to seconds as rough estimate
        Logger.debug("   ⏱️ Weekly Duration: ~\(Int(weeklyDuration/60))min (estimated from TSS)")
        
        // CTL/ATL (from last day of week)
        let lastDay = thisWeek.last
        let ctlStart = thisWeek.first?.load?.ctl ?? 0
        let ctlEnd = lastDay?.load?.ctl ?? 0
        let atl = lastDay?.load?.atl ?? 0
        let tsb = ctlEnd - atl
        Logger.debug("   📈 CTL: \(ctlStart) → \(ctlEnd), ATL: \(atl), TSB: \(tsb)")
        
        // HRV
        let hrvValues = thisWeek.compactMap { day -> Double? in
            guard let hrv = day.physio?.hrv, hrv > 0 else { return nil }
            return hrv
        }
        let hrvTrend = determineHRVTrend(values: hrvValues)
        
        // Training Load
        let workoutCount = thisWeek.filter { ($0.load?.tss ?? 0) > 0 }.count
        
        weeklyMetrics = WeeklyMetrics(
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
        
        Logger.debug("✅ Weekly Metrics Complete: Recovery \(Int(avgRecovery))%, TSS \(Int(weeklyTSS)), Duration \(Int(weeklyDuration))s, CTL \(Int(ctlEnd))")
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
    
    private func calculateTrainingZones() async {
        let thisWeek = getLast7Days()
        
        var restoringDays = 0
        var optimalDays = 0
        var overreachingDays = 0
        
        for day in thisWeek {
            let recovery = day.recoveryScore
            let strain = day.strainScore
            
            // Classify day into training zone
            if strain < 5 || recovery < 40 {
                restoringDays += 1
            } else if strain > 12 || (strain > 8 && recovery < 60) {
                overreachingDays += 1
            } else {
                optimalDays += 1
            }
        }
        
        // Calculate zone distribution (mock for now - need actual power zone data)
        // TODO: Calculate from actual Intervals.icu zone time data
        let zoneEasy = Double.random(in: 72...85)
        let zoneHard = Double.random(in: 8...15)
        let zoneTempo = 100 - zoneEasy - zoneHard
        
        // Polarization score: how close to 80/20 rule
        let targetEasy = 80.0
        let easyDeviation = abs(zoneEasy - targetEasy)
        let polarization = max(0, min(100, 100 - easyDeviation * 2))
        
        trainingZoneDistribution = TrainingZoneDistribution(
            restoringDays: restoringDays,
            optimalDays: optimalDays,
            overreachingDays: overreachingDays,
            zoneEasyPercent: zoneEasy,
            zoneTempoPercent: zoneTempo,
            zoneHardPercent: zoneHard,
            polarizationScore: polarization
        )
        
        Logger.debug("🎯 Training Zones: \(optimalDays) optimal, \(overreachingDays) overreach, \(restoringDays) rest")
    }
    
    // MARK: - Sleep Architecture
    
    private func loadSleepArchitecture() async {
        let thisWeek = getLast7Days()
        var sleepDataArray: [SleepDayData] = []
        var hypnogramArray: [SleepNightData] = []
        
        for day in thisWeek {
            guard let date = day.date else { continue }
            
            // Fetch actual sleep data from HealthKit for this day
            let dayStart = Calendar.current.startOfDay(for: date)
            guard let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) else { continue }
            
            do {
                let samples = try await healthKitManager.fetchSleepData(from: dayStart, to: dayEnd)
                
                var deep: TimeInterval = 0
                var rem: TimeInterval = 0
                var core: TimeInterval = 0
                var awake: TimeInterval = 0
                var earliestBedtime: Date?
                var latestWakeTime: Date?
                
                // Convert HK samples to hypnogram samples
                var hypnogramSamples: [SleepHypnogramChart.SleepStageSample] = []
                
                for sample in samples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    
                    // Track bedtime and wake time
                    if earliestBedtime == nil || sample.startDate < earliestBedtime! {
                        earliestBedtime = sample.startDate
                    }
                    if latestWakeTime == nil || sample.endDate > latestWakeTime! {
                        latestWakeTime = sample.endDate
                    }
                    
                    // Add to hypnogram
                    if let hypnogramSample = SleepHypnogramChart.SleepStageSample(from: sample) {
                        hypnogramSamples.append(hypnogramSample)
                    }
                    
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
                
                if deep > 0 || rem > 0 || core > 0 {
                    sleepDataArray.append(SleepDayData(
                        date: date,
                        deep: deep / 3600.0,
                        rem: rem / 3600.0,
                        core: core / 3600.0,
                        awake: awake / 3600.0,
                        bedtime: earliestBedtime,
                        wakeTime: latestWakeTime
                    ))
                    
                    // Add hypnogram data if we have bedtime and wake time
                    if let bedtime = earliestBedtime, let wakeTime = latestWakeTime, !hypnogramSamples.isEmpty {
                        hypnogramArray.append(SleepNightData(
                            date: date,
                            samples: hypnogramSamples,
                            bedtime: bedtime,
                            wakeTime: wakeTime
                        ))
                    }
                }
            } catch {
                Logger.error("Failed to fetch sleep data for \(date): \(error)")
            }
        }
        
        // Filter out future sleep sessions (shouldn't happen, but just in case)
        let now = Date()
        let pastHypnograms = hypnogramArray.filter { $0.wakeTime < now }
        
        sleepArchitecture = sleepDataArray
        sleepHypnograms = pastHypnograms
        
        Logger.debug("😴 Sleep Architecture: \(sleepDataArray.count) days, \(hypnogramArray.count) total hypnograms (\(pastHypnograms.count) past) from HealthKit")
    }
    
    // MARK: - Heatmap
    
    private func generateWeeklyHeatmap() async {
        let thisWeek = getLast7Days()
        
        var trainingData: [WeeklyHeatmap.DayData] = []
        var sleepData: [WeeklyHeatmap.DayData] = []
        
        for (index, day) in thisWeek.enumerated() {
            let dayOfWeek = index + 1 // 1 = Monday
            
            // Training intensity (simplified - AM/PM based on strain)
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
        
        weeklyHeatmap = WeeklyHeatmapData(trainingData: trainingData, sleepData: sleepData)
    }
    
    // MARK: - Circadian Rhythm
    
    private func calculateCircadianRhythm() async {
        // Use actual bedtime/wake time from sleep architecture
        Logger.debug("🕐 [SLEEP SCHEDULE DEBUG]")
        Logger.debug("   Sleep architecture entries: \(sleepArchitecture.count)")
        
        guard !sleepArchitecture.isEmpty else {
            Logger.warning("   ⚠️ No sleep architecture data")
            return
        }
        
        // Only use PAST sleep (not future)
        let now = Date()
        let pastSleep = sleepArchitecture.filter { sleep in
            guard let wakeTime = sleep.wakeTime else { return false }
            return wakeTime < now
        }
        Logger.debug("   Past sleep sessions: \(pastSleep.count)")
        
        let bedtimes = pastSleep.compactMap { $0.bedtime }.compactMap { $0 }
        let wakeTimes = pastSleep.compactMap { $0.wakeTime }.compactMap { $0 }
        
        guard !bedtimes.isEmpty && !wakeTimes.isEmpty else {
            Logger.warning("   ⚠️ No valid bedtime/wake time data")
            return
        }
        
        // Calculate average bedtime (in fractional hours from midnight)
        // Need to handle times after midnight (e.g., 23:00 = 23.0, 00:30 = 24.5 to avoid averaging issues)
        let bedtimeHours = bedtimes.map { date -> Double in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            var hour = Double(components.hour ?? 0)
            let minute = Double(components.minute ?? 0) / 60.0
            
            // If bedtime is before 6am, treat as next day (e.g., 1am = 25.0)
            if hour < 6 {
                hour += 24
            }
            
            let fractionalHour = hour + minute
            let timeStr = String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
            Logger.debug("      Bedtime: \(timeStr) = \(fractionalHour)h")
            return fractionalHour
        }
        let avgBedtimeRaw = bedtimeHours.reduce(0, +) / Double(bedtimeHours.count)
        // Normalize back to 0-24 range
        let avgBedtime = avgBedtimeRaw >= 24 ? avgBedtimeRaw - 24 : avgBedtimeRaw
        Logger.debug("   Average bedtime: \(avgBedtime)h (raw: \(avgBedtimeRaw))")
        
        // Calculate average wake time (simpler - always morning)
        let wakeTimeHours = wakeTimes.map { date -> Double in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            let fractionalHour = Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60.0
            let timeStr = String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
            Logger.debug("      Wake: \(timeStr) = \(fractionalHour)h")
            return fractionalHour
        }
        let avgWakeTime = wakeTimeHours.reduce(0, +) / Double(wakeTimeHours.count)
        Logger.debug("   Average wake time: \(avgWakeTime)h")
        
        // Calculate bedtime variance (standard deviation in minutes)
        let avgBedtimeMinutes = avgBedtime * 60
        let bedtimeMinutes = bedtimeHours.map { $0 * 60 }
        let varianceSum = bedtimeMinutes.map { pow($0 - avgBedtimeMinutes, 2) }.reduce(0, +)
        let variance = varianceSum / Double(bedtimeMinutes.count)
        let bedtimeVariance = sqrt(variance)
        
        // Training time (could be fetched from workout times if needed)
        let avgTrainingTime: Double? = nil // TODO: Calculate from workout times
        
        let thisWeek = getLast7Days()
        let consistency = calculateSleepConsistency(days: thisWeek)
        
        circadianRhythm = CircadianRhythmData(
            avgBedtime: avgBedtime,
            avgWakeTime: avgWakeTime,
            bedtimeVariance: bedtimeVariance,
            avgTrainingTime: avgTrainingTime,
            consistency: consistency
        )
        
        Logger.debug("⏰ Circadian Rhythm: Bedtime \(String(format: "%.1f", avgBedtime))h, Wake \(String(format: "%.1f", avgWakeTime))h, Variance ±\(Int(bedtimeVariance))min")
    }
    
    // MARK: - CTL Historical Data
    
    private func loadCTLHistoricalData() async {
        let thisWeek = getLast7Days()
        
        Logger.debug("📊 Loading CTL data for \(thisWeek.count) days")
        
        var dataPoints: [FitnessTrajectoryChart.DataPoint] = []
        var daysWithoutLoad = 0
        
        for day in thisWeek {
            if let date = day.date {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d"
                let dateStr = dateFormatter.string(from: date)
                
                if let load = day.load {
                    Logger.debug("  \(dateStr): CTL=\(String(format: "%.1f", load.ctl)), ATL=\(String(format: "%.1f", load.atl))")
                } else {
                    Logger.debug("  \(dateStr): No load data")
                    daysWithoutLoad += 1
                }
            }
            
            guard let date = day.date,
                  let ctl = day.load?.ctl,
                  let atl = day.load?.atl else {
                continue
            }
            
            let tsb = ctl - atl
            
            dataPoints.append(FitnessTrajectoryChart.DataPoint(
                date: date,
                ctl: ctl,
                atl: atl,
                tsb: tsb
            ))
        }
        
        // Check if we have meaningful data (not all zeros)
        let hasNonZeroData = dataPoints.contains { $0.ctl > 0 || $0.atl > 0 }
        
        if !dataPoints.isEmpty && hasNonZeroData {
            ctlHistoricalData = dataPoints
            Logger.debug("📈 CTL Historical: \(dataPoints.count) days loaded")
        } else {
            Logger.warning("⚠️ No meaningful CTL data available (\(daysWithoutLoad) days without load data, \(dataPoints.count) days with zero values)")
            Logger.warning("   Attempting to calculate CTL/ATL from activities...")
            
            // Try to calculate missing CTL/ATL
            await CacheManager.shared.calculateMissingCTLATL()
            
            // Reload data after calculation
            let reloadedWeek = getLast7Days()
            var reloadedPoints: [FitnessTrajectoryChart.DataPoint] = []
            
            for day in reloadedWeek {
                guard let date = day.date,
                      let ctl = day.load?.ctl,
                      let atl = day.load?.atl,
                      ctl > 0 || atl > 0 else {
                    continue
                }
                
                let tsb = ctl - atl
                reloadedPoints.append(FitnessTrajectoryChart.DataPoint(
                    date: date,
                    ctl: ctl,
                    atl: atl,
                    tsb: tsb
                ))
            }
            
            if !reloadedPoints.isEmpty {
                ctlHistoricalData = reloadedPoints
                Logger.debug("📈 CTL Historical: \(reloadedPoints.count) days loaded after calculation")
            } else {
                Logger.warning("⚠️ Still no CTL data after calculation - may need more activities with TSS")
            }
        }
    }
    
    // MARK: - AI Summary
    
    private func fetchAISummary() async {
        Logger.debug("🤖 [AI SUMMARY] Starting fetch...")
        
        guard let metrics = weeklyMetrics,
              let zones = trainingZoneDistribution else {
            Logger.warning("⚠️ Missing data for AI summary")
            Logger.debug("   weeklyMetrics: \(weeklyMetrics == nil ? "nil" : "present")")
            Logger.debug("   trainingZoneDistribution: \(trainingZoneDistribution == nil ? "nil" : "present")")
            return
        }
        
        isLoadingAI = true
        aiError = nil
        
        defer { isLoadingAI = false }
        
        // Build request payload
        let weekSummary = determineWeekSummary()
        Logger.debug("   Week summary: \(weekSummary)")
        Logger.debug("   Recovery: \(Int(metrics.avgRecovery))% (change: \(Int(metrics.recoveryChange))%)")
        Logger.debug("   TSS: \(Int(metrics.weeklyTSS))")
        Logger.debug("   CTL: \(Int(metrics.ctlStart)) → \(Int(metrics.ctlEnd))")
        
        let payload: [String: Any] = [
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
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            let response = try await fetchFromAPI(body: jsonData)
            aiSummary = response.text
            Logger.debug("✅ AI weekly summary generated (\(response.cached ? "cached" : "fresh"))")
        } catch {
            aiError = error.localizedDescription
            aiSummary = getFallbackSummary()
            Logger.error("AI weekly summary error: \(error)")
        }
    }
    
    private func determineWeekSummary() -> String {
        guard let metrics = weeklyMetrics else { return "Unknown" }
        
        let ctlChange = metrics.ctlEnd - metrics.ctlStart
        let recoveryChange = metrics.recoveryChange
        
        if ctlChange > 3 && recoveryChange > -5 {
            return "Building phase"
        } else if abs(ctlChange) < 2 && recoveryChange > 5 {
            return "Recovery week"
        } else if metrics.weeklyTSS < 300 {
            return "Taper week"
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
        
        // Get HMAC secret from Keychain (same as AIBriefClient)
        guard let secret = KeychainHelper.shared.get(service: "com.veloready.app.secrets", account: "APP_HMAC_SECRET") else {
            throw NSError(domain: "WeeklyReport", code: -2, userInfo: [NSLocalizedDescriptionKey: "Missing HMAC secret"])
        }
        
        // Calculate HMAC signature using CryptoKit (same as AIBriefClient)
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
    
    private func getFallbackSummary() -> String {
        guard let metrics = weeklyMetrics else {
            return "Your weekly performance data is being analyzed. Check back shortly for your personalized report."
        }
        
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
        let diff = day == 1 ? -6 : 2 - day // If Sunday, go back 6 days; otherwise go to Monday
        return calendar.date(byAdding: .day, value: diff, to: now)!
    }
    
    static func daysUntilNextMonday() -> Int {
        let now = Date()
        let calendar = Calendar.current
        let day = calendar.component(.weekday, from: now)
        return day == 1 ? 0 : 9 - day // If Sunday (1), it's 0 days; else count to next Monday
    }
}
