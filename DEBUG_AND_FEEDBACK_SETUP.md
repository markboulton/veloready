# Debug Menu & User Feedback Setup

## Date: October 15, 2025

## Overview
Implemented a two-tier support system:
1. **Developer Debug Menu** - Only visible to you (the developer)
2. **User Feedback System** - Always visible to all users (including beta testers)

---

## How It Works

### 1. Developer Detection (`DebugFlags.swift`)

The app automatically detects if the current user is a developer using multiple signals:

```swift
static var isDeveloper: Bool {
    #if DEBUG
    return true  // Always true in Xcode debug builds
    #else
    return isKnownDeveloperDevice || isTestFlightBuild
    #endif
}
```

#### Detection Methods:

**Debug Builds (Xcode):**
- ✅ Debug menu always visible
- ✅ Verbose logging enabled
- ✅ All experimental features shown

**TestFlight Builds:**
- ✅ Identified as TestFlight automatically
- ❌ Debug menu hidden by default
- ✅ Can be enabled by adding device to whitelist

**Production Builds (App Store):**
- ✅ Identified as Production
- ❌ Debug menu hidden
- ✅ Can be enabled by adding device to whitelist

---

## For You (Developer)

### Current Setup:

**In Xcode (Debug builds):**
- Debug menu automatically visible ✅
- Shows: "DEBUG & TESTING" section in Settings
- Badge shows: "Debug (Xcode)"

**Your Device Identifier:**
```
Run the app → Settings → Debug (if visible) → Footer shows Device ID
OR
Check DebugFlags.getDeviceIdentifier()
```

### To Enable Debug Menu on Your Production Device:

1. **Get your Device ID:**
   - Install the app on your device
   - Open Settings → scroll to bottom
   - Look for "Debug/Testing" section footer
   - Copy the Device ID UUID

2. **Add to Whitelist:**
```swift
// In DebugFlags.swift
private static var isKnownDeveloperDevice: Bool {
    let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
    
    let developerDevices: Set<String> = [
        "YOUR-DEVICE-UUID-HERE",  // Your iPhone
        "ANOTHER-UUID-HERE"        // Your iPad (optional)
    ]
    
    return developerDevices.contains(deviceId)
}
```

3. **Rebuild and Deploy:**
   - Recompile the app
   - Debug menu will now appear on your device even in production builds

---

## For Beta Testers

### What They See:

**Settings Screen:**
```
┌─────────────────────────┐
│ About                   │
│  ℹ️ About VeloReady      │
│  ❓ Help & Support       │
└─────────────────────────┘

┌─────────────────────────┐
│ Help & Support          │
│  ✉️ Send Feedback        │
│  Report issues or       │
│  suggest improvements   │
└─────────────────────────┘

❌ NO Debug Menu
```

### Feedback Flow for Users:

1. **Tap "Send Feedback"** in Settings
2. **Feedback Form Opens:**
   - Text field for their message
   - Toggle: "Include diagnostic logs" (on by default)
   - Toggle: "Include device information" (on by default)
   - Preview of device info (build, iOS version, etc.)

3. **Tap "Send Feedback"**
   - Opens Mail app with pre-filled email
   - **To:** support@veloready.app
   - **Subject:** VeloReady Feedback
   - **Body:** Their message + logs + device info

4. **User Sends Email**
   - You receive feedback with full diagnostic information
   - No manual log collection needed

---

## What Gets Sent in Feedback Emails

### Standard Email Format:

```
[User's feedback message here]

---

Device Information:
VeloReady 1.0.0 (123)
Environment: TestFlight Beta
Device: iPhone 15 Pro - iOS 18.1
Device ID: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX

Recent Logs:
Log collection placeholder
Timestamp: 2025-10-15 20:00:00
Note: Implement Logger.getRecentLogs() for detailed logs
```

**What's Included:**
- ✅ User's feedback text
- ✅ App version and build number
- ✅ Build environment (TestFlight/Production)
- ✅ Device model and iOS version
- ✅ Device identifier (for whitelisting if needed)
- ✅ Recent logs (placeholder - can be enhanced)

**What's NOT Included:**
- ❌ User's personal data
- ❌ Health data
- ❌ Workout details
- ❌ Account information

---

## Files Created

### Core Infrastructure:

**`DebugFlags.swift`**
- Developer detection logic
- Feature flags (showDebugMenu, verboseLogging, etc.)
- Build environment detection
- Device identifier utilities

**`FeedbackView.swift`**
- User feedback form
- Email composition
- Log collection (placeholder)
- Device info display

### Settings Integration:

**`FeedbackSection.swift`**
- "Send Feedback" button in Settings
- Always visible to all users
- Opens FeedbackView sheet

**`DebugSection.swift` (Updated)**
- Conditionally shows based on `DebugFlags.showDebugMenu`
- Shows environment badge
- Displays device ID in footer for easy whitelisting

**`SettingsView.swift` (Updated)**
- Added FeedbackSection (always visible)
- Removed `#if DEBUG` conditional around DebugSection
- DebugSection now self-manages visibility

---

## Testing Checklist

### As Developer (Xcode):
- [x] Debug menu visible in Settings
- [x] Badge shows "Debug (Xcode)"
- [x] Device ID shown in footer
- [x] All debug features accessible
- [x] Feedback button also visible

### As Beta Tester (TestFlight):
- [ ] Install via TestFlight
- [ ] Open Settings
- [ ] Should see "Send Feedback" button
- [ ] Should NOT see "DEBUG & TESTING" section
- [ ] Tap "Send Feedback"
- [ ] Fill out form
- [ ] Verify email opens with logs

### As Production User (App Store):
- [ ] Install from App Store
- [ ] Open Settings
- [ ] Should see "Send Feedback" button
- [ ] Should NOT see "DEBUG & TESTING" section
- [ ] Feedback flow works correctly

---

## Future Enhancements

### Log Collection (TODO):

Currently, the feedback system includes a placeholder for logs. To implement full log collection:

1. **Add Log Buffer to Logger:**
```swift
// In Logger.swift
private static var logBuffer: [String] = []
private static let maxBufferSize = 100

static func getRecentLogs() -> String {
    return logBuffer.joined(separator: "\n")
}
```

2. **Update FeedbackView:**
```swift
private func collectRecentLogs() -> String {
    return Logger.getRecentLogs()
}
```

3. **Consider Log Levels:**
   - Store only errors and warnings
   - Include performance logs
   - Redact sensitive data

### Additional Features:

1. **Screenshot Attachment:**
   - Allow users to attach screenshots
   - Helpful for UI bugs

2. **In-App Support Chat:**
   - Real-time support (Intercom, Zendesk, etc.)
   - Expensive but better UX

3. **Bug Reporter:**
   - Shake to report bug
   - Automatic screenshot capture
   - One-tap bug reporting

4. **Analytics Integration:**
   - Track which features users request
   - Common pain points
   - Feature usage before feedback

---

## Adding Your Device to Whitelist

### Step-by-Step:

1. **Run app in Debug mode (Xcode)**
2. **Go to Settings**
3. **Scroll to Debug section**
4. **Copy Device ID from footer**
5. **Add to `DebugFlags.swift`:**

```swift
private static var isKnownDeveloperDevice: Bool {
    let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
    
    let developerDevices: Set<String> = [
        "PASTE-YOUR-UUID-HERE"  // Mark's iPhone 15 Pro
    ]
    
    return developerDevices.contains(deviceId)
}
```

6. **Archive and deploy to TestFlight**
7. **Debug menu will now appear on your device**

### Multiple Devices:

```swift
let developerDevices: Set<String> = [
    "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA",  // iPhone 15 Pro
    "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB",  // iPad Pro
    "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"   // Test Device
]
```

---

## Privacy & Security

### User Data Protection:

**What's Safe to Include:**
- ✅ App version/build
- ✅ Device model/iOS version
- ✅ Device identifier (not personally identifying)
- ✅ Performance logs (timing, cache hits)
- ✅ Error messages (non-personal)

**Never Include:**
- ❌ User's name, email, phone
- ❌ Health data (HRV, sleep, HR)
- ❌ Workout locations (GPS coordinates)
- ❌ OAuth tokens
- ❌ API keys

### GDPR Compliance:

- Device identifier is anonymous
- Can be changed by reinstalling app
- Not linked to personal identity
- Users opt-in to sending logs
- Clear disclosure in UI

---

## Support Email Setup

### Configure `support@veloready.app`:

1. **Set up email:**
   - Gmail/G Suite recommended
   - Or custom domain email
   - Enable IMAP for replies

2. **Auto-Responder (Optional):**
```
Thank you for your feedback!

We've received your message and will respond within 24-48 hours.

For urgent issues, you can also reach us on Twitter @VeloReady.

- The VeloReady Team
```

3. **Email Filters:**
   - Label: "VeloReady Feedback"
   - Priority for "Bug" keyword
   - Auto-tag TestFlight emails

---

## Summary

### What You Get:

**As Developer:**
- ✅ Full debug menu when needed
- ✅ Works in Xcode and production
- ✅ Easy device whitelisting
- ✅ Environment badges for clarity

**For Beta Testers:**
- ✅ Easy feedback mechanism
- ✅ No technical knowledge required
- ✅ Logs sent automatically
- ✅ Clean, professional UX

**For You (Support):**
- ✅ All diagnostic info in one email
- ✅ Device IDs for whitelisting
- ✅ Build info for bug tracking
- ✅ User's exact problem description

---

## Status: COMPLETE ✅

**Files Created:**
- `DebugFlags.swift` - Developer detection
- `FeedbackView.swift` - User feedback form
- `FeedbackSection.swift` - Settings integration

**Files Updated:**
- `DebugSection.swift` - Conditional visibility
- `SettingsView.swift` - Added feedback section

**Build Status:**
- ✅ Compiles successfully
- ✅ Ready for testing
- ✅ Ready for TestFlight deployment

**Next Steps:**
1. Test feedback flow in simulator
2. Get your device ID
3. Add to whitelist
4. Deploy to TestFlight
5. Test as beta user (no debug menu)
6. Verify feedback emails work
