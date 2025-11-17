import Foundation
import CoreData

/// Main service for ML training data management
/// Orchestrates data aggregation, feature engineering, and storage
@MainActor
class MLTrainingDataService: ObservableObject {
    
    static let shared = MLTrainingDataService()
    
    // MARK: - Dependencies
    
    private let historicalAggregator = HistoricalDataAggregator()
    private let hybridAggregator = HybridMLDataAggregator()
    private let featureEngineer = FeatureEngineer()
    private let hybridFeatureEngineer = HybridFeatureEngineer()
    private let modelRegistry = MLModelRegistry.shared
    private let persistence = PersistenceController.shared
    
    // MARK: - Configuration
    
    /// Use hybrid ML approach (ingestible sources + pattern augmentation)
    /// Set to false to use legacy approach (requires updating FeatureEngineer for new fields)
    private let useHybridApproach = true
    
    // MARK: - Published State
    
    @Published var isProcessing = false
    var lastProcessingDate: Date?
    @Published var trainingDataCount: Int = 0
    @Published var dataQualityScore: Double = 0.0
    
    // MARK: - User Defaults Keys
    
    private let lastProcessingDateKey = "ml_last_processing_date"
    private let trainingDataCountKey = "ml_training_data_count"
    
    // MARK: - Initialization
    
    private init() {
        loadState()
        
        // Auto-process historical data on first launch if we have no data
        Task {
            await autoProcessIfNeeded()
        }
    }
    
    /// Automatically process historical data if we have none or if it's a new day
    private func autoProcessIfNeeded() async {
        // Check if we need to process
        let shouldProcess: Bool
        
        if trainingDataCount == 0 && lastProcessingDate == nil {
            // First time - no data at all
            Logger.info("🚀 [ML] No training data found - auto-processing historical data...")
            shouldProcess = true
        } else if let lastDate = lastProcessingDate {
            // Check if it's a new day since last processing
            let calendar = Calendar.current
            if !calendar.isDate(lastDate, inSameDayAs: Date()) {
                Logger.info("🔄 [ML] New day detected - updating training data...")
                shouldProcess = true
            } else {
                // Even if processed today, refresh the count from Core Data to ensure accuracy
                Logger.debug("📊 [ML] Training data already processed today - refreshing count from Core Data...")
                await refreshTrainingDataCount()
                
                // Check if we have new DailyScores in Core Data that might create more valid training data
                // This handles the case where scores were calculated after ML processing ran
                let hasNewScores = await checkForNewDailyScores(since: lastDate)
                if hasNewScores {
                    Logger.info("🔄 [ML] New recovery scores detected since last processing - reprocessing...")
                    shouldProcess = true
                } else {
                    shouldProcess = false
                }
            }
        } else {
            shouldProcess = false
        }
        
        if shouldProcess {
            await processHistoricalData(days: 90)
        }
    }
    
    /// Check if new DailyScores have been created since the last processing date
    /// This helps detect when recovery scores are calculated after ML processing has already run
    private func checkForNewDailyScores(since date: Date) async -> Bool {
        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(
            format: "lastUpdated > %@ AND recoveryScore > 0",
            date as NSDate
        )
        
        let newScores = persistence.fetch(request)
        if !newScores.isEmpty {
            Logger.debug("📊 [ML] Found \(newScores.count) DailyScores updated since last ML processing")
            return true
        }
        return false
    }
    
    // MARK: - Public API
    
    /// Process historical data and generate training dataset
    /// This is the main entry point for Phase 1
    /// - Parameter days: Number of days to look back (default: 180, allows 30-day baselines for 150 days of training data)
    func processHistoricalData(days: Int = 180) async {
        guard !isProcessing else {
            Logger.warning("[ML] Already processing historical data")
            return
        }
        
        isProcessing = true
        Logger.debug("🚀 [ML] Starting historical data processing for \(days) days...")
        Logger.debug("🔧 [ML] Using \(useHybridApproach ? "HYBRID" : "LEGACY") approach")
        
        do {
            let dataset: MLTrainingDataset
            
            if useHybridApproach {
                // NEW: Hybrid approach with API compliance
                // Step 1: Aggregate hybrid data (ingestible + patterns)
                let hybridData = await hybridAggregator.aggregateTrainingData(days: days)
                Logger.debug("📊 [ML] Step 1 complete: Aggregated hybrid data")
                Logger.debug("   - Training activities: \(hybridData.trainingActivities.count)")
                Logger.debug("   - Wellness data: \(hybridData.wellnessData.count)")
                Logger.debug("   - Pattern features: \(hybridData.patternAugmentations.count)")
                
                // 🔒 CRITICAL: Runtime assertion to prevent API violations
                let hasStravaRawData = hybridData.trainingActivities.contains { $0.source == .strava }
                assert(!hasStravaRawData, """
                    ❌ CRITICAL API VIOLATION:
                    Strava raw data detected in ML training set!
                    This violates Strava's API terms of service.
                    Only pattern-based features should be used from Strava.
                    """)
                
                // Step 2: Extract features with hybrid approach
                dataset = await hybridFeatureEngineer.extractFeatures(from: hybridData)
                Logger.debug("🔧 [ML] Step 2 complete: Extracted \(dataset.dataPoints.count) training samples")
                
            } else {
                // LEGACY: Original approach (kept for backwards compatibility)
                let historicalData = await historicalAggregator.aggregateHistoricalData(days: days)
                Logger.debug("📊 [ML] Step 1 complete: Aggregated \(historicalData.count) days of data")
                
                dataset = await featureEngineer.extractFeatures(from: historicalData)
                Logger.debug("🔧 [ML] Step 2 complete: Extracted \(dataset.dataPoints.count) training samples")
            }
            
            // Step 3: Store to Core Data
            try await storeTrainingData(dataset: dataset)
            Logger.debug("💾 [ML] Step 3 complete: Stored training data to Core Data")
            
            // Step 4: Update state
            trainingDataCount = dataset.validDays
            dataQualityScore = dataset.completeness
            lastProcessingDate = Date()
            saveState()
            
            Logger.debug("✅ [ML] Historical data processing complete!")
            Logger.debug("📈 [ML] Stats: \(trainingDataCount) valid days, \(String(format: "%.1f%%", dataQualityScore * 100)) completeness")
            
        } catch {
            Logger.error("[ML] Failed to process historical data: \(error)")
        }
        
        isProcessing = false
    }
    
    /// Get training dataset from Core Data
    /// - Parameter days: Number of days to fetch (default: 180)
    /// - Returns: ML training dataset ready for model training
    func getTrainingDataset(days: Int = 180) async -> MLTrainingDataset? {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return nil
        }
        
        let request = MLTrainingData.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND isValidTrainingData == YES",
            startDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        let trainingRecords = persistence.fetch(request)
        Logger.debug("📊 [ML] Fetched \(trainingRecords.count) training records from Core Data")
        
        guard !trainingRecords.isEmpty else { return nil }
        
        // Convert Core Data records to training data points
        let dataPoints = trainingRecords.compactMap { record -> MLTrainingDataPoint? in
            guard let date = record.date,
                  let featureVector = record.featureVector else { return nil }
            
            // Reconstruct feature vector using the fromDictionary method
            let features: MLFeatureVector
            do {
                features = try MLFeatureVector.fromDictionary(featureVector)
            } catch {
                Logger.error("[ML] Failed to reconstruct feature vector: \(error)")
                return nil
            }
            
            return MLTrainingDataPoint(
                features: features,
                targetRecovery: record.targetRecoveryScore,
                targetReadiness: record.targetReadinessScore,
                dataQuality: record.dataQualityScore
            )
        }
        
        return MLTrainingDataset(
            dataPoints: dataPoints,
            startDate: trainingRecords.first?.date ?? Date(),
            endDate: trainingRecords.last?.date ?? Date(),
            totalDays: trainingRecords.count,
            validDays: dataPoints.count
        )
    }
    
    /// Check if user has sufficient data for ML training
    func hasSufficientDataForTraining(minimumDays: Int = 30) async -> Bool {
        let dataset = await getTrainingDataset(days: 90)
        let validDays = dataset?.validDays ?? 0
        Logger.debug("📊 [ML] Sufficient data check: \(validDays) valid days (minimum: \(minimumDays))")
        return validDays >= minimumDays
    }
    
    /// Clear all existing ML training data from Core Data
    func clearTrainingData() async {
        Logger.info("🗑️ [ML] Clearing all training data from Core Data...")
        
        let request = MLTrainingData.fetchRequest()
        let records = persistence.fetch(request)
        
        for record in records {
            persistence.delete(record)
        }
        
        Logger.info("✅ [ML] Cleared \(records.count) training records")
        await refreshTrainingDataCount()
    }
    
    /// Force reprocess of training data (useful after new scores are calculated)
    /// This will clear existing data and regenerate with current validation rules
    func reprocessTrainingData() async {
        Logger.info("🔄 [ML] Manual reprocess requested - clearing old data and regenerating...")
        await clearTrainingData()
        // Use 180 days to ensure we have enough history for 30-day baselines on all dates
        await processHistoricalData(days: 180)
    }
    
    /// Refresh training data count from Core Data
    /// Useful for updating UI when data is processed in background
    func refreshTrainingDataCount() async {
        // Query Core Data directly for accurate count
        let request = MLTrainingData.fetchRequest()
        request.predicate = NSPredicate(format: "isValidTrainingData == YES")
        
        let records = persistence.fetch(request)
        let count = records.count
        Logger.debug("📊 [ML] Refreshed training data count from Core Data: \(count) valid days")
        
        // Also log how many TOTAL days we have (including invalid ones) for debugging
        let totalRequest = MLTrainingData.fetchRequest()
        let totalRecords = persistence.fetch(totalRequest)
        Logger.debug("📊 [ML] Total training records in Core Data: \(totalRecords.count) (valid: \(count))")
        
        // Log why records are invalid if we have a significant mismatch
        if totalRecords.count > count + 2 {
            Logger.debug("⚠️ [ML] \(totalRecords.count - count) records are invalid")
            Logger.debug("   Valid records need: dataQuality ≥ 0.15 (≥5 features), HRV, RHR, AND targetRecovery > 0")
            Logger.debug("   (Sleep data is optional - not all users wear watches to bed)")
            Logger.debug("   Tip: Training data requires consecutive days with recovery scores to predict tomorrow's score")
        }
        
        trainingDataCount = count
        saveState()
        
        // Also update quality score if we have data
        if count > 0 {
            let dataset = await getTrainingDataset(days: 90)
            if let dataset = dataset {
                dataQualityScore = dataset.completeness
                saveState()
            }
        }
    }
    
    /// Get data quality report
    func getDataQualityReport() async -> MLDataQualityReport {
        let dataset = await getTrainingDataset(days: 90)
        
        guard let dataset = dataset else {
            return MLDataQualityReport(
                totalDays: 0,
                validDays: 0,
                completeness: 0.0,
                hasSufficientData: false,
                missingFeatures: []
            )
        }
        
        // Analyze missing features
        var featureCompleteness: [String: Int] = [:]
        for dataPoint in dataset.dataPoints {
            let features = dataPoint.features.toDictionary()
            for (key, _) in features {
                featureCompleteness[key, default: 0] += 1
            }
        }
        
        let totalPoints = dataset.dataPoints.count
        let missingFeatures = featureCompleteness
            .filter { Double($0.value) / Double(totalPoints) < 0.8 }
            .map { $0.key }
            .sorted()
        
        return MLDataQualityReport(
            totalDays: dataset.totalDays,
            validDays: dataset.validDays,
            completeness: dataset.completeness,
            hasSufficientData: dataset.validDays >= 30,
            missingFeatures: missingFeatures
        )
    }
    
    // MARK: - Storage
    
    private func storeTrainingData(dataset: MLTrainingDataset) async throws {
        let context = persistence.newBackgroundContext()
        
        try await context.perform {
            // Clear existing training data first
            let deleteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MLTrainingData")
            let deleteOp = NSBatchDeleteRequest(fetchRequest: deleteRequest)
            try? context.execute(deleteOp)
            
            // Store new training data
            for dataPoint in dataset.dataPoints {
                let record = MLTrainingData(context: context)
                record.id = UUID()
                record.date = dataPoint.features.timestamp
                record.setFeatureVector(dataPoint.features.toDictionary())
                record.targetRecoveryScore = dataPoint.targetRecovery
                record.targetReadinessScore = dataPoint.targetReadiness
                record.actualRecoveryScore = 0 // Will be filled in later
                record.actualReadinessScore = 0
                record.predictionError = 0
                record.predictionConfidence = 0
                record.modelVersion = "none" // No model trained yet
                record.trainingPhase = "baseline"
                record.dataQualityScore = dataPoint.dataQuality
                record.isValidTrainingData = dataPoint.isValidForTraining
                record.createdAt = Date()
                record.lastUpdated = Date()
            }
            
            try context.save()
            Logger.debug("💾 [ML] Stored \(dataset.dataPoints.count) training records to Core Data")
        }
    }
    
    // MARK: - State Management
    
    private func loadState() {
        if let lastDate = UserDefaults.standard.object(forKey: lastProcessingDateKey) as? Date {
            lastProcessingDate = lastDate
        }
        trainingDataCount = UserDefaults.standard.integer(forKey: trainingDataCountKey)
    }
    
    private func saveState() {
        if let lastDate = lastProcessingDate {
            UserDefaults.standard.set(lastDate, forKey: lastProcessingDateKey)
        }
        UserDefaults.standard.set(trainingDataCount, forKey: trainingDataCountKey)
    }
}

// MARK: - Data Quality Report

struct MLDataQualityReport {
    let totalDays: Int
    let validDays: Int
    let completeness: Double
    let hasSufficientData: Bool
    let missingFeatures: [String]
    
    var completenessPercentage: String {
        String(format: "%.1f%%", completeness * 100)
    }
}
