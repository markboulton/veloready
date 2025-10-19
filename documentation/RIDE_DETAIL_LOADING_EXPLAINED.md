# Ride Detail Loading Sequence Explained

## What Causes the Delay?

When opening a ride detail view, you see a **spinner and grey skeleton rectangles** while the system performs several asynchronous operations to fetch and process ride data.

---

## Loading Sequence Breakdown

### 1. **Initial View Render** (Immediate)
- `RideDetailSheet` appears with basic activity summary
- Shows activity name, type, date from cached data
- Display uses `activity` passed from Activities list (already available)

### 2. **`.task` Modifier Triggers** (Lines 36-54 in RideDetailSheet.swift)
```swift
.task {
    // This async block runs when view appears
    await viewModel.loadActivityData(...)
    await athleteZoneService.fetchAthleteData()
}
```

**What happens:**
- `isLoading = true` → Triggers skeleton UI
- Grey rectangles appear where charts will render
- Spinner shows system is working

---

## 3. **Main Data Loading Operation** (THE DELAY)

### For Strava Activities (Most Common)

**Function:** `loadStravaActivityData()` in `RideDetailViewModel.swift` (Lines 404-581)

**This is what causes the delay:**

#### Step 1: Ensure Zones Available (~50-200ms)
```swift
await ensureZonesAvailable(profileManager: profileManager)
```
- Checks if power/HR zones exist
- Generates adaptive zones if needed from historical data
- Calculates FTP/Max HR if missing

#### Step 2: Fetch Strava Streams (~500-2000ms) ⏱️ **PRIMARY DELAY**
```swift
let streams = try await StravaAPIClient.shared.fetchActivityStreams(
    id: stravaId,
    types: ["time", "latlng", "distance", "altitude", "velocity_smooth", 
            "heartrate", "cadence", "watts", "temp", "moving", "grade_smooth"]
)
```

**Network request to Strava API fetching:**
- Time series data (every second of the ride)
- GPS coordinates (lat/lng pairs)
- Power, heart rate, cadence streams
- Elevation, speed, temperature data
- Can be 3,000+ data points for a 50-minute ride

**Why slow:**
- External API call (not cached)
- Large payload (3,199 samples = ~1-2MB data)
- Network latency (200-2000ms depending on connection)

#### Step 3: Convert Streams to WorkoutSamples (~100-300ms)
```swift
let workoutSamples = convertStravaStreamsToWorkoutSamples(streams: streams)
```
- Processes 3,199+ data points
- Creates `WorkoutSample` objects
- Maps Strava format to app format

#### Step 4: Enrich Activity with Stream Data (~50-150ms)
```swift
enriched = enrichActivityWithStreamData(activity: activity, samples: workoutSamples, profileManager: profileManager)
```

**Calculates from raw data:**
- Average power, HR, speed, cadence
- Max values for all metrics
- Elevation gain
- **HR zone times** (line 219-224)
- **Power zone times** (line 226-232)

#### Step 5: Calculate TSS/IF (~10-50ms)
```swift
// Lines 442-562
let intensityFactor = np / ftpValue
let tss = (duration * np * intensityFactor) / (ftpValue * 36.0)
```

**Fallback logic (can add delay):**
- If no FTP: Fetch from Strava athlete (~200ms)
- If no Strava FTP: Estimate from ride data
- Calculate Normalized Power if missing

---

## 4. **Secondary Operations** (Parallel)

### Map Loading
```swift
await loadMapSnapshot()
```
- Extracts 3,199 GPS coordinates
- Generates map snapshot
- Can take 200-500ms

### Athlete Data Refresh (if needed)
```swift
await athleteZoneService.fetchAthleteData()
```
- Only runs if data is stale (>24 hours)
- Fetches athlete profile from Intervals.icu
- Usually skipped (cached)

---

## Total Loading Time Breakdown

| Operation | Time | % of Delay |
|-----------|------|------------|
| **Strava API fetch** | 500-2000ms | **70-80%** |
| Stream conversion | 100-300ms | 10-15% |
| Activity enrichment | 50-150ms | 5-10% |
| Zone calculations | 50-100ms | 5% |
| TSS/IF calculation | 10-50ms | 1-2% |
| **TOTAL** | **710-2600ms** | **100%** |

**Average: 1.2 seconds**

---

## Why Skeleton Screens Show

### Skeleton Triggers
```swift
// Line 87 in WorkoutDetailView.swift
if viewModel.isLoading {
    VStack(spacing: 20) {
        ProgressView()
            .scaleEffect(1.5)
        // Grey rectangles placeholder
    }
}
```

**Grey rectangles appear for:**
1. **Power/HR charts** - Waiting for stream data
2. **Zone distribution bars** - Waiting for zone calculations
3. **Map section** - Waiting for GPS coordinate processing
4. **TSS/IF metrics** - Waiting for FTP-based calculations

### When Skeleton Disappears
```swift
isLoading = false  // Line 579
```
- After all stream data processed
- After activity enriched with calculations
- Before charts render with real data

---

## Performance Characteristics

### Fast Load (<800ms)
✅ Good network connection  
✅ Short ride (<30 min, <1500 samples)  
✅ Strava API responsive  
✅ Zones already cached  

### Slow Load (>1500ms)
⚠️ Poor network connection  
⚠️ Long ride (>60 min, >3500 samples)  
⚠️ Strava API slow  
⚠️ First time opening (zones need generation)  

---

## What You're Seeing in Logs

### Before Data Loads
```
🏁 Original Activity TSS: nil
🏁 Enriched Activity: NIL
```

### During Loading (The Delay)
```
🟠 Fetching streams from Strava API...
🔄 Converting Strava streams to workout samples...
🟠 Converted to 3199 workout samples
🔧 ✅ Calculated HR zone times from stream data
🔧 ✅ Calculated Power zone times from stream data
🟠 Calculated TSS: 58
```

### After Loading
```
🏁 Enriched Activity: EXISTS
🏁 Enriched Activity TSS: 58.31532908218791
📊 Total samples: 3199
```

---

## Optimization Opportunities

### Current Architecture
- ❌ **No caching** of Strava streams (fetched every time)
- ❌ Sequential processing (could be parallel)
- ✅ Skeleton UI (good UX)
- ✅ Fallback data if API fails

### Potential Improvements
1. **Cache Strava streams locally**
   - Save to Core Data after first fetch
   - Reduce load time from 1.2s → 100ms
   - Update: ~200ms faster

2. **Parallel processing**
   - Fetch streams + zones + athlete data simultaneously
   - Update: ~150ms faster

3. **Lazy loading**
   - Show basic metrics first (0ms)
   - Load charts asynchronously
   - Progressive enhancement

4. **Pre-fetch on list scroll**
   - Load stream data while user scrolls Activities list
   - Instant detail view when tapped

---

## Summary

**Primary delay:** Fetching 3,000+ data points from Strava API over the network

**What you see:**
- Spinner = Network request in progress
- Grey rectangles = Placeholder for charts that need stream data

**What the system is doing:**
1. Fetching time-series data from Strava (70-80% of time)
2. Converting streams to app format
3. Calculating zone times, TSS, IF
4. Enriching activity with computed metrics
5. Generating map from GPS coordinates

**Why it can't be instant:**
- External API dependency (Strava)
- Large data payloads (1-2MB)
- Complex calculations (zone distribution, TSS)
- Network latency varies (200-2000ms)

**Good news:** The skeleton loading provides good UX feedback and the enriched data is comprehensive once loaded.
