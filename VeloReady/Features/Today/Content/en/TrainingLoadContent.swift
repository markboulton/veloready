import Foundation

/// Content strings for Training Load chart
enum TrainingLoadContent {
    // MARK: - Header
    static let title = "Training Load Impact"  /// Chart title
    static let proBadge = "PRO"  /// PRO badge text
    
    // MARK: - Metrics
    enum Metrics {
        static let ctl = "CTL (Fitness)"  /// CTL label
        static let atl = "ATL (Fatigue)"  /// ATL label
        static let tsb = "TSB (Form)"  /// TSB label
        static let form = "Form"  /// Form label
        static let intensityFactor = "Intensity Factor (IF)"  /// IF label
        static let tss = "Training Stress Score (TSS)"  /// TSS label
        static let rideIntensity = "Ride Intensity"  /// Ride intensity label
    }
    
    // MARK: - TSB Descriptions
    enum TSBDescriptions {
        static let heavilyFatigued = "Heavily fatigued - consider rest"  /// TSB < -30
        static let fatigued = "Fatigued - light training recommended"  /// TSB -30 to -10
        static let balanced = "Balanced - normal training"  /// TSB -10 to 25
        static let fresh = "Fresh - good for hard efforts"  /// TSB > 25
    }
    
    // MARK: - Descriptions
    enum Descriptions {
        static let weightedAveragePower = "Weighted average power relative to FTP"  /// IF description
        static let totalTrainingLoad = "Total training load from this ride"  /// TSS description
    }
    
    // MARK: - Empty States
    static let noData = "No training load data available"  /// No data message
    static let loading = CommonContent.States.loadingData
}
