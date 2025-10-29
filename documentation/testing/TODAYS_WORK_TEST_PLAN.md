# 30-Minute Test Plan - Today's Work

**Date:** October 19, 2025  
**Testing:** Phase 2, 3, 4 + Ops Dashboard  
**Time Required:** ~30 minutes

---

## 🎯 What We're Testing

Today's work includes:
1. **Phase 2:** iOS cache unification (HealthKit, services)
2. **Phase 3:** Backend optimization (1-hour cache)
3. **Phase 4:** Performance monitoring dashboard
4. **Ops Dashboard:** API stats, cache metrics, user management

---

## ✅ Test Checklist (30 Minutes)

### **Part 1: iOS App Testing** (15 minutes)

#### **Test 1: Verify Cache is Working** (5 min)

**Objective:** Confirm cache hits/misses are logging correctly

1. Open Xcode
2. Run VeloReady on iPhone 16 simulator
3. Open Console (Cmd+Shift+Y)
4. Watch for cache logs during app usage

**Expected Logs (First Launch):**
```
[Cache MISS] healthkit:hrv:...
[Cache STORE] healthkit:hrv:... (cost: 1KB)
📊 [Activities] Fetching from VeloReady backend
💾 [Cache STORE] strava:activities:7
```

5. **Pull down to refresh Today screen**

**Expected Logs (Second Time):**
```
⚡ [Cache HIT] healthkit:hrv:... (age: 45s)
⚡ [Cache HIT] strava:activities:7 (age: 120s)
```

**✅ Pass Criteria:**
- See `[Cache MISS]` on first fetch
- See `[Cache HIT]` on second fetch (within 5 min for HealthKit, 1 hour for activities)
- No errors

---

#### **Test 2: Cache Statistics Dashboard** (5 min)

**Objective:** Verify cache monitoring works

1. In app, go to: **Settings → Debug → Monitoring → Cache Statistics**
2. Check dashboard displays:
   - **Unified Cache:** Hit rate (should be >0% after warm-up)
   - **Stream Cache:** Activity count, samples
   - **Performance Metrics:** Operation timings
   - **Memory:** Current app memory usage

3. Tap **"Reset Statistics"** button
4. Go back to Today screen (pull to refresh)
5. Return to Cache Statistics

**Expected:** 
- Hit rate increases after navigating
- Performance metrics show operation timings
- Memory usage displayed

**✅ Pass Criteria:**
- Dashboard loads without crashes
- Metrics update when navigating
- "Reset Statistics" works

---

#### **Test 3: Performance Monitoring** (5 min)

**Objective:** Verify performance logging works

1. With Console open, navigate through app:
   - Today screen (recovery/sleep/strain)
   - Training tab (activity list)
   - Open an activity detail
   - Go to History tab

2. Watch Console for performance logs:
```
⚡ [Fetch Activities] 45ms
⚡ [Recovery Score Calculation] 234ms
⚡ [Stream cache HIT] 8ms
```

3. Check Cache Statistics → Performance Metrics section
   - Should show all measured operations
   - Average, P95, Max timings displayed

**✅ Pass Criteria:**
- Performance logs appear in console
- Slow operations (>1s) show warning: `🐌 SLOW: [Operation]`
- Performance metrics dashboard populates

---

### **Part 2: Backend Testing** (10 minutes)

#### **Test 4: Unified Ops Dashboard - Metrics** (5 min)

**Objective:** Verify unified ops dashboard works

1. Open browser to: **https://veloready.app/ops**
   (Or: `https://veloready.netlify.app/ops`)

2. Check **API & Cache Performance** section displays:
   - **Strava API Usage**: Total calls, usage %, progress bar
   - **Cache Performance**: Hit rate, cached vs. fetched
   - **Optimization Impact**: Reduction %, before/after
   - **Cache Configuration**: TTLs, cache types

3. Verify **System Metrics**:
   - Athletes count
   - Activities count
   - Queue depth
   - Deauthorizations

4. Check data updates (values are realistic)

**✅ Pass Criteria:**
- Dashboard loads without errors
- All metrics display (not showing "—")
- API usage < 1000 calls/day
- Cache hit rate > 0%
- Optimization shows >90% reduction

---

#### **Test 5: Ops Dashboard - User Management** (5 min)

**Objective:** Test admin actions

1. On ops dashboard, click **"👤 User Management"** button
2. Section expands showing action form

3. Enter your athlete ID (e.g., `104662`) in "Athlete ID" field

4. Click **"Get Stats"** button

**Expected:**
- Shows user statistics:
  - Total activities
  - Rides/Runs breakdown
  - First/Last activity dates
  - Total distance
  - Token status

5. Test other actions (⚠️ **CAREFUL - DESTRUCTIVE!**):
   - ❌ **DO NOT** test "Delete User" on real data
   - ❌ **DO NOT** test "Delete Activities" unless you want to delete them

**✅ Pass Criteria:**
- User Management section displays
- "Get Stats" returns valid data
- No JavaScript errors in browser console

---

### **Part 3: Integration Testing** (5 minutes)

#### **Test 6: End-to-End Flow** (5 min)

**Objective:** Verify complete data flow

1. **Backend webhook simulation:**
   - Check ops dashboard: Note current "Activities" count
   - If you have a recent Strava activity, it should appear
   - Check "Last hour" stat shows recent activity

2. **iOS app sync:**
   - Open VeloReady app
   - Pull to refresh on Today screen
   - Check Console for:
     ```
     📊 [Activities] Fetching from VeloReady backend
     ⚡ [Cache HIT] healthkit:hrv:...
     ```

3. **Cache working:**
   - Close app completely (swipe up)
   - Reopen app
   - Navigate to Today screen
   - Should load **instantly** (from cache)
   - Console shows: `⚡ [Cache HIT]` for all data

**✅ Pass Criteria:**
- Activities sync from Strava → Backend → iOS
- Second app open loads instantly
- All cache hits after warm-up

---

## 📊 Success Criteria Summary

### **Must Pass:**
- ✅ Cache hits logging in iOS console
- ✅ Cache Statistics dashboard displays
- ✅ Performance logs show operation timings
- ✅ Ops dashboard loads and shows metrics
- ✅ User Management "Get Stats" works
- ✅ Second app open loads instantly (cached)

### **Optional (Nice to Have):**
- ⏳ Cache hit rate >85% after warm-up
- ⏳ Performance metrics show all operations
- ⏳ API usage significantly lower than before

---

## 🐛 Known Issues & Expected Behaviors

### **Expected on First Launch:**
- All `[Cache MISS]` - this is normal
- Slower load times - fetching fresh data
- API calls to backend

### **Expected on Second Launch (within cache TTL):**
- Mostly `[Cache HIT]` logs
- Much faster load times
- Minimal or zero API calls

### **Cache TTLs:**
- **HealthKit data:** 5 minutes
- **Activities:** 1 hour
- **Streams:** 7 days
- **Daily scores:** 1 hour

### **If Something Doesn't Work:**

**iOS App Issues:**
1. Check Console for errors
2. Try: Clean Build Folder (Cmd+Shift+K)
3. Try: Reset simulator (Device → Erase All Content)
4. Check: UnifiedCacheManager is initialized

**Ops Dashboard Issues:**
1. Check browser console (F12) for errors
2. Verify: Netlify functions deployed
3. Check: Database connection
4. Try: Hard refresh (Cmd+Shift+R)

---

## 🎯 Quick Validation Commands

### **Check iOS Build Status:**
```bash
cd /Users/markboulton/Dev/VeloReady
xcodebuild -project VeloReady.xcodeproj -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep "BUILD SUCCEEDED"
```

### **Check Backend Functions:**
```bash
cd /Users/markboulton/Dev/veloready-website
netlify functions:list
```

### **Test Backend Locally:**
```bash
cd /Users/markboulton/Dev/veloready-website
netlify dev
# Then visit: http://localhost:8888/ops
```

---

## 📝 Testing Notes Template

Use this to track your testing:

```
✅ iOS Cache Logging: [PASS/FAIL]
   Notes: _______________________________________

✅ Cache Statistics Dashboard: [PASS/FAIL]
   Notes: _______________________________________

✅ Performance Monitoring: [PASS/FAIL]
   Notes: _______________________________________

✅ Ops Dashboard Metrics: [PASS/FAIL]
   Notes: _______________________________________

✅ User Management: [PASS/FAIL]
   Notes: _______________________________________

✅ End-to-End Flow: [PASS/FAIL]
   Notes: _______________________________________

Overall Status: [PASS/FAIL]
Issues Found: ___________________________________
```

---

## 🚀 Post-Testing Actions

### **If All Tests Pass:**
1. ✅ Mark as production-ready
2. ✅ Deploy to TestFlight (if applicable)
3. ✅ Monitor ops dashboard over next 24 hours
4. ✅ Document any observations

### **If Tests Fail:**
1. Note which test failed
2. Check error logs
3. Review `FINAL_IMPLEMENTATION_SUMMARY.md` for troubleshooting
4. Reach out for assistance

---

## 💡 Tips for Efficient Testing

1. **Keep Console open** - Most issues show in logs
2. **Use simulator** - Faster than physical device for testing
3. **Test incrementally** - Don't skip steps
4. **Take screenshots** - Of cache statistics for later comparison
5. **Monitor ops dashboard** - Leave it open in browser tab

---

## 📚 Reference Documents

- `/Users/markboulton/Dev/VeloReady/FINAL_IMPLEMENTATION_SUMMARY.md` - Complete overview
- `/Users/markboulton/Dev/VeloReady/PHASE_2_3_COMPLETION_SUMMARY.md` - Phase 2/3 details
- `/Users/markboulton/Dev/VeloReady/PHASE_4_EVALUATION.md` - Phase 4 implementation
- Unified Ops Dashboard: `https://veloready.app/ops`

---

**Expected Total Time:** 30 minutes  
**Difficulty:** Easy  
**Risk:** Low (all changes are backwards compatible)

**Good luck! You've built an exceptionally well-architected system.** 🚀
