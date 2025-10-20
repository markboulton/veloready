import Foundation
import SwiftUI

/// Tracks cumulative sleep deficit over 7 days
/// Research basis: Van Dongen et al. (2003) - Cumulative sleep restriction effects
struct SleepDebt: Codable {
    let totalDebtHours: Double
    let band: DebtBand
    let averageSleepDuration: Double // in hours
    let sleepNeed: Double // in hours
    let calculatedAt: Date
    
    enum DebtBand: String, CaseIterable, Codable {
        case minimal = "Minimal"
        case moderate = "Moderate"
        case significant = "Significant"
        case critical = "Critical"
        
        var color: String {
            switch self {
            case .minimal: return "green"
            case .moderate: return "yellow"
            case .significant: return "orange"
            case .critical: return "red"
            }
        }
        
        var colorToken: Color {
            switch self {
            case .minimal: return ColorScale.greenAccent
            case .moderate: return ColorScale.yellowAccent
            case .significant: return ColorScale.amberAccent
            case .critical: return ColorScale.redAccent
            }
        }
        
        var description: String {
            switch self {
            case .minimal: return SleepContent.SleepDebt.minimalDescription
            case .moderate: return SleepContent.SleepDebt.moderateDescription
            case .significant: return SleepContent.SleepDebt.significantDescription
            case .critical: return SleepContent.SleepDebt.criticalDescription
            }
        }
        
        var recommendation: String {
            switch self {
            case .minimal: return SleepContent.SleepDebt.minimalRecommendation
            case .moderate: return SleepContent.SleepDebt.moderateRecommendation
            case .significant: return SleepContent.SleepDebt.significantRecommendation
            case .critical: return SleepContent.SleepDebt.criticalRecommendation
            }
        }
    }
    
    /// Calculate sleep debt from historical sleep data
    /// - Parameters:
    ///   - sleepDurations: Array of (date, duration in seconds) for last 7 days
    ///   - sleepNeed: Individual sleep need in seconds (default 7 hours)
    static func calculate(sleepDurations: [(date: Date, duration: Double)], sleepNeed: Double = 25200) -> SleepDebt {
        let sleepNeedHours = sleepNeed / 3600.0
        var totalDebt = 0.0
        var totalSleep = 0.0
        
        // Calculate cumulative debt over last 7 days
        for (_, duration) in sleepDurations.prefix(7) {
            let durationHours = duration / 3600.0
            totalSleep += durationHours
            let dailyDebt = max(0, sleepNeedHours - durationHours)
            totalDebt += dailyDebt
        }
        
        let avgSleep = sleepDurations.isEmpty ? 0 : totalSleep / Double(min(7, sleepDurations.count))
        let band = determineBand(debtHours: totalDebt)
        
        return SleepDebt(
            totalDebtHours: totalDebt,
            band: band,
            averageSleepDuration: avgSleep,
            sleepNeed: sleepNeedHours,
            calculatedAt: Date()
        )
    }
    
    private static func determineBand(debtHours: Double) -> DebtBand {
        switch debtHours {
        case 0..<2: return .minimal
        case 2..<4: return .moderate
        case 4..<6: return .significant
        default: return .critical
        }
    }
}
