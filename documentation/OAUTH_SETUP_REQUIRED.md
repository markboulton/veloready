# OAuth Setup Required - Action Items

## 🚨 CRITICAL: Both OAuth Providers Need Configuration

Your OAuth flows are **failing at the provider level** because redirect URIs aren't registered. The app code is correct, but the OAuth providers are rejecting the requests.

---

## Issue 1: Intervals.icu Error

**Error:** "URI error" when trying to authenticate

**Root Cause:**  
The redirect URI `veloready://auth/intervals/callback` is **not whitelisted** in your Intervals.icu OAuth application settings.

**Fix Required:**

### Step 1: Log into Intervals.icu Developer Portal
1. Go to: https://intervals.icu/settings (or your account settings)
2. Navigate to **API Applications** or **OAuth Apps**
3. Find your application (Client ID: `108`)

### Step 2: Add Redirect URI
Add this **exact** redirect URI to your application:
```
veloready://auth/intervals/callback
```

**Important:**
- The URI must match **exactly** (case-sensitive)
- No trailing slash
- Include the custom URL scheme `veloready://`

### Step 3: Save and Test
1. Save the application settings
2. Wait a few minutes for changes to propagate
3. Try connecting again in the app

---

## Issue 2: Strava "Invalid redirect_uri" Error

**Error:**  
```json
{"message":"Bad Request","errors":[{"resource":"Application","field":"redirect_uri","code":"invalid"}]}
```

**Root Cause:**  
The redirect URI `https://veloready.app/auth/strava/callback` is **not whitelisted** in your Strava API application settings.

**Fix Required:**

### Step 1: Log into Strava Developer Portal
1. Go to: https://www.strava.com/settings/api
2. Find your "VeloReady" application
3. Click "Edit" or "Update Application"

### Step 2: Add Authorization Callback Domain
In the "Authorization Callback Domain" field, add:
```
veloready.app
```

### Step 3: Add Redirect URIs
Strava requires you to specify the **exact** callback URLs. Add these:

```
https://veloready.app/auth/strava/callback
veloready://auth/strava/callback
rideready://auth/strava/callback
```

**Note:** Some OAuth providers only accept HTTPS URLs, not custom schemes. If Strava rejects `veloready://`, you must use the HTTPS URLs.

### Step 4: Save and Test
1. Click "Update" or "Save"
2. Wait a few minutes for changes to propagate
3. Try connecting again in the app

---

## Website Landing Pages (Required for HTTPS Redirects)

If you're using `https://veloready.app/auth/strava/callback`, you need landing pages that redirect to your app.

### Check Your Netlify Website

1. **Verify the site exists:**
   ```bash
   curl -I https://veloready.app
   ```
   Should return `200 OK` or `301 redirect`

2. **Check if OAuth handlers exist:**
   ```bash
   curl https://veloready.app/auth/strava/callback?code=test123&state=abc
   ```
   Should either:
   - Return HTML with JavaScript redirect to `veloready://`
   - Return 301 redirect to `veloready://auth/strava/done?code=test123&state=abc`

### If Landing Pages Don't Exist:

You need to create HTML pages that capture the OAuth code and redirect to your app:

**File: `veloready-website/auth/strava/callback.html`**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Connecting to Strava...</title>
    <meta charset="UTF-8">
</head>
<body>
    <h1>Connecting to Strava...</h1>
    <p>Redirecting to VeloReady app...</p>
    
    <script>
        // Get query parameters
        const params = new URLSearchParams(window.location.search);
        const code = params.get('code');
        const state = params.get('state');
        const error = params.get('error');
        
        // Build deep link URL
        let deepLink = 'veloready://auth/strava/callback?';
        if (code) deepLink += 'code=' + encodeURIComponent(code) + '&';
        if (state) deepLink += 'state=' + encodeURIComponent(state) + '&';
        if (error) deepLink += 'error=' + encodeURIComponent(error);
        
        // Attempt redirect
        window.location.href = deepLink;
        
        // Fallback message
        setTimeout(() => {
            document.body.innerHTML = '<h2>Almost there!</h2><p>Tap to open VeloReady:</p><a href="' + deepLink + '">Open VeloReady</a>';
        }, 2000);
    </script>
</body>
</html>
```

**File: `veloready-website/auth/intervals/callback.html`**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Connecting to Intervals.icu...</title>
    <meta charset="UTF-8">
</head>
<body>
    <h1>Connecting to Intervals.icu...</h1>
    <p>Redirecting to VeloReady app...</p>
    
    <script>
        const params = new URLSearchParams(window.location.search);
        const code = params.get('code');
        const state = params.get('state');
        const error = params.get('error');
        
        let deepLink = 'veloready://auth/intervals/callback?';
        if (code) deepLink += 'code=' + encodeURIComponent(code) + '&';
        if (state) deepLink += 'state=' + encodeURIComponent(state) + '&';
        if (error) deepLink += 'error=' + encodeURIComponent(error);
        
        window.location.href = deepLink;
        
        setTimeout(() => {
            document.body.innerHTML = '<h2>Almost there!</h2><p>Tap to open VeloReady:</p><a href="' + deepLink + '">Open VeloReady</a>';
        }, 2000);
    </script>
</body>
</html>
```

Deploy these to your Netlify site.

---

## Quick Start: Minimal Working Setup

### Option 1: Custom URL Schemes Only (Simplest)

**Pros:** No website required  
**Cons:** Some OAuth providers reject custom schemes

1. **Intervals.icu Settings:**
   - Redirect URI: `veloready://auth/intervals/callback`

2. **Strava Settings:**
   - Redirect URI: `veloready://auth/strava/callback`

3. **Update app to use custom schemes only:**

```swift
// In IntervalsOAuthManager.swift - line 25
private let redirectURI = "veloready://auth/intervals/callback"

// In StravaAuthService.swift - line 198
URLQueryItem(name: "redirect", value: "veloready://auth/strava/callback")
```

### Option 2: HTTPS URLs (More Reliable)

**Pros:** Works with all OAuth providers  
**Cons:** Requires website with landing pages

1. **Deploy landing pages to Netlify** (see HTML above)

2. **Intervals.icu Settings:**
   - Redirect URI: `https://veloready.app/auth/intervals/callback`

3. **Strava Settings:**
   - Redirect URI: `https://veloready.app/auth/strava/callback`

4. **App code already configured for this!** No changes needed.

---

## Testing Checklist

### After Configuring Intervals.icu:
- [ ] Redirect URI registered: `veloready://auth/intervals/callback`
- [ ] Open app → Settings → Connect Intervals.icu
- [ ] Should successfully authorize and return to app
- [ ] Check logs for: `✅ Authorization code received`

### After Configuring Strava:
- [ ] Redirect URI registered: `https://veloready.app/auth/strava/callback`
- [ ] Landing page deployed and accessible
- [ ] Open app → Settings → Connect Strava
- [ ] Should successfully authorize and return to app
- [ ] Check logs for: `✅ [STRAVA OAUTH] Callback URL received!`

---

## Common Issues

### "redirect_uri_mismatch" Error
**Cause:** The redirect URI in the OAuth request doesn't **exactly** match what's registered.

**Fix:**
1. Copy the redirect URI from the error message
2. Paste it exactly into the OAuth provider settings (including protocol, path, and query params if any)
3. Save and retry

### "Invalid Redirect URI" Error  
**Cause:** OAuth provider doesn't accept custom URL schemes

**Fix:** Use HTTPS redirect URIs with landing pages instead

### Landing Page Opens in Safari Instead of App
**Cause:** Universal Links not configured or not working

**Fix:**
1. Verify `apple-app-site-association` file is deployed
2. Test on a **physical device** (Universal Links don't work in simulator)
3. Uninstall/reinstall app to refresh Universal Links cache

---

## Current Configuration Status

**What's Already Configured in the App:**
- ✅ Custom URL schemes: `veloready://` and `rideready://`
- ✅ Deep link handlers in `VeloReadyApp.swift`
- ✅ OAuth managers ready to handle callbacks
- ✅ Info.plist with URL scheme declarations

**What You Need to Configure:**
- ⏳ Intervals.icu OAuth app redirect URI
- ⏳ Strava OAuth app redirect URI
- ⏳ (Optional) Landing pages on veloready.app

---

## Next Steps

1. **Immediate (5 minutes):**
   - Add redirect URIs to Intervals.icu OAuth app
   - Add redirect URIs to Strava OAuth app

2. **If using HTTPS redirects (30 minutes):**
   - Create landing page HTML files
   - Deploy to Netlify
   - Test on physical device

3. **Test the full flow:**
   - Build and run app
   - Connect to Intervals.icu → Should work!
   - Connect to Strava → Should work!

---

**Need Help?**
- Intervals.icu API Docs: https://forum.intervals.icu/t/oauth2/850
- Strava API Docs: https://developers.strava.com/docs/authentication/
- Check Netlify deployment: https://app.netlify.com/sites/veloready/overview
