# Supabase Token Refresh Bug - Analysis & Fix

**Date:** October 27, 2025  
**Issue:** CTL/ATL charts showing 0 values due to authentication failure  
**Root Cause:** Token refresh logic not being called proactively  

---

## The Bug

### What's Happening

1. Supabase access tokens **expire after 1 hour** (3600 seconds)
2. When you sign in, the app stores the token with an expiration time
3. After 1 hour, the token becomes invalid
4. The app tries to use the expired token to fetch activities
5. The backend rejects the request with `401 Unauthorized`
6. The charts show 0 values because no data was fetched

### Why Token Refresh Isn't Working

Looking at the code, the issue is in `VeloReadyAPIClient.swift` lines 122-126:

```swift
// Refresh token if needed before making request
do {
    try await SupabaseClient.shared.refreshTokenIfNeeded()
} catch {
    Logger.warning("⚠️ [VeloReady API] Token refresh failed: \(error)")
}
```

**The problem:** This catches the error but **doesn't throw it**. So the request continues with an expired token, and the API returns 401.

In `SupabaseClient.swift` line 100, `refreshTokenIfNeeded()` only refreshes if the token expires in **less than 5 minutes**:

```swift
if session.expiresAt.timeIntervalSinceNow < 300 {
    try await refreshToken()
}
```

This is good, but if the refresh fails, the app doesn't handle it properly.

### Second Issue: Session Loading on App Start

In `SupabaseClient.swift` lines 31-39, when loading a saved session:

```swift
// Check if token is expired
if session.expiresAt > Date() {
    self.session = session
    self.isAuthenticated = true
} else {
    Logger.debug("⚠️ [Supabase] Saved session expired - clearing")
    clearSession()
}
```

**The problem:** If the token is expired, it just clears the session silently. The app doesn't try to use the refresh token to get a new access token. This means after 1 hour of inactivity, you have to sign out/in manually.

---

## The Fix

### Part 1: Proactive Token Refresh on App Start

When loading a saved session, if the access token is expired but we have a refresh token, we should try to refresh it automatically.

**File:** `SupabaseClient.swift`

```swift
/// Load session from UserDefaults
private func loadSession() {
    guard let data = UserDefaults.standard.data(forKey: "supabase_session"),
          let session = try? JSONDecoder().decode(SupabaseSession.self, from: data) else {
        return
    }
    
    // Check if token is expired
    if session.expiresAt > Date() {
        self.session = session
        self.isAuthenticated = true
        Logger.debug("✅ [Supabase] Loaded saved session (expires: \(session.expiresAt))")
    } else {
        Logger.debug("⚠️ [Supabase] Saved session expired - attempting refresh...")
        
        // Try to refresh the token using the refresh token
        Task {
            do {
                // Temporarily set the session so refreshToken() can access it
                self.session = session
                try await refreshToken()
                Logger.debug("✅ [Supabase] Session refreshed on startup")
            } catch {
                Logger.error("❌ [Supabase] Failed to refresh expired session: \(error)")
                clearSession()
            }
        }
    }
}
```

### Part 2: Better Error Handling in API Client

When token refresh fails, we should throw the error so the app knows authentication failed.

**File:** `VeloReadyAPIClient.swift`

```swift
private func makeRequest<T: Decodable>(url: URL) async throws -> T {
    var request = URLRequest(url: url)
    request.timeoutInterval = 30
    
    // Refresh token if needed before making request
    do {
        try await SupabaseClient.shared.refreshTokenIfNeeded()
    } catch {
        Logger.warning("⚠️ [VeloReady API] Token refresh failed: \(error)")
        // Throw the error so the caller knows auth failed
        throw VeloReadyAPIError.notAuthenticated
    }
    
    // Add Supabase authentication header
    if let accessToken = SupabaseClient.shared.accessToken {
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        Logger.debug("🔐 [VeloReady API] Added auth header")
    } else {
        Logger.warning("⚠️ [VeloReady API] No auth token available")
        throw VeloReadyAPIError.notAuthenticated
    }
    
    // ... rest of request handling
}
```

### Part 3: Show Re-Authentication UI When Refresh Fails

When token refresh fails permanently (refresh token expired after 30 days), show a user-friendly alert.

**File:** Create new `AuthenticationStateManager.swift`

```swift
import SwiftUI

@MainActor
class AuthenticationStateManager: ObservableObject {
    static let shared = AuthenticationStateManager()
    
    @Published var showReAuthAlert = false
    
    private init() {
        // Listen for authentication failures
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthFailure),
            name: .supabaseAuthFailed,
            object: nil
        )
    }
    
    @objc private func handleAuthFailure() {
        showReAuthAlert = true
    }
}

extension Notification.Name {
    static let supabaseAuthFailed = Notification.Name("supabaseAuthFailed")
}
```

Then in `SupabaseClient.swift`, when refresh fails:

```swift
private func refreshToken() async throws {
    // ... existing code ...
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        Logger.error("[Supabase] Token refresh failed - clearing session")
        clearSession()
        
        // Notify the app that re-authentication is needed
        NotificationCenter.default.post(name: .supabaseAuthFailed, object: nil)
        
        throw SupabaseError.refreshFailed
    }
    
    // ... rest of code ...
}
```

And in your root view (e.g., `MainTabView.swift`):

```swift
@StateObject private var authManager = AuthenticationStateManager.shared

var body: some View {
    // ... existing view code ...
    .alert("Session Expired", isPresented: $authManager.showReAuthAlert) {
        Button("Sign In Again") {
            // Navigate to sign in screen
            // Or trigger sign out flow
            SupabaseClient.shared.clearSession()
        }
        Button("Cancel", role: .cancel) {}
    } message: {
        Text("Your session has expired. Please sign in again to continue.")
    }
}
```

---

## Testing Strategy

### Manual Testing

1. **Test Token Expiration:**
   - Sign in
   - Wait 1 hour (or manually set `expiresAt` to past date in debugger)
   - Try to fetch activities
   - Should automatically refresh and work

2. **Test Refresh Token Expiration:**
   - Sign in
   - Manually set both tokens to expired (access + refresh)
   - Try to fetch activities
   - Should show re-auth alert

3. **Test App Restart with Expired Token:**
   - Sign in
   - Force quit app
   - Manually set token to expired
   - Reopen app
   - Should automatically refresh token and work

### Integration Tests (Phase 1 of Testing Roadmap)

**File:** `VeloReadyAPIClientTests.swift`

```swift
@MainActor
class VeloReadyAPIClientTests: XCTestCase {
    
    func testFetchActivitiesWithExpiredToken() async throws {
        // Given: A user with an expired access token but valid refresh token
        let expiredSession = SupabaseSession(
            accessToken: "expired_token",
            refreshToken: "valid_refresh_token",
            expiresAt: Date().addingTimeInterval(-3600), // 1 hour ago
            user: SupabaseUser(id: "test_user", email: "test@example.com")
        )
        SupabaseClient.shared.session = expiredSession
        
        // When: Fetching activities
        let activities = try await VeloReadyAPIClient.shared.fetchActivities()
        
        // Then: Token should be refreshed and activities fetched
        XCTAssertFalse(activities.isEmpty)
        XCTAssertTrue(SupabaseClient.shared.isAuthenticated)
        XCTAssertNotEqual(SupabaseClient.shared.accessToken, "expired_token")
    }
    
    func testFetchActivitiesWithExpiredRefreshToken() async throws {
        // Given: A user with both expired access and refresh tokens
        let expiredSession = SupabaseSession(
            accessToken: "expired_token",
            refreshToken: "expired_refresh_token",
            expiresAt: Date().addingTimeInterval(-86400), // 1 day ago
            user: SupabaseUser(id: "test_user", email: "test@example.com")
        )
        SupabaseClient.shared.session = expiredSession
        
        // When: Fetching activities
        do {
            _ = try await VeloReadyAPIClient.shared.fetchActivities()
            XCTFail("Should throw notAuthenticated error")
        } catch VeloReadyAPIError.notAuthenticated {
            // Then: Should throw authentication error
            XCTAssertFalse(SupabaseClient.shared.isAuthenticated)
        }
    }
    
    func testAutomaticTokenRefreshBeforeExpiry() async throws {
        // Given: A user with a token expiring in 4 minutes
        let almostExpiredSession = SupabaseSession(
            accessToken: "almost_expired_token",
            refreshToken: "valid_refresh_token",
            expiresAt: Date().addingTimeInterval(240), // 4 minutes from now
            user: SupabaseUser(id: "test_user", email: "test@example.com")
        )
        SupabaseClient.shared.session = almostExpiredSession
        
        // When: Making an API request
        let activities = try await VeloReadyAPIClient.shared.fetchActivities()
        
        // Then: Token should be proactively refreshed
        XCTAssertNotEqual(SupabaseClient.shared.accessToken, "almost_expired_token")
        XCTAssertFalse(activities.isEmpty)
    }
}
```

---

## Rollout Plan

### Phase 1: Fix the Critical Bug (This Week)

**Goal:** Stop the "sign out/in" workaround from being needed

1. ✅ Implement Part 1: Proactive refresh on app start
2. ✅ Implement Part 2: Better error handling in API client
3. ✅ Test manually with expired tokens
4. ✅ Deploy to TestFlight

**Files to Change:**
- `VeloReady/Core/Networking/SupabaseClient.swift`
- `VeloReady/Core/Networking/VeloReadyAPIClient.swift`

### Phase 2: Add Re-Auth UI (Next Week)

**Goal:** User-friendly experience when refresh token expires (rare, every 30 days)

1. ✅ Create `AuthenticationStateManager`
2. ✅ Add re-auth alert to main view
3. ✅ Test with expired refresh token
4. ✅ Deploy to TestFlight

**Files to Create:**
- `VeloReady/Core/Authentication/AuthenticationStateManager.swift`

**Files to Change:**
- `VeloReady/Features/Today/Views/MainTabView.swift`

### Phase 3: Add Integration Tests (Week After)

**Goal:** Prevent this bug from happening again

1. ✅ Create test suite for token refresh
2. ✅ Add to CI/CD pipeline
3. ✅ Document test patterns

**Files to Create:**
- `VeloReadyTests/Integration/VeloReadyAPIClientTests.swift`
- `VeloReadyTests/Integration/SupabaseClientTests.swift`

---

## Expected Behavior After Fix

### Happy Path (Token Expires After 1 Hour)

1. User signs in → Token valid for 1 hour
2. User uses app for 1 hour 10 minutes
3. Token expires while app is in background
4. User opens app → App detects expired token
5. App automatically uses refresh token to get new access token
6. User sees charts with data (no sign out/in needed) ✅

### Edge Case (Refresh Token Expires After 30 Days)

1. User signs in → Tokens valid
2. User doesn't open app for 30+ days
3. Both access token AND refresh token expire
4. User opens app → App tries to refresh
5. Refresh fails (refresh token expired)
6. App shows alert: "Session Expired - Please Sign In Again"
7. User taps "Sign In Again" → OAuth flow starts
8. User authenticates → New tokens issued ✅

### Network Failure During Refresh

1. User's token expires
2. App tries to refresh token
3. Network request fails (no internet)
4. App shows network error (not auth error)
5. User retries when online
6. Refresh succeeds ✅

---

## Monitoring & Alerts

To prevent this from happening in production, add monitoring:

### Backend (Supabase Edge Functions)

Add logging to `auth-refresh-token.ts`:

```typescript
console.log("[Auth Refresh] Request from athleteId:", athleteId);

if (error) {
  console.error("[Auth Refresh] FAILED:", {
    athleteId,
    error: error.message,
    errorType: error.name
  });
}
```

### iOS App (Sentry/CloudWatch)

Add telemetry when refresh fails:

```swift
private func refreshToken() async throws {
    // ... existing code ...
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        
        // Log to analytics
        Logger.error("[Supabase] Token refresh failed - HTTP \(httpResponse?.statusCode ?? 0)")
        
        // Send to Sentry or your error tracking
        // Sentry.captureError(SupabaseError.refreshFailed)
        
        clearSession()
        throw SupabaseError.refreshFailed
    }
}
```

---

## Summary

| Issue | Current Behavior | After Fix |
|-------|-----------------|-----------|
| Token expires after 1h | Must sign out/in manually | Auto-refreshes seamlessly |
| App restart with expired token | Silent failure, shows 0 values | Auto-refreshes on startup |
| Refresh token expires (30d) | Silent failure, shows 0 values | Shows "Sign In Again" alert |
| Network error during refresh | Silent failure | Shows network error, retries |

**Impact:**
- 🎯 Fixes the "0 values in CTL/ATL chart" bug
- 🚀 Improves user experience (no manual sign out/in)
- 🔐 Maintains security (tokens still expire)
- 📊 Adds visibility into auth failures

**Next Steps:**
1. Review this fix
2. Implement Phase 1 (critical bug fix)
3. Test on TestFlight
4. Roll out Phase 2 & 3 as planned

