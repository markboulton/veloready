import XCTest
@testable import VeloReady

/// Unit tests for provider-specific rate limiting
@MainActor
final class ProviderRateLimitTests: XCTestCase {
    
    var throttler: RequestThrottler!
    
    override func setUp() async throws {
        throttler = RequestThrottler.shared
        // Reset all throttle state before each test
        await throttler.reset(provider: .strava)
        await throttler.reset(provider: .intervalsICU)
        await throttler.reset(provider: .appleHealth)
    }
    
    // MARK: - Provider Configuration Tests
    
    func testProviderRateLimitConfigurations() {
        // Test Strava configuration
        let stravaConfig = ProviderRateLimitConfig.forProvider(.strava)
        XCTAssertEqual(stravaConfig.maxRequestsPer15Min, 100)
        XCTAssertEqual(stravaConfig.maxRequestsPerDay, 1000)
        XCTAssertTrue(stravaConfig.hasRateLimits)
        
        // Test Intervals.icu configuration
        let intervalsConfig = ProviderRateLimitConfig.forProvider(.intervalsICU)
        XCTAssertEqual(intervalsConfig.maxRequestsPer15Min, 100)
        XCTAssertEqual(intervalsConfig.maxRequestsPerHour, 200)
        XCTAssertEqual(intervalsConfig.maxRequestsPerDay, 2000)
        XCTAssertTrue(intervalsConfig.hasRateLimits)
        
        // Test Apple Health configuration (no limits)
        let healthConfig = ProviderRateLimitConfig.forProvider(.appleHealth)
        XCTAssertNil(healthConfig.maxRequestsPer15Min)
        XCTAssertNil(healthConfig.maxRequestsPerHour)
        XCTAssertNil(healthConfig.maxRequestsPerDay)
        XCTAssertFalse(healthConfig.hasRateLimits)
    }
    
    // MARK: - Rate Limit Window Tests
    
    func testRateLimitWindowDurations() {
        XCTAssertEqual(RateLimitWindow.fifteenMinute.duration, 900) // 15 minutes
        XCTAssertEqual(RateLimitWindow.hourly.duration, 3600) // 1 hour
        XCTAssertEqual(RateLimitWindow.daily.duration, 86400) // 24 hours
    }
    
    func testRateLimitWindowKeys() {
        XCTAssertEqual(RateLimitWindow.fifteenMinute.redisKeySuffix, "15min")
        XCTAssertEqual(RateLimitWindow.hourly.redisKeySuffix, "hour")
        XCTAssertEqual(RateLimitWindow.daily.redisKeySuffix, "day")
    }
    
    // MARK: - Throttling Behavior Tests
    
    func testAppleHealthNoLimits() async {
        // Apple Health should never be throttled (on-device API)
        for _ in 0..<1000 {
            let result = await throttler.shouldAllowRequest(provider: .appleHealth)
            XCTAssertTrue(result.allowed, "Apple Health should always be allowed")
            XCTAssertNil(result.retryAfter)
        }
    }
    
    func testStravaRateLimitEnforcement() async {
        let config = ProviderRateLimitConfig.strava
        let maxRequests = config.maxRequestsPer15Min!
        
        // Make requests up to the limit
        for i in 1...maxRequests {
            let result = await throttler.shouldAllowRequest(provider: .strava)
            XCTAssertTrue(result.allowed, "Request \(i) should be allowed")
        }
        
        // Next request should be throttled
        let throttledResult = await throttler.shouldAllowRequest(provider: .strava)
        XCTAssertFalse(throttledResult.allowed, "Request after limit should be throttled")
        XCTAssertNotNil(throttledResult.retryAfter, "Should provide retry time")
        XCTAssertNotNil(throttledResult.reason, "Should provide reason")
        XCTAssertTrue(throttledResult.reason!.contains("strava"), "Reason should mention provider")
    }
    
    func testIntervalsRateLimitEnforcement() async {
        let config = ProviderRateLimitConfig.intervalsICU
        let maxRequests = config.maxRequestsPer15Min!
        
        // Make requests up to the limit
        for i in 1...maxRequests {
            let result = await throttler.shouldAllowRequest(provider: .intervalsICU)
            XCTAssertTrue(result.allowed, "Request \(i) should be allowed")
        }
        
        // Next request should be throttled
        let throttledResult = await throttler.shouldAllowRequest(provider: .intervalsICU)
        XCTAssertFalse(throttledResult.allowed, "Request after limit should be throttled")
        XCTAssertNotNil(throttledResult.retryAfter)
    }
    
    // MARK: - Multi-Provider Independence Tests
    
    func testProvidersAreIndependent() async {
        // Fill Strava's limit
        let stravaConfig = ProviderRateLimitConfig.strava
        for _ in 1...stravaConfig.maxRequestsPer15Min! {
            _ = await throttler.shouldAllowRequest(provider: .strava)
        }
        
        // Verify Strava is throttled
        let stravaResult = await throttler.shouldAllowRequest(provider: .strava)
        XCTAssertFalse(stravaResult.allowed, "Strava should be throttled")
        
        // Verify Intervals.icu is still allowed
        let intervalsResult = await throttler.shouldAllowRequest(provider: .intervalsICU)
        XCTAssertTrue(intervalsResult.allowed, "Intervals should still be allowed")
        
        // Verify Apple Health is still allowed
        let healthResult = await throttler.shouldAllowRequest(provider: .appleHealth)
        XCTAssertTrue(healthResult.allowed, "Apple Health should still be allowed")
    }
    
    // MARK: - Status Monitoring Tests
    
    func testProviderStatusTracking() async {
        // Make some requests
        for _ in 1...10 {
            _ = await throttler.shouldAllowRequest(provider: .strava)
        }
        
        // Check status
        let status = await throttler.getProviderStatus(provider: .strava)
        XCTAssertEqual(status.provider, .strava)
        
        if let remaining15 = status.remaining15Min, let max15 = status.max15Min {
            XCTAssertEqual(remaining15, max15 - 10, "Should have 10 requests used")
        } else {
            XCTFail("Strava should have 15-minute window status")
        }
    }
    
    func testProviderStatusDisplayString() async {
        // Make some requests
        for _ in 1...5 {
            _ = await throttler.shouldAllowRequest(provider: .strava)
        }
        
        let status = await throttler.getProviderStatus(provider: .strava)
        let displayString = status.displayString
        
        XCTAssertTrue(displayString.contains("strava"), "Display string should contain provider name")
        XCTAssertTrue(displayString.contains("15min"), "Display string should contain 15min window")
        XCTAssertTrue(displayString.contains("day"), "Display string should contain daily window")
    }
    
    // MARK: - Reset Tests
    
    func testProviderReset() async {
        // Fill up limit
        let config = ProviderRateLimitConfig.strava
        for _ in 1...config.maxRequestsPer15Min! {
            _ = await throttler.shouldAllowRequest(provider: .strava)
        }
        
        // Verify throttled
        var result = await throttler.shouldAllowRequest(provider: .strava)
        XCTAssertFalse(result.allowed)
        
        // Reset
        await throttler.reset(provider: .strava)
        
        // Verify unthrottled
        result = await throttler.shouldAllowRequest(provider: .strava)
        XCTAssertTrue(result.allowed, "After reset, requests should be allowed again")
    }
    
    // MARK: - Edge Cases
    
    func testConcurrentRequests() async {
        // Simulate concurrent requests to the same provider
        await withTaskGroup(of: Void.self) { group in
            for _ in 1...50 {
                group.addTask {
                    _ = await self.throttler.shouldAllowRequest(provider: .strava)
                }
            }
        }
        
        // Check status is consistent
        let status = await throttler.getProviderStatus(provider: .strava)
        if let remaining = status.remaining15Min, let max = status.max15Min {
            XCTAssertTrue(remaining <= max, "Remaining should not exceed max")
            XCTAssertTrue(remaining >= 0, "Remaining should not be negative")
        }
    }
    
    func testEndpointContextLogging() async {
        // Test that endpoint context is properly passed
        let result = await throttler.shouldAllowRequest(
            provider: .strava,
            endpoint: "/api/activities"
        )
        XCTAssertTrue(result.allowed)
        // Note: Can't easily test logging, but endpoint parameter should be passed through
    }
}

// MARK: - Rate Limit Monitor Tests

@MainActor
final class RateLimitMonitorTests: XCTestCase {
    
    var monitor: RateLimitMonitor!
    
    override func setUp() {
        monitor = RateLimitMonitor.shared
        // Reset monitor state
        monitor.recentViolations.removeAll()
        monitor.aggregateStats = AggregateRateLimitStats()
    }
    
    func testViolationLogging() {
        // Log a violation
        monitor.logViolation(
            provider: .strava,
            endpoint: "/api/activities",
            retryAfter: 30,
            reason: "Test violation"
        )
        
        XCTAssertEqual(monitor.recentViolations.count, 1)
        
        let violation = monitor.recentViolations[0]
        XCTAssertEqual(violation.provider, .strava)
        XCTAssertEqual(violation.endpoint, "/api/activities")
        XCTAssertEqual(violation.retryAfter, 30)
        XCTAssertEqual(violation.reason, "Test violation")
    }
    
    func testSuccessLogging() {
        // Log successful requests
        for _ in 1...10 {
            monitor.logSuccessfulRequest(provider: .strava, endpoint: "/api/activities")
        }
        
        let stats = monitor.aggregateStats.providerStats[.strava]
        XCTAssertEqual(stats?.successCount, 10)
        XCTAssertEqual(stats?.violationCount, 0)
    }
    
    func testHealthScore() {
        // No violations = perfect score
        monitor.logSuccessfulRequest(provider: .strava, endpoint: nil)
        let perfectScore = monitor.getHealthScore(for: .strava)
        XCTAssertGreaterThan(perfectScore, 90.0, "Perfect health should be > 90%")
        
        // Add violations to lower score
        for _ in 1...5 {
            monitor.logViolation(provider: .strava, endpoint: nil, retryAfter: 10, reason: nil)
        }
        let degradedScore = monitor.getHealthScore(for: .strava)
        XCTAssertLessThan(degradedScore, perfectScore, "Violations should lower health score")
    }
    
    func testDiagnosticsExport() {
        // Add some data
        monitor.logSuccessfulRequest(provider: .strava, endpoint: nil)
        monitor.logViolation(provider: .strava, endpoint: "/test", retryAfter: 15, reason: "Test")
        
        let diagnostics = monitor.exportDiagnostics()
        
        XCTAssertTrue(diagnostics.contains("Rate Limit Diagnostics"))
        XCTAssertTrue(diagnostics.contains("strava"))
        XCTAssertTrue(diagnostics.contains("Provider Status"))
        XCTAssertTrue(diagnostics.contains("Aggregate Stats"))
        XCTAssertTrue(diagnostics.contains("Recent Violations"))
    }
    
    func testMaxViolationsTracking() {
        // Log more than max violations
        for i in 1...100 {
            monitor.logViolation(
                provider: .strava,
                endpoint: "/test\(i)",
                retryAfter: Double(i),
                reason: "Test \(i)"
            )
        }
        
        // Should only keep max (50)
        XCTAssertEqual(monitor.recentViolations.count, 50)
        
        // Should keep most recent ones
        XCTAssertEqual(monitor.recentViolations[0].reason, "Test 100")
    }
}

