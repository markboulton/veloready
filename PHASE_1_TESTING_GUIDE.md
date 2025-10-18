# Phase 1 Testing Guide

**Quick reference for testing API centralization**

---

## 🎯 Quick Test (5 minutes)

### **1. Deploy Backend**
```bash
cd ~/Dev/veloready-website
netlify deploy --prod
```

**Expected output:**
```
✔ Deploy is live!
Functions:
  - api-activities
  - api-streams
```

---

### **2. Test Backend Endpoints**

#### Test Activities Endpoint:
```bash
curl -v "https://veloready.app/api/activities?daysBack=7&limit=10" | jq '.metadata'
```

**Expected:**
```json
{
  "athleteId": 104662,
  "daysBack": 7,
  "limit": 10,
  "count": 5,
  "cachedUntil": "2025-10-18T22:00:00Z"
}
```

**Check for:**
- ✅ Status code: 200
- ✅ `X-Cache` header present (HIT or MISS)
- ✅ Activities array not empty

---

#### Test Streams Endpoint:
```bash
# Replace with a real activity ID from your account
curl -v "https://veloready.app/api/streams/12345678" | jq 'keys'
```

**Expected:**
```json
["time", "watts", "heartrate", "cadence", ...]
```

**Check for:**
- ✅ Status code: 200
- ✅ `X-Cache` header present
- ✅ Multiple stream types returned

---

### **3. Run iOS App**

```bash
cd ~/Dev/VeloReady
open VeloReady.xcodeproj
```

**In Xcode:**
1. Select iPhone simulator
2. Press **⌘R** to run
3. Watch console logs

---

### **4. Verify Logs**

**Look for these in Xcode console:**

```
🌐 [VeloReady API] Fetching activities (daysBack: 30, limit: 50)
📦 Cache status: MISS
✅ [VeloReady API] Received 42 activities
```

**On second app open:**
```
🌐 [VeloReady API] Fetching activities (daysBack: 30, limit: 50)
📦 Cache status: HIT    ← Should see HIT now!
✅ [VeloReady API] Received 42 activities
```

---

### **5. Test Activity Detail**

1. Tap any activity in Today tab
2. Wait for detail view to load
3. Check console logs

**Expected:**
```
🟠 Fetching streams from VeloReady backend...
📦 Cache status: MISS
🟠 Received 8 stream types from backend
🟠 Converted to 1000 workout samples
```

4. Go back and open same activity again
5. Should see cache HIT and instant load

---

## ✅ Success Criteria

### **Backend**
- [ ] Both endpoints deploy successfully
- [ ] Activities endpoint returns data
- [ ] Streams endpoint returns data
- [ ] Cache headers present in responses
- [ ] No errors in Netlify logs

### **iOS**
- [ ] App builds without errors
- [ ] Activities load in Today tab
- [ ] Activity details open and show charts
- [ ] Console shows VeloReady API logs
- [ ] Second load shows cache HIT

---

## ⚠️ Common Issues

### **Issue: "Athlete not found"**
**Cause:** Hard-coded athlete ID (104662) doesn't match your account

**Fix:** Update athlete ID in:
- `netlify/functions/api-activities.ts` (line 29)
- `netlify/functions/api-streams.ts` (line 37)

---

### **Issue: "Failed to fetch streams"**
**Cause:** Invalid activity ID or activity has no streams

**Fix:** 
1. Check activity ID is correct
2. Try a different activity (with power/HR data)
3. Check Netlify logs for detailed error

---

### **Issue: App loads but no data**
**Cause:** Not connected to Strava

**Fix:**
1. Open Settings in app
2. Connect to Strava
3. Restart app

---

### **Issue: Backend returns 500 error**
**Cause:** Database connection or Strava token issue

**Fix:**
1. Check Netlify logs: https://app.netlify.com/sites/YOUR_SITE/functions
2. Verify DATABASE_URL env var set
3. Check if Strava tokens expired

---

## 🔍 Debug Commands

### **Check Netlify Deployment:**
```bash
cd ~/Dev/veloready-website
netlify status
netlify functions:list
```

### **View Live Logs:**
```bash
netlify logs:function api-activities --live
```

### **Test Locally:**
```bash
netlify dev
# Then test: http://localhost:8888/api/activities
```

### **Check iOS Console:**
In Xcode: **⌘/** to open console filter, type "VeloReady API"

---

## 📊 Monitoring

### **Netlify Dashboard**
https://app.netlify.com

**Check:**
- Function invocations count
- Error rate
- Average execution time
- Bandwidth usage

**Healthy metrics:**
- Invocations: <10K/day for 1K users
- Errors: <1%
- Avg time: <500ms
- Bandwidth: <1GB/day

---

### **iOS Performance**

**Measure startup time:**
1. Close app completely
2. Start timer
3. Launch app
4. Stop when activities appear

**Target:** <3 seconds

---

### **Cache Hit Rate**

Run this after 10 app opens:
```bash
# Count HIT vs MISS in Netlify logs
netlify logs:function api-activities | grep "X-Cache" | sort | uniq -c
```

**Target:** >80% HIT rate

---

## 🐛 Bug Reports

If something doesn't work:

1. **Capture logs:**
   - Backend: `netlify logs:function api-activities > backend.log`
   - iOS: Copy console output to file

2. **Check environment:**
   ```bash
   netlify env:list
   # Verify: DATABASE_URL, STRAVA_CLIENT_ID, STRAVA_CLIENT_SECRET
   ```

3. **Test minimal case:**
   ```bash
   curl "https://veloready.app/api/activities?daysBack=1&limit=1"
   ```

4. **Share:**
   - Error message
   - Expected behavior
   - Actual behavior
   - Logs

---

## ✨ What to Test Next

### **User Flows**

1. **Cold Start (No Cache)**
   - Delete app
   - Reinstall
   - Connect Strava
   - Load activities
   - **Expect:** 2-3 second load

2. **Warm Start (With Cache)**
   - Close app
   - Reopen
   - **Expect:** Instant load (<1s)

3. **Activity Detail**
   - Open 5 different activities
   - Go back and reopen same 5
   - **Expect:** First opens slow, reopens instant

4. **Offline Mode**
   - Open app with WiFi
   - Turn off WiFi
   - Try to load new activity
   - **Expect:** Error message
   - Open previously viewed activity
   - **Expect:** Works (local cache)

---

## 📈 Performance Targets

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| App startup | <3s | TBD | ⏳ |
| Activity list load | <1s (cached) | TBD | ⏳ |
| Activity detail | <500ms (cached) | TBD | ⏳ |
| Cache hit rate | >80% | TBD | ⏳ |
| Memory usage | <150MB | TBD | ⏳ |
| API calls/user/day | <1 | TBD | ⏳ |

**Fill in "Current" after testing**

---

## ✅ Phase 1 Sign-Off

Once all tests pass, check these:

- [ ] Backend endpoints deployed and working
- [ ] iOS app using backend APIs (verified in logs)
- [ ] Cache working (verified HIT in logs)
- [ ] Activity detail loads with charts
- [ ] No increase in errors or crashes
- [ ] Performance acceptable (<3s startup)
- [ ] Documentation complete

**Date Tested:** __________  
**Tested By:** __________  
**Status:** ✅ PASS / ❌ FAIL  
**Notes:** ______________________________________

---

Ready for Phase 2! 🚀
