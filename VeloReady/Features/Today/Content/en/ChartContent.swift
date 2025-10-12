import Foundation

/// Content strings for chart components
enum ChartContent {
    // MARK: - Period Labels
    enum Period {
        static let sevenDays = "7 Days"  /// 7-day period label
        static let thirtyDays = "30 Days"  /// 30-day period label
        static let sixtyDays = "60 Days"  /// 60-day period label
    }
    
    // MARK: - Summary Stats
    enum Stats {
        static let average = "Avg"  /// Average label
        static let minimum = "Min"  /// Minimum label
        static let maximum = "Max"  /// Maximum label
    }
    
    // MARK: - Trend Indicators
    enum Trend {
        static let improving = "Improving"  /// Improving trend
        static let declining = "Declining"  /// Declining trend
        static let stable = "Stable"  /// Stable trend
    }
    
    // MARK: - Empty State
    enum EmptyState {
        static let noData = "Not enough data"  /// No data message
        static let checkBack = "Check back after a few days"  /// Check back message
    }
    
    // MARK: - Chart Titles (Generic)
    enum Titles {
        static func recoveryTrend(days: Int) -> String {
            "\(days)-Day Recovery Trend"
        }
        
        static func sleepTrend(days: Int) -> String {
            "\(days)-Day Sleep Trend"
        }
        
        static func loadTrend(days: Int) -> String {
            "\(days)-Day Load Trend"
        }
        
        static func heartRateTrend(days: Int) -> String {
            "\(days)-Day Heart Rate Trend"
        }
        
        static func vo2MaxTrend(days: Int) -> String {
            "\(days)-Day VO₂ Max Trend"
        }
        
        static func hrvTrend(days: Int) -> String {
            "\(days)-Day HRV Trend"
        }
    }
}
