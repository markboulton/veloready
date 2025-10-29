# Spinner Positioning & Onboarding Flash Fix

## Issues Fixed

### 1. ⚪ Spinner Vertical Positioning (FINAL: -16px)
**Problem**: Spinner in rings (Recovery, Sleep, Load) was positioned too low, not centered in the ring circle.

**Root Cause**: The `CompactRingView` includes a title label below the ring, which shifts the visual center. The spinner needs to be offset upward to appear centered within the ring itself.

**Solution**: Added `ZStack(alignment: .center)` and `.offset(y: -16)` to the `ProgressView` in all three ring views (adjusted from -18 to -16 based on user feedback).

```swift
ZStack(alignment: .center) {
    CompactRingView(
        score: nil, // Shows background ring only
        title: "",
        band: RecoveryScore.RecoveryBand.optimal,
        animationDelay: 0.0,
        action: {},
        centerText: nil,
        animationTrigger: animationTrigger
    )
    
    // Standard iOS spinner centered in ring
    ProgressView()
        .scaleEffect(1.2)
        .offset(y: -16) // Offset to visually center within ring circle
}
```

**Files Changed**:
- `VeloReady/Features/Today/Views/Dashboard/Sections/RecoveryMetricsSection.swift`

---

### 2. ⚡ Flash of Onboarding/Paywall/HealthKit Screens on Startup
**Problem**: Brief flash of onboarding screen, pro upsell screen, or HealthKit permission UI visible during app launch, even after completing onboarding/granting permissions.

**Root Cause**: 
- `OnboardingManager.hasCompletedOnboarding` was initialized to `false` by default, then read from UserDefaults in `init()`
- `ProFeatureConfig` subscription state properties were also initialized to default values, then loaded in `init()`
- `HealthKitManager.isAuthorized` and `authorizationState` were initialized to default values (`false` and `.notDetermined`), then updated asynchronously in `init()`
- This caused a brief moment where the UI rendered with incorrect default values before the actual cached values were loaded from UserDefaults or checked asynchronously

**Solution**: Load values **inline during property declaration** instead of in `init()`, ensuring the correct state is available **before** any views are created.

#### OnboardingManager Fix:
```swift
// BEFORE (caused flash)
@Published var hasCompletedOnboarding: Bool {
    didSet {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
    }
}

private init() {
    self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
}

// AFTER (no flash)
@Published var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
    didSet {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
    }
}

private init() {
    // Value already loaded inline above to prevent flash
}
```

#### ProFeatureConfig Fix:
```swift
// BEFORE (caused flash)
@Published var isProUser: Bool = false
@Published var isInTrialPeriod: Bool = false
@Published var trialDaysRemaining: Int = 0
@Published var bypassSubscriptionForTesting: Bool = false

private init() {
    loadSubscriptionState() // Loads from UserDefaults AFTER properties initialized
}

// AFTER (no flash)
@Published var isProUser: Bool = UserDefaults.standard.bool(forKey: "isProUser")
@Published var isInTrialPeriod: Bool = UserDefaults.standard.bool(forKey: "isInTrialPeriod")
@Published var trialDaysRemaining: Int = UserDefaults.standard.integer(forKey: "trialDaysRemaining")

#if DEBUG
@Published var bypassSubscriptionForTesting: Bool = UserDefaults.standard.bool(forKey: "bypassProForTesting")
#else
@Published var bypassSubscriptionForTesting: Bool = false
#endif

private init() {
    // Values already loaded inline above to prevent flash
    // loadSubscriptionState() can still be called to reload if needed
}
```

#### HealthKitManager Fix:
```swift
// BEFORE (caused flash)
@MainActor @Published var isAuthorized = false
@MainActor @Published var authorizationState: AuthorizationState = .notDetermined

private init() {
    Task { @MainActor in
        await checkAuthorizationStatusFast() // Updates properties asynchronously AFTER init
    }
}

// AFTER (no flash)
@MainActor @Published var isAuthorized: Bool = {
    // Quick inline check - cache the result to prevent flash
    let cached = UserDefaults.standard.bool(forKey: "healthKitAuthorized")
    return cached
}()

@MainActor @Published var authorizationState: AuthorizationState = {
    // Quick inline check - cache the result to prevent flash
    if let rawValue = UserDefaults.standard.value(forKey: "healthKitAuthState") as? Int,
       let state = AuthorizationState(rawValue: rawValue) {
        return state
    }
    return .notDetermined
}()

private init() {
    // Cached values already loaded inline above
    Task { @MainActor in
        await checkAuthorizationStatusFast() // Still runs, but UI starts with correct cached state
    }
}

// Also updated all setters to cache values:
func updateAuthorizationState(...) {
    // ... update properties ...
    
    // Cache the values to prevent flash on next app startup
    UserDefaults.standard.set(isAuthorized, forKey: "healthKitAuthorized")
    UserDefaults.standard.set(authorizationState.rawValue, forKey: "healthKitAuthState")
}
```

**Files Changed**:
- `VeloReady/Features/Onboarding/OnboardingManager.swift`
- `VeloReady/Core/Config/ProFeatureConfig.swift`
- `VeloReady/Core/Networking/HealthKitManager.swift`

---

## Impact

### Before:
- ❌ Spinner appeared below center of ring circles
- ❌ Brief flash of onboarding screen on every app launch (even after completing onboarding)
- ❌ Brief flash of pro upsell screen for pro users
- ❌ Brief flash of HealthKit permission UI for authorized users

### After:
- ✅ Spinner perfectly centered in ring circles
- ✅ No flash of onboarding screen - correct state loaded immediately
- ✅ No flash of paywall for pro users
- ✅ No flash of HealthKit permission UI - cached authorization state loaded immediately
- ✅ Smoother, more polished startup experience

---

## Technical Notes

### Why Inline Initialization Works
When you initialize a `@Published` property inline:
```swift
@Published var value: Bool = UserDefaults.standard.bool(forKey: "key")
```

The value is read **during property creation**, which happens **before** the class instance is fully initialized and **before** any views can observe it. This ensures:
1. No intermediate default state (like `false`)
2. First render uses correct cached value
3. No flash/flicker as state updates

### Why Init Loading Caused Flash
When you load in `init()`:
```swift
@Published var value: Bool = false // Default value visible first

init() {
    self.value = UserDefaults.standard.bool(forKey: "key") // Updated after
}
```

The sequence is:
1. Property created with default `false`
2. View can start observing (sees `false`)
3. `init()` updates to actual cached value
4. View updates (flash from `false` → `true`)

---

## Testing

To verify these fixes:
1. Complete onboarding flow
2. Force quit app
3. Relaunch app
4. ✅ Should show main app immediately, no flash of onboarding
5. ✅ Spinner in rings should be perfectly centered

---

## Related Files

### Spinner Positioning:
- `VeloReady/Features/Today/Views/Dashboard/Sections/RecoveryMetricsSection.swift`

### Flash Fix:
- `VeloReady/Features/Onboarding/OnboardingManager.swift` (onboarding state caching)
- `VeloReady/Core/Config/ProFeatureConfig.swift` (subscription state caching)
- `VeloReady/Core/Networking/HealthKitManager.swift` (authorization state caching)
- `VeloReady/App/VeloReadyApp.swift` (uses OnboardingManager)
- `VeloReady/Features/Today/Views/Dashboard/TodayView.swift` (uses ProFeatureConfig and HealthKitManager)

