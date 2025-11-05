import Foundation

/// Client-side request throttler to prevent overwhelming the backend
/// Implements per-endpoint rate limiting with sliding window algorithm
///
/// Rate limits:
/// - Activities: 10 requests/minute
/// - Streams: 20 requests/minute
/// - Default: 30 requests/minute
///
/// Thread-safe via Swift actor model
actor RequestThrottler {
    // MARK: - Singleton
    static let shared = RequestThrottler()

    // MARK: - Configuration

    /// Rate limit definitions per endpoint
    private enum RateLimit {
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
        static func from(endpoint: String) -> RateLimit {
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

    /// Track timestamps of requests per endpoint
    /// Key: endpoint path, Value: array of request timestamps
    private var requestTimestamps: [String: [Date]] = [:]

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Check if a request to the given endpoint should be allowed
    /// - Parameter endpoint: The API endpoint path (e.g., "/api/activities")
    /// - Returns: Tuple with (allowed, retryAfter) where retryAfter is seconds to wait if not allowed
    func shouldAllowRequest(endpoint: String) async -> (allowed: Bool, retryAfter: TimeInterval?) {
        let limit = RateLimit.from(endpoint: endpoint)
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
        let limit = RateLimit.from(endpoint: endpoint)
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
        let limit = RateLimit.from(endpoint: endpoint)
        let currentCount = getCurrentCount(endpoint: endpoint)
        return max(0, limit.maxRequests - currentCount)
    }
}
