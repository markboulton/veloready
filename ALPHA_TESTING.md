# Alpha Testing Guide

## Build Configurations

You need **three** distinct build types:

### 1. Developer (Debug Configuration)
**For:** Internal development and testing
- **Alpha Testing menu** ✅ visible
- **Full Debug menu** ✅ visible (when `DebugFlags.showDebugMenu = true`)
- File logging available
- All testing features enabled
- Mock data toggles
- API inspectors

### 2. Alpha (Debug Configuration)
**For:** TestFlight alpha testers
- **Alpha Testing menu** ✅ visible (simplified)
- **Full Debug menu** ❌ hidden (unless developer device)
- File logging available
- Pro feature testing
- Cache management
- No overwhelming technical options

### 3. Production (Release Configuration)
**For:** App Store public release
- **No debug menus** ❌ completely excluded via `#if DEBUG`
- No alpha testing options
- No debug settings
- Smaller binary size
- Zero runtime overhead

## Files Excluded from Production

The following files are wrapped in `#if DEBUG` and will NOT be compiled into App Store builds:

1. **AlphaTesterSettingsView.swift** - Simplified alpha tester menu
2. **DebugSettingsView.swift** - Full developer debug menu
3. **DebugSection.swift** - Settings section that shows both menus

## How to Build in Xcode

### Step 1: Edit Your Scheme
1. In Xcode, click on the scheme dropdown (next to the device selector)
2. Select **"Edit Scheme..."**
3. You'll configure different actions for different builds

### Step 2: Configure for Developer Builds
**For:** Your local development and testing

1. In Edit Scheme, select **"Run"** from left sidebar
2. Set **Build Configuration** to **Debug**
3. ✅ This gives you full debug menu access

### Step 3: Configure for Alpha Builds (TestFlight)
**For:** Alpha testers via TestFlight

1. In Edit Scheme, select **"Archive"** from left sidebar
2. Set **Build Configuration** to **Debug**
3. ✅ This gives alpha testers the simplified menu
4. ❌ They won't see full debug menu (unless their device is in `DebugFlags`)

**To upload to TestFlight:**
1. Product → Archive (⌘⇧B then Archive)
2. Organizer opens → Select your archive
3. Click **"Distribute App"**
4. Choose **"TestFlight & App Store"**
5. Follow prompts to upload

### Step 4: Configure for Production Builds (App Store)
**For:** Public App Store release

1. In Edit Scheme, select **"Archive"** from left sidebar
2. Set **Build Configuration** to **Release**
3. ❌ No debug menus at all - completely excluded
4. ✅ Optimized, smaller binary

**To submit to App Store:**
1. Product → Archive (with Release configuration)
2. Organizer opens → Select your archive
3. Click **"Distribute App"**
4. Choose **"App Store Connect"**
5. Follow prompts to submit for review

---

## Quick Reference: Xcode Configurations

| Build Type | Scheme Action | Configuration | Debug Menus | Use Case |
|------------|---------------|---------------|-------------|----------|
| **Developer** | Run | Debug | Full access | Local development |
| **Alpha** | Archive | Debug | Simplified | TestFlight testers |
| **Production** | Archive | Release | None | App Store |

---

## Terminal Commands (Alternative)

If you prefer terminal builds:

### For Developer Testing
```bash
xcodebuild -configuration Debug -scheme VeloReady build
```

### For Alpha Testers (TestFlight)
```bash
xcodebuild -configuration Debug -scheme VeloReady archive \
  -archivePath ./build/VeloReady-Alpha.xcarchive
```

### For App Store (Production)
```bash
xcodebuild -configuration Release -scheme VeloReady archive \
  -archivePath ./build/VeloReady-Production.xcarchive
```

## Visual Guide: What Each Build Shows

### Developer Build (Debug + DebugFlags.showDebugMenu = true)
```
Settings
└── Developer
    ├── Alpha Testing (ALPHA badge)
    │   ├── Debug Logging
    │   ├── Pro Features Testing
    │   ├── Cache Management
    │   └── Feedback Instructions
    └── Debug (DEV badge)
        ├── Monitoring Dashboards
        ├── API Debug Inspector
        ├── Pro Toggle
        ├── Mock Data Toggles
        ├── Cache Management
        ├── AI Brief Testing
        ├── OAuth Management
        └── ... (all technical tools)
```

### Alpha Build (Debug, TestFlight)
```
Settings
└── Testing
    └── Alpha Testing (ALPHA badge)
        ├── Debug Logging
        ├── Pro Features Testing
        ├── Cache Management
        └── Feedback Instructions
```

### Production Build (Release, App Store)
```
Settings
└── (No debug/testing sections at all)
```

---

## Developer Access Control

### Alpha Testers (Default)
- See: **Alpha Testing** menu only
- Can: Enable logging, test Pro features, clear cache
- Cannot: Access technical debug tools

### Developers (Special Access)
To see the full debug menu, add your device to `DebugFlags.swift`:

**Location:** `/Core/Config/DebugFlags.swift`

```swift
static var showDebugMenu: Bool {
    #if DEBUG
    let deviceID = getDeviceIdentifier()
    let developerDevices = [
        "YOUR-DEVICE-ID-HERE",  // Add your device
        "ANOTHER-DEVICE-ID"
    ]
    return developerDevices.contains(deviceID)
    #else
    return false
    #endif
}
```

**To find your device ID:**
1. Run app on your device
2. Go to Settings → Alpha Testing
3. Scroll to footer - device ID shown there
4. Add it to `developerDevices` array

## Alpha Testing Menu Features

### 1. Debug Logging
- Toggle to enable/disable log recording
- Logs written to: `Documents/veloready_debug.log`
- Automatically included in feedback submissions
- 5MB file size limit with automatic rotation

### 2. Pro Features Testing
- Toggle to bypass subscription check
- Test VeloAI, training load charts, advanced analytics
- Uses `ProFeatureConfig.bypassSubscriptionForTesting`

### 3. Cache Management
- Clear Intervals.icu activity cache
- Useful for troubleshooting stale data
- Confirmation alert before clearing

### 4. Feedback Instructions
- Step-by-step guide for bug reporting
- Explains logging workflow
- Encourages proper bug submissions

## Verifying Build Configuration

### Check if debug code is excluded:
```bash
# Build for release and check binary
xcodebuild -configuration Release -scheme VeloReady build
strings VeloReady.app/VeloReady | grep "Alpha Testing"
# Should return nothing in RELEASE builds
```

### Check if debug code is included:
```bash
# Build for debug and check binary
xcodebuild -configuration Debug -scheme VeloReady build
strings VeloReady.app/VeloReady | grep "Alpha Testing"
# Should find "Alpha Testing" string in DEBUG builds
```

## Best Practices

### For TestFlight Releases
1. Use DEBUG configuration
2. Enable alpha testing features
3. Include logging capabilities
4. Test Pro features without subscription

### For App Store Releases
1. Use RELEASE configuration
2. Verify no debug menus appear
3. Test on clean device
4. Confirm binary size reduction

## Troubleshooting

### "Alpha Testing menu not showing"
- Check you're using DEBUG build configuration
- Verify `#if DEBUG` flags are present in files
- Rebuild project (clean build folder)

### "Debug menu showing in production"
- Verify RELEASE configuration is selected
- Check Xcode scheme settings
- Ensure no `DEBUG` preprocessor flags in RELEASE

### "Logs not being recorded"
- Enable "Debug Logging" toggle in Alpha Testing menu
- Check `Logger.isDebugLoggingEnabled` returns true
- Verify file permissions for Documents directory

## File Locations

```
VeloReady/
├── Features/Settings/Views/
│   ├── AlphaTesterSettingsView.swift    (#if DEBUG)
│   ├── DebugSettingsView.swift          (#if DEBUG)
│   └── Sections/
│       └── DebugSection.swift           (#if DEBUG)
├── Core/
│   ├── Config/
│   │   ├── DebugFlags.swift             (Controls developer access)
│   │   └── ProFeatureConfig.swift       (Pro testing toggle)
│   └── Utils/
│       └── Logger.swift                 (File logging for alpha)
└── ALPHA_TESTING.md                     (This file)
```

## Summary

✅ **Alpha testers** get clean, focused testing interface  
✅ **Developers** get full technical debug tools  
✅ **Production users** see nothing - zero overhead  
✅ **Build size** reduced by excluding debug code  
✅ **Security** - no debug features in App Store  

---

Last updated: October 21, 2025
