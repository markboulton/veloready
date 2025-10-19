import Foundation
import CoreData

extension MLTrainingData {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MLTrainingData> {
        return NSFetchRequest<MLTrainingData>(entityName: "MLTrainingData")
    }
    
    // Core identifiers
    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    
    // Feature data (encoded as JSON)
    @NSManaged public var featureVectorData: Data?
    
    // Target values (what we're trying to predict)
    @NSManaged public var targetRecoveryScore: Double
    @NSManaged public var targetReadinessScore: Double
    
    // Actual values (for validation)
    @NSManaged public var actualRecoveryScore: Double
    @NSManaged public var actualReadinessScore: Double
    
    // Prediction quality tracking
    @NSManaged public var predictionError: Double
    @NSManaged public var predictionConfidence: Double
    
    // Model metadata
    @NSManaged public var modelVersion: String?
    @NSManaged public var trainingPhase: String? // "baseline", "weights", "lstm"
    
    // Quality flags
    @NSManaged public var dataQualityScore: Double // 0-1 (completeness of features)
    @NSManaged public var isValidTrainingData: Bool
    
    // Timestamps
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastUpdated: Date?
}

extension MLTrainingData: Identifiable {
    
}

// MARK: - Helper Methods

extension MLTrainingData {
    
    /// Decode feature vector from stored Data
    var featureVector: [String: Double]? {
        guard let data = featureVectorData else { return nil }
        return try? JSONDecoder().decode([String: Double].self, from: data)
    }
    
    /// Encode feature vector to Data
    func setFeatureVector(_ features: [String: Double]) {
        self.featureVectorData = try? JSONEncoder().encode(features)
    }
    
    /// Calculate completeness of feature data
    func calculateDataQuality() -> Double {
        guard let features = featureVector else { return 0.0 }
        
        let expectedFeatures = [
            "hrv", "hrv_baseline", "hrv_delta",
            "rhr", "rhr_baseline", "rhr_delta",
            "sleep_duration", "sleep_baseline", "sleep_delta",
            "yesterday_strain", "yesterday_tss",
            "ctl", "atl", "tsb",
            "day_of_week", "recovery_trend_7d"
        ]
        
        let presentFeatures = expectedFeatures.filter { features[$0] != nil }.count
        return Double(presentFeatures) / Double(expectedFeatures.count)
    }
}
