import Foundation

/// Type-safe cache key system with built-in TTL configuration
///
/// **Purpose:**
/// Eliminates string-based cache keys and provides compiler-enforced consistency.
/// Each cache key type has a predefined TTL that matches its data volatility.
///
/// **Benefits:**
/// - Compiler errors on typos (not runtime cache misses)
/// - Single source of truth for key formats
/// - Automatic TTL management per data type
/// - Easy to refactor (find all usages)
/// - Self-documenting code
///
/// **Usage:**
/// ```swift
/// // Backward compatible with old string-based API
/// let key = CacheKey.stravaActivities(daysBack: 365)  // Returns String
/// let ttl = CacheTTL.activities
///
/// // Or use enum cases for type-safe access
/// let cacheKey = CacheKey.stravaActivities(daysBack: 365)
/// ```
///
/// **Key Format Convention:**
/// All keys follow the pattern: `source:type:identifier`
/// - Source: strava, intervals, healthkit, score, baseline
/// - Type: activities, streams, hrv, recovery, etc.
/// - Identifier: numeric ID, date string, or parameter
///
/// **TTL Strategy:**
/// - Activities: 1 hour (frequently updated)
/// - Streams: 7 days (immutable after creation)
/// - Health metrics: 5 minutes (real-time data)
/// - Scores: 48 hours (calculated daily)
/// - Baselines: 1 hour (7-day rolling average)
/// - Wellness: 10 minutes (daily manual entry)
enum CacheKey {
    
    // MARK: - Activities (Static Methods for Backward Compatibility)
    
    /// Strava activities from the last N days
    /// - Parameter daysBack: Number of days to fetch (90, 180, 365)
    /// - Returns: Cache key string: `strava:activities:{daysBack}`
    static func stravaActivities(daysBack: Int) -> String {
        return "strava:activities:\(daysBack)"
    }
    
    /// Intervals.icu activities from the last N days
    /// - Parameter daysBack: Number of days to fetch (90, 180, 365)
    /// - Returns: Cache key string: `intervals:activities:{daysBack}`
    static func intervalsActivities(daysBack: Int) -> String {
        return "intervals:activities:\(daysBack)"
    }
    
    // MARK: - Streams
    
    /// Activity stream data (power, HR, cadence, altitude)
    /// - Parameters:
    ///   - activityId: Unique activity identifier
    ///   - source: Data source (strava, intervals)
    /// - Returns: Cache key string: `stream:{source}_{activityId}`
    static func activityStreams(activityId: String, source: String) -> String {
        return "\(source):streams:\(activityId)"
    }
    
    // MARK: - Scores
    
    /// Recovery score for a specific date
    /// - Parameter date: Date (normalized to start of day)
    /// - Returns: Cache key string: `score:recovery:{ISO8601Date}`
    static func recoveryScore(date: Date) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateString = ISO8601DateFormatter().string(from: startOfDay)
        return "score:recovery:\(dateString)"
    }
    
    /// Sleep score for a specific date
    /// - Parameter date: Date (normalized to start of day)
    /// - Returns: Cache key string: `score:sleep:{ISO8601Date}`
    static func sleepScore(date: Date) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateString = ISO8601DateFormatter().string(from: startOfDay)
        return "score:sleep:\(dateString)"
    }
    
    /// Strain score for a specific date
    /// - Parameter date: Date (normalized to start of day)
    /// - Returns: Cache key string: `score:strain:{ISO8601Date}`
    static func strainScore(date: Date) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateString = ISO8601DateFormatter().string(from: startOfDay)
        return "score:strain:\(dateString)"
    }
    
    // MARK: - Baselines
    
    /// HRV baseline (7-day rolling average)
    /// - Returns: Cache key string: `baseline:hrv:7day`
    static var baselineHRV: String {
        return "baseline:hrv:7day"
    }
    
    /// Resting heart rate baseline (7-day rolling average)
    /// - Returns: Cache key string: `baseline:rhr:7day`
    static var baselineRHR: String {
        return "baseline:rhr:7day"
    }
    
    /// Sleep duration baseline (7-day rolling average)
    /// - Returns: Cache key string: `baseline:sleep:7day`
    static var baselineSleep: String {
        return "baseline:sleep:7day"
    }
    
    // MARK: - HealthKit
    
    /// Heart rate variability for a specific date
    /// - Parameter date: Date (will be normalized to start of day)
    /// - Returns: Cache key string: `healthkit:hrv:{ISO8601Date}`
    static func hrv(date: Date) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateString = ISO8601DateFormatter().string(from: startOfDay)
        return "healthkit:hrv:\(dateString)"
    }
    
    /// Resting heart rate for a specific date
    /// - Parameter date: Date (will be normalized to start of day)
    /// - Returns: Cache key string: `healthkit:rhr:{ISO8601Date}`
    static func rhr(date: Date) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateString = ISO8601DateFormatter().string(from: startOfDay)
        return "healthkit:rhr:\(dateString)"
    }
    
    /// Sleep analysis for a specific date
    /// - Parameter date: Date (will be normalized to start of day)
    /// - Returns: Cache key string: `healthkit:sleep:{ISO8601Date}`
    static func sleep(date: Date) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateString = ISO8601DateFormatter().string(from: startOfDay)
        return "healthkit:sleep:\(dateString)"
    }
    
    // MARK: - Wellness
    
    /// Intervals.icu wellness data (last N days)
    /// - Parameter days: Number of days to fetch
    /// - Returns: Cache key string: `intervals:wellness:{days}`
    static func intervalsWellness(days: Int) -> String {
        return "intervals:wellness:\(days)"
    }
    
    // MARK: - Illness
    
    /// Illness detection indicator for a specific date
    /// - Parameter date: Date (normalized to start of day)
    /// - Returns: Cache key string: `illness:detection:v3:{ISO8601Date}`
    /// - Note: v3 = Fixed respiratory rate false positive
    static func illnessDetection(date: Date) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateString = ISO8601DateFormatter().string(from: startOfDay)
        return "illness:detection:v3:\(dateString)"
    }
    
    
    // MARK: - Validation
    
    /// Validate cache key format (for migration/debugging)
    /// Expected format: `source:type:identifier`
    static func validate(_ key: String) -> Bool {
        let pattern = "^[a-z]+:[a-z]+:[a-zA-Z0-9-:_]+$"
        return key.range(of: pattern, options: .regularExpression) != nil
    }
}

