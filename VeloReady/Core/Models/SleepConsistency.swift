import Foundation
import SwiftUI

/// Tracks sleep schedule consistency (circadian rhythm health)
/// Research basis: Phillips et al. (2017) - Irregular sleep patterns impair recovery
struct SleepConsistency: Codable {
    let score: Int // 0-100
    let band: ConsistencyBand
    let bedtimeVariability: Double // Standard deviation in minutes
    let wakeTimeVariability: Double // Standard deviation in minutes
    let calculatedAt: Date
    
    enum ConsistencyBand: String, CaseIterable, Codable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        
        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "yellow"
            case .fair: return "orange"
            case .poor: return "red"
            }
        }
        
        var colorToken: Color {
            switch self {
            case .excellent: return ColorScale.greenAccent
            case .good: return ColorScale.yellowAccent
            case .fair: return ColorScale.amberAccent
            case .poor: return ColorScale.redAccent
            }
        }
        
        var description: String {
            switch self {
            case .excellent: return "Highly consistent sleep schedule"
            case .good: return "Generally consistent sleep schedule"
            case .fair: return "Moderately inconsistent sleep schedule"
            case .poor: return "Highly irregular sleep schedule"
            }
        }
        
        var recommendation: String {
            switch self {
            case .excellent: return "Maintain current sleep schedule"
            case .good: return "Try to keep bedtime within 30 minutes"
            case .fair: return "Establish more regular sleep/wake times"
            case .poor: return "Prioritize consistent sleep schedule - critical for recovery"
            }
        }
    }
    
    /// Calculate sleep consistency from historical bedtime/wake time data
    /// - Parameter sleepSessions: Array of (bedtime, wakeTime) for last 7 days
    static func calculate(sleepSessions: [(bedtime: Date, wakeTime: Date)]) -> SleepConsistency {
        guard sleepSessions.count >= 3 else {
            // Not enough data
            return SleepConsistency(
                score: 50,
                band: .fair,
                bedtimeVariability: 0,
                wakeTimeVariability: 0,
                calculatedAt: Date()
            )
        }
        
        // Extract time of day (ignoring date) for bedtime and wake time
        let calendar = Calendar.current
        var bedtimeMinutes: [Double] = []
        var wakeTimeMinutes: [Double] = []
        
        for session in sleepSessions {
            let bedtimeComponents = calendar.dateComponents([.hour, .minute], from: session.bedtime)
            let wakeComponents = calendar.dateComponents([.hour, .minute], from: session.wakeTime)
            
            // Convert to minutes since midnight (handle overnight bedtimes)
            var bedMinutes = Double((bedtimeComponents.hour ?? 0) * 60 + (bedtimeComponents.minute ?? 0))
            if bedMinutes < 720 { // Before noon = likely overnight (add 24 hours)
                bedMinutes += 1440
            }
            
            let wakeMinutes = Double((wakeComponents.hour ?? 0) * 60 + (wakeComponents.minute ?? 0))
            
            bedtimeMinutes.append(bedMinutes)
            wakeTimeMinutes.append(wakeMinutes)
        }
        
        // Calculate standard deviation
        let bedtimeSD = standardDeviation(bedtimeMinutes)
        let wakeTimeSD = standardDeviation(wakeTimeMinutes)
        
        // Score based on average variability
        let avgVariability = (bedtimeSD + wakeTimeSD) / 2.0
        let score = calculateScore(variability: avgVariability)
        let band = determineBand(score: score)
        
        return SleepConsistency(
            score: score,
            band: band,
            bedtimeVariability: bedtimeSD,
            wakeTimeVariability: wakeTimeSD,
            calculatedAt: Date()
        )
    }
    
    private static func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
    
    private static func calculateScore(variability: Double) -> Int {
        // SD < 30min = Excellent (90-100)
        // SD 30-60min = Good (70-89)
        // SD 60-90min = Fair (50-69)
        // SD > 90min = Poor (<50)
        switch variability {
        case 0..<30:
            return Int(100 - (variability / 30 * 10))
        case 30..<60:
            return Int(89 - ((variability - 30) / 30 * 19))
        case 60..<90:
            return Int(69 - ((variability - 60) / 30 * 19))
        default:
            return max(0, Int(50 - ((variability - 90) / 60 * 50)))
        }
    }
    
    private static func determineBand(score: Int) -> ConsistencyBand {
        switch score {
        case 90...100: return .excellent
        case 70..<90: return .good
        case 50..<70: return .fair
        default: return .poor
        }
    }
}
