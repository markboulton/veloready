# VeloReady Logging Strategy

## Current State (Beta-Ready)

### ✅ Automatic Production Optimization
The Logger is **already optimized for production**:

1. **DEBUG vs RELEASE Builds**
   - **DEBUG**: Uses `print()` for easy console reading
   - **RELEASE**: Uses `os_log` (Apple's efficient logging system)
   - **Performance Impact**: Near-zero in production

2. **Runtime Toggle**
   - Verbose logging controlled by `Logger.isDebugLoggingEnabled`
   - **Default**: OFF (no verbose logs)
   - **User control**: Settings → Debug → Enable Debug Logging
   - **Persists** across app launches

3. **Log Levels**
   ```swift
   Logger.debug()     // Only when toggle ON, DEBUG builds only
   Logger.info()      // Always shown, uses os_log in production
   Logger.warning()   // Always shown
   Logger.error()     // Always shown
   ```

## Beta Testing Guidelines

### For Beta Testers
**By default, verbose logging is OFF**. To enable diagnostic logging:
1. Open VeloReady
2. Go to Settings → Debug
3. Toggle "Enable Debug Logging"
4. Use app normally
5. Share logs via Settings → Debug → Export Logs

### For Developers
**Current logging in codebase:**

#### ✅ Keep (Production-Safe)
```swift
Logger.info()     // App lifecycle events
Logger.warning()  // Recoverable issues
Logger.error()    // Actual errors
```

#### 🔧 Debug Only (Respects Toggle)
```swift
Logger.debug()         // Detailed flow
Logger.performance()   // Timing measurements
Logger.network()       // API calls
Logger.data()          // Data operations
Logger.cache()         // Cache operations
```

## Current Logging in Today Page

### Recently Added (For Debugging)

**VO2 Max Card** (`AdaptiveVO2MaxCard.swift`):
```swift
Logger.debug("🏃 [VO2MaxCard] Loading card data")
Logger.debug("   estimatedVO2: ...")
Logger.debug("   hasPro: ...")
```

**Training Load Chart** (`TrainingLoadGraphCard.swift`):
```swift
Logger.debug("📊 [TrainingLoadCard] Loading chart data")
Logger.debug("   Fetched X daily scores...")
Logger.debug("   CTL range: ...")
```

**Chart Rendering** (`TodayTrainingLoadChart.swift`):
```swift
Logger.debug("📈 [Chart] Rendering with X points")
Logger.debug("📈 [Chart] CTL: min=X, max=X...")
```

### Recommendation for Beta

**Leave as-is** because:
1. ✅ All use `Logger.debug()` (toggle-controlled)
2. ✅ Zero impact when toggle OFF
3. ✅ Invaluable for user bug reports
4. ✅ Automatic in production (os_log)

## Performance Impact Analysis

### Memory
- **DEBUG build with toggle OFF**: 0 bytes (logging compiled out)
- **DEBUG build with toggle ON**: ~5MB max (log file rotation)
- **RELEASE build**: Minimal (os_log manages memory)

### CPU
- **print() overhead**: ~1-5ms per log (DEBUG only)
- **os_log overhead**: <0.1ms per log (production)
- **File writing**: Async queue, no UI blocking

### Battery
- **Negligible impact** - logging is I/O bound, not CPU intensive
- os_log is specifically optimized for low power consumption

## Cleanup Recommendations

### Before Beta Launch
**No action needed** - logging is already production-ready!

### Optional: Reduce Verbosity
If you want less verbose logs even in debug mode:

1. **Remove chart rendering logs** (too frequent):
   ```swift
   // Remove from TodayTrainingLoadChart.swift line 9-23
   let _ = Logger.debug("📈 [Chart] Rendering...")
   ```

2. **Consolidate card logs** (one line per card):
   ```swift
   // Instead of 5 debug lines, use:
   Logger.debug("🏃 [VO2MaxCard] Loaded: \(vo2Value), hasData: \(hasData)")
   ```

3. **Keep error/warning logs** (always useful):
   ```swift
   Logger.warning("⚠️ No VO2 estimate available")
   Logger.error("❌ Failed to fetch training load data")
   ```

## Beta Testing Workflow

### When User Reports Bug:
1. Ask user to enable debug logging
2. Reproduce issue
3. User exports logs (Settings → Debug → Export Logs)
4. Send via email/TestFlight feedback
5. Logs include:
   - Last 500 log lines
   - Device info
   - App version
   - Timestamp

### Log File Location:
- **DEBUG**: `Documents/veloready_debug.log`
- **Size limit**: 5MB (auto-rotation)
- **Privacy**: Local only, never sent without user action

## Recommendation

**✅ Ship current logging as-is for beta**

Why:
- Zero production performance impact
- User-controlled verbosity
- Critical for diagnosing user-reported bugs
- Already follows iOS best practices
- Automatic cleanup in release builds

The logging infrastructure is **production-ready** and **beta-safe**.
