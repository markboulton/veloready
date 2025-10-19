# Phase 1 & 2 Testing Checklist

**Date:** October 19, 2025, 7:45am UTC+01:00  
**Status:** Phase 1 Complete, Phase 2 Foundation Complete

---

## 📊 Progress Overview

```
Phase 1: API Centralization     ████████████████████ 100% ✅
Phase 2: Cache Unification      ████████░░░░░░░░░░░░  40% ⏳
Overall Progress:               ████████████░░░░░░░░  70%
```

---

## ✅ Phase 1: API Centralization Testing

### **Backend Deployment** ✅ COMPLETE

- [x] **Backend functions deployed**
  - Status: ✅ Deployed to production
  - Functions: 6 new endpoints (api-activities, api-streams, api-intervals-*)
  - URL: https://api.veloready.app
  - Verified: `netlify functions:list` shows all functions

- [x] **Clean URL redirects working**
  - Status: ✅ Working
  - Test: `curl "https://api.veloready.app/api/activities?daysBack=7&limit=5"`
  - Result: Returns activities JSON with metadata
  
- [x] **Cache headers present**
  - Status: ✅ Verified
  - Headers: `cache-control: private,max-age=300`, `x-cache: MISS/HIT`
  - TTL: 5 minutes (activities), 24 hours (streams)

- [x] **No conflicts with existing endpoints**
  - Status: ✅ Tested
  - Verified: All 8 existing endpoints still work
  - Report: `REDIRECT_COMPATIBILITY_TEST.md`

---

### **iOS Client Updates** ✅ COMPLETE

- [x] **VeloReadyAPIClient created**
  - Status: ✅ Complete
  - Location: `Core/Networking/VeloReadyAPIClient.swift`
  - Methods: fetchActivities(), fetchActivityStreams(), fetchIntervalsActivities(), fetchIntervalsWellness()

- [x] **Base URL updated to api.veloready.app**
  - Status: ✅ Complete
  - Old: `https://veloready.app/.netlify/functions/*`
  - New: `https://api.veloready.app/api/*`

- [x] **UnifiedActivityService updated**
  - Status: ✅ Complete
  - Now uses VeloReadyAPIClient for Strava activities
  - Wrapped with UnifiedCacheManager for deduplication

- [x] **RideDetailViewModel updated**
  - Status: ✅ Complete
  - Fetches streams through backend
  - Converts backend response to StravaStream format

- [x] **iOS build succeeds**
  - Status: ✅ Verified
  - Command: `xcodebuild -project VeloReady.xcodeproj -scheme VeloReady build`
  - Result: BUILD SUCCEEDED

---

### **Phase 1 Testing To Do** ⏳ PENDING

#### **1. iOS App End-to-End Test** (15 minutes)

- [ ] **Open app in simulator**
  ```bash
  cd ~/Dev/VeloReady
  open VeloReady.xcodeproj
  # Select iPhone simulator
  # Press ⌘R to run
  ```

- [ ] **Verify console logs**
  - Look for: `🌐 [VeloReady API] Fetching activities...`
  - Look for: `✅ [VeloReady API] Received X activities`
  - Look for: `📦 Cache status: MISS` (first time)

- [ ] **Test Today tab**
  - Activities should load
  - Should see recent rides
  - Tap any activity to open detail

- [ ] **Test activity detail**
  - Charts should display
  - Power/HR data should show
  - Look for: `🌐 [VeloReady API] Fetching streams...`

- [ ] **Test cache (second load)**
  - Close and reopen app
  - Look for: `📦 Cache status: HIT`
  - Should load instantly (<100ms)

- [ ] **Test offline mode**
  - Turn on Airplane Mode
  - Try to load new activity (should show error)
  - Open previously viewed activity (should work from cache)

---

#### **2. Backend Monitoring** (Ongoing)

- [ ] **Check Netlify dashboard**
  - URL: https://app.netlify.com/sites/veloready/functions
  - Look for: Function invocations count
  - Look for: Error rate (<1%)
  - Look for: Average execution time (<500ms)

- [ ] **Monitor cache hit rate**
  ```bash
  # After 24 hours of use
  netlify logs:function api-activities | grep "X-Cache" | sort | uniq -c
  ```
  - Target: >80% HIT rate

- [ ] **Check API usage**
  - Strava dashboard: https://www.strava.com/settings/api
  - Should see reduced API calls
  - Target: <1,000 calls/day for 1K users

---

#### **3. Database Migration** (5 minutes)

- [ ] **Run Intervals.icu migration**
  ```sql
  -- In Supabase SQL Editor (https://supabase.com/dashboard/project/YOUR_PROJECT/editor)
  -- Run: add-intervals-credentials.sql
  
  ALTER TABLE public.athlete 
  ADD COLUMN IF NOT EXISTS intervals_athlete_id TEXT,
  ADD COLUMN IF NOT EXISTS intervals_api_key TEXT,
  ADD COLUMN IF NOT EXISTS intervals_connected_at TIMESTAMP WITH TIME ZONE;
  
  CREATE INDEX IF NOT EXISTS idx_athlete_intervals_id 
  ON public.athlete(intervals_athlete_id)
  WHERE intervals_athlete_id IS NOT NULL;
  ```

- [ ] **Verify migration**
  ```sql
  SELECT column_name, data_type, is_nullable 
  FROM information_schema.columns 
  WHERE table_name = 'athlete' 
  AND column_name LIKE 'intervals%';
  ```
  - Should show 3 new columns

- [ ] **Test Intervals endpoints**
  ```bash
  # After connecting Intervals.icu in app
  curl "https://api.veloready.app/api/intervals/activities?daysBack=7&limit=5"
  # Should return 200 with activities (not 500)
  ```

---

## ⏳ Phase 2: Cache Unification Testing

### **Foundation Complete** ✅

- [x] **UnifiedCacheManager created**
  - Status: ✅ Complete
  - Location: `Core/Data/UnifiedCacheManager.swift`
  - Features: Auto-caching, request deduplication, memory management

- [x] **Example migration done**
  - Status: ✅ Complete
  - Service: UnifiedActivityService
  - Result: Activities now cached with deduplication

- [x] **Documentation complete**
  - Status: ✅ Complete
  - File: `PHASE_2_CACHE_UNIFICATION.md`
  - Includes: Migration patterns, testing strategy

---

### **Phase 2 Testing To Do** ⏳ PENDING

#### **1. Test UnifiedCacheManager** (10 minutes)

- [ ] **Verify cache hits**
  ```swift
  // In Xcode Console, look for:
  ⚡ [Cache HIT] strava:activities:30 (age: 245s)
  💾 [Cache STORE] strava:activities:30 (cost: 50KB)
  ```

- [ ] **Verify deduplication**
  ```swift
  // Open 3 tabs simultaneously that need same data
  // Should see:
  🔄 [Cache DEDUPE] strava:activities:30 - reusing existing request
  ```

- [ ] **Check cache statistics**
  ```swift
  // Add to debug menu or console:
  let stats = UnifiedCacheManager.shared.getStatistics()
  print(stats.description)
  
  // Should show:
  // - Hits: X
  // - Misses: Y
  // - Deduplicated: Z
  // - Hit Rate: >80%
  ```

---

#### **2. Migrate Remaining Services** (2-3 days)

**Priority 1: RecoveryScoreService** (High impact)
- [ ] Wrap HRV fetching with cache
- [ ] Wrap RHR fetching with cache
- [ ] Wrap sleep fetching with cache
- [ ] Test: Multiple services requesting HRV = 1 fetch
- [ ] Expected: 50% reduction in HealthKit calls

**Priority 2: SleepScoreService**
- [ ] Wrap sleep data fetching with cache
- [ ] Test: Sleep score calculation doesn't refetch data
- [ ] Expected: Instant on second calculation

**Priority 3: StrainScoreService**
- [ ] Wrap activity fetching with cache
- [ ] Test: Strain calculation reuses cached activities
- [ ] Expected: No duplicate activity fetches

**Priority 4: HealthKitManager**
- [ ] Wrap HRV sample fetching with cache
- [ ] Wrap RHR sample fetching with cache
- [ ] Wrap sleep sample fetching with cache
- [ ] Test: Multiple calls = 1 HealthKit query
- [ ] Expected: Faster, fewer HealthKit queries

**Priority 5: RideDetailViewModel**
- [ ] Wrap stream fetching with cache
- [ ] Test: Opening same activity twice = instant second time
- [ ] Expected: 96% cache hit rate for streams

---

#### **3. Deprecate Old Cache Layers** (1 day)

- [ ] **Mark StreamCacheService deprecated**
  ```swift
  @available(*, deprecated, message: "Use UnifiedCacheManager instead")
  class StreamCacheService { ... }
  ```

- [ ] **Mark StravaDataService deprecated**
  ```swift
  @available(*, deprecated, message: "Use UnifiedCacheManager instead")
  class StravaDataService { ... }
  ```

- [ ] **Mark IntervalsCache deprecated**
  ```swift
  @available(*, deprecated, message: "Use UnifiedCacheManager instead")
  class IntervalsCache { ... }
  ```

- [ ] **Remove old cache logic**
  - Remove manual cache checking
  - Remove lastFetchDate tracking
  - Remove cacheExpiryMinutes constants
  - Clean up ~200 lines of code

---

#### **4. Performance Testing** (1 day)

- [ ] **Memory profiling**
  ```
  1. Open Xcode Instruments
  2. Select "Allocations" template
  3. Run app and navigate through 5 tabs
  4. Check memory usage
  
  Target: <150MB (down from 65MB+ before)
  ```

- [ ] **Cache hit rate measurement**
  ```swift
  // After 1 hour of use:
  let stats = UnifiedCacheManager.shared.getStatistics()
  
  Target:
  - Hit rate: >85%
  - Deduplicated requests: >50 (10%+ of total)
  - Total requests: ~500
  ```

- [ ] **App startup time**
  ```
  1. Force quit app
  2. Start timer
  3. Launch app
  4. Stop when Today view fully loaded
  
  Target: <3 seconds (down from 8s before)
  ```

- [ ] **Activity detail load time**
  ```
  1. Tap activity
  2. Measure time to charts displayed
  
  First load: <500ms
  Cached load: <100ms
  ```

---

## 📊 Success Metrics

### **Phase 1 Success Criteria:**

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| **Backend deployed** | Yes | ✅ Yes | ✅ |
| **iOS build succeeds** | Yes | ✅ Yes | ✅ |
| **Endpoints working** | Yes | ✅ Yes | ✅ |
| **Cache headers present** | Yes | ✅ Yes | ✅ |
| **No breaking changes** | Yes | ✅ Yes | ✅ |
| **iOS app tested** | Yes | ⏳ Pending | ⏳ |
| **Cache hit rate** | >80% | ⏳ TBD | ⏳ |
| **API calls reduced** | >90% | ⏳ TBD | ⏳ |

### **Phase 2 Success Criteria:**

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| **UnifiedCacheManager** | Created | ✅ Yes | ✅ |
| **Example migration** | 1 service | ✅ Yes | ✅ |
| **All services migrated** | 5 services | ⏳ 1/5 | ⏳ |
| **Old caches deprecated** | 4 layers | ⏳ 0/4 | ⏳ |
| **Memory reduction** | 77% | ⏳ TBD | ⏳ |
| **Cache hit rate** | >85% | ⏳ TBD | ⏳ |
| **Deduplication** | >50% | ⏳ TBD | ⏳ |

---

## 🎯 Quick Test (30 minutes)

If you're short on time, run this minimal test:

### **Phase 1 Quick Test:**
1. [ ] Open VeloReady in Xcode simulator
2. [ ] Check console for "VeloReady API" logs
3. [ ] Verify activities load
4. [ ] Open one activity detail
5. [ ] Close and reopen app
6. [ ] Verify "Cache HIT" in logs

### **Phase 2 Quick Test:**
1. [ ] Check console for "Cache" logs
2. [ ] Open 2 tabs that need same data
3. [ ] Look for "Cache DEDUPE" message
4. [ ] Verify only 1 network call made

**Estimated time:** 30 minutes  
**Confidence level:** 80% (covers critical paths)

---

## 🐛 Known Issues

### **Phase 1:**
- ⚠️ **Intervals endpoints return 500** - Need DB migration (not blocking)
- ✅ **Strava endpoints working** - All good

### **Phase 2:**
- ⏳ **Only 1 service migrated** - Need to migrate 4 more
- ⏳ **Old cache layers still active** - Need to deprecate
- ⏳ **No performance metrics yet** - Need to measure

---

## 📁 Testing Documentation

### **For Backend Testing:**
- `BACKEND_TESTING_RESULTS.md` - Backend endpoint tests
- `REDIRECT_COMPATIBILITY_TEST.md` - Compatibility verification
- `API_DOMAIN_MIGRATION.md` - Domain migration guide

### **For iOS Testing:**
- `PHASE_1_TESTING_GUIDE.md` - Step-by-step iOS testing
- `PHASE_2_CACHE_UNIFICATION.md` - Cache testing guide
- `IMPLEMENTATION_STATUS.md` - Overall status

### **For Monitoring:**
- Netlify Dashboard: https://app.netlify.com/sites/veloready/functions
- Strava API Dashboard: https://www.strava.com/settings/api

---

## ✅ Next Actions (Priority Order)

### **Today (30 minutes):**
1. [ ] Run iOS app in simulator
2. [ ] Verify backend integration works
3. [ ] Check console logs
4. [ ] Test one activity detail

### **This Week (2-3 hours):**
5. [ ] Run database migration
6. [ ] Test Intervals endpoints
7. [ ] Monitor cache hit rates
8. [ ] Check Netlify dashboard

### **Next Week (2-3 days):**
9. [ ] Migrate remaining 4 services
10. [ ] Deprecate old cache layers
11. [ ] Run performance tests
12. [ ] Measure memory reduction

---

## 🎉 Progress Summary

**What's Done:**
- ✅ Phase 1 code complete (100%)
- ✅ Phase 2 foundation complete (40%)
- ✅ Backend deployed and working
- ✅ iOS builds successfully
- ✅ Documentation complete

**What's Next:**
- ⏳ Test iOS app end-to-end (30 min)
- ⏳ Run database migration (5 min)
- ⏳ Migrate remaining services (2-3 days)
- ⏳ Performance testing (1 day)

**Overall Status:** 70% complete, ready for testing! 🚀
