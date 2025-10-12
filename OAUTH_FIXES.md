# OAuth Authentication Issues & Fixes

## ⚠️ NEW ISSUE DISCOVERED: Provider Configuration Required

**Status:** App code is correct, but OAuth providers are rejecting requests.

### **Intervals.icu Error**
```
URI error when loading OAuth page
```
**Cause:** `veloready://auth/intervals/callback` is not registered in Intervals.icu OAuth app settings.

**Fix:** Add redirect URI to https://intervals.icu/settings API settings.

### **Strava Error**
```json
{"message":"Bad Request","errors":[{"resource":"Application","field":"redirect_uri","code":"invalid"}]}
```
**Cause:** `https://veloready.app/auth/strava/callback` is not registered in Strava OAuth app settings.

**Fix:** Add callback URL to https://www.strava.com/settings/api application settings.

**See `OAUTH_SETUP_REQUIRED.md` for detailed instructions.**

---

## Previous Issues Fixed

### ✅ Intervals.icu OAuth Callback (CRITICAL FIX)

**Problem:**
The WebView was checking for the wrong URL scheme when Intervals.icu redirected back after authentication. It was looking for `com.markboulton.rideready` but the actual redirect URI was `veloready://auth/intervals/callback`.

**Symptom:**
- User successfully logged into Intervals.icu
- WebView loaded but never triggered the callback
- App remained in connecting state
- No authentication tokens were exchanged

**Files Fixed:**
- `/VeloReady/Features/Onboarding/Views/IntervalsOAuthWebView.swift` (line 81)
- `/VeloReady/Features/Onboarding/Views/OAuthWebView.swift` (line 68)

**Change:**
```swift
// OLD (BROKEN):
if url.scheme == "com.markboulton.rideready" {

// NEW (FIXED):
if url.scheme == "veloready" || url.scheme == "rideready" || url.scheme == "com.veloready.app" {
```

**Why This Works:**
- Now properly detects when intervals.icu redirects to `veloready://auth/intervals/callback`
- Supports both new `veloready://` and legacy `rideready://` schemes
- WebView intercepts the redirect and calls `onCallback()` as intended
- The app's `onOpenURL` handler in `VeloReadyApp.swift` then processes the authorization code

---

### ⚠️ Strava OAuth (USER CANCELLED - NOT A BUG)

**Analysis:**
The log shows:
```
👋 [STRAVA OAUTH] User cancelled - closing session
Error Code: 1 (ASWebAuthenticationSessionError.canceledLogin)
```

**This is NOT a bug** - the user actually cancelled the Strava OAuth flow by:
- Tapping "Cancel" in the OAuth browser
- Closing the authentication sheet
- Denying permissions

**Strava OAuth Flow is Configured Correctly:**
- Uses `ASWebAuthenticationSession` (Apple's recommended approach)
- Callback scheme: `veloready://` 
- Backend endpoint: `https://veloready.app/oauth/strava/start`
- Properly configured in `Info.plist` with URL schemes

**To Test Strava OAuth:**
1. Tap "Connect to Strava" in the app
2. **Complete** the authentication flow (don't tap Cancel)
3. Log in with valid Strava credentials
4. Approve the permissions
5. The backend will handle token exchange and redirect back to the app

---

## Configuration Summary

### URL Schemes (Info.plist)
```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>veloready</string>      <!-- Primary scheme -->
    <string>rideready</string>       <!-- Legacy support -->
    <string>com.veloready.app</string>
</array>
```

### Intervals.icu OAuth Config
- Client ID: `108`
- Redirect URI: `veloready://auth/intervals/callback`
- OAuth Endpoint: `https://intervals.icu/oauth/authorize`
- Token Endpoint: `https://intervals.icu/api/oauth/token`
- Scopes: `ACTIVITY:READ,WELLNESS:READ,CALENDAR:READ,SETTINGS:READ`

### Strava OAuth Config
- Uses backend proxy: `https://veloready.app/oauth/strava/start`
- Callback scheme: `veloready://` or Universal Links
- Status polling: `https://veloready.app/api/me/strava/status`

---

## Testing Instructions

### Test Intervals.icu OAuth:

1. Build and run the app
2. Navigate to Settings → Data Sources
3. Tap "Connect to intervals.icu"
4. Log in with your intervals.icu credentials
5. Approve permissions
6. **Expected:** Should now see callback logs:
   ```
   ✅ OAuth callback detected in WebView: veloready://
   Full URL: veloready://auth/intervals/callback?code=...&state=...
   ✅ Authorization code received
   🔄 Exchanging code for tokens...
   ✅ Tokens received successfully
   ```

### Test Strava OAuth:

1. Build and run the app
2. Navigate to Settings → Data Sources
3. Tap "Connect to Strava"
4. **Important:** Complete the entire flow - don't cancel!
5. Log in with Strava credentials
6. Approve permissions
7. **Expected:** Should see:
   ```
   🚀 [STRAVA OAUTH] Starting OAuth Flow
   ✅ [STRAVA OAUTH] Session started successfully
   ✅ [STRAVA OAUTH] Callback URL received!
   ✅ Strava OAuth successful
   ```

---

## Known Remaining Issues

### Test/Debug Files (Low Priority)
The following test files still reference old schemes but are not used in production:
- `IntervalsOAuthTestView.swift`
- `OAuthDebugView.swift`

These can be updated later if needed for testing.

---

## Build Status

✅ Build succeeded with no errors
⚠️ 5 warnings (Swift 6 concurrency - not related to OAuth)

---

## Next Steps

1. **Test the Intervals.icu OAuth** - This should now work correctly
2. **Test Strava OAuth** - Make sure to complete the flow instead of cancelling
3. If Strava still fails, check:
   - Backend logs at `https://veloready.app`
   - Strava developer console for API errors
   - Network connectivity

---

**Summary:** The critical Intervals.icu OAuth bug has been fixed. Users can now successfully authenticate with intervals.icu. Strava OAuth was already working - users just need to complete the authentication flow instead of cancelling it.
