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
        static let average = "Avg"  /// Average (abbreviated to prevent wrapping)
        static let minimum = "Min"  /// Minimum (abbreviated to prevent wrapping)
        static let maximum = "Max"  /// Maximum (abbreviated to prevent wrapping)
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
        static let noData = CommonContent.States.noData  /// No data message - from CommonContent
        static let noHeartRateData = "No heart rate data available"  /// No HR data
        static let noPowerData = "No power data available"  /// No power data
    }
    
    // MARK: - Summary Labels
    enum Summary {
        static let avg = "Avg:"  /// Average prefix
        static let max = "Max:"  /// Maximum prefix
        static let min = "Min:"  /// Minimum prefix
        static let avgShort = CommonContent.Labels.average  /// Average (short) - from CommonContent
        static let maxShort = "Max"  /// Maximum (short)
        static let minShort = "Min"  /// Minimum (short)
    }
    
    // MARK: - Axis Labels
    enum Axis {
        static let time = "Time"  /// Time axis
        static let value = "Value"  /// Value axis
        static let date = "Date"  /// Date axis
        static let day = "Day"  /// Day axis
        static let average = CommonContent.Metrics.average  /// Average line label - from CommonContent
    }
    
    // MARK: - HRV Chart
    enum HRV {
        static let hrvTrend = "HRV Trend"  /// HRV trend title
        static let noDataForPeriod = "No HRV data for this period"  /// No data message
        static let dataWillAppear = "HRV data will appear as it's collected"  /// Data collection message
        static let average = CommonContent.Metrics.average  /// Average label - from CommonContent
        static let minimum = CommonContent.Metrics.minimum  /// Minimum label - from CommonContent
        static let maximum = CommonContent.Metrics.maximum  /// Maximum label - from CommonContent
        static let msUnit = CommonContent.Units.milliseconds  /// Milliseconds unit
    }
    
    // MARK: - RHR Chart
    enum RHR {
        static let rhrTrend = "RHR Trend"  /// RHR trend title
        static let noDataForPeriod = "No RHR data for this period"  /// No data message
        static let dataWillAppear = "RHR data will appear as it's collected"  /// Data collection message
    }
    
    // MARK: - Weekly Trend
    enum WeeklyTrend {
        static let notEnoughData = CommonContent.States.notEnoughData  /// Not enough data message - from CommonContent
        static let checkBackLater = CommonContent.EmptyStates.checkBack  /// Check back message - from CommonContent
    }
    
    // MARK: - Trend Direction Icons
    enum TrendIcons {
        static let arrowUpRight = "arrow.up.right"  /// Upward trend icon
        static let arrowDownRight = "arrow.down.right"  /// Downward trend icon
        static let arrowRight = "arrow.right"  /// Stable trend icon
        static let minus = "minus"  /// No trend icon
    }
    
    // MARK: - Chart Titles (Static)
    enum ChartTitles {
        static let recoveryScore = "Recovery Score"  /// Recovery score chart
        static let sleepScore = "Sleep Score"  /// Sleep score chart
        static let sleepHypnogram = "Sleep Hypnogram"  /// Sleep hypnogram chart
        static let sleepArchitecture = "Sleep Architecture (7 days)"  /// Sleep architecture chart
        static let dailyRhythmPatterns = "Daily Rhythm Patterns"  /// Daily rhythm patterns
        static let wellnessFoundation = "Wellness Foundation"  /// Wellness foundation
    }
    
    // MARK: - Chart Examples (Preview/Demo)
    enum Examples {
        static let lastNightSleep = "Last night: 7.2h total sleep"  /// Example sleep data
        static let deepSleepAvg = "Deep: 1.3h avg"  /// Example deep sleep
        static let remSleepAvg = "REM: 1.9h avg"  /// Example REM sleep
        static let bedtimeVariance = "Bedtime variance: ±22 min"  /// Example bedtime variance
        static let trainingTime = "Training time: Mostly afternoons"  /// Example training time
        static let foundationScore = "Foundation Score: 78/100"  /// Example foundation score
        static let qualityConsistent = "Quality consistent - supporting training adaptations well."  /// Example quality message
    }
}

