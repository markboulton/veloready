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
        static let average = CommonContent.Metrics.average
        static let minimum = CommonContent.Metrics.minimum
        static let maximum = CommonContent.Metrics.maximum
    }
    
    // MARK: - Trend Indicators
    enum Trend {
        static let improving = "Improving"  /// Improving trend
        static let declining = "Declining"  /// Declining trend
        static let stable = "Stable"  /// Stable trend
    }
    
    // MARK: - Empty State
    enum EmptyState {
        static let noData = CommonContent.States.notEnoughData
        static let checkBack = CommonContent.EmptyStates.checkBack
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
    
    // MARK: - Zone Labels
    enum Zones {
        static let zone = "Zone"  /// Zone prefix
        static let noData = "No data available"  /// No data message
        static let noHeartRateData = "No heart rate data available"  /// No HR data
        static let noPowerData = "No power data available"  /// No power data
    }
    
    // MARK: - Summary Labels
    enum Summary {
        static let avg = "Avg:"  /// Average prefix
        static let max = "Max:"  /// Maximum prefix
        static let min = "Min:"  /// Minimum prefix
    }
    
    // MARK: - Axis Labels
    enum Axis {
        static let time = "Time"  /// Time axis
        static let value = "Value"  /// Value axis
        static let date = "Date"  /// Date axis
    }
}
