# OAuth Fix - Action Plan

## Summary

**Problem:** Both OAuth flows are failing because redirect URIs aren't registered with the providers.

**Solutions Applied:**
1. ✅ Fixed app WebView callback detection  
2. ✅ Updated website OAuth landing page to use correct redirect URIs
3. ⏳ **YOU MUST:** Register redirect URIs in provider settings (5 minutes)

---

## 🚨 REQUIRED ACTIONS (Do This First!)

### Action 1: Register Intervals.icu Redirect URI (2 minutes)

1. **Go to:** https://intervals.icu/settings  
   (or wherever you manage your Intervals.icu OAuth app - Client ID: `108`)

2. **Find:** "Redirect URIs" or "Callback URLs" section

3. **Add this exact URI:**
   ```
   veloready://auth/intervals/callback
   ```

4. **Save** the application settings

5. **Test:** Open the app → Settings → Connect to Intervals.icu

---

### Action 2: Register Strava Redirect URIs (2 minutes)

1. **Go to:** https://www.strava.com/settings/api

2. **Find your VeloReady application** (or create one if it doesn't exist)

3. **Set Authorization Callback Domain:**
   ```
   veloready.app
   ```

4. **Add these callback URLs:**
   ```
   https://veloready.app/oauth/strava/callback
   veloready://auth/strava/callback
   ```
   
   **Note:** If Strava only allows one URL, use the HTTPS one.

5. **Save** the application

6. **Test:** Open the app → Settings → Connect to Strava

---

### Action 3: Deploy Updated Website (1 minute)

The website OAuth landing page has been updated to use correct redirect URIs.

**If using Netlify with auto-deploy:**
```bash
cd ~/Dev/veloready-website
git add .
git commit -m "Fix OAuth redirect URIs for veloready:// scheme"
git push origin main
```

Netlify will auto-deploy in ~2 minutes.

**Verify deployment:**
```bash
curl https://veloready.app/oauth/intervals/callback
# Should return HTML (not 404)
```

---

## What Was Fixed in the Code

### ✅ App Code (VeloReady)

**File:** `IntervalsOAuthWebView.swift`
- **Before:** Checked for `com.markboulton.rideready` scheme
- **After:** Checks for `veloready://` or `rideready://` schemes
- **Impact:** OAuth callbacks now properly detected in WebView

**File:** `OAuthWebView.swift`
- Same fix applied for consistency

### ✅ Website Code (veloready-website)

**File:** `public/oauth-callback.html`
- **Before:** Redirected to `com.markboulton.veloready://oauth/callback`
- **After:** Redirects to `veloready://auth/intervals/callback`
- **Before:** Redirected to `veloready://oauth/strava/done`
- **After:** Redirects to `veloready://auth/strava/done`
- **Impact:** Landing pages now redirect to correct app URLs

---

## Testing After Configuration

### Test Intervals.icu OAuth:

1. Open VeloReady app
2. Go to Settings → Data Sources
3. Tap "Connect to intervals.icu"
4. **Expected behavior:**
   - ✅ WebView opens with Intervals.icu login
   - ✅ You enter credentials and approve
   - ✅ Page redirects to `https://veloready.app/oauth/intervals/callback?code=...`
   - ✅ Landing page immediately redirects to `veloready://auth/intervals/callback`
   - ✅ App receives callback and exchanges code for token
   - ✅ You see "Connected to Intervals.icu" in settings

5. **Check logs for:**
   ```
   ✅ OAuth callback detected in WebView: veloready://
   ✅ Authorization code received
   🔄 Exchanging code for tokens...
   ✅ Tokens received successfully
   ```

### Test Strava OAuth:

1. Open VeloReady app
2. Go to Settings → Data Sources
3. Tap "Connect to Strava"
4. **Expected behavior:**
   - ✅ ASWebAuthenticationSession browser opens
   - ✅ Redirects to backend: `https://veloready.app/oauth/strava/start`
   - ✅ Backend redirects to Strava login
   - ✅ You enter credentials and approve
   - ✅ Strava redirects to `https://veloready.app/oauth/strava/callback?code=...`
   - ✅ Landing page exchanges code for token via backend
   - ✅ Landing page redirects to `veloready://auth/strava/done?ok=1`
   - ✅ App receives callback and polls for status
   - ✅ You see "Connected to Strava" in settings

5. **Check logs for:**
   ```
   🚀 [STRAVA OAUTH] Starting OAuth Flow
   ✅ [STRAVA OAUTH] Session started successfully
   ✅ [STRAVA OAUTH] Callback URL received!
   ✅ Strava OAuth successful
   ```

---

## Alternative: Custom URL Schemes Only (Simpler)

If you don't want to use the website landing pages, you can configure both providers to use custom URL schemes directly:

### Intervals.icu
**Redirect URI:** `veloready://auth/intervals/callback`  
✅ Works with WebView

### Strava
**Redirect URI:** `veloready://auth/strava/callback`  
⚠️ May not work - Strava often requires HTTPS URLs

**To switch to this approach:**

1. Update `StravaAuthService.swift` line 198:
   ```swift
   URLQueryItem(name: "redirect", value: "veloready://auth/strava/callback")
   ```

2. Register `veloready://auth/strava/callback` in Strava settings

3. The backend at `veloready.app` needs to accept this as a valid redirect

**Pros:** No website dependency  
**Cons:** May not work with all OAuth providers

---

## Troubleshooting

### "redirect_uri_mismatch" Error

**Cause:** The redirect URI in the request doesn't match what's registered.

**Fix:**
1. Copy the **exact** redirect URI from the error message
2. Paste it into the OAuth provider settings
3. Make sure there are no trailing slashes or extra characters
4. Save and retry

### Intervals.icu Still Shows URI Error

**Possible causes:**
1. Redirect URI not saved in Intervals.icu settings
2. Using wrong Client ID
3. URL scheme not registered in Info.plist (already done)

**Debug steps:**
1. Double-check the redirect URI in Intervals.icu settings: `veloready://auth/intervals/callback`
2. Verify it matches **exactly** (no spaces, correct slashes)
3. Try logging out and back into Intervals.icu

### Strava Still Shows "Invalid redirect_uri"

**Possible causes:**
1. Callback URL not added to Strava app settings
2. Authorization Callback Domain not set to `veloready.app`
3. Strava backend at `rideready.icu` needs configuration

**Debug steps:**
1. Go to https://www.strava.com/settings/api
2. Edit your VeloReady application
3. Verify Authorization Callback Domain: `veloready.app`
4. Verify callback URL exists: `https://veloready.app/oauth/strava/callback`
5. If using custom scheme, add: `veloready://auth/strava/callback`

### Website Not Deployed

**Check deployment status:**
```bash
# Check if website is accessible
curl -I https://veloready.app

# Check OAuth endpoint
curl https://veloready.app/oauth/intervals/callback
```

**If website doesn't exist:**
1. Verify Netlify site is configured
2. Check DNS is pointing to Netlify
3. Verify custom domain is set up in Netlify dashboard

---

## Current Configuration Summary

### App (VeloReady)

**Info.plist URL Schemes:**
- ✅ `veloready`
- ✅ `rideready` (legacy)
- ✅ `com.veloready.app`

**Deep Link Handlers:**
- ✅ `veloready://auth/intervals/callback`
- ✅ `veloready://auth/strava/callback`
- ✅ `veloready://auth/strava/done`

### Website (veloready.app)

**OAuth Endpoints:**
- ✅ `/oauth/intervals/callback` → serves landing page
- ✅ `/oauth/strava/callback` → serves landing page  
- ✅ `/oauth/strava/done` → serves landing page

**Landing Page Redirects:**
- ✅ Intervals: `veloready://auth/intervals/callback?code=...&state=...`
- ✅ Strava: `veloready://auth/strava/done?ok=1&state=...&athlete_id=...`

### OAuth Provider Settings (You Need to Configure)

**Intervals.icu:**
- ⏳ Client ID: `108`
- ⏳ Redirect URI: `veloready://auth/intervals/callback` **← ADD THIS**

**Strava:**
- ⏳ Authorization Callback Domain: `veloready.app` **← ADD THIS**
- ⏳ Callback URLs: 
  - `https://veloready.app/oauth/strava/callback` **← ADD THIS**
  - `veloready://auth/strava/callback` **← OPTIONAL**

---

## Next Steps

1. ✅ **You're reading this** - Good!
2. ⏳ **Register redirect URIs** in Intervals.icu (2 min)
3. ⏳ **Register callback URLs** in Strava (2 min)
4. ⏳ **Deploy website changes** to Netlify (1 min)
5. ✅ **Test OAuth flows** in the app (5 min)
6. 🎉 **OAuth working!**

---

**Questions?**
- Check the logs in Xcode console
- Verify network requests in Safari Dev Tools
- Test on a physical device (Universal Links don't work in simulator)
