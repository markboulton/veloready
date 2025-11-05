import Foundation

/// Exponential backoff retry policy for network requests
/// Implements intelligent retry logic with exponential delays
///
/// Retry behavior:
/// - Max 3 retries per endpoint
/// - Exponential delays: 1s, 2s, 4s
/// - Resets after 5 minutes of no failures
/// - Thread-safe via Swift actor model
///
/// Note: This is separate from NetworkClient's RetryPolicy struct
actor ExponentialBackoffRetryPolicy {
    // MARK: - Singleton
    static let shared = ExponentialBackoffRetryPolicy()

    // MARK: - Configuration

    /// Maximum number of retry attempts
    private let maxRetries = 3

    /// Time window after which failure count resets
    private let resetWindow: TimeInterval = 300 // 5 minutes

    // MARK: - State

    /// Track failure count per endpoint
    /// Key: endpoint path, Value: number of consecutive failures
    private var failureCounts: [String: Int] = [:]

    /// Track last failure time per endpoint
    /// Key: endpoint path, Value: timestamp of last failure
    private var lastFailures: [String: Date] = [:]

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Check if a request should be retried after failure
    /// - Parameters:
    ///   - endpoint: The API endpoint path (e.g., "/api/activities")
    ///   - error: The error that occurred
    /// - Returns: Tuple with (retry, delay) where delay is seconds to wait before retry
    func shouldRetry(endpoint: String, error: Error) async -> (retry: Bool, delay: TimeInterval) {
        let now = Date()

        // Check if we should reset the failure count (>5 minutes since last failure)
        if let lastFailure = lastFailures[endpoint] {
            let timeSinceLastFailure = now.timeIntervalSince(lastFailure)
            if timeSinceLastFailure > resetWindow {
                Logger.debug("🔄 [RetryPolicy] Resetting failure count for \(endpoint) (>5 min since last failure)")
                failureCounts[endpoint] = 0
            }
        }

        // Get current failure count
        let failureCount = failureCounts[endpoint] ?? 0

        // Check if we've exceeded max retries
        if failureCount >= maxRetries {
            Logger.warning("⚠️ [RetryPolicy] Max retries (\(maxRetries)) reached for \(endpoint)")
            return (retry: false, delay: 0)
        }

        // Check if error is retryable
        guard isRetryableError(error) else {
            Logger.debug("🚫 [RetryPolicy] Error is not retryable for \(endpoint): \(error)")
            return (retry: false, delay: 0)
        }

        // Calculate exponential backoff delay: 2^failureCount
        // Attempt 1: 2^0 = 1s
        // Attempt 2: 2^1 = 2s
        // Attempt 3: 2^2 = 4s
        let delay = pow(2.0, Double(failureCount))

        // Increment failure count
        failureCounts[endpoint] = failureCount + 1
        lastFailures[endpoint] = now

        Logger.info("🔁 [RetryPolicy] Will retry \(endpoint) (attempt \(failureCount + 1)/\(maxRetries)) after \(Int(delay))s")

        return (retry: true, delay: delay)
    }

    /// Record a successful request to reset failure counters
    /// - Parameter endpoint: The API endpoint path
    func recordSuccess(endpoint: String) {
        let hadFailures = (failureCounts[endpoint] ?? 0) > 0

        // Reset counters
        failureCounts[endpoint] = 0
        lastFailures[endpoint] = nil

        if hadFailures {
            Logger.debug("✅ [RetryPolicy] Success for \(endpoint) - failure count reset")
        }
    }

    /// Get current failure count for an endpoint (for debugging/monitoring)
    /// - Parameter endpoint: The endpoint to check
    /// - Returns: Number of consecutive failures
    func getFailureCount(endpoint: String) -> Int {
        return failureCounts[endpoint] ?? 0
    }

    /// Reset retry state for a specific endpoint
    /// Useful for testing or manual override
    /// - Parameter endpoint: The endpoint to reset (if nil, resets all)
    func reset(endpoint: String? = nil) {
        if let endpoint = endpoint {
            failureCounts[endpoint] = 0
            lastFailures[endpoint] = nil
            Logger.debug("🔄 [RetryPolicy] Reset retry state for \(endpoint)")
        } else {
            failureCounts.removeAll()
            lastFailures.removeAll()
            Logger.debug("🔄 [RetryPolicy] Reset all retry state")
        }
    }

    // MARK: - Private Helpers

    /// Determine if an error is retryable
    /// - Parameter error: The error to check
    /// - Returns: true if the error should trigger a retry
    private func isRetryableError(_ error: Error) -> Bool {
        // Check for VeloReadyAPIError types
        if let apiError = error as? VeloReadyAPIError {
            switch apiError {
            case .networkError:
                // Network errors are retryable (connection timeout, no internet, etc.)
                return true
            case .serverError:
                // 5xx server errors are retryable
                return true
            case .httpError(let statusCode, _):
                // Only retry on 5xx errors, not 4xx client errors
                return statusCode >= 500
            case .rateLimitExceeded:
                // Don't retry rate limits (user should wait)
                return false
            case .throttled:
                // Don't retry throttled requests (handled by throttler)
                return false
            case .circuitOpen:
                // Don't retry circuit breaker errors (handled by circuit breaker)
                return false
            case .authenticationFailed, .notAuthenticated:
                // Don't retry auth errors (user needs to re-authenticate)
                return false
            case .tierLimitExceeded:
                // Don't retry tier limit errors (user needs to upgrade)
                return false
            case .notFound:
                // 404 errors are not retryable
                return false
            case .invalidURL, .invalidResponse, .decodingError:
                // These are client-side errors, not retryable
                return false
            }
        }

        // Check for URLError types (network layer errors)
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .networkConnectionLost,
                 .dnsLookupFailed,
                 .notConnectedToInternet:
                // Network connectivity issues are retryable
                return true
            case .badServerResponse:
                // Server issues are retryable
                return true
            default:
                // Other URLErrors are not retryable
                return false
            }
        }

        // Unknown error types - be conservative and don't retry
        return false
    }
}
