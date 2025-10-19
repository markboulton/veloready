import Foundation

/// Privacy-focused telemetry service for ML performance tracking
/// All metrics are aggregated and no PII/health data is collected
@MainActor
class MLTelemetryService {
    static let shared = MLTelemetryService()
    
    private var isEnabled: Bool
    
    // Telemetry batching (send max 1x per hour)
    private var eventQueue: [TelemetryEvent] = []
    private var lastFlushTime = Date()
    private let flushInterval: TimeInterval = 3600 // 1 hour
    
    private init() {
        // Check user preference for telemetry
        self.isEnabled = UserDefaults.standard.bool(forKey: "mlTelemetryEnabled")
        
        // Default to enabled (can be disabled in Settings)
        if UserDefaults.standard.object(forKey: "mlTelemetryEnabled") == nil {
            self.isEnabled = true
            UserDefaults.standard.set(true, forKey: "mlTelemetryEnabled")
        }
    }
    
    // MARK: - Public API
    
    /// Enable or disable telemetry collection
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "mlTelemetryEnabled")
        Logger.info("🔔 [Telemetry] \(enabled ? "Enabled" : "Disabled")", category: .data)
    }
    
    // MARK: - Model Performance Events
    
    /// Track a prediction made by the ML model
    func trackPrediction(
        predictedScore: Double,
        actualScore: Double?,
        inferenceTimeMs: Double,
        modelVersion: String,
        confidence: Double?
    ) {
        guard isEnabled else { return }
        
        let mae = actualScore.map { abs(predictedScore - $0) }
        
        let properties: [String: Any] = [
            "mae_rounded": mae.map { roundToNearest5($0) } as Any,
            "inference_time_ms": round(inferenceTimeMs),
            "model_version": modelVersion,
            "confidence_rounded": confidence.map { roundToNearest5($0 * 100) } as Any
        ]
        
        track(event: "ml_prediction_made", properties: properties)
    }
    
    /// Track model training completion
    func trackTrainingCompleted(
        sampleCount: Int,
        validationMAE: Double,
        trainingTimeSeconds: Double,
        modelVersion: String
    ) {
        guard isEnabled else { return }
        
        let properties: [String: Any] = [
            "sample_count_rounded": roundToNearest5(Double(sampleCount)),
            "validation_mae_rounded": roundToNearest5(validationMAE),
            "training_time_s": round(trainingTimeSeconds),
            "model_version": modelVersion
        ]
        
        track(event: "ml_training_completed", properties: properties)
    }
    
    /// Track feature importance from model
    func trackFeatureImportance(
        topFeatures: [String],
        modelVersion: String
    ) {
        guard isEnabled else { return }
        
        let properties: [String: Any] = [
            "top_3_features": Array(topFeatures.prefix(3)),
            "model_version": modelVersion
        ]
        
        track(event: "ml_feature_importance", properties: properties)
    }
    
    // MARK: - Data Quality Events
    
    /// Track data collection milestone
    func trackDataCollectionMilestone(
        daysCollected: Int,
        validDays: Int
    ) {
        guard isEnabled else { return }
        
        let properties: [String: Any] = [
            "days_collected": daysCollected,
            "valid_days": validDays,
            "completion_pct": round(Double(validDays) / 30.0 * 100)
        ]
        
        track(event: "ml_data_collection_milestone", properties: properties)
    }
    
    /// Track feature missing frequency
    func trackFeatureMissing(
        featureName: String,
        frequency: Double
    ) {
        guard isEnabled else { return }
        
        let properties: [String: Any] = [
            "feature_name": featureName,
            "missing_pct": round(frequency * 100)
        ]
        
        track(event: "ml_feature_missing", properties: properties)
    }
    
    // MARK: - User Behavior Events
    
    /// Track when user enables personalization
    func trackPersonalizationEnabled(daysUntilEnabled: Int) {
        guard isEnabled else { return }
        
        let properties: [String: Any] = [
            "days_until_enabled": daysUntilEnabled
        ]
        
        track(event: "ml_personalization_enabled", properties: properties)
    }
    
    /// Track when user disables personalization
    func trackPersonalizationDisabled(reason: String?) {
        guard isEnabled else { return }
        
        let properties: [String: Any] = [
            "reason": reason ?? "user_preference"
        ]
        
        track(event: "ml_personalization_disabled", properties: properties)
    }
    
    /// Track when user views ML info sheet
    func trackInfoSheetViewed(source: String) {
        guard isEnabled else { return }
        
        let properties: [String: Any] = [
            "source": source
        ]
        
        track(event: "ml_info_sheet_viewed", properties: properties)
    }
    
    // MARK: - Error Tracking
    
    /// Track ML errors
    func trackError(
        errorType: String,
        errorMessage: String,
        context: [String: Any] = [:]
    ) {
        guard isEnabled else { return }
        
        var properties = context
        properties["error_type"] = errorType
        properties["error_message_hash"] = hashString(errorMessage) // Don't send raw error messages
        
        track(event: "ml_error", properties: properties)
    }
    
    // MARK: - Private Helpers
    
    private func track(event: String, properties: [String: Any]) {
        let telemetryEvent = TelemetryEvent(
            name: event,
            properties: properties,
            timestamp: Date()
        )
        
        eventQueue.append(telemetryEvent)
        
        // Log locally for debugging
        Logger.debug("📊 [Telemetry] \(event): \(String(describing: properties))", category: .data)
        
        // Flush if interval exceeded
        if Date().timeIntervalSince(lastFlushTime) > flushInterval {
            flushEvents()
        }
    }
    
    private func flushEvents() {
        guard !eventQueue.isEmpty else { return }
        
        Logger.info("🔄 [Telemetry] Flushing \(self.eventQueue.count) events", category: .data)
        
        // TODO: Send to TelemetryDeck or Firebase
        // For now, just log and clear
        // Example integration:
        // TelemetryDeck.send(eventQueue)
        
        eventQueue.removeAll()
        lastFlushTime = Date()
    }
    
    /// Round to nearest 5 for privacy
    private func roundToNearest5(_ value: Double) -> Double {
        return round(value / 5.0) * 5.0
    }
    
    /// Hash string to avoid sending raw error messages
    private func hashString(_ string: String) -> String {
        let data = Data(string.utf8)
        let hash = data.reduce(0) { ($0 &+ UInt($1)) % 10000 }
        return String(hash)
    }
}

// MARK: - Telemetry Event Model

private struct TelemetryEvent {
    let name: String
    let properties: [String: Any]
    let timestamp: Date
}
