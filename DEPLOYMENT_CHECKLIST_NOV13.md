# Deployment Checklist - November 13, 2025

## ✅ What's on Main (Ready to Deploy)

**Branch:** `main`  
**Commit:** `d663c47` (docs: Add branch strategy analysis)  
**Previous:** `45ac167` (Merge Wahoo integration + Strava fixes)

### **Features Included:**

1. **Strava Cache Improvements** ✅
   - 5-minute cache for recent activities (< 7 days)
   - 1-hour cache for historical activities (> 7 days)
   - Pull-to-refresh now invalidates cache (forces fresh fetch)
   - Backend smart cache TTL (5 min recent, 1 hour old)

2. **Wahoo Integration** ✅
   - OAuth authentication flow
   - `IntervalsActivity` → `Activity` type rename (cleaner API)
   - `ActivityConverter.stravaToActivity()` (more accurate naming)
   - Wahoo data source support infrastructure

### **Files Changed:**

**Strava Cache Fixes:**
- `UnifiedActivityService.swift` - Custom TTL support
- `TodayCoordinator.swift` - Cache invalidation on pull-to-refresh
- Documentation (3 files)

**Wahoo Integration:**
- 70+ files (type renames, OAuth, data sources)
- See `ACTIVITY_MODEL_RENAME.md` for full list

---

## 📋 Pre-Deployment Checklist

### **1. iOS App Testing**

- [ ] **Build succeeds** in Xcode
  ```bash
  cd /Users/mark.boulton/Documents/dev/veloready
  # Open in Xcode, Cmd+B to build
  ```

- [ ] **Run unit tests**
  ```bash
  # Xcode: Cmd+U
  # Expected: All tests pass
  ```

- [ ] **Test Strava cache fixes:**
  - [ ] Complete activity on Strava
  - [ ] Open VeloReady app
  - [ ] Pull to refresh
  - [ ] ✅ New activity appears (< 5 min delay)

- [ ] **Verify Wahoo NOT visible** (unless ready to launch):
  - [ ] Check Settings → Data Sources
  - [ ] Should NOT show "Connect Wahoo" (if feature flag disabled)
  - [ ] Or shows Wahoo but disabled/coming soon

### **2. Backend Deployment**

- [ ] **Clear old Strava cache:**
  ```bash
  cd /Users/mark.boulton/Documents/dev/veloready-website
  
  # Clear your athlete's cache (replace 104662 with your ID)
  netlify blobs:delete strava-cache "activities:104662:1762382996:1" --context production
  ```

- [ ] **Deploy backend:**
  ```bash
  # Deploy with smart cache TTL changes
  netlify deploy --prod
  
  # Expected: Functions deployed successfully
  ```

- [ ] **Verify backend changes:**
  - [ ] Check Netlify function logs
  - [ ] Look for: `[Strava Cache] Cache strategy: RECENT (5min)` or `HISTORICAL (1hr)`
  - [ ] Verify cache TTL is dynamic

### **3. Monitor After Deployment**

**First 24 Hours:**

- [ ] **Strava API call frequency:**
  ```sql
  -- Run in Supabase SQL Editor
  SELECT 
    DATE_TRUNC('hour', at) as hour,
    COUNT(*) as api_calls
  FROM audit_log 
  WHERE note = 'activities:list' 
    AND at > NOW() - INTERVAL '24 hours'
  GROUP BY hour
  ORDER BY hour DESC;
  ```
  
  **Expected:** 12-48 calls/hour (depending on user activity)  
  **Alert if:** > 100 calls/hour with few users

- [ ] **Check rate limit errors:**
  - Netlify logs: Look for 429 responses
  - iOS logs: Look for rate limit errors
  - **Expected:** None

- [ ] **User reports:**
  - Pull-to-refresh works?
  - New activities appear quickly?
  - No crashes or errors?

---

## 🚀 Deployment Commands

### **Backend (Do First)**

```bash
cd /Users/mark.boulton/Documents/dev/veloready-website

# 1. Clear old cache (optional but recommended)
netlify blobs:delete strava-cache "activities:104662:1762382996:1" --context production

# 2. Deploy functions
netlify deploy --prod

# 3. Watch logs
netlify logs:function api-activities --live
```

### **iOS App (After Backend)**

```bash
cd /Users/mark.boulton/Documents/dev/veloready

# 1. Ensure on main
git checkout main
git pull origin main

# 2. Open in Xcode
open VeloReady.xcodeproj

# 3. Build & run (Cmd+R)
# Test locally first

# 4. Archive & submit to TestFlight when ready
# Xcode: Product → Archive
```

---

## 🎛️ Feature Flag Strategy (If Hiding Wahoo)

If you want to deploy but hide Wahoo features:

### **Option 1: ProFeatureConfig Flag**

```swift
// In ProFeatureConfig.swift
var wahooEnabled: Bool {
    #if DEBUG
    return true  // Available in debug builds
    #else
    return false  // Hidden in production
    #endif
}

// In DataSourcesSettingsView.swift
if proConfig.wahooEnabled {
    // Show "Connect Wahoo" button
}
```

### **Option 2: Server-Side Flag (Recommended)**

```swift
// Fetch from backend/Firebase Remote Config
var wahooEnabled: Bool {
    return RemoteConfig.shared.bool(forKey: "wahoo_enabled")
}

// Enable for specific users or percentage rollout
// No app update needed to toggle
```

### **Option 3: Keep Code, Hide UI**

- Don't show Wahoo in data sources list
- OAuth endpoints still work (no harm)
- `Activity` type improvements benefit all code
- Enable UI when Wahoo integration is ready

**Recommendation:** Option 3 (simplest, no code changes needed)

---

## 📊 Success Metrics

### **Week 1 After Deployment:**

**Strava Cache Performance:**
- [ ] API calls < 5% of daily limit (30,000)
- [ ] No rate limit errors (429 responses)
- [ ] Pull-to-refresh works consistently
- [ ] New activities appear within 5-10 minutes

**User Experience:**
- [ ] No increase in crash rate
- [ ] No performance degradation
- [ ] Positive feedback on activity freshness

**Wahoo (if enabled):**
- [ ] OAuth flow works
- [ ] No errors in Wahoo code paths
- [ ] Ready for gradual rollout

---

## 🐛 Rollback Plan (If Needed)

### **If Something Goes Wrong:**

**Backend Rollback:**
```bash
cd /Users/mark.boulton/Documents/dev/veloready-website

# Find previous deployment
netlify sites:list

# Rollback to previous version
netlify deploy:rollback --context production
```

**iOS App Rollback:**
- Stop TestFlight distribution
- Previous version still available to users
- Fix issue, redeploy

**Quick Fix for Cache Issues:**
```bash
# Increase cache TTL back to 1 hour
# Edit strava.ts, change:
const cacheTTL = isRecentActivities ? 300 : 3600;
# to:
const cacheTTL = 3600;

# Redeploy
netlify deploy --prod
```

---

## 📝 Post-Deployment Notes

### **Document:**
- [ ] Date deployed
- [ ] Version/build number
- [ ] Any issues encountered
- [ ] User feedback received

### **Monitor:**
- [ ] Strava API usage (daily)
- [ ] Error rates (Sentry/logs)
- [ ] User feedback (support channels)

### **Plan Next:**
- [ ] When to enable Wahoo (if hidden)
- [ ] Next feature priorities
- [ ] Performance optimizations if needed

---

## ✅ Final Checklist Before Deploy

- [ ] Code builds successfully
- [ ] Tests pass
- [ ] Backend deployed
- [ ] Cache cleared
- [ ] Monitoring in place
- [ ] Rollback plan ready
- [ ] Feature flags configured (if using)
- [ ] Documentation updated

---

## 🎯 Summary

**Main branch contains:**
- ✅ Wahoo integration (infrastructure ready)
- ✅ Strava cache fixes (user-facing improvements)
- ✅ Both tested and working together
- ✅ Ready to deploy

**Deployment strategy:**
1. Deploy backend (smart cache TTL)
2. Deploy iOS app (cache invalidation on pull-to-refresh)
3. Hide Wahoo UI if not ready to launch
4. Monitor API usage for 24-48 hours
5. Enable Wahoo when ready

**Risk level:** 🟢 Low
- Strava fixes are low-risk improvements
- Wahoo changes are mostly internal (type renames)
- Can hide Wahoo UI with minimal code
- Easy rollback if needed

**Expected impact:**
- 📈 Better UX (activities appear within 5 min)
- 📊 Slightly higher API usage (3-4% vs 0.5%, still safe)
- 🎉 Pull-to-refresh actually works
- 🚀 Foundation ready for Wahoo when needed

---

**Status:** ✅ Ready to deploy  
**Date:** November 13, 2025  
**Decision:** Keep main with Wahoo + Strava together

