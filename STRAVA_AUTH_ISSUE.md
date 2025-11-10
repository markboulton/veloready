# Strava Authentication Issue

**Date:** November 10, 2025  
**Status:** 🔴 **NOT FIXED** - Requires backend token refresh implementation  
**Priority:** High (affects all Strava integrations)

---

## Problem

The app shows **"No Strava/Intervals activity found"** even though:
- Strava connection state: `connected(athleteId: "104662")`
- `UserDefaults` shows `strava_is_connected: true`
- User previously connected successfully

**Error in logs:**
```
❌ [Strava] Failed to fetch activities: notAuthenticated
🔍 [LatestActivity] Total activities: 15 (all from Apple Health)
❌ [LatestActivity] No Strava/Intervals activity found
```

---

## Root Cause

The **Strava access token stored in Supabase has expired**, but the app doesn't detect this because:

1. **Connection state is stored in `UserDefaults`**, not validated against Supabase
2. **No token expiry checking** when the app launches
3. **OAuth tokens expire after 6 hours** (Strava default)

**Timeline:**
1. User connects to Strava → tokens stored in Supabase
2. App marks `strava_is_connected = true` in `UserDefaults`
3. 6+ hours pass → Strava access token expires
4. App launches → checks `UserDefaults` → shows "connected" ✅
5. App tries to fetch activities → Supabase returns `401 Unauthorized` → shows "notAuthenticated" ❌

---

## Why This Happens

### Current Flow (Broken)

```swift
// StravaAuthService.swift - loadStoredConnection()
if UserDefaults.standard.bool(forKey: "strava_is_connected") {
    let athleteId = UserDefaults.standard.string(forKey: "strava_athlete_id")
    connectionState = .connected(athleteId: athleteId)
    // ❌ NO TOKEN VALIDATION!
}
```

### What Should Happen

```swift
if UserDefaults.standard.bool(forKey: "strava_is_connected") {
    // ✅ Validate Supabase session is still valid
    if await SupabaseClient.shared.isSessionValid() {
        connectionState = .connected(athleteId: athleteId)
    } else {
        // Token expired - disconnect and prompt re-auth
        connectionState = .disconnected
        UserDefaults.standard.set(false, forKey: "strava_is_connected")
    }
}
```

---

## Required Fixes

### 1. Backend: Implement Token Refresh (veloready-website)

The backend needs to:
- Store Strava `refresh_token` (currently only stores `access_token`)
- Implement automatic token refresh when `access_token` expires
- Return refreshed tokens to iOS app

**Files to modify:**
- `netlify/functions/oauth-strava-token-exchange.ts`
- `netlify/functions/api-activities.ts` (add token refresh logic)

**Strava Token Refresh Flow:**
```typescript
// When access token expires (401 from Strava API)
const refreshResponse = await fetch('https://www.strava.com/oauth/token', {
  method: 'POST',
  body: JSON.stringify({
    client_id: STRAVA_CLIENT_ID,
    client_secret: STRAVA_CLIENT_SECRET,
    refresh_token: user.strava_refresh_token,
    grant_type: 'refresh_token'
  })
});

const { access_token, refresh_token, expires_at } = await refreshResponse.json();

// Update database with new tokens
await supabase
  .from('athletes')
  .update({
    strava_access_token: access_token,
    strava_refresh_token: refresh_token,
    strava_token_expires_at: expires_at
  })
  .eq('id', userId);
```

### 2. iOS: Validate Session on Launch

**File:** `VeloReady/Core/Services/StravaAuthService.swift`

```swift
private func loadStoredConnection() {
    // Check UserDefaults
    guard UserDefaults.standard.bool(forKey: StravaAuthConfig.isConnectedKey) else {
        connectionState = .disconnected
        return
    }
    
    let athleteId = UserDefaults.standard.string(forKey: StravaAuthConfig.athleteIdKey)
    
    // ✅ NEW: Validate Supabase session is still valid
    Task { @MainActor in
        if await SupabaseClient.shared.isSessionValid() {
            connectionState = .connected(athleteId: athleteId)
        } else {
            // Token expired - force re-auth
            Logger.warning("⚠️ [STRAVA] Session expired - disconnecting")
            disconnect()
        }
    }
}
```

### 3. iOS: Add Session Validation to SupabaseClient

**File:** `VeloReady/Core/Networking/SupabaseClient.swift`

```swift
/// Check if current session is valid (not expired)
func isSessionValid() async -> Bool {
    guard let session = currentSession else {
        return false
    }
    
    // Check if token is expired (with 5-minute buffer)
    let bufferTime: TimeInterval = 300 // 5 minutes
    let isExpired = session.expiresAt.timeIntervalSinceNow < bufferTime
    
    if isExpired {
        // Try to refresh
        return await refreshSession()
    }
    
    return true
}
```

---

## Workaround (Temporary)

**For the user RIGHT NOW:**

1. Go to **Settings** → **Integrations**
2. Tap **"Disconnect Strava"**
3. Tap **"Connect with Strava"** again
4. This will generate fresh tokens (valid for 6 hours)

---

## Long-Term Solution

Implement **automatic token refresh** on the backend:
1. Store both `access_token` and `refresh_token` in database
2. Check token expiry before each API call
3. Automatically refresh if expired
4. iOS app doesn't need to know about token refresh (transparent)

This is the **recommended approach** used by all production Strava integrations.

---

## Testing

After implementing fixes:

1. **Test token expiry:**
   - Connect Strava
   - Manually set `strava_token_expires_at` to past date in database
   - Launch app → should show "disconnected"

2. **Test token refresh:**
   - Connect Strava
   - Wait 6+ hours (or manually expire token)
   - Fetch activities → should auto-refresh and succeed

3. **Test re-auth flow:**
   - Disconnect Strava
   - Connect again → should work immediately

---

## Priority

**HIGH** - This affects:
- All Strava activity imports
- Training load calculations
- Activity history display
- Ride statistics

Users will lose access to their Strava data **every 6 hours** until this is fixed.

