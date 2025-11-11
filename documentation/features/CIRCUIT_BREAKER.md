# Circuit Breaker Pattern Implementation

## Overview

The circuit breaker pattern has been implemented to prevent cascading failures by temporarily blocking requests to failing endpoints. When an endpoint experiences repeated failures, the circuit "opens" and blocks subsequent requests for a timeout period, giving the backend time to recover.

## Implementation Details

### Circuit States

The circuit breaker operates in three states:

| State | Description | Behavior |
|-------|-------------|----------|
| **Closed** | Normal operation | All requests allowed |
| **Open** | Service failing | Requests blocked for 60 seconds |
| **Half-Open** | Testing recovery | Limited requests allowed to test if service recovered |

### State Transitions

```
        ┌─────────────┐
        │   Closed    │ ◄─────────┐
        │ (Normal)    │           │
        └──────┬──────┘           │
               │                  │
        5 failures                │
               │              Success
               ▼                  │
        ┌─────────────┐           │
        │    Open     │           │
        │ (Blocking)  │           │
        └──────┬──────┘           │
               │                  │
        60s timeout               │
               │                  │
               ▼                  │
        ┌─────────────┐           │
        │  Half-Open  │───────────┘
        │ (Testing)   │
        └──────┬──────┘
               │
          Failure
               │
               ▼
        Back to Open
```

### Configuration

- **Failure Threshold**: 5 consecutive failures
- **Timeout**: 60 seconds
- **Per-Endpoint**: Each API endpoint has an independent circuit

## Architecture

### CircuitBreaker Actor
**File**: `VeloReady/Core/Networking/CircuitBreaker.swift`

Thread-safe actor that manages circuit state:

```swift
actor CircuitBreaker {
    static let shared = CircuitBreaker()

    // Check if request should be allowed
    func shouldAllowRequest(endpoint: String) async -> Bool

    // Record result of request
    func recordResult(endpoint: String, success: Bool)

    // Get current state
    func getState(endpoint: String) -> State

    // Get failure count
    func getFailureCount(endpoint: String) -> Int

    // Get time remaining until circuit can be tested
    func getTimeRemaining(endpoint: String) -> TimeInterval?

    // Reset circuit
    func reset(endpoint: String? = nil)
}
```

### VeloReadyAPIClient Updates
**File**: `VeloReady/Core/Networking/VeloReadyAPIClient.swift`

**New Error Case** (Line 417):
```swift
case circuitOpen(retryAfter: TimeInterval)
```

**Error Message**:
```
"Service temporarily unavailable due to repeated failures. Please try again in {seconds} seconds."
```

**Integration** (Line 143-181):
- Checks circuit breaker before making request
- Records success/failure after each attempt
- Throws `circuitOpen` error if circuit is open

## Behavior

### Normal Operation (Closed)

When the circuit is closed, requests flow normally:

1. Check circuit state → Closed
2. Allow request to proceed
3. Record result (success or failure)
4. Update failure counter

### Circuit Opens (5 Failures)

After 5 consecutive failures:

1. Circuit state → Open
2. Start 60-second timeout timer
3. Block all subsequent requests
4. Return `circuitOpen` error immediately

### Timeout Period (Open)

During the 60-second timeout:

1. All requests blocked
2. Error includes retry-after time
3. No network calls made
4. Circuit waits for recovery

### Testing Recovery (Half-Open)

After 60 seconds:

1. Circuit state → Half-Open
2. Allow limited requests through
3. **If request succeeds**: Circuit → Closed, reset counters
4. **If request fails**: Circuit → Open, restart timeout

### Success in Any State

When a request succeeds:

- **Closed**: Reset failure counter to 0
- **Half-Open**: Close circuit, reset all counters
- **Open**: Should not occur (requests blocked)

## Benefits

### 1. Prevents Cascading Failures
- Stops avalanche of requests to failing service
- Gives backend time to recover
- Prevents resource exhaustion

### 2. Fail Fast
- Immediate error response (no network wait)
- Better user experience than timeout
- Reduces app perceived latency

### 3. Automatic Recovery
- Tests recovery after timeout
- Self-healing system
- No manual intervention required

### 4. Per-Endpoint Protection
- Independent circuits per endpoint
- Activities failure doesn't block streams
- Granular failure isolation

### 5. Resource Conservation
- Reduces unnecessary network calls
- Saves battery and bandwidth
- Prevents backend overload

## Testing

### Unit Tests
**File**: `VeloReadyTests/Unit/CircuitBreakerTests.swift`

Comprehensive test suite with 15+ test cases:

#### State Tests
- ✅ Circuit starts in closed state
- ✅ Circuit remains closed on success
- ✅ Circuit opens after 5 failures
- ✅ Requests blocked when open

#### Threshold Tests
- ✅ 4 failures keep circuit closed
- ✅ 5th failure opens circuit
- ✅ Failure count tracked correctly

#### Endpoint Isolation Tests
- ✅ Different endpoints have independent circuits
- ✅ Opening one circuit doesn't affect others

#### Reset Tests
- ✅ Reset specific endpoint
- ✅ Reset all endpoints

#### Monitoring Tests
- ✅ Get current state
- ✅ Get failure count
- ✅ Get time remaining

#### Integration Test
- ✅ **Full flow**: 5 failures → circuit opens → requests blocked for 60s

### Running Tests

```bash
# Run all circuit breaker tests
xcodebuild test -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:VeloReadyTests/CircuitBreakerTests

# Run integration test
xcodebuild test -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:VeloReadyTests/CircuitBreakerTests/testFullCircuitBreakerFlow
```

### Manual Testing

Simulate repeated failures to trigger circuit breaker:

```swift
// Make 5+ failed requests
for i in 1...6 {
    do {
        let activities = try await VeloReadyAPIClient.shared.fetchActivities()
        print("Request \(i): Success")
    } catch VeloReadyAPIError.circuitOpen(let retryAfter) {
        print("Request \(i): Circuit open - retry in \(Int(retryAfter))s")
    } catch {
        print("Request \(i): Failed - \(error)")
    }
}
```

**Expected Output**:
```
Request 1: Failed - networkError(...)
Request 2: Failed - networkError(...)
Request 3: Failed - networkError(...)
Request 4: Failed - networkError(...)
Request 5: Failed - networkError(...)
Request 6: Circuit open - retry in 60s
```

## Logging

The circuit breaker produces detailed logs when debug logging is enabled:

### Closed State (Normal)
```
⚡ [CircuitBreaker] /api/activities - State: CLOSED, allowing request
```

### Tracking Failures
```
⚠️ [CircuitBreaker] /api/activities - Failure 1/5 in CLOSED
⚠️ [CircuitBreaker] /api/activities - Failure 2/5 in CLOSED
⚠️ [CircuitBreaker] /api/activities - Failure 3/5 in CLOSED
⚠️ [CircuitBreaker] /api/activities - Failure 4/5 in CLOSED
```

### Circuit Opens
```
🔴 [CircuitBreaker] /api/activities - Threshold reached (5/5) → OPEN
```

### Requests Blocked
```
🔴 [CircuitBreaker] /api/activities - Circuit OPEN, blocking request (retry in 45s)
🔴 [VeloReady API] Circuit breaker OPEN for /api/activities - blocking request
```

### Half-Open Testing
```
🔄 [CircuitBreaker] /api/activities - Timeout expired, moving to HALF-OPEN
🟡 [CircuitBreaker] /api/activities - State: HALF-OPEN, allowing test request
```

### Successful Recovery
```
✅ [CircuitBreaker] /api/activities - Success in HALF-OPEN → CLOSED (recovered)
```

### Failed Recovery
```
🔴 [CircuitBreaker] /api/activities - Failure in HALF-OPEN → OPEN (recovery failed)
```

## Integration with Other Features

### Client-Side Throttling
Circuit breaker runs **before** throttle checks:
1. Check circuit breaker (fastest)
2. If circuit open → deny immediately
3. If circuit closed → check throttle → make request

### Exponential Backoff Retry
Circuit breaker and retry work together:
1. Request fails → retry with backoff
2. After 3 retries → record final failure
3. After 5 total failures (including retries) → circuit opens
4. Future requests blocked without retry attempts

### Request Flow
```
User Request
    ↓
Check Circuit Breaker
    ↓
Circuit Open? ──YES──> Throw circuitOpen error
    │
    NO
    ↓
Check Throttle
    ↓
Make Request (with retries)
    ↓
Record Result in Circuit Breaker
    ↓
Success / Failure
```

## Monitoring

### Check Circuit State

```swift
// Get current state
let state = await CircuitBreaker.shared.getState(endpoint: "/api/activities")
print("Circuit state: \(state)") // closed, open, or halfOpen

// Get failure count
let failures = await CircuitBreaker.shared.getFailureCount(endpoint: "/api/activities")
print("Failures: \(failures)/5")

// Get time remaining (if open)
if let remaining = await CircuitBreaker.shared.getTimeRemaining(endpoint: "/api/activities") {
    print("Retry in: \(Int(remaining))s")
}
```

### Dashboard Example

```swift
struct CircuitBreakerStatus: View {
    @State private var activitiesState: CircuitBreaker.State = .closed
    @State private var streamsState: CircuitBreaker.State = .closed

    var body: some View {
        VStack {
            HStack {
                Text("Activities:")
                Text(activitiesState.rawValue)
                    .foregroundColor(activitiesState == .open ? .red : .green)
            }
            HStack {
                Text("Streams:")
                Text(streamsState.rawValue)
                    .foregroundColor(streamsState == .open ? .red : .green)
            }
        }
        .task {
            // Update state periodically
            while true {
                activitiesState = await CircuitBreaker.shared.getState(endpoint: "/api/activities")
                streamsState = await CircuitBreaker.shared.getState(endpoint: "/api/streams")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
}
```

## Configuration

### Adjusting Failure Threshold

Edit `CircuitBreaker.swift`:
```swift
private let failureThreshold = 5 // Change to desired number
```

**Recommendations**:
- **Lower (3-4)**: More sensitive, faster protection, may be too aggressive
- **Higher (7-10)**: More tolerant, slower to open, may allow more failures

### Adjusting Timeout

Edit `CircuitBreaker.swift`:
```swift
private let timeout: TimeInterval = 60 // Change to desired seconds
```

**Recommendations**:
- **Shorter (30s)**: Faster recovery testing, may reopen quickly
- **Longer (120s)**: More time for backend recovery, slower to test

## Troubleshooting

### Circuit Opens Too Easily

**Symptoms**: Circuit opens after only a few failures, normal transient errors cause blocks

**Solutions**:
1. Increase failure threshold (5 → 7 or 10)
2. Verify errors are truly failures (check logging)
3. Check if retries are working correctly

### Circuit Stays Open Too Long

**Symptoms**: Users wait too long before service is available again

**Solutions**:
1. Reduce timeout (60s → 30s)
2. Check backend recovery time
3. Implement health check endpoints

### Circuit Not Opening

**Symptoms**: Repeated failures but circuit stays closed

**Solutions**:
1. Verify `recordResult()` is being called
2. Check if failures are being recorded correctly
3. Enable debug logging to see circuit state

### False Circuit Opens

**Symptoms**: Circuit opens when backend is actually healthy

**Solutions**:
1. Check error classification (network vs. client errors)
2. Verify failure counting logic
3. Increase threshold to be more tolerant

## Performance Impact

### Latency Impact

| Scenario | Impact | Explanation |
|----------|--------|-------------|
| **Circuit Closed** | ~0ms | Simple state check |
| **Circuit Open** | ~0ms | Immediate failure, no network call |
| **Circuit Half-Open** | ~0ms | Simple state check |

### Memory Usage

- **Per Endpoint**: ~100 bytes (state + counters + timestamps)
- **10 Endpoints**: ~1 KB total
- **Negligible** impact on app memory

### CPU Usage

- **State checks**: Microseconds (simple if/switch)
- **State updates**: Milliseconds (actor synchronization)
- **Negligible** CPU impact

### Network Impact

- **Circuit Closed**: No change
- **Circuit Open**: **Reduces network calls** (no requests sent)
- **Significant savings** when circuit is open

## Best Practices

### 1. Monitor Circuit State

Implement observability to track:
- How often circuits open
- Which endpoints are problematic
- Recovery success rate

### 2. Alert on Circuit Opens

Notify operations team when:
- Circuit opens (indicates backend issues)
- Circuit stays open for extended period
- Multiple circuits open simultaneously

### 3. Graceful Degradation

When circuit is open:
- Show cached data if available
- Display user-friendly error message
- Offer manual retry option

### 4. Test Recovery Paths

Regularly test:
- Circuit opens after failures
- Circuit closes after recovery
- Half-open state transitions correctly

### 5. Coordinate with Backend

- Backend should have health check endpoints
- Circuit timeout should align with backend recovery time
- Monitor backend metrics alongside circuit state

## Code References

- **CircuitBreaker Actor**: `/Users/markboulton/Dev/VeloReady/VeloReady/Core/Networking/CircuitBreaker.swift`
- **VeloReadyAPIClient Integration**: `/Users/markboulton/Dev/VeloReady/VeloReady/Core/Networking/VeloReadyAPIClient.swift:143-181`
- **Error Case**: `/Users/markboulton/Dev/VeloReady/VeloReady/Core/Networking/VeloReadyAPIClient.swift:417`
- **Unit Tests**: `/Users/markboulton/Dev/VeloReady/VeloReadyTests/Unit/CircuitBreakerTests.swift`

## Future Enhancements

Possible improvements:
- [ ] Configurable thresholds per endpoint
- [ ] Adaptive timeout based on failure patterns
- [ ] Circuit breaker metrics/analytics
- [ ] Health check integration
- [ ] Bulkhead pattern for request isolation
- [ ] Fallback strategies (cached data, degraded mode)
- [ ] Circuit state persistence across app restarts

## Related Documentation

- [Exponential Backoff Retry](EXPONENTIAL_BACKOFF_RETRY.md)
- [Client-Side Throttling](CLIENT_SIDE_THROTTLING.md)
- [Backend Rate Limiting](../veloready-website/RATE_LIMIT_TESTING.md)
- [Network Architecture](NETWORK_ARCHITECTURE.md)
