import Foundation

/// Illness indicator model for detecting potential body stress signals
/// Non-diagnostic, educational tool based on physiological deviations
struct IllnessIndicator: Codable, Equatable {
    let date: Date
    let severity: Severity
    let confidence: Double  // 0.0 to 1.0
    let signals: [Signal]
    let recommendation: String
    
    /// Severity levels for body stress indicators
    enum Severity: String, Codable {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        
        var colorToken: String {
            switch self {
            case .low: return "ColorScale.yellowAccent"
            case .moderate: return "ColorScale.amberAccent"
            case .high: return "ColorScale.redAccent"
            }
        }
        
        var icon: String {
            switch self {
            case .low: return Icons.Status.info
            case .moderate: return Icons.Status.warning
            case .high: return Icons.Status.warningFill
            }
        }
    }
    
    /// Individual physiological signals
    struct Signal: Codable, Equatable, Identifiable {
        let id = UUID()
        let type: SignalType
        let deviation: Double  // Percentage deviation from baseline
        let value: Double
        let baseline: Double?
        
        enum CodingKeys: String, CodingKey {
            case type, deviation, value, baseline
        }
        
        enum SignalType: String, Codable {
            case hrvDrop = "HRV Drop"
            case hrvSpike = "HRV Spike"
            case elevatedRHR = "Elevated RHR"
            case respiratoryRate = "Respiratory Rate Change"
            case sleepDisruption = "Sleep Disruption"
            case activityDrop = "Activity Drop"
            case temperatureElevation = "Temperature Elevation"
            
            var icon: String {
                switch self {
                case .hrvDrop: return Icons.Health.hrv
                case .hrvSpike: return Icons.Health.hrv
                case .elevatedRHR: return Icons.Health.heartCircle
                case .respiratoryRate: return Icons.Health.respiratory
                case .sleepDisruption: return Icons.Health.sleepFill
                case .activityDrop: return Icons.Activity.running
                case .temperatureElevation: return Icons.Health.bolt
                }
            }
            
            var description: String {
                switch self {
                case .hrvDrop: return "Heart rate variability significantly below baseline"
                case .hrvSpike: return "Unusually high HRV - parasympathetic overdrive from inflammation"
                case .elevatedRHR: return "Resting heart rate elevated above normal range"
                case .respiratoryRate: return "Breathing pattern changes detected"
                case .sleepDisruption: return "Sleep quality significantly impacted"
                case .activityDrop: return "Unusual decrease in activity levels"
                case .temperatureElevation: return "Body temperature above baseline"
                }
            }
        }
    }
    
    /// Computed properties
    /// Shows alert for moderate/high severity with at least 50% confidence
    var isSignificant: Bool {
        severity != .low && confidence >= 0.5
    }
    
    /// Check if indicator is recent (within last 24 hours)
    /// Old indicators should not be shown even if they were significant
    var isRecent: Bool {
        let hoursSinceDetection = Date().timeIntervalSince(date) / 3600
        return hoursSinceDetection < 24
    }
    
    var primarySignal: Signal? {
        signals.max(by: { abs($0.deviation) < abs($1.deviation) })
    }
    
    /// Generate recommendation based on severity and signals
    static func generateRecommendation(severity: Severity, signals: [Signal]) -> String {
        // Find primary signal (largest deviation)
        let primarySignal = signals.max(by: { abs($0.deviation) < abs($1.deviation) })
        
        // Build context based on primary signal
        var context = ""
        if let primary = primarySignal {
            switch primary.type {
            case .hrvSpike:
                context = "Elevated HRV detected. "
            case .hrvDrop:
                context = "Suppressed HRV detected. "
            case .elevatedRHR:
                context = "Elevated resting heart rate detected. "
            case .sleepDisruption:
                context = "Sleep disruption detected. "
            case .respiratoryRate:
                context = "Respiratory changes detected. "
            case .activityDrop:
                context = "Activity levels reduced. "
            case .temperatureElevation:
                context = "Temperature elevation detected. "
            }
        }
        
        switch severity {
        case .low:
            return context + "Monitor your recovery metrics. Consider taking it easy if symptoms persist."
        case .moderate:
            return context + "Your body is showing stress signals. Prioritize rest and recovery today."
        case .high:
            return context + "Rest is strongly recommended. Consult a healthcare provider if you feel unwell."
        }
    }
}

// MARK: - Detection Algorithm

extension IllnessIndicator {
    /// Detect potential illness indicators from physiological data
    static func detect(
        hrv: Double?,
        hrvBaseline: Double?,
        rhr: Double?,
        rhrBaseline: Double?,
        sleepScore: Int?,
        sleepBaseline: Double?,
        activityLevel: Double?,
        activityBaseline: Double?,
        respiratoryRate: Double?,
        respiratoryBaseline: Double?
    ) -> IllnessIndicator? {
        var signals: [Signal] = []
        var totalDeviation: Double = 0
        var signalCount: Int = 0
        
        // HRV Detection (both drops and spikes)
        if let hrv = hrv, let hrvBaseline = hrvBaseline, hrvBaseline > 0 {
            let deviation = ((hrv - hrvBaseline) / hrvBaseline) * 100
            
            // HRV Drop Detection (fatigue, overtraining)
            if deviation < -10 {  // 10% drop threshold
                signals.append(Signal(
                    type: .hrvDrop,
                    deviation: deviation,
                    value: hrv,
                    baseline: hrvBaseline
                ))
                totalDeviation += abs(deviation)
                signalCount += 1
            }
            // HRV Spike Detection (illness - parasympathetic overdrive)
            // When sick, HRV can spike dramatically (>100% above baseline)
            // This is inflammation triggering excessive vagal tone
            else if deviation > 100 {  // 100% spike threshold (very high HRV)
                signals.append(Signal(
                    type: .hrvSpike,
                    deviation: deviation,
                    value: hrv,
                    baseline: hrvBaseline
                ))
                totalDeviation += abs(deviation) * 1.2  // Higher weight for spikes
                signalCount += 1
            }
        }
        
        // Elevated RHR Detection
        if let rhr = rhr, let rhrBaseline = rhrBaseline, rhrBaseline > 0 {
            let deviation = ((rhr - rhrBaseline) / rhrBaseline) * 100
            if deviation > 3 {  // 3% elevation threshold (lowered for sensitivity)
                signals.append(Signal(
                    type: .elevatedRHR,
                    deviation: deviation,
                    value: rhr,
                    baseline: rhrBaseline
                ))
                totalDeviation += abs(deviation)
                signalCount += 1
            }
        }
        
        // Sleep Disruption Detection
        // Note: Sleep score 70-85 can still mask poor quality sleep with many wake events
        if let sleepScore = sleepScore, let sleepBaseline = sleepBaseline, sleepBaseline > 0 {
            let deviation = ((Double(sleepScore) - sleepBaseline) / sleepBaseline) * 100
            // Detect drops OR moderate sleep scores (60-84 range often indicates disrupted sleep)
            if deviation < -15 || (sleepScore >= 60 && sleepScore < 85 && deviation < 0) {
                signals.append(Signal(
                    type: .sleepDisruption,
                    deviation: deviation,
                    value: Double(sleepScore),
                    baseline: sleepBaseline
                ))
                totalDeviation += abs(deviation) * 0.7  // Increased weight for sleep
                signalCount += 1
            }
        }
        
        // Respiratory Rate Changes
        if let respiratoryRate = respiratoryRate, let respiratoryBaseline = respiratoryBaseline, respiratoryBaseline > 0 {
            let deviation = ((respiratoryRate - respiratoryBaseline) / respiratoryBaseline) * 100
            if abs(deviation) > 8 {  // 8% change threshold (lowered for sensitivity)
                signals.append(Signal(
                    type: .respiratoryRate,
                    deviation: deviation,
                    value: respiratoryRate,
                    baseline: respiratoryBaseline
                ))
                totalDeviation += abs(deviation) * 0.7
                signalCount += 1
            }
        }
        
        // Activity Drop Detection
        if let activityLevel = activityLevel, let activityBaseline = activityBaseline, activityBaseline > 0 {
            let deviation = ((activityLevel - activityBaseline) / activityBaseline) * 100
            if deviation < -25 {  // 25% drop threshold (lowered for sensitivity)
                signals.append(Signal(
                    type: .activityDrop,
                    deviation: deviation,
                    value: activityLevel,
                    baseline: activityBaseline
                ))
                totalDeviation += abs(deviation) * 0.3  // Lowest weight
                signalCount += 1
            }
        }
        
        // Need at least 1 strong signal for detection (lowered from 2 for better sensitivity)
        guard signals.count >= 1 else { return nil }
        
        // Calculate severity based on deviation magnitude and signal count
        let avgDeviation = totalDeviation / Double(signalCount)
        let severity: Severity
        if avgDeviation > 30 || signals.count >= 4 {
            severity = .high
        } else if avgDeviation > 20 || signals.count >= 3 {
            severity = .moderate
        } else {
            severity = .low
        }
        
        // Calculate confidence (0.0 to 1.0)
        let signalConfidence = min(Double(signals.count) / 5.0, 1.0)
        let deviationConfidence = min(avgDeviation / 50.0, 1.0)
        let confidence = (signalConfidence * 0.6) + (deviationConfidence * 0.4)
        
        return IllnessIndicator(
            date: Date(),
            severity: severity,
            confidence: confidence,
            signals: signals,
            recommendation: generateRecommendation(severity: severity, signals: signals)
        )
    }
}
