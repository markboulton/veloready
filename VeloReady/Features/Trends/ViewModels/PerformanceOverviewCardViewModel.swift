import Foundation
import SwiftUI

/// ViewModel for Performance Overview card
/// Generates insights by analyzing balance between Recovery, Load, and Sleep metrics
@MainActor
class PerformanceOverviewCardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var insight: String = ""
    
    // MARK: - Public Methods
    
    /// Generate insight based on latest recovery, load, and sleep values
    func generateInsight(
        recoveryData: [TrendsViewModel.TrendDataPoint],
        loadData: [TrendsViewModel.TrendDataPoint],
        sleepData: [TrendsViewModel.TrendDataPoint]
    ) -> String {
        guard let lastRecovery = recoveryData.last?.value,
              let lastLoad = loadData.last?.value,
              let lastSleep = sleepData.last?.value else {
            return TrendsContent.PerformanceOverview.trackConsistently
        }
        
        // Analyze balance between metrics and provide actionable insights
        return analyzeMetricBalance(
            recovery: lastRecovery,
            load: lastLoad,
            sleep: lastSleep
        )
    }
    
    // MARK: - Private Methods
    
    /// Analyze the balance between recovery, training load, and sleep
    /// Returns context-specific insight based on current state
    private func analyzeMetricBalance(recovery: Double, load: Double, sleep: Double) -> String {
        // Well-recovered + Light load + Good sleep = Ready for hard training
        if recovery > 75 && load < 50 && sleep > 75 {
            return TrendsContent.PerformanceOverview.Insights.wellRecovered
        }
        
        // Low recovery + High load = Overtraining risk
        if recovery < 60 && load > 70 {
            return TrendsContent.PerformanceOverview.Insights.highLoadLowRecovery
        }
        
        // Poor sleep + Low recovery = Sleep is limiting factor
        if sleep < 60 && recovery < 70 {
            return TrendsContent.PerformanceOverview.Insights.poorSleepAffecting
        }
        
        // High load + Good recovery = Positive adaptation
        if load > 80 && recovery > 70 {
            return TrendsContent.PerformanceOverview.Insights.highLoadGoodRecovery
        }
        
        // Default: General monitoring guidance
        return TrendsContent.PerformanceOverview.Insights.monitorMetrics
    }
}
