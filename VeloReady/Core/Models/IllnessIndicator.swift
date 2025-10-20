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
            case elevatedRHR = "Elevated RHR"
            case respiratoryRate = "Respiratory Rate Change"
            case sleepDisruption = "Sleep Disruption"
            case activityDrop = "Activity Drop"
            case temperatureElevation = "Temperature Elevation"
            
            var icon: String {
                switch self {
                case .hrvDrop: return Icons.Health.hrv
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
    var isSignificant: Bool {
        severity != .low && confidence >= 0.6
    }
    
    var primarySignal: Signal? {
        signals.max(by: { abs($0.deviation) < abs($1.deviation) })
    }
    
    /// Generate recommendation based on severity and signals
    static func generateRecommendation(severity: Severity, signals: [Signal]) -> String {
        switch severity {
        case .low:
            return "Monitor your recovery metrics. Consider taking it easy if symptoms persist."
        case .moderate:
            return "Your body is showing stress signals. Prioritize rest and recovery today."
        case .high:
            return "Significant body stress detected. Rest is strongly recommended. Consult a healthcare provider if you feel unwell."
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
        
        // HRV Drop Detection (most reliable indicator)
        if let hrv = hrv, let hrvBaseline = hrvBaseline, hrvBaseline > 0 {
            let deviation = ((hrv - hrvBaseline) / hrvBaseline) * 100
            if deviation < -10 {  // 10% drop threshold (lowered for sensitivity)
                signals.append(Signal(
                    type: .hrvDrop,
                    deviation: deviation,
                    value: hrv,
                    baseline: hrvBaseline
                ))
                totalDeviation += abs(deviation)
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
        if let sleepScore = sleepScore, let sleepBaseline = sleepBaseline, sleepBaseline > 0 {
            let deviation = ((Double(sleepScore) - sleepBaseline) / sleepBaseline) * 100
            if deviation < -15 {  // 15% drop in sleep quality (lowered for sensitivity)
                signals.append(Signal(
                    type: .sleepDisruption,
                    deviation: deviation,
                    value: Double(sleepScore),
                    baseline: sleepBaseline
                ))
                totalDeviation += abs(deviation) * 0.5  // Lower weight
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
