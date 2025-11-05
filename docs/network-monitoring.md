# Network Connectivity Monitoring

## Overview

VeloReady includes comprehensive network connectivity monitoring to detect when the device goes offline and inform users about their connection status. This feature enhances user experience by providing clear feedback when network operations may fail due to connectivity issues.

## Architecture

### NetworkMonitor Service

**Location**: `VeloReady/Core/Services/NetworkMonitor.swift`

The `NetworkMonitor` class is a `@MainActor` singleton that uses Apple's `Network` framework to monitor network connectivity changes in real-time.

**Key Features**:
- Singleton pattern for app-wide access
- Uses `NWPathMonitor` from Network framework for reliable connectivity detection
- Monitors connection state (connected/disconnected)
- Detects connection type (Wi-Fi, Cellular, Ethernet, etc.)
- Logs state transitions for debugging
- Background queue for network monitoring to avoid blocking main thread

**Published Properties**:
```swift
@Published private(set) var isConnected: Bool = true
@Published private(set) var connectionType: NWInterface.InterfaceType?
```

**Usage Example**:
```swift
@ObservedObject private var networkMonitor = NetworkMonitor.shared

var body: some View {
    if !networkMonitor.isConnected {
        Text("No internet connection")
    }
}
```

### OfflineBannerView Component

**Location**: `VeloReady/Features/Shared/Components/OfflineBannerView.swift`

A reusable SwiftUI component that displays an orange banner when the device is offline.

**Features**:
- Conditionally renders only when offline
- Smooth slide-in/slide-out animations
- Orange background for high visibility
- Shows Wi-Fi slash icon and "No internet connection" message
- Dismisses automatically when connection is restored

**Usage Example**:
```swift
@ObservedObject private var networkMonitor = NetworkMonitor.shared

var body: some View {
    NavigationStack {
        VStack(spacing: 0) {
            OfflineBannerView(networkMonitor: networkMonitor)
            // Your content here
        }
    }
}
```

## Integration Points

The network monitoring feature is integrated into the following key views:

### 1. TodayView (Dashboard)
**File**: `VeloReady/Features/Today/Views/Dashboard/TodayView.swift`

Shows offline banner at the top of the dashboard when network is unavailable.

### 2. ActivitiesView
**File**: `VeloReady/Features/Activities/Views/ActivitiesView.swift`

Displays offline banner when viewing activities list, informing users why data may not refresh.

## Testing

### Unit Tests

**Location**: `VeloReadyTests/Unit/NetworkMonitorTests.swift`

Comprehensive test suite covering:
- Initial state validation
- Singleton pattern verification
- Connection type detection (Wi-Fi, Cellular, Ethernet)
- Status description formatting
- Helper methods (isUsingCellular, isUsingWiFi)
- Start/stop monitoring lifecycle

**Run Tests**:
```bash
xcodebuild test -scheme VeloReady \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:VeloReadyTests/NetworkMonitorTests
```

**Test Results**: ✅ All 10 tests pass successfully

### Manual Testing Guide

#### Test 1: Offline Detection
1. Run the app on a physical device or simulator
2. Navigate to TodayView or ActivitiesView
3. Enable Airplane Mode
4. **Expected**:
   - Orange "No internet connection" banner appears at the top
   - Console logs: `⚠️ [NetworkMonitor] Network connection lost - device is offline`
   - Banner animates in smoothly from top edge

#### Test 2: Online Detection
1. While in Airplane Mode with banner visible
2. Disable Airplane Mode
3. **Expected**:
   - Orange banner disappears with smooth animation
   - Console logs: `✅ [NetworkMonitor] Network connection restored (Wi-Fi)` or `(Cellular)`
   - UI returns to normal state

#### Test 3: Connection Type Switching (Physical Device Only)
1. Connect to Wi-Fi
2. Verify app shows "Connected via Wi-Fi" in console
3. Disable Wi-Fi (Settings > Wi-Fi > Off)
4. **Expected**:
   - If cellular is available: Connection switches to Cellular
   - If no cellular: Offline banner appears
   - Console shows connection type transition

#### Test 4: Network Transitions During API Calls
1. Start loading activities (pull to refresh)
2. Immediately enable Airplane Mode mid-request
3. **Expected**:
   - Offline banner appears
   - Loading fails gracefully
   - User sees error message or cached data
   - No app crashes

## Implementation Details

### Thread Safety
- `NetworkMonitor` is isolated to `@MainActor` for UI updates
- Network path monitoring runs on dedicated background queue: `com.veloready.networkmonitor`
- All `@Published` property updates are dispatched to main actor

### State Management
```swift
monitor.pathUpdateHandler = { [weak self] path in
    Task { @MainActor in
        let nowConnected = path.status == .satisfied
        self.isConnected = nowConnected
        self.connectionType = self.determineConnectionType(from: path)
        self.logStateTransition(from: wasConnected, to: nowConnected, type: self.connectionType)
    }
}
```

### Connection Type Detection
Priority order:
1. Wi-Fi
2. Cellular
3. Wired Ethernet
4. Loopback
5. Other

### Logging
- **Info logs**: Connection state changes (online ↔ offline)
- **Debug logs**: Initial setup, monitoring lifecycle events
- **Warning logs**: Offline state transitions

## Utility Methods

```swift
// Check if using cellular (useful for data usage warnings)
let onCellular = networkMonitor.isUsingCellular

// Check if using Wi-Fi (useful for large downloads)
let onWiFi = networkMonitor.isUsingWiFi

// Get human-readable status description
let status = networkMonitor.statusDescription
// Returns: "Connected via Wi-Fi" or "Offline - No internet connection"
```

## Performance Considerations

- **Minimal Overhead**: NWPathMonitor is highly efficient and designed for continuous monitoring
- **Lazy Loading**: Monitor only starts when first accessed (singleton pattern)
- **Background Queue**: Network monitoring runs on utility QoS background queue
- **Immediate UI Updates**: State changes are batched and dispatched to main actor

## Future Enhancements

Potential improvements for future releases:

1. **Retry Logic Integration**: Automatically retry failed API requests when connection is restored
2. **Offline Mode**: Cache data locally and sync when online
3. **Data Usage Warnings**: Warn users before large downloads on cellular
4. **Connection Quality**: Monitor network quality/bandwidth, not just availability
5. **Reachability to Specific Hosts**: Check connectivity to api.veloready.app specifically

## Related Files

- `VeloReady/Core/Services/NetworkMonitor.swift` - Core monitoring service
- `VeloReady/Features/Shared/Components/OfflineBannerView.swift` - UI component
- `VeloReadyTests/Unit/NetworkMonitorTests.swift` - Unit tests
- `VeloReady/Features/Today/Views/Dashboard/TodayView.swift` - Integration point
- `VeloReady/Features/Activities/Views/ActivitiesView.swift` - Integration point

## References

- [Apple Network Framework](https://developer.apple.com/documentation/network)
- [NWPathMonitor Documentation](https://developer.apple.com/documentation/network/nwpathmonitor)
- [SwiftUI @Published Documentation](https://developer.apple.com/documentation/combine/published)

---

**Last Updated**: 2025-11-05
**Version**: 1.0.0
**Status**: ✅ Production Ready
