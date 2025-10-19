import Foundation

/// Orchestrates recovery score calculation using ML or rule-based approach
/// Provides seamless fallback and A/B testing capabilities
@MainActor
class PersonalizedRecoveryCalculator {
    
    static let shared = PersonalizedRecoveryCalculator()
    
    private let mlPredictionService = MLPredictionService.shared
    private let mlRegistry = MLModelRegistry.shared
    
    private init() {}
    
    // MARK: - Public API
    
    /// Calculate recovery score using best available method
    /// - Parameter features: Feature vector for today
    /// - Returns: Recovery score (0-100) with metadata
    func calculateRecoveryScore(features: MLFeatureVector) async -> RecoveryScoreResult {
        // Check if ML is enabled and available
        if mlRegistry.isMLEnabled && mlPredictionService.isModelAvailable {
            return await calculateWithML(features: features)
        } else {
            return calculateWithRuleBased(features: features)
        }
    }
    
    /// Force ML prediction (for testing)
    func calculateWithML(features: MLFeatureVector) async -> RecoveryScoreResult {
        do {
            let prediction = try await mlPredictionService.predict(features: features)
            
            return RecoveryScoreResult(
                score: prediction.predictedScore,
                method: .machineLearning,
                confidence: prediction.confidence,
                inferenceTimeMs: prediction.inferenceTimeMs,
                modelVersion: prediction.modelVersion
            )
        } catch {
            Logger.warning("⚠️ [PersonalizedRecovery] ML prediction failed: \(error), falling back to rule-based")
            return calculateWithRuleBased(features: features)
        }
    }
    
    /// Force rule-based calculation (for comparison)
    func calculateWithRuleBased(features: MLFeatureVector) -> RecoveryScoreResult {
        let startTime = Date()
        
        // Use existing rule-based algorithm
        let score = computeRuleBasedScore(features: features)
        
        let inferenceTime = Date().timeIntervalSince(startTime) * 1000 // ms
        
        return RecoveryScoreResult(
            score: score,
            method: .ruleBased,
            confidence: 0.8, // Rule-based has consistent confidence
            inferenceTimeMs: inferenceTime,
            modelVersion: "rule-based-v1"
        )
    }
    
    // MARK: - Rule-Based Algorithm
    
    /// Compute recovery score using rule-based algorithm
    /// This is the existing algorithm from RecoveryScoreService
    private func computeRuleBasedScore(features: MLFeatureVector) -> Double {
        var score = 50.0 // Start at neutral
        
        // 1. HRV contribution (30% weight)
        if let hrv = features.hrv, let hrvBaseline = features.hrvBaseline, hrvBaseline > 0 {
            let hrvDelta = (hrv - hrvBaseline) / hrvBaseline
            score += hrvDelta * 30.0
        }
        
        // 2. RHR contribution (20% weight)
        if let rhr = features.rhr, let rhrBaseline = features.rhrBaseline, rhrBaseline > 0 {
            let rhrDelta = (rhrBaseline - rhr) / rhrBaseline // Inverse: lower RHR is better
            score += rhrDelta * 20.0
        }
        
        // 3. Sleep contribution (25% weight)
        if let sleepDuration = features.sleepDuration, let sleepBaseline = features.sleepBaseline, sleepBaseline > 0 {
            let sleepDelta = (sleepDuration - sleepBaseline) / sleepBaseline
            score += sleepDelta * 25.0
        }
        
        // 4. Training load contribution (25% weight)
        if let tsb = features.tsb {
            // TSB (Training Stress Balance): positive = fresh, negative = fatigued
            let tsbContribution = tsb / 50.0 // Normalize to -1 to 1 range
            score += tsbContribution * 25.0
        }
        
        // Clamp to 0-100 range
        return max(0, min(100, score))
    }
}

// MARK: - Result Types

/// Result of recovery score calculation
struct RecoveryScoreResult {
    let score: Double
    let method: CalculationMethod
    let confidence: Double
    let inferenceTimeMs: Double
    let modelVersion: String
    let timestamp: Date
    
    init(score: Double, method: CalculationMethod, confidence: Double, 
         inferenceTimeMs: Double, modelVersion: String) {
        self.score = score
        self.method = method
        self.confidence = confidence
        self.inferenceTimeMs = inferenceTimeMs
        self.modelVersion = modelVersion
        self.timestamp = Date()
    }
    
    /// Display name for UI
    var methodDisplayName: String {
        switch method {
        case .machineLearning:
            return "Personalized"
        case .ruleBased:
            return "Standard"
        }
    }
    
    /// Whether this is a high-quality prediction
    var isHighQuality: Bool {
        return confidence >= 0.7
    }
}

enum CalculationMethod: String, Codable {
    case machineLearning = "ml"
    case ruleBased = "rule_based"
}
