# Exponential Backoff Retry Logic Implementation

## Overview

Exponential backoff retry logic has been implemented to handle transient network failures gracefully. When a network request fails due to a retryable error (e.g., timeout, connection lost), the app will automatically retry the request with increasing delays.

## Implementation Details

### Retry Behavior

- **Max Retries**: 3 attempts per endpoint
- **Exponential Delays**: 1s, 2s, 4s (calculated as 2^attempt)
- **Reset Window**: Failure counters reset after 5 minutes of no failures
- **Per-Endpoint Tracking**: Each API endpoint has independent failure counters

### Architecture

#### 1. ExponentialBackoffRetryPolicy Actor
**File**: `VeloReady/Core/Networking/RetryPolicy.swift`

Thread-safe actor that manages retry state and decisions:

```swift
actor ExponentialBackoffRetryPolicy {
    static let shared = ExponentialBackoffRetryPolicy()

    // Check if request should be retried
    func shouldRetry(endpoint: String, error: Error) async -> (retry: Bool, delay: TimeInterval)

    // Record successful request to reset counters
    func recordSuccess(endpoint: String)

    // Get current failure count for endpoint
    func getFailureCount(endpoint: String) -> Int

    // Reset retry state
    func reset(endpoint: String? = nil)
}
```

**Key Features**:
- Tracks failure count per endpoint
- Records last failure timestamp
- Resets counters after 5 minutes
- Calculates exponential backoff delays
- Determines if errors are retryable

#### 2. VeloReadyAPIClient Updates
**File**: `VeloReady/Core/Networking/VeloReadyAPIClient.swift`

Added `makeRequestWithRetry` wrapper that:
1. Attempts the request via `makeRequest()`
2. On success, records success to reset counters
3. On failure, checks if error is retryable
4. If retryable, waits for exponential delay
5. Recursively retries up to max attempts

**Integration Points**:
- Line 42: `fetchActivities()` uses `makeRequestWithRetry()`
- Line 74: `fetchActivityStreams()` uses `makeRequestWithRetry()`
- Line 97: `fetchIntervalsActivities()` uses `makeRequestWithRetry()`
- Line 116: `fetchIntervalsWellness()` uses `makeRequestWithRetry()`

### Retryable vs Non-Retryable Errors

#### ✅ Retryable Errors

Errors that indicate transient failures worth retrying:

| Error Type | Example | Retryable |
|------------|---------|-----------|
| **Network Errors** | Connection timeout, DNS failure | ✅ Yes |
| **Server Errors (5xx)** | 500, 502, 503, 504 | ✅ Yes |
| **URLError Types** | `.timedOut`, `.networkConnectionLost`, `.notConnectedToInternet`, `.cannotConnectToHost` | ✅ Yes |

#### ❌ Non-Retryable Errors

Errors that won't be fixed by retrying:

| Error Type | Example | Retryable |
|------------|---------|-----------|
| **Client Errors (4xx)** | 400, 403, 404 | ❌ No |
| **Authentication** | Token expired, invalid credentials | ❌ No |
| **Rate Limiting** | 429 Too Many Requests | ❌ No |
| **Throttling** | Client-side throttle | ❌ No |
| **Tier Limits** | Free plan limit exceeded | ❌ No |
| **Client-Side Errors** | Invalid URL, decoding errors | ❌ No |

### Retry Flow

```
┌─────────────────┐
│ Make Request    │
└────────┬────────┘
         │
         ▼
    ┌────────┐
    │Success?│
    └───┬─┬──┘
        │ │
    YES │ │ NO
        │ │
        ▼ ▼
┌───────┐ ┌──────────────┐
│Record │ │  Retryable   │
│Success│ │    Error?    │
└───┬───┘ └──────┬───┬───┘
    │           │   │
    │       YES │   │ NO
    │           │   │
    │           ▼   ▼
    │     ┌─────────┐  ┌────────────┐
    │     │Max      │  │Throw Error │
    │     │Retries? │  └────────────┘
    │     └────┬─┬──┘
    │          │ │
    │      YES │ │ NO
    │          │ │
    │          ▼ │
    │    ┌─────────┐
    │    │Throw    │
    │    │Error    │
    │    └─────────┘
    │              │
    │              ▼
    │        ┌──────────┐
    │        │Wait Delay│
    │        │(1s,2s,4s)│
    │        └────┬─────┘
    │             │
    │             ▼
    │        ┌─────────┐
    └────────┤Retry    │
             │Request  │
             └─────────┘
```

## Testing

### Unit Tests
**File**: `VeloReadyTests/Unit/RetryPolicyTests.swift`

Comprehensive test suite with 16 test cases:

#### Basic Retry Tests
- ✅ Network errors are retryable
- ✅ Server errors (5xx) are retryable
- ✅ 5xx HTTP errors are retryable
- ✅ 4xx HTTP errors are NOT retryable
- ✅ Authentication errors are NOT retryable
- ✅ Rate limit errors are NOT retryable
- ✅ Throttled errors are NOT retryable

#### Exponential Backoff Tests
- ✅ Correct delays: 1s, 2s, 4s
- ✅ Max retries enforced (3 attempts)

#### Success Reset Tests
- ✅ Success resets failure counters

#### Time Window Tests
- ✅ Failure count resets after 5 minutes

#### Endpoint Isolation Tests
- ✅ Different endpoints have separate counters

#### Integration Test
- ✅ **Full retry flow with actual delays** (testNetworkFailure_ThreeRetriesWithExponentialBackoff)

### Running Tests

```bash
# Run all retry policy tests
xcodebuild test -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:VeloReadyTests/RetryPolicyTests

# Run integration test
xcodebuild test -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:VeloReadyTests/RetryPolicyTests/testNetworkFailure_ThreeRetriesWithExponentialBackoff
```

### Manual Testing

Simulate network failure to verify retry behavior:

```swift
// In debug build, simulate network timeout
do {
    let activities = try await VeloReadyAPIClient.shared.fetchActivities()
    print("✅ Success: \(activities.count) activities")
} catch {
    print("❌ Failed after retries: \(error)")
}
```

**Expected Behavior**:
```
🔁 [RetryPolicy] Will retry /api/activities (attempt 1/3) after 1s
⏳ [VeloReady API] Waiting 1s before retry...
🔁 [RetryPolicy] Will retry /api/activities (attempt 2/3) after 2s
⏳ [VeloReady API] Waiting 2s before retry...
🔁 [RetryPolicy] Will retry /api/activities (attempt 3/3) after 4s
⏳ [VeloReady API] Waiting 4s before retry...
⚠️ [RetryPolicy] Max retries (3) reached for /api/activities
❌ Failed after retries: networkError(...)
```

## Logging

The retry policy produces detailed logs when debug logging is enabled:

### Retry Allowed
```
🔁 [RetryPolicy] Will retry /api/activities (attempt 1/3) after 1s
⏳ [VeloReady API] Waiting 1s before retry...
```

### Max Retries Reached
```
⚠️ [RetryPolicy] Max retries (3) reached for /api/activities
```

### Success Reset
```
✅ [RetryPolicy] Success for /api/activities - failure count reset
```

### Failure Count Reset (5 minutes)
```
🔄 [RetryPolicy] Resetting failure count for /api/activities (>5 min since last failure)
```

### Non-Retryable Error
```
🚫 [RetryPolicy] Error is not retryable for /api/activities: authenticationFailed
```

## Benefits

### 1. Improved Reliability
- Automatically handles transient network failures
- No manual intervention required
- Transparent to the user

### 2. Better User Experience
- Reduces "Network Error" messages for temporary issues
- App appears more stable and reliable
- Smoother experience on poor connections

### 3. Intelligent Backoff
- Exponential delays prevent overwhelming the server
- Gives time for transient issues to resolve
- Respects server recovery time

### 4. Per-Endpoint Isolation
- Different endpoints don't affect each other
- Activities endpoint failure doesn't prevent streams from working
- Granular failure tracking

### 5. Smart Error Handling
- Only retries errors that make sense
- Doesn't retry authentication or client errors
- Prevents infinite retry loops

## Configuration

### Adjusting Max Retries

Edit `RetryPolicy.swift`:
```swift
private let maxRetries = 3 // Change to desired number
```

### Adjusting Reset Window

Edit `RetryPolicy.swift`:
```swift
private let resetWindow: TimeInterval = 300 // 5 minutes, change as needed
```

### Adjusting Delay Formula

Current formula: `2^attempt` (1s, 2s, 4s)

To change:
```swift
// In shouldRetry method
let delay = pow(2.0, Double(failureCount)) // Current

// Alternative: Linear backoff (1s, 2s, 3s)
let delay = Double(failureCount + 1)

// Alternative: Slower exponential (1s, 1.5s, 2.25s)
let delay = pow(1.5, Double(failureCount))
```

## Integration with Existing Features

### Client-Side Throttling
Retry logic works **after** throttle checks:
1. Check throttle (fast, local)
2. If allowed, make request
3. If request fails, apply retry logic

### Server-Side Rate Limiting
- Server 429 responses are **not** retried
- Client should wait for `Retry-After` header
- Prevents wasting retry attempts on rate limits

### Request Flow
```
User Request
    ↓
Check Throttle (RequestThrottler)
    ↓
Make Request (makeRequestWithRetry)
    ↓
[Retry Logic with Exponential Backoff]
    ↓
Success / Final Failure
```

## Monitoring

### Check Retry State

```swift
// Get current failure count
let failureCount = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: "/api/activities")
print("Current failures: \(failureCount)/3")
```

### Reset Retry State

```swift
// Reset specific endpoint
await ExponentialBackoffRetryPolicy.shared.reset(endpoint: "/api/activities")

// Reset all endpoints
await ExponentialBackoffRetryPolicy.shared.reset()
```

## Troubleshooting

### Retries Not Working

1. **Check error type**: Only retryable errors trigger retries
   ```swift
   // Enable debug logging
   Logger.isDebugLoggingEnabled = true
   ```

2. **Verify max retries not reached**: Check failure count
   ```swift
   let count = await ExponentialBackoffRetryPolicy.shared.getFailureCount(endpoint: "/api/activities")
   ```

3. **Reset retry state if stuck**:
   ```swift
   await ExponentialBackoffRetryPolicy.shared.reset()
   ```

### Too Many Retries

If requests are taking too long due to retries:

1. Check if errors are truly transient
2. Consider reducing max retries
3. Check server health (5xx errors indicate server issues)

### Retries on Non-Transient Errors

If you see retries on errors that shouldn't be retried:

1. Check `isRetryableError()` logic in `RetryPolicy.swift`
2. Add error type to non-retryable list
3. File a bug report

## Performance Impact

### Delay Overhead

| Scenario | Total Time | Breakdown |
|----------|-----------|-----------|
| **Success (no retry)** | ~200-500ms | Network request only |
| **1 retry** | ~1.2-1.5s | Request + 1s delay + retry |
| **2 retries** | ~3.2-3.5s | Request + 1s + 2s delays + retries |
| **3 retries** | ~7.2-7.5s | Request + 1s + 2s + 4s delays + retries |

### Resource Usage

- **Memory**: Minimal (only tracks timestamps per endpoint)
- **CPU**: Negligible (simple arithmetic)
- **Battery**: Minimal impact from delays
- **Network**: Additional attempts on failure only

## Code References

- **ExponentialBackoffRetryPolicy Actor**: `/Users/markboulton/Dev/VeloReady/VeloReady/Core/Networking/RetryPolicy.swift`
- **makeRequestWithRetry**: `/Users/markboulton/Dev/VeloReady/VeloReady/Core/Networking/VeloReadyAPIClient.swift:143-168`
- **Activities Integration**: `/Users/markboulton/Dev/VeloReady/VeloReady/Core/Networking/VeloReadyAPIClient.swift:42`
- **Streams Integration**: `/Users/markboulton/Dev/VeloReady/VeloReady/Core/Networking/VeloReadyAPIClient.swift:74`
- **Unit Tests**: `/Users/markboulton/Dev/VeloReady/VeloReadyTests/Unit/RetryPolicyTests.swift`

## Future Enhancements

Possible improvements:
- [ ] Jittered delays to prevent thundering herd
- [ ] Adaptive retry based on server load
- [ ] Retry budget per time window
- [ ] Analytics on retry success rate
- [ ] User notification for persistent failures
- [ ] Circuit breaker pattern for cascading failures

## Related Documentation

- [Client-Side Throttling](CLIENT_SIDE_THROTTLING.md)
- [Backend Rate Limiting](../veloready-website/RATE_LIMIT_TESTING.md)
- [Network Architecture](NETWORK_ARCHITECTURE.md)
