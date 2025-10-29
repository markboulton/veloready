# VeloReadyCore - Business Logic Testing Package

This Swift Package contains the core business logic for VeloReady that can be tested on macOS without requiring iOS simulators.

## Purpose

The purpose of this package is to enable **fast, reliable CI testing** on GitHub Actions without the complexity and overhead of iOS simulators. By extracting pure business logic (no UIKit/SwiftUI dependencies) into this package, we can:

- ✅ Run tests on macOS in ~10 seconds instead of ~3-5 minutes with simulators
- ✅ Avoid simulator creation/booting failures on CI
- ✅ Get immediate feedback on core logic changes
- ✅ Test 1:1 replicas of production code

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

## Running Tests

### Locally
```bash
cd VeloReadyCore
swift run VeloReadyCoreTests
```

### In CI (GitHub Actions)
Tests run automatically on every push via the `ci.yml` workflow.

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

## Migration Plan

Over time, you can gradually move more core logic into this package:

1. **Phase 1** (Current): Simple test examples to prove the concept
2. **Phase 2**: Move `TrainingLoadCalculator` and tests
3. **Phase 3**: Move data models (`StravaActivity`, `HealthMetric`, etc.)
4. **Phase 4**: Move service layer logic (`UnifiedCacheManager`, etc.)
5. **Phase 5**: Move networking clients (without UI dependencies)

## Benefits

- **Speed**: Tests run in seconds instead of minutes
- **Reliability**: No simulator failures or timeout issues
- **Focus**: Tests only core business logic that matters most
- **Simplicity**: No complex CI configuration needed
- **Cost**: Faster CI means lower GitHub Actions costs

## Trade-offs

- **No UI testing**: This doesn't test SwiftUI views or UI interactions
- **Manual sync**: You need to keep this package in sync with main app
- **Initial setup**: Requires extracting logic into a separate package

For UI-specific tests, continue to use your local testing workflow with `./Scripts/quick-test.sh`.

