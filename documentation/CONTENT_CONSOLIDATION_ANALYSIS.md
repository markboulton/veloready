# Content Consolidation Analysis

## Duplication Patterns Identified

### 1. **Empty States** (Highest Duplication)
**Occurrences:** 15+ files
- `noData` - 12 variations ("No data", "No data available", "Not enough data", "No X data")
- `noDataFound` - 3 variations
- `loading` / `loadingData` - 10+ variations
- `checkBack` - 2 variations

**Files Affected:**
- TrendsContent.swift (7 instances)
- TodayContent.swift (5 instances)
- ActivityContent.swift (3 instances)
- CommonContent.swift (1 instance)
- ComponentContent.swift (2 instances)
- TrainingLoadContent.swift, ChartContent.swift, AthleteZonesContent.swift

### 2. **Common Actions** (High Duplication)
**Occurrences:** 20+ files
- `title` - Every content file
- `loading` - 8 files
- `error` - 5 files
- `retry` - 3 files
- `sync` / `syncing` - 6 files

### 3. **Common Labels** (Medium Duplication)
- "Wear Apple Watch during sleep" - 3 files (TrendsContent HRV, RestingHR, RecoveryTrend)
- "Track for 7+ days" - 4 files
- "Grant permission" - 3 files
- Bullet point "•" - 5 files

### 4. **Status Messages** (Medium Duplication)
- `enabled` / `disabled` - 5 files
- `connected` / `disconnected` - 3 files
- `success` / `failed` - 2 files

## Recommended Consolidation Strategy

### Phase 1: Create Hierarchical CommonContent
```swift
enum CommonContent {
    // MARK: - Universal States
    enum States {
        static let loading = "Loading..."
        static let loadingData = "Loading data..."
        static let syncing = "Syncing..."
        static let analyzing = "Analyzing..."
        static let noData = "No data available"
        static let notEnoughData = "Not enough data"
        static let error = "Something went wrong"
        static let success = "Success"
        static let failed = "Failed"
    }
    
    // MARK: - Universal Actions
    enum Actions {
        static let retry = "Retry"
        static let refresh = "Refresh"
        static let sync = "Sync"
        static let connect = "Connect"
        static let disconnect = "Disconnect"
        static let enable = "Enable"
        static let disable = "Disable"
        static let save = "Save"
        static let cancel = "Cancel"
        static let done = "Done"
        static let close = "Close"
    }
    
    // MARK: - Universal Labels
    enum Labels {
        static let title = "Title"
        static let subtitle = "Subtitle"
        static let description = "Description"
        static let status = "Status"
        static let enabled = "Enabled"
        static let disabled = "Disabled"
        static let connected = "Connected"
        static let disconnected = "Disconnected"
    }
    
    // MARK: - Universal Instructions
    enum Instructions {
        static let wearAppleWatch = "Wear Apple Watch during sleep"
        static let grantPermission = "Grant permission in Settings"
        static let trackConsistently = "Track consistently for 7+ days"
        static let checkBackLater = "Check back after a few days"
        static let pullToRefresh = "Pull to refresh"
    }
    
    // MARK: - Universal Formatting
    enum Formatting {
        static let bulletPoint = "•"
        static let dash = "—"
        static let separator = "·"
    }
    
    // MARK: - Time Units
    enum TimeUnits {
        static let day = "day"
        static let days = "days"
        static let hour = "hour"
        static let hours = "hours"
        static let minute = "minute"
        static let minutes = "minutes"
        static let second = "second"
        static let seconds = "seconds"
    }
}
```

### Phase 2: Feature-Specific Content Inherits from Common
```swift
enum TrendsContent {
    // Use CommonContent for shared strings
    static let noData = CommonContent.States.notEnoughData
    static let loading = CommonContent.States.loadingData
    static let bulletPoint = CommonContent.Formatting.bulletPoint
    
    // Feature-specific strings only
    enum Cards {
        static let performanceOverview = "Performance Overview"
        // ...
    }
}
```

### Phase 3: Refactor Pattern
1. Move all duplicated strings to CommonContent
2. Update feature content files to reference CommonContent
3. Keep only feature-specific strings in feature content files
4. Document the hierarchy

## Impact Analysis

### Before Consolidation
- **Total Content Strings:** ~800
- **Duplicated Strings:** ~200 (25%)
- **Content Files:** 15+

### After Consolidation
- **CommonContent Strings:** ~100
- **Feature-Specific Strings:** ~500
- **Reduction:** 25% fewer total strings
- **Maintenance:** Single source of truth for common strings

## Benefits

1. **Consistency:** Same string used everywhere
2. **Maintainability:** Update once, changes everywhere
3. **Localization:** Easier to translate common strings
4. **Efficiency:** Smaller codebase
5. **Clarity:** Feature files only contain feature-specific content

## Next Steps

1. ✅ Analysis complete
2. ⏳ Enhance CommonContent with all shared strings
3. ⏳ Refactor all content files to use CommonContent
4. ⏳ Remove duplicates from feature files
5. ⏳ Document new content hierarchy
6. ⏳ Return to abstraction task with efficient system
