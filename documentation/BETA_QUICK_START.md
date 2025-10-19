# 🚀 VeloReady Beta - Quick Start Checklist

**Goal:** Get VeloReady to your beta testers in 2-3 hours

---

## ⚡ Critical Items (Must Do First)

### 1. App Icon ⚠️ REQUIRED
**Status:** ❌ Missing  
**Time:** 30 minutes

You **cannot** submit to TestFlight without an app icon.

**Quick Solution:**
1. Create a simple 1024x1024 PNG icon
   - Use Figma, Canva, or Photoshop
   - Simple design: "VR" text or bicycle icon
   - Background color + white text/icon
2. Generate all sizes at [AppIcon.co](https://appicon.co)
3. Add to `VeloReady/Assets.xcassets/AppIcon.appiconset/`

**Or hire on Fiverr:** $10-20, delivered in 24 hours

---

### 2. Privacy Policy ⚠️ REQUIRED
**Status:** ❌ Missing  
**Time:** 20 minutes

TestFlight requires a publicly accessible privacy policy URL.

**Quick Solution:**
1. Use the template in `TESTFLIGHT_DEPLOYMENT_GUIDE.md` (Step 2.1)
2. Deploy to your website: `https://veloready.app/privacy`
3. Or use a simple HTML page on Netlify

**Temporary Solution:**
- Create a simple Markdown file
- Deploy to Netlify: `https://veloready.netlify.app/privacy`
- Update later with custom domain

---

### 3. OAuth Configuration ⚠️ REQUIRED
**Status:** ⏳ Pending  
**Time:** 20 minutes

Beta testers need working OAuth to connect Strava/Intervals.icu.

**Strava Setup:**
1. Go to https://www.strava.com/settings/api
2. Add callback URLs:
   ```
   veloready://auth/strava/callback
   https://veloready.app/auth/strava/callback
   ```

**Intervals.icu Setup:**
1. Go to https://intervals.icu/settings/api
2. Add redirect URIs:
   ```
   veloready://auth/intervals/callback
   https://veloready.app/auth/intervals/callback
   ```

---

## 📋 Pre-Submission Checklist

### Xcode Configuration
- [x] Bundle ID: `com.veloready.app`
- [x] Display Name: "VeloReady"
- [x] Version: 1.0
- [x] Build: 1
- [x] Team: C79WM3NZ27
- [ ] App Icon: **ADD THIS**
- [x] HealthKit capability enabled
- [x] Associated Domains configured

### App Store Connect Setup
- [ ] Create app in App Store Connect
- [ ] Set category: Health & Fitness
- [ ] Complete age rating questionnaire
- [ ] Add privacy policy URL
- [ ] Configure TestFlight information
- [ ] Answer export compliance questions

### Testing
- [ ] Build and run on physical device
- [ ] Test HealthKit permissions
- [ ] Test OAuth flows (Strava, Intervals.icu)
- [ ] Verify no critical crashes
- [ ] Check all screens show "VeloReady"

---

## 🎯 Step-by-Step (2-3 Hours)

### Hour 1: Prepare App

**1. Add App Icon (30 min)**
```bash
# Create icon, then add to Xcode
# VeloReady/Assets.xcassets/AppIcon.appiconset/
```

**2. Deploy Privacy Policy (20 min)**
```bash
# Create privacy.html in your website repo
# Deploy to Netlify
```

**3. Configure OAuth (20 min)**
- Strava Developer Portal
- Intervals.icu API Settings

### Hour 2: App Store Connect

**4. Create App (15 min)**
- Log into App Store Connect
- Create new app
- Fill in basic information

**5. Configure Settings (15 min)**
- Set category and age rating
- Add privacy policy URL
- Configure TestFlight info

**6. Test on Device (30 min)**
- Build to iPhone
- Test all critical flows
- Verify OAuth works

### Hour 3: Archive & Upload

**7. Archive App (20 min)**
```bash
# In Xcode:
# 1. Select "Any iOS Device (arm64)"
# 2. Product → Archive
# 3. Wait for Organizer
```

**8. Upload to App Store Connect (20 min)**
- Validate archive
- Distribute to App Store Connect
- Wait for upload

**9. Wait for Processing (30-60 min)**
- Monitor App Store Connect
- Complete export compliance
- Build becomes "Ready to Test"

### After Processing: Invite Testers

**10. Create Beta Group (10 min)**
- TestFlight → External Testing
- Create "Private Beta" group
- Add your build

**11. Invite Testers (10 min)**
- Add testers by email
- Send invitations
- Testers receive email

---

## 📧 Beta Tester Emails

You have their email addresses. Here's what happens:

**Step 1: Add to TestFlight**
1. App Store Connect → TestFlight → External Testing
2. Click "Add Testers"
3. Enter each email address
4. Click "Send Invites"

**Step 2: Testers Receive Email**
- Email from Apple with TestFlight link
- Instructions to install TestFlight app
- Link to install VeloReady

**Step 3: Testers Install**
1. Install TestFlight (if needed)
2. Accept invitation
3. Install VeloReady
4. Start testing!

---

## 🚨 Common Issues & Solutions

### "No signing certificate"
**Solution:** Xcode → Settings → Accounts → Download Manual Profiles

### "Missing app icon"
**Solution:** Add icon to Assets.xcassets (see Hour 1, Step 1)

### "Invalid provisioning profile"
**Solution:** Clean build (⌘ + Shift + K) and try again

### "Processing stuck"
**Solution:** Wait 60 minutes. If still stuck, upload new build with incremented build number

### "Testers can't install"
**Solution:** Check they're using iOS 17.0+. Resend invitation if expired.

---

## 📝 What Testers Need

**Requirements:**
- iPhone with iOS 17.0 or later
- TestFlight app (free from App Store)
- Email address (to receive invitation)
- Apple Health app with some data

**Optional:**
- Strava account (for activity sync)
- Intervals.icu account (for analytics)

**They do NOT need:**
- Apple Developer account
- Paid subscription
- Special configuration

---

## 🎉 Success Checklist

You're ready when:

- ✅ App icon added
- ✅ Privacy policy live
- ✅ OAuth configured
- ✅ App created in App Store Connect
- ✅ Archive uploaded successfully
- ✅ Build processed and ready
- ✅ Beta group created
- ✅ Testers invited

**Then:** Testers receive email and can install!

---

## 📞 Need Help?

**Detailed Guide:** See `TESTFLIGHT_DEPLOYMENT_GUIDE.md`

**Apple Resources:**
- App Store Connect: https://appstoreconnect.apple.com
- TestFlight Help: https://developer.apple.com/testflight/

**Common Questions:**

**Q: How many testers can I invite?**  
A: Up to 100 external testers without App Review. Up to 10,000 total.

**Q: How long does processing take?**  
A: Usually 30-60 minutes. Can be up to 2 hours.

**Q: Can I update the app after testers install?**  
A: Yes! Just archive and upload a new build with incremented build number.

**Q: Do testers pay anything?**  
A: No, TestFlight is completely free for testers.

**Q: How long can beta testing last?**  
A: Each build is valid for 90 days. You can upload new builds anytime.

---

## 🚀 Ready to Start?

**Next Action:** Add app icon (see Hour 1, Step 1)

**Then:** Follow the 3-hour timeline above

**Questions?** Check `TESTFLIGHT_DEPLOYMENT_GUIDE.md` for detailed instructions

---

**Good luck! 🚴‍♂️**
