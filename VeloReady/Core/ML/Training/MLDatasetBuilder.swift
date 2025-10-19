import Foundation
import CoreData
import CreateML

/// Builds ML datasets from Core Data training data
/// Handles missing values, outlier removal, and train/test splitting
@MainActor
class MLDatasetBuilder {
    
    private let persistenceController = PersistenceController.shared
    
    // MARK: - Public API
    
    /// Build complete dataset from Core Data
    /// - Returns: MLDataTable ready for training
    func buildDataset() async throws -> MLDataTable {
        Logger.info("📊 [MLDatasetBuilder] Building dataset from Core Data...")
        
        // 1. Fetch all training data
        let trainingData = try await fetchTrainingData()
        Logger.info("📊 [MLDatasetBuilder] Fetched \(trainingData.count) training data points")
        
        guard !trainingData.isEmpty else {
            throw MLDatasetError.noData
        }
        
        // 2. Convert to data points
        let dataPoints = try convertToDataPoints(trainingData)
        Logger.info("📊 [MLDatasetBuilder] Converted to \(dataPoints.count) data points")
        
        // 3. Filter valid data points
        let validPoints = dataPoints.filter { $0.isValidForTraining }
        Logger.info("📊 [MLDatasetBuilder] Valid points: \(validPoints.count)/\(dataPoints.count)")
        
        guard validPoints.count >= 10 else {
            throw MLDatasetError.insufficientData(count: validPoints.count)
        }
        
        // 4. Remove outliers
        let cleanedPoints = removeOutliers(validPoints)
        Logger.info("📊 [MLDatasetBuilder] After outlier removal: \(cleanedPoints.count)")
        
        // 5. Convert to Create ML format
        let dataTable = try createMLDataTable(from: cleanedPoints)
        Logger.info("✅ [MLDatasetBuilder] Dataset built: \(dataTable.rows.count) rows, \(dataTable.columnNames.count) features")
        
        return dataTable
    }
    
    /// Build dataset and split into train/test
    /// - Parameter testRatio: Percentage for test set (default 0.2 = 20%)
    /// - Returns: Tuple of (training, testing) datasets
    func buildTrainTestSplit(testRatio: Double = 0.2) async throws -> (train: MLDataTable, test: MLDataTable) {
        let fullDataset = try await buildDataset()
        
        let (train, test) = fullDataset.randomSplit(by: 1.0 - testRatio)
        
        Logger.info("📊 [MLDatasetBuilder] Train/test split: \(train.rows.count) train, \(test.rows.count) test")
        
        return (train, test)
    }
    
    // MARK: - Private Methods
    
    /// Fetch all MLTrainingData from Core Data
    private func fetchTrainingData() async throws -> [MLTrainingData] {
        let context = persistenceController.container.viewContext
        
        return try await context.perform {
            let request = MLTrainingData.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \MLTrainingData.date, ascending: true)]
            
            return try context.fetch(request)
        }
    }
    
    /// Convert Core Data entities to MLTrainingDataPoint structs
    private func convertToDataPoints(_ trainingData: [MLTrainingData]) throws -> [MLTrainingDataPoint] {
        return trainingData.compactMap { data in
            guard let featuresDict = data.featureVector,
                  let features = try? MLFeatureVector.fromDictionary(featuresDict) else {
                Logger.warning("⚠️ [MLDatasetBuilder] Failed to parse features for date: \(data.date ?? Date())")
                return nil
            }
            
            return MLTrainingDataPoint(
                features: features,
                targetRecovery: data.targetRecoveryScore,
                targetReadiness: data.targetReadinessScore,
                dataQuality: data.dataQualityScore
            )
        }
    }
    
    /// Remove outliers using 3-sigma rule
    /// Removes data points where recovery score is > 3 standard deviations from mean
    private func removeOutliers(_ dataPoints: [MLTrainingDataPoint]) -> [MLTrainingDataPoint] {
        let recoveryScores = dataPoints.map { $0.targetRecovery }
        
        guard let mean = recoveryScores.mean,
              let stdDev = recoveryScores.standardDeviation else {
            return dataPoints
        }
        
        let lowerBound = mean - (3 * stdDev)
        let upperBound = mean + (3 * stdDev)
        
        let filtered = dataPoints.filter { point in
            point.targetRecovery >= lowerBound && point.targetRecovery <= upperBound
        }
        
        let removedCount = dataPoints.count - filtered.count
        if removedCount > 0 {
            Logger.info("📊 [MLDatasetBuilder] Removed \(removedCount) outliers (mean: \(Int(mean)), σ: \(Int(stdDev)))")
        }
        
        return filtered
    }
    
    /// Convert data points to Create ML MLDataTable
    private func createMLDataTable(from dataPoints: [MLTrainingDataPoint]) throws -> MLDataTable {
        var columns: [String: [Double]] = [:]
        
        // Initialize all feature columns
        let featureNames = MLFeatureVector.allFeatureNames
        for name in featureNames {
            columns[name] = []
        }
        
        // Add target columns
        columns["targetRecovery"] = []
        columns["targetReadiness"] = []
        
        // Populate columns
        for point in dataPoints {
            let featuresDict = point.features.toDictionary()
            
            // Add features (with imputation for missing values)
            for name in featureNames {
                if let value = featuresDict[name] as? Double {
                    columns[name]?.append(value)
                } else {
                    // Impute missing values with 0 (will be handled by model)
                    columns[name]?.append(0.0)
                }
            }
            
            // Add targets
            columns["targetRecovery"]?.append(point.targetRecovery)
            columns["targetReadiness"]?.append(point.targetReadiness)
        }
        
        // Create MLDataTable
        return try MLDataTable(dictionary: columns)
    }
}

// MARK: - Error Types

enum MLDatasetError: LocalizedError {
    case noData
    case insufficientData(count: Int)
    case conversionFailed
    
    var errorDescription: String? {
        switch self {
        case .noData:
            return "No training data available in Core Data"
        case .insufficientData(let count):
            return "Insufficient training data: \(count) points (minimum 10 required)"
        case .conversionFailed:
            return "Failed to convert data to Create ML format"
        }
    }
}

// MARK: - Array Extensions for Statistics

extension Array where Element == Double {
    var mean: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
    
    var standardDeviation: Double? {
        guard let mean = mean, count > 1 else { return nil }
        let variance = map { pow($0 - mean, 2) }.reduce(0, +) / Double(count - 1)
        return sqrt(variance)
    }
}
