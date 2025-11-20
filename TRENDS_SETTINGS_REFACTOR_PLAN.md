# Trends & Settings Refactor: Comprehensive Analysis & Phased Approach

**Date:** 2025-11-20
**Branch:** `trends-settings-refactor`
**Status:** Planning Phase
**Author:** Analysis based on Today & Activities refactor patterns

---

## Executive Summary

This document provides a comprehensive analysis of the **Trends** and **Settings** pages in VeloReady, identifying architectural issues and proposing a phased refactoring approach based on the successful patterns established in the **Today** and **Activities** refactors.

### Key Findings

**Trends Page:**
- **834-line** TrendsViewModel + **1,153-line** WeeklyReportViewModel (God Objects)
- 21+ separate `@Published` properties causing over-rendering
- No data loading lifecycle (data never loads automatically)
- Duplicate data fetching between TrendsView and WeeklyReportView
- Business logic mixed with state management

**Settings Page:**
- **28 `@Published` properties** in UserSettings singleton (God Object)
- No validation layer for settings
- Bidirectional dependencies between services (AthleteZoneService ↔ UserSettings)
- Every property change triggers full UserDefaults serialization
- Scattered persistence across 13+ singleton services

### Refactoring Impact

| Metric | Before | After (Estimated) | Improvement |
|--------|--------|------------------|-------------|
| **Lines per ViewModel** | 834-1,153 | 200-400 | 55-65% reduction |
| **Published Properties** | 21-28 | 4-6 grouped | 75-80% reduction |
| **Services per Feature** | 6-13 scattered | 1-2 focused | 50-85% reduction |
| **Observation Overhead** | All properties | Targeted groups | ~70% reduction |
| **Test Coverage** | ~0% (untestable) | 80%+ (testable) | N/A |

---

## Part 1: Trends Page Analysis

### Current Architecture

```
┌─────────────────────────────────────────────────┐
│ VIEWS                                            │
├─────────────────────────────────────────────────┤
│ TrendsView (342 lines)                          │
│ ├─ @State private var viewModel = TrendsViewModel()
│ ├─ @ObservedObject proConfig, oauthManager      │
│ ├─ 40+ card components rendered                 │
│ └─ ⚠️ NO .task { await viewModel.load() }      │
│                                                  │
│ WeeklyReportView (140 lines)                    │
│ ├─ @State private var viewModel = WeeklyReportViewModel()
│ ├─ @State private var trendsViewModel = TrendsViewModel()  ⚠️ DUPLICATE
│ └─ Loads both ViewModels in parallel            │
└─────────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────┐
│ VIEW MODELS (GOD OBJECTS)                       │
├─────────────────────────────────────────────────┤
│ TrendsViewModel (834 lines) @Observable         │
│ ├─ 21 @Published properties                     │
│ ├─ 11 async data loaders                        │
│ ├─ 4 nested data models                         │
│ ├─ 7 mock data generators                       │
│ └─ Mixed: state + logic + mocking               │
│                                                  │
│ WeeklyReportViewModel (1,153 lines) @Observable │
│ ├─ 13 @Published properties                     │
│ ├─ 8 async data loaders                         │
│ ├─ 16 nested data structures                    │
│ ├─ AI API integration + caching                 │
│ ├─ Complex wellness calculations                │
│ └─ Direct Core Data access                      │
└─────────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────┐
│ SERVICES (Calculation + Data)                   │
├─────────────────────────────────────────────────┤
│ HealthKitManager                                 │
│ PersistenceController (Core Data)               │
│ IntervalsAPIClient                               │
│ UnifiedActivityService                           │
│ RecoveryScoreService                             │
│ AthleteProfileManager                            │
│ OvertrainingRiskCalculator (stateless)           │
│ TrainingPhaseDetector (stateless)                │
│ CorrelationCalculator (stateless)                │
└─────────────────────────────────────────────────┘
```

### Critical Issues

#### Issue 1: Data Never Loads Automatically

**File:** `TrendsView.swift` (Line 6)

```swift
struct TrendsView: View {
    @State private var viewModel = TrendsViewModel()
    // ⚠️ NO .task { await viewModel.loadTrendData() }
    // ⚠️ NO .onAppear { ... }

    var body: some View {
        // View renders but data never loads
    }
}
```

**Impact:** Trends page shows empty state because `loadTrendData()` is never called.

**Fix:** Add `.task { await viewModel.loadTrendData() }` to TrendsView.

---

#### Issue 2: Duplicate Data Loading

**File:** `WeeklyReportView.swift` (Lines 96-97)

```swift
struct WeeklyReportView: View {
    @State private var viewModel = WeeklyReportViewModel()
    @State private var trendsViewModel = TrendsViewModel()  // ⚠️ DUPLICATE

    var body: some View {
        // ...
        .task {
            await viewModel.loadWeeklyReport()
            await trendsViewModel.loadTrendData()  // ⚠️ Loads same data as TrendsView
        }
    }
}
```

**Impact:**
- Activities fetched **twice** (UnifiedActivityService called twice)
- CTL/ATL calculated **twice**
- Stress computed **twice**
- Unnecessary API calls and calculations

**Fix:** Share single TrendsViewModel instance or merge state management.

---

#### Issue 3: God Object - TrendsViewModel (834 lines)

**Responsibilities:**
1. State Management (21 `@Published` properties)
2. Data Aggregation (6 different services)
3. Data Transformation (7 different patterns)
4. Business Logic (correlation, phase detection, risk calculation, stress synthesis)
5. Mock Data Generation (7 methods)
6. Notification Management (NSNotificationCenter observer)

**Code Smell Indicators:**
- 21 published properties
- 11 private async methods for loading
- 7 private methods for mock data
- 4 nested data models defined in ViewModel

**Example:**
```swift
@Observable
final class TrendsViewModel {
    // State (21 properties)
    var selectedTimeRange: TimeRange
    var isLoading: Bool
    var errorMessage: String?
    var ftpTrendData: [TrendDataPoint]
    var recoveryTrendData: [TrendDataPoint]
    var hrvTrendData: [HRVTrendDataPoint]
    var weeklyTSSData: [WeeklyTSSDataPoint]
    var dailyLoadData: [TrendDataPoint]
    var sleepData: [TrendDataPoint]
    var restingHRData: [TrendDataPoint]
    var stressData: [TrendDataPoint]
    var activitiesForLoad: [Activity]
    var recoveryVsPowerData: [CorrelationDataPoint]
    var recoveryVsPowerCorrelation: CorrelationCalculator.CorrelationResult?
    var currentTrainingPhase: TrainingPhaseDetector.PhaseDetectionResult?
    var overtrainingRisk: OvertrainingRiskCalculator.RiskResult?
    // ... 4 more properties

    // Loading (11 methods mixing data fetch + transformation + business logic)
    private func loadFTPTrend() async
    private func loadRecoveryTrend() async
    private func loadHRVTrend() async
    private func loadWeeklyTSSTrend(_ activities: [Activity]) async
    private func loadDailyLoadTrend(_ activities: [Activity]) async
    private func loadSleepTrend() async
    private func loadRestingHRTrend() async
    private func loadStressTrend() async  // Complex 5-factor synthesis
    private func loadRecoveryVsPowerCorrelation(_ activities: [Activity]) async
    private func loadTrainingPhaseDetection() async
    private func loadOvertrainingRisk() async

    // Mock data (7 methods - should not be in ViewModel)
    private func generateMockFTPTrend() -> [TrendDataPoint]
    private func generateMockRecoveryTrend() -> [TrendDataPoint]
    // ... 5 more
}
```

**Fix:** Extract to TrendsDataLoader pattern (like Today/Activities refactors).

---

#### Issue 4: God Object - WeeklyReportViewModel (1,153 lines)

**Responsibilities:**
1. Weekly metrics calculation (7 different calculations)
2. Wellness score (6-factor weighted formula)
3. Sleep architecture analysis (complex HealthKit session grouping)
4. Circadian rhythm calculation (time arithmetic with 24-hour wrapping)
5. CTL/ATL historical data + projection
6. AI summary generation + caching
7. Training zone classification
8. Heatmap generation

**Tight Couplings:**
- Direct Core Data access (PersistenceController)
- Direct HTTP requests (should use service layer)
- HMAC signing via CryptoKit (should be in service)
- Keychain access (should be in service)
- Hardcoded API URL (should be in config)

**Example of Mixed Concerns:**
```swift
// Lines 843-935: AI Summary (Mixing: HTTP + Crypto + Caching + Business Logic)
private func fetchAISummary() async {
    // 1. Check Core Data cache
    let request: NSFetchRequest<DailyScores> = DailyScores.fetchRequest()
    // ... Core Data query

    // 2. Build AI payload
    let payload: [String: Any] = [
        "week_summary": determineWeekSummary(),
        "wellness_score": wellnessFoundation?.overall ?? 0,
        // ...
    ]

    // 3. Compute HMAC signature
    let signature = computeHMAC(data: payloadData, secret: apiSecret)

    // 4. Make HTTP request
    var request = URLRequest(url: URL(string: "https://veloready.app/.netlify/functions/weekly-report")!)
    request.addValue("Bearer \(signature)", forHTTPHeaderField: "Authorization")
    let (data, _) = try await URLSession.shared.data(for: request)

    // 5. Save to Core Data cache
    dailyScore.aiBriefText = aiText
    try? context.save()
}
```

**Fix:** Extract services:
- `AIGenerationService` for HTTP + HMAC
- `WellnessCalculationService` for wellness formula
- `SleepAnalysisService` for sleep architecture
- `CircadianRhythmService` for bedtime averaging

---

#### Issue 5: Observation Pattern Mismatch

**File:** `TrendsView.swift`, `WeeklyReportView.swift`

```swift
struct TrendsView: View {
    @State private var viewModel = TrendsViewModel()
    // ⚠️ @State wrapper on @Observable class is incorrect
    // Should be: let viewModel = TrendsViewModel()
}
```

**Problem:**
- `@State` is for value types, not needed with `@Observable` classes
- Mixing `@State` + `@ObservedObject` + `@Observable` creates inconsistency

**Fix:** Remove `@State` wrapper, use property directly.

---

#### Issue 6: No Loading State Management

**Current:**
```swift
var isLoading: Bool = false
var errorMessage: String?
```

**Problems:**
- Implicit loading state (boolean)
- No representation of different loading phases
- Error handling separated from state
- No cache vs fresh data distinction

**Refactored (from Today/Activities):**
```swift
enum TrendsLoadingPhase: Equatable {
    case notStarted
    case loading(progress: Double)  // 0.0 - 1.0 for 11 loaders
    case complete
    case error(Error)
    case refreshing

    var isLoading: Bool {
        switch self {
        case .loading, .refreshing: return true
        default: return false
        }
    }
}

@Published var phase: TrendsLoadingPhase = .notStarted
```

---

#### Issue 7: No Cache Strategy

**Current:**
- Core Data used for Recovery, Sleep (DailyScores entity)
- HealthKit queried fresh every time (HRV, RHR)
- Activities fetched fresh from UnifiedActivityService
- No cache-first loading pattern

**Refactored (Today pattern):**
```swift
func load() async {
    phase = .loading(progress: 0)

    // 1. Load cached data (instant)
    let cached = await loader.loadCachedTrends(timeRange: selectedTimeRange)
    scoresData = cached.scores
    fitnessData = cached.fitness

    // 2. Load fresh data (background)
    do {
        let fresh = try await loader.loadFreshTrends(timeRange: selectedTimeRange)
        scoresData = fresh.scores
        fitnessData = fresh.fitness
        phase = .complete
    } catch {
        phase = .error(error)
    }
}
```

---

### Proposed Refactoring: Trends

#### Architecture Pattern (Based on Today/Activities)

```
┌────────────────────────────────────────────────┐
│ VIEW (Simplified)                               │
├────────────────────────────────────────────────┤
│ TrendsView                                      │
│ └─ @ObservedObject var viewState = TrendsViewState.shared
│    └─ .task { await viewState.load() }         │
└────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│ STATE CONTAINER (Focused)                      │
├────────────────────────────────────────────────┤
│ TrendsViewState: ObservableObject               │
│ ├─ enum LoadingPhase (6 states)                │
│ ├─ @Published var phase: LoadingPhase          │
│ ├─ @Published var selectedTimeRange: TimeRange │
│ ├─ @Published var scoresData: TrendsScoresData?│
│ ├─ @Published var fitnessData: TrendsFitnessData?
│ ├─ @Published var analyticsData: TrendsAnalyticsData?
│ ├─ private let loader: TrendsDataLoader        │
│ └─ func load() async                            │
└────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│ DATA LOADER (All Loading Logic)                │
├────────────────────────────────────────────────┤
│ TrendsDataLoader                                │
│ ├─ Dependencies (DI):                           │
│ │  ├─ HealthKitManager                          │
│ │  ├─ UnifiedActivityService                    │
│ │  ├─ RecoveryScoreService                      │
│ │  └─ PersistenceController                     │
│ │                                                │
│ ├─ Data Transfer Objects:                       │
│ │  ├─ TrendsScoresData (recovery, hrv, rhr, sleep, stress)
│ │  ├─ TrendsFitnessData (ftp, weeklyTSS, dailyLoad, activities)
│ │  └─ TrendsAnalyticsData (correlation, phase, risk)
│ │                                                │
│ ├─ Public API:                                  │
│ │  ├─ loadCachedTrends() → TrendsBundle        │
│ │  ├─ loadFreshTrends() → TrendsBundle         │
│ │  └─ loadScores/loadFitness/loadAnalytics     │
│ │                                                │
│ └─ Private Loading Methods (extracted from VM):│
│    ├─ loadRecoveryTrend()                       │
│    ├─ loadHRVTrend()                            │
│    └─ ... (11 loaders)                          │
└────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│ CALCULATION SERVICES (Pure Functions)          │
├────────────────────────────────────────────────┤
│ OvertrainingRiskCalculator (stateless)          │
│ TrainingPhaseDetector (stateless)               │
│ CorrelationCalculator (stateless)               │
│ StressSynthesisCalculator (NEW - extract from VM)
└────────────────────────────────────────────────┘
```

#### Data Transfer Objects

```swift
// Group related data instead of 21 individual properties

struct TrendsScoresData {
    let recovery: [TrendDataPoint]
    let hrv: [HRVTrendDataPoint]
    let restingHR: [TrendDataPoint]
    let sleep: [TrendDataPoint]
    let stress: [TrendDataPoint]
}

struct TrendsFitnessData {
    let ftp: [TrendDataPoint]
    let weeklyTSS: [WeeklyTSSDataPoint]
    let dailyLoad: [TrendDataPoint]
    let activities: [Activity]
}

struct TrendsAnalyticsData {
    let recoveryVsPower: [CorrelationDataPoint]
    let recoveryVsPowerCorrelation: CorrelationCalculator.CorrelationResult?
    let trainingPhase: TrainingPhaseDetector.PhaseDetectionResult?
    let overtrainingRisk: OvertrainingRiskCalculator.RiskResult?
}

struct TrendsBundle {
    let scores: TrendsScoresData
    let fitness: TrendsFitnessData
    let analytics: TrendsAnalyticsData
}
```

#### Refactored ViewModel

```swift
@MainActor
final class TrendsViewState: ObservableObject {
    static let shared = TrendsViewState()

    // MARK: - Loading State

    enum LoadingPhase: Equatable {
        case notStarted
        case loading(progress: Double)
        case complete
        case error(Error)
        case refreshing

        static func == (lhs: LoadingPhase, rhs: LoadingPhase) -> Bool {
            switch (lhs, rhs) {
            case (.notStarted, .notStarted),
                 (.complete, .complete),
                 (.error, .error):
                return true
            case (.loading(let p1), .loading(let p2)):
                return p1 == p2
            case (.refreshing, .refreshing):
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Published State (6 properties instead of 21)

    @Published var phase: LoadingPhase = .notStarted
    @Published var selectedTimeRange: TimeRange = .days90
    @Published var lastUpdated: Date?

    @Published var scoresData: TrendsScoresData?
    @Published var fitnessData: TrendsFitnessData?
    @Published var analyticsData: TrendsAnalyticsData?

    // MARK: - Dependencies

    private let loader: TrendsDataLoader
    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.loader = TrendsDataLoader()
    }

    // MARK: - Public API

    func load() async {
        phase = .loading(progress: 0)

        // 1. Load cached data first (instant)
        if let cached = await loader.loadCachedTrends(timeRange: selectedTimeRange) {
            scoresData = cached.scores
            fitnessData = cached.fitness
            analyticsData = cached.analytics
        }

        // 2. Load fresh data
        do {
            let fresh = try await loader.loadFreshTrends(timeRange: selectedTimeRange)
            scoresData = fresh.scores
            fitnessData = fresh.fitness
            analyticsData = fresh.analytics

            phase = .complete
            lastUpdated = Date()
        } catch {
            phase = .error(error)
        }
    }

    func refresh() async {
        phase = .refreshing
        await load()
    }
}
```

#### Refactored Data Loader

```swift
@MainActor
final class TrendsDataLoader {

    // MARK: - Dependencies (Dependency Injection)

    private let healthKitManager: HealthKitManager
    private let unifiedActivityService: UnifiedActivityService
    private let recoveryScoreService: RecoveryScoreService
    private let persistence: PersistenceController
    private let profileManager: AthleteProfileManager

    init(
        healthKitManager: HealthKitManager = .shared,
        unifiedActivityService: UnifiedActivityService = .shared,
        recoveryScoreService: RecoveryScoreService = .shared,
        persistence: PersistenceController = .shared,
        profileManager: AthleteProfileManager = .shared
    ) {
        self.healthKitManager = healthKitManager
        self.unifiedActivityService = unifiedActivityService
        self.recoveryScoreService = recoveryScoreService
        self.persistence = persistence
        self.profileManager = profileManager
    }

    // MARK: - Public API

    func loadCachedTrends(timeRange: TrendsViewState.TimeRange) async -> TrendsBundle? {
        // Load from Core Data cache
        async let scores = loadCachedScores(timeRange: timeRange)
        async let fitness = loadCachedFitness(timeRange: timeRange)

        guard let scoresData = await scores,
              let fitnessData = await fitness else {
            return nil
        }

        return TrendsBundle(
            scores: scoresData,
            fitness: fitnessData,
            analytics: nil  // Analytics calculated fresh only
        )
    }

    func loadFreshTrends(timeRange: TrendsViewState.TimeRange) async throws -> TrendsBundle {
        // Fetch activities once and share
        let activities = try await unifiedActivityService.fetchRecentActivities(
            days: timeRange.days,
            includeHealthKit: true
        )

        // Load all categories in parallel
        async let scores = loadFreshScores(timeRange: timeRange)
        async let fitness = loadFreshFitness(timeRange: timeRange, activities: activities)
        async let analytics = loadAnalytics(timeRange: timeRange, activities: activities)

        return try await TrendsBundle(
            scores: scores,
            fitness: fitness,
            analytics: analytics
        )
    }

    // MARK: - Category Loaders

    private func loadFreshScores(timeRange: TrendsViewState.TimeRange) async throws -> TrendsScoresData {
        async let recovery = loadRecoveryTrend(timeRange: timeRange)
        async let hrv = loadHRVTrend(timeRange: timeRange)
        async let rhr = loadRestingHRTrend(timeRange: timeRange)
        async let sleep = loadSleepTrend(timeRange: timeRange)
        async let stress = loadStressTrend(timeRange: timeRange)

        return try await TrendsScoresData(
            recovery: recovery,
            hrv: hrv,
            restingHR: rhr,
            sleep: sleep,
            stress: stress
        )
    }

    private func loadFreshFitness(timeRange: TrendsViewState.TimeRange, activities: [Activity]) async throws -> TrendsFitnessData {
        async let ftp = loadFTPTrend()
        async let weeklyTSS = loadWeeklyTSSTrend(activities: activities, timeRange: timeRange)
        async let dailyLoad = loadDailyLoadTrend(activities: activities, timeRange: timeRange)

        return try await TrendsFitnessData(
            ftp: ftp,
            weeklyTSS: weeklyTSS,
            dailyLoad: dailyLoad,
            activities: activities
        )
    }

    private func loadAnalytics(timeRange: TrendsViewState.TimeRange, activities: [Activity]) async throws -> TrendsAnalyticsData {
        // Analytics from calculation services
        let correlation = await loadRecoveryVsPowerCorrelation(activities: activities)
        let phase = await loadTrainingPhaseDetection(timeRange: timeRange)
        let risk = await loadOvertrainingRisk(timeRange: timeRange)

        return TrendsAnalyticsData(
            recoveryVsPower: correlation.data,
            recoveryVsPowerCorrelation: correlation.result,
            trainingPhase: phase,
            overtrainingRisk: risk
        )
    }

    // MARK: - Individual Data Loaders (Extracted from TrendsViewModel)

    private func loadRecoveryTrend(timeRange: TrendsViewState.TimeRange) async throws -> [TrendDataPoint] {
        // Exact logic from TrendsViewModel.loadRecoveryTrend() lines 172-211
        // ...
    }

    private func loadHRVTrend(timeRange: TrendsViewState.TimeRange) async throws -> [HRVTrendDataPoint] {
        // Exact logic from TrendsViewModel.loadHRVTrend() lines 215-250
        // ...
    }

    // ... 9 more loader methods (extracted from TrendsViewModel)
}
```

---

## Part 2: Settings Page Analysis

### Current Architecture

```
┌──────────────────────────────────────────────────┐
│ VIEWS (32 files)                                 │
├──────────────────────────────────────────────────┤
│ SettingsView (768 lines)                         │
│ ├─ @StateObject userSettings = UserSettings.shared
│ ├─ @StateObject proConfig = ProFeatureConfig.shared
│ ├─ @State × 10 (sheet management)                │
│ └─ Renders 13 sections:                          │
│    ├─ ProfileSection                             │
│    ├─ GoalsSettingsSection                       │
│    ├─ SleepSettingsSection                       │
│    ├─ DataSourcesSection                         │
│    ├─ MLPersonalizationSection                   │
│    ├─ TrainingZonesSection                       │
│    ├─ DisplaySettingsSection                     │
│    ├─ NotificationSettingsSection                │
│    ├─ iCloudSection                              │
│    ├─ AccountSection                             │
│    ├─ AboutSection                               │
│    ├─ FeedbackSection                            │
│    └─ DebugSection                               │
│                                                   │
│ + 9 Detail Views (Settings screens)              │
│ + 5 Debug/Hidden Views                           │
└──────────────────────────────────────────────────┘
                     ↓
┌──────────────────────────────────────────────────┐
│ SINGLETONS (GOD OBJECTS)                         │
├──────────────────────────────────────────────────┤
│ UserSettings (451 lines, 28 @Published)          │
│ ├─ Sleep Settings (4 properties)                 │
│ ├─ Athletic Zones (10 properties)                │
│ ├─ Zone Configuration (3 properties)             │
│ ├─ Display Preferences (5 properties)            │
│ ├─ Goals (3 properties)                          │
│ ├─ Sport Preferences (1 property)                │
│ ├─ Notifications (2 properties)                  │
│ ├─ Every didSet → saveSettings()                 │
│ ├─ Every didSet → side effects (notifications, zones)
│ └─ Persists to UserDefaults (monolithic blob)    │
│                                                   │
│ ProFeatureConfig (30+ @Published flags)          │
│ NotificationManager (@ObservableObject)           │
│ AthleteZoneService (@ObservableObject)            │
│ iCloudSyncService (@ObservableObject)             │
│ ThemeManager                                      │
│ DataSourceManager                                 │
│ MLModelRegistry                                   │
│ + 6 more singletons                              │
└──────────────────────────────────────────────────┘
                     ↓
┌──────────────────────────────────────────────────┐
│ PERSISTENCE (Fragmented)                         │
├──────────────────────────────────────────────────┤
│ UserDefaults (multiple keys):                    │
│ ├─ "UserSettings" (28 properties as JSON)        │
│ ├─ "isProUser"                                   │
│ ├─ "bypassProForTesting"                         │
│ ├─ "iCloudSyncEnabled"                           │
│ └─ 20+ more individual keys                      │
│                                                   │
│ iCloud (NSUbiquitousKeyValueStore)               │
│ └─ Syncs UserSettings blob                       │
└──────────────────────────────────────────────────┘
```

### Critical Issues

#### Issue 1: God Object - UserSettings (28 @Published properties)

**File:** `UserSettings.swift` (451 lines)

```swift
@MainActor
class UserSettings: ObservableObject {
    static let shared = UserSettings()

    // ⚠️ 28 @Published properties, each with saveSettings() in didSet

    // Sleep (4 properties)
    @Published var sleepTargetHours: Double = 8.0 { didSet { saveSettings() } }
    @Published var sleepTargetMinutes: Int = 0 { didSet { saveSettings() } }
    @Published var sleepReminders: Bool = true {
        didSet {
            saveSettings()
            Task { @MainActor in
                await NotificationManager.shared.updateScheduledNotifications()  // Side effect!
            }
        }
    }
    @Published var sleepReminderTime: Date = ... {
        didSet {
            saveSettings()
            Task { @MainActor in
                await NotificationManager.shared.updateScheduledNotifications()  // Side effect!
            }
        }
    }

    // Athletic Zones (10 properties)
    @Published var hrZone1Max: Int = 120 { didSet { saveSettings() } }
    @Published var hrZone2Max: Int = 140 { didSet { saveSettings() } }
    @Published var hrZone3Max: Int = 160 { didSet { saveSettings() } }
    @Published var hrZone4Max: Int = 180 { didSet { saveSettings() } }
    @Published var hrZone5Max: Int = 200 { didSet { saveSettings() } }
    @Published var powerZone1Max: Int = 150 { didSet { saveSettings() } }
    @Published var powerZone2Max: Int = 200 { didSet { saveSettings() } }
    @Published var powerZone3Max: Int = 250 { didSet { saveSettings() } }
    @Published var powerZone4Max: Int = 300 { didSet { saveSettings() } }
    @Published var powerZone5Max: Int = 350 { didSet { saveSettings() } }

    // Zone Configuration (3 properties)
    @Published var zoneSource: String = "intervals" {
        didSet {
            saveSettings()
            applyZoneSource()  // ⚠️ Business logic in didSet
        }
    }
    @Published var freeUserFTP: Int = 200 {
        didSet {
            saveSettings()
            if zoneSource == "coggan" {
                applyCogganPowerZones()  // ⚠️ Cascading side effects
            }
        }
    }
    @Published var freeUserMaxHR: Int = 180 { didSet { saveSettings() } }

    // Display Preferences (5 properties)
    @Published var showSleepScore: Bool = true { didSet { saveSettings() } }
    @Published var showRecoveryScore: Bool = true { didSet { saveSettings() } }
    @Published var showHealthData: Bool = true { didSet { saveSettings() } }
    @Published var useMetricUnits: Bool = true { didSet { saveSettings() } }
    @Published var use24HourTime: Bool = true { didSet { saveSettings() } }

    // Goals (3 properties)
    @Published var calorieGoal: Double = 0.0 { didSet { saveSettings() } }
    @Published var useBMRAsGoal: Bool = true { didSet { saveSettings() } }
    @Published var stepGoal: Int = 10000 { didSet { saveSettings() } }

    // Sport Preferences (1 property)
    @Published var sportPreferences: SportPreferences = .default { didSet { saveSettings() } }

    // Notifications (1 property)
    @Published var recoveryAlerts: Bool = true { didSet { saveSettings() } }

    // ⚠️ Every property change triggers full UserDefaults write
    private func saveSettings() {
        guard !isLoading else { return }

        let settings = UserSettingsData(
            sleepTargetHours: sleepTargetHours,
            sleepTargetMinutes: sleepTargetMinutes,
            // ... encode all 28 properties
        )

        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "UserSettings")
        }
    }
}
```

**Problems:**
1. **God Object:** 28 properties in one class
2. **Side Effects:** Every didSet triggers I/O (saveSettings)
3. **Cascading Logic:** Some didSet blocks call other methods (applyZoneSource, applyCogganPowerZones)
4. **Notification Side Effects:** Some didSet blocks call NotificationManager
5. **No Validation:** Properties accept any value
6. **No Grouping:** Monolithic structure
7. **Performance:** Every property change encodes all 28 properties to UserDefaults

---

#### Issue 2: Bidirectional Dependencies

```
AthleteZoneService ─────────────┐
                                 ↓
                          UserSettings
                                 ↓
                    NotificationManager
```

**File:** `AthleteZoneService.swift` (Line 84)

```swift
private func updateUserSettingsWithZones(_ athlete: IntervalsAthlete) async {
    // ⚠️ Service directly modifies UserSettings
    userSettings.powerZone1Max = Int(zones[1])
    userSettings.powerZone2Max = Int(zones[2])
    userSettings.powerZone3Max = Int(zones[3])
    userSettings.powerZone4Max = Int(zones[4])
    userSettings.powerZone5Max = Int(zones[5])

    // Each assignment triggers:
    // 1. userSettings.didSet
    // 2. saveSettings() (5 UserDefaults writes!)
    // 3. iCloud sync notification
}
```

**File:** `UserSettings.swift` (Lines 115-118)

```swift
@Published var sleepReminders: Bool = true {
    didSet {
        saveSettings()
        Task { @MainActor in
            // ⚠️ UserSettings triggers NotificationManager
            await NotificationManager.shared.updateScheduledNotifications()
        }
    }
}
```

**Problems:**
- Circular dependencies between services
- Tight coupling makes testing impossible
- Changes ripple through multiple services
- No clear data flow

---

#### Issue 3: No Validation Layer

**Example:** Zone boundaries have no constraints

```swift
// UserSettings.swift
@Published var hrZone1Max: Int = 120  // Can be ANY Int
@Published var hrZone2Max: Int = 140  // Can be ANY Int
@Published var hrZone3Max: Int = 160  // Can be ANY Int

// Nothing enforces: hrZone1Max < hrZone2Max < hrZone3Max
// Nothing prevents: hrZone1Max = -100 or hrZone2Max = 999999
```

**UI enforces constraints, but domain doesn't:**

```swift
// GoalsSettingsView.swift (Line 21)
Stepper(value: $userSettings.stepGoal, in: 1000...30000, step: 500)
// UI: 1000-30000
// Domain: Any Int
```

**Missing:**
- Domain validation
- Constraint checking
- Dependency validation (e.g., coggan params only when zoneSource=="coggan")
- Pre-save validation

---

#### Issue 4: Fragmented Persistence

**Multiple UserDefaults Keys:**

```swift
// UserSettings.swift
UserDefaults.standard.set(encoded, forKey: "UserSettings")  // 28 properties

// ProFeatureConfig.swift
UserDefaults.standard.bool(forKey: "isProUser")
UserDefaults.standard.bool(forKey: "bypassProForTesting")

// iCloudSyncService.swift
UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")

// ThemeManager.swift
UserDefaults.standard.string(forKey: "selectedTheme")

// ... 20+ more individual keys across services
```

**Problems:**
- No centralized persistence layer
- No migration strategy
- No versioning
- Duplicate UserDefaults logic

---

#### Issue 5: ProfileViewModel Embedded in View

**File:** `ProfileView.swift` (Lines 195-265)

```swift
// ⚠️ ViewModel embedded in View file (not separated)
@MainActor
class ProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    // ... 6 more properties

    // ⚠️ Mixed responsibilities
    func loadProfile() {
        // 1. Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: profileKey) { ... }

        // 2. Fetch from AthleteProfileManager
        let athleteProfile = AthleteProfileManager.shared.profile

        // 3. Load profile photo from URL
        Task { await loadProfilePhoto(from: photoURL) }

        // 4. Query connected services
        loadConnectedServices()
    }

    private func loadProfilePhoto(from url: URL) async {
        // ⚠️ Direct URL image loading in ViewModel
        let (data, _) = try? await URLSession.shared.data(from: url)
        if let data = data, let image = UIImage(data: data) {
            await MainActor.run {
                self.avatarImage = image
            }
        }
    }
}
```

**Problems:**
- ViewModel not separated from View
- Mixed responsibilities (UserDefaults, API, image loading, service queries)
- No error handling
- Direct URLSession usage (should use service)

---

### Proposed Refactoring: Settings

#### Architecture Pattern (Based on Today/Activities)

```
┌──────────────────────────────────────────────────┐
│ VIEW (Simplified)                                 │
├──────────────────────────────────────────────────┤
│ SettingsView                                      │
│ └─ @ObservedObject var viewState = SettingsViewState.shared
│    └─ Renders sections based on viewState        │
└──────────────────────────────────────────────────┘
                     ↓
┌──────────────────────────────────────────────────┐
│ STATE CONTAINER (Focused, 4-5 groups)            │
├──────────────────────────────────────────────────┤
│ SettingsViewState: ObservableObject              │
│ ├─ enum LoadingPhase                             │
│ ├─ enum Sheet (sleep, zones, display, etc.)      │
│ ├─ @Published var phase: LoadingPhase            │
│ ├─ @Published var activeSheet: Sheet?            │
│ ├─ @Published var sleepSettings: SleepSettings   │
│ ├─ @Published var zoneSettings: ZoneSettings     │
│ ├─ @Published var displaySettings: DisplaySettings
│ ├─ @Published var profileSettings: ProfileSettings
│ ├─ private let loader: SettingsDataLoader        │
│ └─ func load() async                              │
│    func save(_ category: SettingsCategory) async │
└──────────────────────────────────────────────────┘
                     ↓
┌──────────────────────────────────────────────────┐
│ DATA LOADER (All Persistence Logic)              │
├──────────────────────────────────────────────────┤
│ SettingsDataLoader                                │
│ ├─ Dependencies (DI):                             │
│ │  ├─ UserDefaults                                │
│ │  ├─ NotificationManager                         │
│ │  ├─ AthleteZoneService                          │
│ │  └─ iCloudSyncService                           │
│ │                                                  │
│ ├─ Data Transfer Objects:                         │
│ │  ├─ SleepSettings (4 properties)                │
│ │  ├─ ZoneSettings (13 properties)                │
│ │  ├─ DisplaySettings (5 properties)              │
│ │  └─ ProfileSettings (6 properties)              │
│ │                                                  │
│ ├─ Load Operations:                               │
│ │  ├─ loadAllSettings() → SettingsBundle          │
│ │  ├─ loadSleepSettings() → SleepSettings         │
│ │  └─ ... (load each category)                    │
│ │                                                  │
│ ├─ Save Operations (Atomic):                      │
│ │  ├─ saveSleepSettings() throws                  │
│ │  ├─ saveZoneSettings() throws                   │
│ │  └─ ... (save each category)                    │
│ │                                                  │
│ └─ Validation:                                    │
│    ├─ validateSleepSettings() → [Error]           │
│    └─ validateZoneSettings() → [Error]            │
└──────────────────────────────────────────────────┘
```

#### Focused State Objects (Instead of UserSettings God Object)

```swift
// Group 1: Sleep Settings (4 properties)
struct SleepSettings: Codable, Equatable {
    let targetHours: Double
    let targetMinutes: Int
    let reminders: Bool
    let reminderTime: Date
}

// Group 2: Zone Settings (13 properties)
struct ZoneSettings: Codable, Equatable {
    let source: String  // "intervals", "coggan", "custom"
    let hrZones: [Int]  // 5 zones
    let powerZones: [Int]  // 5 zones
    let cogganFTP: Int
    let cogganMaxHR: Int

    // Validation
    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []

        // Check zone boundaries
        if hrZones[0] >= hrZones[1] {
            errors.append(.invalidZoneOrder("HR Zone 1 must be < Zone 2"))
        }
        // ... more validation

        return errors
    }
}

// Group 3: Display Settings (5 properties)
struct DisplaySettings: Codable, Equatable {
    let metricUnits: Bool
    let time24Hour: Bool
    let showSleep: Bool
    let showRecovery: Bool
    let showHealth: Bool
}

// Group 4: Profile Settings (6 properties)
struct ProfileSettings: Codable, Equatable {
    let name: String
    let email: String
    let age: Int
    let weight: Double
    let height: Int
    let avatar: Data?  // UIImage encoded as Data
}

// Group 5: Goals (3 properties)
struct GoalsSettings: Codable, Equatable {
    let calorieGoal: Double
    let useBMRAsGoal: Bool
    let stepGoal: Int
}

// Bundle
struct SettingsBundle {
    let sleep: SleepSettings
    let zones: ZoneSettings
    let display: DisplaySettings
    let profile: ProfileSettings
    let goals: GoalsSettings
}
```

#### Refactored ViewState

```swift
@MainActor
final class SettingsViewState: ObservableObject {
    static let shared = SettingsViewState()

    // MARK: - Loading State

    enum LoadingPhase: Equatable {
        case notStarted
        case loading
        case complete
        case error(Error)

        static func == (lhs: LoadingPhase, rhs: LoadingPhase) -> Bool {
            switch (lhs, rhs) {
            case (.notStarted, .notStarted),
                 (.loading, .loading),
                 (.complete, .complete),
                 (.error, .error):
                return true
            default:
                return false
            }
        }
    }

    enum Sheet: Identifiable {
        case sleep
        case zones
        case display
        case notifications
        case profile
        case goals

        var id: Self { self }
    }

    // MARK: - Published State (6 properties instead of 28)

    @Published var phase: LoadingPhase = .notStarted
    @Published var activeSheet: Sheet?

    @Published var sleepSettings: SleepSettings?
    @Published var zoneSettings: ZoneSettings?
    @Published var displaySettings: DisplaySettings?
    @Published var profileSettings: ProfileSettings?
    @Published var goalsSettings: GoalsSettings?

    // MARK: - Dependencies

    private let loader: SettingsDataLoader
    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.loader = SettingsDataLoader()
    }

    // MARK: - Public API

    func load() async {
        phase = .loading

        do {
            let bundle = try await loader.loadAllSettings()
            sleepSettings = bundle.sleep
            zoneSettings = bundle.zones
            displaySettings = bundle.display
            profileSettings = bundle.profile
            goalsSettings = bundle.goals

            phase = .complete
        } catch {
            phase = .error(error)
        }
    }

    func save(_ settings: SleepSettings) async throws {
        // Validate
        // No validation needed for sleep (simple properties)

        // Save
        try await loader.saveSleepSettings(settings)

        // Update local state
        sleepSettings = settings

        // Trigger side effects (notifications)
        await NotificationManager.shared.updateScheduledNotifications()
    }

    func save(_ settings: ZoneSettings) async throws {
        // Validate
        let errors = settings.validate()
        guard errors.isEmpty else {
            throw SettingsError.validationFailed(errors)
        }

        // Save
        try await loader.saveZoneSettings(settings)

        // Update local state
        zoneSettings = settings
    }
}
```

#### Refactored Data Loader

```swift
@MainActor
final class SettingsDataLoader {

    // MARK: - Dependencies (Dependency Injection)

    private let userDefaults: UserDefaults
    private let notificationManager: NotificationManager
    private let athleteZoneService: AthleteZoneService
    private let iCloudSyncService: iCloudSyncService

    init(
        userDefaults: UserDefaults = .standard,
        notificationManager: NotificationManager = .shared,
        athleteZoneService: AthleteZoneService = .shared,
        iCloudSyncService: iCloudSyncService = .shared
    ) {
        self.userDefaults = userDefaults
        self.notificationManager = notificationManager
        self.athleteZoneService = athleteZoneService
        self.iCloudSyncService = iCloudSyncService
    }

    // MARK: - Load Operations

    func loadAllSettings() async throws -> SettingsBundle {
        async let sleep = loadSleepSettings()
        async let zones = loadZoneSettings()
        async let display = loadDisplaySettings()
        async let profile = loadProfileSettings()
        async let goals = loadGoalsSettings()

        return try await SettingsBundle(
            sleep: sleep,
            zones: zones,
            display: display,
            profile: profile,
            goals: goals
        )
    }

    func loadSleepSettings() async -> SleepSettings {
        if let data = userDefaults.data(forKey: "SleepSettings"),
           let settings = try? JSONDecoder().decode(SleepSettings.self, from: data) {
            return settings
        }

        // Return defaults
        return SleepSettings(
            targetHours: 8.0,
            targetMinutes: 0,
            reminders: true,
            reminderTime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!
        )
    }

    func loadZoneSettings() async -> ZoneSettings {
        if let data = userDefaults.data(forKey: "ZoneSettings"),
           let settings = try? JSONDecoder().decode(ZoneSettings.self, from: data) {
            return settings
        }

        // Return defaults
        return ZoneSettings(
            source: "intervals",
            hrZones: [120, 140, 160, 180, 200],
            powerZones: [150, 200, 250, 300, 350],
            cogganFTP: 200,
            cogganMaxHR: 180
        )
    }

    // ... loadDisplaySettings, loadProfileSettings, loadGoalsSettings

    // MARK: - Save Operations (Atomic)

    func saveSleepSettings(_ settings: SleepSettings) async throws {
        let encoded = try JSONEncoder().encode(settings)
        userDefaults.set(encoded, forKey: "SleepSettings")

        // Sync to iCloud
        await iCloudSyncService.sync(key: "SleepSettings", value: encoded)
    }

    func saveZoneSettings(_ settings: ZoneSettings) async throws {
        let encoded = try JSONEncoder().encode(settings)
        userDefaults.set(encoded, forKey: "ZoneSettings")

        // Sync to iCloud
        await iCloudSyncService.sync(key: "ZoneSettings", value: encoded)
    }

    // ... saveDisplaySettings, saveProfileSettings, saveGoalsSettings

    // MARK: - Sync with External Services

    func syncZonesFromIntervals() async throws -> ZoneSettings {
        let athlete = try await athleteZoneService.fetchAthleteData()

        return ZoneSettings(
            source: "intervals",
            hrZones: athlete.hrZones,
            powerZones: athlete.powerZones,
            cogganFTP: 0,  // Not applicable
            cogganMaxHR: 0  // Not applicable
        )
    }
}
```

---

## Part 3: Phased Refactoring Plan

### Overview

Both **Trends** and **Settings** require significant refactoring to match the architectural patterns established in **Today** and **Activities**. The following phased approach balances impact, risk, and effort.

### Priority Matrix

| Feature | Impact | Complexity | Risk | Priority |
|---------|--------|------------|------|----------|
| **Trends Phase 1** | High | Medium | Low | **1** |
| **Settings Phase 1** | High | Medium | Medium | **2** |
| **Trends Phase 2** | Medium | Low | Low | **3** |
| **Settings Phase 2** | High | High | High | **4** |
| **Trends Phase 3** | Low | Low | Low | **5** |
| **Settings Phase 3** | Medium | Medium | Medium | **6** |

---

### Phase 1: Trends - Extract Data Loader

**Goal:** Extract all data loading logic from TrendsViewModel to TrendsDataLoader

**Impact:** High (reduces ViewModel from 834 to ~200 lines)
**Complexity:** Medium (straightforward extraction)
**Risk:** Low (pure function extraction)
**Effort:** 1-2 days

#### Tasks

1. **Create TrendsDataLoader.swift**
   - Define Data Transfer Objects (TrendsScoresData, TrendsFitnessData, TrendsAnalyticsData)
   - Move all 11 loading methods from TrendsViewModel to TrendsDataLoader
   - Add dependency injection for services
   - Implement `loadCachedTrends()` and `loadFreshTrends()`

2. **Refactor TrendsViewModel → TrendsViewState**
   - Reduce to 6 published properties (phase, timeRange, lastUpdated, scoresData, fitnessData, analyticsData)
   - Replace individual property loading with grouped loading
   - Add LoadingPhase enum
   - Implement cache-first loading strategy

3. **Fix Critical Bug**
   - Add `.task { await viewState.load() }` to TrendsView

4. **Test**
   - Verify all trend cards still render correctly
   - Verify cache-first loading improves performance
   - Run quick-test.sh

**Acceptance Criteria:**
- [ ] TrendsViewModel reduced to ~200 lines
- [ ] TrendsDataLoader created with 11 loading methods
- [ ] Data loads automatically when TrendsView appears
- [ ] All tests pass

**Files Modified:**
- `TrendsViewModel.swift` → `TrendsViewState.swift` (refactor)
- `TrendsDataLoader.swift` (new)
- `TrendsView.swift` (add .task)

---

### Phase 2: Trends - Service Layer Extraction

**Goal:** Extract business logic to dedicated services

**Impact:** Medium (improves testability)
**Complexity:** Low (simple extraction)
**Risk:** Low (stateless services)
**Effort:** 1 day

#### Tasks

1. **Create StressSynthesisService.swift**
   - Extract stress score calculation from TrendsViewModel.loadStressTrend()
   - 5-factor formula: recovery (30%), HRV (25%), RHR (20%), sleep (15%), load (10%)

2. **Create WellnessCalculationService.swift**
   - Extract wellness score from WeeklyReportViewModel.calculateWellnessFoundation()
   - 6-factor formula with conditional rebalancing

3. **Create SleepAnalysisService.swift**
   - Extract sleep architecture from WeeklyReportViewModel.loadSleepArchitecture()
   - Sleep session grouping (2-hour gap logic)
   - Sleep stage extraction

4. **Create CircadianRhythmService.swift**
   - Extract bedtime averaging from WeeklyReportViewModel.calculateCircadianRhythm()
   - Time arithmetic with 24-hour wrapping

5. **Create AIGenerationService.swift**
   - Extract AI summary from WeeklyReportViewModel.fetchAISummary()
   - HTTP request + HMAC signing + caching

6. **Update DataLoaders to use new services**

**Acceptance Criteria:**
- [ ] 5 new service classes created
- [ ] Business logic extracted from ViewModels
- [ ] All services have unit tests
- [ ] ViewModels call services instead of inline logic

**Files Created:**
- `StressSynthesisService.swift`
- `WellnessCalculationService.swift`
- `SleepAnalysisService.swift`
- `CircadianRhythmService.swift`
- `AIGenerationService.swift`

**Files Modified:**
- `TrendsDataLoader.swift`
- `WeeklyReportViewModel.swift`

---

### Phase 3: Trends - Eliminate Duplicate Loading

**Goal:** Remove duplicate TrendsViewModel instance from WeeklyReportView

**Impact:** Medium (improves performance)
**Complexity:** Low (remove duplicate)
**Risk:** Low (safe refactor)
**Effort:** 0.5 days

#### Tasks

1. **Remove duplicate TrendsViewModel from WeeklyReportView**
   - Delete `@State private var trendsViewModel = TrendsViewModel()`
   - Remove `await trendsViewModel.loadTrendData()` call

2. **Share TrendsViewState if needed**
   - If WeeklyReportView needs trend data, access `TrendsViewState.shared`
   - Otherwise, remove all trend loading from WeeklyReportView

3. **Test**
   - Verify no duplicate API calls
   - Verify weekly report still loads correctly

**Acceptance Criteria:**
- [ ] WeeklyReportView no longer instantiates TrendsViewModel
- [ ] No duplicate activity fetching
- [ ] All tests pass

**Files Modified:**
- `WeeklyReportView.swift`

---

### Phase 4: Settings - Extract Data Loader

**Goal:** Extract all persistence logic from UserSettings to SettingsDataLoader

**Impact:** High (enables focused state objects)
**Complexity:** High (28 properties, complex dependencies)
**Risk:** High (many services depend on UserSettings)
**Effort:** 2-3 days

#### Tasks

1. **Create Data Transfer Objects**
   - `SleepSettings.swift` (4 properties)
   - `ZoneSettings.swift` (13 properties + validation)
   - `DisplaySettings.swift` (5 properties)
   - `ProfileSettings.swift` (6 properties)
   - `GoalsSettings.swift` (3 properties)

2. **Create SettingsDataLoader.swift**
   - Load operations for each settings category
   - Save operations with validation
   - Atomic transactions (all or nothing)
   - Dependency injection for services

3. **Create SettingsViewState.swift**
   - 6 published properties (phase, activeSheet, 5 settings groups)
   - LoadingPhase enum
   - load() and save() methods

4. **Migrate UserDefaults keys**
   - Deprecate monolithic "UserSettings" key
   - Create individual keys per category
   - Implement migration for existing users

5. **Update views to use SettingsViewState**
   - Replace `@StateObject userSettings` with `@ObservedObject viewState`
   - Update bindings

6. **Break bidirectional dependencies**
   - AthleteZoneService no longer modifies UserSettings directly
   - AthleteZoneService returns ZoneSettings DTO
   - SettingsDataLoader coordinates the update

7. **Test extensively**
   - Verify all settings load correctly
   - Verify all settings save correctly
   - Verify migration from old format works
   - Run full test suite

**Acceptance Criteria:**
- [ ] UserSettings decomposed into 5 focused DTOs
- [ ] SettingsDataLoader handles all persistence
- [ ] SettingsViewState manages UI state
- [ ] No bidirectional dependencies
- [ ] All settings views updated
- [ ] Migration works for existing users
- [ ] All tests pass

**Files Created:**
- `SleepSettings.swift`
- `ZoneSettings.swift`
- `DisplaySettings.swift`
- `ProfileSettings.swift`
- `GoalsSettings.swift`
- `SettingsDataLoader.swift`
- `SettingsViewState.swift`

**Files Modified:**
- All 13 settings section views
- All 9 settings detail views
- `AthleteZoneService.swift`
- `NotificationManager.swift`

**Files Deprecated:**
- `UserSettings.swift` (gradually phased out)

---

### Phase 5: Settings - Profile Refactor

**Goal:** Extract ProfileViewModel and create ProfileDataLoader

**Impact:** Medium (improves profile loading)
**Complexity:** Medium (multiple data sources)
**Risk:** Medium (existing profile data)
**Effort:** 1 day

#### Tasks

1. **Create ProfileDataLoader.swift**
   - Define ProfileData DTO
   - Load from UserDefaults
   - Load from AthleteProfileManager
   - Load from Strava
   - Load profile photo
   - Atomic save operation

2. **Separate ProfileViewState.swift**
   - Move ViewModel out of ProfileView.swift
   - Use ProfileDataLoader

3. **Update ProfileView**
   - Use @StateObject ProfileViewState

4. **Test**
   - Verify profile loading works
   - Verify profile saving works
   - Verify photo loading works

**Acceptance Criteria:**
- [ ] ProfileDataLoader created
- [ ] ProfileViewState separated from View
- [ ] Profile loading and saving work correctly
- [ ] All tests pass

**Files Created:**
- `ProfileDataLoader.swift`
- `ProfileViewState.swift`

**Files Modified:**
- `ProfileView.swift`

---

### Phase 6: Settings - Validation Layer

**Goal:** Add validation for all settings

**Impact:** Medium (prevents invalid state)
**Complexity:** Medium (define validation rules)
**Risk:** Low (additive feature)
**Effort:** 1 day

#### Tasks

1. **Define validation rules**
   - Zone boundaries (zone1 < zone2 < zone3 < zone4 < zone5)
   - Goals (positive values, reasonable ranges)
   - Sleep (target hours 4-12, minutes 0-59)

2. **Implement validation in DTOs**
   - Add `validate()` method to each DTO
   - Return array of ValidationError

3. **Add validation to save operations**
   - SettingsDataLoader validates before saving
   - Throws ValidationError if invalid

4. **Show validation errors in UI**
   - Display error messages to user
   - Prevent save if validation fails

5. **Test validation**
   - Unit tests for all validation rules
   - UI tests for error display

**Acceptance Criteria:**
- [ ] All settings DTOs have validation
- [ ] Invalid settings cannot be saved
- [ ] Validation errors shown to user
- [ ] All tests pass

**Files Modified:**
- All DTO files (add validate methods)
- `SettingsDataLoader.swift`
- All settings detail views (add error handling)

---

## Part 4: Success Metrics

### Code Quality Metrics

| Metric | Before | Target | Improvement |
|--------|--------|--------|-------------|
| **Trends**|||
| ViewModel lines | 834 + 1,153 | 200 + 200 | 80% reduction |
| Published properties | 21 + 13 | 6 + 6 | 65% reduction |
| Test coverage | 0% | 80%+ | N/A |
| **Settings**|||
| UserSettings lines | 451 | Decomposed | N/A |
| Published properties | 28 | 5 groups | 82% reduction |
| Services per feature | 13 scattered | 2 focused | 85% reduction |
| Test coverage | 0% | 80%+ | N/A |

### Performance Metrics

| Metric | Before | Target |
|--------|--------|--------|
| Trends data load time | Unknown (never loads) | <500ms (cached) |
| Settings save time | 28 UserDefaults writes | 1 UserDefaults write |
| Over-rendering | Every property change | Only affected groups |

### Architecture Metrics

| Metric | Before | Target |
|--------|--------|--------|
| God Objects | 4 (TrendsVM, WeeklyReportVM, UserSettings, ProConfig) | 0 |
| Bidirectional deps | 3 | 0 |
| Tight couplings | Many | Minimal (DI) |
| Observation pattern | Mixed | Consistent |

---

## Part 5: Risk Mitigation

### High-Risk Areas

1. **Settings Migration**
   - **Risk:** Existing users lose settings data
   - **Mitigation:** Implement careful migration logic, test with production data snapshots

2. **Breaking Dependencies**
   - **Risk:** AthleteZoneService → UserSettings refactor breaks existing flows
   - **Mitigation:** Incremental refactor, maintain backward compatibility temporarily

3. **WeeklyReport AI Cache**
   - **Risk:** Refactoring breaks AI summary caching
   - **Mitigation:** Preserve cache key structure, test cache hit/miss scenarios

### Testing Strategy

1. **Unit Tests**
   - All DataLoaders (TrendsDataLoader, SettingsDataLoader, ProfileDataLoader)
   - All services (StressSynthesisService, WellnessCalculationService, etc.)
   - All DTOs (validation logic)

2. **Integration Tests**
   - Settings migration (old → new format)
   - Zone syncing (Intervals.icu → SettingsViewState)
   - Notification scheduling (Settings → NotificationManager)

3. **Manual Testing**
   - Test all 13 settings sections
   - Test all trend cards
   - Test weekly report
   - Test profile editing

---

## Part 6: Timeline

### Conservative Estimate (Sequential)

| Phase | Effort | Dependencies | Start | End |
|-------|--------|--------------|-------|-----|
| **Phase 1: Trends Data Loader** | 2 days | None | Day 1 | Day 2 |
| **Phase 2: Trends Services** | 1 day | Phase 1 | Day 3 | Day 3 |
| **Phase 3: Trends Dedup** | 0.5 days | Phase 1 | Day 4 | Day 4 |
| **Phase 4: Settings Data Loader** | 3 days | None | Day 5 | Day 7 |
| **Phase 5: Settings Profile** | 1 day | Phase 4 | Day 8 | Day 8 |
| **Phase 6: Settings Validation** | 1 day | Phase 4 | Day 9 | Day 9 |
| **Total** | **8.5 days** ||||

### Optimistic Estimate (Parallel)

If Phases 1-3 (Trends) and Phases 4-6 (Settings) can be done in parallel:

| Track | Effort | Timeline |
|-------|--------|----------|
| **Trends Track** | 3.5 days | Days 1-4 |
| **Settings Track** | 5 days | Days 1-5 |
| **Total** | **5 days** |(overlapping)|

---

## Part 7: Conclusion

Both **Trends** and **Settings** pages suffer from similar architectural issues:
- God Objects (large ViewModels with 20+ properties)
- Mixed responsibilities (state + logic + persistence)
- No separation of concerns
- Tight couplings and bidirectional dependencies
- Poor testability

The proposed refactoring follows the successful patterns established in **Today** and **Activities** refactors:
- **ViewState:** Focused state containers with 4-6 grouped properties
- **DataLoader:** All data loading/persistence logic extracted to service layer
- **DTOs:** Data Transfer Objects for clean boundaries
- **Dependency Injection:** Testable architecture
- **Loading Phases:** Explicit state management with enums
- **Cache-First:** Performance optimization

### Next Steps

1. **Review this document** with team
2. **Prioritize phases** based on business needs
3. **Start with Phase 1** (Trends Data Loader) - highest impact, lowest risk
4. **Iterate** through phases sequentially or in parallel
5. **Maintain tests** throughout refactor

### Questions for Discussion

1. Can Trends and Settings refactors proceed in parallel?
2. Should we prioritize Trends or Settings first?
3. Do we need to maintain backward compatibility with old UserDefaults keys?
4. Should we add telemetry to track migration success?
5. Should we feature-flag the refactored Settings behind a debug toggle initially?

---

**End of Document**
