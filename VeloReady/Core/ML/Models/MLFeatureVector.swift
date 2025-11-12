import Foundation

/// Feature vector for ML training - represents a single day's training data
struct MLFeatureVector: Codable {
    // MARK: - Physiological Features
    
    /// Current HRV value (milliseconds)
    let hrv: Double?
    
    /// 30-day HRV baseline (milliseconds)
    let hrvBaseline: Double?
    
    /// HRV delta from baseline (percentage, -1.0 to 1.0)
    let hrvDelta: Double?
    
    /// HRV coefficient of variation over last 7 days (std dev / mean * 100)
    let hrvCoefficientOfVariation: Double?
    
    /// Current RHR value (bpm)
    let rhr: Double?
    
    /// 30-day RHR baseline (bpm)
    let rhrBaseline: Double?
    
    /// RHR delta from baseline (percentage, -1.0 to 1.0)
    let rhrDelta: Double?
    
    /// Sleep duration last night (hours)
    let sleepDuration: Double?
    
    /// 30-day sleep baseline (hours)
    let sleepBaseline: Double?
    
    /// Sleep delta from baseline (hours)
    let sleepDelta: Double?
    
    /// Respiratory rate (breaths per minute)
    let respiratoryRate: Double?
    
    // MARK: - Training Load Features
    
    /// Yesterday's strain score (0-18)
    let yesterdayStrain: Double?
    
    /// Yesterday's TSS
    let yesterdayTSS: Double?
    
    /// Chronic Training Load (42-day exponentially weighted average)
    let ctl: Double?
    
    /// Acute Training Load (7-day exponentially weighted average)
    let atl: Double?
    
    /// Training Stress Balance (CTL - ATL)
    let tsb: Double?
    
    /// Acute:Chronic ratio (ATL/CTL)
    let acuteChronicRatio: Double?
    
    /// Training monotony (average TSS / std dev TSS over last 7 days)
    let trainingMonotony: Double?
    
    /// Training strain (total TSS * monotony over last 7 days)
    let trainingStrain: Double?
    
    // MARK: - Recovery Trends
    
    /// 7-day rolling average of recovery scores
    let recoveryTrend7d: Double?
    
    /// 3-day rolling average of recovery scores
    let recoveryTrend3d: Double?
    
    /// Yesterday's recovery score
    let yesterdayRecovery: Double?
    
    /// Recovery change from yesterday (delta)
    let recoveryChange: Double?
    
    // MARK: - Sleep Trends
    
    /// 7-day rolling average of sleep duration (hours)
    let sleepTrend7d: Double?
    
    /// Accumulated sleep debt (hours below baseline over last 7 days)
    let sleepDebt7d: Double?
    
    /// Sleep quality score (if available, 0-100)
    let sleepQualityScore: Double?
    
    // MARK: - Temporal Features
    
    /// Day of week (1=Monday, 7=Sunday)
    let dayOfWeek: Int
    
    /// Days since last hard workout (TSS > 100)
    let daysSinceHardWorkout: Int?
    
    /// Days into current training block
    let trainingBlockDay: Int?
    
    // MARK: - Contextual Features
    
    /// Alcohol detected (overnight HRV suppression)
    let alcoholDetected: Bool?
    
    /// Possible illness marker (HRV drop + RHR spike)
    let illnessMarker: Bool?
    
    /// Month of year (1-12, for seasonal patterns)
    let monthOfYear: Int
    
    // MARK: - Pattern-Based Features (from non-ingestible sources)
    
    /// Strava pattern: CTL trend (aggregate metric, not raw data)
    /// Compliant with Strava API terms - uses metadata only
    let stravaPatternCTLTrend: Double?
    
    /// Strava pattern: ATL trend (7-day average)
    let stravaPatternATLTrend: Double?
    
    /// Strava pattern: TSB trend (stress balance)
    let stravaPatternTSBTrend: Double?
    
    /// Strava pattern: Intensity trend (average IF over 14 days)
    let stravaPatternIntensityTrend: Double?
    
    /// Strava pattern: Volume trend (hours per week)
    let stravaPatternVolumeTrend: Double?
    
    // MARK: - Data Quality
    
    /// Timestamp when features were extracted
    let timestamp: Date
    
    /// Primary training data source (for model interpretation)
    let primaryTrainingSource: DataSource?
    
    /// Whether this feature vector includes Strava pattern augmentation
    let hasStravaAugmentation: Bool
    
    /// Completeness score (0-1, based on missing features)
    var completeness: Double {
        let mirror = Mirror(reflecting: self)
        let optionalProperties = mirror.children.filter { child in
            let value = child.value
            return String(describing: type(of: value)).contains("Optional")
        }
        
        let nonNilCount = optionalProperties.filter { child in
            let value = child.value
            let mirror = Mirror(reflecting: value)
            return mirror.displayStyle != .optional || mirror.children.count > 0
        }.count
        
        return Double(nonNilCount) / Double(max(optionalProperties.count, 1))
    }
    
    // MARK: - Conversion
    
    /// Convert to dictionary for storage
    func toDictionary() -> [String: Double] {
        var dict: [String: Double] = [:]
        
        // Physiological
        if let hrv = hrv { dict["hrv"] = hrv }
        if let hrvBaseline = hrvBaseline { dict["hrv_baseline"] = hrvBaseline }
        if let hrvDelta = hrvDelta { dict["hrv_delta"] = hrvDelta }
        if let hrvCoefficientOfVariation = hrvCoefficientOfVariation { dict["hrv_cv"] = hrvCoefficientOfVariation }
        if let rhr = rhr { dict["rhr"] = rhr }
        if let rhrBaseline = rhrBaseline { dict["rhr_baseline"] = rhrBaseline }
        if let rhrDelta = rhrDelta { dict["rhr_delta"] = rhrDelta }
        if let sleepDuration = sleepDuration { dict["sleep_duration"] = sleepDuration }
        if let sleepBaseline = sleepBaseline { dict["sleep_baseline"] = sleepBaseline }
        if let sleepDelta = sleepDelta { dict["sleep_delta"] = sleepDelta }
        if let respiratoryRate = respiratoryRate { dict["respiratory_rate"] = respiratoryRate }
        
        // Training load
        if let yesterdayStrain = yesterdayStrain { dict["yesterday_strain"] = yesterdayStrain }
        if let yesterdayTSS = yesterdayTSS { dict["yesterday_tss"] = yesterdayTSS }
        if let ctl = ctl { dict["ctl"] = ctl }
        if let atl = atl { dict["atl"] = atl }
        if let tsb = tsb { dict["tsb"] = tsb }
        if let acuteChronicRatio = acuteChronicRatio { dict["acute_chronic_ratio"] = acuteChronicRatio }
        if let trainingMonotony = trainingMonotony { dict["training_monotony"] = trainingMonotony }
        if let trainingStrain = trainingStrain { dict["training_strain"] = trainingStrain }
        
        // Recovery trends
        if let recoveryTrend7d = recoveryTrend7d { dict["recovery_trend_7d"] = recoveryTrend7d }
        if let recoveryTrend3d = recoveryTrend3d { dict["recovery_trend_3d"] = recoveryTrend3d }
        if let yesterdayRecovery = yesterdayRecovery { dict["yesterday_recovery"] = yesterdayRecovery }
        if let recoveryChange = recoveryChange { dict["recovery_change"] = recoveryChange }
        
        // Sleep trends
        if let sleepTrend7d = sleepTrend7d { dict["sleep_trend_7d"] = sleepTrend7d }
        if let sleepDebt7d = sleepDebt7d { dict["sleep_debt_7d"] = sleepDebt7d }
        if let sleepQualityScore = sleepQualityScore { dict["sleep_quality"] = sleepQualityScore }
        
        // Temporal
        dict["day_of_week"] = Double(dayOfWeek)
        if let daysSinceHardWorkout = daysSinceHardWorkout { dict["days_since_hard_workout"] = Double(daysSinceHardWorkout) }
        if let trainingBlockDay = trainingBlockDay { dict["training_block_day"] = Double(trainingBlockDay) }
        
        // Contextual
        if let alcoholDetected = alcoholDetected { dict["alcohol_detected"] = alcoholDetected ? 1.0 : 0.0 }
        if let illnessMarker = illnessMarker { dict["illness_marker"] = illnessMarker ? 1.0 : 0.0 }
        dict["month_of_year"] = Double(monthOfYear)
        
        // Pattern-based features
        if let stravaPatternCTLTrend = stravaPatternCTLTrend { dict["strava_pattern_ctl"] = stravaPatternCTLTrend }
        if let stravaPatternATLTrend = stravaPatternATLTrend { dict["strava_pattern_atl"] = stravaPatternATLTrend }
        if let stravaPatternTSBTrend = stravaPatternTSBTrend { dict["strava_pattern_tsb"] = stravaPatternTSBTrend }
        if let stravaPatternIntensityTrend = stravaPatternIntensityTrend { dict["strava_pattern_intensity"] = stravaPatternIntensityTrend }
        if let stravaPatternVolumeTrend = stravaPatternVolumeTrend { dict["strava_pattern_volume"] = stravaPatternVolumeTrend }
        
        return dict
    }
    
    /// Create MLFeatureVector from dictionary
    static func fromDictionary(_ dict: [String: Double]) throws -> MLFeatureVector {
        return MLFeatureVector(
            // Physiological
            hrv: dict["hrv"],
            hrvBaseline: dict["hrv_baseline"],
            hrvDelta: dict["hrv_delta"],
            hrvCoefficientOfVariation: dict["hrv_cv"],
            rhr: dict["rhr"],
            rhrBaseline: dict["rhr_baseline"],
            rhrDelta: dict["rhr_delta"],
            sleepDuration: dict["sleep_duration"],
            sleepBaseline: dict["sleep_baseline"],
            sleepDelta: dict["sleep_delta"],
            respiratoryRate: dict["respiratory_rate"],
            
            // Training load
            yesterdayStrain: dict["yesterday_strain"],
            yesterdayTSS: dict["yesterday_tss"],
            ctl: dict["ctl"],
            atl: dict["atl"],
            tsb: dict["tsb"],
            acuteChronicRatio: dict["acute_chronic_ratio"],
            trainingMonotony: dict["training_monotony"],
            trainingStrain: dict["training_strain"],
            
            // Recovery trends
            recoveryTrend7d: dict["recovery_trend_7d"],
            recoveryTrend3d: dict["recovery_trend_3d"],
            yesterdayRecovery: dict["yesterday_recovery"],
            recoveryChange: dict["recovery_change"],
            
            // Sleep trends
            sleepTrend7d: dict["sleep_trend_7d"],
            sleepDebt7d: dict["sleep_debt_7d"],
            sleepQualityScore: dict["sleep_quality"],
            
            // Temporal
            dayOfWeek: Int(dict["day_of_week"] ?? 1),
            daysSinceHardWorkout: dict["days_since_hard_workout"].map { Int($0) },
            trainingBlockDay: dict["training_block_day"].map { Int($0) },
            
            // Contextual
            alcoholDetected: dict["alcohol_detected"].map { $0 > 0.5 },
            illnessMarker: dict["illness_marker"].map { $0 > 0.5 },
            monthOfYear: Int(dict["month_of_year"] ?? 1),
            
            // Pattern-based features
            stravaPatternCTLTrend: dict["strava_pattern_ctl"],
            stravaPatternATLTrend: dict["strava_pattern_atl"],
            stravaPatternTSBTrend: dict["strava_pattern_tsb"],
            stravaPatternIntensityTrend: dict["strava_pattern_intensity"],
            stravaPatternVolumeTrend: dict["strava_pattern_volume"],
            
            timestamp: Date(), // Use current time for reconstructed vectors
            primaryTrainingSource: nil, // Not stored in dictionary
            hasStravaAugmentation: dict["strava_pattern_ctl"] != nil
        )
    }
    
    /// All feature names for Create ML
    static var allFeatureNames: [String] {
        return [
            // Physiological
            "hrv", "hrv_baseline", "hrv_delta", "hrv_cv",
            "rhr", "rhr_baseline", "rhr_delta",
            "sleep_duration", "sleep_baseline", "sleep_delta",
            "respiratory_rate",
            
            // Training load
            "yesterday_strain", "yesterday_tss",
            "ctl", "atl", "tsb", "acute_chronic_ratio",
            "training_monotony", "training_strain",
            
            // Recovery trends
            "recovery_trend_7d", "recovery_trend_3d",
            "yesterday_recovery", "recovery_change",
            
            // Sleep trends
            "sleep_trend_7d", "sleep_debt_7d", "sleep_quality",
            
            // Temporal
            "day_of_week", "days_since_hard_workout", "training_block_day",
            
            // Contextual
            "alcohol_detected", "illness_marker", "month_of_year",
            
            // Pattern-based features
            "strava_pattern_ctl", "strava_pattern_atl", "strava_pattern_tsb",
            "strava_pattern_intensity", "strava_pattern_volume"
        ]
    }
}

// MARK: - Training Data Point

/// Complete training data point with features and targets
struct MLTrainingDataPoint {
    /// Feature vector for this day
    let features: MLFeatureVector
    
    /// Target: Tomorrow's recovery score (what we're predicting)
    let targetRecovery: Double
    
    /// Target: Tomorrow's readiness score
    let targetReadiness: Double
    
    /// Data quality (0-1)
    let dataQuality: Double
    
    /// Whether this is valid for training (no missing critical features)
    var isValidForTraining: Bool {
        // Require minimum completeness and critical features
        return dataQuality >= 0.7 &&
               features.hrv != nil &&
               features.rhr != nil &&
               features.sleepDuration != nil &&
               targetRecovery > 0
    }
}

// MARK: - Training Dataset

/// Collection of training data points
struct MLTrainingDataset {
    let dataPoints: [MLTrainingDataPoint]
    let startDate: Date
    let endDate: Date
    let totalDays: Int
    let validDays: Int
    
    var completeness: Double {
        Double(validDays) / Double(max(totalDays, 1))
    }
    
    /// Filter to only valid training data
    var validDataPoints: [MLTrainingDataPoint] {
        dataPoints.filter { $0.isValidForTraining }
    }
    
    /// Split into training and validation sets
    func trainTestSplit(testRatio: Double = 0.2) -> (train: [MLTrainingDataPoint], test: [MLTrainingDataPoint]) {
        let valid = validDataPoints
        let testSize = Int(Double(valid.count) * testRatio)
        let trainSize = valid.count - testSize
        
        let train = Array(valid.prefix(trainSize))
        let test = Array(valid.suffix(testSize))
        
        return (train, test)
    }
}
