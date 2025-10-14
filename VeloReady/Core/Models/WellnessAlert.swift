import Foundation
import SwiftUI

/// Wellness Alert for detecting potential illness or unusual physiological patterns
/// NOTE: This is NOT medical advice - it's a wellness awareness tool
struct WellnessAlert: Identifiable {
    let id = UUID()
    let severity: Severity
    let type: AlertType
    let detectedAt: Date
    let metrics: AffectedMetrics
    let trendDays: Int // Number of consecutive days the pattern has been detected
    
    enum Severity: String, CaseIterable {
        case yellow = "Yellow"
        case amber = "Amber"
        case red = "Red"
        
        var color: Color {
            switch self {
            case .yellow: return ColorScale.yellowAccent
            case .amber: return ColorScale.amberAccent
            case .red: return ColorScale.redAccent
            }
        }
        
        var icon: String {
            Icons.Status.warning
        }
    }
    
    enum AlertType: String {
        case unusualMetrics = "Unusual Metrics"
        case sustainedElevation = "Sustained Elevation"
        case multipleIndicators = "Multiple Indicators"
        
        var title: String {
            self.rawValue
        }
    }
    
    struct AffectedMetrics {
        let elevatedRHR: Bool
        let depressedHRV: Bool
        let elevatedRespiratoryRate: Bool
        let elevatedBodyTemp: Bool
        let poorSleep: Bool
        
        var count: Int {
            var total = 0
            if elevatedRHR { total += 1 }
            if depressedHRV { total += 1 }
            if elevatedRespiratoryRate { total += 1 }
            if elevatedBodyTemp { total += 1 }
            if poorSleep { total += 1 }
            return total
        }
    }
    
    /// One-sentence summary for the banner
    var bannerMessage: String {
        switch severity {
        case .yellow:
            return "Your metrics show some unusual patterns worth noting"
        case .amber:
            return "Multiple metrics are showing sustained changes"
        case .red:
            return "Several key metrics are significantly elevated"
        }
    }
}
