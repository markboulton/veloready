# @MainActor Audit - Performance Optimization Phase 3

## Executive Summary

**Goal:** Convert calculation-heavy services from `@MainActor class` to `actor` to prevent UI blocking.

**Current State:** 88 files with @MainActor annotation (136 matches)
- Services: 27 marked @MainActor
- ViewModels: ~15 marked @MainActor  
- Other: ~46 scattered uses

**Target:** Convert **20-25 calculation services** to actors
**Impact:** Heavy calculations will run on background threads, preventing UI freezes

---

## Priority 1: MUST CONVERT (Heavy Calculation Services)

These services perform CPU-intensive calculations and should NEVER block the UI thread.

### Score Calculation Services (3)
| Service | Current | Lines | Why Convert |
|---------|---------|-------|-------------|
| **RecoveryScoreService** | @MainActor class | ~1,130 | Heavy HRV/RHR/Sleep calculations, training load aggregation |
| **SleepScoreService** | @MainActor class | ~800 | Heavy sleep analysis, efficiency calculations |
| **StrainScoreService** | @MainActor class | ~490 | Heavy strain calculations, training load processing |

**Benefit:** These run on every app launch and can block UI for 2-5 seconds

### Detection Services (2)
| Service | Current | Lines | Why Convert |
|---------|---------|-------|-------------|
| **IllnessDetectionService** | @MainActor class | ~440 | Multi-day trend analysis, statistical calculations |
| **WellnessDetectionService** | @MainActor class | ~520 | Pattern matching, anomaly detection |

**Benefit:** Illness detection scans 30+ days of data, can block UI for 1-3 seconds

### Pure Calculation Classes (3)
| Service | Current | Lines | Why Convert |
|---------|---------|-------|-------------|
| **BaselineCalculator** | class (@unchecked Sendable) | ~290 | 7-day rolling averages, statistical calculations |
| **TrainingLoadCalculator** | class | ~423 | CTL/ATL calculations over 42 days |
| **TRIMPCalculator** | class | ~244 | Zone-based training impulse calculations |

**Benefit:** Already thread-safe with @unchecked Sendable, just need actor isolation

---

## Priority 2: SHOULD CONVERT (ML & Data Processing)

Heavy data processing that benefits from background execution.

### ML Services (7)
| Service | Current | Lines | Why Convert |
|---------|---------|-------|-------------|
| **MLPredictionService** | @MainActor class | ~380 | Heavy ML inference, model loading |
| **MLTrainingDataService** | @MainActor class | ~290 | Data aggregation across all sources |
| **HistoricalDataAggregator** | @MainActor class | ~320 | Aggregates 365+ days of historical data |
| **FeatureEngineer** | @MainActor class | ~410 | Feature extraction and transformation |
| **MLDatasetBuilder** | @MainActor class | ~240 | Dataset building, outlier removal |
| **MLModelTrainer** | @MainActor class | ~190 | Model training (very heavy) |
| **PersonalizedRecoveryCalculator** | @MainActor class | ~150 | Orchestrates ML predictions |

**Benefit:** ML operations can take 5-10 seconds, completely blocking UI

### ML Registry & Telemetry (2)
| Service | Current | Lines | Why Convert |
|---------|---------|-------|-------------|
| **MLModelRegistry** | @MainActor class | ~320 | Model management, version control |
| **MLTelemetryService** | @MainActor class | ~180 | Metric aggregation, logging |

---

## Priority 3: OPTIONAL (Lighter Operations)

Could benefit from actor isolation but lower impact.

### Activity Processing (3)
| Service | Current | Lines | Why Convert |
|---------|---------|-------|-------------|
| **UnifiedActivityService** | @MainActor class | ~180 | API calls (already async), light processing |
| **ActivityDeduplicationService** | @MainActor class | ~240 | Deduplication logic across 3 sources |
| **ActivityDataTransformer** | @MainActor struct | ~150 | Time-series transformations |

**Note:** UnifiedActivityService is ObservableObject for caching, might need special handling

---

## MUST STAY @MainActor (UI-Dependent)

These services interact with UI frameworks or publish to UI and CANNOT be converted.

### ObservableObject Services (UI State Management)
- **AIBriefService** - Publishes brief text to UI
- **AthleteZoneService** - Publishes zone settings to UI
- **DataSourceManager** - Manages data source UI state
- **LiveActivityService** - Publishes calorie/step counts to UI
- **LoadingStateManager** - Manages loading spinners
- **NetworkMonitor** - Publishes network status to UI
- **RideSummaryService** - Publishes ride summaries to UI
- **SleepDebtService** - Publishes sleep debt to UI
- **StravaDataService** - Publishes Strava activities to UI
- **SubscriptionManager** - StoreKit requires main thread
- **TrainingLoadService** - Publishes CTL/ATL to UI
- **VO2MaxTrackingService** - Publishes VO2Max trends to UI
- **iCloudSyncService** - NSUbiquitousKeyValueStore requires main thread
- **RecoverySleepCorrelationService** - Publishes correlation data to UI
- **ReadinessForecastService** - Publishes forecast data to UI

### Authentication Services (ASWebAuth requires main thread)
- **StravaAuthService** - ASWebAuthenticationSession requires main thread
- **IntervalsOAuthManager** - OAuth flows require main thread

### Location/Maps (Main thread required)
- **MapSnapshotService** - MKMapSnapshotter requires main thread
- **LocationGeocodingService** - CLGeocoder works better on main thread
- **ActivityLocationService** - Location services

### Notification/Storage (Mixed requirements)
- **NotificationManager** - UNUserNotificationCenter prefers main thread
- **RPEStorageService** - Core Data operations
- **WorkoutMetadataService** - Core Data operations

---

## Conversion Pattern

### Before (Current Pattern):
```swift
@MainActor
class RecoveryScoreService: ObservableObject {
    @Published var currentRecoveryScore: RecoveryScore?
    
    func calculateRecoveryScore() async {
        // Heavy calculation blocks main thread!
        let score = performHeavyCalculation()
        currentRecoveryScore = score
    }
}
```

### After (Actor Pattern):
```swift
actor RecoveryScoreService {
    // Published properties stay on main actor
    @MainActor @Published var currentRecoveryScore: RecoveryScore?
    
    // Heavy calculation runs on background thread
    nonisolated func calculateRecoveryScore() async {
        let score = await performHeavyCalculation()
        
        // Only touch main thread for UI update
        await MainActor.run {
            currentRecoveryScore = score
        }
    }
    
    // Private calculation method runs in actor context
    private func performHeavyCalculation() async -> RecoveryScore {
        // Heavy work happens here on background thread
    }
}
```

---

## Conversion Order (Recommended)

### Phase 3a: Score Services (Week 1)
1. ✅ RecoveryScoreService
2. ✅ SleepScoreService  
3. ✅ StrainScoreService

### Phase 3b: Calculators (Week 1)
4. ✅ BaselineCalculator
5. ✅ TrainingLoadCalculator
6. ✅ TRIMPCalculator

### Phase 3c: Detection Services (Week 2)
7. ✅ IllnessDetectionService
8. ✅ WellnessDetectionService

### Phase 3d: ML Services (Week 2-3)
9. ✅ MLPredictionService
10. ✅ HistoricalDataAggregator
11. ✅ FeatureEngineer
12. ✅ MLDatasetBuilder
13. ✅ MLModelTrainer
14. ✅ MLTrainingDataService
15. ✅ PersonalizedRecoveryCalculator

### Phase 3e: ML Infrastructure (Week 3)
16. ✅ MLModelRegistry
17. ✅ MLTelemetryService

### Phase 3f: Optional (Week 4)
18. ActivityDeduplicationService
19. ActivityDataTransformer
20. UnifiedActivityService (needs careful ObservableObject handling)

---

## Testing Strategy

### After Each Conversion:
1. **Build**: Must compile without errors
2. **Unit Tests**: Run `./Scripts/quick-test.sh` (60-90s)
3. **Manual Test**: Launch app, verify score calculations work
4. **Performance**: Verify UI doesn't freeze during calculations

### Key Test Cases:
- App launch (score calculation shouldn't block UI)
- Pull-to-refresh on Today view
- Opening detail views
- ML training (very heavy, should run in background)

---

## Performance Metrics (Expected Improvements)

### Current State (All @MainActor):
- App launch: 3-5 second freeze while scores calculate
- Recovery calculation: 2-3 second UI freeze
- ML training: 10-15 second UI freeze
- Illness detection: 1-2 second UI freeze

### Target State (Actors):
- App launch: No UI freeze, scores appear progressively
- Recovery calculation: No UI freeze, instant feedback
- ML training: No UI freeze, progress indicators work
- Illness detection: No UI freeze, background processing

**Target:** Eliminate all UI freezes >100ms caused by calculations

---

## Implementation Notes

### Key Challenges:
1. **ObservableObject**: Services with @Published properties need special handling
2. **Singleton Access**: `static let shared` works with actors
3. **Dependencies**: Services calling each other need actor isolation boundaries
4. **Core Data**: PersistenceController access might need main thread
5. **HealthKit**: Some HealthKit operations prefer main thread

### Solutions:
1. Keep @Published properties with @MainActor annotation
2. Use `await` for actor-isolated calls
3. Use `nonisolated` for calculation methods
4. Wrap Core Data in `MainActor.run {}` when needed
5. Test HealthKit operations on background threads

---

## Summary

**Total Services to Convert: 20-25**
- Priority 1 (Must): 8 services
- Priority 2 (Should): 9 services  
- Priority 3 (Optional): 3 services

**Expected Impact:**
- ✅ Eliminate all calculation-related UI freezes
- ✅ App launch becomes responsive immediately
- ✅ Heavy ML operations don't block UI
- ✅ Better battery life (efficient thread usage)
- ✅ Smoother user experience

**Risk Level: Low**
- Incremental conversion (one service at a time)
- Full test suite after each change
- Easy rollback if issues found
- Pattern is well-established in Swift concurrency
