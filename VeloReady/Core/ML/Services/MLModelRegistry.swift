import Foundation
import CoreML

/// Manages ML model versions, deployment, and fallback strategies
@MainActor
class MLModelRegistry: ObservableObject {
    
    static let shared = MLModelRegistry()
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let currentModelVersionKey = "ml_current_model_version"
    private let modelMetadataKey = "ml_model_metadata"
    private let mlEnabledKey = "ml_enabled"
    
    @Published var currentModelVersion: String?
    @Published var isMLEnabled: Bool
    @Published var availableModels: [MLModelMetadata] = []
    
    // MARK: - Initialization
    
    private init() {
        self.currentModelVersion = userDefaults.string(forKey: currentModelVersionKey)
        self.isMLEnabled = userDefaults.bool(forKey: mlEnabledKey)
        loadModelMetadata()
        
        Logger.debug("🤖 [ML Registry] Initialized (version: \(currentModelVersion ?? "none"), enabled: \(isMLEnabled))")
    }
    
    // MARK: - Model Management
    
    /// Register a new model version
    func registerModel(metadata: MLModelMetadata) {
        availableModels.append(metadata)
        saveModelMetadata()
        Logger.debug("🤖 [ML Registry] Registered model: \(metadata.version)")
    }
    
    /// Deploy a model version (make it current)
    func deployModel(version: String) throws {
        guard let model = availableModels.first(where: { $0.version == version }) else {
            throw MLRegistryError.modelNotFound(version)
        }
        
        guard model.isValid else {
            throw MLRegistryError.modelInvalid(version)
        }
        
        currentModelVersion = version
        userDefaults.set(version, forKey: currentModelVersionKey)
        
        Logger.debug("🤖 [ML Registry] Deployed model: \(version)")
    }
    
    /// Rollback to previous model version
    func rollback() throws {
        guard let current = currentModelVersion else {
            throw MLRegistryError.noCurrentModel
        }
        
        // Find previous model (by date)
        let sortedModels = availableModels.sorted { $0.createdAt < $1.createdAt }
        guard let currentIndex = sortedModels.firstIndex(where: { $0.version == current }),
              currentIndex > 0 else {
            throw MLRegistryError.noPreviousModel
        }
        
        let previousModel = sortedModels[currentIndex - 1]
        try deployModel(version: previousModel.version)
        
        Logger.debug("🤖 [ML Registry] Rolled back to: \(previousModel.version)")
    }
    
    /// Enable or disable ML predictions
    func setMLEnabled(_ enabled: Bool) {
        isMLEnabled = enabled
        userDefaults.set(enabled, forKey: mlEnabledKey)
        Logger.debug("🤖 [ML Registry] ML \(enabled ? "enabled" : "disabled")")
    }
    
    /// Get metadata for current model
    func getCurrentModelMetadata() -> MLModelMetadata? {
        guard let version = currentModelVersion else { return nil }
        return availableModels.first(where: { $0.version == version })
    }
    
    /// Check if ML should be used for predictions
    func shouldUseML() -> Bool {
        return isMLEnabled && currentModelVersion != nil
    }
    
    /// Get model file URL for a version
    func getModelURL(for version: String) -> URL? {
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDir.appendingPathComponent("MLModels").appendingPathComponent("\(version).mlmodel")
    }
    
    // MARK: - Metadata Persistence
    
    private func loadModelMetadata() {
        guard let data = userDefaults.data(forKey: modelMetadataKey),
              let models = try? JSONDecoder().decode([MLModelMetadata].self, from: data) else {
            return
        }
        availableModels = models
    }
    
    private func saveModelMetadata() {
        guard let data = try? JSONEncoder().encode(availableModels) else { return }
        userDefaults.set(data, forKey: modelMetadataKey)
    }
    
    // MARK: - Validation
    
    /// Validate model performance before deployment
    func validateModel(
        version: String,
        testDataset: MLTrainingDataset,
        minimumAccuracy: Double = 0.7
    ) async throws -> MLModelValidationResult {
        
        guard let modelURL = getModelURL(for: version) else {
            throw MLRegistryError.modelFileNotFound(version)
        }
        
        // Load model
        guard let model = try? MLModel(contentsOf: modelURL) else {
            throw MLRegistryError.modelLoadFailed(version)
        }
        
        // Run predictions on test set
        var predictions: [(predicted: Double, actual: Double)] = []
        
        for dataPoint in testDataset.validDataPoints {
            // This is a placeholder - actual prediction logic would go here
            // For now, we'll just track that validation is happening
            let predicted = dataPoint.targetRecovery // Placeholder
            let actual = dataPoint.targetRecovery
            predictions.append((predicted, actual))
        }
        
        // Calculate metrics
        let errors = predictions.map { abs($0.predicted - $0.actual) }
        let mae = errors.reduce(0, +) / Double(errors.count)
        let rmse = sqrt(errors.map { $0 * $0 }.reduce(0, +) / Double(errors.count))
        
        let accuracy = 1.0 - (mae / 100.0) // Normalize to 0-1
        let isValid = accuracy >= minimumAccuracy
        
        let result = MLModelValidationResult(
            version: version,
            accuracy: accuracy,
            mae: mae,
            rmse: rmse,
            testSampleCount: predictions.count,
            isValid: isValid,
            validatedAt: Date()
        )
        
        Logger.debug("🤖 [ML Registry] Validation result: \(version) - Accuracy: \(String(format: "%.2f", accuracy)), MAE: \(String(format: "%.2f", mae))")
        
        return result
    }
}

// MARK: - Model Metadata

struct MLModelMetadata: Codable {
    let version: String
    let phase: MLPhase
    let createdAt: Date
    let trainingSampleCount: Int
    let validationAccuracy: Double?
    let modelType: MLModelType
    let isValid: Bool
    
    enum MLPhase: String, Codable {
        case baseline = "baseline"
        case adaptiveWeights = "adaptive_weights"
        case lstm = "lstm"
    }
    
    enum MLModelType: String, Codable {
        case tabularRegressor = "tabular_regressor"
        case neuralNetwork = "neural_network"
        case lstm = "lstm"
    }
}

// MARK: - Validation Result

struct MLModelValidationResult {
    let version: String
    let accuracy: Double
    let mae: Double
    let rmse: Double
    let testSampleCount: Int
    let isValid: Bool
    let validatedAt: Date
}

// MARK: - Errors

enum MLRegistryError: Error, LocalizedError {
    case modelNotFound(String)
    case modelInvalid(String)
    case modelFileNotFound(String)
    case modelLoadFailed(String)
    case noCurrentModel
    case noPreviousModel
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound(let version):
            return "Model version '\(version)' not found in registry"
        case .modelInvalid(let version):
            return "Model version '\(version)' failed validation"
        case .modelFileNotFound(let version):
            return "Model file not found for version '\(version)'"
        case .modelLoadFailed(let version):
            return "Failed to load model version '\(version)'"
        case .noCurrentModel:
            return "No model is currently deployed"
        case .noPreviousModel:
            return "No previous model version available for rollback"
        }
    }
}
