import Foundation
import CoreML

/// Service for making predictions using trained ML models
/// Handles model loading, inference, confidence scoring, and caching
@MainActor
class MLPredictionService {
    
    static let shared = MLPredictionService()
    
    // MARK: - State
    
    private var loadedModel: MLModel?
    private var modelVersion: String?
    private var predictionCache: [String: CachedPrediction] = [:]
    private let cacheTTL: TimeInterval = 86400 // 24 hours
    
    // MARK: - Initialization
    
    private init() {
        // Model will be loaded on first prediction
    }
    
    // MARK: - Public API
    
    /// Make a prediction for tomorrow's recovery score
    /// - Parameter features: Feature vector for today
    /// - Returns: Prediction result with score and confidence
    func predict(features: MLFeatureVector) async throws -> PredictionResult {
        // Check cache first
        let cacheKey = generateCacheKey(features)
        if let cached = predictionCache[cacheKey], cached.isValid(ttl: cacheTTL) {
            Logger.debug("⚡ [MLPrediction] Cache hit for prediction")
            return cached.result
        }
        
        // Load model if needed
        if loadedModel == nil {
            try await loadModel()
        }
        
        guard let model = loadedModel else {
            throw MLPredictionError.modelNotLoaded
        }
        
        // Prepare input
        let input = try prepareInput(features)
        
        // Run inference
        let startTime = Date()
        let output = try await model.prediction(from: input)
        let inferenceTime = Date().timeIntervalSince(startTime) * 1000 // ms
        
        // Extract prediction
        guard let predictedScore = output.featureValue(for: "targetRecovery")?.doubleValue else {
            throw MLPredictionError.invalidOutput
        }
        
        // Calculate confidence
        let confidence = calculateConfidence(features: features, prediction: predictedScore)
        
        // Create result
        let result = PredictionResult(
            predictedScore: predictedScore,
            confidence: confidence,
            inferenceTimeMs: inferenceTime,
            modelVersion: modelVersion ?? "unknown",
            features: features
        )
        
        // Cache result
        predictionCache[cacheKey] = CachedPrediction(result: result, cachedAt: Date())
        
        // Log telemetry (fire and forget)
        Task {
            await logPrediction(result: result)
        }
        
        Logger.info("🤖 [MLPrediction] Predicted recovery: \(Int(predictedScore)) (confidence: \(Int(confidence * 100))%, \(String(format: "%.1f", inferenceTime))ms)")
        
        return result
    }
    
    /// Check if ML model is available and loaded
    var isModelAvailable: Bool {
        return loadedModel != nil || modelFileExists()
    }
    
    /// Reload model from disk (useful after training new model)
    func reloadModel() async throws {
        loadedModel = nil
        modelVersion = nil
        predictionCache.removeAll()
        try await loadModel()
        Logger.info("🔄 [MLPrediction] Model reloaded")
    }
    
    /// Clear prediction cache
    func clearCache() {
        predictionCache.removeAll()
        Logger.debug("🗑️ [MLPrediction] Cache cleared")
    }
    
    // MARK: - Private Methods
    
    /// Load trained model from disk
    private func loadModel() async throws {
        Logger.info("📦 [MLPrediction] Loading ML model...")
        
        // Get model URL
        guard let modelURL = getModelURL() else {
            throw MLPredictionError.modelNotFound
        }
        
        // Load model
        let config = MLModelConfiguration()
        config.computeUnits = .all // Use Neural Engine if available
        
        let model = try MLModel(contentsOf: modelURL, configuration: config)
        
        loadedModel = model
        modelVersion = "1.0" // TODO: Read from model metadata
        
        Logger.info("✅ [MLPrediction] Model loaded successfully")
    }
    
    /// Prepare ML input from feature vector
    private func prepareInput(_ features: MLFeatureVector) throws -> MLFeatureProvider {
        let featuresDict = features.toDictionary()
        var inputDict: [String: Any] = [:]
        
        // Convert all features to MLFeatureValue
        for (key, value) in featuresDict {
            inputDict[key] = value
        }
        
        // Create feature provider
        return try MLDictionaryFeatureProvider(dictionary: inputDict)
    }
    
    /// Calculate confidence score for prediction
    /// Based on data quality, feature completeness, and model certainty
    private func calculateConfidence(features: MLFeatureVector, prediction: Double) -> Double {
        var confidence = 1.0
        
        // 1. Check feature completeness
        let featuresDict = features.toDictionary()
        let totalFeatures = Double(MLFeatureVector.allFeatureNames.count)
        let presentFeatures = Double(featuresDict.filter { $0.value != 0 }.count)
        let completeness = presentFeatures / totalFeatures
        confidence *= completeness
        
        // 2. Check if prediction is in reasonable range (0-100)
        if prediction < 0 || prediction > 100 {
            confidence *= 0.5 // Low confidence for out-of-range predictions
        }
        
        // 3. Check critical features
        let hasCriticalFeatures = features.hrv != nil && 
                                  features.rhr != nil && 
                                  features.sleepDuration != nil
        if !hasCriticalFeatures {
            confidence *= 0.7
        }
        
        // 4. Clamp to 0-1 range
        return max(0.0, min(1.0, confidence))
    }
    
    /// Generate cache key from features
    private func generateCacheKey(_ features: MLFeatureVector) -> String {
        // Use timestamp rounded to hour for cache key
        let hour = Calendar.current.component(.hour, from: features.timestamp)
        let day = Calendar.current.component(.day, from: features.timestamp)
        return "prediction_\(day)_\(hour)"
    }
    
    /// Get model file URL
    private func getModelURL() -> URL? {
        // Check documents directory first (for newly trained models)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let documentModelURL = documentsURL.appendingPathComponent("PersonalizedRecovery.mlmodel")
        
        if FileManager.default.fileExists(atPath: documentModelURL.path) {
            return documentModelURL
        }
        
        // Check app bundle (for pre-trained models)
        if let bundleURL = Bundle.main.url(forResource: "PersonalizedRecovery", withExtension: "mlmodel") {
            return bundleURL
        }
        
        return nil
    }
    
    /// Check if model file exists
    private func modelFileExists() -> Bool {
        return getModelURL() != nil
    }
    
    /// Log prediction telemetry
    private func logPrediction(result: PredictionResult) async {
        await MLTelemetryService.shared.trackPrediction(
            predictedScore: result.predictedScore,
            actualScore: nil, // Will be updated later
            inferenceTimeMs: result.inferenceTimeMs,
            modelVersion: result.modelVersion,
            confidence: result.confidence
        )
    }
}

// MARK: - Result Types

/// Result of an ML prediction
struct PredictionResult {
    let predictedScore: Double
    let confidence: Double          // 0.0-1.0
    let inferenceTimeMs: Double
    let modelVersion: String
    let features: MLFeatureVector
    let timestamp: Date
    
    init(predictedScore: Double, confidence: Double, inferenceTimeMs: Double, 
         modelVersion: String, features: MLFeatureVector) {
        self.predictedScore = predictedScore
        self.confidence = confidence
        self.inferenceTimeMs = inferenceTimeMs
        self.modelVersion = modelVersion
        self.features = features
        self.timestamp = Date()
    }
    
    /// Whether this prediction is high quality
    var isHighQuality: Bool {
        return confidence >= 0.7 && inferenceTimeMs < 100
    }
}

/// Cached prediction with timestamp
private struct CachedPrediction {
    let result: PredictionResult
    let cachedAt: Date
    
    func isValid(ttl: TimeInterval) -> Bool {
        return Date().timeIntervalSince(cachedAt) < ttl
    }
}

// MARK: - Error Types

enum MLPredictionError: LocalizedError {
    case modelNotFound
    case modelNotLoaded
    case invalidInput
    case invalidOutput
    case inferenceFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "ML model file not found. Train a model first."
        case .modelNotLoaded:
            return "ML model failed to load"
        case .invalidInput:
            return "Invalid input features"
        case .invalidOutput:
            return "Invalid model output"
        case .inferenceFailed:
            return "Model inference failed"
        }
    }
}
