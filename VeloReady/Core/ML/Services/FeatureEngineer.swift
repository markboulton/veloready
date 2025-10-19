import Foundation

/// Transforms raw historical data into ML-ready feature vectors
@MainActor
class FeatureEngineer {
    
    // MARK: - Public API
    
    /// Extract features from historical data
    /// - Parameter historicalData: Map of dates to historical data points
    /// - Returns: Array of ML training data points
    func extractFeatures(from historicalData: [Date: HistoricalDataPoint]) async -> MLTrainingDataset {
        Logger.debug("🔧 [ML] Starting feature extraction...")
        
        // Sort dates chronologically
        let sortedDates = historicalData.keys.sorted()
        guard !sortedDates.isEmpty else {
            Logger.warning("[ML] No historical data to extract features from")
            return MLTrainingDataset(
                dataPoints: [],
                startDate: Date(),
                endDate: Date(),
                totalDays: 0,
                validDays: 0
            )
        }
        
        let startDate = sortedDates.first!
        let endDate = sortedDates.last!
        
        var dataPoints: [MLTrainingDataPoint] = []
        
        // Process each date
        for (index, date) in sortedDates.enumerated() {
            guard let dataPoint = historicalData[date] else { continue }
            
            // Skip if we can't predict tomorrow (last day)
            guard index < sortedDates.count - 1 else { continue }
            
            let tomorrow = sortedDates[index + 1]
            guard let tomorrowData = historicalData[tomorrow] else { continue }
            
            // Extract features for this day
            if let features = extractDayFeatures(
                date: date,
                dataPoint: dataPoint,
                historicalData: historicalData,
                allDates: sortedDates,
                currentIndex: index
            ) {
                // Extract targets (tomorrow's scores)
                let targetRecovery = tomorrowData.coreDataScore?.recoveryScore ?? 0
                let targetReadiness = calculateReadiness(from: tomorrowData) ?? 0
                
                let trainingPoint = MLTrainingDataPoint(
                    features: features,
                    targetRecovery: targetRecovery,
                    targetReadiness: targetReadiness,
                    dataQuality: features.completeness
                )
                
                dataPoints.append(trainingPoint)
            }
        }
        
        let validCount = dataPoints.filter { $0.isValidForTraining }.count
        Logger.debug("🔧 [ML] Feature extraction complete: \(dataPoints.count) data points (\(validCount) valid)")
        
        return MLTrainingDataset(
            dataPoints: dataPoints,
            startDate: startDate,
            endDate: endDate,
            totalDays: sortedDates.count,
            validDays: validCount
        )
    }
    
    // MARK: - Day Feature Extraction
    
    private func extractDayFeatures(
        date: Date,
        dataPoint: HistoricalDataPoint,
        historicalData: [Date: HistoricalDataPoint],
        allDates: [Date],
        currentIndex: Int
    ) -> MLFeatureVector? {
        
        let calendar = Calendar.current
        
        // Get yesterday's data
        let yesterday = calendar.date(byAdding: .day, value: -1, to: date)
        let yesterdayData = yesterday.flatMap { historicalData[$0] }
        
        // MARK: Physiological Features
        
        let hrv = dataPoint.healthKitData?.hrv ?? dataPoint.coreDataScore?.physio?.hrv
        let hrvBaseline = calculateRollingAverage(
            dates: allDates,
            data: historicalData,
            endIndex: currentIndex,
            window: 30,
            extractor: { $0.healthKitData?.hrv ?? $0.coreDataScore?.physio?.hrv }
        )
        let hrvDelta = calculateDelta(current: hrv, baseline: hrvBaseline)
        
        let hrvCoefficientOfVariation = calculateCoefficientOfVariation(
            dates: allDates,
            data: historicalData,
            endIndex: currentIndex,
            window: 7,
            extractor: { $0.healthKitData?.hrv ?? $0.coreDataScore?.physio?.hrv }
        )
        
        let rhr = dataPoint.healthKitData?.rhr ?? dataPoint.coreDataScore?.physio?.rhr
        let rhrBaseline = calculateRollingAverage(
            dates: allDates,
            data: historicalData,
            endIndex: currentIndex,
            window: 30,
            extractor: { $0.healthKitData?.rhr ?? $0.coreDataScore?.physio?.rhr }
        )
        let rhrDelta = calculateDelta(current: rhr, baseline: rhrBaseline)
        
        let sleepDuration = dataPoint.healthKitData?.sleepDuration ?? 
                           (dataPoint.coreDataScore?.physio?.sleepDuration).map { $0 / 3600.0 }
        let sleepBaseline = calculateRollingAverage(
            dates: allDates,
            data: historicalData,
            endIndex: currentIndex,
            window: 30,
            extractor: { $0.healthKitData?.sleepDuration ?? ($0.coreDataScore?.physio?.sleepDuration).map { $0 / 3600.0 } }
        )
        let sleepDelta = sleepDuration.flatMap { dur in sleepBaseline.map { dur - $0 } }
        
        let respiratoryRate: Double? = nil // Not available in DailyPhysio
        
        // MARK: Training Load Features
        
        let yesterdayStrain = yesterdayData?.coreDataScore?.strainScore
        let yesterdayTSS = yesterdayData?.dailyTSS
        
        let ctl = dataPoint.coreDataScore?.load?.ctl
        let atl = dataPoint.coreDataScore?.load?.atl
        let tsb = dataPoint.coreDataScore?.load?.tsb
        let acuteChronicRatio = atl.flatMap { a in ctl.flatMap { c in c > 0 ? a / c : nil } }
        
        let (trainingMonotony, trainingStrain) = calculateTrainingMonotonyAndStrain(
            dates: allDates,
            data: historicalData,
            endIndex: currentIndex,
            window: 7
        )
        
        // MARK: Recovery Trends
        
        let recoveryTrend7d = calculateRollingAverage(
            dates: allDates,
            data: historicalData,
            endIndex: currentIndex,
            window: 7,
            extractor: { $0.coreDataScore?.recoveryScore }
        )
        
        let recoveryTrend3d = calculateRollingAverage(
            dates: allDates,
            data: historicalData,
            endIndex: currentIndex,
            window: 3,
            extractor: { $0.coreDataScore?.recoveryScore }
        )
        
        let yesterdayRecovery = yesterdayData?.coreDataScore?.recoveryScore
        let currentRecovery = dataPoint.coreDataScore?.recoveryScore
        let recoveryChange = currentRecovery.flatMap { curr in
            yesterdayRecovery.map { curr - $0 }
        }
        
        // MARK: Sleep Trends
        
        let sleepTrend7d = calculateRollingAverage(
            dates: allDates,
            data: historicalData,
            endIndex: currentIndex,
            window: 7,
            extractor: { $0.healthKitData?.sleepDuration ?? (($0.coreDataScore?.physio?.sleepDuration).map { $0 / 3600.0 }) }
        )
        
        let sleepDebt7d = calculateSleepDebt(
            dates: allDates,
            data: historicalData,
            endIndex: currentIndex,
            window: 7,
            baseline: sleepBaseline
        )
        
        let sleepQualityScore = dataPoint.coreDataScore?.sleepScore
        
        // MARK: Temporal Features
        
        let dayOfWeek = calendar.component(.weekday, from: date)
        let adjustedDayOfWeek = dayOfWeek == 1 ? 7 : dayOfWeek - 1 // Convert to Monday=1, Sunday=7
        
        let daysSinceHardWorkout = calculateDaysSinceHardWorkout(
            dates: allDates,
            data: historicalData,
            currentIndex: currentIndex
        )
        
        let trainingBlockDay = currentIndex // Simple approximation
        
        // MARK: Contextual Features
        
        let alcoholDetected = detectAlcohol(
            hrv: hrv,
            hrvBaseline: hrvBaseline,
            sleepDuration: sleepDuration
        )
        
        let illnessMarker = detectIllness(
            hrv: hrv,
            hrvBaseline: hrvBaseline,
            rhr: rhr,
            rhrBaseline: rhrBaseline
        )
        
        let monthOfYear = calendar.component(.month, from: date)
        
        // Create feature vector
        return MLFeatureVector(
            hrv: hrv,
            hrvBaseline: hrvBaseline,
            hrvDelta: hrvDelta,
            hrvCoefficientOfVariation: hrvCoefficientOfVariation,
            rhr: rhr,
            rhrBaseline: rhrBaseline,
            rhrDelta: rhrDelta,
            sleepDuration: sleepDuration,
            sleepBaseline: sleepBaseline,
            sleepDelta: sleepDelta,
            respiratoryRate: respiratoryRate,
            yesterdayStrain: yesterdayStrain,
            yesterdayTSS: yesterdayTSS,
            ctl: ctl,
            atl: atl,
            tsb: tsb,
            acuteChronicRatio: acuteChronicRatio,
            trainingMonotony: trainingMonotony,
            trainingStrain: trainingStrain,
            recoveryTrend7d: recoveryTrend7d,
            recoveryTrend3d: recoveryTrend3d,
            yesterdayRecovery: yesterdayRecovery,
            recoveryChange: recoveryChange,
            sleepTrend7d: sleepTrend7d,
            sleepDebt7d: sleepDebt7d,
            sleepQualityScore: sleepQualityScore,
            dayOfWeek: adjustedDayOfWeek,
            daysSinceHardWorkout: daysSinceHardWorkout,
            trainingBlockDay: trainingBlockDay,
            alcoholDetected: alcoholDetected,
            illnessMarker: illnessMarker,
            monthOfYear: monthOfYear,
            timestamp: Date()
        )
    }
    
    // MARK: - Helper Functions
    
    private func calculateRollingAverage(
        dates: [Date],
        data: [Date: HistoricalDataPoint],
        endIndex: Int,
        window: Int,
        extractor: (HistoricalDataPoint) -> Double?
    ) -> Double? {
        let startIndex = max(0, endIndex - window + 1)
        let windowDates = Array(dates[startIndex...endIndex])
        
        let values = windowDates.compactMap { date in
            data[date].flatMap(extractor)
        }
        
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
    
    private func calculateDelta(current: Double?, baseline: Double?) -> Double? {
        guard let current = current, let baseline = baseline, baseline > 0 else { return nil }
        return (current - baseline) / baseline
    }
    
    private func calculateSleepDebt(
        dates: [Date],
        data: [Date: HistoricalDataPoint],
        endIndex: Int,
        window: Int,
        baseline: Double?
    ) -> Double? {
        guard let baseline = baseline else { return nil }
        
        let startIndex = max(0, endIndex - window + 1)
        let windowDates = Array(dates[startIndex...endIndex])
        
        var debt = 0.0
        for date in windowDates {
            let sleep = data[date]?.healthKitData?.sleepDuration ?? (data[date]?.coreDataScore?.physio?.sleepDuration).map { $0 / 3600.0 }
            if let sleep = sleep {
                let deficit = baseline - sleep
                if deficit > 0 {
                    debt += deficit
                }
            }
        }
        
        return debt
    }
    
    private func calculateDaysSinceHardWorkout(
        dates: [Date],
        data: [Date: HistoricalDataPoint],
        currentIndex: Int
    ) -> Int? {
        // Look back up to 14 days
        for i in (max(0, currentIndex - 14)..<currentIndex).reversed() {
            let date = dates[i]
            if let dataPoint = data[date], dataPoint.dailyTSS > 100 {
                return currentIndex - i
            }
        }
        return nil // No hard workout in last 14 days
    }
    
    private func detectAlcohol(hrv: Double?, hrvBaseline: Double?, sleepDuration: Double?) -> Bool? {
        guard let hrv = hrv, let hrvBaseline = hrvBaseline, hrvBaseline > 0 else { return nil }
        let hrvDrop = (hrvBaseline - hrv) / hrvBaseline
        return hrvDrop > 0.15 // 15% drop suggests alcohol
    }
    
    private func detectIllness(hrv: Double?, hrvBaseline: Double?, rhr: Double?, rhrBaseline: Double?) -> Bool? {
        guard let hrv = hrv, let hrvBaseline = hrvBaseline, hrvBaseline > 0,
              let rhr = rhr, let rhrBaseline = rhrBaseline, rhrBaseline > 0 else { return nil }
        
        let hrvDrop = (hrvBaseline - hrv) / hrvBaseline
        let rhrSpike = (rhr - rhrBaseline) / rhrBaseline
        
        return hrvDrop > 0.15 && rhrSpike > 0.08 // HRV down 15% AND RHR up 8%
    }
    
    private func calculateReadiness(from dataPoint: HistoricalDataPoint) -> Double? {
        // Simple readiness calculation for target value
        guard let recovery = dataPoint.coreDataScore?.recoveryScore else { return nil }
        let sleep = dataPoint.coreDataScore?.sleepScore ?? 50
        let strain = dataPoint.coreDataScore?.strainScore ?? 0
        
        // Simple weighted formula (matches existing ReadinessScore logic)
        let loadReadiness = max(0, 100 - (strain / 18.0 * 100))
        return (recovery * 0.4) + (sleep * 0.35) + (loadReadiness * 0.25)
    }
    
    /// Calculate coefficient of variation (CV) = (std dev / mean) * 100
    /// Used to measure stability/variability in metrics like HRV
    private func calculateCoefficientOfVariation(
        dates: [Date],
        data: [Date: HistoricalDataPoint],
        endIndex: Int,
        window: Int,
        extractor: (HistoricalDataPoint) -> Double?
    ) -> Double? {
        let startIndex = max(0, endIndex - window + 1)
        let windowDates = Array(dates[startIndex...endIndex])
        
        let values = windowDates.compactMap { date in
            data[date].flatMap(extractor)
        }
        
        guard values.count >= 3 else { return nil } // Need at least 3 points
        
        let mean = values.reduce(0, +) / Double(values.count)
        guard mean > 0 else { return nil }
        
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(variance)
        
        return (stdDev / mean) * 100.0
    }
    
    /// Calculate training monotony and strain over a window
    /// Monotony = average TSS / std dev TSS
    /// Strain = total TSS * monotony
    private func calculateTrainingMonotonyAndStrain(
        dates: [Date],
        data: [Date: HistoricalDataPoint],
        endIndex: Int,
        window: Int
    ) -> (monotony: Double?, strain: Double?) {
        let startIndex = max(0, endIndex - window + 1)
        let windowDates = Array(dates[startIndex...endIndex])
        
        let tssValues = windowDates.compactMap { date in
            data[date]?.dailyTSS
        }
        
        guard tssValues.count >= 3 else { return (nil, nil) } // Need at least 3 points
        
        let mean = tssValues.reduce(0, +) / Double(tssValues.count)
        let variance = tssValues.map { pow($0 - mean, 2) }.reduce(0, +) / Double(tssValues.count)
        let stdDev = sqrt(variance)
        
        guard stdDev > 0 else { return (nil, nil) } // Avoid division by zero
        
        let monotony = mean / stdDev
        let totalTSS = tssValues.reduce(0, +)
        let strain = totalTSS * monotony
        
        return (monotony, strain)
    }
}
