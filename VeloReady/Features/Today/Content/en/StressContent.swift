import Foundation

/// Content strings for Stress monitoring feature
/// Follows content abstraction strategy
enum StressContent {
    // MARK: - Navigation
    static let title = "Stress Analysis"  /// Navigation title for stress detail sheet
    static let detailsLink = "Details"  /// Details link text for banner
    
    // MARK: - Banner Messages
    enum Banner {
        static let title = "Training Stress Detected"  /// Banner heading
        static let elevated = "High Training Stress. Your body is showing signs of accumulated stress."  /// Elevated stress banner
        static let high = "Critical Stress Level. Your body needs immediate recovery."  /// High stress banner
    }
    
    // MARK: - Sections
    enum Sections {
        static let currentState = "Current State"  /// Current state section
        static let trend = "30-Day Trend"  /// Trend section
        static let contributors = "Contributors"  /// Contributors section
        static let whatThisMeans = "What This Means"  /// Explanation section
        static let recommendation = "Recommendation"  /// Recommendation section
    }
    
    // MARK: - Metrics
    enum Metrics {
        static let acuteStress = "Acute Stress"  /// Acute stress label
        static let chronicStress = "Chronic Stress"  /// Chronic stress label
        static let trend = "Trend:"  /// Trend label
        static let youAreHere = "You are here"  /// Chart marker label
    }
    
    // MARK: - Contributors
    enum Contributors {
        static let trainingLoad = "Training Load"  /// Training load contributor
        static let sleepQuality = "Sleep Quality"  /// Sleep quality contributor
        static let hrv = "HRV"  /// HRV contributor
        static let temperature = "Body Temperature"  /// Temperature contributor
        static let recovery = "Recovery Score"  /// Recovery contributor
        static let strain = "Strain"  /// Strain contributor
        
        // Descriptions
        static func trainingLoadDescription(atlCtlRatio: Double) -> String {
            return "ATL/CTL = \(String(format: "%.1f", atlCtlRatio)) (overreaching)"
        }
        
        static func sleepQualityDescription(wakeEvents: Int, hours: Double) -> String {
            return "\(wakeEvents) wake events, \(String(format: "%.1f", hours))h sleep"
        }
        
        static func hrvDescription(deviationPercent: Int) -> String {
            return "\(abs(deviationPercent))% below baseline"
        }
        
        static func temperatureDescription(deviationC: Double) -> String {
            return "\(String(format: "%.1f", deviationC))°C above baseline"
        }
    }
    
    // MARK: - Disclaimer
    enum Disclaimer {
        static let text = "This analysis is based on training load patterns and physiological metrics. It's designed to help you optimize training, not diagnose medical conditions."
    }
    
    // MARK: - Recommendations
    enum Recommendations {
        static let implementRecoveryWeek = "✅ Implement recovery week NOW"  /// Main recommendation
        static let reduceVolume = "• Reduce volume by 50%"  /// Volume reduction
        static let keepZ2 = "• Keep intensity at Z2 only"  /// Intensity guidance
        static let prioritizeSleep = "• Prioritize 8+ hours sleep"  /// Sleep guidance
        static let monitorHRV = "• Monitor HRV for recovery signs"  /// HRV monitoring
        static let disclaimer = "These are training recommendations. If you feel unwell or have concerns about your health, please consult a healthcare provider."
        
        static func expectedRecovery(days: Int) -> String {
            return "Expected Recovery: \(days)-\(days+3) days"
        }
    }
    
    // MARK: - Status Labels
    enum Status {
        static let low = "Low"  /// Low status
        static let moderate = "Moderate"  /// Moderate status
        static let elevated = "Elevated"  /// Elevated status
        static let high = "High"  /// High status
        static let optimal = "Optimal"  /// Optimal status
        static let good = "Good"  /// Good status
        static let fair = "Fair"  /// Fair status
    }
    
    // MARK: - Trend Labels
    enum TrendLabels {
        static let increasing = "Increasing"  /// Increasing trend
        static let stable = "Stable"  /// Stable trend
        static let decreasing = "Decreasing"  /// Decreasing trend
    }
    
    // MARK: - Chart Labels
    enum Chart {
        static let lowLabel = "Low"  /// Chart low label
        static let moderateLabel = "Moderate"  /// Chart moderate label
        static let highLabel = "High"  /// Chart high label
    }
    
    // MARK: - Recovery Factors Card
    enum RecoveryFactors {
        static let title = "Recovery Breakdown"  /// Card title
        static let stress = "Stress"  /// Stress factor
        static let subtitle = "Factors contributing to your recovery score"  /// Card subtitle
    }
    
    // MARK: - Actions
    enum Actions {
        static let gotIt = "Got it"  /// Dismiss button
        static let learnMore = "Learn More"  /// Learn more button
    }
    
    // MARK: - Empty States
    static let noData = CommonContent.States.noData  /// No data message
    static let loading = CommonContent.States.loadingData  /// Loading message
}

