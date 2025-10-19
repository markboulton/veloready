import Foundation
import CoreData

/// Main service for ML training data management
/// Orchestrates data aggregation, feature engineering, and storage
@MainActor
class MLTrainingDataService: ObservableObject {
    
    static let shared = MLTrainingDataService()
    
    // MARK: - Dependencies
    
    private let historicalAggregator = HistoricalDataAggregator()
    private let featureEngineer = FeatureEngineer()
    private let modelRegistry = MLModelRegistry.shared
    private let persistence = PersistenceController.shared
    
    // MARK: - Published State
    
    @Published var isProcessing = false
    @Published var lastProcessingDate: Date?
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
    
    /// Automatically process historical data if we have none
    private func autoProcessIfNeeded() async {
        // Only run if we have no training data and haven't processed before
        guard trainingDataCount == 0, lastProcessingDate == nil else {
            Logger.debug("📊 [ML] Training data already exists (\(trainingDataCount) days), skipping auto-process")
            return
        }
        
        Logger.info("🚀 [ML] No training data found - auto-processing historical data...")
        await processHistoricalData(days: 90)
    }
    
    // MARK: - Public API
    
    /// Process historical data and generate training dataset
    /// This is the main entry point for Phase 1
    /// - Parameter days: Number of days to look back (default: 90)
    func processHistoricalData(days: Int = 90) async {
        guard !isProcessing else {
            Logger.warning("[ML] Already processing historical data")
            return
        }
        
        isProcessing = true
        Logger.debug("🚀 [ML] Starting historical data processing for \(days) days...")
        
        do {
            // Step 1: Aggregate historical data from all sources
            let historicalData = await historicalAggregator.aggregateHistoricalData(days: days)
            Logger.debug("📊 [ML] Step 1 complete: Aggregated \(historicalData.count) days of data")
            
            // Step 2: Extract features
            let dataset = await featureEngineer.extractFeatures(from: historicalData)
            Logger.debug("🔧 [ML] Step 2 complete: Extracted \(dataset.dataPoints.count) training samples")
            
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
    /// - Parameter days: Number of days to fetch (default: 90)
    /// - Returns: ML training dataset ready for model training
    func getTrainingDataset(days: Int = 90) async -> MLTrainingDataset? {
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
            
            // Reconstruct feature vector
            let features = MLFeatureVector(
                hrv: featureVector["hrv"],
                hrvBaseline: featureVector["hrv_baseline"],
                hrvDelta: featureVector["hrv_delta"],
                hrvCoefficientOfVariation: featureVector["hrv_cv"],
                rhr: featureVector["rhr"],
                rhrBaseline: featureVector["rhr_baseline"],
                rhrDelta: featureVector["rhr_delta"],
                sleepDuration: featureVector["sleep_duration"],
                sleepBaseline: featureVector["sleep_baseline"],
                sleepDelta: featureVector["sleep_delta"],
                respiratoryRate: featureVector["respiratory_rate"],
                yesterdayStrain: featureVector["yesterday_strain"],
                yesterdayTSS: featureVector["yesterday_tss"],
                ctl: featureVector["ctl"],
                atl: featureVector["atl"],
                tsb: featureVector["tsb"],
                acuteChronicRatio: featureVector["acute_chronic_ratio"],
                trainingMonotony: featureVector["training_monotony"],
                trainingStrain: featureVector["training_strain"],
                recoveryTrend7d: featureVector["recovery_trend_7d"],
                recoveryTrend3d: featureVector["recovery_trend_3d"],
                yesterdayRecovery: featureVector["yesterday_recovery"],
                recoveryChange: featureVector["recovery_change"],
                sleepTrend7d: featureVector["sleep_trend_7d"],
                sleepDebt7d: featureVector["sleep_debt_7d"],
                sleepQualityScore: featureVector["sleep_quality"],
                dayOfWeek: Int(featureVector["day_of_week"] ?? 1),
                daysSinceHardWorkout: featureVector["days_since_hard_workout"].map(Int.init),
                trainingBlockDay: featureVector["training_block_day"].map(Int.init),
                alcoholDetected: featureVector["alcohol_detected"].map { $0 > 0 },
                illnessMarker: featureVector["illness_marker"].map { $0 > 0 },
                monthOfYear: Int(featureVector["month_of_year"] ?? 1),
                timestamp: date
            )
            
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
