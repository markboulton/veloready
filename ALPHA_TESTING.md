# Alpha Testing Guide

## Build Configurations

### DEBUG Builds (TestFlight, Local Development)
- **Alpha Testing menu** is visible in Settings
- **Full Debug menu** is visible for developers (when `DebugFlags.showDebugMenu = true`)
- File logging is available
- All testing features enabled

### RELEASE Builds (App Store)
- **No debug menus** - completely excluded via `#if DEBUG` compiler flags
- No alpha testing options visible
- No debug settings accessible
- Smaller binary size
- Zero runtime overhead from debug code

## Files Excluded from Production

The following files are wrapped in `#if DEBUG` and will NOT be compiled into App Store builds:

1. **AlphaTesterSettingsView.swift** - Simplified alpha tester menu
2. **DebugSettingsView.swift** - Full developer debug menu
3. **DebugSection.swift** - Settings section that shows both menus

## How to Build for Different Audiences

### For Alpha Testers (TestFlight)
```bash
# Build with DEBUG configuration
xcodebuild -configuration Debug -scheme VeloReady archive
```
**Result:** Alpha testers see "Alpha Testing" menu in Settings

### For App Store (Production)
```bash
# Build with RELEASE configuration
xcodebuild -configuration Release -scheme VeloReady archive
```
**Result:** No debug menus visible, clean production build

## Developer Access Control

### Alpha Testers
- See: **Alpha Testing** menu only
- Can: Enable logging, test Pro features, clear cache
- Cannot: Access technical debug tools

### Developers
Set `DebugFlags.showDebugMenu = true` in your device to see:
- **Alpha Testing** menu (simplified)
- **Debug** menu (full technical tools)

Location: `/Core/Config/DebugFlags.swift`

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
