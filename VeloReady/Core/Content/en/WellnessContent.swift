import Foundation

/// Content strings for wellness alerts and health trend observations
/// NOTE: All content is carefully worded to avoid medical claims
enum WellnessContent {
    
    // MARK: - Banner Messages
    
    enum Banner {
        static let tapToLearnMore = "Tap to learn more"
    }
    
    // MARK: - Detail Sheet
    
    enum Detail {
        static let title = "Wellness Check"
        static let disclaimer = "This is not medical advice. These are observations from your health data to help you make informed decisions about your wellbeing."
        
        // Section titles
        static let whatWeNoticed = "What We Noticed"
        static let affectedMetrics = "Affected Metrics"
        static let whatThisMeans = "What This Means"
        static let recommendations = "What You Can Do"
        
        // Severity descriptions
        static func severityDescription(for severity: String) -> String {
            switch severity.lowercased() {
            case "yellow":
                return "We've noticed some changes in your metrics. This could be normal variation, but it's worth being aware of."
            case "amber":
                return "Multiple metrics are showing sustained changes over the past few days. Consider if you're feeling off."
            case "red":
                return "Several key health metrics are showing significant changes. If you're not feeling well, consider reaching out to a healthcare professional."
            default:
                return "Your metrics are showing some unusual patterns."
            }
        }
    }
    
    // MARK: - Metric Descriptions
    
    enum Metrics {
        static let elevatedRHR = "Elevated Resting Heart Rate"
        static let elevatedRHRDescription = "Your resting heart rate has been consistently higher than your baseline. This can indicate your body is working harder than usual."
        
        static let depressedHRV = "Reduced Heart Rate Variability"
        static let depressedHRVDescription = "Your HRV has been lower than normal. Lower HRV can indicate physical stress or that your body is fighting something."
        
        static let elevatedRespiratory = "Elevated Respiratory Rate"
        static let elevatedRespiratoryDescription = "Your breathing rate has been higher than usual during sleep. This can be a sign of respiratory system stress."
        
        static let elevatedTemp = "Elevated Body Temperature"
        static let elevatedTempDescription = "Your body temperature readings are higher than your baseline."
        
        static let poorSleep = "Disrupted Sleep Quality"
        static let poorSleepDescription = "Your sleep quality has been consistently poor over multiple nights, which can impact recovery and immune function."
    }
    
    // MARK: - Recommendations
    
    enum Recommendations {
        static let general = [
            "Monitor how you're feeling and track any symptoms",
            "Prioritize rest and recovery",
            "Stay well hydrated",
            "Consider reducing training intensity until metrics normalize"
        ]
        
        static let moderate = [
            "Take it easy with training - consider rest or very light activity",
            "Ensure you're getting adequate sleep",
            "Pay attention to nutrition and hydration",
            "Monitor your symptoms and how you feel"
        ]
        
        static let significant = [
            "Consider taking a rest day from training",
            "Monitor your symptoms closely",
            "If you're feeling unwell, consider contacting a healthcare provider",
            "Focus on rest, hydration, and nutrition"
        ]
        
        static let medicalDisclaimer = "If you have concerns about your health, always consult with a qualified healthcare professional."
    }
    
    // MARK: - Empty States
    
    enum EmptyState {
        static let noAlert = "No wellness concerns detected"
        static let noAlertDescription = "Your health metrics are tracking normally compared to your baseline."
        static let insufficientData = "Not enough data to analyze trends"
        static let insufficientDataDescription = "We need a few more days of health data to detect patterns."
    }
    
    // MARK: - Illness Detection
    
    enum IllnessDetection {
        static let title = "Body Stress Signals"
        static let subtitle = "Potential strain indicators"
        
        // Detection messages
        static let patternsDetected = "We've detected some unusual patterns in your health metrics"
        static let multiDayTrend = "These changes have been consistent over multiple days"
        static let notMedicalDiagnosis = "This is not a medical diagnosis - just observations from your data"
        
        // Confidence levels
        static let lowConfidence = "Low confidence"
        static let moderateConfidence = "Moderate confidence"
        static let highConfidence = "High confidence"
        
        // Actions
        static let viewDetails = "View Details"
        static let dismiss = "Dismiss"
        static let understood = "Understood"
        
        // Signal descriptions (detailed)
        static let hrvDropDetail = "Your heart rate variability has dropped significantly below your baseline, which may indicate your body is under stress or fighting something."
        static let elevatedRHRDetail = "Your resting heart rate has been consistently elevated, suggesting your cardiovascular system is working harder than usual."
        static let respiratoryChangeDetail = "Changes in your breathing patterns during sleep can indicate respiratory system stress or congestion."
        static let sleepDisruptionDetail = "Sustained poor sleep quality can impact your immune system and overall recovery capacity."
        static let activityDropDetail = "A significant decrease in your usual activity levels may indicate fatigue or reduced energy."
        static let temperatureElevationDetail = "Elevated body temperature readings above your baseline."
        
        // Recommendations by severity
        static func recommendations(for severity: String) -> [String] {
            switch severity.lowercased() {
            case "low":
                return [
                    "Monitor how you're feeling over the next day or two",
                    "Consider reducing training intensity",
                    "Prioritize sleep and hydration",
                    "Track any symptoms you notice"
                ]
            case "moderate":
                return [
                    "Take it easy with training - light activity or rest",
                    "Focus on recovery: sleep, nutrition, hydration",
                    "Monitor your symptoms closely",
                    "Consider if you're feeling unwell"
                ]
            case "high":
                return [
                    "Rest is strongly recommended today",
                    "Monitor your symptoms carefully",
                    "If you're feeling unwell, consider contacting a healthcare provider",
                    "Prioritize rest, hydration, and nutrition"
                ]
            default:
                return []
            }
        }
    }
}
