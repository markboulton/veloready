import Foundation

/// Provider-specific rate limit configurations
/// Each external API provider has different rate limits that must be respected
struct ProviderRateLimitConfig {
    let provider: DataSource
    let maxRequestsPer15Min: Int?
    let maxRequestsPerHour: Int?
    let maxRequestsPerDay: Int?
    let windowDuration: TimeInterval // Primary window (seconds)
    
    /// Get all configured providers
    static let allProviders: [ProviderRateLimitConfig] = [
        .strava,
        .intervalsICU,
        .appleHealth,
        // Future: .wahoo, .garmin
    ]
    
    /// Strava API limits (official documentation)
    /// https://developers.strava.com/docs/rate-limits/
    static let strava = ProviderRateLimitConfig(
        provider: .strava,
        maxRequestsPer15Min: 100,   // 100 requests per 15 minutes
        maxRequestsPerHour: nil,     // Not specified
        maxRequestsPerDay: 1000,     // 1000 requests per day
        windowDuration: 900          // 15 minutes primary window
    )
    
    /// Intervals.icu API limits
    /// Note: Unofficial limits based on observation - adjust as needed
    static let intervalsICU = ProviderRateLimitConfig(
        provider: .intervalsICU,
        maxRequestsPer15Min: 100,    // Conservative estimate
        maxRequestsPerHour: 200,     // Conservative estimate
        maxRequestsPerDay: 2000,     // Conservative estimate
        windowDuration: 900          // 15 minutes primary window
    )
    
    /// Apple Health (HealthKit) - no external rate limits
    /// On-device API with no network calls
    static let appleHealth = ProviderRateLimitConfig(
        provider: .appleHealth,
        maxRequestsPer15Min: nil,    // No limits (local API)
        maxRequestsPerHour: nil,
        maxRequestsPerDay: nil,
        windowDuration: 60           // Nominal window for consistency
    )
    
    // MARK: - Future Providers
    
    /// Wahoo API limits
    /// TODO: Research official Wahoo API documentation
    static let wahoo = ProviderRateLimitConfig(
        provider: .strava, // Placeholder - will be .wahoo when added to DataSource
        maxRequestsPer15Min: 60,     // TODO: Confirm with Wahoo docs
        maxRequestsPerHour: 200,     // TODO: Confirm with Wahoo docs
        maxRequestsPerDay: 1440,     // TODO: Confirm with Wahoo docs
        windowDuration: 900          // 15 minutes
    )
    
    /// Garmin Connect API limits
    /// TODO: Research official Garmin Connect API documentation
    static let garmin = ProviderRateLimitConfig(
        provider: .strava, // Placeholder - will be .garmin when added to DataSource
        maxRequestsPer15Min: 250,    // TODO: Confirm with Garmin docs
        maxRequestsPerHour: 1000,    // 1000 requests per hour (estimated)
        maxRequestsPerDay: 10000,    // 10000 requests per day (estimated)
        windowDuration: 3600         // 1 hour primary window
    )
    
    // MARK: - Helper Methods
    
    /// Get configuration for a specific provider
    static func forProvider(_ provider: DataSource) -> ProviderRateLimitConfig {
        switch provider {
        case .strava:
            return .strava
        case .intervalsICU:
            return .intervalsICU
        case .appleHealth:
            return .appleHealth
        // Future:
        // case .wahoo:
        //     return .wahoo
        // case .garmin:
        //     return .garmin
        }
    }
    
    /// Check if this provider has rate limits
    var hasRateLimits: Bool {
        return maxRequestsPer15Min != nil ||
               maxRequestsPerHour != nil ||
               maxRequestsPerDay != nil
    }
    
    /// Get display string for monitoring
    var displayString: String {
        var parts: [String] = []
        
        if let per15Min = maxRequestsPer15Min {
            parts.append("\(per15Min)/15min")
        }
        if let perHour = maxRequestsPerHour {
            parts.append("\(perHour)/hour")
        }
        if let perDay = maxRequestsPerDay {
            parts.append("\(perDay)/day")
        }
        
        if parts.isEmpty {
            return "No limits (local API)"
        }
        
        return parts.joined(separator: ", ")
    }
}

/// Rate limit window type for tracking
enum RateLimitWindow {
    case fifteenMinute
    case hourly
    case daily
    
    var duration: TimeInterval {
        switch self {
        case .fifteenMinute: return 900    // 15 minutes
        case .hourly: return 3600          // 1 hour
        case .daily: return 86400          // 24 hours
        }
    }
    
    var redisKeySuffix: String {
        switch self {
        case .fifteenMinute: return "15min"
        case .hourly: return "hour"
        case .daily: return "day"
        }
    }
    
    /// Calculate current window ID
    var currentWindow: Int {
        return Int(Date().timeIntervalSince1970 / duration)
    }
}

