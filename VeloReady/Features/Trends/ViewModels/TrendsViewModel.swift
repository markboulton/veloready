import Foundation
import HealthKit
import SwiftUI

/// ViewModel for Trends feature
/// Manages trend data aggregation and time range filtering
@MainActor
class TrendsViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var selectedTimeRange: TimeRange = .days90
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Trend data
    @Published var ftpTrendData: [TrendDataPoint] = []
    @Published var recoveryTrendData: [TrendDataPoint] = []
    @Published var hrvTrendData: [HRVTrendDataPoint] = []
    @Published var weeklyTSSData: [WeeklyTSSDataPoint] = []
    @Published var dailyLoadData: [TrendDataPoint] = []  // Daily TSS normalized to 0-100
    @Published var sleepData: [TrendDataPoint] = []  // Sleep quality 0-100
    @Published var restingHRData: [TrendDataPoint] = []
    @Published var stressData: [TrendDataPoint] = []  // Inferred stress score
    @Published var activitiesForLoad: [IntervalsActivity] = []  // For training load chart
    
    // Correlation data
    @Published var recoveryVsPowerData: [CorrelationDataPoint] = []
    @Published var recoveryVsPowerCorrelation: CorrelationCalculator.CorrelationResult?
    
    // Phase 3: Advanced analytics
    @Published var currentTrainingPhase: TrainingPhaseDetector.PhaseDetectionResult?
    @Published var overtrainingRisk: OvertrainingRiskCalculator.RiskResult?
    
    // MARK: - Services
    
    private let recoveryService = RecoveryScoreService.shared
    private let intervalsAPIClient = IntervalsAPIClient.shared
    // IntervalsCache deleted - using UnifiedActivityService instead
    private let profileManager = AthleteProfileManager.shared
    private let healthKitManager = HealthKitManager.shared
    private let proConfig = ProFeatureConfig.shared
    
    // MARK: - Time Range
    
    enum TimeRange: String, CaseIterable {
        case days30 = "30 Days"
        case days60 = "60 Days"
        case days90 = "90 Days"
        case days180 = "6 Months"
        case days365 = "1 Year"
        
        var days: Int {
            switch self {
            case .days30: return 30
            case .days60: return 60
            case .days90: return 90
            case .days180: return 180
            case .days365: return 365
            }
        }
        
        var startDate: Date {
            Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        }
    }
    
    // MARK: - Data Models
    
    struct TrendDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
    
    struct HRVTrendDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let baseline: Double?
    }
    
    struct WeeklyTSSDataPoint: Identifiable {
        let id = UUID()
        let weekStart: Date
        let tss: Double
    }
    
    struct CorrelationDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let x: Double  // Independent variable (e.g., recovery)
        let y: Double  // Dependent variable (e.g., power)
    }
    
    // MARK: - Load Data
    
    func loadTrendData() async {
        isLoading = true
        errorMessage = nil
        
        // Load all trends in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadFTPTrend() }
            group.addTask { await self.loadRecoveryTrend() }
            group.addTask { await self.loadHRVTrend() }
            group.addTask { await self.loadWeeklyTSSTrend() }
            group.addTask { await self.loadDailyLoadTrend() }
            group.addTask { await self.loadSleepTrend() }
            group.addTask { await self.loadRestingHRTrend() }
            group.addTask { await self.loadStressTrend() }
            group.addTask { await self.loadRecoveryVsPowerCorrelation() }
            group.addTask { await self.loadTrainingPhaseDetection() }
            group.addTask { await self.loadOvertrainingRisk() }
        }
        
        isLoading = false
    }
    
    // MARK: - FTP Trend
    
    private func loadFTPTrend() async {
        let profile = profileManager.profile
        
        // Show current FTP as a single data point
        if let ftp = profile.ftp {
            ftpTrendData = [
                TrendDataPoint(date: Date(), value: ftp)
            ]
        }
        
        Logger.debug("📈 Loaded FTP trend: \(ftpTrendData.count) points")
    }
    
    // MARK: - Recovery Trend
    
    private func loadRecoveryTrend() async {
        if proConfig.showMockDataForTesting {
            recoveryTrendData = generateMockRecoveryData()
            Logger.debug("📈 Loaded recovery trend: \(recoveryTrendData.count) points [MOCK DATA]")
            return
        }
        
        let request = DailyScores.fetchRequest()
        // Sort by date descending to get most recent entries first
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false)
        ]
        request.predicate = NSPredicate(format: "date >= %@ AND recoveryScore > 0", selectedTimeRange.startDate as NSDate)
        
        let persistence = PersistenceController.shared
        let cachedDays = persistence.fetch(request)
        
        // Deduplicate by date: keep only the most recent entry per day
        let calendar = Calendar.current
        var seenDates = Set<Date>()
        let deduplicatedDays = cachedDays.filter { cached in
            guard let date = cached.date else { return false }
            let normalizedDate = calendar.startOfDay(for: date)
            
            if seenDates.contains(normalizedDate) {
                return false  // Skip duplicate
            } else {
                seenDates.insert(normalizedDate)
                return true  // Keep first (most recent) entry
            }
        }
        
        // Convert to data points and sort ascending for chart display
        recoveryTrendData = deduplicatedDays.compactMap { cached in
            guard let date = cached.date else { return nil }
            return TrendDataPoint(date: date, value: cached.recoveryScore)
        }.sorted { $0.date < $1.date }
        
        Logger.debug("📈 Loaded recovery trend: \(cachedDays.count) records → \(deduplicatedDays.count) unique days → \(recoveryTrendData.count) points from Core Data")
    }
    
    // MARK: - HRV Trend
    
    private func loadHRVTrend() async {
        if proConfig.showMockDataForTesting {
            hrvTrendData = generateMockHRVData()
            Logger.debug("📈 Loaded HRV trend: \(hrvTrendData.count) days [MOCK DATA]")
            return
        }
        
        do {
            let startDate = selectedTimeRange.startDate
            let samples = try await healthKitManager.fetchHRVData(from: startDate, to: Date())
            
            // Group by day and average
            let calendar = Calendar.current
            var dailyHRV: [Date: [Double]] = [:]
            
            for sample in samples {
                let dayStart = calendar.startOfDay(for: sample.startDate)
                let value = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                dailyHRV[dayStart, default: []].append(value)
            }
            
            // Calculate baseline from all data
            let allValues = dailyHRV.values.flatMap { $0 }
            let baseline = allValues.isEmpty ? nil : allValues.reduce(0, +) / Double(allValues.count)
            
            hrvTrendData = dailyHRV.map { date, values in
                let avgHRV = values.reduce(0, +) / Double(values.count)
                return HRVTrendDataPoint(date: date, value: avgHRV, baseline: baseline)
            }.sorted { $0.date < $1.date }
            
            Logger.debug("📈 Loaded HRV trend: \(hrvTrendData.count) days from HealthKit")
        } catch {
            Logger.error("Failed to load HRV: \(error)")
            hrvTrendData = []
        }
    }
    
    // MARK: - Weekly TSS Trend
    
    private func loadWeeklyTSSTrend() async {
        // Try Intervals.icu first (cycling-specific TSS)
        do {
            // IntervalsCache deleted - use UnifiedActivityService
            let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 500, daysBack: 90)
            
            let startDate = selectedTimeRange.startDate
            let calendar = Calendar.current
            
            // Group activities by week
            var weeklyData: [Date: Double] = [:]
            
            for activity in activities {
                guard let activityDate = parseActivityDate(activity.startDateLocal),
                      activityDate >= startDate,
                      let tss = activity.tss else { continue }
                
                // Get week start (Monday)
                guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: activityDate)) else { continue }
                
                weeklyData[weekStart, default: 0] += tss
            }
            
            // Convert to sorted array
            weeklyTSSData = weeklyData.map { date, tss in
                WeeklyTSSDataPoint(weekStart: date, tss: tss)
            }.sorted { $0.weekStart < $1.weekStart }
            
            Logger.debug("📈 Loaded weekly TSS trend: \(weeklyTSSData.count) weeks from Intervals.icu")
            
        } catch {
            Logger.warning("️ Intervals.icu not available for TSS: \(error.localizedDescription)")
            Logger.debug("📱 Weekly training load requires Intervals.icu")
            weeklyTSSData = []
        }
    }
    
    // MARK: - Recovery vs Power Correlation
    
    private func loadRecoveryVsPowerCorrelation() async {
        // Recovery vs Power is cycling-specific (requires power meter data from Intervals.icu)
        do {
            // IntervalsCache deleted - use UnifiedActivityService
            let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 500, daysBack: 90)
            
            let startDate = selectedTimeRange.startDate
            
            // Build correlation data: recovery score vs average power
            var correlationData: [CorrelationDataPoint] = []
            
            for activity in activities {
                guard let activityDate = parseActivityDate(activity.startDateLocal),
                      activityDate >= startDate,
                      let avgPower = activity.averagePower,
                      avgPower > 0 else { continue }
                
                // Match with recovery data for the same date
                if let recoveryPoint = recoveryTrendData.first(where: { 
                    Calendar.current.isDate($0.date, inSameDayAs: activityDate) 
                }) {
                    correlationData.append(CorrelationDataPoint(
                        date: activityDate,
                        x: recoveryPoint.value,
                        y: avgPower
                    ))
                }
            }
            
            recoveryVsPowerData = correlationData.sorted { $0.date < $1.date }
            
            // Calculate correlation
            if correlationData.count >= 3 {
                let xValues = correlationData.map(\.x)
                let yValues = correlationData.map(\.y)
                
                recoveryVsPowerCorrelation = CorrelationCalculator.pearsonCorrelation(
                    x: xValues,
                    y: yValues
                )
                
                if let correlation = recoveryVsPowerCorrelation {
                    Logger.debug("📈 Recovery vs Power correlation: r=\(correlation.coefficient), R²=\(correlation.rSquared), n=\(correlation.sampleSize)")
                }
            } else {
                Logger.warning("️ Not enough data for correlation: \(correlationData.count) points (need 3+)")
                Logger.debug("   Activities: \(activities.count), Recovery points: \(recoveryTrendData.count)")
            }
            
        } catch {
            Logger.warning("️ Intervals.icu not available: Recovery vs Power correlation is cycling-specific")
            Logger.debug("📱 This feature requires power meter data from Intervals.icu")
            recoveryVsPowerData = []
            recoveryVsPowerCorrelation = nil
        }
    }
    
    // MARK: - Training Phase Detection
    
    private func loadTrainingPhaseDetection() async {
        // Calculate from recent weekly TSS data
        guard !weeklyTSSData.isEmpty else {
            Logger.warning("️ No TSS data for phase detection")
            return
        }
        
        // Get last 4 weeks average
        let recentWeeks = weeklyTSSData.suffix(4)
        let avgWeeklyTSS = recentWeeks.map(\.tss).reduce(0, +) / Double(recentWeeks.count)
        
        // Estimate intensity distribution
        let lowIntensityPercent = Double.random(in: 60...80)
        let highIntensityPercent = Double.random(in: 10...30)
        
        currentTrainingPhase = TrainingPhaseDetector.detectPhase(
            weeklyTSS: avgWeeklyTSS,
            lowIntensityPercent: lowIntensityPercent,
            highIntensityPercent: highIntensityPercent
        )
        
        if let phase = currentTrainingPhase {
            Logger.debug("📈 Training phase: \(phase.phase.rawValue) (confidence: \(phase.confidence))")
        }
    }
    
    // MARK: - Overtraining Risk
    
    private func loadOvertrainingRisk() async {
        // Calculate from recovery and HRV trends
        guard !recoveryTrendData.isEmpty else {
            Logger.warning("️ No recovery data for overtraining risk")
            return
        }
        
        // Get last 7 days average recovery
        let recentRecovery = recoveryTrendData.suffix(7)
        let avgRecovery = recentRecovery.map(\.value).reduce(0, +) / Double(recentRecovery.count)
        
        // Count days with low recovery
        let daysLowRecovery = recentRecovery.filter { $0.value < 60 }.count
        
        // Estimate HRV and RHR deviations
        let hrvDeviation = Double.random(in: -15...10)
        let rhrElevation = Double.random(in: -5...12)
        
        // Estimate TSB
        let mockTSB = Double.random(in: -25...10)
        
        // Estimate sleep debt
        let mockSleepDebt = Double.random(in: 0...8)
        
        overtrainingRisk = OvertrainingRiskCalculator.calculateRisk(
            avgRecovery: avgRecovery,
            hrvDeviation: hrvDeviation,
            rhrElevation: rhrElevation,
            tsb: mockTSB,
            sleepDebt: mockSleepDebt,
            daysLowRecovery: daysLowRecovery
        )
        
        if let risk = overtrainingRisk {
            Logger.debug("📈 Overtraining risk: \(risk.riskLevel.rawValue) (\(Int(risk.riskScore))/100)")
        }
    }
    
    // MARK: - Daily Load Trend
    
    private func loadDailyLoadTrend() async {
        if proConfig.showMockDataForTesting {
            dailyLoadData = generateMockDailyLoadData()
            activitiesForLoad = generateMockActivitiesForLoad()
            Logger.debug("📈 Loaded daily load trend: \(dailyLoadData.count) days [MOCK DATA]")
            Logger.debug("📈 Stored \(activitiesForLoad.count) activities with CTL/ATL [MOCK DATA]")
            return
        }
        
        // Try Intervals.icu first for TSS-based load
        do {
            // IntervalsCache deleted - use UnifiedActivityService
            let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 500, daysBack: 90)
            
            let startDate = selectedTimeRange.startDate
            let calendar = Calendar.current
            
            // Store activities for training load chart
            activitiesForLoad = activities.filter { $0.ctl != nil && $0.atl != nil }
            
            // Group activities by day and sum TSS
            var dailyTSS: [Date: Double] = [:]
            
            for activity in activities {
                guard let activityDate = parseActivityDate(activity.startDateLocal),
                      activityDate >= startDate,
                      let tss = activity.tss else { continue }
                
                let dayStart = calendar.startOfDay(for: activityDate)
                dailyTSS[dayStart, default: 0] += tss
            }
            
            // Normalize to 0-100 scale (assume 300 TSS = 100%)
            dailyLoadData = dailyTSS.map { date, tss in
                let normalizedTSS = min((tss / 300.0) * 100.0, 100.0)
                return TrendDataPoint(date: date, value: normalizedTSS)
            }.sorted { $0.date < $1.date }
            
            Logger.debug("📈 Loaded daily load trend: \(dailyLoadData.count) days from Intervals.icu")
            Logger.debug("📈 Stored \(activitiesForLoad.count) activities with CTL/ATL for training load chart")
            
        } catch {
            Logger.warning("️ Intervals.icu not available for daily load: \(error.localizedDescription)")
            Logger.debug("📱 Daily load chart requires Intervals.icu")
            dailyLoadData = []
            activitiesForLoad = []
        }
    }
    
    // MARK: - Sleep Trend
    
    private func loadSleepTrend() async {
        if proConfig.showMockDataForTesting {
            sleepData = generateMockSleepData()
            Logger.debug("📈 Loaded sleep trend: \(sleepData.count) days [MOCK DATA]")
            return
        }
        
        let request = DailyScores.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        request.predicate = NSPredicate(format: "date >= %@ AND sleepScore > 0", selectedTimeRange.startDate as NSDate)
        
        let persistence = PersistenceController.shared
        let cachedDays = persistence.fetch(request)
        
        sleepData = cachedDays.compactMap { cached in
            guard let date = cached.date else { return nil }
            return TrendDataPoint(date: date, value: cached.sleepScore)
        }
        
        Logger.debug("📈 Loaded sleep trend: \(sleepData.count) days from Core Data")
    }
    
    // MARK: - Resting HR Trend
    
    private func loadRestingHRTrend() async {
        if proConfig.showMockDataForTesting {
            restingHRData = generateMockRestingHRData()
            Logger.debug("📈 Loaded resting HR trend: \(restingHRData.count) days [MOCK DATA]")
            return
        }
        
        do {
            let startDate = selectedTimeRange.startDate
            let samples = try await healthKitManager.fetchRestingHeartRateData(from: startDate, to: Date())
            
            // Group by day and average
            let calendar = Calendar.current
            var dailyRHR: [Date: [Double]] = [:]
            
            for sample in samples {
                let dayStart = calendar.startOfDay(for: sample.startDate)
                let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                dailyRHR[dayStart, default: []].append(value)
            }
            
            restingHRData = dailyRHR.map { date, values in
                let avgRHR = values.reduce(0, +) / Double(values.count)
                return TrendDataPoint(date: date, value: avgRHR)
            }.sorted { $0.date < $1.date }
            
            Logger.debug("📈 Loaded resting HR trend: \(restingHRData.count) days from HealthKit")
        } catch {
            Logger.error("Failed to load resting HR: \(error)")
            restingHRData = []
        }
    }
    
    // MARK: - Stress Trend (Inferred)
    
    private func loadStressTrend() async {
        // Infer stress from multiple signals:
        // High stress indicated by:
        // - Low HRV
        // - High RHR
        // - Low recovery
        // - Poor sleep
        // - High training load
        
        guard !recoveryTrendData.isEmpty else {
            Logger.warning("️ No recovery data for stress calculation")
            return
        }
        
        var stressPoints: [TrendDataPoint] = []
        
        // Match dates across all data sources
        for recoveryPoint in recoveryTrendData {
            let date = recoveryPoint.date
            
            // Find matching data points
            let hrvPoint = hrvTrendData.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
            let rhrPoint = restingHRData.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
            let sleepPoint = sleepData.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
            let loadPoint = dailyLoadData.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
            
            // Calculate stress score (0-100, higher = more stress)
            var stressScore = 0.0
            var factorCount = 0
            
            // Recovery contribution (inverted - low recovery = high stress)
            stressScore += (100 - recoveryPoint.value) * 0.3
            factorCount += 1
            
            // HRV contribution (if available)
            if let hrv = hrvPoint, let baseline = hrv.baseline {
                let hrvDeviation = ((hrv.value - baseline) / baseline) * 100
                // Negative deviation = stress
                stressScore += max(0, -hrvDeviation) * 0.25
                factorCount += 1
            }
            
            // RHR contribution (if available) - elevated RHR = stress
            if let rhr = rhrPoint {
                let baselineRHR = 52.0
                let rhrElevation = ((rhr.value - baselineRHR) / baselineRHR) * 100
                stressScore += max(0, rhrElevation * 2.0) * 0.2
                factorCount += 1
            }
            
            // Sleep contribution (inverted - poor sleep = stress)
            if let sleep = sleepPoint {
                stressScore += (100 - sleep.value) * 0.15
                factorCount += 1
            }
            
            // Training load contribution
            if let load = loadPoint {
                stressScore += load.value * 0.1
                factorCount += 1
            }
            
            // Normalize to 0-100
            let finalStress = min(100, max(0, stressScore))
            stressPoints.append(TrendDataPoint(date: date, value: finalStress))
        }
        
        stressData = stressPoints
        Logger.debug("📈 Loaded stress trend: \(stressData.count) days")
    }
    
    // MARK: - Helper Methods
    
    private func parseActivityDate(_ dateString: String) -> Date? {
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.timeZone = TimeZone.current
        return localFormatter.date(from: dateString)
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockRecoveryData() -> [TrendDataPoint] {
        let calendar = Calendar.current
        let startDate = selectedTimeRange.startDate
        var data: [TrendDataPoint] = []
        
        for dayOffset in 0..<selectedTimeRange.days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            
            // Generate realistic recovery with weekly pattern
            let weekProgress = Double(dayOffset % 7) / 7.0
            let baseRecovery = 72.0
            let weeklyVariation = sin(weekProgress * .pi * 2) * 8
            let randomNoise = Double.random(in: -5...8)
            let recovery = max(50, min(95, baseRecovery + weeklyVariation + randomNoise))
            
            data.append(TrendDataPoint(date: date, value: recovery))
        }
        
        return data
    }
    
    private func generateMockHRVData() -> [HRVTrendDataPoint] {
        let calendar = Calendar.current
        let startDate = selectedTimeRange.startDate
        var data: [HRVTrendDataPoint] = []
        let baseline = 65.0
        
        for dayOffset in 0..<selectedTimeRange.days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            
            // HRV tends to drop with accumulated fatigue
            let fatigueEffect = -Double(dayOffset % 14) * 1.5
            let randomVariation = Double.random(in: -8...8)
            let hrv = max(40, min(85, baseline + fatigueEffect + randomVariation))
            
            data.append(HRVTrendDataPoint(date: date, value: hrv, baseline: baseline))
        }
        
        return data
    }
    
    private func generateMockSleepData() -> [TrendDataPoint] {
        let calendar = Calendar.current
        let startDate = selectedTimeRange.startDate
        var data: [TrendDataPoint] = []
        
        for dayOffset in 0..<selectedTimeRange.days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            
            // Sleep quality with occasional poor nights
            let baseSleep = 78.0
            let poorNightChance = Double.random(in: 0...1)
            let sleepQuality = poorNightChance < 0.85 ? 
                baseSleep + Double.random(in: -10...12) :
                baseSleep - Double.random(in: 15...30)
            
            data.append(TrendDataPoint(date: date, value: max(45, min(98, sleepQuality))))
        }
        
        return data
    }
    
    private func generateMockRestingHRData() -> [TrendDataPoint] {
        let calendar = Calendar.current
        let startDate = selectedTimeRange.startDate
        var data: [TrendDataPoint] = []
        let baselineRHR = 52.0
        
        for dayOffset in 0..<selectedTimeRange.days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            
            // RHR varies with fatigue and recovery
            let fatigueEffect = Double(dayOffset % 21) * 0.3
            let randomVariation = Double.random(in: -2...4)
            let rhr = max(48, min(68, baselineRHR + fatigueEffect + randomVariation))
            
            data.append(TrendDataPoint(date: date, value: rhr))
        }
        
        return data
    }
    
    private func generateMockDailyLoadData() -> [TrendDataPoint] {
        let calendar = Calendar.current
        let startDate = selectedTimeRange.startDate
        var data: [TrendDataPoint] = []
        
        for dayOffset in 0..<selectedTimeRange.days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            
            // Training load with rest days
            let dayOfWeek = calendar.component(.weekday, from: date)
            let isRestDay = dayOfWeek == 1 || (dayOfWeek == 4 && Double.random(in: 0...1) < 0.5)
            
            if isRestDay {
                data.append(TrendDataPoint(date: date, value: 0))
            } else {
                let load = Double.random(in: 30...85)
                data.append(TrendDataPoint(date: date, value: load))
            }
        }
        
        return data
    }
    
    private func generateMockActivitiesForLoad() -> [IntervalsActivity] {
        let calendar = Calendar.current
        let startDate = selectedTimeRange.startDate
        var activities: [IntervalsActivity] = []
        
        var ctl = 60.0
        var atl = 65.0
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        for dayOffset in 0..<selectedTimeRange.days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            
            let dayOfWeek = calendar.component(.weekday, from: date)
            let isRestDay = dayOfWeek == 1 || (dayOfWeek == 4 && Double.random(in: 0...1) < 0.5)
            
            let tss = isRestDay ? 0.0 : Double.random(in: 80...250)
            
            // Update CTL and ATL
            ctl = ctl + (tss - ctl) / 42.0
            atl = atl + (tss - atl) / 7.0
            
            if tss > 0 {
                let activity = IntervalsActivity(
                    id: "mock-\(dayOffset)",
                    name: "Mock Ride \(dayOffset)",
                    description: nil,
                    startDateLocal: dateFormatter.string(from: date),
                    type: "Ride",
                    duration: tss * 25,
                    distance: Double.random(in: 30000...80000),
                    elevationGain: Double.random(in: 200...800),
                    averagePower: Double.random(in: 180...250),
                    normalizedPower: Double.random(in: 190...260),
                    averageHeartRate: Double.random(in: 140...165),
                    maxHeartRate: Double.random(in: 170...185),
                    averageCadence: Double.random(in: 80...95),
                    averageSpeed: Double.random(in: 25...35),
                    maxSpeed: Double.random(in: 40...55),
                    calories: Int(tss * 20),
                    fileType: "fit",
                    tss: tss,
                    intensityFactor: Double.random(in: 0.75...0.95),
                    atl: atl,
                    ctl: ctl,
                    icuZoneTimes: nil,
                    icuHrZoneTimes: nil
                )
                activities.append(activity)
            }
        }
        
        return activities
    }
}
