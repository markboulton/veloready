# Enhanced Offline Banner UI

## Overview

The Enhanced Offline Banner is a production-ready UI component that provides clear visual feedback about network connectivity state in VeloReady. It displays different states (offline, syncing) with appropriate colors and auto-dismisses when connection is stable.

## Component Architecture

### OfflineBanner Component

**Location**: `VeloReady/Core/Components/OfflineBanner.swift`

A SwiftUI component that observes NetworkMonitor and displays connection state with smooth animations.

**Key Features**:
- **State-aware UI**: Shows different content for offline and syncing states
- **Auto-dismiss**: Automatically hides after 3 seconds when connection is restored
- **Smooth animations**: Slide-in/slide-out transitions with opacity
- **Color-coded states**:
  - Offline: `ColorScale.amberAccent` (amber/orange)
  - Syncing: `ColorScale.greenAccent` (green)
- **Network monitoring**: Observes `NetworkMonitor.shared.isConnected`

### UI States

#### 1. Offline State
**Trigger**: Device loses network connection
**Display**:
- Icon: `wifi.slash`
- Text: "No internet connection"
- Badge: "Offline"
- Color: Amber accent (warning color)
- Behavior: Visible until connection restored

#### 2. Syncing State
**Trigger**: Connection restored (offline → online transition)
**Display**:
- Icon: `arrow.triangle.2.circlepath` (sync icon)
- Text: "Syncing data"
- Badge: "Online"
- Color: Green accent (success color)
- Behavior: Auto-dismisses after 3 seconds

#### 3. Online State (Hidden)
**Trigger**: Connection is stable
**Display**: Banner is hidden
**Behavior**: No visual indicator needed

## Integration Points

The OfflineBanner is integrated into these key views:

### 1. TodayView (Dashboard)
**File**: `VeloReady/Features/Today/Views/Dashboard/TodayView.swift:46`
**Location**: Top of VStack, above all content
**Purpose**: Inform users when dashboard data may be stale

### 2. ActivitiesView
**File**: `VeloReady/Features/Activities/Views/ActivitiesView.swift:18`
**Location**: Top of VStack, above activity list
**Purpose**: Inform users when activity data cannot refresh

### 3. TrendsView
**File**: `VeloReady/Features/Trends/Views/TrendsView.swift:15`
**Location**: Top of VStack, above trends content
**Purpose**: Inform users when trend data cannot update

## Implementation Details

### State Management

```swift
@ObservedObject private var networkMonitor = NetworkMonitor.shared
@State private var showSyncingState = false
@State private var dismissTimer: Timer?
@State private var previousConnectionState = true
```

**State Transitions**:
- `networkMonitor.isConnected` → Drives offline state
- `showSyncingState` → Drives syncing state
- `dismissTimer` → Auto-dismiss after 3 seconds

### Connection Change Handler

```swift
private func handleConnectionChange(from oldValue: Bool, to newValue: Bool) {
    // Offline → Online: Show syncing state
    if !oldValue && newValue {
        showSyncingState = true
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation {
                showSyncingState = false
            }
        }
    }

    // Online → Offline: Show offline state
    if oldValue && !newValue {
        showSyncingState = false
        dismissTimer?.invalidate()
    }
}
```

### Animation

```swift
.animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
.animation(.easeInOut(duration: 0.3), value: showSyncingState)
.transition(.move(edge: .top).combined(with: .opacity))
```

**Animation Details**:
- Duration: 0.3 seconds
- Easing: ease-in-out curve
- Transition: Slide from top + fade in/out
- Triggers: Network state changes, syncing state changes

## Manual Testing Guide

### Test 1: Offline Detection
1. Launch VeloReady on device or simulator
2. Navigate to TodayView, ActivitiesView, or TrendsView
3. **Enable Airplane Mode** ✈️
4. **Expected Results**:
   - Amber banner slides in from top
   - Shows "No internet connection" with offline badge
   - Wi-Fi slash icon visible
   - Console logs: `📡 [OfflineBanner] Connection changed: true → false`
   - Console logs: `📡 [OfflineBanner] Connection lost, showing offline state`

### Test 2: Syncing State
1. While in Airplane Mode (offline banner visible)
2. **Disable Airplane Mode**
3. **Expected Results**:
   - Amber banner immediately transitions to green banner
   - Shows "Syncing data" with online badge
   - Circular sync icon visible
   - Console logs: `📡 [OfflineBanner] Connection changed: false → true`
   - Console logs: `📡 [OfflineBanner] Showing syncing state`
   - After 3 seconds: Banner slides out and disappears
   - Console logs: `📡 [OfflineBanner] Auto-dismissing syncing state`

### Test 3: Rapid Network Changes
1. Enable/Disable Airplane Mode rapidly (3-4 times within 10 seconds)
2. **Expected Results**:
   - Banner responds to each state change
   - No duplicate banners appear
   - Timer resets on each online transition
   - Animations are smooth, no jank

### Test 4: Banner Across Multiple Views
1. Start in TodayView with banner visible (offline)
2. Navigate to ActivitiesView
3. Navigate to TrendsView
4. **Expected Results**:
   - Banner visible at top of each view
   - State persists across navigation
   - Same styling and behavior on all screens

### Test 5: Banner Position
1. Open any view with OfflineBanner
2. Scroll content up and down
3. **Expected Results**:
   - Banner stays pinned at top (doesn't scroll)
   - Content scrolls beneath banner
   - Navigation bar appears/disappears normally
   - Banner doesn't interfere with pull-to-refresh

### Test 6: Background/Foreground Transitions
1. Enable Airplane Mode (banner visible)
2. Background the app (home button or swipe up)
3. Wait 5 seconds
4. Disable Airplane Mode
5. Bring app to foreground
6. **Expected Results**:
   - Banner should show syncing state briefly
   - Then auto-dismiss after 3 seconds
   - State correctly reflects current connectivity

## Color Specifications

### Offline State
```swift
ColorScale.amberAccent
// Hex: #F59E0B (amber-500)
// RGB: rgb(245, 158, 11)
// Usage: Warning state, non-critical issue
```

### Syncing State
```swift
ColorScale.greenAccent
// Hex: #10B981 (green-500)
// RGB: rgb(16, 185, 129)
// Usage: Success state, positive action
```

### Text & Icons
```swift
.foregroundColor(.white)
// Ensures high contrast on colored backgrounds
```

## Performance Considerations

### Memory & CPU
- **Minimal overhead**: Single NetworkMonitor observer
- **Efficient rendering**: Conditional rendering (only when needed)
- **Timer management**: Auto-cancels on state changes
- **Animation**: GPU-accelerated SwiftUI animations

### Battery Impact
- **Negligible**: NetworkMonitor already runs for app functionality
- **No polling**: Uses NWPathMonitor callbacks (event-driven)
- **Timer**: Only active for 3 seconds during syncing state

## Accessibility

### VoiceOver Support
```swift
// Future enhancement: Add accessibility labels
.accessibilityLabel("Network status: Offline")
.accessibilityLabel("Network status: Syncing")
```

### Dynamic Type
- Font sizes automatically scale with Dynamic Type
- Layout adjusts to larger text sizes

### Reduced Motion
```swift
// Future enhancement: Respect reduce motion preference
@Environment(\.accessibilityReduceMotion) var reduceMotion

.animation(reduceMotion ? nil : .easeInOut(duration: 0.3))
```

## Comparison with Previous Implementation

### OfflineBannerView (Old)
- ❌ Only showed offline state
- ❌ No syncing indicator
- ❌ Manual dismissal required
- ❌ Fixed orange color
- ❌ Required passing NetworkMonitor as parameter

### OfflineBanner (New)
- ✅ Shows offline AND syncing states
- ✅ Auto-dismisses after sync
- ✅ Color-coded states (amber/green)
- ✅ Self-contained (observes NetworkMonitor internally)
- ✅ Smooth animations with proper transitions

## Future Enhancements

Potential improvements for future releases:

1. **Queue Size Indicator**:
   ```swift
   if queueSize > 0 {
       Text("\(queueSize) pending")
   }
   ```

2. **Manual Retry Button**:
   ```swift
   Button("Retry") {
       // Trigger sync
   }
   ```

3. **Detailed Error Messages**:
   ```swift
   if let error = lastError {
       Text(error.localizedDescription)
   }
   ```

4. **Connection Type Badge**:
   ```swift
   if connectionType == .cellular {
       Image(systemName: "antenna.radiowaves.left.and.right")
   }
   ```

5. **Haptic Feedback**:
   ```swift
   UIImpactFeedbackGenerator(style: .light).impactOccurred()
   ```

## Troubleshooting

### Banner Doesn't Appear When Offline

**Problem**: Banner not visible despite no connectivity

**Solutions**:
1. Verify NetworkMonitor.shared.isConnected is false
2. Check OfflineBanner is added to view hierarchy
3. Ensure VStack(spacing: 0) has OfflineBanner at top
4. Check z-index / layering isn't hiding banner

### Banner Doesn't Auto-Dismiss

**Problem**: Green syncing banner stays visible indefinitely

**Solutions**:
1. Check timer is being created (dismissTimer not nil)
2. Verify timer isn't being invalidated prematurely
3. Check for memory leaks preventing timer callback
4. Look for console log: "Auto-dismissing syncing state"

### Banner Appears in Wrong Color

**Problem**: Colors don't match ColorScale.amberAccent or greenAccent

**Solutions**:
1. Verify ColorScale extension exists and is accessible
2. Check Dark Mode / Light Mode settings
3. Ensure color definitions match design system
4. Verify no color overrides in parent views

### Multiple Banners Appear

**Problem**: Banner duplicates or stacks

**Solutions**:
1. Ensure OfflineBanner only added once per view
2. Check for accidental nested VStacks with multiple banners
3. Verify conditional rendering logic (if/else)
4. Remove old OfflineBannerView references

## Related Files

- `VeloReady/Core/Components/OfflineBanner.swift` - Main component
- `VeloReady/Core/Services/NetworkMonitor.swift` - Network state detection
- `VeloReady/Features/Today/Views/Dashboard/TodayView.swift` - Integration (Today)
- `VeloReady/Features/Activities/Views/ActivitiesView.swift` - Integration (Activities)
- `VeloReady/Features/Trends/Views/TrendsView.swift` - Integration (Trends)
- `VeloReady/Features/Shared/Components/OfflineBannerView.swift` - Previous implementation (deprecated)

## Migration from OfflineBannerView

**Old Usage**:
```swift
@ObservedObject private var networkMonitor = NetworkMonitor.shared

OfflineBannerView(networkMonitor: networkMonitor)
```

**New Usage**:
```swift
// No need to observe NetworkMonitor in parent view
OfflineBanner()
```

**Migration Steps**:
1. Remove `@ObservedObject private var networkMonitor = NetworkMonitor.shared`
2. Replace `OfflineBannerView(networkMonitor: networkMonitor)` with `OfflineBanner()`
3. Ensure VStack(spacing: 0) wrapper exists
4. Build and test offline/online transitions

---

**Last Updated**: 2025-11-06
**Version**: 1.0.0
**Status**: ✅ Production Ready
