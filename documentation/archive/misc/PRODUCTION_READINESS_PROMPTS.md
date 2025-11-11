# VeloReady Production Readiness - Step-by-Step Prompts

Use these prompts to guide implementation. Copy/paste each prompt when you're ready for that step.

---

## Sprint 1: Subscription Foundation (Week 1)

### ✅ Day 1: Database Schema
**Status:** COMPLETE
- Migration created: `003_subscriptions.sql`
- Table: `user_subscriptions` with RLS, indexes, triggers

---

### ✅ Day 2: iOS Subscription Sync
**Status:** COMPLETE
- Added `currentUserId` to SupabaseClient.swift
- Added `athleteId` property to StravaAuthService.swift
- Created Date+Extensions.swift with iso8601String
- Added `syncToBackend()` to SubscriptionManager.swift
- See: `DAY_2_COMPLETE.md` for details

---

### Day 2 (OLD - COMPLETED):

**Prompt:**
```
Implement iOS subscription sync to Supabase backend:

1. Update SubscriptionManager.swift:
   - Add syncToBackend() async method after line 238
   - Extract transaction details (id, productId, expiration)
   - Map subscriptionStatus to tier/status/dates
   - Upsert to Supabase user_subscriptions table
   - Call syncToBackend() from updateProFeatureConfig() at line 172

2. Update SupabaseClient.swift:
   - Add computed property: var currentUserId: String?
   - Return session?.user.id.uuidString

3. Create Date+Extensions.swift:
   - Add computed property: var iso8601String: String
   - Use ISO8601DateFormatter()

Test: Trigger a test purchase and verify Supabase table updates with correct tier.
```

---

### Day 3: Backend Authentication Enhancement

**Prompt:**
```
Enhance backend authentication to include subscription tier:

1. Replace netlify/lib/auth.ts completely:
   - Import Supabase with service key (SUPABASE_SERVICE_KEY)
   - Create AuthResult interface with: userId, athleteId, subscriptionTier, subscriptionExpires
   - Update authenticate(request) function to:
     * Extract JWT from Authorization header
     * Verify with Supabase auth.getUser()
     * Get athlete_id from user metadata
     * Query user_subscriptions table for tier
     * Check if subscription expired (downgrade to 'free' if so)
     * Return AuthResult
   - Export TIER_LIMITS constant with free/pro/trial limits:
     * free: 90 days, 100 activities, 60 activities/hour, 30 streams/hour
     * pro: 365 days, 500 activities, 300 activities/hour, 100 streams/hour
     * trial: same as pro
   - Export getTierLimits(tier) helper function

Test: Create unit test with valid/invalid/expired tokens.
```

---

### Day 4: Enforce Limits in API Endpoints

**Prompt:**
```
Add subscription tier enforcement to all API endpoints:

1. Update netlify/functions/api-activities.ts:
   - Import authenticate and getTierLimits from lib/auth
   - Call authenticate(request) at start
   - Parse daysBack and limit query params
   - Get tier limits: getTierLimits(subscriptionTier)
   - Check if requestedDays > limits.daysBack
   - If exceeded, return 403 with JSON error:
     * error: 'TIER_LIMIT_EXCEEDED'
     * message: upgrade prompt
     * currentTier, requestedDays, maxDaysAllowed
   - Cap requested values to tier limits
   - Add metadata to success response: tier, requestedDays, count

2. Repeat same pattern for:
   - api-streams.ts
   - api-intervals-activities.ts
   - api-intervals-streams.ts
   - api-wellness.ts

Test: FREE user requests 365 days → 403, PRO user → success.
```

---

### Day 5: iOS Error Handling

**Prompt:**
```
Add tier limit error handling to iOS API client:

1. Update VeloReady/Core/Networking/VeloReadyAPIClient.swift:
   - Add to VeloReadyAPIError enum:
     * case tierLimitExceeded(message: String, currentTier: String, upgrade: Bool)
     * case authenticationFailed
   - Add computed property shouldShowUpgradePrompt
   - Create TierLimitError struct (Codable) matching backend response
   - Update makeRequest() method:
     * Handle 403 status → decode TierLimitError → throw tierLimitExceeded
     * Handle 401 status → throw authenticationFailed
   - Add error descriptions for new cases

Test: FREE user hits limit → upgrade prompt shown, PRO user → no prompt.
```

---

## Sprint 2: Rate Limiting (Week 2)

### Day 6: Rate Limiting Setup

**Prompt:**
```
Set up Redis-based rate limiting infrastructure:

✅ SKIP: Upstash already configured (used for webhook queue)
✅ SKIP: Environment variables already set (UPSTASH_REDIS_REST_URL, UPSTASH_REDIS_REST_TOKEN)

1. Install dependency (if not already installed):
   cd veloready-website
   npm install @upstash/redis

2. Create netlify/lib/rate-limit.ts:
   - Import Redis from @upstash/redis
   - Import getTierLimits from ./auth
   - Use existing Upstash credentials from process.env
   - Export async function checkRateLimit(userId, athleteId, tier, endpoint):
     * Calculate hourly window: Math.floor(Date.now() / 3600000)
     * Create key: rate_limit:{athleteId}:{endpoint}:{window}
     * Increment counter with redis.incr()
     * Set expiry to 3600 seconds on first request
     * Get tier limit for endpoint
     * Return { allowed: boolean, remaining: number, resetAt: number }
   - Export async function trackStravaCall(athleteId):
     * Track 15-minute window (100 req limit)
     * Track daily window (1000 req limit)
     * Return boolean if allowed

Note: This uses the SAME Redis instance as webhook queue, but different key patterns:
- Webhook queue: queue:* keys
- Rate limiting: rate_limit:* keys
- No conflicts!

Test: Make 61 requests as FREE user → should block at 61st.
```

---

### Day 7: Apply Rate Limiting to Endpoints

**Prompt:**
```
Apply rate limiting to backend API endpoints:

1. Update netlify/functions/api-activities.ts:
   - Import checkRateLimit from lib/rate-limit
   - Call checkRateLimit(userId, athleteId, subscriptionTier, 'activities') after auth
   - If !rateLimit.allowed, return 429 with:
     * error: 'RATE_LIMIT_EXCEEDED'
     * message with retry time
     * tier, resetAt
     * Headers: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset, Retry-After
   - Add same headers to success response

2. Repeat for api-streams.ts (use 'streams' endpoint)

Test: Hammer endpoint 100x in 1 minute → verify 429 response and headers.
```

---

### Day 8: iOS Client Throttling

**Prompt:**
```
Add client-side request throttling to iOS app:

1. Create VeloReady/Core/Networking/RequestThrottler.swift:
   - Make it an actor for thread safety
   - Add static shared instance
   - Track requestTimestamps: [String: [Date]] dictionary
   - Define limits per endpoint: activities: 10/min, streams: 20/min, default: 30/min
   - Add method shouldAllowRequest(endpoint: String) async -> (allowed: Bool, retryAfter: TimeInterval?):
     * Filter timestamps to last 60 seconds
     * Check if count >= limit
     * If at limit, calculate retryAfter from oldest timestamp
     * If allowed, append current timestamp
     * Return result
   - Add reset(endpoint:) method

2. Update VeloReady/Core/Networking/VeloReadyAPIClient.swift:
   - Add checkThrottle(endpoint: String) async throws method
   - Call RequestThrottler.shared.shouldAllowRequest()
   - If not allowed, throw VeloReadyAPIError.throttled(retryAfter)
   - Call checkThrottle() before makeRequest() in fetchActivities() and fetchStreams()

Test: Make 11 activity requests in 30 seconds → should throttle 11th.
```

---

### Day 9: Exponential Backoff

**Prompt:**
```
Implement exponential backoff retry logic:

1. Create VeloReady/Core/Networking/RetryPolicy.swift:
   - Make it an actor
   - Add static shared instance
   - Track failureCounts: [String: Int] and lastFailures: [String: Date]
   - Add method shouldRetry(endpoint: String, error: Error) async -> (retry: Bool, delay: TimeInterval):
     * Reset counter if last failure was >5 minutes ago
     * Max 3 retries
     * Calculate exponential delay: pow(2.0, Double(failureCount)) (1s, 2s, 4s)
     * Increment failure count
     * Return retry decision and delay
   - Add recordSuccess(endpoint: String) to reset counters

2. Update VeloReadyAPIClient.swift:
   - Add makeRequestWithRetry<T>(url: URL, endpoint: String) async throws -> T wrapper
   - Try makeRequest(), catch errors
   - On error, check RetryPolicy.shouldRetry()
   - If should retry, sleep for delay, then recursively call makeRequestWithRetry()
   - On success, call RetryPolicy.recordSuccess()

Test: Simulate network failure → verify 3 retries with 1s, 2s, 4s delays.
```

---

### Day 10: Circuit Breaker Pattern

**Prompt:**
```
Implement circuit breaker to prevent cascading failures:

1. Create VeloReady/Core/Networking/CircuitBreaker.swift:
   - Make it an actor
   - Add static shared instance
   - Define State enum: closed, open, halfOpen
   - Track states: [String: State], failureCounts: [String: Int], lastFailures: [String: Date]
   - Set constants: failureThreshold = 5, timeout = 60 seconds
   - Add method shouldAllowRequest(endpoint: String) async -> Bool:
     * If closed: allow
     * If open: check if timeout expired, move to halfOpen if so, otherwise deny
     * If halfOpen: allow (testing recovery)
   - Add method recordResult(endpoint: String, success: Bool):
     * If success in halfOpen: move to closed, reset counters
     * If failure: increment counter, open circuit if threshold reached
     * Log state changes

2. Update VeloReadyAPIClient.swift:
   - Check CircuitBreaker.shouldAllowRequest() before making request
   - If not allowed, throw VeloReadyAPIError.circuitOpen
   - Record result after each attempt

Test: Trigger 5 consecutive failures → circuit opens → requests blocked for 60s.
```

---

## Sprint 3: Offline Mode (Week 3)

### Day 11: Network Monitor

**Prompt:**
```
Create network connectivity monitor:

1. Create VeloReady/Core/Services/NetworkMonitor.swift:
   - Make it @MainActor and ObservableObject
   - Add static shared instance
   - Import Network framework
   - Add @Published var isConnected: Bool = true
   - Add @Published var connectionType: NWInterface.InterfaceType?
   - Create NWPathMonitor instance
   - In init(), set pathUpdateHandler:
     * Update isConnected based on path.status
     * Update connectionType from path.availableInterfaces
     * Log transitions (offline/online)
   - Start monitor on background queue

2. Update key views to observe NetworkMonitor.shared.isConnected

Test: Toggle airplane mode → verify app detects offline/online state.
```

---

### Day 12: Cache-First Strategy

**Prompt:**
```
Implement cache-first data loading strategy:

1. Update VeloReady/Core/Data/UnifiedCacheManager.swift:
   - Add new method fetchCacheFirst<T>(key, ttl, fetchOperation):
     * Check if cache exists (even if stale)
     * If exists, return immediately
     * If stale AND online, start background Task.detached to refresh
     * If no cache AND offline, throw NetworkError.offline
     * If no cache AND online, call existing fetch() method
   - Add getExpiredCache() helper to return cache regardless of TTL

2. Update services to use fetchCacheFirst() for critical data:
   - UnifiedActivityService.fetchRecentActivities()
   - RecoveryScoreService (for baseline data)

Test: Go offline → app shows cached data, no errors.
```

---

### Day 13: Core Data as Offline Store

**Prompt:**
```
Bridge memory cache to Core Data for persistence:

1. Create VeloReady/Core/Data/CachePersistenceLayer.swift:
   - Make it an actor
   - Add static shared instance
   - Add method saveToCore Data<T: Codable>(key: String, value: T):
     * Get Core Data context
     * Parse key to determine entity (DailyScores, DailyLoad, etc.)
     * Save to appropriate entity
     * Call context.save()
   - Add method loadFromCoreData<T: Codable>(key: String) -> T?:
     * Query appropriate entity based on key
     * Decode and return

2. Update UnifiedCacheManager.swift:
   - After storing in memory cache, also call CachePersistenceLayer.saveToCore Data()
   - Before network fetch, try CachePersistenceLayer.loadFromCoreData()

Test: Kill app while offline → relaunch → data still available.
```

---

### Day 14: Offline Write Queue

**Prompt:**
```
Queue writes when offline for later sync:

1. Create VeloReady/Core/Services/OfflineWriteQueue.swift:
   - Make it an actor
   - Add static shared instance
   - Define QueuedWrite struct: id, type, payload, timestamp
   - Track queuedWrites: [QueuedWrite] array
   - Add method enqueue(_ write: QueuedWrite):
     * Append to array
     * Persist to UserDefaults
   - Add method syncWhenOnline() async:
     * Check NetworkMonitor.shared.isConnected
     * For each write, execute API call
     * Remove from queue on success
     * Save updated queue
   - Load queue from UserDefaults on init

2. Update relevant services:
   - RPE rating submissions
   - Manual activity creation
   - Settings changes

Test: Add RPE offline → go online → verify syncs to backend.
```

---

### Day 15: Offline UI States

**Prompt:**
```
Add offline indicators to UI:

1. Create VeloReady/Core/Components/OfflineBanner.swift:
   - ObserveObject NetworkMonitor.shared
   - Show banner at top when !isConnected
   - Show "Syncing..." when coming back online (OfflineWriteQueue.issyncing)
   - Auto-dismiss after 3 seconds when online
   - Use ColorScale.amberAccent for offline, greenAccent for syncing

2. Add OfflineBanner to:
   - TodayView (top of ZStack)
   - TrendsView
   - ActivitiesView

Test: Go offline → banner appears, go online → shows syncing, then dismisses.
```

---

## Sprint 4: Performance Optimization (Week 4)

### Day 16-17: Windowed Chart Data

**Prompt:**
```
Optimize chart rendering to only show visible data:

1. Update VeloReady/Features/Today/Views/Charts/TrendChart.swift:
   - Add @State private var visibleDateRange: ClosedRange<Date>?
   - Add computed property visibleDataPoints that filters data array to visible range
   - Update Chart to use visibleDataPoints instead of full data array
   - Add .chartScrollableAxes(.horizontal) modifier
   - Add .chartXVisibleDomain(length: selectedPeriod.visibleDays) modifier
   - Add .onChange(of: chartProxy.xVisibleDomain) to update visibleDateRange
   - Implement loadDataForWindow(domain) to fetch only visible data

Test: Scroll 60-day chart → verify only visible portion renders, smooth 60 FPS.
```

---

### Day 18-19: Virtual Scrolling for Activities

**Prompt:**
```
Add pagination to activities list:

1. Update VeloReady/Features/Activities/ViewModels/ActivitiesViewModel.swift:
   - Add @Published var currentPage: Int = 0
   - Add constant pageSize: Int = 15
   - Add computed property paginatedActivities: [UnifiedActivity]:
     * Return Array(allActivities.prefix((currentPage + 1) * pageSize))
   - Add @Published var isLoadingMore: Bool = false
   - Add method loadNextPage():
     * Guard !isLoadingMore
     * Increment currentPage
     * Set isLoadingMore = true briefly

2. Update VeloReady/Features/Activities/Views/ActivitiesView.swift:
   - Replace LazyVStack with LazyVGrid(columns: [GridItem(.flexible())])
   - Use viewModel.paginatedActivities instead of allActivities
   - Add .onAppear to last item to trigger loadNextPage()
   - Show ProgressView at bottom when isLoadingMore

Test: Scroll to bottom → next page loads, smooth scrolling with 500+ activities.
```

---

### Day 20-21: Async Map Generation

**Prompt:**
```
Move map snapshot generation to background thread:

1. Update VeloReady/Features/Today/Views/Components/LatestActivityCardV2.swift:
   - Add @State private var mapSnapshot: UIImage?
   - Add @State private var isGeneratingMap: Bool = false
   - Replace synchronous map with conditional:
     * If mapSnapshot exists: show Image(uiImage: mapSnapshot)
     * If isGeneratingMap: show ProgressView()
     * Else: show placeholder
   - Add .task { } modifier to generate map asynchronously

2. Create or update VeloReady/Core/Services/MapSnapshotService.swift:
   - Add method generateMapAsync(coordinates: [CLLocationCoordinate2D]) async -> UIImage?:
     * Wrap in Task.detached(priority: .utility)
     * Create MKMapSnapshotter.Options
     * Call snapshotter.start() on background thread
     * Return image

Test: Scroll activities → maps load progressively, no UI jank.
```

---

### Day 22: Core Data Batch Fetching

**Prompt:**
```
Optimize Core Data fetch requests for large datasets:

1. Update VeloReady/Features/Shared/ViewModels/StrainDetailViewModel.swift:
   - In fetchLoadTrendData() method:
     * Set request.fetchBatchSize = 20
     * Set request.returnsObjectsAsFaults = false
     * Set request.propertiesToFetch = ["date", "strainScore"]
     * Consider using NSFetchedResultsController for automatic updates

2. Repeat for similar view models:
   - RecoveryDetailViewModel
   - SleepDetailViewModel
   - TrendsViewModel

Test: Load 365 days of data → smooth scrolling, low memory usage.
```

---

## Sprint 5: Testing & Polish (Week 5)

### Day 23-24: Integration Testing

**Prompt:**
```
Run comprehensive integration tests:

1. Test subscription flow:
   - Purchase subscription in TestFlight
   - Verify Supabase table updates
   - Verify backend enforces tier
   - Verify iOS shows correct tier
   - Test upgrade prompts

2. Test rate limiting:
   - Make 100 requests in 1 minute as FREE user
   - Verify 429 responses
   - Verify headers correct
   - Test as PRO user (higher limits)

3. Test offline mode:
   - Go offline
   - Verify cached data shows
   - Add RPE rating
   - Go online
   - Verify sync happens

4. Test error states:
   - 403 tier limit
   - 429 rate limit
   - 401 auth failure
   - Network timeout
   - Circuit breaker open

Document any issues found.
```

---

### Day 25-26: Performance Testing

**Prompt:**
```
Profile and optimize performance:

1. Use Xcode Instruments:
   - Run Time Profiler with 500+ activities
   - Identify hot paths (>5% CPU)
   - Run Allocations to check memory leaks
   - Run Network profiler to verify caching

2. Test on slow network:
   - Enable Network Link Conditioner (3G)
   - Verify app remains responsive
   - Check cache-first strategy works

3. Measure key metrics:
   - App launch time (target: <2s)
   - Chart render time (target: <500ms)
   - Activity list scroll FPS (target: 60)
   - Memory usage with 500 activities (target: <100MB)

Document results and optimize bottlenecks.
```

---

### Day 27: Bug Fixes

**Prompt:**
```
Fix issues found during testing:

Provide me with the list of bugs found in testing, and I'll fix them one by one.

For each bug, tell me:
1. What's broken
2. Steps to reproduce
3. Expected vs actual behavior
4. Any error logs

I'll provide targeted fixes for each issue.
```

---

## Sprint 6: Rollout & Monitoring (Week 6)

### Day 28: Staged Rollout

**Prompt:**
```
Deploy to staging and test with beta users:

1. Deploy backend:
   - Push to Netlify staging branch
   - Verify environment variables set
   - Test all endpoints manually

2. Deploy iOS:
   - Submit build to TestFlight
   - Add 10 beta testers
   - Monitor crash logs in App Store Connect
   - Watch Supabase logs for errors

3. Monitor for 24 hours:
   - Check Redis metrics in Upstash
   - Check Supabase query performance
   - Review user feedback

Document any critical issues for immediate fix.
```

---

### Day 29: Production Deploy

**Prompt:**
```
Promote to production:

1. Backend:
   - Merge staging to main branch
   - Netlify auto-deploys to production
   - Verify production environment variables
   - Test production endpoints

2. iOS:
   - Submit to App Store for review
   - Monitor submission status
   - Prepare App Store listing updates

3. Real-time monitoring:
   - Watch error logs in Supabase
   - Monitor Redis rate limit hits
   - Check Netlify function logs
   - Set up alerts for 5xx errors

Be ready for emergency rollback if needed.
```

---

### Day 30: Documentation & Handoff

**Prompt:**
```
Create final documentation:

1. Update README.md with:
   - New architecture diagram (Supabase + Redis + Netlify)
   - Subscription tiers and limits table
   - Environment variables needed
   - Deployment instructions

2. Create TROUBLESHOOTING.md:
   - Common errors and solutions
   - How to check subscription status
   - How to reset rate limits
   - How to handle offline issues

3. Create API_DOCUMENTATION.md:
   - All endpoints with auth requirements
   - Rate limits per tier
   - Error response formats
   - Example requests/responses

4. Update .windsurfrules with new patterns and learnings.
```

---

## Quick Reference

**When you're ready to start a task, copy the prompt for that day and send it to me.**

**Example:**
```
I'm ready for Day 2. Here's the prompt:

[paste Day 2 prompt here]
```

**I'll then implement that specific task with all the code changes needed.**

---

## Emergency Contacts

**If something breaks:**
1. Check Supabase logs: Dashboard → Logs
2. Check Netlify logs: Dashboard → Functions → Logs
3. Check Redis: Upstash dashboard → Metrics
4. Check iOS: Xcode → Organizer → Crashes

**Rollback procedures:**
- Backend: Netlify → Deploys → Revert to previous
- iOS: Can't rollback, must submit hotfix
- Database: Supabase → SQL Editor → Run rollback migration
