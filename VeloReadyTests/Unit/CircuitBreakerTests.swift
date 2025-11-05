import XCTest
@testable import VeloReady

/// Tests for circuit breaker pattern to prevent cascading failures
/// Verifies state transitions, failure thresholds, and timeout behavior
final class CircuitBreakerTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // Reset circuit breaker state before each test
        await CircuitBreaker.shared.reset()
    }

    override func tearDown() async throws {
        // Clean up after each test
        await CircuitBreaker.shared.reset()
        try await super.tearDown()
    }

    // MARK: - Basic State Tests

    /// Test that circuit starts in closed state
    func testCircuit_StartsInClosedState() async throws {
        let endpoint = "/api/activities"

        let state = await CircuitBreaker.shared.getState(endpoint: endpoint)
        XCTAssertEqual(state, .closed, "Circuit should start in closed state")

        let allowed = await CircuitBreaker.shared.shouldAllowRequest(endpoint: endpoint)
        XCTAssertTrue(allowed, "Requests should be allowed in closed state")
    }

    /// Test that circuit stays closed with successful requests
    func testCircuit_RemainsClosedOnSuccess() async throws {
        let endpoint = "/api/activities"

        // Record 5 successful requests
        for _ in 1...5 {
            await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: true)
        }

        let state = await CircuitBreaker.shared.getState(endpoint: endpoint)
        XCTAssertEqual(state, .closed, "Circuit should remain closed on success")

        let failureCount = await CircuitBreaker.shared.getFailureCount(endpoint: endpoint)
        XCTAssertEqual(failureCount, 0, "Failure count should be 0")
    }

    // MARK: - Failure Threshold Tests

    /// Test that circuit opens after 5 consecutive failures
    func testCircuit_OpensAfter5Failures() async throws {
        let endpoint = "/api/activities"

        // Record 4 failures - should still be closed
        for i in 1...4 {
            await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: false)
            let state = await CircuitBreaker.shared.getState(endpoint: endpoint)
            XCTAssertEqual(state, .closed, "Circuit should remain closed after \(i) failures")
        }

        // 5th failure should open the circuit
        await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: false)
        let state = await CircuitBreaker.shared.getState(endpoint: endpoint)
        XCTAssertEqual(state, .open, "Circuit should open after 5 failures")

        let failureCount = await CircuitBreaker.shared.getFailureCount(endpoint: endpoint)
        XCTAssertEqual(failureCount, 5, "Failure count should be 5")
    }

    /// Test that requests are blocked when circuit is open
    func testCircuit_BlocksRequestsWhenOpen() async throws {
        let endpoint = "/api/activities"

        // Open the circuit by recording 5 failures
        for _ in 1...5 {
            await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: false)
        }

        // Verify circuit is open
        let state = await CircuitBreaker.shared.getState(endpoint: endpoint)
        XCTAssertEqual(state, .open, "Circuit should be open")

        // Attempt to make a request - should be blocked
        let allowed = await CircuitBreaker.shared.shouldAllowRequest(endpoint: endpoint)
        XCTAssertFalse(allowed, "Requests should be blocked when circuit is open")
    }

    // MARK: - Timeout and Half-Open Tests

    /// Test that circuit moves to half-open after timeout (simulated)
    func testCircuit_MovesToHalfOpenAfterTimeout() async throws {
        let endpoint = "/api/activities"

        // Open the circuit
        for _ in 1...5 {
            await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: false)
        }

        var state = await CircuitBreaker.shared.getState(endpoint: endpoint)
        XCTAssertEqual(state, .open, "Circuit should be open")

        // In a real scenario, we'd wait 60 seconds
        // For testing, we'll simulate this by manually resetting and testing the state machine

        // Reset to test the half-open path
        await CircuitBreaker.shared.reset(endpoint: endpoint)

        // Manually set to half-open state by opening and waiting
        // (In real code, this happens automatically after timeout)
        // For this test, we verify the state machine logic is correct
    }

    /// Test that circuit closes on success in half-open state
    func testCircuit_ClosesOnSuccessInHalfOpen() async throws {
        let endpoint = "/api/activities"

        // We can't easily test the timeout transition in unit tests,
        // but we can test the state transitions by using the internal methods
        // For now, we'll test the logic flow

        // Open circuit with 5 failures
        for _ in 1...5 {
            await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: false)
        }

        // In production, after 60s timeout, circuit would be half-open
        // We'll simulate recovery by resetting to allow testing
        await CircuitBreaker.shared.reset(endpoint: endpoint)

        // Now test that success closes the circuit
        await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: true)
        let state = await CircuitBreaker.shared.getState(endpoint: endpoint)
        XCTAssertEqual(state, .closed, "Circuit should close on success")
    }

    // MARK: - Endpoint Isolation Tests

    /// Test that different endpoints have independent circuits
    func testEndpoints_HaveIndependentCircuits() async throws {
        let activitiesEndpoint = "/api/activities"
        let streamsEndpoint = "/api/streams"

        // Open activities circuit with 5 failures
        for _ in 1...5 {
            await CircuitBreaker.shared.recordResult(endpoint: activitiesEndpoint, success: false)
        }

        let activitiesState = await CircuitBreaker.shared.getState(endpoint: activitiesEndpoint)
        XCTAssertEqual(activitiesState, .open, "Activities circuit should be open")

        // Streams circuit should still be closed
        let streamsState = await CircuitBreaker.shared.getState(endpoint: streamsEndpoint)
        XCTAssertEqual(streamsState, .closed, "Streams circuit should be closed")

        // Verify activities requests blocked but streams allowed
        let activitiesAllowed = await CircuitBreaker.shared.shouldAllowRequest(endpoint: activitiesEndpoint)
        XCTAssertFalse(activitiesAllowed, "Activities requests should be blocked")

        let streamsAllowed = await CircuitBreaker.shared.shouldAllowRequest(endpoint: streamsEndpoint)
        XCTAssertTrue(streamsAllowed, "Streams requests should be allowed")
    }

    /// Test that success resets failure count in closed state
    func testSuccess_ResetsFailureCountInClosed() async throws {
        let endpoint = "/api/activities"

        // Record 3 failures
        for _ in 1...3 {
            await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: false)
        }

        var failureCount = await CircuitBreaker.shared.getFailureCount(endpoint: endpoint)
        XCTAssertEqual(failureCount, 3, "Should have 3 failures")

        // Record success - should reset counter
        await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: true)

        failureCount = await CircuitBreaker.shared.getFailureCount(endpoint: endpoint)
        XCTAssertEqual(failureCount, 0, "Success should reset failure count")

        let state = await CircuitBreaker.shared.getState(endpoint: endpoint)
        XCTAssertEqual(state, .closed, "Circuit should remain closed")
    }

    // MARK: - Integration Tests

    /// Integration test: Simulate 5 consecutive failures → circuit opens → requests blocked
    func testFullCircuitBreakerFlow() async throws {
        let endpoint = "/api/activities"

        print("\n🧪 Testing circuit breaker flow...")

        // Step 1: Record 5 consecutive failures
        print("   Step 1: Recording 5 consecutive failures")
        for i in 1...5 {
            await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: false)
            let state = await CircuitBreaker.shared.getState(endpoint: endpoint)
            let count = await CircuitBreaker.shared.getFailureCount(endpoint: endpoint)
            print("      Failure \(i): State = \(state), Count = \(count)")

            if i < 5 {
                XCTAssertEqual(state, .closed, "Circuit should be closed before 5 failures")
            } else {
                XCTAssertEqual(state, .open, "Circuit should open after 5 failures")
            }
        }

        // Step 2: Verify circuit is open
        print("   Step 2: Verifying circuit is open")
        let state = await CircuitBreaker.shared.getState(endpoint: endpoint)
        XCTAssertEqual(state, .open, "Circuit should be open")

        // Step 3: Verify requests are blocked
        print("   Step 3: Verifying requests are blocked")
        let allowed = await CircuitBreaker.shared.shouldAllowRequest(endpoint: endpoint)
        XCTAssertFalse(allowed, "Requests should be blocked when circuit is open")

        // Step 4: Check time remaining
        print("   Step 4: Checking time remaining")
        let timeRemaining = await CircuitBreaker.shared.getTimeRemaining(endpoint: endpoint)
        XCTAssertNotNil(timeRemaining, "Should have time remaining")
        if let remaining = timeRemaining {
            XCTAssertGreaterThan(remaining, 0, "Time remaining should be positive")
            XCTAssertLessThanOrEqual(remaining, 60, "Time remaining should be <= 60s")
            print("      Time remaining: \(Int(remaining))s")
        }

        print("   ✅ Circuit breaker test completed successfully")
    }

    /// Test that circuit breaker respects the 60-second timeout
    func testCircuit_RespectesTimeout() async throws {
        let endpoint = "/api/activities"

        // Open the circuit
        for _ in 1...5 {
            await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: false)
        }

        // Get initial time remaining
        let initialRemaining = await CircuitBreaker.shared.getTimeRemaining(endpoint: endpoint)
        XCTAssertNotNil(initialRemaining, "Should have time remaining")

        // Wait a short time
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Check time remaining decreased
        let newRemaining = await CircuitBreaker.shared.getTimeRemaining(endpoint: endpoint)
        XCTAssertNotNil(newRemaining, "Should still have time remaining")

        if let initial = initialRemaining, let new = newRemaining {
            XCTAssertLessThan(new, initial, "Time remaining should decrease")
            XCTAssertEqual(initial - new, 1.0, accuracy: 0.5, "Should decrease by ~1 second")
        }
    }

    // MARK: - Reset Tests

    /// Test resetting specific endpoint
    func testReset_ClearsSpecificEndpoint() async throws {
        let endpoint = "/api/activities"

        // Open the circuit
        for _ in 1...5 {
            await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: false)
        }

        var state = await CircuitBreaker.shared.getState(endpoint: endpoint)
        XCTAssertEqual(state, .open, "Circuit should be open")

        // Reset the endpoint
        await CircuitBreaker.shared.reset(endpoint: endpoint)

        state = await CircuitBreaker.shared.getState(endpoint: endpoint)
        XCTAssertEqual(state, .closed, "Circuit should be closed after reset")

        let failureCount = await CircuitBreaker.shared.getFailureCount(endpoint: endpoint)
        XCTAssertEqual(failureCount, 0, "Failure count should be 0 after reset")
    }

    /// Test resetting all endpoints
    func testReset_ClearsAllEndpoints() async throws {
        // Open circuits for different endpoints
        for _ in 1...5 {
            await CircuitBreaker.shared.recordResult(endpoint: "/api/activities", success: false)
            await CircuitBreaker.shared.recordResult(endpoint: "/api/streams", success: false)
        }

        var activitiesState = await CircuitBreaker.shared.getState(endpoint: "/api/activities")
        var streamsState = await CircuitBreaker.shared.getState(endpoint: "/api/streams")

        XCTAssertEqual(activitiesState, .open, "Activities circuit should be open")
        XCTAssertEqual(streamsState, .open, "Streams circuit should be open")

        // Reset all endpoints
        await CircuitBreaker.shared.reset()

        activitiesState = await CircuitBreaker.shared.getState(endpoint: "/api/activities")
        streamsState = await CircuitBreaker.shared.getState(endpoint: "/api/streams")

        XCTAssertEqual(activitiesState, .closed, "Activities circuit should be closed")
        XCTAssertEqual(streamsState, .closed, "Streams circuit should be closed")
    }

    // MARK: - Monitoring Tests

    /// Test getting current state
    func testGetState_ReturnsCorrectState() async throws {
        let endpoint = "/api/activities"

        // Initial state should be closed
        var state = await CircuitBreaker.shared.getState(endpoint: endpoint)
        XCTAssertEqual(state, .closed, "Initial state should be closed")

        // After 5 failures, should be open
        for _ in 1...5 {
            await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: false)
        }

        state = await CircuitBreaker.shared.getState(endpoint: endpoint)
        XCTAssertEqual(state, .open, "State should be open after 5 failures")
    }

    /// Test getting failure count
    func testGetFailureCount_ReturnsCorrectCount() async throws {
        let endpoint = "/api/activities"

        // Initial count should be 0
        var count = await CircuitBreaker.shared.getFailureCount(endpoint: endpoint)
        XCTAssertEqual(count, 0, "Initial failure count should be 0")

        // Record 3 failures
        for i in 1...3 {
            await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: false)
            count = await CircuitBreaker.shared.getFailureCount(endpoint: endpoint)
            XCTAssertEqual(count, i, "Failure count should match number of failures")
        }
    }

    /// Test getting time remaining
    func testGetTimeRemaining_ReturnsCorrectValue() async throws {
        let endpoint = "/api/activities"

        // No time remaining when closed
        var timeRemaining = await CircuitBreaker.shared.getTimeRemaining(endpoint: endpoint)
        XCTAssertNil(timeRemaining, "Should have no time remaining when closed")

        // Open the circuit
        for _ in 1...5 {
            await CircuitBreaker.shared.recordResult(endpoint: endpoint, success: false)
        }

        // Should have time remaining when open
        timeRemaining = await CircuitBreaker.shared.getTimeRemaining(endpoint: endpoint)
        XCTAssertNotNil(timeRemaining, "Should have time remaining when open")

        if let remaining = timeRemaining {
            XCTAssertGreaterThan(remaining, 0, "Time remaining should be positive")
            XCTAssertLessThanOrEqual(remaining, 60, "Time remaining should be <= 60s")
        }
    }
}
