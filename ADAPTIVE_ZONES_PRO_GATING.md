# Adaptive Zones - PRO Feature Gating

**Date:** October 16, 2025  
**Feature:** Adaptive FTP/HR/Power Zones are now PRO-only

---

## 🎯 **Business Model**

### **FREE Tier (No Subscription)**

**What FREE users GET:**
- ✅ **Manual FTP input** - Set your FTP in Settings → Athlete Zones
- ✅ **Manual Max HR input** - Set your max HR in Settings → Athlete Zones
- ✅ **Strava FTP fallback** - If connected, uses Strava's stored FTP
- ✅ **Intervals.icu FTP fallback** - If connected, uses Intervals.icu's stored FTP
- ✅ **Coggan default zones** - Static zones based on FTP/Max HR (industry standard)
- ✅ **Manual zone editing** - Edit zones directly in Settings
- ✅ **Full UI access** - All charts, TSS, Intensity, etc.

**What FREE users DON'T GET:**
- ❌ **Adaptive FTP computation** - No automatic FTP calculation from performance
- ❌ **Adaptive power zones** - No performance-based zone computation
- ❌ **Adaptive HR zones** - No performance-based HR zone computation

### **PRO Tier (VeloReady+ Subscription)**

**Everything FREE has, PLUS:**
- ✅ **Adaptive FTP** - Computed from 120 days of power data
- ✅ **Adaptive power zones** - Zones computed from actual performance distribution
- ✅ **Adaptive HR zones** - HR zones computed from lactate threshold detection
- ✅ **Extended data window** - 120 days vs 90 days for FREE
- ✅ **Automatic updates** - Zones update as fitness changes
- ✅ **Higher accuracy** - Uses Critical Power model, power duration curve analysis

---

## 📊 **How It Works**

### **FREE User Flow:**

1. **User downloads app** (FREE tier)
2. **Connects to Strava or Intervals.icu** (optional)
   - If Strava: FTP fetched from Strava athlete profile
   - If Intervals.icu: FTP fetched from Intervals.icu profile
3. **Or sets FTP manually** in Settings → Athlete Zones
4. **App generates Coggan default zones** from FTP/Max HR
5. **User can edit zones** if they prefer custom values

**Example:**
```
User sets FTP = 220W (manual)
→ App generates 7 Coggan power zones:
  Zone 1: 0-121W (Active Recovery)
  Zone 2: 121-159W (Endurance)
  Zone 3: 159-187W (Tempo)
  Zone 4: 187-214W (Lactate Threshold)
  Zone 5: 214-242W (VO2 Max)
  Zone 6: 242-275W (Anaerobic)
  Zone 7: 275W+ (Neuromuscular)
```

### **PRO User Flow:**

1. **User upgrades to PRO**
2. **App fetches 120 days of activities** with power data
3. **Adaptive FTP computation runs:**
   - Analyzes power-duration curve
   - Finds 60-min, 20-min, 5-min best efforts
   - Computes weighted FTP with confidence buffer
   - Example: FTP = 212W (from performance data)
4. **Adaptive zones generated** from actual performance distribution
5. **Zones update automatically** as fitness changes

**Example:**
```
App analyzes 120 days of rides
→ Best 60-min: 220W
→ Best 20-min: 216W
→ Best 5-min: 216W
→ Weighted FTP: 208W
→ With buffer: 212W
→ Generates adaptive zones based on performance
```

---

## 🔧 **Technical Implementation**

### **Feature Gates (ProFeatureConfig.swift)**

```swift
// MARK: - Adaptive Zone Features (PRO Only)

/// Can compute FTP from performance data (PRO feature)
/// FREE users must use manual FTP or Strava/Intervals.icu FTP
var canUseAdaptiveFTP: Bool { hasProAccess }

/// Can compute power zones from performance data (PRO feature)
/// FREE users get Coggan default zones based on FTP
var canUseAdaptivePowerZones: Bool { hasProAccess }

/// Can compute HR zones from performance data (PRO feature)
/// FREE users get Coggan default zones based on Max HR
var canUseAdaptiveHRZones: Bool { hasProAccess }
```

### **Gated Computation (AthleteProfile.swift)**

```swift
// Check PRO access for adaptive zone computation
let proConfig = await MainActor.run { ProFeatureConfig.shared }

// Only update if source is NOT manual (don't override user settings)
if profile.ftpSource != .manual {
    if await proConfig.canUseAdaptiveFTP {
        await computeFTPFromPerformanceData(recentActivities)
    } else {
        Logger.data("🔒 Adaptive FTP computation requires PRO - FREE users use manual/Strava/Intervals.icu FTP")
    }
}

// FREE users still get Coggan default zones
if (profile.powerZones == nil || profile.powerZones!.isEmpty), let ftp = profile.ftp, ftp > 0 {
    profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: ftp)
    let zoneType = canUseAdaptivePower ? "adaptive" : "Coggan default"
    Logger.data("✅ Generated \(zoneType) power zones from FTP: \(Int(ftp))W")
}
```

### **Logging**

**FREE user logs:**
```
🔒 Adaptive FTP computation requires PRO - FREE users use manual/Strava/Intervals.icu FTP
✅ Generated Coggan default power zones from FTP: 220W
✅ Generated Coggan default HR zones from max HR: 180bpm
```

**PRO user logs:**
```
📊 STAGE 1: Building Power-Duration Curve
📊 Analyzing 36 activities...
📊 Weighted FTP: 208W
📊 Buffered FTP: 212W
✅ Generated adaptive power zones from FTP: 212W
✅ Generated adaptive HR zones from max HR: 177bpm
```

---

## 🎨 **UI Considerations**

### **Settings → Athlete Zones**

**For FREE users:**
- Show **"Set FTP"** button prominently
- Show **current FTP** (manual, Strava, or Intervals.icu)
- Show **Coggan default zones**
- Show **"Upgrade to PRO for adaptive zones"** badge/hint

**For PRO users:**
- Show **computed FTP** with confidence score
- Show **adaptive zones** with data quality indicator
- Show **"Recompute from performance"** button
- Show **last updated** timestamp

### **Upgrade Prompts**

**When to show:**
- Settings → Athlete Zones (subtle badge)
- When user taps zone charts (optional)
- When user manually sets FTP (optional)

**Message:**
```
🚀 Upgrade to PRO for Adaptive Zones

Get automatically computed FTP and zones from your actual performance data.

• Adaptive FTP from 120 days of rides
• Performance-based power zones
• Lactate threshold HR zones
• Updates as your fitness changes

[Upgrade to PRO] [Maybe Later]
```

---

## 📋 **Testing Checklist**

### **Test as FREE User:**

1. **New user flow:**
   - [ ] App doesn't compute adaptive FTP
   - [ ] User can set manual FTP in Settings
   - [ ] Coggan zones generated from manual FTP
   - [ ] Logs show "🔒 Adaptive FTP computation requires PRO"

2. **Strava-only user:**
   - [ ] FTP fetched from Strava
   - [ ] Coggan zones generated from Strava FTP
   - [ ] No adaptive computation runs

3. **Intervals.icu user:**
   - [ ] FTP fetched from Intervals.icu
   - [ ] Coggan zones generated from Intervals.icu FTP
   - [ ] No adaptive computation runs

4. **Manual editing:**
   - [ ] User can edit FTP in Settings
   - [ ] Zones regenerate from new FTP
   - [ ] TSS/Intensity calculations work

### **Test as PRO User:**

1. **Upgrade flow:**
   - [ ] User upgrades to PRO
   - [ ] Adaptive FTP computation runs
   - [ ] Adaptive zones generated
   - [ ] Logs show performance analysis

2. **Automatic updates:**
   - [ ] New activities added
   - [ ] Zones recompute on refresh
   - [ ] FTP updates if performance changes

3. **Manual override:**
   - [ ] PRO user can still set manual FTP
   - [ ] Manual override disables adaptive computation
   - [ ] Can reset to adaptive later

### **Test PRO → FREE Downgrade:**

1. **User downgrades:**
   - [ ] Keeps existing FTP (doesn't lose it)
   - [ ] Keeps existing zones
   - [ ] Adaptive computation stops running
   - [ ] Can still edit manually

---

## 🔐 **Security & Revenue Protection**

### **Server-Side Validation**

**For future API-based features:**
- AI briefs should validate PRO status server-side
- Any zone-based analytics should check subscription
- Don't trust client-side `hasProAccess` flag alone

### **Client-Side Enforcement**

**Current implementation:**
- ProFeatureConfig checks subscription state
- AthleteProfile respects `canUseAdaptiveFTP` flag
- UI shows upgrade prompts appropriately

---

## 📝 **Summary**

**FREE users get:**
- Manual FTP + Coggan zones ✅
- Strava/Intervals.icu FTP fallback ✅
- Full UI access ✅
- Great experience for casual users ✅

**PRO users get:**
- Everything FREE has ✅
- Adaptive FTP from performance ✅
- Adaptive zones from performance ✅
- Automatic updates ✅
- Worth the upgrade for serious athletes ✅

---

## ✅ **Status**

- [x] Feature gates added to ProFeatureConfig
- [x] Adaptive computation gated in AthleteProfile
- [x] FREE users get Coggan defaults
- [x] PRO users get adaptive zones
- [x] Logging indicates tier clearly
- [x] Build passing
- [x] Ready for testing

---

## 🚀 **Next Steps**

1. **Test as FREE user** - Verify no adaptive computation
2. **Test as PRO user** - Verify adaptive zones work
3. **Add UI badges** - Subtle PRO indicators in Settings
4. **Add upgrade prompts** - Non-intrusive upgrade messaging
5. **Document for users** - In-app help text explaining difference
