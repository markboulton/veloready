# 🚀 TestFlight Deployment Guide - VeloReady Private Beta

**Last Updated:** October 15, 2025  
**Status:** Ready for Beta Testing

---

## 📋 Overview

This guide walks you through deploying VeloReady to TestFlight for private beta testing with a small group of testers using their email addresses.

**Timeline:** ~2-3 hours (including App Store Connect setup and review)

---

## ✅ Pre-Deployment Checklist

### App Configuration
- [x] Bundle ID: `com.veloready.app`
- [x] Display Name: "VeloReady"
- [x] Version: 1.0
- [x] Build Number: 1
- [x] Team ID: C79WM3NZ27
- [ ] App Icon: **REQUIRED** - Must add app icon before submission
- [ ] Privacy Policy URL: **REQUIRED** for TestFlight

### Capabilities Required
- [x] HealthKit
- [x] Associated Domains (for Universal Links)
- [x] Background Modes (remote notifications)
- [ ] iCloud (if using iCloud sync)

### OAuth Configuration
- [ ] Strava OAuth callbacks configured
- [ ] Intervals.icu OAuth callbacks configured
- [ ] Test OAuth flows on physical device

### Legal Requirements
- [ ] Privacy Policy created and hosted
- [ ] Terms of Service (optional but recommended)
- [ ] Export Compliance documentation

---

## 🎯 Step-by-Step Deployment

### Step 1: Prepare App Store Connect (30 minutes)

#### 1.1 Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **Apps** → **+** → **New App**
3. Fill in details:
   - **Platform:** iOS
   - **Name:** VeloReady
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select `com.veloready.app`
   - **SKU:** `veloready-ios` (or any unique identifier)
   - **User Access:** Full Access

#### 1.2 Configure App Information

Navigate to **App Information** section:

**Category:**
- Primary: Health & Fitness
- Secondary: Sports (optional)

**Age Rating:**
- Complete the age rating questionnaire
- Expected: 4+ (no mature content)

**Privacy Policy URL:**
- **REQUIRED:** You must host a privacy policy
- Suggested: `https://veloready.app/privacy`
- See Step 2 for privacy policy template

#### 1.3 Set Up TestFlight Information

Navigate to **TestFlight** tab:

**Beta App Information:**
- **Beta App Description:** Brief description for testers
- **Feedback Email:** Your support email
- **Marketing URL:** `https://veloready.app` (optional)
- **Privacy Policy URL:** Same as above

**Test Information:**
- **Beta App Review Information:**
  - First Name, Last Name
  - Phone Number
  - Email Address
  - Sign-in required: Yes
  - Notes: "HealthKit permissions required. OAuth setup instructions provided to testers."

**Export Compliance:**
- Uses Encryption: Yes (HTTPS)
- Exempt from regulations: Yes (standard encryption only)

---

### Step 2: Create Required Documents (20 minutes)

#### 2.1 Privacy Policy

Create a privacy policy at `https://veloready.app/privacy`. Here's a template:

```markdown
# Privacy Policy for VeloReady

**Last Updated:** October 15, 2025

## Data Collection

VeloReady collects and processes the following data:

### Health Data (via Apple HealthKit)
- Sleep data (duration, quality)
- Heart rate variability (HRV)
- Resting heart rate (RHR)
- Respiratory rate
- Active calories
- Step count

### Activity Data (via Strava & Intervals.icu)
- Cycling activities (rides, workouts)
- Power data, heart rate zones
- Training metrics (TSS, IF, NP)

## Data Storage

- All data is stored **locally on your device**
- Health data is encrypted by iOS
- OAuth tokens stored securely in iOS Keychain
- No data is sent to VeloReady servers
- No third-party analytics or tracking

## Data Sharing

- We do **not** sell or share your data
- Data is only accessed by third-party services you explicitly connect (Strava, Intervals.icu)
- You can disconnect services anytime

## Your Rights

- Delete all app data anytime via Settings
- Revoke HealthKit permissions in iOS Settings
- Disconnect OAuth services in app Settings

## Contact

Email: support@veloready.app
```

**Action:** Deploy this to your website before submitting to TestFlight.

#### 2.2 Beta Testing Instructions (for testers)

Create a document to send to beta testers:

```markdown
# VeloReady Beta Testing Instructions

Welcome to the VeloReady private beta! 🚴‍♂️

## Getting Started

1. **Accept TestFlight Invite**
   - Check your email for TestFlight invitation
   - Tap "View in TestFlight" or "Start Testing"
   - Install TestFlight app if needed

2. **Install VeloReady**
   - Open TestFlight app
   - Find VeloReady
   - Tap "Install"

3. **Grant HealthKit Permissions**
   - VeloReady requires HealthKit access
   - Grant all requested permissions for full functionality

4. **Connect Data Sources (Optional)**
   - Strava: For activity sync
   - Intervals.icu: For advanced analytics
   - Or use HealthKit-only mode

## What to Test

- **Onboarding:** Complete the welcome flow
- **Today View:** Check recovery, sleep, and load scores
- **Activities:** View your cycling activities
- **Trends:** Explore your fitness trends
- **Settings:** Test all settings and preferences

## Reporting Issues

**Via TestFlight:**
- Take screenshot of issue
- Tap "Send Beta Feedback" in TestFlight
- Describe what happened

**Via Email:**
- Send to: support@veloready.app
- Include: iOS version, device model, steps to reproduce

## Known Limitations

- Beta 1: OAuth flows require physical device (not simulator)
- Some features may be incomplete
- Performance optimizations ongoing

Thank you for testing! 🙏
```

---

### Step 3: Prepare App for Archive (15 minutes)

#### 3.1 Add App Icon

**CRITICAL:** App Store Connect requires an app icon.

1. Create app icon set (1024x1024 PNG)
2. Use a tool like [AppIconGenerator](https://appicon.co) to generate all sizes
3. Add to `VeloReady/Assets.xcassets/AppIcon.appiconset/`

**Temporary Solution:** Use a simple icon with "VR" text or cycling symbol.

#### 3.2 Update Build Settings in Xcode

1. Open `VeloReady.xcodeproj`
2. Select **VeloReady** target
3. **General** tab:
   - Display Name: `VeloReady`
   - Bundle Identifier: `com.veloready.app`
   - Version: `1.0`
   - Build: `1`

4. **Signing & Capabilities:**
   - Automatically manage signing: ✓
   - Team: Select your team (C79WM3NZ27)
   - Provisioning Profile: Automatic

5. **Build Settings:**
   - Search "bitcode"
   - Enable Bitcode: No (deprecated in Xcode 14+)

#### 3.3 Clean Build

```bash
# In Xcode
Product → Clean Build Folder (⌘ + Shift + K)
```

---

### Step 4: Archive and Upload (20 minutes)

#### 4.1 Create Archive

1. In Xcode, select **Any iOS Device (arm64)** as destination
   - Do NOT select a simulator
   - If you have a device connected, you can select it

2. **Product** → **Archive** (or ⌘ + B with Archive scheme)
   - This will take 2-5 minutes
   - Xcode will build and create an archive

3. **Organizer** window will open automatically
   - If not: **Window** → **Organizer**

#### 4.2 Validate Archive

Before uploading, validate the archive:

1. In Organizer, select your archive
2. Click **Validate App**
3. Select distribution method: **App Store Connect**
4. Select distribution options:
   - Upload symbols: ✓ (for crash reports)
   - Manage Version and Build Number: ✓
5. Click **Validate**
6. Wait for validation (2-3 minutes)

**If validation fails:**
- Check error messages carefully
- Common issues:
  - Missing app icon
  - Invalid bundle ID
  - Missing capabilities
  - Code signing issues

#### 4.3 Upload to App Store Connect

1. Click **Distribute App**
2. Select **App Store Connect**
3. Select **Upload**
4. Distribution options:
   - Upload symbols: ✓
   - Manage Version and Build Number: ✓
5. Review summary
6. Click **Upload**
7. Wait for upload (5-10 minutes depending on connection)

**Success Message:**
"Upload Successful. Your app will be processed and appear in App Store Connect shortly."

---

### Step 5: Wait for Processing (30-60 minutes)

#### 5.1 Monitor Processing Status

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. **Apps** → **VeloReady** → **TestFlight** tab
3. Check **iOS Builds** section

**Status progression:**
- ⏳ **Processing** (30-60 minutes)
- ⚠️ **Missing Compliance** (you'll need to answer export compliance)
- ✅ **Ready to Submit** or **Testing**

#### 5.2 Complete Export Compliance

Once processing completes, you'll see "Missing Compliance":

1. Click on the build
2. **Export Compliance Information**
3. Answer questions:
   - **Is your app designed to use cryptography?** Yes
   - **Does your app contain encryption?** Yes
   - **Is your app exempt from regulations?** Yes
   - **Reason:** App uses standard encryption (HTTPS only)
4. Save

**Build status will change to "Ready to Submit"**

---

### Step 6: Create Beta Test Group (10 minutes)

#### 6.1 Create Internal Testing Group (Optional)

For your own testing first:

1. **TestFlight** → **Internal Testing**
2. Click **+** to create group
3. Name: "Internal Team"
4. Add yourself and any team members
5. Enable **Automatic Distribution** (new builds auto-deploy)
6. Save

#### 6.2 Create External Testing Group

For your beta testers:

1. **TestFlight** → **External Testing**
2. Click **+** to create group
3. Name: "Private Beta Testers"
4. **Build:** Select your uploaded build
5. **Testers:** We'll add them next
6. **Beta App Review:** Not needed for first 100 external testers
7. Save

---

### Step 7: Invite Beta Testers (10 minutes)

#### 7.1 Add Testers by Email

1. In your External Testing group
2. Click **Testers** → **+** (Add Testers)
3. Select **Add New Testers**
4. Enter tester information:
   - **Email:** Tester's email address
   - **First Name:** (optional)
   - **Last Name:** (optional)
5. Click **Add**
6. Repeat for each tester

**Limits:**
- Up to 10,000 external testers total
- Up to 100 testers before requiring Beta App Review
- First 100 testers get instant access

#### 7.2 Send Invitations

1. Select all testers you just added
2. Click **Send Invites**
3. Testers will receive email with TestFlight link

**Email will contain:**
- Link to install TestFlight (if needed)
- Link to install VeloReady
- Redemption code (if applicable)

---

### Step 8: Monitor Beta Testing (Ongoing)

#### 8.1 Track Installations

**TestFlight Dashboard shows:**
- Number of invites sent
- Number of testers who installed
- Number of active sessions
- Crash reports
- Feedback submissions

#### 8.2 Collect Feedback

**Testers can provide feedback via:**
1. **Screenshot Feedback:**
   - Shake device while in app
   - TestFlight captures screenshot
   - Tester adds comments

2. **Crash Reports:**
   - Automatic if tester opts in
   - View in App Store Connect → TestFlight → Crashes

3. **Email:**
   - Direct feedback to your support email

#### 8.3 Release Updates

When you fix bugs or add features:

1. Increment build number in Xcode (e.g., 1 → 2)
2. Archive and upload (Steps 4.1-4.3)
3. Wait for processing
4. Build auto-distributes to testers (if enabled)
5. Testers get notification to update

---

## 🚨 Troubleshooting

### Archive Fails

**"No signing certificate found"**
- Solution: Xcode → Settings → Accounts → Download Manual Profiles
- Or: Enable "Automatically manage signing"

**"Missing required icon file"**
- Solution: Add app icon to Assets.xcassets

**"Invalid bundle identifier"**
- Solution: Verify bundle ID matches App Store Connect

### Upload Fails

**"Invalid Provisioning Profile"**
- Solution: Regenerate provisioning profile in Developer Portal
- Or: Clean build and try again

**"Asset validation failed"**
- Solution: Check error details, usually missing icon sizes

### Processing Stuck

**Build stuck in "Processing" for >2 hours**
- Solution: Contact Apple Developer Support
- Or: Upload a new build with incremented build number

### Testers Can't Install

**"This beta is full"**
- Solution: You've hit 100 tester limit, need Beta App Review

**"Invitation expired"**
- Solution: Resend invitation from TestFlight

**"App not available in your region"**
- Solution: Check app availability settings in App Store Connect

---

## 📝 Pre-Flight Checklist

Before inviting testers, verify:

- [ ] App icon added and looks good
- [ ] Privacy policy live at URL
- [ ] OAuth services configured (Strava, Intervals.icu)
- [ ] HealthKit permissions tested on device
- [ ] App builds and runs on physical device
- [ ] No critical bugs or crashes
- [ ] Onboarding flow complete
- [ ] All user-facing text says "VeloReady"
- [ ] Beta testing instructions prepared
- [ ] Support email monitored

---

## 🎯 Quick Command Reference

### Archive App
```bash
# In Xcode
1. Select "Any iOS Device (arm64)"
2. Product → Archive (⌘ + B)
3. Wait for Organizer to open
```

### Increment Build Number
```bash
# In Xcode
1. Select VeloReady target
2. General → Build: increment number
3. Or use agvtool:
xcrun agvtool next-version -all
```

### Check Archive Status
```bash
# View all archives
open ~/Library/Developer/Xcode/Archives/
```

---

## 📧 Email Template for Beta Testers

```
Subject: You're invited to test VeloReady! 🚴‍♂️

Hi [Name],

You're invited to join the private beta for VeloReady, a smart cycling analytics app for iOS!

**What is VeloReady?**
VeloReady helps cyclists optimize training with:
- Daily recovery scores (HRV, RHR, sleep)
- Training load management
- Activity analytics with power zones
- Strava & Intervals.icu integration

**How to Get Started:**

1. Accept the TestFlight invitation (separate email)
2. Install TestFlight if you don't have it
3. Install VeloReady from TestFlight
4. Grant HealthKit permissions
5. Start testing!

**What I Need from You:**

- Test the app for 1-2 weeks
- Report any bugs or issues
- Share feedback on features and UX
- Let me know what you love and what needs work

**Reporting Issues:**

- Via TestFlight: Shake device → Send Beta Feedback
- Via Email: support@veloready.app

**Requirements:**

- iPhone running iOS 17.0 or later
- Apple Health app with some health data
- (Optional) Strava or Intervals.icu account

Thank you for being an early tester! Your feedback will help shape VeloReady.

Cheers,
[Your Name]

---

Questions? Reply to this email or reach out at support@veloready.app
```

---

## 🎉 Success Criteria

Your beta is successful when:

- ✅ All invited testers receive and accept invitations
- ✅ Testers successfully install and launch app
- ✅ No critical crashes reported
- ✅ HealthKit permissions work correctly
- ✅ OAuth flows work on physical devices
- ✅ Testers provide meaningful feedback
- ✅ You can deploy updates smoothly

---

## 📚 Additional Resources

### Apple Documentation
- [TestFlight Overview](https://developer.apple.com/testflight/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Beta Testing Guide](https://developer.apple.com/testflight/testers/)

### VeloReady Documentation
- `PRE_LAUNCH_CHECKLIST.md` - Pre-deployment checklist
- `SETUP_INSTRUCTIONS.md` - Development setup
- `README.md` - Project overview

### Support
- **App Store Connect:** https://appstoreconnect.apple.com
- **Developer Portal:** https://developer.apple.com/account
- **TestFlight:** https://testflight.apple.com

---

## 🚀 Next Steps After Beta

Once beta testing is complete:

1. **Incorporate Feedback**
   - Fix reported bugs
   - Improve UX based on feedback
   - Add requested features (if feasible)

2. **Prepare for App Store**
   - Create app screenshots (required)
   - Write app description
   - Prepare promotional text
   - Record app preview video (optional)

3. **Submit for Review**
   - Complete all App Store metadata
   - Submit for App Review
   - Respond to any review feedback
   - Launch! 🎉

---

**Good luck with your beta! 🚴‍♂️**

**Questions?** Check the troubleshooting section or contact Apple Developer Support.
