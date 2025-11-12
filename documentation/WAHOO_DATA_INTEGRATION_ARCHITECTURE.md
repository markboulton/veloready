# Wahoo Data Integration Architecture

## Problem Statement

Phase 3 implemented Wahoo's **infrastructure layer** (OAuth, webhooks, database), but didn't integrate Wahoo data into the **consumption layer** where the app actually uses activity data for:

- CTL/ATL/TSB calculations
- TSS calculations
- Adaptive FTP/Zones
- Ride detail views
- Activity lists
- Training load charts
- Recovery/Strain scores
- ML training data

**Currently:** Wahoo workouts are stored in the database but **never fetched or displayed** in the app.

## Current Architecture

### Data Flow (Strava/Intervals.icu)
```
Strava API / Intervals.icu API
    ↓
StravaDataService / UnifiedActivityService
    ↓
ActivityConverter (converts to Activity)
    ↓
Activity (common internal format)
    ↓
Calculations (CTL/ATL/TSS/FTP/Zones)
    ↓
Views (RideDetailSheet, ActivityCard, Charts)
```

### Key Components

1. **UnifiedActivity** - Wrapper for multiple sources
   ```swift
   struct UnifiedActivity {
       let source: ActivitySource // .strava, .intervalsICU, .appleHealth
       let intervalsActivity: Activity?
       let stravaActivity: StravaActivity?
       let healthKitWorkout: HKWorkout?
   }
   ```

2. **ActivityConverter** - Transforms external formats
   ```swift
   static func stravaToIntervals(_ activity: StravaActivity) -> Activity
   ```

3. **UnifiedActivityService** - Fetches from all sources
   ```swift
   func fetchRecentActivities() async -> [Activity]
   ```

4. **StravaDataService** - Strava-specific fetching
   ```swift
   func fetchActivitiesForZones() async -> [StravaActivity]
   ```

5. **TrainingLoadCalculator** - Uses Activity
   ```swift
   func calculateTrainingLoadFromActivities(_ activities: [Activity])
   ```

6. **AthleteProfile.computeFromActivities** - Adaptive FTP/Zones
   ```swift
   func computeFromActivities(_ activities: [Activity])
   ```

## Required Changes for Wahoo Integration

### Phase 3A: Data Model Integration

#### 1. Add Wahoo to UnifiedActivity
**File:** `VeloReady/Core/Models/UnifiedActivity.swift`

```swift
struct UnifiedActivity {
    // ... existing fields ...
    
    let wahooWorkout: WahooWorkout? // NEW
    
    enum ActivitySource {
        case intervalsICU
        case strava
        case wahoo // NEW
        case appleHealth
    }
}
```

#### 2. Create WahooWorkout Model
**NEW FILE:** `VeloReady/Core/Models/WahooWorkout.swift`

```swift
/// Represents a workout from Wahoo (SYSTM, ELEMNT, etc.)
struct WahooWorkout: Codable, Identifiable {
    let id: String // wahoo_workout_id from database
    let wahooUserId: String
    let name: String?
    let type: String? // "cycling", "running", etc.
    let startedAt: Date
    let durationSeconds: Int?
    let distanceMeters: Double?
    let calories: Int?
    let avgPowerWatts: Int?
    let maxPowerWatts: Int?
    let avgHeartRate: Int?
    let maxHeartRate: Int?
    let normalizedPower: Int?
    let intensityFactor: Double?
    let trainingStressScore: Double?
    
    // Computed properties
    var duration: TimeInterval? {
        durationSeconds.map { TimeInterval($0) }
    }
    
    var tss: Double? {
        trainingStressScore
    }
    
    var np: Double? {
        normalizedPower.map { Double($0) }
    }
    
    var avgPower: Double? {
        avgPowerWatts.map { Double($0) }
    }
}
```

#### 3. Add WahooDataService
**NEW FILE:** `VeloReady/Core/Services/Data/WahooDataService.swift`

```swift
@MainActor
class WahooDataService: ObservableObject {
    static let shared = WahooDataService()
    
    @Published private(set) var workouts: [WahooWorkout] = []
    @Published private(set) var isLoading = false
    
    private let wahooAuth = WahooAuthService.shared
    private let veloReadyAPI = VeloReadyAPIClient.shared
    private let cache = UnifiedCacheManager.shared
    
    /// Fetch Wahoo workouts for a time range
    func fetchWorkouts(daysBack: Int = 90) async -> [WahooWorkout] {
        guard case .connected(let userId) = wahooAuth.connectionState else {
            return []
        }
        
        let cacheKey = CacheKey.wahooWorkouts(daysBack: daysBack)
        let cacheTTL: TimeInterval = 3600 // 1 hour
        
        do {
            let workouts = try await cache.fetch(key: cacheKey, ttl: cacheTTL) {
                // Fetch from backend API (reads from wahoo_workouts table)
                try await self.veloReadyAPI.fetchWahooWorkouts(
                    userId: userId,
                    daysBack: daysBack
                )
            }
            
            self.workouts = workouts
            return workouts
        } catch {
            Logger.error("❌ [Wahoo] Failed to fetch workouts: \(error)")
            return []
        }
    }
}
```

#### 4. Extend ActivityConverter
**File:** `VeloReady/Core/Utils/ActivityConverter.swift`

```swift
extension ActivityConverter {
    /// Convert Wahoo workout to Activity format
    static func wahooToIntervals(_ workout: WahooWorkout) -> Activity {
        Activity(
            id: Int(workout.id) ?? 0,
            startDateLocal: ISO8601DateFormatter().string(from: workout.startedAt),
            type: workout.type ?? "Ride",
            name: workout.name,
            movingTime: workout.durationSeconds,
            distance: workout.distanceMeters,
            calories: workout.calories,
            averageWatts: workout.avgPowerWatts,
            normalizedWatts: workout.normalizedPower,
            averageHeartrate: workout.avgHeartRate,
            maxHeartrate: workout.maxHeartRate,
            tss: workout.trainingStressScore,
            intensityFactor: workout.intensityFactor,
            // ... map other fields ...
        )
    }
    
    /// Convert batch of Wahoo workouts
    static func wahooToIntervals(_ workouts: [WahooWorkout]) -> [Activity] {
        workouts.map { wahooToIntervals($0) }
    }
}
```

### Phase 3B: Service Integration

#### 5. Update UnifiedActivityService
**File:** `VeloReady/Core/Services/Data/UnifiedActivityService.swift`

```swift
class UnifiedActivityService {
    // ... existing properties ...
    private let wahooData = WahooDataService.shared // NEW
    private let wahooAuth = WahooAuthService.shared // NEW
    
    func fetchRecentActivities(limit: Int = 100, daysBack: Int = 90) async throws -> [Activity] {
        var allActivities: [Activity] = []
        
        // 1. Fetch from Intervals.icu (if connected)
        if case .connected = intervalsOAuth.connectionState {
            let intervalsActivities = try await fetchFromIntervals(limit: limit, daysBack: daysBack)
            allActivities.append(contentsOf: intervalsActivities)
        }
        
        // 2. Fetch from Strava (if connected and no Intervals)
        else if case .connected = stravaAuth.connectionState {
            let stravaActivities = await fetchFromStrava(daysBack: daysBack)
            let converted = ActivityConverter.stravaToIntervals(stravaActivities)
            allActivities.append(contentsOf: converted)
        }
        
        // 3. NEW: Fetch from Wahoo (if connected)
        if case .connected = wahooAuth.connectionState {
            let wahooWorkouts = await wahooData.fetchWorkouts(daysBack: daysBack)
            let converted = ActivityConverter.wahooToIntervals(wahooWorkouts)
            allActivities.append(contentsOf: converted)
        }
        
        // 4. Deduplicate and sort
        let deduplicated = deduplicateActivities(allActivities)
        return deduplicated.sorted { $0.startDate > $1.startDate }
    }
    
    /// Deduplicate activities from multiple sources based on timestamp + duration
    private func deduplicateActivities(_ activities: [Activity]) -> [Activity] {
        var seen: Set<String> = []
        var unique: [Activity] = []
        
        for activity in activities {
            // Create dedup key: date + duration (within 60s tolerance)
            let dateKey = Int(activity.startDate.timeIntervalSince1970 / 60) // Round to minute
            let durationKey = (activity.movingTime ?? 0) / 60 // Round to minute
            let key = "\(dateKey)_\(durationKey)"
            
            if !seen.contains(key) {
                seen.insert(key)
                unique.append(activity)
            } else {
                Logger.debug("📊 Deduped activity: \(activity.name ?? "Unknown") at \(activity.startDate)")
            }
        }
        
        return unique
    }
}
```

### Phase 3C: View Integration

#### 6. Update UnifiedActivityCard
**File:** `VeloReady/Features/Today/Views/Components/UnifiedActivityCard.swift`

```swift
struct UnifiedActivityCard: View {
    let activity: UnifiedActivity
    
    var body: some View {
        if let intervalsActivity = activity.intervalsActivity {
            HapticNavigationLink(destination: RideDetailSheet(activity: intervalsActivity)) {
                SharedActivityRowView(activity: activity)
            }
        } else if let stravaActivity = activity.stravaActivity {
            HapticNavigationLink(destination: RideDetailSheet(activity: ActivityConverter.stravaToIntervals(stravaActivity))) {
                SharedActivityRowView(activity: activity)
            }
        } else if let wahooWorkout = activity.wahooWorkout { // NEW
            HapticNavigationLink(destination: RideDetailSheet(activity: ActivityConverter.wahooToIntervals(wahooWorkout))) {
                SharedActivityRowView(activity: activity)
            }
        } else if let healthWorkout = activity.healthKitWorkout {
            HapticNavigationLink(destination: WalkingDetailView(workout: healthWorkout)) {
                SharedActivityRowView(activity: activity)
            }
        }
    }
}
```

#### 7. Update SharedActivityRowView
**File:** Show Wahoo icon/badge

```swift
// In activity row, show source badge
if activity.source == .wahoo {
    Image(systemName: Icons.DataSource.wahoo)
        .foregroundColor(Color(DataSource.wahoo.brandColor))
}
```

### Phase 3D: Calculation Integration

#### 8. Update AthleteProfile.computeFromActivities
**File:** `VeloReady/Core/Models/AthleteProfile.swift`

```swift
func computeFromActivities(_ activities: [Activity]) async {
    // Existing: Fetch Strava activities
    let stravaActivities = await StravaDataService.shared.fetchActivitiesForZones()
    
    // NEW: Fetch Wahoo workouts
    let wahooWorkouts = await WahooDataService.shared.fetchWorkouts(daysBack: 365)
    let wahooConverted = ActivityConverter.wahooToIntervals(wahooWorkouts)
    
    // Merge all sources
    let mergedActivities = ActivityMerger.mergeWithLogging(
        strava: stravaActivities,
        intervals: activities,
        wahoo: wahooWorkouts // NEW parameter
    )
    
    // Continue with existing adaptive FTP/zones logic...
    await computeFTPFromPerformanceData(mergedActivities)
}
```

#### 9. Extend ActivityMerger
**File:** `VeloReady/Core/Utils/ActivityMerger.swift`

```swift
static func mergeWithLogging(
    strava: [StravaActivity],
    intervals: [Activity],
    wahoo: [WahooWorkout] // NEW
) -> [Activity] {
    // Convert all to Activity
    let stravaConverted = ActivityConverter.stravaToIntervals(strava)
    let wahooConverted = ActivityConverter.wahooToIntervals(wahoo)
    
    // Combine and dedupe
    let all = stravaConverted + intervals + wahooConverted
    return deduplicate(all)
}
```

### Phase 3E: Backend API

#### 10. Add Wahoo Workouts Endpoint
**NEW FILE:** `veloready-website/netlify/functions/api-wahoo-workouts.ts`

```typescript
export async function handler(event: HandlerEvent) {
  const userId = getUserIdFromAuth(event);
  const daysBack = parseInt(event.queryStringParameters?.days_back || '90');
  
  // Query wahoo_workouts table
  const db = new Client({ connectionString: process.env.DATABASE_URL });
  await db.connect();
  
  const result = await db.query(
    `SELECT * FROM wahoo_workouts 
     WHERE user_id = $1 
     AND started_at >= NOW() - INTERVAL '${daysBack} days'
     ORDER BY started_at DESC`,
    [userId]
  );
  
  await db.end();
  
  return {
    statusCode: 200,
    body: JSON.stringify(result.rows),
  };
}
```

#### 11. Update VeloReadyAPIClient
**File:** `VeloReady/Core/Networking/VeloReadyAPIClient.swift`

```swift
func fetchWahooWorkouts(userId: String, daysBack: Int) async throws -> [WahooWorkout] {
    let url = URL(string: "\(baseURL)/api/wahoo-workouts?days_back=\(daysBack)")!
    
    // Use provider-aware rate limiting
    let throttleResult = await RequestThrottler.shared.shouldAllowRequest(
        provider: .wahoo,
        endpoint: "workouts"
    )
    
    if !throttleResult.allowed {
        throw APIError.rateLimited
    }
    
    let data = try await networkClient.execute(request, provider: .wahoo)
    return try JSONDecoder().decode([WahooWorkout].self, from: data)
}
```

## Implementation Priority

### HIGH PRIORITY (Core Functionality)
1. ✅ WahooWorkout model
2. ✅ ActivityConverter.wahooToIntervals
3. ✅ WahooDataService
4. ✅ Backend api-wahoo-workouts endpoint
5. ✅ VeloReadyAPIClient.fetchWahooWorkouts
6. ✅ UnifiedActivityService integration
7. ✅ UnifiedActivity.wahooWorkout property

### MEDIUM PRIORITY (Calculations)
8. ✅ AthleteProfile Wahoo integration (Adaptive FTP)
9. ✅ ActivityMerger Wahoo support
10. ✅ TrainingLoadCalculator (already uses Activity, should work automatically)
11. ✅ RecoveryScoreService (already uses unified activities)
12. ✅ StrainScoreService (already uses unified activities)

### LOW PRIORITY (UI/Polish)
13. ✅ UnifiedActivityCard Wahoo support
14. ✅ SharedActivityRowView Wahoo badge
15. ✅ RideDetailSheet Wahoo indicators
16. ✅ Wahoo-specific detail views (optional, can use existing)
17. ✅ Power zones sync from Wahoo

## Testing Strategy

### Unit Tests
- `ActivityConverter.wahooToIntervals()` accuracy
- Deduplication logic with Wahoo + Strava + Intervals
- CTL/ATL calculations with Wahoo data

### Integration Tests
1. **OAuth → Data Sync**
   - Connect Wahoo
   - Verify workouts appear in activity list
   - Verify workouts are used in CTL/ATL

2. **Multi-Source Sync**
   - Connect Strava + Wahoo
   - Verify deduplication works
   - Verify no duplicate activities in list

3. **Adaptive FTP**
   - Connect Wahoo
   - Verify Wahoo power data used for FTP calculation
   - Verify power zones computed from Wahoo

4. **Recovery Score**
   - Verify Wahoo TSS contributes to recovery
   - Verify training load includes Wahoo

### Manual Testing Checklist
- [ ] Wahoo workouts appear in Today view
- [ ] Wahoo workouts appear in Activities list
- [ ] Tapping Wahoo workout opens detail view
- [ ] CTL/ATL chart includes Wahoo data
- [ ] Adaptive FTP uses Wahoo power data
- [ ] Power zones reflect Wahoo workouts
- [ ] Recovery score includes Wahoo TSS
- [ ] Strain score includes Wahoo activities
- [ ] Multi-source deduplication works
- [ ] Wahoo badge shows on activity cards

## Data Priority Strategy

When multiple sources are connected, priority should be:

1. **Intervals.icu** (most complete data, includes wellness)
2. **Wahoo** (native power/HR data, TSS)
3. **Strava** (social, GPS tracks, patterns only)
4. **Apple Health** (wellness, casual workouts)

**Deduplication Logic:**
- Match activities by timestamp (±2 minutes) and duration (±5%)
- Keep the version with most complete data (power > HR > GPS)
- Prefer Intervals > Wahoo > Strava > Apple Health

## Architecture Benefits

✅ **No Code Duplication** - Single converter per source
✅ **Unified Calculations** - All sources use same CTL/ATL/FTP logic
✅ **Transparent to Users** - Same UI regardless of source
✅ **Easy to Add More Sources** - Just add converter + service
✅ **Proper Deduplication** - Smart merging prevents duplicates

## Migration Path

### For Existing Users
1. User connects Wahoo (Phase 3 OAuth works)
2. Webhooks sync workout history to database
3. App fetches workouts via new API endpoint
4. Workouts appear alongside existing Strava/Intervals data
5. Calculations automatically include Wahoo (no manual action needed)

### For New Users
- Can start with Wahoo only
- Full app functionality works with just Wahoo
- Can add Strava/Intervals later for supplemental data

## Success Criteria

**Phase 3A Complete When:**
- [x] WahooWorkout model created
- [ ] ActivityConverter.wahooToIntervals works
- [ ] WahooDataService fetches from backend
- [ ] Backend API endpoint returns workouts
- [ ] UnifiedActivityService includes Wahoo

**Phase 3 Fully Complete When:**
- [ ] Wahoo workouts visible in app
- [ ] CTL/ATL includes Wahoo TSS
- [ ] Adaptive FTP uses Wahoo power
- [ ] Recovery/Strain use Wahoo data
- [ ] Deduplication tested with 2+ sources
- [ ] All manual tests pass

## Files to Create/Modify

### New Files (9)
1. `VeloReady/Core/Models/WahooWorkout.swift`
2. `VeloReady/Core/Services/Data/WahooDataService.swift`
3. `veloready-website/netlify/functions/api-wahoo-workouts.ts`

### Modified Files (8)
1. `VeloReady/Core/Models/UnifiedActivity.swift`
2. `VeloReady/Core/Utils/ActivityConverter.swift`
3. `VeloReady/Core/Utils/ActivityMerger.swift`
4. `VeloReady/Core/Services/Data/UnifiedActivityService.swift`
5. `VeloReady/Core/Models/AthleteProfile.swift`
6. `VeloReady/Core/Networking/VeloReadyAPIClient.swift`
7. `VeloReady/Features/Today/Views/Components/UnifiedActivityCard.swift`
8. `VeloReady/Features/Today/Views/Components/SharedActivityRowView.swift`

**Total:** 17 files (9 new, 8 modified)

## Estimated Effort

- **Phase 3A (Data Models):** 2-3 hours
- **Phase 3B (Services):** 2-3 hours
- **Phase 3C (Views):** 1-2 hours
- **Phase 3D (Calculations):** 1-2 hours
- **Phase 3E (Backend):** 1-2 hours
- **Testing:** 2-3 hours

**Total:** 9-15 hours

---

**Status:** Architecture Defined  
**Next Step:** Implement Phase 3A (Data Models)

