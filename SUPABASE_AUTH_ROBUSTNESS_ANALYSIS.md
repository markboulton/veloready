# Supabase Authentication Robustness Analysis

## 🔍 Current Issue

**User Report:**
> "I have connected Strava. This keeps happening with Supabase whilst I'm debugging and it needs to be way more robust."

**Symptoms:**
```
⚠️ [Supabase] No saved session found
💡 [Supabase] You need to connect Strava to create a session
❌ [Supabase] Token refresh failed on launch: notAuthenticated
```

---

## 🎯 Root Causes Identified

### **1. No Session After Strava Connection** ❌

**Problem:** Tokens may fail to save after Strava OAuth

**Potential Causes:**
1. OAuth callback may fail silently
2. Backend may not return tokens
3. `createSession()` may fail to save to UserDefaults
4. Race condition between token receipt and app navigation

**Current Code:**
```swift
// StravaAuthService.swift:194-208
if let accessToken = accessToken,
   let refreshToken = refreshToken,
   let expiresInStr = expiresInStr,
   let expiresIn = Int(expiresInStr),
   let userId = userId {
    SupabaseClient.shared.createSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
        userId: userId
    )
} else {
    Logger.warning("⚠️ [Supabase] No tokens received from backend - API requests may fail")
}
```

**Issues:**
- ❌ No error logging if tokens are missing
- ❌ No retry mechanism
- ❌ Silent failure (just a warning)
- ❌ No verification that session was actually saved
- ❌ No user notification of failure

---

### **2. Token Refresh Fails on App Launch** ❌

**Problem:** When token is expired, refresh fails with `notAuthenticated`

**Current Flow:**
```swift
// SupabaseClient.swift:32-71
private func loadSession() {
    // ... load from UserDefaults ...
    
    if session.expiresAt > Date() {
        // Token valid
        self.isAuthenticated = true
    } else {
        // Token expired - try to refresh
        Task {
            do {
                self.session = session  // Temporarily set expired session
                try await refreshToken()
            } catch {
                Logger.error("❌ [Supabase] Token refresh failed on launch: \(error)")
                clearSession()  // ❌ DESTROYS SESSION ON FAILURE!
            }
        }
    }
}
```

**Issues:**
- ❌ If refresh fails, entire session is cleared
- ❌ User must re-authenticate with Strava (poor UX)
- ❌ No retry mechanism
- ❌ No exponential backoff
- ❌ Race condition: App may make API calls before refresh completes

---

### **3. Token Refresh Endpoint May Fail** ❌

**Problem:** Backend endpoint may be unreachable or return errors

**Current Code:**
```swift
// SupabaseClient.swift:165-212
private func refreshToken() async throws {
    guard let session = session else {
        throw SupabaseError.notAuthenticated
    }
    
    // Call backend
    let url = URL(string: "https://api.veloready.app/.netlify/functions/auth-refresh-token")
    // ... make request ...
    
    guard httpResponse.statusCode == 200 else {
        Logger.error("[Supabase] Token refresh failed - clearing session")
        clearSession()  // ❌ DESTROYS SESSION ON FAILURE!
        throw SupabaseError.refreshFailed
    }
}
```

**Issues:**
- ❌ Network failure = lost session
- ❌ Backend error = lost session
- ❌ Timeout = lost session
- ❌ No retry on transient failures
- ❌ No offline support

---

### **4. No Proactive Token Refresh** ⚠️

**Problem:** Tokens expire while app is running, causing API failures

**Current Behavior:**
- Token checked on app launch
- Not checked periodically during runtime
- API calls may use expired tokens

**Result:**
- API calls fail mid-session
- User sees errors
- Must restart app to refresh

---

### **5. No Session Validation** ❌

**Problem:** No verification that saved session is actually valid

**Current Code:**
```swift
func createSession(...) {
    let session = SupabaseSession(...)
    saveSession(session)  // Assumes success
}
```

**Issues:**
- ❌ No validation that UserDefaults write succeeded
- ❌ No validation that token format is correct
- ❌ No validation that user_id is valid
- ❌ No backend verification call

---

## 🔧 Proposed Solutions

### **Solution 1: Robust Session Creation with Retry**

```swift
func createSession(accessToken: String, refreshToken: String, expiresIn: Int, userId: String, retryCount: Int = 0) {
    Logger.info("💾 [Supabase] Creating session (attempt \(retryCount + 1)/3)...")
    Logger.info("   User ID: \(userId)")
    Logger.info("   Expires in: \(expiresIn)s")
    
    let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
    let session = SupabaseSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        user: SupabaseUser(id: userId, email: nil)
    )
    
    // Attempt to save
    guard let data = try? JSONEncoder().encode(session) else {
        Logger.error("❌ [Supabase] Failed to encode session!")
        if retryCount < 2 {
            // Retry after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.createSession(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn, userId: userId, retryCount: retryCount + 1)
            }
        }
        return
    }
    
    UserDefaults.standard.set(data, forKey: "supabase_session")
    UserDefaults.standard.synchronize()  // Force immediate write
    
    // Verify save succeeded
    if let savedData = UserDefaults.standard.data(forKey: "supabase_session"),
       let _ = try? JSONDecoder().decode(SupabaseSession.self, from: savedData) {
        self.session = session
        self.isAuthenticated = true
        Logger.info("✅ [Supabase] Session created and verified (expires: \(expiresAt))")
    } else {
        Logger.error("❌ [Supabase] Session save verification FAILED!")
        if retryCount < 2 {
            // Retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.createSession(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn, userId: userId, retryCount: retryCount + 1)
            }
        }
    }
}
```

**Benefits:**
- ✅ Retry on failure (up to 3 attempts)
- ✅ Verify save succeeded
- ✅ Force immediate UserDefaults write
- ✅ Comprehensive logging

---

### **Solution 2: Preserve Session on Refresh Failure**

```swift
private func refreshToken() async throws {
    guard let session = session else {
        throw SupabaseError.notAuthenticated
    }
    
    Logger.info("🔄 [Supabase] Refreshing access token...")
    Logger.info("   Refresh token: \(session.refreshToken.prefix(16))...")
    Logger.info("   Expired at: \(session.expiresAt)")
    
    // Call backend
    guard let url = URL(string: "https://api.veloready.app/.netlify/functions/auth-refresh-token") else {
        throw SupabaseError.invalidResponse
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 10.0  // 10s timeout
    
    let body = ["refresh_token": session.refreshToken]
    request.httpBody = try JSONEncoder().encode(body)
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        Logger.info("🔄 [Supabase] Refresh response: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            // Log error but DON'T clear session
            Logger.error("❌ [Supabase] Token refresh failed with status \(httpResponse.statusCode)")
            Logger.warning("⚠️ [Supabase] Keeping expired session for retry - user won't be logged out")
            throw SupabaseError.refreshFailed
        }
        
        // Parse response
        struct RefreshResponse: Codable {
            let access_token: String
            let refresh_token: String
            let expires_in: Int
        }
        
        let refreshResponse = try JSONDecoder().decode(RefreshResponse.self, from: data)
        
        // Create new session with refreshed tokens
        let newSession = SupabaseSession(
            accessToken: refreshResponse.access_token,
            refreshToken: refreshResponse.refresh_token,
            expiresAt: Date().addingTimeInterval(TimeInterval(refreshResponse.expires_in)),
            user: session.user
        )
        
        saveSession(newSession)
        Logger.info("✅ [Supabase] Token refreshed successfully (expires: \(newSession.expiresAt))")
        
    } catch {
        // Log error but DON'T clear session
        Logger.error("❌ [Supabase] Token refresh network error: \(error)")
        Logger.warning("⚠️ [Supabase] Keeping expired session - will retry on next API call")
        throw error
    }
}
```

**Benefits:**
- ✅ Expired session preserved on failure
- ✅ User won't be logged out on transient failures
- ✅ Can retry refresh later
- ✅ Better timeout handling
- ✅ More detailed logging

---

### **Solution 3: Proactive Token Refresh**

```swift
@MainActor
class SupabaseClient: ObservableObject {
    // ... existing properties ...
    
    private var refreshTimer: Timer?
    
    private init() {
        loadSession()
        startProactiveRefresh()
    }
    
    /// Start timer to proactively refresh tokens before expiry
    private func startProactiveRefresh() {
        // Check every 5 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshTokenIfNeeded()
            }
        }
    }
    
    /// Refresh token if it expires within 10 minutes
    func refreshTokenIfNeeded() async {
        guard let session = session else { return }
        
        let now = Date()
        let timeUntilExpiry = session.expiresAt.timeIntervalSince(now)
        
        // If expires within 10 minutes, refresh proactively
        if timeUntilExpiry < 600 {
            Logger.info("🔄 [Supabase] Token expires in \(Int(timeUntilExpiry))s - refreshing proactively...")
            do {
                try await refreshToken()
            } catch {
                Logger.error("❌ [Supabase] Proactive refresh failed: \(error)")
                // Don't clear session - just log error
            }
        }
    }
}
```

**Benefits:**
- ✅ Tokens refreshed before expiry
- ✅ No mid-session API failures
- ✅ Better user experience
- ✅ Runs in background

---

### **Solution 4: Session Validation After Creation**

```swift
func createSession(...) async {
    // ... create and save session ...
    
    // Validate session with backend
    Logger.info("🔍 [Supabase] Validating session with backend...")
    
    guard let url = URL(string: "https://api.veloready.app/.netlify/functions/api-validate-session") else {
        Logger.error("❌ [Supabase] Invalid validation URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            Logger.error("❌ [Supabase] Session validation FAILED - token may be invalid")
            Logger.warning("⚠️ [Supabase] Session saved but not validated - API calls may fail")
            return
        }
        
        Logger.info("✅ [Supabase] Session validated successfully - ready for API calls")
        
    } catch {
        Logger.error("❌ [Supabase] Session validation error: \(error)")
    }
}
```

**Benefits:**
- ✅ Verify tokens are actually valid
- ✅ Catch backend issues early
- ✅ Better error reporting

---

### **Solution 5: Better Error Messages**

```swift
private func loadSession() {
    guard let data = UserDefaults.standard.data(forKey: "supabase_session"),
          let session = try? JSONDecoder().decode(SupabaseSession.self, from: data) else {
        // IMPROVED: More actionable message
        Logger.info("ℹ️ [Supabase] No session found - app is in onboarding mode")
        Logger.info("💡 [Supabase] Connect Strava in Settings to enable cloud sync")
        return
    }
    
    // Check if token is expired
    if session.expiresAt > Date() {
        self.session = session
        self.isAuthenticated = true
        Logger.info("✅ [Supabase] Session loaded (expires: \(session.expiresAt))")
        Logger.info("   User ID: \(session.user.id)")
    } else {
        let expiredMinutes = Int(Date().timeIntervalSince(session.expiresAt) / 60)
        Logger.info("⏳ [Supabase] Session expired \(expiredMinutes) minutes ago - refreshing...")
        
        // ... refresh logic ...
    }
}
```

**Benefits:**
- ✅ Less scary messages
- ✅ More actionable
- ✅ Better UX

---

## 📊 Implementation Priority

| **Solution** | **Priority** | **Impact** | **Effort** |
|--------------|--------------|------------|------------|
| 1. Robust Session Creation | 🔴 **HIGH** | Prevents lost sessions | Low |
| 2. Preserve Session on Failure | 🔴 **HIGH** | No forced re-auth | Low |
| 3. Proactive Token Refresh | 🟡 **MEDIUM** | Better runtime UX | Medium |
| 4. Session Validation | 🟡 **MEDIUM** | Early error detection | Low |
| 5. Better Error Messages | 🟢 **LOW** | Less user confusion | Low |

---

## 🧪 Testing Plan

### **Test 1: Fresh Install**
1. Delete app
2. Install and launch
3. Connect Strava
4. **Verify:** Session saved successfully

### **Test 2: Expired Token**
1. Force token expiry (change system time)
2. Launch app
3. **Verify:** Token refreshed, session preserved

### **Test 3: Network Failure During Refresh**
1. Enable Airplane Mode
2. Launch app with expired token
3. **Verify:** Session preserved, retry on next API call

### **Test 4: Backend Error**
1. Backend returns 500 error
2. **Verify:** Session preserved, error logged

### **Test 5: Missing Tokens in OAuth Callback**
1. Backend returns ok=1 but no tokens
2. **Verify:** Error logged, retry attempted

---

## 🎯 Expected Outcomes

**After Implementation:**
- ✅ Sessions reliably saved after Strava OAuth
- ✅ Expired tokens refreshed without clearing session
- ✅ Transient network failures don't log users out
- ✅ Proactive refresh prevents mid-session failures
- ✅ Better logging for debugging
- ✅ More robust, production-ready auth system

**User Impact:**
- ✅ Fewer "connect Strava" prompts
- ✅ No unexpected logouts
- ✅ Better offline experience
- ✅ More reliable API calls

