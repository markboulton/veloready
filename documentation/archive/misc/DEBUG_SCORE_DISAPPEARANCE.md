# Debug: Score Disappearance During Offline/Online Transitions

## Problem Statement
When user toggles wifi off/on and returns to app:
1. Scores disappear (empty rings shown)
2. No visible loading status
3. Should show: offline status → scores remain → syncing status → scores remain

## Comprehensive Logging Added

### Log Categories to Watch:

#### 1. **ViewModel Lifecycle** (`🏗️ [VIEWMODEL]`)
- When RecoveryMetricsSectionViewModel is created
- When it's deinitialized (indicates view recreation)
- Initial score values on creation

#### 2. **Score Changes via Combine** (`🔄 [VIEWMODEL]`)
- Every time a score service publishes a new value
- Shows old → new value transitions
- Tracks if scores are being set to nil

#### 3. **Network State Changes** (`🌐 [NETWORK]`)
- When network state changes (online ↔ offline)
- Score values BEFORE network change
- Score values AFTER going offline
- Score values AFTER showing syncing state
- Score values AFTER refreshData()

#### 4. **App Foreground Events** (`🔄 [FOREGROUND]`)
- When app enters foreground (user returns from Settings)
- Score values BEFORE any action
- Score values AFTER cache invalidation
- Score values AFTER refreshData()

#### 5. **Data Refresh** (`🔍 [REFRESH]`)
- Score values at START of refreshData()
- Score values BEFORE marking complete
- Score values at END of refreshData()

#### 6. **View Body Evaluation** (`📺 [VIEW]`)
- When RecoveryMetricsSection view is recreated
- When body is re-evaluated
- Current score values during render

#### 7. **Score Service Sync Loading** (Already Added)
- `🔍 [RECOVERY SYNC]`, `🔍 [SLEEP SYNC]`, `🔍 [STRAIN SYNC]`
- Shows synchronous UserDefaults loading
- Shows before/after score values

#### 8. **Score Service Async Loading** (Already Added)
- `🔍 [RECOVERY ASYNC]`, `🔍 [SLEEP ASYNC]`, `🔍 [STRAIN ASYNC]`
- Shows async UnifiedCacheManager loading
- Shows preservation of sync-loaded scores

## How to Debug

### Step 1: Run the App
```bash
cd /Users/markboulton/Dev/veloready
# Run in simulator and watch Console.app logs filtered by "VeloReady"
```

### Step 2: Test Offline Scenario
1. Open app → wait for scores to load
2. Open Control Center → turn OFF wifi
3. Return to app (should show orange offline status + scores REMAIN)
4. **Check logs for**:
   - `🌐 [NETWORK] Network state changed: OFFLINE`
   - `🌐 [NETWORK] Score state AFTER going offline:` (should show scores like 92, 93, etc., NOT -999)
   - `📺 [VIEW] RecoveryMetricsSection body evaluated` (should show scores, NOT -999)

### Step 3: Test Online Scenario
1. Open Control Center → turn ON wifi
2. Return to app (should show green syncing status + scores REMAIN)
3. **Check logs for**:
   - `🌐 [NETWORK] Network state changed: ONLINE`
   - `🌐 [NETWORK] Score state AFTER showing syncing state:` (should show scores)
   - `🌐 [NETWORK] About to call refreshData()`
   - `🔍 [REFRESH] Score state at START of refreshData():` (should show scores)
   - `🔍 [REFRESH] Score state at END of refreshData():` (should show scores)
   - `📺 [VIEW] RecoveryMetricsSection body evaluated` (should show scores)

### Step 4: Check for View Recreation
If you see:
```
🗑️ [VIEWMODEL] RecoveryMetricsSectionViewModel DEINIT - was deinitialized
🏗️ [VIEWMODEL] RecoveryMetricsSectionViewModel INIT starting
```
**This means the view is being RECREATED**, which would reset to nil scores until services publish again.

## Expected Log Patterns

### ✅ GOOD (scores persist):
```
🌐 [NETWORK] Network state changed: OFFLINE
🌐 [NETWORK] Score state BEFORE handling network change:
   Recovery: 92
   Sleep: 93
   Strain: 8.5
🌐 [NETWORK] Score state AFTER going offline:
   Recovery: 92
   Sleep: 93
   Strain: 8.5
📺 [VIEW] RecoveryMetricsSection body evaluated - recovery: 92, sleep: 93, strain: 8.5
```

### ❌ BAD (scores disappear):
```
🌐 [NETWORK] Network state changed: OFFLINE
🌐 [NETWORK] Score state BEFORE handling network change:
   Recovery: 92
   Sleep: 93
   Strain: 8.5
🗑️ [VIEWMODEL] RecoveryMetricsSectionViewModel DEINIT - was deinitialized
🏗️ [VIEWMODEL] RecoveryMetricsSectionViewModel INIT starting
📺 [VIEW] RecoveryMetricsSection body evaluated - recovery: -1, sleep: -1, strain: -1
🌐 [NETWORK] Score state AFTER going offline:
   Recovery: -999
   Sleep: -999
   Strain: -999
```

## Root Causes to Look For

1. **View Recreation**: If ViewModel deinit/init happens during network transitions
2. **Score Service Clearing**: If scores go from valid values to -999 in service
3. **Combine Not Publishing**: If scores exist in service but ViewModel doesn't receive them
4. **View Rebuild**: If view body evaluates with nil scores even though ViewModel has them

## What the Logs Will Tell Us

The logs will show **exactly**:
- ✅ When scores are loaded (sync + async)
- ✅ When network state changes
- ✅ Whether scores remain in services during transitions
- ✅ Whether ViewModel is being recreated
- ✅ Whether view is rendering with nil vs valid scores
- ✅ Where in the flow scores get cleared

## Next Steps After Reviewing Logs

Once we see the logs, we can:
1. Identify the EXACT point where scores disappear
2. Fix the root cause (view recreation, score clearing, etc.)
3. Verify the fix with the same logging
4. Remove debug logs once issue is resolved
