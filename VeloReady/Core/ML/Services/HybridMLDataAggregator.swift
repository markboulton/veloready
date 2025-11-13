import Foundation

/// Aggregates ML training data with hybrid approach:
/// - Primary training data: HealthKit + ingestible sources (Intervals, Wahoo, Garmin)
/// - Augmentation data: Strava patterns (not raw data)
///
/// This architecture ensures API compliance while maximizing ML capabilities
@MainActor
class HybridMLDataAggregator {
    
    // MARK: - Dependencies
    
    private let healthKitManager: HealthKitManager
    
    // MARK: - Initialization
    
    init(
        healthKitManager: HealthKitManager = .shared
    ) {
        self.healthKitManager = healthKitManager
    }
    
    // MARK: - Public API
    
    /// Aggregate training data for ML with hybrid approach
    /// - Parameter days: Number of days to look back (default: 90)
    /// - Returns: Hybrid dataset combining ingestible data + pattern augmentations
    func aggregateTrainingData(days: Int = 90) async -> HybridMLDataset {
        Logger.info("🔄 [HybridML] Starting hybrid data aggregation for \(days) days...")
        
        // Step 1: Get ingestible training data (from compliant sources)
        Logger.debug("📊 [HybridML] Step 1: Fetching ingestible activities...")
        let ingestibleActivities = await fetchIngestibleActivities(days: days)
        Logger.debug("✅ [HybridML] Fetched \(ingestibleActivities.count) ingestible activities")
        
        // Step 2: Get wellness data (always from HealthKit)
        Logger.debug("💤 [HybridML] Step 2: Fetching wellness data...")
        let wellnessData = await fetchWellnessData(days: days)
        Logger.debug("✅ [HybridML] Fetched \(wellnessData.count) wellness data points")
        
        // Step 3: Get pattern features from non-ingestible sources (Strava)
        Logger.debug("📈 [HybridML] Step 3: Extracting pattern features...")
        let patternFeatures = await fetchPatternFeatures(days: days)
        Logger.debug("✅ [HybridML] Extracted \(patternFeatures.count) pattern features")
        
        // Step 4: Log data source breakdown
        let sourceBreakdown = getDataSourceBreakdown(
            activities: ingestibleActivities,
            wellness: wellnessData,
            patterns: patternFeatures
        )
        Logger.info("📊 [HybridML] Data source breakdown:")
        for (source, count) in sourceBreakdown {
            Logger.info("   - \(source): \(count) data points")
        }
        
        // Step 5: Combine into hybrid dataset
        let dataset = HybridMLDataset(
            trainingActivities: ingestibleActivities,
            wellnessData: wellnessData,
            patternAugmentations: patternFeatures,
            startDate: Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date(),
            endDate: Date()
        )
        
        Logger.info("✅ [HybridML] Hybrid data aggregation complete")
        Logger.info("   - Training activities: \(dataset.trainingActivities.count)")
        Logger.info("   - Wellness data points: \(dataset.wellnessData.count)")
        Logger.info("   - Pattern augmentations: \(dataset.patternAugmentations.count)")
        
        return dataset
    }
    
    // MARK: - Private Fetching Methods
    
    /// Fetch activities from ML-ingestible sources only
    private func fetchIngestibleActivities(days: Int) async -> [UnifiedActivity] {
        // For now, fetch from HealthKit workouts only
        // TODO: Add Intervals.icu activities when they become available
        let healthKitWorkouts = await healthKitManager.fetchRecentWorkouts(limit: 200, daysBack: days)
        
        // Convert to UnifiedActivity
        let activities = healthKitWorkouts.map { UnifiedActivity(from: $0) }
        
        Logger.debug("🔍 [HybridML] Fetched \(activities.count) ingestible activities from HealthKit")
        
        return activities
    }
    
    /// Fetch wellness data (ALWAYS from HealthKit - on-device, user-owned)
    private func fetchWellnessData(days: Int) async -> [WellnessData] {
        var wellnessDataPoints: [WellnessData] = []
        
        // Calculate date range
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        // Fetch HRV samples
        let hrvSamples = await healthKitManager.fetchHRVSamples(from: startDate, to: endDate)
        
        // Fetch RHR samples
        let rhrSamples = await healthKitManager.fetchRHRSamples(from: startDate, to: endDate)
        
        // Fetch sleep sessions
        let sleepSessions = await healthKitManager.fetchSleepSessions(from: startDate, to: endDate)
        
        // Group by date
        var dataByDate: [Date: WellnessData] = [:]
        
        // Add HRV
        for sample in hrvSamples {
            let date = Calendar.current.startOfDay(for: sample.startDate)
            var data = dataByDate[date] ?? WellnessData(
                source: .appleHealth,
                date: date,
                hrv: nil,
                rhr: nil,
                sleepDuration: nil,
                respiratoryRate: nil,
                recoveryScore: nil
            )
            data = WellnessData(
                source: data.source,
                date: data.date,
                hrv: sample.quantity.doubleValue(for: .secondUnit(with: .milli)),
                rhr: data.rhr,
                sleepDuration: data.sleepDuration,
                respiratoryRate: data.respiratoryRate,
                recoveryScore: data.recoveryScore
            )
            dataByDate[date] = data
        }
        
        // Add RHR
        for sample in rhrSamples {
            let date = Calendar.current.startOfDay(for: sample.startDate)
            var data = dataByDate[date] ?? WellnessData(
                source: .appleHealth,
                date: date,
                hrv: nil,
                rhr: nil,
                sleepDuration: nil,
                respiratoryRate: nil,
                recoveryScore: nil
            )
            data = WellnessData(
                source: data.source,
                date: data.date,
                hrv: data.hrv,
                rhr: sample.quantity.doubleValue(for: .hertz()) * 60, // Convert to BPM
                sleepDuration: data.sleepDuration,
                respiratoryRate: data.respiratoryRate,
                recoveryScore: data.recoveryScore
            )
            dataByDate[date] = data
        }
        
        // Add sleep
        for session in sleepSessions {
            let date = Calendar.current.startOfDay(for: session.bedtime)
            var data = dataByDate[date] ?? WellnessData(
                source: .appleHealth,
                date: date,
                hrv: nil,
                rhr: nil,
                sleepDuration: nil,
                respiratoryRate: nil,
                recoveryScore: nil
            )
            let duration = session.wakeTime.timeIntervalSince(session.bedtime) / 3600 // Hours
            data = WellnessData(
                source: data.source,
                date: data.date,
                hrv: data.hrv,
                rhr: data.rhr,
                sleepDuration: duration,
                respiratoryRate: data.respiratoryRate,
                recoveryScore: data.recoveryScore
            )
            dataByDate[date] = data
        }
        
        // Add recovery scores from DailyScores Core Data
        let persistence = PersistenceController.shared
        let dailyScoresRequest = DailyScores.fetchRequest()
        dailyScoresRequest.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@ AND recoveryScore > 0",
            startDate as NSDate,
            endDate as NSDate
        )
        
        let dailyScores = persistence.fetch(dailyScoresRequest)
        for score in dailyScores {
            guard let scoreDate = score.date else { continue }
            let date = Calendar.current.startOfDay(for: scoreDate)
            
            if var existingData = dataByDate[date] {
                // Update existing wellness data with recovery score
                // Use the normalized date to ensure consistency
                existingData = WellnessData(
                    source: existingData.source,
                    date: date,  // Use normalized startOfDay date
                    hrv: existingData.hrv,
                    rhr: existingData.rhr,
                    sleepDuration: existingData.sleepDuration,
                    respiratoryRate: existingData.respiratoryRate,
                    recoveryScore: score.recoveryScore
                )
                dataByDate[date] = existingData
            } else {
                // Create new wellness data with just recovery score
                let newData = WellnessData(
                    source: .appleHealth,
                    date: date,
                    hrv: nil,
                    rhr: nil,
                    sleepDuration: nil,
                    respiratoryRate: nil,
                    recoveryScore: score.recoveryScore
                )
                dataByDate[date] = newData
            }
        }
        
        wellnessDataPoints = Array(dataByDate.values).sorted { $0.date < $1.date }
        
        Logger.debug("💤 [HybridML] Aggregated wellness data for \(wellnessDataPoints.count) days")
        Logger.debug("   - \(dailyScores.count) DailyScores fetched from Core Data")
        let daysWithRecovery = wellnessDataPoints.filter { $0.recoveryScore != nil && $0.recoveryScore! > 0 }
        Logger.debug("   - \(daysWithRecovery.count) wellness days have recovery scores populated")
        
        // Debug: Show dates with recovery scores
        for (index, wellness) in daysWithRecovery.enumerated() {
            if index < 5 {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                Logger.debug("      [\(index)]: \(formatter.string(from: wellness.date)) recovery=\(wellness.recoveryScore!)")
            }
        }
        
        return wellnessDataPoints
    }
    
    /// Fetch pattern features from non-ingestible sources (e.g., Strava)
    private func fetchPatternFeatures(days: Int) async -> [MLPatternFeature] {
        var allFeatures: [MLPatternFeature] = []
        
        // TODO: Implement Strava pattern extraction
        // For now, return empty array - patterns will be added when Strava integration is active
        // This requires fetching Strava activities and extracting aggregate metrics
        
        Logger.debug("📈 [HybridML] Pattern extraction not yet implemented - skipping")
        
        return allFeatures
    }
    
    /// Get breakdown of data sources for logging
    private func getDataSourceBreakdown(
        activities: [UnifiedActivity],
        wellness: [WellnessData],
        patterns: [MLPatternFeature]
    ) -> [String: Int] {
        var breakdown: [String: Int] = [:]
        
        // Count activities by source
        for activity in activities {
            let source = activity.source.displayName
            breakdown[source, default: 0] += 1
        }
        
        // Count wellness data
        breakdown["HealthKit (Wellness)"] = wellness.count
        
        // Count pattern features
        for pattern in patterns {
            let key = "\(pattern.source.displayName) (Patterns)"
            breakdown[key, default: 0] += 1
        }
        
        return breakdown
    }
}

// MARK: - Hybrid ML Dataset

/// Combined dataset with ingestible data + pattern augmentations
struct HybridMLDataset {
    /// Activities from ML-ingestible sources (Intervals, HealthKit, Wahoo, Garmin)
    let trainingActivities: [UnifiedActivity]
    
    /// Wellness data (always from HealthKit)
    let wellnessData: [WellnessData]
    
    /// Pattern-based features from non-ingestible sources (Strava)
    let patternAugmentations: [MLPatternFeature]
    
    /// Date range
    let startDate: Date
    let endDate: Date
    
    /// Get all unique dates in the dataset
    var dates: [Date] {
        var allDates = Set<Date>()
        
        // Add activity dates
        for activity in trainingActivities {
            let date = Calendar.current.startOfDay(for: activity.startDate)
            allDates.insert(date)
        }
        
        // Add wellness dates
        for wellness in wellnessData {
            allDates.insert(wellness.date)
        }
        
        return allDates.sorted()
    }
    
    /// Check if dataset has sufficient data for ML training
    var hasSufficientData: Bool {
        return trainingActivities.count >= 30 && wellnessData.count >= 60
    }
    
    /// Get data quality report
    var qualityReport: String {
        let activityDays = Set(trainingActivities.map { Calendar.current.startOfDay(for: $0.startDate) }).count
        let wellnessDays = wellnessData.count
        let patternCount = patternAugmentations.count
        
        return """
        Hybrid ML Dataset Quality:
        - Activity Days: \(activityDays) (from ingestible sources)
        - Wellness Days: \(wellnessDays) (HealthKit)
        - Pattern Features: \(patternCount) (Strava)
        - Sufficient: \(hasSufficientData ? "✅ Yes" : "❌ No - need more data")
        """
    }
}

