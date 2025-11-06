# VeloReadyCore - Pure Calculation Engine

**Pure Swift calculation package for VeloReady - Zero iOS dependencies**

This Swift Package contains all core calculation logic for VeloReady's recovery, sleep, strain, baseline, and training load algorithms. Fully tested, platform-independent, and ready for reuse across iOS, backend, ML, widgets, and watch.

## ✅ Phase 1 Complete (Nov 2025)

Successfully extracted all core calculations from iOS app:
- **1,056 lines** of pure calculation logic
- **82 comprehensive tests** (all passing in <2 seconds)
- **39x faster** than iOS simulator tests
- **Zero dependencies** on UIKit, SwiftUI, or iOS frameworks
- **Production-ready** and fully documented

## 🎯 What's Included

### 1. Recovery Calculations (364 lines, 36 tests)
- HRV, RHR, Sleep, Training Load scoring
- Alcohol detection algorithm
- Recovery band determination

### 2. Sleep Calculations (195 lines, 14 tests)
- Performance, efficiency, stage quality scoring
- Disturbances and timing analysis
- Sleep band determination

### 3. Strain Calculations (303 lines, 20 tests)
- TRIMP and blended TRIMP (HR + Power)
- Whoop-style EPOC and strain formulas
- Cardio, strength, and non-exercise load scoring
- Recovery factor modulation

### 4. Baseline Calculations (92 lines, 6 tests)
- 7-day rolling averages for HRV, RHR, Sleep
- Sleep score and respiratory baselines

### 5. Training Load Calculations (102 lines, 6 tests)
- CTL (42-day chronic training load)
- ATL (7-day acute training load)
- TSB (training stress balance)

## Architecture

```
VeloReadyCore/
├── Sources/
│   └── VeloReadyCore.swift      # Core business logic (no UIKit/SwiftUI)
├── Tests/
│   └── VeloReadyCoreTests.swift # Tests that replicate production tests
└── Package.swift
```

## What Goes Here

**Include:**
- Training load calculations (CTL, ATL, TSS)
- Data models and structures
- Business logic and algorithms
- Networking layer and API clients
- Data processing and transformations
- Service layer logic

**Exclude:**
- SwiftUI views
- UIKit components
- View models that depend on UIKit/SwiftUI
- Device-specific features (Camera, GPS, etc.)

## Maintaining 1:1 Test Parity

To ensure this package accurately tests your production code:

1. **Extract core logic**: Move business logic from your main app to this package
2. **Replicate tests**: Copy relevant tests from `VeloReadyTests/Unit/` to `VeloReadyCore/Tests/`
3. **Keep in sync**: When you update production code, update this package
4. **Link in main app**: Import `VeloReadyCore` in your main iOS app

## 🧪 Running Tests

### Locally (Fast!)
```bash
cd VeloReadyCore
swift test  # 82 tests in <2 seconds
```

### In CI (GitHub Actions)
Tests run automatically on every push via the `ci.yml` workflow.

### Test Coverage
- **Recovery:** 36 tests covering all scoring components
- **Sleep:** 14 tests covering all sleep metrics
- **Strain:** 20 tests covering TRIMP, EPOC, sub-scores
- **Baseline:** 6 tests covering rolling averages
- **Training Load:** 6 tests covering CTL/ATL/TSB

**Total: 82 tests, 100% pass rate, <2 second execution**

## Adding New Tests

1. Add your test logic to `Tests/VeloReadyCoreTests.swift`
2. Use simple assertions with `print` statements
3. Return exit code 1 on failure, 0 on success

Example:
```swift
func testNewFeature() {
    let result = MyCalculator.calculate(input: 100)
    if result == 200 {
        print("✅ New feature test passed")
    } else {
        print("❌ New feature test failed: expected 200, got \(result)")
        exit(1)
    }
}
```

## 🔄 iOS App Integration

All core iOS services now delegate to VeloReadyCore:

```swift
// RecoveryScoreService.swift
import VeloReadyCore
let result = VeloReadyCore.RecoveryCalculations.calculateScore(inputs: coreInputs)

// SleepScoreService.swift
import VeloReadyCore
let result = VeloReadyCore.SleepCalculations.calculateScore(inputs: coreInputs)

// BaselineCalculator.swift
import VeloReadyCore
let baseline = VeloReadyCore.BaselineCalculations.calculateHRVBaseline(hrvValues: values)

// TrainingLoadCalculator.swift
import VeloReadyCore
let ctl = VeloReadyCore.TrainingLoadCalculations.calculateCTL(dailyTSS: tssValues)
```

iOS services handle data fetching from HealthKit, Strava, and Intervals.icu, then delegate all calculations to VeloReadyCore.

## 🚀 Reusability

VeloReadyCore is platform-independent and ready for:

### Current
- ✅ **iOS App** - All 4 core services integrated
- ✅ **Testing** - 39x faster than simulator tests

### Ready For
- 🔜 **Backend** - AI brief service can calculate recovery server-side
- 🔜 **ML Pipeline** - Training data uses same scoring algorithms
- 🔜 **Widgets** - Independent score calculations
- 🔜 **Apple Watch** - Same logic across devices
- 🔜 **macOS App** - Cross-platform consistency

## 📊 Performance

**Before Phase 1:**
- Tests require iOS simulator
- 78 second execution time
- Can't run on Linux/backend
- Duplicate logic across services

**After Phase 1:**
- Pure Swift tests (no simulator)
- <2 second execution time (39x faster)
- Runs anywhere Swift runs
- Single source of truth

## 📚 Documentation

See [PHASE1_FINAL_COMPLETE.md](../PHASE1_FINAL_COMPLETE.md) for complete Phase 1 details.

