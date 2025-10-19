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
    
    // MARK: - Data Quality
    
    /// Timestamp when features were extracted
    let timestamp: Date
    
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
        
        return dict
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
