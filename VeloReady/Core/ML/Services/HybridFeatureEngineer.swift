import Foundation

/// Enhanced feature engineer that handles hybrid datasets
/// Combines ingestible training data with pattern-based augmentations
@MainActor
class HybridFeatureEngineer {
    
    // MARK: - Public API
    
    /// Extract features from hybrid dataset (ingestible data + patterns)
    /// - Parameter dataset: Hybrid dataset with training data and pattern augmentations
    /// - Returns: ML training dataset ready for model training
    func extractFeatures(from dataset: HybridMLDataset) async -> MLTrainingDataset {
        Logger.info("🔧 [HybridML] Starting hybrid feature extraction...")
        
        var dataPoints: [MLTrainingDataPoint] = []
        let dates = dataset.dates
        
        guard !dates.isEmpty else {
            Logger.warning("[HybridML] No dates in hybrid dataset")
            return MLTrainingDataset(
                dataPoints: [],
                startDate: Date(),
                endDate: Date(),
                totalDays: 0,
                validDays: 0
            )
        }
        
        // Process each date
        for (index, date) in dates.enumerated() {
            // Skip last day (can't predict tomorrow)
            guard index < dates.count - 1 else { continue }
            
            let tomorrow = dates[index + 1]
            
            // Extract base features from ingestible sources
            let baseFeatures = extractBaseFeatures(
                date: date,
                activities: dataset.trainingActivities,
                wellness: dataset.wellnessData,
                allDates: dates,
                currentIndex: index
            )
            
            // Augment with pattern features
            let augmentedFeatures = augmentWithPatterns(
                baseFeatures: baseFeatures,
                patterns: dataset.patternAugmentations,
                date: date
            )
            
            // Get tomorrow's wellness for target
            let tomorrowWellness = dataset.wellnessData.first { $0.date == tomorrow }
            let targetRecovery = calculateRecoveryScore(from: tomorrowWellness) ?? 0
            let targetReadiness = calculateReadinessScore(from: tomorrowWellness) ?? 0
            
            if targetRecovery > 0 {
                let trainingPoint = MLTrainingDataPoint(
                    features: augmentedFeatures,
                    targetRecovery: targetRecovery,
                    targetReadiness: targetReadiness,
                    dataQuality: augmentedFeatures.completeness
                )
                
                dataPoints.append(trainingPoint)
            }
        }
        
        let validCount = dataPoints.filter { $0.isValidForTraining }.count
        Logger.info("✅ [HybridML] Feature extraction complete: \(dataPoints.count) data points (\(validCount) valid)")
        
        return MLTrainingDataset(
            dataPoints: dataPoints,
            startDate: dataset.startDate,
            endDate: dataset.endDate,
            totalDays: dates.count,
            validDays: validCount
        )
    }
    
    // MARK: - Base Feature Extraction
    
    /// Extract base features from ingestible sources
    private func extractBaseFeatures(
        date: Date,
        activities: [UnifiedActivity],
        wellness: [WellnessData],
        allDates: [Date],
        currentIndex: Int
    ) -> MLFeatureVector {
        
        // Get wellness data for this date
        let todayWellness = wellness.first { $0.date == date }
        
        // Get activities for this date
        let todayActivities = activities.filter {
            Calendar.current.isDate($0.startDate, inSameDayAs: date)
        }
        
        // Calculate training load features
        let ctl = calculateCTL(activities: activities, upToDate: date)
        let atl = calculateATL(activities: activities, upToDate: date)
        let tsb = (ctl ?? 0) - (atl ?? 0)
        
        // Get yesterday's data
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        let yesterdayActivities = activities.filter {
            Calendar.current.isDate($0.startDate, inSameDayAs: yesterday)
        }
        let yesterdayTSS = yesterdayActivities.compactMap { $0.tss }.reduce(0, +)
        
        // Calculate baselines (30-day)
        let hrvBaseline = calculateHRVBaseline(wellness: wellness, upToDate: date)
        let rhrBaseline = calculateRHRBaseline(wellness: wellness, upToDate: date)
        let sleepBaseline = calculateSleepBaseline(wellness: wellness, upToDate: date)
        
        // RHR fallback strategy (3 levels):
        // 1. Use today's specific RHR if available
        // 2. Use 30-day baseline RHR if available
        // 3. Use athlete's current known RHR as last resort (from AthleteProfile)
        // This is critical for ML training as RHR is a key predictor of recovery
        let effectiveRHR: Double? = todayWellness?.rhr 
            ?? rhrBaseline 
            ?? AthleteProfileManager.shared.profile.restingHR
        
        // Create feature vector
        return MLFeatureVector(
            // Physiological
            hrv: todayWellness?.hrv,
            hrvBaseline: hrvBaseline,
            hrvDelta: todayWellness?.hrv.map { ($0 - (hrvBaseline ?? $0)) / (hrvBaseline ?? $0) },
            hrvCoefficientOfVariation: calculateHRVCV(wellness: wellness, upToDate: date),
            rhr: effectiveRHR,
            rhrBaseline: rhrBaseline,
            rhrDelta: effectiveRHR.map { ($0 - (rhrBaseline ?? $0)) / (rhrBaseline ?? $0) },
            sleepDuration: todayWellness?.sleepDuration,
            sleepBaseline: sleepBaseline,
            sleepDelta: todayWellness?.sleepDuration.map { $0 - (sleepBaseline ?? $0) },
            respiratoryRate: todayWellness?.respiratoryRate,
            
            // Training load
            yesterdayStrain: nil, // TODO: Calculate strain
            yesterdayTSS: yesterdayTSS > 0 ? yesterdayTSS : nil,
            ctl: ctl,
            atl: atl,
            tsb: tsb != 0 ? tsb : nil,
            acuteChronicRatio: (atl != nil && ctl != nil && ctl! > 0) ? atl! / ctl! : nil,
            trainingMonotony: calculateMonotony(activities: activities, upToDate: date),
            trainingStrain: nil, // TODO: Calculate strain
            
            // Recovery trends
            recoveryTrend7d: nil, // TODO: Calculate from historical recovery scores
            recoveryTrend3d: nil,
            yesterdayRecovery: nil,
            recoveryChange: nil,
            
            // Sleep trends
            sleepTrend7d: calculateSleepTrend(wellness: wellness, upToDate: date, days: 7),
            sleepDebt7d: calculateSleepDebt(wellness: wellness, upToDate: date, days: 7),
            sleepQualityScore: nil, // TODO: Add sleep quality metric
            
            // Temporal
            dayOfWeek: Calendar.current.component(.weekday, from: date),
            daysSinceHardWorkout: daysSinceHardWorkout(activities: activities, upToDate: date),
            trainingBlockDay: nil, // TODO: Implement training block tracking
            
            // Contextual
            alcoholDetected: nil, // TODO: Detect HRV suppression patterns
            illnessMarker: detectIllnessMarker(wellness: todayWellness),
            monthOfYear: Calendar.current.component(.month, from: date),
            
            // Pattern-based features (will be filled in augmentation step)
            stravaPatternCTLTrend: nil,
            stravaPatternATLTrend: nil,
            stravaPatternTSBTrend: nil,
            stravaPatternIntensityTrend: nil,
            stravaPatternVolumeTrend: nil,
            
            // Metadata
            timestamp: date,
            primaryTrainingSource: determinePrimarySource(activities: todayActivities),
            hasStravaAugmentation: false // Will be set to true if patterns added
        )
    }
    
    /// Augment base features with pattern-based features from non-ingestible sources
    private func augmentWithPatterns(
        baseFeatures: MLFeatureVector,
        patterns: [MLPatternFeature],
        date: Date
    ) -> MLFeatureVector {
        
        var features = baseFeatures
        
        // Find pattern features for this date (or most recent)
        let relevantPatterns = patterns.filter {
            $0.calculationDate <= date
        }.sorted { $0.calculationDate > $1.calculationDate }
        
        // Add Strava patterns if available
        if let ctlPattern = relevantPatterns.first(where: { $0.type == .trainingLoadTrend }) {
            features = MLFeatureVector(
                hrv: features.hrv,
                hrvBaseline: features.hrvBaseline,
                hrvDelta: features.hrvDelta,
                hrvCoefficientOfVariation: features.hrvCoefficientOfVariation,
                rhr: features.rhr,
                rhrBaseline: features.rhrBaseline,
                rhrDelta: features.rhrDelta,
                sleepDuration: features.sleepDuration,
                sleepBaseline: features.sleepBaseline,
                sleepDelta: features.sleepDelta,
                respiratoryRate: features.respiratoryRate,
                yesterdayStrain: features.yesterdayStrain,
                yesterdayTSS: features.yesterdayTSS,
                ctl: features.ctl,
                atl: features.atl,
                tsb: features.tsb,
                acuteChronicRatio: features.acuteChronicRatio,
                trainingMonotony: features.trainingMonotony,
                trainingStrain: features.trainingStrain,
                recoveryTrend7d: features.recoveryTrend7d,
                recoveryTrend3d: features.recoveryTrend3d,
                yesterdayRecovery: features.yesterdayRecovery,
                recoveryChange: features.recoveryChange,
                sleepTrend7d: features.sleepTrend7d,
                sleepDebt7d: features.sleepDebt7d,
                sleepQualityScore: features.sleepQualityScore,
                dayOfWeek: features.dayOfWeek,
                daysSinceHardWorkout: features.daysSinceHardWorkout,
                trainingBlockDay: features.trainingBlockDay,
                alcoholDetected: features.alcoholDetected,
                illnessMarker: features.illnessMarker,
                monthOfYear: features.monthOfYear,
                stravaPatternCTLTrend: ctlPattern.value,
                stravaPatternATLTrend: relevantPatterns.first(where: { $0.type == .acuteLoadTrend })?.value,
                stravaPatternTSBTrend: relevantPatterns.first(where: { $0.type == .stressBalanceTrend })?.value,
                stravaPatternIntensityTrend: relevantPatterns.first(where: { $0.type == .intensityTrend })?.value,
                stravaPatternVolumeTrend: relevantPatterns.first(where: { $0.type == .volumeTrend })?.value,
                timestamp: features.timestamp,
                primaryTrainingSource: features.primaryTrainingSource,
                hasStravaAugmentation: true
            )
            
            Logger.debug("📈 [HybridML] Augmented \(date) with Strava patterns")
        }
        
        return features
    }
    
    // MARK: - Helper Calculations
    
    private func calculateCTL(activities: [UnifiedActivity], upToDate: Date) -> Double? {
        let relevantActivities = activities.filter { $0.startDate <= upToDate }
        guard relevantActivities.count >= 7 else { return nil }
        
        // 42-day exponentially weighted average
        let decay = 0.976
        var ctl: Double = 0
        
        for activity in relevantActivities.sorted(by: { $0.startDate < $1.startDate }) {
            if let tss = activity.tss {
                ctl = ctl * decay + tss * (1 - decay)
            }
        }
        
        return ctl > 0 ? ctl : nil
    }
    
    private func calculateATL(activities: [UnifiedActivity], upToDate: Date) -> Double? {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: upToDate)!
        let recentActivities = activities.filter {
            $0.startDate >= sevenDaysAgo && $0.startDate <= upToDate
        }
        
        let tssValues = recentActivities.compactMap { $0.tss }
        guard !tssValues.isEmpty else { return nil }
        
        return tssValues.reduce(0, +) / 7.0
    }
    
    private func calculateHRVBaseline(wellness: [WellnessData], upToDate: Date) -> Double? {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: upToDate)!
        let recentWellness = wellness.filter {
            $0.date >= thirtyDaysAgo && $0.date <= upToDate
        }
        
        let hrvValues = recentWellness.compactMap { $0.hrv }
        guard !hrvValues.isEmpty else { return nil }
        
        return hrvValues.reduce(0, +) / Double(hrvValues.count)
    }
    
    private func calculateRHRBaseline(wellness: [WellnessData], upToDate: Date) -> Double? {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: upToDate)!
        let recentWellness = wellness.filter {
            $0.date >= thirtyDaysAgo && $0.date <= upToDate
        }
        
        let rhrValues = recentWellness.compactMap { $0.rhr }
        guard !rhrValues.isEmpty else { return nil }
        
        return rhrValues.reduce(0, +) / Double(rhrValues.count)
    }
    
    private func calculateSleepBaseline(wellness: [WellnessData], upToDate: Date) -> Double? {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: upToDate)!
        let recentWellness = wellness.filter {
            $0.date >= thirtyDaysAgo && $0.date <= upToDate
        }
        
        let sleepValues = recentWellness.compactMap { $0.sleepDuration }
        guard !sleepValues.isEmpty else { return nil }
        
        return sleepValues.reduce(0, +) / Double(sleepValues.count)
    }
    
    private func calculateHRVCV(wellness: [WellnessData], upToDate: Date) -> Double? {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: upToDate)!
        let recentWellness = wellness.filter {
            $0.date >= sevenDaysAgo && $0.date <= upToDate
        }
        
        let hrvValues = recentWellness.compactMap { $0.hrv }
        guard hrvValues.count >= 3 else { return nil }
        
        let mean = hrvValues.reduce(0, +) / Double(hrvValues.count)
        let variance = hrvValues.map { pow($0 - mean, 2) }.reduce(0, +) / Double(hrvValues.count)
        let stdDev = sqrt(variance)
        
        return (stdDev / mean) * 100
    }
    
    private func calculateSleepTrend(wellness: [WellnessData], upToDate: Date, days: Int) -> Double? {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: upToDate)!
        let recentWellness = wellness.filter {
            $0.date >= startDate && $0.date <= upToDate
        }
        
        let sleepValues = recentWellness.compactMap { $0.sleepDuration }
        guard !sleepValues.isEmpty else { return nil }
        
        return sleepValues.reduce(0, +) / Double(sleepValues.count)
    }
    
    private func calculateSleepDebt(wellness: [WellnessData], upToDate: Date, days: Int) -> Double? {
        let baseline = calculateSleepBaseline(wellness: wellness, upToDate: upToDate)
        guard let baseline = baseline else { return nil }
        
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: upToDate)!
        let recentWellness = wellness.filter {
            $0.date >= startDate && $0.date <= upToDate
        }
        
        let debt = recentWellness.compactMap { wellness -> Double? in
            guard let sleep = wellness.sleepDuration else { return nil }
            return max(0, baseline - sleep)
        }.reduce(0, +)
        
        return debt
    }
    
    private func calculateMonotony(activities: [UnifiedActivity], upToDate: Date) -> Double? {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: upToDate)!
        let recentActivities = activities.filter {
            $0.startDate >= sevenDaysAgo && $0.startDate <= upToDate
        }
        
        let tssValues = recentActivities.compactMap { $0.tss }
        guard tssValues.count >= 3 else { return nil }
        
        let mean = tssValues.reduce(0, +) / Double(tssValues.count)
        let variance = tssValues.map { pow($0 - mean, 2) }.reduce(0, +) / Double(tssValues.count)
        let stdDev = sqrt(variance)
        
        guard stdDev > 0 else { return nil }
        return mean / stdDev
    }
    
    private func daysSinceHardWorkout(activities: [UnifiedActivity], upToDate: Date) -> Int? {
        let hardWorkouts = activities.filter { ($0.tss ?? 0) > 100 && $0.startDate <= upToDate }
        guard let lastHard = hardWorkouts.max(by: { $0.startDate < $1.startDate }) else {
            return nil
        }
        
        let days = Calendar.current.dateComponents([.day], from: lastHard.startDate, to: upToDate).day
        return days
    }
    
    private func detectIllnessMarker(wellness: WellnessData?) -> Bool? {
        guard let wellness = wellness,
              let hrv = wellness.hrv,
              let rhr = wellness.rhr else {
            return nil
        }
        
        // Simple heuristic: HRV drop + RHR spike might indicate illness
        // This would need more sophisticated logic in production
        return hrv < 40 && rhr > 70
    }
    
    private func determinePrimarySource(activities: [UnifiedActivity]) -> DataSource? {
        guard let firstActivity = activities.first else { return nil }
        
        switch firstActivity.source {
        case .intervalsICU:
            return .intervalsICU
        case .strava:
            return .strava
        case .appleHealth:
            return .appleHealth
        }
    }
    
    private func calculateRecoveryScore(from wellness: WellnessData?) -> Double? {
        guard let wellness = wellness else { return nil }
        
        // Use actual recovery score from DailyScores if available
        if let recoveryScore = wellness.recoveryScore, recoveryScore > 0 {
            return recoveryScore
        }
        
        // Fallback: Simplified recovery score calculation if no actual score
        // This should rarely be used now that we fetch from DailyScores
        var score: Double = 50 // Base score
        
        if let hrv = wellness.hrv {
            score += min(30, (hrv - 50) / 2) // HRV contribution
        }
        
        if let rhr = wellness.rhr {
            score += min(20, (70 - rhr) / 2) // RHR contribution
        }
        
        return max(0, min(100, score))
    }
    
    private func calculateReadinessScore(from wellness: WellnessData?) -> Double? {
        // Similar to recovery but might include different weights
        return calculateRecoveryScore(from: wellness)
    }
}

