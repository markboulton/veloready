# Core Data Cache Persistence Setup

## ⚠️ REQUIRED: Add CacheEntry Entity to Core Data Model

The cache persistence layer requires a new `CacheEntry` entity in the Core Data model.

### Steps to Add the Entity:

1. **Open the Core Data Model**:
   - Navigate to `VeloReady/Core/Data/VeloReady.xcdatamodeld`
   - Open the file in Xcode

2. **Add New Entity**:
   - Click the "+" button at the bottom to add a new entity
   - Name it: `CacheEntry`

3. **Add Attributes**:
   | Attribute | Type | Optional | Description |
   |-----------|------|----------|-------------|
   | `key` | String | No | Unique cache key (e.g., "strava:activities:365") |
   | `valueData` | Binary Data | No | JSON-encoded cached value |
   | `cachedAt` | Date | No | Timestamp when cached |
   | `expiresAt` | Date | Yes | Expiration timestamp |

4. **Add Indexes (Optional but Recommended)**:
   - Add index on `key` for faster lookups
   - Add index on `expiresAt` for faster cleanup queries

5. **Set Codegen**:
   - Select the `CacheEntry` entity
   - In the inspector, set "Codegen" to "Manual/None"
   - (The Swift files are already created: `CacheEntry+CoreDataClass.swift` and `CacheEntry+CoreDataProperties.swift`)

6. **Save the Model**:
   - Save the .xcdatamodeld file
   - Build the project

### Architecture Overview:

```
┌─────────────────────────────────────────────────┐
│         UnifiedCacheManager (Memory)            │
│  ┌──────────────────────────────────────────┐   │
│  │  Memory Cache (volatile)                 │   │
│  │  - Fast lookup (ns)                      │   │
│  │  - Auto-eviction under pressure          │   │
│  │  - Lost on app termination               │   │
│  └──────────────────────────────────────────┘   │
└─────────────────┬───────────────────────────────┘
                  │
                  │ Save on every cache write
                  │ Load on cache miss
                  ▼
┌─────────────────────────────────────────────────┐
│     CachePersistenceLayer (Core Data)           │
│  ┌──────────────────────────────────────────┐   │
│  │  CacheEntry Entity                       │   │
│  │  - Persistent across app restarts        │   │
│  │  - JSON-encoded values                   │   │
│  │  - TTL-based expiration                  │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

### Benefits:

✅ **Survives app termination** - Data persists across kills/restarts
✅ **Instant offline startup** - No network needed for cached data
✅ **Automatic cleanup** - Expired entries are automatically removed
✅ **Type-safe** - Generic Codable support for all cache types
✅ **Thread-safe** - Actor-based with background context
✅ **Non-blocking** - Saves happen in background tasks

### Cache Flow:

1. **Write Path**:
   ```
   UnifiedCacheManager.storeInCache()
   └─> Memory cache (instant)
   └─> Task.detached:
       └─> CachePersistenceLayer.saveToCoreData()
           └─> Background context (non-blocking)
   ```

2. **Read Path**:
   ```
   UnifiedCacheManager.fetch()
   ├─> Memory cache? → Return (fast)
   ├─> Core Data? → Restore to memory → Return (medium)
   └─> Network fetch → Save to both → Return (slow)
   ```

3. **Offline Startup**:
   ```
   App Launch (offline)
   └─> Memory cache empty
   └─> Core Data populated with last session's data
   └─> Data restored to memory
   └─> UI displays cached data (<200ms)
   ```

### Testing After Setup:

1. **Build the app** - Should succeed now
2. **Run the app online** - Cache entries are saved to Core Data
3. **Kill the app**
4. **Turn off network**
5. **Relaunch the app** - Data should load from Core Data!

### Verification Query:

To verify entries are being saved, use this Core Data query in debugging:

```swift
let request: NSFetchRequest<CacheEntry> = CacheEntry.fetchRequest()
let count = try? context.count(for: request)
print("📊 Cache entries in Core Data: \(count ?? 0)")
```

### Cleanup:

To clear all cached entries (for testing):

```swift
await CachePersistenceLayer.shared.clearAll()
```

---

## 🎯 Files Created:

- ✅ `CachePersistenceLayer.swift` - Actor-based persistence layer
- ✅ `CacheEntry+CoreDataClass.swift` - Entity class
- ✅ `CacheEntry+CoreDataProperties.swift` - Entity properties
- ⚠️ `VeloReady.xcdatamodeld` - **NEEDS MANUAL ENTITY ADDITION** (see steps above)

## 📝 Integration Complete:

- ✅ `UnifiedCacheManager.fetch()` - Checks Core Data on cache miss
- ✅ `UnifiedCacheManager.fetchCacheFirst()` - Checks Core Data for stale data
- ✅ `UnifiedCacheManager.storeInCache()` - Saves to Core Data in background
- ✅ TTL determination - Maps cache keys to appropriate TTL values

---

**After adding the entity to the Core Data model, rebuild and test!** 🚀
