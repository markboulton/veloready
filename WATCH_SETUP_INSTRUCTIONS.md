# 🎯 Apple Watch Setup Instructions

## What We Built

### 1. **WatchConnectivityManager** ✅
- Syncs recovery score to watch
- Syncs HRV/RHR data
- Requests health data FROM watch (preferred source)
- Queues data when watch not reachable

### 2. **Recovery Score Widget/Complication** ✅
- Shows on watch face
- Shows on iPhone home screen
- Updates every hour
- Color-coded by score
- Shows sparkles ✨ when ML is used

---

## Setup Steps

### Step 1: Configure App Group (Required)

The widget needs to share data with the main app via an App Group.

1. **Open Xcode**
2. **Select VeloReady target**
3. **Go to Signing & Capabilities**
4. **Click "+ Capability"**
5. **Add "App Groups"**
6. **Click "+" and create:**
   ```
   group.com.markboulton.VeloReady
   ```

7. **Repeat for VeloReadyWidget target:**
   - Select **VeloReadyWidget** target (not RideReadyWidget - we renamed it)
   - Add "App Groups" capability
   - Enable the same group: `group.com.markboulton.VeloReady`

### Step 2: Test Widget on iPhone

1. **Build and run** the app on your iPhone
2. **Long press** on home screen
3. **Tap "+" button** (top left)
4. **Search for "VeloReady"**
5. **Add the widget** to your home screen
6. **Open the app** to calculate recovery score
7. **Wait ~1 minute** for widget to update

**Expected Result:**
- Widget shows your recovery score
- Shows band (Optimal/Good/Fair/Pay Attention)
- Color-coded (green/yellow/orange/red)
- If ML enabled: shows sparkles ✨

### Step 3: Test Watch Complications (If you have Apple Watch)

1. **Pair your Apple Watch** with iPhone
2. **Open Watch app** on iPhone
3. **Go to Face Gallery**
4. **Choose a watch face** that supports complications
5. **Tap "Add"** then **"Customize"**
6. **Tap a complication slot**
7. **Scroll to find "VeloReady"**
8. **Select it**

**Complication Types:**
- **Circular**: Gauge with score in center
- **Rectangular**: Score + band + sparkles
- **Inline**: Text only ("Recovery: 75")

### Step 4: Enable Watch Connectivity (Optional - for future)

The WatchConnectivityManager is ready, but you'll need a Watch app target to fully utilize it.

**To add Watch app:**
1. File → New → Target
2. Choose "Watch App"
3. Name it "VeloReady Watch"
4. Add WatchConnectivity framework
5. Implement watch-side sync

**For now:** The widget/complication works without a full Watch app!

---

## How It Works

### Data Flow:

```
iPhone App
    ↓
RecoveryScoreService calculates score
    ↓
Saves to:
  1. UserDefaults (app cache)
  2. Shared UserDefaults (App Group) ← Widget reads this
  3. WatchConnectivityManager (for Watch app)
    ↓
Widget/Complication updates every hour
```

### Widget Update Frequency:

- **Automatic**: Every 1 hour
- **Manual**: Pull down to refresh widget
- **On app open**: Immediate update

---

## Testing Checklist

### iPhone Widget:
- [ ] Widget shows recovery score
- [ ] Widget shows correct band
- [ ] Widget shows correct color
- [ ] Widget shows sparkles when ML enabled
- [ ] Widget updates after opening app

### Watch Complication (if applicable):
- [ ] Complication appears in Face Gallery
- [ ] Complication shows recovery score
- [ ] Complication updates hourly
- [ ] Tapping complication opens app (future)

### Watch Connectivity (future):
- [ ] Recovery score syncs to watch
- [ ] HRV/RHR data syncs to watch
- [ ] Watch data preferred over iPhone

---

## Troubleshooting

### Widget shows "--" or "No Data"

**Cause:** App Group not configured or no recovery score calculated

**Fix:**
1. Verify App Group is configured in BOTH targets
2. Open main app and wait for recovery score to calculate
3. Force quit widget (swipe up in app switcher)
4. Re-add widget to home screen

### Widget not updating

**Cause:** iOS widget timeline not refreshing

**Fix:**
1. Remove widget from home screen
2. Force quit main app
3. Reopen main app
4. Wait for recovery score to calculate
5. Re-add widget

### Complication not appearing

**Cause:** Widget extension not installed on watch

**Fix:**
1. Open Watch app on iPhone
2. Go to "My Watch" → "General" → "Software Update"
3. Ensure watch OS is up to date
4. Reinstall app on iPhone
5. Wait for automatic sync to watch

### "group.com.markboulton.VeloReady" error

**Cause:** App Group not registered with Apple

**Fix:**
1. Go to developer.apple.com
2. Certificates, Identifiers & Profiles
3. Identifiers → App Groups
4. Register the group ID
5. Regenerate provisioning profiles
6. Re-download in Xcode

---

## What's Next (Future Enhancements)

### Week 3 Remaining:
- [ ] Add full Watch app target
- [ ] Implement watch-side UI
- [ ] Prefer Watch HRV/RHR data over iPhone
- [ ] Add watch workout integration
- [ ] Test on physical watch

### Future Features:
- [ ] Tap complication to open app
- [ ] Watch-side recovery calculation
- [ ] Live Activity for workouts
- [ ] Watch notifications
- [ ] Haptic feedback for low recovery

---

## Current Status

**✅ Implemented:**
- WatchConnectivityManager (iPhone side)
- Widget/Complication views (all sizes)
- Shared data via App Group
- Automatic sync on score calculation
- Color-coded UI
- Personalization indicator (sparkles)

**⏸️ Pending:**
- App Group configuration in Xcode
- Watch app target (optional)
- Physical watch testing

**🎯 Ready to Test:**
- iPhone widget (after App Group setup)
- Watch complications (after App Group setup)

---

## Summary

You now have:
1. ✅ **Widget** showing recovery score on iPhone home screen
2. ✅ **Complications** for Apple Watch faces
3. ✅ **Watch sync** infrastructure ready
4. ⏸️ **App Group** needs configuration in Xcode

**Next:** Configure App Group in Xcode, then test the widget!

---

## Quick Start

**Fastest way to see it working:**

1. Open Xcode
2. Add App Groups capability to both targets
3. Build and run on iPhone
4. Open app, wait for recovery score
5. Add widget to home screen
6. See your recovery score! 🎉

**Time to complete:** ~5 minutes
