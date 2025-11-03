# Day 2: iOS Subscription Sync - FIXED

## Issue Found & Resolved

### Problem
Initial implementation made direct REST calls to Supabase:
```
❌ https://gvkfdiqbbjhapqkxmfgh.supabase.co/rest/v1/user_subscriptions
Error: "A server with the specified hostname could not be found"
```

**Root cause:** Hardcoded Supabase URL unreachable from simulator (DNS failure). Also exposed API keys in client code (security risk).

### Solution
Implemented proper backend endpoint architecture:

**iOS (SubscriptionManager.swift):**
- Sends subscription data to `https://api.veloready.app/subscription/sync`
- Includes JWT token in Authorization header
- Backend handles all Supabase operations

**Backend (subscription-sync.ts):**
- New Netlify Function at `/subscription/sync`
- Validates JWT token via `authenticate()` helper
- Extracts user_id from JWT
- Upserts to `user_subscriptions` table with proper RLS

## Files Changed

### iOS
- **SubscriptionManager.swift** (lines 249-336)
  - Removed hardcoded Supabase URL
  - Removed hardcoded API keys
  - Now uses backend endpoint with JWT auth
  - Filters out nil values from request body

### Backend
- **subscription-sync.ts** (NEW)
  - Netlify Function for subscription sync
  - JWT authentication via `authenticate()` helper
  - Upserts to Supabase with user isolation
  - Proper error handling and logging

## Architecture Benefits

✅ **Security:**
- No API keys in client code
- JWT tokens validated on backend
- User isolation via RLS policies

✅ **Reliability:**
- Backend handles Supabase operations
- Proper error handling and logging
- Consistent with other API endpoints

✅ **Scalability:**
- Centralized backend routing
- Can add rate limiting, monitoring
- Future: webhook support for subscription changes

## Testing

**Build Status:** ✅ SUCCEEDED

**Unit Tests:** 14/15 passed (1 pre-existing failure unrelated to changes)

**Quick Test:**
```
Settings → Debug Settings → "Test Subscription Sync"
Expected: Logs show "✅ [Subscription] Synced to backend: free" or "pro"
```

**Full Flow:**
```
Trends → Weekly Recovery Trend → PaywallView → Purchase
Expected: Logs show sync to backend with correct tier
```

## Next Steps

- Deploy backend endpoint to production
- Test with real subscription purchase
- Monitor logs for sync success/failures
- Ready for Day 3: Backend authentication enhancement
