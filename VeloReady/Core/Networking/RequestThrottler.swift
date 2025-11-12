import Foundation

/// Client-side request throttler to prevent overwhelming the backend and external APIs
/// Implements provider-aware rate limiting with sliding window algorithm
///
/// Supports two modes:
/// 1. Legacy endpoint-based limits (for backwards compatibility)
/// 2. Provider-specific limits (respects each API's rate limits)
///
/// Thread-safe via Swift actor model
actor RequestThrottler {
    // MARK: - Singleton
    static let shared = RequestThrottler()

    // MARK: - Configuration

    /// Legacy rate limit definitions per endpoint (for backwards compatibility)
    private enum EndpointRateLimit {
        case activities
        case streams
        case `default`

        var maxRequests: Int {
            switch self {
            case .activities: return 10
            case .streams: return 20
            case .default: return 30
            }
        }

        var windowDuration: TimeInterval {
            return 60 // 1 minute window for all limits
        }

        /// Get limit type from endpoint path
        static func from(endpoint: String) -> EndpointRateLimit {
            if endpoint.contains("/activities") {
                return .activities
            } else if endpoint.contains("/streams") {
                return .streams
            } else {
                return .default
            }
        }
    }

    // MARK: - State

    /// Track timestamps of requests per endpoint (legacy)
    /// Key: endpoint path, Value: array of request timestamps
    private var requestTimestamps: [String: [Date]] = [:]
    
    /// Track timestamps per provider and window
    /// Key: "{provider}:{window}", Value: array of request timestamps
    private var providerTimestamps: [String: [Date]] = [:]

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods
    
    /// Check if a request for a specific provider should be allowed (NEW: Provider-aware)
    /// - Parameters:
    ///   - provider: The data source provider (e.g., .strava, .intervalsICU)
    ///   - endpoint: Optional endpoint context for logging
    /// - Returns: Tuple with (allowed, retryAfter, reason)
    func shouldAllowRequest(
        provider: DataSource,
        endpoint: String? = nil
    ) async -> (allowed: Bool, retryAfter: TimeInterval?, reason: String?) {
        let config = ProviderRateLimitConfig.forProvider(provider)
        
        // If no rate limits, always allow (e.g., HealthKit)
        guard config.hasRateLimits else {
            Logger.debug("✅ [RequestThrottler] Allowing \(provider) - no rate limits")
            return (allowed: true, retryAfter: nil, reason: nil)
        }
        
        let now = Date()
        
        // Check all applicable windows for this provider
        var violations: [(window: RateLimitWindow, remaining: Int, retryAfter: TimeInterval)] = []
        
        // Check 15-minute window if applicable
        if let max15Min = config.maxRequestsPer15Min {
            let (allowed, remaining, retryAfter) = checkWindow(
                provider: provider,
                window: .fifteenMinute,
                maxRequests: max15Min,
                now: now
            )
            if !allowed {
                violations.append((window: .fifteenMinute, remaining: remaining, retryAfter: retryAfter))
            }
        }
        
        // Check hourly window if applicable
        if let maxHour = config.maxRequestsPerHour {
            let (allowed, remaining, retryAfter) = checkWindow(
                provider: provider,
                window: .hourly,
                maxRequests: maxHour,
                now: now
            )
            if !allowed {
                violations.append((window: .hourly, remaining: remaining, retryAfter: retryAfter))
            }
        }
        
        // Check daily window if applicable
        if let maxDay = config.maxRequestsPerDay {
            let (allowed, remaining, retryAfter) = checkWindow(
                provider: provider,
                window: .daily,
                maxRequests: maxDay,
                now: now
            )
            if !allowed {
                violations.append((window: .daily, remaining: remaining, retryAfter: retryAfter))
            }
        }
        
        // If any window is violated, deny request
        if !violations.isEmpty {
            let shortestRetry = violations.min(by: { $0.retryAfter < $1.retryAfter })!
            let reason = "Rate limit exceeded for \(provider): \(violations.map { "\($0.remaining) left in \($0.window)" }.joined(separator: ", "))"
            
            Logger.warning("⏱️ [RequestThrottler] \(reason)")
            Logger.debug("⏱️ [RequestThrottler] Retry after: \(Int(shortestRetry.retryAfter))s")
            
            // Log violation to monitor
            Task { @MainActor in
                RateLimitMonitor.shared.logViolation(
                    provider: provider,
                    endpoint: endpoint,
                    retryAfter: shortestRetry.retryAfter,
                    reason: reason
                )
            }
            
            return (allowed: false, retryAfter: shortestRetry.retryAfter, reason: reason)
        }
        
        // All windows pass - record request and allow
        recordRequest(provider: provider, windows: [.fifteenMinute, .hourly, .daily], now: now)
        
        let endpointStr = endpoint.map { " (\($0))" } ?? ""
        Logger.debug("✅ [RequestThrottler] Allowing \(provider)\(endpointStr)")
        
        // Log successful request to monitor
        Task { @MainActor in
            RateLimitMonitor.shared.logSuccessfulRequest(provider: provider, endpoint: endpoint)
        }
        
        return (allowed: true, retryAfter: nil, reason: nil)
    }

    /// Check if a request to the given endpoint should be allowed (LEGACY: Endpoint-based)
    /// - Parameter endpoint: The API endpoint path (e.g., "/api/activities")
    /// - Returns: Tuple with (allowed, retryAfter) where retryAfter is seconds to wait if not allowed
    func shouldAllowRequest(endpoint: String) async -> (allowed: Bool, retryAfter: TimeInterval?) {
        let limit = EndpointRateLimit.from(endpoint: endpoint)
        let now = Date()
        let windowStart = now.addingTimeInterval(-limit.windowDuration)

        // Get or initialize timestamps for this endpoint
        var timestamps = requestTimestamps[endpoint] ?? []

        // Filter to only timestamps within the current window (last 60 seconds)
        timestamps = timestamps.filter { $0 > windowStart }

        // Check if we're at or over the limit
        if timestamps.count >= limit.maxRequests {
            // Calculate retry-after based on oldest timestamp
            let oldestTimestamp = timestamps.first ?? now
            let retryAfter = limit.windowDuration - now.timeIntervalSince(oldestTimestamp)

            Logger.warning("⏱️ [RequestThrottler] Throttling \(endpoint) - \(timestamps.count)/\(limit.maxRequests) requests in window")
            Logger.debug("⏱️ [RequestThrottler] Retry after: \(Int(retryAfter))s")

            return (allowed: false, retryAfter: max(0, retryAfter))
        }

        // Allow request and append timestamp
        timestamps.append(now)
        requestTimestamps[endpoint] = timestamps

        Logger.debug("✅ [RequestThrottler] Allowing \(endpoint) - \(timestamps.count)/\(limit.maxRequests) requests in window")

        return (allowed: true, retryAfter: nil)
    }

    /// Reset throttle state for a specific endpoint
    /// Useful for testing or manual override
    /// - Parameter endpoint: The endpoint to reset (if nil, resets all)
    func reset(endpoint: String? = nil) {
        if let endpoint = endpoint {
            requestTimestamps[endpoint] = []
            Logger.debug("🔄 [RequestThrottler] Reset throttle state for \(endpoint)")
        } else {
            requestTimestamps.removeAll()
            Logger.debug("🔄 [RequestThrottler] Reset all throttle state")
        }
    }

    /// Get current request count for an endpoint (for debugging/monitoring)
    /// - Parameter endpoint: The endpoint to check
    /// - Returns: Number of requests in current window
    func getCurrentCount(endpoint: String) -> Int {
        let limit = EndpointRateLimit.from(endpoint: endpoint)
        let now = Date()
        let windowStart = now.addingTimeInterval(-limit.windowDuration)

        let timestamps = requestTimestamps[endpoint] ?? []
        let activeTimestamps = timestamps.filter { $0 > windowStart }

        return activeTimestamps.count
    }

    /// Get remaining requests allowed for an endpoint
    /// - Parameter endpoint: The endpoint to check
    /// - Returns: Number of requests remaining in current window
    func getRemainingRequests(endpoint: String) -> Int {
        let limit = EndpointRateLimit.from(endpoint: endpoint)
        let currentCount = getCurrentCount(endpoint: endpoint)
        return max(0, limit.maxRequests - currentCount)
    }
    
    // MARK: - Provider-Specific Methods
    
    /// Check a specific window for rate limit
    /// - Returns: (allowed, remaining, retryAfter)
    private func checkWindow(
        provider: DataSource,
        window: RateLimitWindow,
        maxRequests: Int,
        now: Date
    ) -> (allowed: Bool, remaining: Int, retryAfter: TimeInterval) {
        let key = "\(provider.rawValue):\(window.redisKeySuffix)"
        let windowStart = now.addingTimeInterval(-window.duration)
        
        // Get timestamps for this provider/window
        var timestamps = providerTimestamps[key] ?? []
        
        // Filter to only timestamps within the current window
        timestamps = timestamps.filter { $0 > windowStart }
        
        let remaining = max(0, maxRequests - timestamps.count)
        
        if timestamps.count >= maxRequests {
            // Calculate retry-after based on oldest timestamp
            let oldestTimestamp = timestamps.first ?? now
            let retryAfter = window.duration - now.timeIntervalSince(oldestTimestamp)
            return (allowed: false, remaining: 0, retryAfter: max(0, retryAfter))
        }
        
        return (allowed: true, remaining: remaining, retryAfter: 0)
    }
    
    /// Record a request across multiple windows
    private func recordRequest(provider: DataSource, windows: [RateLimitWindow], now: Date) {
        for window in windows {
            let key = "\(provider.rawValue):\(window.redisKeySuffix)"
            var timestamps = providerTimestamps[key] ?? []
            
            // Clean old timestamps and add new one
            let windowStart = now.addingTimeInterval(-window.duration)
            timestamps = timestamps.filter { $0 > windowStart }
            timestamps.append(now)
            
            providerTimestamps[key] = timestamps
        }
    }
    
    /// Get rate limit status for a provider (for monitoring/debugging)
    func getProviderStatus(provider: DataSource) -> ProviderRateLimitStatus {
        let config = ProviderRateLimitConfig.forProvider(provider)
        let now = Date()
        
        var status = ProviderRateLimitStatus(provider: provider)
        
        // Check 15-minute window
        if let max15Min = config.maxRequestsPer15Min {
            let (_, remaining, _) = checkWindow(
                provider: provider,
                window: .fifteenMinute,
                maxRequests: max15Min,
                now: now
            )
            status.remaining15Min = remaining
            status.max15Min = max15Min
        }
        
        // Check hourly window
        if let maxHour = config.maxRequestsPerHour {
            let (_, remaining, _) = checkWindow(
                provider: provider,
                window: .hourly,
                maxRequests: maxHour,
                now: now
            )
            status.remainingHour = remaining
            status.maxHour = maxHour
        }
        
        // Check daily window
        if let maxDay = config.maxRequestsPerDay {
            let (_, remaining, _) = checkWindow(
                provider: provider,
                window: .daily,
                maxRequests: maxDay,
                now: now
            )
            status.remainingDay = remaining
            status.maxDay = maxDay
        }
        
        return status
    }
    
    /// Reset throttle state for a specific provider
    func reset(provider: DataSource) {
        let providerKey = provider.rawValue
        
        // Remove all keys for this provider
        providerTimestamps = providerTimestamps.filter { !$0.key.starts(with: providerKey) }
        
        Logger.debug("🔄 [RequestThrottler] Reset throttle state for \(provider)")
    }
}

// MARK: - Status Models

/// Rate limit status for a provider (for monitoring)
struct ProviderRateLimitStatus {
    let provider: DataSource
    var remaining15Min: Int?
    var max15Min: Int?
    var remainingHour: Int?
    var maxHour: Int?
    var remainingDay: Int?
    var maxDay: Int?
    
    var displayString: String {
        var parts: [String] = []
        
        if let remaining = remaining15Min, let max = max15Min {
            parts.append("15min: \(remaining)/\(max)")
        }
        if let remaining = remainingHour, let max = maxHour {
            parts.append("hour: \(remaining)/\(max)")
        }
        if let remaining = remainingDay, let max = maxDay {
            parts.append("day: \(remaining)/\(max)")
        }
        
        if parts.isEmpty {
            return "\(provider): No limits"
        }
        
        return "\(provider): " + parts.joined(separator: ", ")
    }
}
