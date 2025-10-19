# Backend Migration: rideready.icu → veloready.app

## ✅ Migration Complete

All backend references have been updated from `rideready.icu` to `veloready.app`.

---

## Files Updated

### **Backend Configuration**

1. **`StravaAuthConfig.swift`**
   - ✅ `backendBase`: `https://rideready.icu` → `https://veloready.app`
   - ✅ `startURL`: `https://rideready.icu/oauth/strava/start` → `https://veloready.app/oauth/strava/start`
   - ✅ `statusURL`: `https://rideready.icu/api/me/strava/status` → `https://veloready.app/api/me/strava/status`
   - ✅ `universalLinkRedirect`: `https://rideready.icu/oauth/strava/done` → `https://veloready.app/oauth/strava/done`

### **API Endpoints**

2. **`AIBriefClient.swift`**
   - ✅ `endpoint`: `https://api.rideready.icu/ai-brief` → `https://veloready.app/ai-brief`

3. **`RideSummaryClient.swift`**
   - ✅ `endpoint`: `https://api.rideready.icu/ai-ride-summary` → `https://veloready.app/ai-ride-summary`

4. **`StravaAPIClient.swift`**
   - ✅ `backendURL`: `https://rideready.icu/api/me/strava/token` → `https://veloready.app/api/me/strava/token`

### **OAuth Handlers**

5. **`StravaAuthService.swift`**
   - ✅ Removed `rideready.icu` from Universal Link validation
   - ✅ Updated comments to reflect veloready.app as primary

6. **`VeloReadyApp.swift`**
   - ✅ Updated Strava OAuth callback handler to use `veloready.app` only
   - ✅ Kept legacy `rideready://` URL scheme support for backward compatibility

---

## What Was Kept (Intentionally)

### **Legacy URL Scheme Support**

- ✅ `rideready://` URL scheme - For backward compatibility
- ✅ `rideready.icu` in entitlements - For legacy Universal Links
- ✅ Keychain service name: `com.markboulton.rideready.secrets` - Changing would lose existing data

### **Widget & File Names**

- `RideReadyWidget.swift` - Legacy file/type names (no functional impact)
- `RideReadyLogo.swift` - Component names (no functional impact)

---

## New Backend Endpoints

The app now expects these endpoints at **veloready.app**:

### **Strava OAuth**
- `GET /oauth/strava/start` - Initiates Strava OAuth flow
- `GET /oauth/strava/callback` - Handles Strava redirect
- `POST /.netlify/functions/oauth-strava-token-exchange` - Exchanges code for token
- `GET /api/me/strava/status` - Checks connection status
- `GET /api/me/strava/token` - Gets access token

### **AI Services**
- `POST /ai-brief` - AI training brief
- `POST /ai-ride-summary` - AI ride summary

---

## Testing Checklist

### **Before Testing:**
- [ ] Ensure veloready.app backend is deployed with all endpoints
- [ ] Verify Netlify functions are working
- [ ] Check DNS is propagated

### **Strava OAuth Test:**
1. Open app → Settings → Connect to Strava
2. Should navigate to: `https://veloready.app/oauth/strava/start`
3. Should redirect to Strava login
4. After approval, should return to app
5. **Expected logs:**
   ```
   🔗 [STRAVA OAUTH] Auth URL constructed:
      URL: https://veloready.app/oauth/strava/start?state=...
   ✅ [STRAVA OAUTH] Session started successfully
   ```

### **AI Services Test:**
1. Calculate recovery score
2. Should call: `https://veloready.app/ai-brief`
3. **Expected logs:**
   ```
   📊 AI Brief Response: HTTP 200
   ✅ AI brief fetched successfully
   ```

---

## Build Status

✅ **Build succeeded** with no errors

---

## Deployment Requirements

### **Website (veloready.app)**

Make sure these files are deployed:
- `public/oauth-callback.html` - OAuth landing page
- `netlify.toml` - Routing configuration
- `.netlify/functions/oauth-strava-token-exchange` - Token exchange function
- `.netlify/functions/ai-brief` - AI brief endpoint
- `.netlify/functions/ai-ride-summary` - AI ride summary endpoint

### **DNS Configuration**

Ensure DNS points to Netlify:
```
veloready.app → Netlify IP
```

---

## Rollback Plan

If needed to revert to rideready.icu:

1. Revert `StravaAuthConfig.swift`:
   ```swift
   static let backendBase = "https://rideready.icu"
   ```

2. Revert API endpoints in:
   - `AIBriefClient.swift`
   - `RideSummaryClient.swift`
   - `StravaAPIClient.swift`

3. Rebuild and deploy

---

**Migration completed:** Oct 12, 2025
**Build status:** ✅ Successful
