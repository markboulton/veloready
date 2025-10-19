# VeloReady Setup Instructions

**Status:** ✅ Source files migrated and configured  
**Next Step:** Create Xcode project

---

## ✅ What's Already Done

1. **✅ Source Files Migrated**
   - All Swift files copied from Rideready to `/Users/markboulton/Dev/VeloReady/VeloReady/`
   - Main app renamed: `VeloReadyApp.swift`
   - OAuth configurations updated for both `veloready://` and legacy `rideready://`

2. **✅ OAuth Configured**
   - StravaAuthService supports `veloready://` and `rideready://` schemes
   - IntervalsOAuthManager uses `veloready://auth/intervals/callback`
   - VeloReadyApp handles callbacks for both domains (veloready.app + rideready.icu)

3. **✅ Info.plist Updated**
   - CFBundleDisplayName: "VeloReady"
   - URL Schemes: `veloready`, `rideready`, `com.veloready.app`
   - Background task: `com.veloready.app.refresh`

4. **✅ Entitlements Ready**
   - File: `VeloReady.entitlements`
   - Associated domains: `veloready.app`, `rideready.icu`
   - HealthKit enabled

5. **✅ Infrastructure Files Created**
   - `netlify.toml` - Netlify configuration with redirects
   - `apple-app-site-association.json` - Universal Links configuration
   - `public/` directory ready for deployment

---

## 🚀 Next Steps: Create Xcode Project

Since the source files are ready, you need to create the Xcode project:

### Option 1: Create New Project in Xcode (Recommended)

1. **Open Xcode**
   ```bash
   open -a Xcode
   ```

2. **Create New Project**
   - File → New → Project
   - iOS → App
   - Product Name: **VeloReady**
   - Team: (select your team)
   - Organization Identifier: **com.veloready**
   - Bundle Identifier: **com.veloready.app**
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Save to: `/Users/markboulton/Dev/VeloReady`

3. **Delete Default Files**
   - Delete the auto-generated `VeloReadyApp.swift`
   - Delete the auto-generated `ContentView.swift`
   - Delete the `Preview Content` folder (we have our own)

4. **Add Existing Source Files**
   - Right-click on VeloReady in Project Navigator
   - Add Files to "VeloReady"...
   - Select `/Users/markboulton/Dev/VeloReady/VeloReady` folder
   - **Important:** Uncheck "Copy items if needed" (files are already in place)
   - Select "Create groups"
   - Click "Add"

5. **Update Entitlements**
   - Select project → VeloReady target
   - Signing & Capabilities tab
   - Click "+ Capability"
   - Add **HealthKit**
   - Add **Associated Domains**
     - `applinks:veloready.app`
     - `applinks:rideready.icu`
     - `applinks:api.veloready.app`
   - Under "Signing"
     - Code Signing Entitlements: `VeloReady/VeloReady.entitlements`

6. **Configure Info.plist Path**
   - Select project → VeloReady target
   - Build Settings tab
   - Search for "Info.plist"
   - Info.plist File: `VeloReady/Info.plist`

7. **Build and Test**
   - ⌘ + B to build
   - Fix any errors (shouldn't be any!)
   - ⌘ + R to run on simulator

---

### Option 2: Use Existing VeloReady.xcodeproj

If there's already a `VeloReady.xcodeproj` in `/Users/markboulton/Dev/Rideready`:

```bash
# Copy it to new location
cp -R /Users/markboulton/Dev/Rideready/VeloReady.xcodeproj /Users/markboulton/Dev/VeloReady/

# Open it
open /Users/markboulton/Dev/VeloReady/VeloReady.xcodeproj
```

Then:
1. Update all file references to point to new location
2. Update bundle ID to `com.veloready.app`
3. Update entitlements path
4. Clean build folder: ⌘ + Shift + K
5. Build: ⌘ + B

---

## 📱 Third-Party Service Configuration

### Strava OAuth Setup

1. **Login:** https://www.strava.com/settings/api

2. **Update Application:**
   ```
   Application Name: VeloReady
   Website: https://veloready.app
   Authorization Callback Domain: veloready.app
   
   Callback URLs (add all):
   ✓ https://veloready.app/auth/strava/callback
   ✓ https://rideready.icu/auth/strava/callback (legacy)
   ✓ veloready://auth/strava/callback
   ✓ rideready://auth/strava/callback (legacy)
   ```

3. **Save Changes**

### Intervals.icu OAuth Setup

1. **Login:** https://intervals.icu/settings/api

2. **Update Application:**
   ```
   Application Name: VeloReady
   Home Page URL: https://veloready.app
   
   Redirect URIs (add all):
   ✓ veloready://auth/intervals/callback
   ✓ rideready://auth/intervals/callback (legacy)
   ✓ https://veloready.app/auth/intervals/callback
   ✓ https://rideready.icu/auth/intervals/callback (legacy)
   ```

3. **Save Changes**

---

## 🌐 Netlify Deployment

### Step 1: Deploy to Netlify

1. **Login to Netlify:** https://app.netlify.com

2. **Create New Site:**
   - Sites → Add new site → Import an existing project
   - Connect to your Git provider
   - Select repository: `veloready` (or your repo name)
   - Build settings:
     - Build command: (leave empty or `echo 'Static site'`)
     - Publish directory: `public`
   - Deploy site

3. **Add Custom Domain:**
   - Site settings → Domain management
   - Add custom domain: `veloready.app`
   - Follow DNS configuration instructions

4. **Update apple-app-site-association:**
   - Edit `/Users/markboulton/Dev/VeloReady/apple-app-site-association.json`
   - Replace `YOUR_TEAM_ID` with your actual Apple Team ID
   - Commit and push changes
   - Netlify will auto-deploy

5. **Verify Universal Links:**
   - Visit: https://veloready.app/.well-known/apple-app-site-association
   - Should return JSON (not 404)
   - Content-Type should be `application/json`

### Step 2: Configure DNS

At your DNS provider (e.g., Cloudflare, GoDaddy):

```
Type    Name    Value                           TTL
A       @       75.2.60.5 (Netlify IP)         Auto
CNAME   www     veloready.app                   Auto
CNAME   api     api.veloready.app              Auto
```

**Note:** Get actual Netlify IP from your Netlify dashboard.

---

## 🧪 Testing Checklist

### Build Testing
- [ ] Project builds without errors
- [ ] No warnings (or minimal/expected warnings)
- [ ] App launches on simulator
- [ ] App launches on physical device

### OAuth Testing (Physical Device!)
- [ ] Strava OAuth with `veloready://` works
- [ ] Intervals.icu OAuth with `veloready://` works
- [ ] Legacy `rideready://` still works (if testing upgrade path)

### Universal Links Testing (Physical Device!)
- [ ] Send email with: `https://veloready.app/auth/strava/callback?code=test`
- [ ] Tap link → Opens VeloReady app (not Safari)
- [ ] Test legacy: `https://rideready.icu/auth/strava/callback?code=test`
- [ ] Should also open VeloReady app

### Deep Links Testing
- [ ] Test: `veloready://auth/strava/callback`
- [ ] Test: `veloready://auth/intervals/callback`
- [ ] Legacy: `rideready://` still works

---

## 🐛 Troubleshooting

### Build Errors

**"Cannot find VeloReadyApp in scope"**
- Ensure `VeloReadyApp.swift` exists in project
- Check target membership (file inspector → Target Membership)

**"Missing Info.plist"**
- Build Settings → Info.plist File: `VeloReady/Info.plist`

**"Code signing error"**
- Select target → Signing & Capabilities
- Team: Select your team
- Enable "Automatically manage signing"

### OAuth Not Working

**"Redirect URI mismatch" from Strava**
- Double-check all 4 callback URLs added to Strava Developer Portal
- URLs must match exactly (case-sensitive!)

**App doesn't open when clicking OAuth link**
- Universal Links only work on physical device (not simulator)
- Verify apple-app-site-association is deployed to veloready.app
- Force-quit app and try again
- Wait 24 hours for Apple CDN to update

**"Invalid callback URL"**
- Check URL schemes in Info.plist
- Verify both `veloready` and `rideready` schemes present

### Universal Links Not Working

1. **Verify file is accessible:**
   ```bash
   curl -v https://veloready.app/.well-known/apple-app-site-association
   ```
   Should return JSON with 200 status

2. **Check Content-Type:**
   Must be `application/json` (not `text/plain`)

3. **Test on physical device:**
   Simulator doesn't support Universal Links properly

4. **Clear app data:**
   - Delete app from device
   - Reinstall
   - Test again

---

## 📊 Migration Status

- ✅ Source code migrated
- ✅ OAuth services updated
- ✅ Info.plist configured  
- ✅ Entitlements configured
- ✅ Infrastructure files created
- ⏳ Xcode project needs creation (manual step)
- ⏳ Strava OAuth needs update (manual step)
- ⏳ Intervals.icu OAuth needs update (manual step)
- ⏳ Netlify deployment needed
- ⏳ Testing on physical device needed

---

## 🎯 Final Checklist

Before considering migration complete:

- [ ] Xcode project created and builds successfully
- [ ] App runs on simulator without crashes
- [ ] App runs on physical device
- [ ] Strava OAuth configured in developer portal
- [ ] Intervals.icu OAuth configured
- [ ] Netlify site deployed with veloready.app domain
- [ ] DNS configured and propagated
- [ ] apple-app-site-association deployed and accessible
- [ ] Universal Links tested on physical device
- [ ] OAuth flows tested end-to-end
- [ ] All branding shows "VeloReady" (not "Rideready")

---

## 📞 Support Resources

- **Strava API:** developers@strava.com
- **Intervals.icu:** support@intervals.icu
- **Netlify:** support.netlify.com
- **Apple Developer:** developer.apple.com/contact

---

## 🎉 Next Steps After Setup

1. **Test thoroughly** on physical device
2. **Fix any issues** that arise
3. **Prepare for TestFlight** beta testing
4. **Update App Store Connect** metadata
5. **Submit for review**
6. **Launch! 🚀**

---

**Questions or Issues?**

Check the comprehensive guides:
- `/Users/markboulton/Dev/Rideready/VELOREADY_MIGRATION_PLAN.md`
- `/Users/markboulton/Dev/Rideready/OAUTH_MIGRATION_GUIDE.md`

**Good luck! 🚴‍♂️**
