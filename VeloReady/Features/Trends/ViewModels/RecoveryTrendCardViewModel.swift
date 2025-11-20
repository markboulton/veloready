import Foundation

/// ViewModel for Recovery Trend card
/// Generates insights based on average recovery score
@MainActor
@Observable
final class RecoveryTrendCardViewModel {
    
    /// Generate insight based on average recovery score
    func generateInsight(data: [TrendsDataLoader.TrendDataPoint]) -> String {
        guard !data.isEmpty else {
            return TrendsContent.noDataFound
        }
        
        let avg = data.map(\.value).reduce(0, +) / Double(data.count)
        
        if avg >= 75 {
            return "Excellent recovery average (\(Int(avg))%). Your body is responding well to training."
        } else if avg >= 60 {
            return "Good recovery average (\(Int(avg))%). You're maintaining solid readiness."
        } else if avg >= 50 {
            return "Moderate recovery average (\(Int(avg))%). Consider more rest or easier training."
        } else {
            return "Low recovery average (\(Int(avg))%). Increase rest days and prioritize sleep."
        }
    }
}
