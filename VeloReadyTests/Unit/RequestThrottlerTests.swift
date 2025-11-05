import XCTest
@testable import VeloReady

/// Tests for client-side request throttling
/// Verifies rate limiting per endpoint to prevent overwhelming backend
final class RequestThrottlerTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // Reset throttler state before each test
        await RequestThrottler.shared.reset()
    }

    override func tearDown() async throws {
        // Clean up after each test
        await RequestThrottler.shared.reset()
        try await super.tearDown()
    }

    // MARK: - Activities Endpoint Tests (10 requests/minute)

    /// Test that activities endpoint allows 10 requests within a minute
    func testActivitiesEndpoint_Allows10RequestsPerMinute() async throws {
        let endpoint = "/api/activities"

        // Make 10 requests - all should be allowed
        for i in 1...10 {
            let result = await RequestThrottler.shared.shouldAllowRequest(endpoint: endpoint)
            XCTAssertTrue(result.allowed, "Request \(i) should be allowed")
            XCTAssertNil(result.retryAfter, "Request \(i) should not have retry delay")
        }

        // Verify we can check the count
        let count = await RequestThrottler.shared.getCurrentCount(endpoint: endpoint)
        XCTAssertEqual(count, 10, "Should have 10 requests tracked")

        let remaining = await RequestThrottler.shared.getRemainingRequests(endpoint: endpoint)
        XCTAssertEqual(remaining, 0, "Should have 0 requests remaining")
    }

    /// Test that activities endpoint throttles 11th request
    func testActivitiesEndpoint_Throttles11thRequest() async throws {
        let endpoint = "/api/activities"

        // Make 10 requests - all should be allowed
        for i in 1...10 {
            let result = await RequestThrottler.shared.shouldAllowRequest(endpoint: endpoint)
            XCTAssertTrue(result.allowed, "Request \(i) should be allowed")
        }

        // 11th request should be throttled
        let throttledResult = await RequestThrottler.shared.shouldAllowRequest(endpoint: endpoint)
        XCTAssertFalse(throttledResult.allowed, "11th request should be throttled")
        XCTAssertNotNil(throttledResult.retryAfter, "Should provide retry-after time")

        // Retry after should be reasonable (< 60 seconds)
        if let retryAfter = throttledResult.retryAfter {
            XCTAssertGreaterThan(retryAfter, 0, "Retry-after should be positive")
            XCTAssertLessThanOrEqual(retryAfter, 60, "Retry-after should be within window")
        }
    }

    /// Test that activities endpoint allows requests after window expires
    func testActivitiesEndpoint_AllowsRequestsAfterWindow() async throws {
        let endpoint = "/api/activities"

        // This test would require waiting 60 seconds in real time
        // For now, we can test the reset functionality as a proxy

        // Fill up the quota
        for _ in 1...10 {
            _ = await RequestThrottler.shared.shouldAllowRequest(endpoint: endpoint)
        }

        // Verify throttled
        var result = await RequestThrottler.shared.shouldAllowRequest(endpoint: endpoint)
        XCTAssertFalse(result.allowed, "Should be throttled after 10 requests")

        // Reset the endpoint
        await RequestThrottler.shared.reset(endpoint: endpoint)

        // Should now be allowed
        result = await RequestThrottler.shared.shouldAllowRequest(endpoint: endpoint)
        XCTAssertTrue(result.allowed, "Should be allowed after reset")
    }

    // MARK: - Streams Endpoint Tests (20 requests/minute)

    /// Test that streams endpoint allows 20 requests within a minute
    func testStreamsEndpoint_Allows20RequestsPerMinute() async throws {
        let endpoint = "/api/streams"

        // Make 20 requests - all should be allowed
        for i in 1...20 {
            let result = await RequestThrottler.shared.shouldAllowRequest(endpoint: endpoint)
            XCTAssertTrue(result.allowed, "Request \(i) should be allowed")
            XCTAssertNil(result.retryAfter, "Request \(i) should not have retry delay")
        }

        let remaining = await RequestThrottler.shared.getRemainingRequests(endpoint: endpoint)
        XCTAssertEqual(remaining, 0, "Should have 0 requests remaining")
    }

    /// Test that streams endpoint throttles 21st request
    func testStreamsEndpoint_Throttles21stRequest() async throws {
        let endpoint = "/api/streams"

        // Make 20 requests - all should be allowed
        for _ in 1...20 {
            _ = await RequestThrottler.shared.shouldAllowRequest(endpoint: endpoint)
        }

        // 21st request should be throttled
        let throttledResult = await RequestThrottler.shared.shouldAllowRequest(endpoint: endpoint)
        XCTAssertFalse(throttledResult.allowed, "21st request should be throttled")
        XCTAssertNotNil(throttledResult.retryAfter, "Should provide retry-after time")
    }

    // MARK: - Endpoint Isolation Tests

    /// Test that different endpoints have separate quotas
    func testEndpoints_HaveSeparateQuotas() async throws {
        let activitiesEndpoint = "/api/activities"
        let streamsEndpoint = "/api/streams"

        // Fill activities quota
        for _ in 1...10 {
            _ = await RequestThrottler.shared.shouldAllowRequest(endpoint: activitiesEndpoint)
        }

        // Verify activities is throttled
        var activitiesResult = await RequestThrottler.shared.shouldAllowRequest(endpoint: activitiesEndpoint)
        XCTAssertFalse(activitiesResult.allowed, "Activities should be throttled")

        // Streams should still be allowed (different quota)
        let streamsResult = await RequestThrottler.shared.shouldAllowRequest(endpoint: streamsEndpoint)
        XCTAssertTrue(streamsResult.allowed, "Streams should not be affected by activities quota")
    }

    // MARK: - Concurrent Request Tests

    /// Test throttler handles concurrent requests correctly
    func testThrottler_HandlesConcurrentRequests() async throws {
        let endpoint = "/api/activities"

        // Make 15 concurrent requests
        await withTaskGroup(of: (Bool, TimeInterval?).self) { group in
            for _ in 1...15 {
                group.addTask {
                    await RequestThrottler.shared.shouldAllowRequest(endpoint: endpoint)
                }
            }

            var allowedCount = 0
            var throttledCount = 0

            for await result in group {
                if result.0 {
                    allowedCount += 1
                } else {
                    throttledCount += 1
                }
            }

            // Exactly 10 should be allowed, 5 throttled
            XCTAssertEqual(allowedCount, 10, "Exactly 10 requests should be allowed")
            XCTAssertEqual(throttledCount, 5, "Exactly 5 requests should be throttled")
        }
    }

    // MARK: - Reset Tests

    /// Test resetting specific endpoint
    func testReset_ClearsSpecificEndpoint() async throws {
        let endpoint = "/api/activities"

        // Make 5 requests
        for _ in 1...5 {
            _ = await RequestThrottler.shared.shouldAllowRequest(endpoint: endpoint)
        }

        var count = await RequestThrottler.shared.getCurrentCount(endpoint: endpoint)
        XCTAssertEqual(count, 5, "Should have 5 requests tracked")

        // Reset the endpoint
        await RequestThrottler.shared.reset(endpoint: endpoint)

        count = await RequestThrottler.shared.getCurrentCount(endpoint: endpoint)
        XCTAssertEqual(count, 0, "Should have 0 requests after reset")
    }

    /// Test resetting all endpoints
    func testReset_ClearsAllEndpoints() async throws {
        // Make requests to different endpoints
        _ = await RequestThrottler.shared.shouldAllowRequest(endpoint: "/api/activities")
        _ = await RequestThrottler.shared.shouldAllowRequest(endpoint: "/api/streams")

        var activitiesCount = await RequestThrottler.shared.getCurrentCount(endpoint: "/api/activities")
        var streamsCount = await RequestThrottler.shared.getCurrentCount(endpoint: "/api/streams")

        XCTAssertEqual(activitiesCount, 1, "Activities should have 1 request")
        XCTAssertEqual(streamsCount, 1, "Streams should have 1 request")

        // Reset all endpoints
        await RequestThrottler.shared.reset()

        activitiesCount = await RequestThrottler.shared.getCurrentCount(endpoint: "/api/activities")
        streamsCount = await RequestThrottler.shared.getCurrentCount(endpoint: "/api/streams")

        XCTAssertEqual(activitiesCount, 0, "Activities should be reset")
        XCTAssertEqual(streamsCount, 0, "Streams should be reset")
    }

    // MARK: - Rate Limit Verification Test

    /// Integration test: Make 11 activity requests in 30 seconds and verify 11th is throttled
    func testRealWorldScenario_11RequestsIn30Seconds() async throws {
        let endpoint = "/api/activities"
        let totalRequests = 11
        let duration: TimeInterval = 30.0 // 30 seconds
        let delayBetweenRequests = duration / Double(totalRequests - 1)

        var allowedCount = 0
        var throttledCount = 0

        for i in 1...totalRequests {
            let result = await RequestThrottler.shared.shouldAllowRequest(endpoint: endpoint)

            if result.allowed {
                allowedCount += 1
                print("✅ Request \(i): Allowed")
            } else {
                throttledCount += 1
                print("⛔ Request \(i): Throttled (retry after \(result.retryAfter ?? 0)s)")
            }

            // Wait between requests (except after last one)
            if i < totalRequests {
                try await Task.sleep(nanoseconds: UInt64(delayBetweenRequests * 1_000_000_000))
            }
        }

        // With a limit of 10/minute:
        // - All 11 requests happen within 30 seconds (well under 60 seconds)
        // - First 10 should be allowed
        // - 11th should be throttled
        XCTAssertEqual(allowedCount, 10, "First 10 requests should be allowed")
        XCTAssertEqual(throttledCount, 1, "11th request should be throttled")

        print("\n📊 Test Results:")
        print("   Allowed: \(allowedCount)")
        print("   Throttled: \(throttledCount)")
    }
}
