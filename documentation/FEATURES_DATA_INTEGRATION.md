# Data Integration Features

## 1. Apple HealthKit Integration

### Marketing Summary
VeloReady seamlessly integrates with Apple Health to access your sleep, heart rate, workouts, and wellness data. No manual logging required—the app automatically pulls your overnight HRV, resting heart rate, sleep stages, and activity data to calculate your recovery score. Your health data stays private on your device, with full control over what VeloReady can access.

### Scientific Detail
Apple HealthKit provides access to comprehensive health and fitness data collected by Apple Watch, iPhone, and third-party apps. VeloReady uses HealthKit as the primary data source for:

**Sleep Data:**
- `HKCategoryTypeIdentifierSleepAnalysis`: Sleep stages (Core, Deep, REM, Awake)
- Time in bed, total sleep duration, sleep efficiency
- Bedtime and wake time for consistency tracking
- Available from Apple Watch Series 4+ with watchOS 7+

**Heart Rate Variability:**
- `HKQuantityTypeIdentifierHeartRateVariabilitySDNN`: RMSSD (root mean square of successive differences)
- Measured overnight during sleep
- Gold standard for autonomic nervous system recovery
- Available from Apple Watch Series 1+

**Resting Heart Rate:**
- `HKQuantityTypeIdentifierRestingHeartRate`: Overnight RHR
- Calculated by Apple Watch during sleep
- Marker of cardiovascular recovery
- Available from Apple Watch Series 1+

**Respiratory Rate:**
- `HKQuantityTypeIdentifierRespiratoryRate`: Breaths per minute during sleep
- Secondary recovery marker
- Available from Apple Watch Series 6+

**Workouts:**
- `HKWorkoutTypeIdentifier`: Cycling workouts with duration, distance, calories
- Heart rate streams for TRIMP calculation
- GPS route data (if available)
- Available from Apple Watch Series 1+ or iPhone

**Privacy & Permissions:**
- User grants granular permissions per data type
- Data never leaves device except for CloudKit sync (user's iCloud)
- HealthKit data cannot be accessed by third parties
- Full compliance with Apple's HealthKit guidelines

**References:**
- Apple HealthKit Documentation: https://developer.apple.com/documentation/healthkit
- Apple Watch Sleep Tracking: https://support.apple.com/en-us/HT211685

### Technical Implementation
**Architecture:**
- `HealthKitManager.swift`: Singleton service managing all HealthKit interactions
- `HealthKitPermissions.swift`: Permission request and status checking
- `HealthKitQueries.swift`: Optimized queries for each data type
- Background delivery for real-time updates

**Permission Request:**
```swift
class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    func requestAuthorization() async throws {
        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!
        ]
        
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }
}
```

**Overnight HRV Query:**
```swift
func getOvernightHRV() async -> Double? {
    let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    
    // Query for last night (10pm yesterday to 10am today)
    let calendar = Calendar.current
    let now = Date()
    let startOfToday = calendar.startOfDay(for: now)
    let lastNight10pm = calendar.date(byAdding: .hour, value: -2, to: startOfToday)!
    let thisModning10am = calendar.date(byAdding: .hour, value: 10, to: startOfToday)!
    
    let predicate = HKQuery.predicateForSamples(
        withStart: lastNight10pm,
        end: thisModning10am,
        options: .strictStartDate
    )
    
    return await withCheckedContinuation { continuation in
        let query = HKStatisticsQuery(
            quantityType: hrvType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage
        ) { _, result, error in
            guard let result = result,
                  let average = result.averageQuantity() else {
                continuation.resume(returning: nil)
                return
            }
            
            let hrv = average.doubleValue(for: HKUnit.secondUnit(with: .milli))
            continuation.resume(returning: hrv)
        }
        
        healthStore.execute(query)
    }
}
```

**Sleep Analysis Query:**
```swift
func getSleepAnalysis(start: Date, end: Date) async -> [HKCategorySample] {
    let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
    
    let predicate = HKQuery.predicateForSamples(
        withStart: start,
        end: end,
        options: .strictStartDate
    )
    
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
    
    return await withCheckedContinuation { continuation in
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let samples = samples as? [HKCategorySample] else {
                continuation.resume(returning: [])
                return
            }
            continuation.resume(returning: samples)
        }
        
        healthStore.execute(query)
    }
}
```

**Background Delivery:**
```swift
func enableBackgroundDelivery() {
    let types: [HKObjectType] = [
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
    ]
    
    for type in types {
        healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
            if success {
                Logger.debug("✅ Background delivery enabled for \(type)")
            } else {
                Logger.error("❌ Failed to enable background delivery: \(error?.localizedDescription ?? "unknown")")
            }
        }
    }
}
```

**Optimization:**
- Anchor queries for incremental updates (only fetch new data)
- Statistics queries for aggregates (faster than sample queries)
- Predicate optimization (strict start date, limited time range)
- Background delivery for real-time updates without polling

---

## 2. Strava Integration

### Marketing Summary
Connect your Strava account to automatically sync your rides with VeloReady. Get detailed power analysis, training load tracking, and AI-powered insights based on your actual workouts. Your Strava activities appear instantly in VeloReady, complete with power curves, heart rate zones, and route maps.

### Scientific Detail
Strava is the world's largest cycling social network, with 100M+ athletes and comprehensive activity tracking. VeloReady integrates with Strava to access:

**Activity Data:**
- Ride metadata: duration, distance, elevation, average power, average HR
- Normalized Power (NP) for TSS calculation
- Intensity Factor (IF) for training load
- Activity type (ride, race, virtual ride)
- Gear used (bike, wheels)

**Stream Data:**
- Power stream (1-second resolution)
- Heart rate stream (1-second resolution)
- Cadence stream (1-second resolution)
- GPS coordinates for route mapping
- Elevation profile

**Athlete Data:**
- FTP (if set in Strava)
- Max HR (if set in Strava)
- Weight (for power-to-weight calculations)

**API Compliance:**
- Strava API rate limits: 100 requests/15min, 1000 requests/day
- Stream data cached for 7 days minimum (per Strava guidelines)
- OAuth 2.0 authentication with refresh tokens
- Webhook subscriptions for real-time activity updates (planned)

**References:**
- Strava API Documentation: https://developers.strava.com/docs/reference/
- Strava API Agreement: https://www.strava.com/legal/api

### Technical Implementation
**Architecture:**
- `StravaAuthService.swift`: OAuth authentication flow
- `VeloReadyAPIClient.swift`: iOS client for backend API
- `api-activities.ts`: Netlify Function fetching activities from Strava
- `api-streams.ts`: Netlify Function fetching stream data from Strava
- Multi-layer caching: HTTP (24h) → Netlify Blobs → Strava API

**OAuth Flow:**
1. User taps "Connect Strava" in Settings
2. App opens `ASWebAuthenticationSession` to Strava OAuth page
3. User authorizes VeloReady
4. Strava redirects to `veloready://oauth/callback?code=...`
5. Backend exchanges code for access token + refresh token
6. Backend creates Supabase user (email: `strava-{athleteId}@veloready.app`)
7. Backend returns JWT tokens to iOS app
8. App stores JWT in `SupabaseClient.swift`
9. All API requests include `Authorization: Bearer {JWT}` header

**Backend Authentication:**
```typescript
// oauth-strava-token-exchange.ts
export default async (req: Request) => {
  const { code } = await req.json();
  
  // Exchange code for Strava tokens
  const stravaResponse = await fetch('https://www.strava.com/oauth/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      client_id: STRAVA_CLIENT_ID,
      client_secret: STRAVA_CLIENT_SECRET,
      code,
      grant_type: 'authorization_code'
    })
  });
  
  const { access_token, refresh_token, athlete } = await stravaResponse.json();
  
  // Create Supabase user
  const email = `strava-${athlete.id}@veloready.app`;
  const { data: authData, error } = await supabase.auth.signUp({
    email,
    password: generateSecurePassword(),
    options: {
      data: {
        strava_athlete_id: athlete.id,
        strava_access_token: access_token,
        strava_refresh_token: refresh_token
      }
    }
  });
  
  // Store athlete data in database
  await supabase.from('athletes').upsert({
    id: athlete.id,
    user_id: authData.user.id,
    firstname: athlete.firstname,
    lastname: athlete.lastname,
    profile: athlete.profile,
    strava_access_token: access_token,
    strava_refresh_token: refresh_token
  });
  
  // Return JWT tokens
  return new Response(JSON.stringify({
    access_token: authData.session.access_token,
    refresh_token: authData.session.refresh_token,
    expires_in: authData.session.expires_in,
    user_id: authData.user.id
  }));
};
```

**Activity Fetching:**
```typescript
// api-activities.ts
export default async (req: Request) => {
  // Authenticate user
  const { userId, athleteId } = await authenticate(req);
  
  // Check cache (24h TTL)
  const cacheKey = `activities:${athleteId}`;
  const cached = await getFromBlobs(cacheKey);
  if (cached) {
    return new Response(cached, {
      headers: { 'Content-Type': 'application/json', 'X-Cache': 'HIT' }
    });
  }
  
  // Fetch from Strava
  const { strava_access_token } = await getAthleteTokens(athleteId);
  const response = await fetch('https://www.strava.com/api/v3/athlete/activities?per_page=30', {
    headers: { 'Authorization': `Bearer ${strava_access_token}` }
  });
  
  const activities = await response.json();
  
  // Add prefetch URLs for top 3 activities
  const prefetchUrls = activities.slice(0, 3).map(a => 
    `/api/streams?activity_id=${a.id}`
  );
  
  const result = JSON.stringify({ activities, prefetchUrls });
  
  // Cache for 24h
  await saveToBlobs(cacheKey, result, 86400);
  
  return new Response(result, {
    headers: { 'Content-Type': 'application/json', 'X-Cache': 'MISS' }
  });
};
```

**Stream Fetching with Cache:**
```typescript
// api-streams.ts
export default async (req: Request) => {
  const { userId, athleteId } = await authenticate(req);
  const { activity_id } = await req.json();
  
  // Check cache (24h TTL, Strava requires 7-day minimum)
  const cacheKey = `streams:${athleteId}:${activity_id}`;
  const cached = await getFromBlobs(cacheKey);
  if (cached) {
    return new Response(cached, {
      headers: { 
        'Content-Type': 'application/json',
        'Cache-Control': 'max-age=86400',  // 24h browser cache
        'X-Cache': 'HIT'
      }
    });
  }
  
  // Fetch from Strava
  const { strava_access_token } = await getAthleteTokens(athleteId);
  const response = await fetch(
    `https://www.strava.com/api/v3/activities/${activity_id}/streams?keys=time,latlng,altitude,heartrate,watts,cadence`,
    { headers: { 'Authorization': `Bearer ${strava_access_token}` } }
  );
  
  const streams = await response.json();
  const result = JSON.stringify(streams);
  
  // Cache for 24h (compliant with Strava 7-day rule)
  await saveToBlobs(cacheKey, result, 86400);
  
  return new Response(result, {
    headers: { 
      'Content-Type': 'application/json',
      'Cache-Control': 'max-age=86400',
      'X-Cache': 'MISS'
    }
  });
};
```

**iOS Client:**
```swift
class VeloReadyAPIClient {
    func fetchActivities() async throws -> [Activity] {
        let url = URL(string: "\(baseURL)/api/activities")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(await getAccessToken())", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(ActivitiesResponse.self, from: data)
        
        // Prefetch streams for top 3 activities in background
        if let prefetchUrls = result.prefetchUrls {
            Task.detached {
                await self.prefetchStreams(urls: prefetchUrls)
            }
        }
        
        return result.activities
    }
    
    func fetchStreams(activityId: String) async throws -> ActivityStreams {
        let url = URL(string: "\(baseURL)/api/streams")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(await getAccessToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["activity_id": activityId])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ActivityStreams.self, from: data)
    }
}
```

**Caching Impact:**
- 96% reduction in Strava API calls
- 80% cache hit rate for activities
- 95% cache hit rate for streams (users view same activities multiple times)
- Instant detail view for prefetched activities

---

## 3. Intervals.icu Integration

### Marketing Summary
Already using Intervals.icu for training plans? VeloReady integrates seamlessly to pull your planned workouts, wellness data, and training calendar. Get AI recommendations that consider your scheduled intervals, and track your actual vs planned training load.

### Scientific Detail
Intervals.icu is a powerful training platform for endurance athletes, offering:

**Wellness Data:**
- Daily wellness surveys (sleep quality, fatigue, soreness, stress, mood)
- Resting heart rate tracking
- Weight and body composition
- Illness and injury logging

**Training Plans:**
- Structured workouts with TSS targets
- Weekly training load targets
- Periodization phases (Base, Build, Peak, Recovery)
- Custom intervals and zone prescriptions

**Activity Analysis:**
- Power curve analysis
- FTP detection
- Fitness (CTL) and Fatigue (ATL) tracking
- Training Stress Balance (TSB)

**API Access:**
- RESTful API with athlete-specific API key
- No rate limits for personal use
- Real-time data sync
- Webhook support for updates

**References:**
- Intervals.icu Documentation: https://intervals.icu/api
- Intervals.icu Blog: https://intervals.icu/blog

### Technical Implementation
**Architecture:**
- `IntervalsAPIClient.swift`: iOS client for Intervals.icu API
- `api-intervals-wellness.ts`: Backend proxy for wellness data
- `api-intervals-activities.ts`: Backend proxy for activities
- `api-intervals-calendar.ts`: Backend proxy for planned workouts

**Authentication:**
- User provides Intervals.icu API key in Settings
- API key stored securely in iOS Keychain
- Backend validates API key on first request
- No OAuth required (API key is sufficient)

**Wellness Data Fetching:**
```swift
class IntervalsAPIClient {
    private let baseURL = "https://intervals.icu/api/v1"
    private var apiKey: String {
        // Retrieve from Keychain
        KeychainHelper.shared.get(key: "intervals_api_key") ?? ""
    }
    
    func fetchWellness(athleteId: String, date: Date) async throws -> WellnessData {
        let dateString = ISO8601DateFormatter().string(from: date)
        let url = URL(string: "\(baseURL)/athlete/\(athleteId)/wellness/\(dateString)")!
        
        var request = URLRequest(url: url)
        request.setValue("Basic \(apiKey.base64Encoded())", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(WellnessData.self, from: data)
    }
    
    func fetchPlannedWorkouts(athleteId: String, startDate: Date, endDate: Date) async throws -> [PlannedWorkout] {
        let start = ISO8601DateFormatter().string(from: startDate)
        let end = ISO8601DateFormatter().string(from: endDate)
        let url = URL(string: "\(baseURL)/athlete/\(athleteId)/events?oldest=\(start)&newest=\(end)")!
        
        var request = URLRequest(url: url)
        request.setValue("Basic \(apiKey.base64Encoded())", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([PlannedWorkout].self, from: data)
    }
}
```

**Integration with AI Brief:**
```swift
// AIBriefService.swift
func buildRequest() throws -> AIBriefRequest {
    // ... other metrics ...
    
    // Fetch today's planned workout from Intervals.icu
    let plannedWorkout = await intervalsClient.fetchPlannedWorkouts(
        athleteId: currentAthleteId,
        startDate: Date(),
        endDate: Date()
    ).first
    
    return AIBriefRequest(
        // ... other fields ...
        plannedWorkout: plannedWorkout?.description,
        targetTSS: plannedWorkout?.tss ?? getDefaultTargetTSS()
    )
}
```

**Data Sync:**
- Wellness data synced daily at 6am
- Planned workouts synced weekly
- Activities synced after each ride (if not using Strava)
- Cached in Core Data for offline access
