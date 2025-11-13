import Foundation

/// Filters data sources based on ML ingestibility and API compliance
/// Ensures VeloReady complies with provider API terms while maximizing ML capabilities
class MLDataSourceFilter {
    
    // MARK: - Data Source Classification
    
    /// Get data sources that can be directly ingested for ML training
    /// Returns sources where raw data can be used per API terms
    static func ingestibleSources() -> [DataSource] {
        return DataSource.allCases.filter { $0.isMLIngestible }
    }
    
    /// Get data sources that can only be used for pattern analysis
    /// These sources provide metadata/patterns but raw data cannot be ingested
    static func patternOnlySources() -> [DataSource] {
        return DataSource.allCases.filter {
            $0.supportsPatternAnalysis && !$0.isMLIngestible
        }
    }
    
    /// Get all ML-eligible sources (either ingestible or pattern-supporting)
    static func mlEligibleSources() -> [DataSource] {
        return DataSource.allCases.filter {
            $0.isMLIngestible || $0.supportsPatternAnalysis
        }
    }
    
    // MARK: - Activity Filtering
    
    /// Filter activities for ML training dataset
    /// Only returns activities from sources that allow raw data ingestion
    static func filterActivitiesForMLTraining(_ activities: [UnifiedActivity]) -> [UnifiedActivity] {
        let ingestible = Set(ingestibleSources())
        
        return activities.filter { activity in
            // Convert UnifiedActivity.ActivitySource to DataSource
            let dataSource = mapActivitySourceToDataSource(activity.source)
            return ingestible.contains(dataSource)
        }
    }
    
    /// Get activities for pattern analysis only (e.g., Strava)
    static func filterActivitiesForPatternAnalysis(_ activities: [UnifiedActivity]) -> [UnifiedActivity] {
        let patternOnly = Set(patternOnlySources())
        
        return activities.filter { activity in
            let dataSource = mapActivitySourceToDataSource(activity.source)
            return patternOnly.contains(dataSource)
        }
    }
    
    // MARK: - Wellness Data Filtering
    
    /// Filter wellness data for ML training
    /// Wellness data typically comes from HealthKit (always ingestible)
    static func filterWellnessDataForMLTraining(_ wellnessData: [WellnessData]) -> [WellnessData] {
        let ingestible = Set(ingestibleSources())
        
        return wellnessData.filter { data in
            ingestible.contains(data.source)
        }
    }
    
    // MARK: - Pattern Feature Extraction
    
    /// Extract pattern features from non-ingestible sources
    /// Calculates aggregate metrics that comply with API terms (e.g., Strava)
    static func extractPatternFeatures(
        from activities: [UnifiedActivity],
        forSource source: DataSource
    ) -> [MLPatternFeature] {
        guard source.supportsPatternAnalysis && !source.isMLIngestible else {
            return []
        }
        
        // Filter to this source only
        let sourceActivities = activities.filter {
            mapActivitySourceToDataSource($0.source) == source
        }
        
        guard !sourceActivities.isEmpty else {
            return []
        }
        
        var features: [MLPatternFeature] = []
        
        // Calculate CTL trend (aggregate metric - compliant)
        if let ctlTrend = calculateCTLTrend(from: sourceActivities) {
            features.append(MLPatternFeature(
                type: .trainingLoadTrend,
                source: source,
                value: ctlTrend,
                isDirectIngestion: false,
                calculationDate: Date()
            ))
        }
        
        // Calculate ATL trend (7-day average)
        if let atlTrend = calculateATLTrend(from: sourceActivities) {
            features.append(MLPatternFeature(
                type: .acuteLoadTrend,
                source: source,
                value: atlTrend,
                isDirectIngestion: false,
                calculationDate: Date()
            ))
        }
        
        // Calculate TSB trend
        if let tsbTrend = calculateTSBTrend(from: sourceActivities) {
            features.append(MLPatternFeature(
                type: .stressBalanceTrend,
                source: source,
                value: tsbTrend,
                isDirectIngestion: false,
                calculationDate: Date()
            ))
        }
        
        // Calculate intensity trend
        if let intensityTrend = calculateIntensityTrend(from: sourceActivities) {
            features.append(MLPatternFeature(
                type: .intensityTrend,
                source: source,
                value: intensityTrend,
                isDirectIngestion: false,
                calculationDate: Date()
            ))
        }
        
        // Calculate volume trend (hours per week)
        if let volumeTrend = calculateVolumeTrend(from: sourceActivities) {
            features.append(MLPatternFeature(
                type: .volumeTrend,
                source: source,
                value: volumeTrend,
                isDirectIngestion: false,
                calculationDate: Date()
            ))
        }
        
        return features
    }
    
    // MARK: - Pattern Calculation Helpers
    
    /// Calculate CTL trend from activity metadata (not raw streams)
    /// Uses aggregate metrics: TSS from each activity (which is derived from metadata)
    private static func calculateCTLTrend(from activities: [UnifiedActivity]) -> Double? {
        // Get activities with TSS
        let activitiesWithTSS = activities.compactMap { activity -> (date: Date, tss: Double)? in
            guard let tss = activity.tss else { return nil }
            return (activity.startDate, tss)
        }
        
        guard activitiesWithTSS.count >= 7 else { return nil }
        
        // Sort by date
        let sorted = activitiesWithTSS.sorted { $0.date < $1.date }
        
        // Calculate 42-day exponentially weighted average
        let decay = 0.976 // CTL decay factor (42 days)
        var ctl: Double = 0
        
        for (_, tss) in sorted {
            ctl = ctl * decay + tss * (1 - decay)
        }
        
        return ctl
    }
    
    /// Calculate ATL trend (7-day average)
    private static func calculateATLTrend(from activities: [UnifiedActivity]) -> Double? {
        let activitiesWithTSS = activities.compactMap { $0.tss }
        guard activitiesWithTSS.count >= 7 else { return nil }
        
        let recent = Array(activitiesWithTSS.suffix(7))
        let totalTSS = recent.reduce(0, +)
        return totalTSS / 7.0
    }
    
    /// Calculate TSB trend (Training Stress Balance)
    private static func calculateTSBTrend(from activities: [UnifiedActivity]) -> Double? {
        guard let ctl = calculateCTLTrend(from: activities),
              let atl = calculateATLTrend(from: activities) else {
            return nil
        }
        return ctl - atl
    }
    
    /// Calculate intensity trend (average IF over last 14 days)
    private static func calculateIntensityTrend(from activities: [UnifiedActivity]) -> Double? {
        let recent = activities.suffix(14).compactMap { $0.intensityFactor }
        guard !recent.isEmpty else { return nil }
        return recent.reduce(0, +) / Double(recent.count)
    }
    
    /// Calculate volume trend (hours per week over last 4 weeks)
    private static func calculateVolumeTrend(from activities: [UnifiedActivity]) -> Double? {
        let fourWeeksAgo = Calendar.current.date(byAdding: .day, value: -28, to: Date())!
        let recentActivities = activities.filter { $0.startDate >= fourWeeksAgo }
        
        guard !recentActivities.isEmpty else { return nil }
        
        let totalDuration = recentActivities.compactMap { $0.duration }.reduce(0, +)
        let totalHours = totalDuration / 3600 // Convert seconds to hours
        return totalHours / 4.0 // Average per week
    }
    
    // MARK: - Helper Methods
    
    /// Map UnifiedActivity.ActivitySource to DataSource
    private static func mapActivitySourceToDataSource(_ source: UnifiedActivity.ActivitySource) -> DataSource {
        switch source {
        case .intervalsICU:
            return .intervalsICU
        case .strava:
            return .strava
        case .appleHealth:
            return .appleHealth
        }
    }
}

// MARK: - Pattern Feature Model

/// Represents a pattern-based ML feature (not raw data ingestion)
/// Used for sources like Strava where raw data cannot be stored/trained
struct MLPatternFeature {
    enum FeatureType: String {
        case trainingLoadTrend    // CTL
        case acuteLoadTrend       // ATL
        case stressBalanceTrend   // TSB
        case intensityTrend       // Average IF
        case volumeTrend          // Hours per week
        case recoveryPattern      // Recovery frequency
    }
    
    let type: FeatureType
    let source: DataSource
    let value: Double
    let isDirectIngestion: Bool  // Always false for pattern features
    let calculationDate: Date
    
    /// Description for debugging/logging
    var description: String {
        return "\(type.rawValue) from \(source.displayName): \(String(format: "%.2f", value))"
    }
}

// MARK: - Wellness Data Model Extension

/// Placeholder for WellnessData - define if not already exists
struct WellnessData {
    let source: DataSource
    let date: Date
    let hrv: Double?
    let rhr: Double?
    let sleepDuration: Double?
    let respiratoryRate: Double?
    let recoveryScore: Double?  // Added for ML target prediction
}

