# Supabase Authentication Implementation Guide

## Overview

This guide documents the implementation of Supabase authentication in the VeloReady iOS app to support proper JWT-based API authentication with the backend.

## Problem Statement

The backend API endpoints (`api-activities.ts`, `api-streams.ts`) require authentication via Supabase JWT tokens. The iOS app was not sending these tokens, causing all API requests to fail with `401 Unauthorized` errors.

## Solution Architecture

### 1. Lightweight Supabase Client (No External Dependencies)

Created a native Swift implementation using `URLSession` instead of adding the Supabase SDK dependency:

**Files Created:**
- `VeloReady/Core/Config/SupabaseConfig.swift` - Configuration constants
- `VeloReady/Core/Networking/SupabaseClient.swift` - Authentication client

**Benefits:**
- ✅ No external dependencies (smaller app size)
- ✅ Full control over authentication flow
- ✅ Native Swift implementation
- ✅ Easy to debug and maintain

### 2. Authentication Flow

```
1. User connects Strava
   ↓
2. StravaAuthService receives OAuth callback
   ↓
3. SupabaseClient.exchangeStravaTokens() creates session
   ↓
4. Session saved to UserDefaults
   ↓
5. VeloReadyAPIClient adds "Authorization: Bearer <token>" header
   ↓
6. Backend validates JWT and returns user-specific data
```

### 3. Session Management

**Session Storage:**
- Stored in `UserDefaults` with key `"supabase_session"`
- Contains: `accessToken`, `refreshToken`, `expiresAt`, `user`
- Automatically loaded on app launch

**Token Refresh:**
- Tokens checked before each API request
- Auto-refresh if expiring within 5 minutes
- Graceful fallback if refresh fails

**Session Lifecycle:**
- Created: After successful Strava OAuth
- Loaded: On app launch
- Refreshed: Before API requests (if needed)
- Cleared: On disconnect/logout

## Implementation Details

### SupabaseConfig.swift

```swift
enum SupabaseConfig {
    static let url = "https://your-project.supabase.co"
    static let anonKey = "your-anon-key-here"
    
    static var isConfigured: Bool {
        return !url.contains("your-project") && !anonKey.contains("your-anon-key")
    }
}
```

**TODO:** Update with actual Supabase project credentials

### SupabaseClient.swift

Key methods:
- `exchangeStravaTokens()` - Create session after OAuth
- `refreshTokenIfNeeded()` - Auto-refresh before expiry
- `clearSession()` - Logout/disconnect
- `accessToken` - Get current token for API requests

### VeloReadyAPIClient.swift

Updated `makeRequest()` to include auth header:

```swift
if let accessToken = SupabaseClient.shared.accessToken {
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
}
```

### StravaAuthService.swift

Updated to create Supabase session after OAuth:

```swift
try await SupabaseClient.shared.exchangeStravaTokens(
    stravaAccessToken: "temp_token_\(athleteId)",
    stravaRefreshToken: "temp_refresh_\(athleteId)",
    athleteId: athleteId
)
```

## Configuration Steps

### 1. Get Supabase Credentials

From your Supabase project dashboard:
1. Go to Settings → API
2. Copy **Project URL** (e.g., `https://abcdefgh.supabase.co`)
3. Copy **anon/public key** (safe to embed in app)

### 2. Update SupabaseConfig.swift

```swift
enum SupabaseConfig {
    static let url = "https://abcdefgh.supabase.co"  // Your project URL
    static let anonKey = "eyJhbGc..."                 // Your anon key
}
```

### 3. Backend Integration (IMPORTANT)

The current implementation uses temporary tokens. For production, you need to:

**Option A: Create Supabase Users via Backend**

Add endpoint to backend: `POST /api/auth/create-user`

```typescript
// netlify/functions/auth-create-user.ts
export async function handler(event: HandlerEvent) {
  const { athleteId, stravaAccessToken, stravaRefreshToken } = JSON.parse(event.body);
  
  // Create Supabase user
  const { data: user, error } = await supabase.auth.admin.createUser({
    email: `athlete_${athleteId}@veloready.app`,
    email_confirm: true,
    user_metadata: {
      athlete_id: athleteId,
      strava_access_token: stravaAccessToken,
      strava_refresh_token: stravaRefreshToken
    }
  });
  
  if (error) throw error;
  
  // Generate session token
  const { data: session } = await supabase.auth.admin.generateLink({
    type: 'magiclink',
    email: user.email
  });
  
  return {
    statusCode: 200,
    body: JSON.stringify({
      accessToken: session.access_token,
      refreshToken: session.refresh_token,
      expiresIn: session.expires_in
    })
  };
}
```

**Option B: Use Strava Tokens Directly**

Update `authenticate()` in `netlify/lib/auth.ts` to accept Strava tokens:

```typescript
export async function authenticate(event: HandlerEvent): Promise<AuthResult | AuthError> {
  const authHeader = event.headers.authorization || event.headers.Authorization;
  
  if (!authHeader) {
    return { statusCode: 401, error: "Missing authorization header" };
  }
  
  const token = authHeader.replace(/^Bearer\s+/i, '');
  
  // Check if it's a Strava token (starts with "temp_token_")
  if (token.startsWith("temp_token_")) {
    const athleteId = parseInt(token.replace("temp_token_", ""));
    
    // Fetch user_id from athlete table
    const athlete = await withDb(async (db) => {
      const { rows } = await db.query(
        `SELECT id, user_id FROM athlete WHERE id = $1`,
        [athleteId]
      );
      return rows[0] || null;
    });
    
    if (!athlete) {
      return { statusCode: 404, error: "Athlete not found" };
    }
    
    return {
      userId: athlete.user_id || `athlete_${athleteId}`,
      athleteId: athlete.id
    };
  }
  
  // Otherwise, validate as Supabase JWT
  // ... existing Supabase validation code
}
```

## Testing

### 1. Test Authentication Flow

```swift
// In your test or debug code:
let client = SupabaseClient.shared

// Check if authenticated
print("Authenticated: \(client.isAuthenticated)")
print("Access Token: \(client.accessToken ?? "none")")

// Test API request
let activities = try await VeloReadyAPIClient.shared.fetchActivities()
print("Fetched \(activities.count) activities")
```

### 2. Monitor Logs

Look for these log messages:

**Success:**
```
✅ [Supabase] Session created for athlete 104662
🔐 [VeloReady API] Added auth header
✅ [VeloReady API] Received 10 activities
```

**Failure:**
```
⚠️ [VeloReady API] No auth token available - request may fail
❌ Failed to fetch activities: Not authenticated
```

### 3. Test Token Refresh

```swift
// Force token expiry
if var session = SupabaseClient.shared.session {
    session.expiresAt = Date().addingTimeInterval(-60) // Expired 1 min ago
    // Save modified session
}

// Try API request - should auto-refresh
let activities = try await VeloReadyAPIClient.shared.fetchActivities()
```

## Security Considerations

### ✅ Safe to Embed in App
- Supabase anon key (public key)
- Supabase project URL
- Backend API URLs

### ⚠️ Never Embed in App
- Supabase service role key
- Database passwords
- Private API keys

### 🔒 Token Security
- Tokens stored in UserDefaults (encrypted on device)
- Auto-refresh before expiry
- Cleared on logout
- HTTPS-only communication

## Deployment Checklist

- [ ] Update `SupabaseConfig.swift` with real credentials
- [ ] Implement backend user creation endpoint (Option A) OR
- [ ] Update backend `authenticate()` to accept Strava tokens (Option B)
- [ ] Test full OAuth → API request flow
- [ ] Verify token refresh works
- [ ] Test disconnect/logout clears session
- [ ] Monitor backend logs for auth errors
- [ ] Test with multiple users (if multi-user)

## Troubleshooting

### "No auth token available" Warning

**Cause:** SupabaseClient has no session
**Fix:** Ensure `exchangeStravaTokens()` is called after OAuth

### "401 Unauthorized" from Backend

**Cause:** Backend can't validate token
**Fix:** Check backend `authenticate()` implementation

### "Invalid or expired token"

**Cause:** Token expired and refresh failed
**Fix:** Check token refresh logic, may need to re-authenticate

### Session Not Persisting

**Cause:** UserDefaults not saving
**Fix:** Check `saveSession()` implementation

## Future Enhancements

1. **Add Supabase SDK** (optional)
   - Full Supabase features (realtime, storage, etc.)
   - Automatic token refresh
   - Better error handling

2. **Implement Proper User Management**
   - Create Supabase users for each athlete
   - Link Strava account to Supabase user
   - Support multiple auth providers

3. **Add Biometric Authentication**
   - Face ID / Touch ID for session access
   - Secure token storage in Keychain

4. **Implement Token Rotation**
   - Rotate tokens on each refresh
   - Detect token theft/reuse

## References

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [JWT Best Practices](https://datatracker.ietf.org/doc/html/rfc8725)
- [iOS Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
