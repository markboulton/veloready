import Foundation

/// Circuit breaker pattern to prevent cascading failures
/// Monitors endpoint health and temporarily blocks requests to failing endpoints
///
/// States:
/// - Closed: Normal operation, requests allowed
/// - Open: Endpoint failing, requests blocked
/// - HalfOpen: Testing recovery, limited requests allowed
///
/// Behavior:
/// - After 5 consecutive failures, circuit opens
/// - Circuit stays open for 60 seconds
/// - After timeout, circuit moves to half-open
/// - First success in half-open closes the circuit
/// - Any failure in half-open reopens the circuit
actor CircuitBreaker {
    // MARK: - Singleton
    static let shared = CircuitBreaker()

    // MARK: - State

    /// Circuit breaker state for an endpoint
    enum State: String {
        case closed     // Normal operation - requests allowed
        case open       // Circuit tripped - requests blocked
        case halfOpen   // Testing recovery - limited requests allowed
    }

    /// Current state per endpoint
    private var states: [String: State] = [:]

    /// Failure count per endpoint
    private var failureCounts: [String: Int] = [:]

    /// Timestamp of last failure per endpoint
    private var lastFailures: [String: Date] = [:]

    /// Timestamp when circuit opened per endpoint
    private var circuitOpenTimes: [String: Date] = [:]

    // MARK: - Configuration

    /// Number of consecutive failures before opening circuit
    private let failureThreshold = 5

    /// Time in seconds to wait before attempting recovery (half-open)
    private let timeout: TimeInterval = 60

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Check if a request to the given endpoint should be allowed
    /// - Parameter endpoint: The API endpoint path (e.g., "/api/activities")
    /// - Returns: true if request should be allowed, false if circuit is open
    func shouldAllowRequest(endpoint: String) async -> Bool {
        let currentState = states[endpoint] ?? .closed
        let now = Date()

        switch currentState {
        case .closed:
            // Normal operation - allow request
            Logger.debug("⚡ [CircuitBreaker] \(endpoint) - State: CLOSED, allowing request")
            return true

        case .open:
            // Check if timeout has expired
            guard let openTime = circuitOpenTimes[endpoint] else {
                // No open time recorded, treat as closed
                Logger.warning("⚠️ [CircuitBreaker] \(endpoint) - Open but no timestamp, treating as closed")
                states[endpoint] = .closed
                return true
            }

            let timeSinceOpen = now.timeIntervalSince(openTime)
            if timeSinceOpen >= timeout {
                // Timeout expired - move to half-open for testing
                Logger.info("🔄 [CircuitBreaker] \(endpoint) - Timeout expired, moving to HALF-OPEN")
                states[endpoint] = .halfOpen
                return true
            } else {
                // Still in timeout period - deny request
                let remainingTime = Int(timeout - timeSinceOpen)
                Logger.warning("🔴 [CircuitBreaker] \(endpoint) - Circuit OPEN, blocking request (retry in \(remainingTime)s)")
                return false
            }

        case .halfOpen:
            // Testing recovery - allow limited requests
            Logger.info("🟡 [CircuitBreaker] \(endpoint) - State: HALF-OPEN, allowing test request")
            return true
        }
    }

    /// Record the result of a request attempt
    /// - Parameters:
    ///   - endpoint: The API endpoint path
    ///   - success: true if request succeeded, false if failed
    func recordResult(endpoint: String, success: Bool) async {
        let currentState = states[endpoint] ?? .closed
        let now = Date()

        if success {
            // Request succeeded
            handleSuccess(endpoint: endpoint, currentState: currentState, now: now)
        } else {
            // Request failed
            handleFailure(endpoint: endpoint, currentState: currentState, now: now)
        }
    }

    /// Get current state for an endpoint (for monitoring/debugging)
    /// - Parameter endpoint: The endpoint to check
    /// - Returns: Current circuit state
    func getState(endpoint: String) -> State {
        return states[endpoint] ?? .closed
    }

    /// Get current failure count for an endpoint
    /// - Parameter endpoint: The endpoint to check
    /// - Returns: Number of consecutive failures
    func getFailureCount(endpoint: String) -> Int {
        return failureCounts[endpoint] ?? 0
    }

    /// Get time remaining until circuit can be tested (if open)
    /// - Parameter endpoint: The endpoint to check
    /// - Returns: Seconds remaining, or nil if not open
    func getTimeRemaining(endpoint: String) -> TimeInterval? {
        guard states[endpoint] == .open,
              let openTime = circuitOpenTimes[endpoint] else {
            return nil
        }

        let timeSinceOpen = Date().timeIntervalSince(openTime)
        let remaining = timeout - timeSinceOpen
        return max(0, remaining)
    }

    /// Reset circuit breaker state for an endpoint
    /// - Parameter endpoint: The endpoint to reset (if nil, resets all)
    func reset(endpoint: String? = nil) {
        if let endpoint = endpoint {
            states[endpoint] = .closed
            failureCounts[endpoint] = 0
            lastFailures[endpoint] = nil
            circuitOpenTimes[endpoint] = nil
            Logger.debug("🔄 [CircuitBreaker] Reset circuit for \(endpoint)")
        } else {
            states.removeAll()
            failureCounts.removeAll()
            lastFailures.removeAll()
            circuitOpenTimes.removeAll()
            Logger.debug("🔄 [CircuitBreaker] Reset all circuits")
        }
    }

    // MARK: - Private Methods

    /// Handle successful request
    private func handleSuccess(endpoint: String, currentState: State, now: Date) {
        switch currentState {
        case .closed:
            // Already closed, just reset failure count to be safe
            if failureCounts[endpoint] ?? 0 > 0 {
                Logger.debug("✅ [CircuitBreaker] \(endpoint) - Success in CLOSED, resetting failure count")
                failureCounts[endpoint] = 0
                lastFailures[endpoint] = nil
            }

        case .halfOpen:
            // Success in half-open - close the circuit and reset
            Logger.info("✅ [CircuitBreaker] \(endpoint) - Success in HALF-OPEN → CLOSED (recovered)")
            states[endpoint] = .closed
            failureCounts[endpoint] = 0
            lastFailures[endpoint] = nil
            circuitOpenTimes[endpoint] = nil

        case .open:
            // Shouldn't happen (requests blocked in open state)
            Logger.warning("⚠️ [CircuitBreaker] \(endpoint) - Success recorded in OPEN state (unexpected)")
            // Treat as recovery and close
            states[endpoint] = .closed
            failureCounts[endpoint] = 0
            lastFailures[endpoint] = nil
            circuitOpenTimes[endpoint] = nil
        }
    }

    /// Handle failed request
    private func handleFailure(endpoint: String, currentState: State, now: Date) {
        // Increment failure count
        let currentCount = failureCounts[endpoint] ?? 0
        let newCount = currentCount + 1
        failureCounts[endpoint] = newCount
        lastFailures[endpoint] = now

        switch currentState {
        case .closed:
            // Check if we've reached failure threshold
            if newCount >= failureThreshold {
                // Open the circuit
                Logger.warning("🔴 [CircuitBreaker] \(endpoint) - Threshold reached (\(newCount)/\(failureThreshold)) → OPEN")
                states[endpoint] = .open
                circuitOpenTimes[endpoint] = now
            } else {
                Logger.debug("⚠️ [CircuitBreaker] \(endpoint) - Failure \(newCount)/\(failureThreshold) in CLOSED")
            }

        case .halfOpen:
            // Failure in half-open - reopen the circuit
            Logger.warning("🔴 [CircuitBreaker] \(endpoint) - Failure in HALF-OPEN → OPEN (recovery failed)")
            states[endpoint] = .open
            circuitOpenTimes[endpoint] = now
            failureCounts[endpoint] = failureThreshold // Set to threshold to stay open

        case .open:
            // Already open, just update timestamp
            Logger.debug("🔴 [CircuitBreaker] \(endpoint) - Additional failure in OPEN state")
            circuitOpenTimes[endpoint] = now
        }
    }
}
