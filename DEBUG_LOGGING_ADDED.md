# Comprehensive Debug Logging Added

## Summary

Added detailed diagnostic logging to identify two critical bugs:
1. **Activity fetch failing** with `serverError` (no details)
2. **AI brief failing** with "Recovery score not available" (but score exists at 74)

---

## What Was Added

### 1. VeloReadyAPIClient.swift - Network Request Logging

**Before:**
```
🌐 [VeloReady API] Fetching activities (daysBack: 7, limit: 50)
✅ [Supabase] Token valid for 627s, no refresh needed
🔐 [VeloReady API] Added auth header
⚠️ Failed to fetch unified activities: serverError  ❌ NO DETAILS!
```

**After:**
```
🌐 [VeloReady API] Fetching activities (daysBack: 7, limit: 50)
✅ [Supabase] Token valid for 627s, no refresh needed
🔐 [VeloReady API] Added auth header
📡 [VeloReady API] Making request to: https://api.veloready.app/.netlify/functions/api/activities?daysBack=7&limit=50
📥 [VeloReady API] Response status: 502
📥 [VeloReady API] Response size: 156 bytes
❌ [VeloReady API] Server error (502)
❌ [VeloReady API] URL: https://api.veloready.app/.netlify/functions/api/activities?daysBack=7&limit=50
❌ [VeloReady API] Response body: {"error":"Bad Gateway","message":"Function timeout"}
📋 [VeloReady API] Response headers:
   Content-Type: application/json
   X-Netlify-Request-Id: abc123
   ...
```

**What You'll See:**
- ✅ Exact URL being requested
- ✅ HTTP status code (500, 502, 503, 504)
- ✅ Error response body from backend (up to 500 chars)
- ✅ All response headers
- ✅ Response size in bytes

---

### 2. AIBriefService.swift - Recovery Score State Logging

**Before:**
```
❌ AI brief error: networkError("Recovery score not available")
```

**After:**
```
🤖 [AI Brief] AIBriefView.onAppear - briefText: nil, isLoading: false
🤖 [AI Brief] Triggering fetchBrief() from onAppear
🤖 [AI Brief] Building request - recovery score: nil
🤖 [AI Brief] Recovery service state: isLoading=true
❌ [AI Brief] Recovery score is nil - cannot build request
❌ AI brief error: networkError("Recovery score not available")
```

**What You'll See:**
- ✅ Recovery score value when AI brief is triggered
- ✅ Whether recovery service is still loading
- ✅ Timing of when brief is requested vs when recovery completes
- ✅ Exact state of recovery service

---

## What These Logs Will Reveal

### For Activity Fetch serverError:

**Possible Causes:**
1. **Backend timeout** (502/504)
   - Function exceeds 10-second Netlify limit
   - Solution: Optimize backend query or increase timeout
   
2. **Backend authentication error** (401/403)
   - JWT token invalid on backend
   - User not found in database
   - Solution: Check backend auth.ts logic
   
3. **Backend rate limiting** (429)
   - Too many requests to backend
   - Solution: Add retry logic with backoff
   
4. **Strava API error** (500/503)
   - Backend successfully authed, but Strava API failed
   - Solution: Add fallback or retry for Strava calls

**Example Log Output:**
```
❌ [VeloReady API] Server error (502)
❌ [VeloReady API] Response body: {"errorType":"Task timed out after 10.00 seconds"}
```
→ **Diagnosis:** Backend function timeout. Need to optimize or increase timeout.

---

### For AI Brief "Recovery score not available":

**Possible Causes:**
1. **Race condition** - AI brief triggered before recovery calculated
   ```
   🤖 [AI Brief] Building request - recovery score: nil
   🤖 [AI Brief] Recovery service state: isLoading=true
   ```
   → **Diagnosis:** AI brief called while recovery still calculating
   → **Solution:** Wait for recovery to complete before showing AI brief

2. **Timing issue** - AI brief triggered too early in Phase 2
   ```
   🤖 [AI Brief] AIBriefView.onAppear - briefText: nil, isLoading: false
   🔍 [Performance] ✅ PHASE 2 complete in 7.40s
   ```
   → **Diagnosis:** AI brief loads before Phase 2 completes
   → **Solution:** Defer AI brief until after Phase 2

3. **Recovery service error** - Recovery calculation failed silently
   ```
   🤖 [AI Brief] Building request - recovery score: nil
   🤖 [AI Brief] Recovery service state: isLoading=false
   ```
   → **Diagnosis:** Recovery finished but score is nil (calc failed)
   → **Solution:** Check recovery service logs for errors

---

## How to Use These Logs

### Testing Steps:

1. **Clean install** on device
2. **Launch app** and wait for Phase 2 to complete
3. **Search logs** for:
   ```
   grep "VeloReady API" logs.txt
   grep "AI Brief" logs.txt
   grep "serverError" logs.txt
   ```

### What to Share:

When reporting issues, include:
- Full VeloReady API request/response logs
- AI Brief state logs
- Recovery service logs
- Phase 2 timing logs

**Example:**
```
# Activity Fetch Issue
📡 [VeloReady API] Making request to: https://...
📥 [VeloReady API] Response status: 502
❌ [VeloReady API] Response body: {"error":"..."}
📋 [VeloReady API] Response headers: {...}

# AI Brief Issue
🤖 [AI Brief] Building request - recovery score: nil
🤖 [AI Brief] Recovery service state: isLoading=true
```

---

## Expected Behavior After Fixes

### Activity Fetch (After Backend Fix):
```
📡 [VeloReady API] Making request to: https://...
📥 [VeloReady API] Response status: 200
📥 [VeloReady API] Response size: 45231 bytes
📦 Cache status: HIT
✅ [VeloReady API] Received 182 activities
```

### AI Brief (After Timing Fix):
```
🤖 [AI Brief] AIBriefView.onAppear - briefText: nil, isLoading: false
✅ PHASE 2 complete in 7.40s - scores ready
🤖 [AI Brief] Building request - recovery score: 74
✅ [AI Brief] Recovery score available: 74
✅ AI brief updated (fresh)
```

---

## Files Modified

1. **VeloReadyAPIClient.swift**
   - Added pre-request logging (URL, auth header)
   - Added response logging (status, size, headers)
   - Added detailed error logging (body, headers)
   
2. **AIBriefService.swift**
   - Added recovery score state logging
   - Added service loading state logging
   - Added pre-request validation logging
   
3. **AIBriefView.swift**
   - Added onAppear trigger logging
   - Shows when fetch is initiated

---

## Next Steps

1. **Test on device** with new logging
2. **Reproduce bugs** (activity fetch fail, AI brief fail)
3. **Capture logs** and share the detailed error output
4. **Diagnose root cause** based on:
   - HTTP status code
   - Error response body
   - Timing of requests
   - Recovery service state

With these logs, we'll know exactly:
- **What HTTP error** the backend returned
- **Why** the backend failed (timeout, auth, rate limit)
- **When** AI brief is triggered relative to recovery calculation
- **Whether** recovery is still loading when AI brief runs

---

## Commit

**Branch:** `iOS-Error-Handling`
**Commit:** `5f10b56` - "debug: Add comprehensive logging for network errors"
**Status:** ✅ Pushed and ready for testing

Test it and share the logs! 🔍
