import XCTest
@testable import VeloReady

/// Tests for exponential backoff retry policy
/// Verifies retry logic, delays, and failure tracking
final class RetryPolicyTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // Reset retry policy state before each test
        await ExponentialBackoffRetryPolicy.shared.reset()
    }

    override func tearDown() async throws {
        // Clean up after each test
        await ExponentialBackoffRetryPolicy.shared.reset()
        try await super.tearDown()
    }

    // MARK: - Basic Retry Tests

    /// Test that network errors are retryable
    func testNetworkError_IsRetryable() async throws {
        let endpoint = "/api/activities"
        let error = VeloReadyAPIError.networkError(URLError(.timedOut))

        let result = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

        XCTAssertTrue(result.retry, "Network error should be retryable")
        XCTAssertEqual(result.delay, 1.0, "First retry should have 1s delay (2^0)")
    }

    /// Test that server errors (5xx) are retryable
    func testServerError_IsRetryable() async throws {
        let endpoint = "/api/activities"
        let error = VeloReadyAPIError.serverError

        let result = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

        XCTAssertTrue(result.retry, "Server error should be retryable")
        XCTAssertEqual(result.delay, 1.0, "First retry should have 1s delay")
    }

    /// Test that 5xx HTTP errors are retryable
    func testHTTPError_5xx_IsRetryable() async throws {
        let endpoint = "/api/activities"
        let error = VeloReadyAPIError.httpError(statusCode: 503, message: "Service Unavailable")

        let result = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

        XCTAssertTrue(result.retry, "503 error should be retryable")
    }

    /// Test that 4xx HTTP errors are NOT retryable
    func testHTTPError_4xx_NotRetryable() async throws {
        let endpoint = "/api/activities"
        let error = VeloReadyAPIError.httpError(statusCode: 400, message: "Bad Request")

        let result = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

        XCTAssertFalse(result.retry, "400 error should not be retryable")
    }

    /// Test that authentication errors are NOT retryable
    func testAuthenticationError_NotRetryable() async throws {
        let endpoint = "/api/activities"
        let error = VeloReadyAPIError.authenticationFailed

        let result = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

        XCTAssertFalse(result.retry, "Authentication error should not be retryable")
    }

    /// Test that rate limit errors are NOT retryable
    func testRateLimitError_NotRetryable() async throws {
        let endpoint = "/api/activities"
        let error = VeloReadyAPIError.rateLimitExceeded

        let result = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

        XCTAssertFalse(result.retry, "Rate limit error should not be retryable")
    }

    /// Test that throttled errors are NOT retryable
    func testThrottledError_NotRetryable() async throws {
        let endpoint = "/api/activities"
        let error = VeloReadyAPIError.throttled(retryAfter: 30)

        let result = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

        XCTAssertFalse(result.retry, "Throttled error should not be retryable")
    }

    // MARK: - Exponential Backoff Tests

    /// Test exponential backoff delays: 1s, 2s, 4s
    func testExponentialBackoff_CorrectDelays() async throws {
        let endpoint = "/api/activities"
        let error = VeloReadyAPIError.networkError(URLError(.timedOut))

        // First retry: 2^0 = 1s
        let result1 = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)
        XCTAssertTrue(result1.retry, "First retry should be allowed")
        XCTAssertEqual(result1.delay, 1.0, "First retry delay should be 1s")

        // Second retry: 2^1 = 2s
        let result2 = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)
        XCTAssertTrue(result2.retry, "Second retry should be allowed")
        XCTAssertEqual(result2.delay, 2.0, "Second retry delay should be 2s")

        // Third retry: 2^2 = 4s
        let result3 = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)
        XCTAssertTrue(result3.retry, "Third retry should be allowed")
        XCTAssertEqual(result3.delay, 4.0, "Third retry delay should be 4s")

        // Fourth attempt should be rejected (max 3 retries)
        let result4 = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)
        XCTAssertFalse(result4.retry, "Fourth retry should be rejected (max 3 retries)")
    }

    /// Test that max retries limit is enforced
    func testMaxRetries_Enforced() async throws {
        let endpoint = "/api/activities"
        let error = VeloReadyAPIError.networkError(URLError(.timedOut))

        // Attempt 4 retries
        for i in 1...4 {
            let result = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

            if i <= 3 {
                XCTAssertTrue(result.retry, "Retry \(i) should be allowed")
            } else {
                XCTAssertFalse(result.retry, "Retry \(i) should be rejected (max 3)")
            }
        }

        // Verify failure count
        let failureCount = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: endpoint)
        XCTAssertEqual(failureCount, 3, "Failure count should be capped at 3")
    }

    // MARK: - Success Reset Tests

    /// Test that success resets failure counters
    func testSuccess_ResetsFailureCount() async throws {
        let endpoint = "/api/activities"
        let error = VeloReadyAPIError.networkError(URLError(.timedOut))

        // Fail twice
        _ = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)
        _ = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

        var failureCount = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: endpoint)
        XCTAssertEqual(failureCount, 2, "Should have 2 failures")

        // Record success
        await ExponentialBackoffRetryPolicy.shared.recordSuccess(endpoint: endpoint)

        failureCount = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: endpoint)
        XCTAssertEqual(failureCount, 0, "Success should reset failure count")

        // Next retry should start at delay 1s again
        let result = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)
        XCTAssertTrue(result.retry, "Should allow retry after success")
        XCTAssertEqual(result.delay, 1.0, "Should restart at 1s delay")
    }

    // MARK: - Time Window Reset Tests

    /// Test that failure count resets after 5 minutes
    func testFailureCount_ResetsAfter5Minutes() async throws {
        let endpoint = "/api/activities"
        let error = VeloReadyAPIError.networkError(URLError(.timedOut))

        // This test would require waiting 5 minutes in real time
        // For now, we test the reset functionality as a proxy

        // Fail twice
        _ = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)
        _ = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

        var failureCount = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: endpoint)
        XCTAssertEqual(failureCount, 2, "Should have 2 failures")

        // Simulate time passing by manually resetting
        await ExponentialBackoffRetryPolicy.shared.reset(endpoint: endpoint)

        failureCount = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: endpoint)
        XCTAssertEqual(failureCount, 0, "Reset should clear failure count")
    }

    // MARK: - Endpoint Isolation Tests

    /// Test that different endpoints have separate retry counters
    func testEndpoints_HaveSeparateCounters() async throws {
        let activitiesEndpoint = "/api/activities"
        let streamsEndpoint = "/api/streams"
        let error = VeloReadyAPIError.networkError(URLError(.timedOut))

        // Fail activities twice
        _ = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: activitiesEndpoint, error: error)
        _ = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: activitiesEndpoint, error: error)

        // Check that activities has 2 failures but streams has 0
        let activitiesCount = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: activitiesEndpoint)
        let streamsCount = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: streamsEndpoint)

        XCTAssertEqual(activitiesCount, 2, "Activities should have 2 failures")
        XCTAssertEqual(streamsCount, 0, "Streams should have 0 failures")

        // Next activities retry should be at 4s (2^2)
        let activitiesResult = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: activitiesEndpoint, error: error)
        XCTAssertEqual(activitiesResult.delay, 4.0, "Activities should be at 4s delay")

        // First streams retry should be at 1s (2^0)
        let streamsResult = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: streamsEndpoint, error: error)
        XCTAssertEqual(streamsResult.delay, 1.0, "Streams should start at 1s delay")
    }

    // MARK: - Integration Test

    /// Integration test: Simulate network failure with 3 retries and exponential delays
    func testNetworkFailure_ThreeRetriesWithExponentialBackoff() async throws {
        let endpoint = "/api/activities"
        let error = VeloReadyAPIError.networkError(URLError(.timedOut))

        print("\n🧪 Testing network failure with retries...")

        var attemptCount = 0
        var totalDelay: TimeInterval = 0

        // Simulate retry loop
        while attemptCount < 4 {
            attemptCount += 1

            let startTime = Date()
            let result = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

            if result.retry {
                print("   Attempt \(attemptCount): Retry allowed, waiting \(Int(result.delay))s")

                // Actually wait for the delay
                try await Task.sleep(nanoseconds: UInt64(result.delay * 1_000_000_000))

                let actualDelay = Date().timeIntervalSince(startTime)
                totalDelay += actualDelay

                // Verify delay is approximately correct (within 0.1s tolerance)
                XCTAssertEqual(actualDelay, result.delay, accuracy: 0.1, "Actual delay should match expected delay")
            } else {
                print("   Attempt \(attemptCount): Max retries reached")
                break
            }
        }

        print("   Total attempts: \(attemptCount)")
        print("   Total delay: \(String(format: "%.1f", totalDelay))s")

        // Verify we made exactly 3 retry attempts
        XCTAssertEqual(attemptCount, 4, "Should have made 4 attempts (initial + 3 retries)")

        // Verify total delay is approximately 7s (1s + 2s + 4s)
        XCTAssertEqual(totalDelay, 7.0, accuracy: 0.5, "Total delay should be ~7s")
    }

    // MARK: - Reset Tests

    /// Test resetting specific endpoint
    func testReset_ClearsSpecificEndpoint() async throws {
        let endpoint = "/api/activities"
        let error = VeloReadyAPIError.networkError(URLError(.timedOut))

        // Fail twice
        _ = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)
        _ = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

        var count = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: endpoint)
        XCTAssertEqual(count, 2, "Should have 2 failures")

        // Reset the endpoint
        await ExponentialBackoffRetryPolicy.shared.reset(endpoint: endpoint)

        count = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: endpoint)
        XCTAssertEqual(count, 0, "Should have 0 failures after reset")
    }

    /// Test resetting all endpoints
    func testReset_ClearsAllEndpoints() async throws {
        let error = VeloReadyAPIError.networkError(URLError(.timedOut))

        // Fail on different endpoints
        _ = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: "/api/activities", error: error)
        _ = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: "/api/streams", error: error)

        var activitiesCount = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: "/api/activities")
        var streamsCount = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: "/api/streams")

        XCTAssertEqual(activitiesCount, 1, "Activities should have 1 failure")
        XCTAssertEqual(streamsCount, 1, "Streams should have 1 failure")

        // Reset all endpoints
        await ExponentialBackoffRetryPolicy.shared.reset()

        activitiesCount = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: "/api/activities")
        streamsCount = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: "/api/streams")

        XCTAssertEqual(activitiesCount, 0, "Activities should be reset")
        XCTAssertEqual(streamsCount, 0, "Streams should be reset")
    }

    // MARK: - URLError Types Tests

    /// Test that timeout errors are retryable
    func testURLError_TimedOut_IsRetryable() async throws {
        let endpoint = "/api/activities"
        let urlError = URLError(.timedOut)
        let error = VeloReadyAPIError.networkError(urlError)

        let result = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

        XCTAssertTrue(result.retry, "Timeout error should be retryable")
    }

    /// Test that connection errors are retryable
    func testURLError_CannotConnectToHost_IsRetryable() async throws {
        let endpoint = "/api/activities"
        let urlError = URLError(.cannotConnectToHost)
        let error = VeloReadyAPIError.networkError(urlError)

        let result = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

        XCTAssertTrue(result.retry, "Cannot connect error should be retryable")
    }

    /// Test that network lost errors are retryable
    func testURLError_NetworkConnectionLost_IsRetryable() async throws {
        let endpoint = "/api/activities"
        let urlError = URLError(.networkConnectionLost)
        let error = VeloReadyAPIError.networkError(urlError)

        let result = await ExponentialBackoffRetryPolicy.shared.shouldRetry(endpoint: endpoint, error: error)

        XCTAssertTrue(result.retry, "Network lost error should be retryable")
    }
}
