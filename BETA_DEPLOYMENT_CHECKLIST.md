# ✅ VeloReady Beta Deployment Checklist

**Print this or keep it open while deploying!**

---

## 🎯 Before You Start

- [ ] Have Apple Developer account access
- [ ] Have App Store Connect access
- [ ] Have Xcode 15+ installed
- [ ] Have VeloReady project ready
- [ ] Have beta tester email addresses ready
- [ ] Set aside 2-3 hours

---

## 📱 Step 1: App Icon (30 min)

- [ ] Create 1024x1024 PNG icon
- [ ] Generate all sizes (use appicon.co)
- [ ] Add to `VeloReady/Assets.xcassets/AppIcon.appiconset/`
- [ ] Verify icon shows in Xcode

**Status:** ⚠️ REQUIRED - Cannot submit without this

---

## 🔒 Step 2: Privacy Policy (20 min)

- [ ] Copy `privacy-policy.html` to website repo
- [ ] Deploy to `https://veloready.app/privacy` or Netlify
- [ ] Verify URL is publicly accessible
- [ ] Test URL in browser

**Status:** ⚠️ REQUIRED - TestFlight needs this URL

---

## 🔐 Step 3: OAuth Setup (20 min)

### Strava
- [ ] Go to https://www.strava.com/settings/api
- [ ] Add callback: `veloready://auth/strava/callback`
- [ ] Add callback: `https://veloready.app/auth/strava/callback`
- [ ] Note Client ID and Secret

### Intervals.icu
- [ ] Go to https://intervals.icu/settings/api
- [ ] Add redirect: `veloready://auth/intervals/callback`
- [ ] Add redirect: `https://veloready.app/auth/intervals/callback`
- [ ] Note Client ID and Secret

**Status:** ⚠️ REQUIRED - Testers need working OAuth

---

## 🏗️ Step 4: Xcode Configuration (10 min)

- [ ] Open `VeloReady.xcodeproj`
- [ ] Select VeloReady target
- [ ] Verify Bundle ID: `com.veloready.app`
- [ ] Verify Display Name: "VeloReady"
- [ ] Verify Version: 1.0
- [ ] Verify Build: 1
- [ ] Verify Team: C79WM3NZ27
- [ ] Verify HealthKit capability enabled
- [ ] Verify Associated Domains configured

---

## 🧪 Step 5: Device Testing (30 min)

- [ ] Connect iPhone to Mac
- [ ] Select iPhone in Xcode
- [ ] Build and run (⌘ + R)
- [ ] App launches successfully
- [ ] Complete onboarding flow
- [ ] Grant HealthKit permissions
- [ ] Test Strava OAuth
- [ ] Test Intervals.icu OAuth
- [ ] Navigate all tabs
- [ ] No critical crashes

**Status:** ⚠️ IMPORTANT - Test before uploading

---

## 🏪 Step 6: App Store Connect Setup (30 min)

### Create App
- [ ] Log into https://appstoreconnect.apple.com
- [ ] Apps → + → New App
- [ ] Platform: iOS
- [ ] Name: VeloReady
- [ ] Primary Language: English (U.S.)
- [ ] Bundle ID: com.veloready.app
- [ ] SKU: veloready-ios
- [ ] User Access: Full Access
- [ ] Click Create

### Configure App Information
- [ ] Category: Health & Fitness
- [ ] Secondary Category: Sports (optional)
- [ ] Complete Age Rating questionnaire (expect 4+)
- [ ] Privacy Policy URL: (your deployed URL)
- [ ] Save

### TestFlight Information
- [ ] Navigate to TestFlight tab
- [ ] Beta App Description: (brief description)
- [ ] Feedback Email: support@veloready.app
- [ ] Privacy Policy URL: (same as above)
- [ ] Beta App Review Information:
  - [ ] First Name, Last Name
  - [ ] Phone Number
  - [ ] Email Address
  - [ ] Sign-in required: Yes
  - [ ] Notes: "HealthKit permissions required"
- [ ] Save

---

## 📦 Step 7: Archive App (20 min)

- [ ] In Xcode, select "Any iOS Device (arm64)"
- [ ] Product → Clean Build Folder (⌘ + Shift + K)
- [ ] Product → Archive (or ⌘ + B with Archive scheme)
- [ ] Wait for archive to complete (2-5 minutes)
- [ ] Organizer window opens automatically

---

## ✅ Step 8: Validate & Upload (20 min)

### Validate
- [ ] In Organizer, select your archive
- [ ] Click "Validate App"
- [ ] Distribution method: App Store Connect
- [ ] Upload symbols: ✓
- [ ] Manage Version and Build Number: ✓
- [ ] Click Validate
- [ ] Wait for validation (2-3 minutes)
- [ ] Validation succeeds (no errors)

### Upload
- [ ] Click "Distribute App"
- [ ] Select App Store Connect
- [ ] Select Upload
- [ ] Upload symbols: ✓
- [ ] Manage Version and Build Number: ✓
- [ ] Review summary
- [ ] Click Upload
- [ ] Wait for upload (5-10 minutes)
- [ ] Success message appears

---

## ⏳ Step 9: Wait for Processing (30-60 min)

- [ ] Go to App Store Connect
- [ ] Apps → VeloReady → TestFlight
- [ ] Check iOS Builds section
- [ ] Status: Processing (wait 30-60 minutes)
- [ ] Check email for processing complete notification
- [ ] Status changes to "Missing Compliance"

### Complete Export Compliance
- [ ] Click on build
- [ ] Export Compliance Information
- [ ] Is your app designed to use cryptography? Yes
- [ ] Does your app contain encryption? Yes
- [ ] Is your app exempt from regulations? Yes
- [ ] Reason: Standard encryption (HTTPS only)
- [ ] Save
- [ ] Status changes to "Ready to Submit"

---

## 👥 Step 10: Create Beta Group (10 min)

### Internal Testing (Optional)
- [ ] TestFlight → Internal Testing
- [ ] Click + to create group
- [ ] Name: "Internal Team"
- [ ] Add yourself
- [ ] Enable Automatic Distribution
- [ ] Save

### External Testing (For Beta Testers)
- [ ] TestFlight → External Testing
- [ ] Click + to create group
- [ ] Name: "Private Beta Testers"
- [ ] Select your build
- [ ] Save

---

## 📧 Step 11: Invite Beta Testers (10 min)

- [ ] In External Testing group
- [ ] Click Testers → + (Add Testers)
- [ ] Select "Add New Testers"
- [ ] Enter first tester:
  - [ ] Email: _______________
  - [ ] First Name: _______________
  - [ ] Last Name: _______________
- [ ] Click Add
- [ ] Repeat for each tester:
  - [ ] Tester 2: _______________
  - [ ] Tester 3: _______________
  - [ ] Tester 4: _______________
  - [ ] Tester 5: _______________
- [ ] Select all testers
- [ ] Click "Send Invites"
- [ ] Invitations sent!

---

## 📬 Step 12: Notify Testers (10 min)

- [ ] Send welcome email to testers (use template in guide)
- [ ] Include:
  - [ ] What VeloReady is
  - [ ] How to accept TestFlight invite
  - [ ] How to report issues
  - [ ] Your contact email
- [ ] Monitor for questions

---

## 📊 Step 13: Monitor Beta (Ongoing)

### Daily Checks
- [ ] Check TestFlight dashboard
- [ ] Review installation count
- [ ] Check crash reports
- [ ] Read feedback submissions
- [ ] Respond to tester emails

### Weekly Tasks
- [ ] Collect feedback
- [ ] Prioritize bug fixes
- [ ] Plan next build
- [ ] Update testers on progress

---

## 🎉 Success Criteria

You're successful when:

- ✅ All testers receive invitations
- ✅ All testers install app
- ✅ No critical crashes reported
- ✅ OAuth flows work
- ✅ Testers provide feedback
- ✅ You can deploy updates

---

## 🚨 Emergency Contacts

**App Store Connect Issues:**
- Apple Developer Support: https://developer.apple.com/contact/

**TestFlight Problems:**
- TestFlight Help: https://developer.apple.com/testflight/

**VeloReady Issues:**
- Check: `TESTFLIGHT_DEPLOYMENT_GUIDE.md`
- Troubleshooting section has solutions

---

## 📝 Notes Section

Use this space for your notes:

**App Icon Designer:** _______________

**Privacy Policy URL:** _______________

**Strava Client ID:** _______________

**Intervals Client ID:** _______________

**First Upload Date:** _______________

**Build Number:** _______________

**Number of Testers:** _______________

**Issues Encountered:**
- 
- 
- 

**Next Steps:**
- 
- 
- 

---

## ✨ You Did It!

Once all checkboxes are complete, your beta is live! 🎉

**Next:** Monitor feedback and iterate based on tester input.

**Questions?** See `TESTFLIGHT_DEPLOYMENT_GUIDE.md` for detailed help.

---

**Good luck! 🚴‍♂️**
