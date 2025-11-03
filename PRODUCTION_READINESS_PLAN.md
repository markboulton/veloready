# VeloReady Production Readiness Plan

## Overview
- **Timeline:** 6 weeks (30 work days)
- **Approach:** Supabase subscriptions (no RevenueCat), Redis rate limiting, cache-first offline, virtualized lists
- **Priority:** P0 (Subscription) → P1 (Rate Limiting) → P2 (Offline) → P3 (Performance)

---

## Sprint 1: Subscription Foundation (Week 1)

### Day 1: Database Schema
1. Create `veloready-website/supabase/migrations/003_subscriptions.sql` (see separate SQL file)
2. Run migration: `cd veloready-website && npx supabase db push`
3. Verify in Supabase dashboard: Check `user_subscriptions` table exists
4. Test RLS: Try reading another user's subscription (should fail)
5. Confirm all existing users have 'free' tier

### Day 2: iOS Subscription Sync
1. **Update `SubscriptionManager.swift`:**
   - Add `syncToBackend() async` method after line 238
   - Fetch latest transaction details
   - Upsert to Supabase `user_subscriptions` table
   - Call from `updateProFeatureConfig()` at line 172

2. **Update `SupabaseClient.swift`:**
   - Add `var currentUserId: String?` property

3. **Create `Date+Extensions.swift`:**
   - Add `var iso8601String: String` computed property

4. **Test:** Trigger purchase → Check Supabase table updates

### Day 3: Backend Authentication Enhancement
1. **Replace `netlify/lib/auth.ts`:**
   - Import Supabase with service key
   - Add `AuthResult` interface with `subscriptionTier`
   - Update `authenticate()` to query `user_subscriptions`
   - Add subscription expiry check (downgrade expired to 'free')
   - Export `TIER_LIMITS` constants (free: 90d/100 activities, pro: 365d/500 activities)
   - Export `getTierLimits(tier)` helper

2. **Test:** Create unit test for auth with valid/invalid/expired tokens

### Day 4: Enforce Limits in API Endpoints
1. **Update `api-activities.ts`:**
   - Import `authenticate` and `getTierLimits`
   - Parse `daysBack` and `limit` query params
   - Check if requested > tier limits
   - Return 403 with upgrade message if exceeded
   - Add metadata to response (tier, limits)

2. **Repeat for:**
   - `api-streams.ts`
   - `api-intervals-activities.ts`
   - `api-intervals-streams.ts`
   - `api-wellness.ts`

3. **Test:** FREE user requests 365 days → 403, PRO user → success

### Day 5: iOS Error Handling
1. **Update `VeloReadyAPIClient.swift`:**
   - Add `VeloReadyAPIError.tierLimitExceeded(message, tier, showUpgrade)`
   - Add `VeloReadyAPIError.authenticationFailed`
   - Create `TierLimitError` struct
   - Update `makeRequest()` to handle 403 (tier limit) and 401 (auth failed)
   - Show upgrade prompt when tier limit hit

2. **Test:** FREE user → upgrade prompt, PRO user → no prompt

---

## Sprint 2: Rate Limiting (Week 2)

### Day 6: Upstash Redis Setup
1. Sign up at [upstash.com](https://upstash.com)
2. Create Redis database
3. Add to `veloready-website/.env`:
   ```
   UPSTASH_REDIS_REST_URL=...
   UPSTASH_REDIS_REST_TOKEN=...
   ```
4. Install: `npm install @upstash/redis`
5. **Create `netlify/lib/rate-limit.ts`:**
   - Import Upstash Redis
   - Export `checkRateLimit(userId, athleteId, tier, endpoint)` function
   - Use hourly sliding window (key format: `rate_limit:{athleteId}:{endpoint}:{hour}`)
   - Return `{ allowed, remaining, resetAt }`
   - Export `trackStravaCall(athleteId)` for Strava limits (100/15min, 1000/day)

6. **Test:** Make 61 requests as FREE user → block at 61st

### Day 7: Apply Rate Limiting to Endpoints
1. **Update `api-activities.ts` and `api-streams.ts`:**
   - Call `checkRateLimit()` before processing
   - Return 429 if limit exceeded
   - Add headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`, `Retry-After`

2. **Test:** Hammer endpoint 100x → verify 429 response and headers

### Day 8: iOS Client Throttling
1. **Create `Core/Networking/RequestThrottler.swift`:**
   - Actor-based throttler
   - Track timestamps per endpoint (activities: 10/min, streams: 20/min)
   - Return `(allowed, retryAfter)`

2. **Update `VeloReadyAPIClient.swift`:**
   - Add `checkThrottle(endpoint)` method
   - Call before `makeRequest()`
   - Throw `VeloReadyAPIError.throttled(retryAfter)`

3. **Test:** Make 11 requests in 30s → throttle 11th

### Day 9: Exponential Backoff
1. **Create `Core/Networking/RetryPolicy.swift`:**
   - Actor-based retry tracker
   - Max 3 retries with backoff: 1s, 2s, 4s
   - Reset counter on success

2. **Update `VeloReadyAPIClient.swift`:**
   - Add `makeRequestWithRetry()` wrapper
   - Catch errors and retry with delay
   - Record success to reset counter

3. **Test:** Simulate network failure → verify 3 retries with correct delays

### Day 10: Circuit Breaker Pattern
1. **Create `Core/Networking/CircuitBreaker.swift`:**
   - Three states: closed (normal), open (failing), halfOpen (testing)
   - Open circuit after 5 consecutive failures
   - Try recovery after 60s timeout
   - Export `shouldAllowRequest(endpoint)` and `recordResult(endpoint, success)`

2. **Update `VeloReadyAPIClient.swift`:**
   - Check circuit breaker before making request
   - Record success/failure after each attempt

3. **Test:** Trigger 5 failures → circuit opens → requests blocked for 60s

---

## Sprint 3: Offline Mode (Week 3)

### Day 11: Network Monitor
1. **Create `Core/Services/NetworkMonitor.swift`:**
   - Use `NWPathMonitor` to track connectivity
   - Publish `isConnected` and `connectionType`
   - Log offline/online transitions

2. **Update views to observe network status**

### Day 12: Cache-First Strategy
1. **Update `UnifiedCacheManager.swift`:**
   - Add `fetchCacheFirst()` method
   - Return cache immediately (even if stale)
   - Background refresh if stale and online
   - Throw `.offline` error if no cache and offline

2. **Test:** Go offline → app shows cached data

### Day 13: Core Data as Offline Store
1. **Create `CachePersistenceLayer.swift`:**
   - Bridge memory cache to Core Data
   - Save to `DailyScores`, `DailyLoad`, `DailyPhysio` entities
   - Load from Core Data if memory cache empty

2. **Test:** Kill app offline → relaunch → data persists

### Day 14: Offline Write Queue
1. **Create `OfflineWriteQueue.swift`:**
   - Queue RPE ratings, manual activities when offline
   - Persist queue to UserDefaults
   - Sync when network restored

2. **Test:** Add RPE offline → go online → syncs to backend

### Day 15: Offline UI States
1. **Create `OfflineBanner.swift` component:**
   - Show at top when offline
   - Hide when online
   - Show "Syncing..." when coming back online

2. **Add to TodayView, TrendsView, ActivitiesView**

---

## Sprint 4: Performance Optimization (Week 4)

### Day 16-17: Windowed Chart Data
1. **Update `TrendChart.swift`:**
   - Add `@State private var visibleDateRange: ClosedRange<Date>?`
   - Use `.chartScrollableAxes(.horizontal)` modifier
   - Add `.chartXVisibleDomain(length:)` modifier
   - Filter `data` to `visibleDataPoints` (only visible range)
   - Implement `loadDataForWindow(domain)` method

2. **Test:** Scroll 60-day chart → only visible data rendered

### Day 18-19: Virtual Scrolling for Activities
1. **Update `ActivitiesViewModel.swift`:**
   - Add pagination: `currentPage`, `pageSize = 15`
   - Computed `paginatedActivities` property
   - Add `loadNextPage()` method

2. **Update `ActivitiesView.swift`:**
   - Use `LazyVGrid` instead of `LazyVStack`
   - Add `.onAppear` to last item → trigger `loadNextPage()`
   - Show loading spinner at bottom when loading

3. **Test:** Scroll to bottom → next page loads

### Day 20-21: Async Map Generation
1. **Update `LatestActivityCardV2.swift`:**
   - Add `@State private var mapSnapshot: UIImage?`
   - Add `@State private var isGeneratingMap = false`
   - Use `.task { mapSnapshot = await generateMapAsync() }`
   - Show placeholder while loading

2. **Create `MapSnapshotService.swift` (if not exists):**
   - Move generation to `Task.detached(priority: .utility)`
   - Use background thread for `MKMapSnapshotter`

3. **Test:** Scroll activities → maps load progressively without jank

### Day 22: Core Data Batch Fetching
1. **Update `StrainDetailViewModel.swift` (and similar):**
   - Add `fetchBatchSize = 20` to fetch requests
   - Set `returnsObjectsAsFaults = false`
   - Set `propertiesToFetch` to only needed columns
   - Consider `NSFetchedResultsController` for automatic updates

2. **Test:** Large dataset → smooth scrolling

---

## Sprint 5: Testing & Polish (Week 5)

### Day 23-24: Integration Testing
- Test complete subscription flow: purchase → sync → backend enforcement
- Test rate limiting under load
- Test offline → online → sync flow
- Test all error states (403, 429, offline, etc.)

### Day 25-26: Performance Testing
- Profile with Instruments (Time Profiler, Allocations)
- Test with 500+ activities
- Test on slow network (3G simulation)
- Measure app launch time, chart render time

### Day 27: Bug Fixes
- Fix issues found during testing
- Add logging for edge cases
- Handle race conditions

---

## Sprint 6: Rollout & Monitoring (Week 6)

### Day 28: Staged Rollout
1. Deploy backend to Netlify
2. Submit iOS build to TestFlight
3. Test with 10 beta users (monitor logs)
4. Fix any critical issues

### Day 29: Production Deploy
1. Promote backend to production
2. Submit iOS to App Store
3. Monitor error logs in real-time
4. Watch Redis metrics

### Day 30: Documentation & Handoff
1. Update README with new architecture
2. Document subscription tiers and limits
3. Create troubleshooting guide
4. Update API documentation

---

## Success Metrics

**Subscription Enforcement:**
- ✅ 0% unauthorized API access
- ✅ Backend validates tier on every request
- ✅ Upgrade prompts show correctly

**Rate Limiting:**
- ✅ No users exceed tier limits
- ✅ Strava API never hits daily limit
- ✅ 429 responses handled gracefully

**Offline Mode:**
- ✅ App usable offline with cached data
- ✅ Writes queued and synced when online
- ✅ Clear offline indicators

**Performance:**
- ✅ 60 FPS scrolling with 500+ activities
- ✅ <2s app launch time
- ✅ Charts render in <500ms

---

## Rollback Plan

If critical issues arise:

1. **Backend:** Revert Netlify deploy (instant)
2. **iOS:** Can't rollback, but can:
   - Feature flag to disable new code
   - Emergency update with fixes
3. **Database:** Keep old schema alongside new (backward compatible)

---

## Tier Limits Reference

| Feature | Free | Pro |
|---------|------|-----|
| Activity History | 90 days | 365 days |
| Max Activities per Request | 100 | 500 |
| API Calls per Hour (Activities) | 60 | 300 |
| API Calls per Hour (Streams) | 30 | 100 |
| Chart Time Ranges | 7d, 30d | 7d, 30d, 60d, 90d |
| AI Briefs | Daily | Daily + Weekly + Monthly |
| Map Overlays | Basic | HR/Power Gradients |
| Data Export | No | CSV/JSON |

---

## Dependencies

**Backend:**
- Supabase (database + auth)
- Upstash Redis (rate limiting)
- Netlify Functions (serverless)

**iOS:**
- StoreKit 2 (subscriptions)
- Core Data (offline storage)
- Network framework (connectivity)

---

## Questions & Answers

**Q: Why not RevenueCat?**
A: StoreKit 2 is sufficient for iOS-only. RevenueCat adds value for cross-platform (Android/Web).

**Q: Can we add features to free tier later?**
A: Yes, just update `TIER_LIMITS` in backend and redeploy.

**Q: What if Upstash Redis goes down?**
A: Rate limiting fails open (allows requests). App continues working.

**Q: How to test without hitting Strava limits?**
A: Use mock data in development, or test with test athlete account.
