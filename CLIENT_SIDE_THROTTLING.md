# Client-Side Request Throttling Implementation

## Overview

Client-side request throttling has been implemented to prevent overwhelming the VeloReady backend API. This complements the server-side rate limiting (100-300 req/hour based on tier) with more aggressive client-side limits to ensure a smooth user experience.

## Implementation Details

### Rate Limits

| Endpoint | Limit | Window |
|----------|-------|--------|
| `/api/activities` | 10 requests | 1 minute |
| `/api/streams` | 20 requests | 1 minute |
| Default | 30 requests | 1 minute |

### Architecture

#### 1. RequestThrottler Actor
**File**: `VeloReady/Core/Networking/RequestThrottler.swift`

Thread-safe actor using Swift's actor model that:
- Tracks request timestamps per endpoint
- Implements sliding window rate limiting
- Provides reset functionality for testing
- Offers monitoring methods (getCurrentCount, getRemainingRequests)

**Key Methods**:
```swift
// Check if request should be allowed
func shouldAllowRequest(endpoint: String) async -> (allowed: Bool, retryAfter: TimeInterval?)

// Reset throttle state (useful for testing)
func reset(endpoint: String? = nil)

// Get current request count in window
func getCurrentCount(endpoint: String) -> Int

// Get remaining requests allowed
func getRemainingRequests(endpoint: String) -> Int
```

#### 2. VeloReadyAPIClient Updates
**File**: `VeloReady/Core/Networking/VeloReadyAPIClient.swift`

Added throttle checking before API requests:

**New Error Case**:
```swift
case throttled(retryAfter: TimeInterval)
```

**Error Message**:
```
"Too many requests. Please wait {seconds} seconds before trying again."
```

**Integration Points**:
- `fetchActivities()` - Line 38: Checks throttle before fetching
- `fetchActivityStreams()` - Line 68: Checks throttle before fetching

**Private Helper**:
```swift
private func checkThrottle(endpoint: String) async throws {
    let result = await RequestThrottler.shared.shouldAllowRequest(endpoint: endpoint)

    if !result.allowed {
        Logger.warning("🛑 [VeloReady API] Request throttled for \(endpoint)")
        throw VeloReadyAPIError.throttled(retryAfter: result.retryAfter ?? 60)
    }
}
```

## Testing

### Unit Tests
**File**: `VeloReadyTests/Unit/RequestThrottlerTests.swift`

Comprehensive test suite covering:
- ✅ Activities endpoint allows 10 requests/minute
- ✅ Activities endpoint throttles 11th request
- ✅ Streams endpoint allows 20 requests/minute
- ✅ Streams endpoint throttles 21st request
- ✅ Endpoints have separate quotas
- ✅ Concurrent request handling
- ✅ Reset functionality
- ✅ Real-world scenario: 11 requests in 30 seconds

### Running Tests

```bash
# Run all throttler tests
xcodebuild test -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:VeloReadyTests/RequestThrottlerTests

# Run specific test
xcodebuild test -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:VeloReadyTests/RequestThrottlerTests/testRealWorldScenario_11RequestsIn30Seconds
```

### Manual Testing

1. **Enable Debug Logging**:
   ```swift
   // In Settings → Debug
   Logger.isDebugLoggingEnabled = true
   ```

2. **Trigger Throttling**:
   ```swift
   // Make rapid activity requests
   for i in 1...11 {
       do {
           let activities = try await VeloReadyAPIClient.shared.fetchActivities()
           print("Request \(i): Success - \(activities.count) activities")
       } catch VeloReadyAPIError.throttled(let retryAfter) {
           print("Request \(i): Throttled - retry after \(Int(retryAfter))s")
       } catch {
           print("Request \(i): Error - \(error)")
       }
   }
   ```

3. **Expected Output**:
   ```
   Request 1: Success - 45 activities
   Request 2: Success - 45 activities
   ...
   Request 10: Success - 45 activities
   Request 11: Throttled - retry after 42s
   ```

## Logging

The throttler produces detailed logs when debug logging is enabled:

**Allowed Requests**:
```
✅ [RequestThrottler] Allowing /api/activities - 5/10 requests in window
```

**Throttled Requests**:
```
⏱️ [RequestThrottler] Throttling /api/activities - 10/10 requests in window
⏱️ [RequestThrottler] Retry after: 45s
🛑 [VeloReady API] Request throttled for /api/activities
```

## Benefits

### 1. Prevents Backend Overload
- Stops runaway request loops before hitting backend
- Reduces 429 responses from server
- Improves backend stability

### 2. Better User Experience
- Faster throttle feedback (no network round-trip)
- Clear retry-after guidance
- Prevents app from appearing frozen during throttled periods

### 3. Cost Optimization
- Reduces unnecessary network calls
- Lowers bandwidth usage
- Minimizes backend processing costs

### 4. Debug-Friendly
- Reset functionality for testing
- Detailed logging
- Monitoring methods for observability

## Integration with Backend Rate Limiting

The client-side throttling works in conjunction with backend rate limiting:

| Layer | Limit | Purpose |
|-------|-------|---------|
| **Client** | 10-30/min | Prevent runaway requests, fast feedback |
| **Backend** | 100-300/hour | Enforce tier limits, prevent abuse |

**Fail-Safe Design**: If client throttling is bypassed, backend rate limiting still applies.

## Edge Cases Handled

1. **Concurrent Requests**: Actor model ensures thread safety
2. **Sliding Window**: Old timestamps automatically expire after 60 seconds
3. **Endpoint Isolation**: Each endpoint has independent quota
4. **Reset on Error**: App can reset throttle state if needed
5. **Graceful Degradation**: Returns retry-after guidance

## Future Enhancements

Possible improvements:
- [ ] Exponential backoff for repeated throttles
- [ ] Per-user persistent throttle state (across app restarts)
- [ ] Adaptive rate limits based on network conditions
- [ ] Analytics on throttle frequency
- [ ] User notification when repeatedly throttled

## Code References

- **RequestThrottler Actor**: `/Users/markboulton/Dev/VeloReady/VeloReady/Core/Networking/RequestThrottler.swift`
- **VeloReadyAPIClient**: `/Users/markboulton/Dev/VeloReady/VeloReady/Core/Networking/VeloReadyAPIClient.swift:122-129` (checkThrottle)
- **Activities Integration**: `/Users/markboulton/Dev/VeloReady/VeloReady/Core/Networking/VeloReadyAPIClient.swift:38`
- **Streams Integration**: `/Users/markboulton/Dev/VeloReady/VeloReady/Core/Networking/VeloReadyAPIClient.swift:68`
- **Error Case**: `/Users/markboulton/Dev/VeloReady/VeloReady/Core/Networking/VeloReadyAPIClient.swift:365`
- **Unit Tests**: `/Users/markboulton/Dev/VeloReady/VeloReadyTests/Unit/RequestThrottlerTests.swift`

## Monitoring

To monitor throttle effectiveness in production:

```swift
// Check current request counts
let activitiesCount = await RequestThrottler.shared.getCurrentCount(endpoint: "/api/activities")
let streamsCount = await RequestThrottler.shared.getCurrentCount(endpoint: "/api/streams")

// Check remaining quota
let remaining = await RequestThrottler.shared.getRemainingRequests(endpoint: "/api/activities")
print("Remaining requests: \(remaining)/10")
```

## Troubleshooting

### Throttle Not Working

1. Check actor is initialized: `RequestThrottler.shared`
2. Verify `checkThrottle()` is called before `makeRequest()`
3. Enable debug logging: `Logger.isDebugLoggingEnabled = true`

### False Throttles

1. Reset state: `await RequestThrottler.shared.reset()`
2. Check system time accuracy
3. Verify endpoint string matches exactly

### Test Failures

1. Ensure tests call `setUp()` to reset state
2. Check for timing-sensitive tests near minute boundaries
3. Run tests individually to avoid interference
