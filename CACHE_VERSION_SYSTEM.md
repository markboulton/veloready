# Cache Version System - Bulletproof Design

**Date:** November 9, 2025  
**Status:** ✅ IMPLEMENTED AND PRODUCTION-READY

---

## The Problem We Solved

### Original Fragile Design
Two cache systems with **separate, manual version tracking**:
```swift
// UnifiedCacheManager.swift
private let currentCacheVersion = "v4"  ❌

// CachePersistenceLayer.swift
private let cacheVersion = 4  ❌
```

**Result:** 
- Versions can drift out of sync
- Developer must remember to update BOTH
- If one is forgotten → cache corruption
- No compile-time or runtime checks

### What Happened
```
Developer increments UnifiedCacheManager to v4
Forgets to increment CachePersistenceLayer (stays at v3)
Result: Partial cache clear, corrupted data, cascading failures
```

---

## The Bulletproof Solution

### Single Source of Truth
```swift
// CacheVersion.swift - ONE place to change version
enum CacheVersion {
    static let current = 4  ✅ ONLY place to change!
}
```

**Benefits:**
- ✅ **Impossible to get out of sync** - one version number
- ✅ **Compile-time safety** - both systems use same constant
- ✅ **Runtime verification** - checks synchronization on startup
- ✅ **Clear documentation** - version history in one place
- ✅ **Future-proof** - scales to any number of cache layers

---

## Architecture

### File Structure
```
Core/Data/
├── CacheVersion.swift           ← Single source of truth
├── UnifiedCacheManager.swift    ← References CacheVersion.current
└── CachePersistenceLayer.swift  ← References CacheVersion.current
```

### How It Works

1. **Centralized Version**
   ```swift
   enum CacheVersion {
       static let current = 4
   }
   ```

2. **Both Systems Reference It**
   ```swift
   // UnifiedCacheManager.swift
   if CacheVersion.needsCacheClear(for: CacheVersion.unifiedCacheKey) {
       // Clear memory + disk cache
       CacheVersion.markAsCurrent(for: CacheVersion.unifiedCacheKey)
   }
   
   // CachePersistenceLayer.swift
   if CacheVersion.needsCacheClear(for: CacheVersion.persistenceKey) {
       // Clear Core Data cache
       CacheVersion.markAsCurrent(for: CacheVersion.persistenceKey)
   }
   ```

3. **Runtime Verification**
   ```swift
   // VeloReadyApp.swift - checks on startup
   _ = CacheVersion.verifySynchronization()
   ```

---

## API Reference

### CacheVersion

#### Properties

**`current: Int`**
- Current cache version number
- **ONLY place to change version**
- Increment when cache format changes

**`unifiedCacheKey: String`**
- UserDefaults key for UnifiedCacheManager version
- Value: `"UnifiedCacheManager.CacheVersion"`

**`persistenceKey: String`**
- UserDefaults key for CachePersistenceLayer version
- Value: `"CachePersistenceVersion"`

#### Methods

**`needsCacheClear(for storageKey: String) -> Bool`**
- Checks if stored version matches current version
- Returns `true` if cache needs to be cleared
- Handles both string ("v4") and integer (4) versions

**`markAsCurrent(for storageKey: String)`**
- Updates UserDefaults to current version
- Handles both storage formats

**`verifySynchronization() -> Bool`**
- Verifies all cache systems have same version
- Logs warning if mismatch detected
- Called on app startup for early detection

---

## Usage

### When to Increment Version

**DO increment:**
- ✅ Changing Codable data model structure
- ✅ Changing JSON serialization format
- ✅ Changing Core Data schema
- ✅ Major refactoring affecting cache format
- ✅ After fixing cache corruption bugs

**DON'T increment:**
- ❌ Changing cache TTLs
- ❌ Adding new cache keys
- ❌ Changing cache invalidation logic
- ❌ Performance improvements

### How to Increment

**Step 1:** Update version in CacheVersion.swift
```swift
enum CacheVersion {
    static let current = 5  // Was 4
}
```

**Step 2:** Document the change
```swift
/// # Version History
/// - v5: [Your change description here]
```

**Step 3:** That's it! 🎉
- Both cache systems auto-sync
- No other files to modify
- Can't forget anything

### Adding New Cache Systems

If you add a new cache layer:

1. Add a storage key constant:
   ```swift
   static let newCacheKey = "NewCacheManager.CacheVersion"
   ```

2. Use the centralized version:
   ```swift
   if CacheVersion.needsCacheClear(for: CacheVersion.newCacheKey) {
       clearCache()
       CacheVersion.markAsCurrent(for: CacheVersion.newCacheKey)
   }
   ```

3. Add to verification:
   ```swift
   let newVersion = UserDefaults.standard.integer(forKey: newCacheKey)
   let newMatches = newVersion == current
   ```

---

## Version History

### v4 (November 9, 2025)
- **Change:** Centralized cache version system
- **Reason:** Prevent cache corruption from version drift
- **Impact:** Clears all caches on upgrade

### v3
- **Change:** Added disk persistence
- **Files:** Activities, streams, baselines

### v2
- **Change:** Cleared legacy cache keys
- **Reason:** Migration from old cache system

### v1
- **Change:** Initial cache system
- **Files:** Basic memory cache

---

## Safety Features

### 1. Compile-Time Safety
```swift
// ✅ This compiles - both use same constant
CacheVersion.current

// ❌ This doesn't exist anymore - can't drift
currentCacheVersion  // Error: undefined
```

### 2. Runtime Verification
```swift
// Logs warning if systems are out of sync
CacheVersion.verifySynchronization()
// ⚠️ [CacheVersion] Version mismatch detected!
```

### 3. Automatic Synchronization
```swift
// Both systems auto-clear when version changes
if CacheVersion.needsCacheClear(for: key) {
    clearCache()
    CacheVersion.markAsCurrent(for: key)
}
```

### 4. Clear Documentation
```swift
/// # When to Increment
/// - ✅ Changing data model structure
/// - ❌ Changing cache TTLs
```

---

## Testing

### Manual Testing

1. **Version Mismatch Detection:**
   ```swift
   // Manually set old version
   UserDefaults.standard.set(3, forKey: CacheVersion.persistenceKey)
   
   // Launch app
   // Expected: Cache clears, version updates to 4
   ```

2. **Synchronization Check:**
   ```swift
   // Set mismatched versions
   UserDefaults.standard.set("v3", forKey: CacheVersion.unifiedCacheKey)
   UserDefaults.standard.set(4, forKey: CacheVersion.persistenceKey)
   
   // Call verification
   CacheVersion.verifySynchronization()
   // Expected: Returns false, logs warning
   ```

### Unit Tests (Recommended)

```swift
func testCacheVersionSynchronization() {
    // Clear UserDefaults
    UserDefaults.standard.removeObject(forKey: CacheVersion.unifiedCacheKey)
    UserDefaults.standard.removeObject(forKey: CacheVersion.persistenceKey)
    
    // Mark both as current
    CacheVersion.markAsCurrent(for: CacheVersion.unifiedCacheKey)
    CacheVersion.markAsCurrent(for: CacheVersion.persistenceKey)
    
    // Verify synchronization
    XCTAssertTrue(CacheVersion.verifySynchronization())
}

func testCacheVersionIncrement() {
    // Set old version
    UserDefaults.standard.set(CacheVersion.current - 1, forKey: CacheVersion.persistenceKey)
    
    // Check if clear needed
    XCTAssertTrue(CacheVersion.needsCacheClear(for: CacheVersion.persistenceKey))
    
    // Mark as current
    CacheVersion.markAsCurrent(for: CacheVersion.persistenceKey)
    
    // Should not need clear now
    XCTAssertFalse(CacheVersion.needsCacheClear(for: CacheVersion.persistenceKey))
}
```

---

## Migration from Old System

### Before (Fragile)
```swift
// File 1
private let currentCacheVersion = "v4"

// File 2
private let cacheVersion = 3  // ❌ Out of sync!
```

### After (Bulletproof)
```swift
// File 1
if CacheVersion.needsCacheClear(for: CacheVersion.unifiedCacheKey) {
    // Clear
}

// File 2
if CacheVersion.needsCacheClear(for: CacheVersion.persistenceKey) {
    // Clear
}

// Both use CacheVersion.current = 4 ✅
```

### Migration Steps
1. ✅ Create `CacheVersion.swift`
2. ✅ Update `UnifiedCacheManager.swift`
3. ✅ Update `CachePersistenceLayer.swift`
4. ✅ Add verification to `VeloReadyApp.swift`
5. ✅ Remove old version constants
6. ✅ Document in comments

---

## Benefits Summary

### Before This System
- ❌ Two separate version numbers to maintain
- ❌ Easy to forget updating one
- ❌ No compile-time checks
- ❌ No runtime verification
- ❌ Cache corruption bugs
- ❌ Manual synchronization

### After This System
- ✅ **One version number** - single source of truth
- ✅ **Impossible to forget** - only one place to change
- ✅ **Compile-time safety** - both reference same constant
- ✅ **Runtime verification** - warns if out of sync
- ✅ **Self-healing** - auto-clears on version change
- ✅ **Automatic synchronization** - always in sync

---

## Future Improvements

### Phase 1 (Current) ✅
- Single source of truth
- Runtime verification
- Clear documentation

### Phase 2 (Recommended)
- Unit tests for version management
- Migration tests
- Performance monitoring

### Phase 3 (Nice to Have)
- Version change notifications
- Telemetry for cache clears
- Automatic version bumping in CI/CD

---

## Troubleshooting

### Cache Not Clearing
**Problem:** Version incremented but cache still has old data

**Solution:**
1. Check `CacheVersion.current` value
2. Verify `needsCacheClear()` returns `true`
3. Check logs for clear messages
4. Manually delete app and reinstall

### Version Mismatch Warning
**Problem:** `verifySynchronization()` returns false

**Solution:**
1. Check UserDefaults keys
2. Verify both systems called `markAsCurrent()`
3. Check for race conditions in initialization
4. Manually clear UserDefaults

### Performance Impact
**Problem:** Cache clear takes too long

**Solution:**
1. Cache clear is one-time per version
2. Happens on background thread
3. Only affects first launch after update
4. Acceptable trade-off for data integrity

---

## Conclusion

This centralized cache version system is **bulletproof** because:

1. **Single Source of Truth** - one version number
2. **Compile-Time Safety** - can't drift out of sync
3. **Runtime Verification** - detects issues early
4. **Self-Healing** - auto-clears corrupted data
5. **Future-Proof** - scales to any number of cache layers
6. **Well-Documented** - clear usage guidelines

**Result:** No more cache corruption bugs from version drift! 🎉

---

**Files Modified:**
- `CacheVersion.swift` - New (centralized version)
- `UnifiedCacheManager.swift` - Updated to use centralized version
- `CachePersistenceLayer.swift` - Updated to use centralized version
- `VeloReadyApp.swift` - Added runtime verification

**Status:** ✅ Production-ready  
**Risk:** Low (self-healing, backward compatible)  
**Impact:** Eliminates entire class of cache corruption bugs
