# Pull-to-Refresh Fix & Rate Limit Impact Analysis

**Date:** November 13, 2025  
**Issues:**
1. Pull-to-refresh doesn't show new Strava activities
2. Concern about rate limits with 5-minute cache at 1000 users

---

## 1. 🐛 Why Pull-to-Refresh Didn't Work

### The Problem

You pulled to refresh but the "4 x 9" ride still didn't appear. Here's why:

**Current Flow:**
```
User pulls to refresh
↓
TodayView.refreshData()
↓
TodayCoordinator.refresh()
↓
ActivitiesCoordinator.fetchRecent(days: 90)
↓
UnifiedActivityService.fetchRecentActivities() ← Uses 1-hour cache!
↓
Returns CACHED data (from 10:49 PM last night)
↓
"4 x 9" ride still missing ❌
```

**The Bug:**

In `TodayCoordinator.swift` line 172-174:
```swift
case (.pullToRefresh, .ready), (.pullToRefresh, .background):
    // User explicitly triggered pull-to-refresh
    await refresh()  // ← Doesn't invalidate cache!
```

The `refresh()` method just calls the normal fetch logic which uses cached data if < 1 hour old.

**Even with my 5-minute TTL fix**, pull-to-refresh would still use cached data if you pulled within 5 minutes of the last fetch.

### The Fix Required

<function_calls>
<invoke name="read_file">
<parameter name="target_file">/Users/mark.boulton/Documents/dev/veloready/VeloReady/Features/Today/Coordinators/TodayCoordinator.swift
