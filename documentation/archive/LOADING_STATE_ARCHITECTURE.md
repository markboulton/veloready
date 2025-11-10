# Loading State Architecture - Implementation Plan

## Overview
Implement Apple Mail-style loading status feedback for VeloReady app startup and data refresh.

---

## 🎯 User Experience Flow

### Initial Startup (0-2 seconds)
```
1. App launches
2. Animated rings appear (logo/splash)
3. Background work begins
4. At 2s: Transition to main UI (even if not ready)
```

### Main UI Loading (2s+)
```
1. UI appears with grey rings
2. "Today" heading visible
3. Loading status text appears below heading:
   - "Calculating scores..."
   - "Contacting Strava..."
   - "Downloading activities..."
   - "Processing data..."
   - [Done - text fades out]
4. Rings fill in as scores become available
5. State labels appear when scores ready
```

### Error States
```
1. Network error: "Unable to reach Strava. Tap to retry."
2. Auth error: "Strava connection expired. Tap to reconnect."
3. API error: "Strava API unavailable. Try again later."
```

---

## 📐 Component Architecture

### 1. LoadingState Model

```swift
// VeloReady/Core/Models/LoadingState.swift

import Foundation

/// Represents the current loading state of the app
enum LoadingState: Equatable {
    case initial                    // App just launched
    case calculatingScores          // Computing recovery/sleep/strain
    case contactingStrava          // Initiating Strava API connection
    case downloadingActivities(count: Int?)  // Fetching activities
    case processingData            // Processing fetched data
    case refreshingScores          // Recalculating with new data
    case complete                  // All loading complete
    case error(LoadingError)       // Error occurred
    
    enum LoadingError: Equatable {
        case network               // Network unavailable
        case stravaAuth           // Strava auth expired
        case stravaAPI            // Strava API error
        case unknown(String)      // Other errors
    }
    
    /// Minimum time this state should be visible (for readability)
    var minimumDisplayDuration: TimeInterval {
        switch self {
        case .initial: return 0.5
        case .calculatingScores: return 1.0
        case .contactingStrava: return 0.8
        case .downloadingActivities: return 1.2
        case .processingData: return 1.0
        case .refreshingScores: return 0.8
        case .complete: return 0.3  // Brief "done" state before fade
        case .error: return 0  // Stays until dismissed
        }
    }
    
    /// Whether this state can be skipped if already complete
    var canSkip: Bool {
        switch self {
        case .complete: return true
        default: return false
        }
    }
}
```

### 2. Loading Status Content

```swift
// VeloReady/Core/Content/LoadingContent.swift

import Foundation

struct LoadingContent {
    // MARK: - Loading States
    
    static let calculatingScores = "Calculating scores..."
    static let contactingStrava = "Contacting Strava..."
    
    static func downloadingActivities(count: Int?) -> String {
        if let count = count {
            return "Downloading \(count) activities..."
        }
        return "Downloading activities..."
    }
    
    static let processingData = "Processing data..."
    static let refreshingScores = "Refreshing scores..."
    static let complete = "Ready"
    
    // MARK: - Error States
    
    static let networkError = "Unable to connect. Tap to retry."
    static let stravaAuthError = "Strava connection expired. Tap to reconnect."
    static let stravaAPIError = "Strava temporarily unavailable."
    
    static func unknownError(_ message: String) -> String {
        return "Error: \(message). Tap to retry."
    }
    
    // MARK: - Accessibility Labels
    
    static func accessibilityLabel(for state: LoadingState) -> String {
        switch state {
        case .initial:
            return "Loading"
        case .calculatingScores:
            return "Calculating recovery and sleep scores"
        case .contactingStrava:
            return "Connecting to Strava"
        case .downloadingActivities(let count):
            if let count = count {
                return "Downloading \(count) activities from Strava"
            }
            return "Downloading activities from Strava"
        case .processingData:
            return "Processing workout data"
        case .refreshingScores:
            return "Refreshing scores with new data"
        case .complete:
            return "Loading complete"
        case .error(let error):
            switch error {
            case .network:
                return "Network error. Tap to retry."
            case .stravaAuth:
                return "Strava authentication error. Tap to reconnect."
            case .stravaAPI:
                return "Strava service unavailable"
            case .unknown(let message):
                return "Error: \(message). Tap to retry."
            }
        }
    }
}
```

### 3. Loading Status View Component

```swift
// VeloReady/Views/Components/LoadingStatusView.swift

import SwiftUI

/// Apple Mail-style loading status indicator
struct LoadingStatusView: View {
    let state: LoadingState
    let onErrorTap: (() -> Void)?
    
    @State private var isVisible = false
    
    var body: some View {
        Group {
            if shouldShowStatus {
                statusContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
        .onChange(of: state) { oldValue, newValue in
            handleStateChange(from: oldValue, to: newValue)
        }
    }
    
    @ViewBuilder
    private var statusContent: some View {
        HStack(spacing: Spacing.xs) {
            // Loading spinner for active states
            if isLoadingState {
                ProgressView()
                    .controlSize(.small)
                    .tint(ColorScale.textSecondary)
            }
            
            // Status text
            VRText(
                statusText,
                style: .caption,
                color: statusColor
            )
            .accessibilityLabel(LoadingContent.accessibilityLabel(for: state))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .if(isErrorState) { view in
            view.onTapGesture {
                onErrorTap?()
            }
        }
    }
    
    private var statusText: String {
        switch state {
        case .initial:
            return ""
        case .calculatingScores:
            return LoadingContent.calculatingScores
        case .contactingStrava:
            return LoadingContent.contactingStrava
        case .downloadingActivities(let count):
            return LoadingContent.downloadingActivities(count: count)
        case .processingData:
            return LoadingContent.processingData
        case .refreshingScores:
            return LoadingContent.refreshingScores
        case .complete:
            return LoadingContent.complete
        case .error(let error):
            switch error {
            case .network:
                return LoadingContent.networkError
            case .stravaAuth:
                return LoadingContent.stravaAuthError
            case .stravaAPI:
                return LoadingContent.stravaAPIError
            case .unknown(let message):
                return LoadingContent.unknownError(message)
            }
        }
    }
    
    private var statusColor: Color {
        if isErrorState {
            return ColorScale.errorColor
        }
        return ColorScale.textSecondary
    }
    
    private var shouldShowStatus: Bool {
        switch state {
        case .initial, .complete:
            return false  // Don't show for these states
        default:
            return true
        }
    }
    
    private var isLoadingState: Bool {
        switch state {
        case .error:
            return false
        case .complete:
            return false
        default:
            return true
        }
    }
    
    private var isErrorState: Bool {
        if case .error = state {
            return true
        }
        return false
    }
    
    private func handleStateChange(from oldState: LoadingState, to newState: LoadingState) {
        // Handle state transitions
        if case .complete = newState {
            // Fade out after brief display
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isVisible = false
            }
        } else {
            isVisible = true
        }
    }
}

// MARK: - View Extension for Conditional Modification

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
```

### 4. Loading State Manager

```swift
// VeloReady/Core/Services/LoadingStateManager.swift

import Foundation
import Combine

/// Manages and throttles loading state transitions
@MainActor
class LoadingStateManager: ObservableObject {
    @Published private(set) var currentState: LoadingState = .initial
    
    private var stateQueue: [LoadingState] = []
    private var isProcessingQueue = false
    private var currentStateStartTime: Date?
    
    /// Update to a new loading state (will be throttled for readability)
    func updateState(_ newState: LoadingState) {
        stateQueue.append(newState)
        processQueueIfNeeded()
    }
    
    /// Force immediate state update (bypass throttling)
    func forceState(_ newState: LoadingState) {
        stateQueue = [newState]
        currentState = newState
        currentStateStartTime = Date()
    }
    
    private func processQueueIfNeeded() {
        guard !isProcessingQueue else { return }
        guard !stateQueue.isEmpty else { return }
        
        isProcessingQueue = true
        Task {
            await processNextState()
        }
    }
    
    private func processNextState() async {
        guard let nextState = stateQueue.first else {
            isProcessingQueue = false
            return
        }
        
        // Wait for minimum display duration of current state
        if let startTime = currentStateStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            let minimumDuration = currentState.minimumDisplayDuration
            let remaining = minimumDuration - elapsed
            
            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }
        }
        
        // Transition to next state
        stateQueue.removeFirst()
        currentState = nextState
        currentStateStartTime = Date()
        
        // Process next state if queue not empty
        if !stateQueue.isEmpty {
            await processNextState()
        } else {
            isProcessingQueue = false
        }
    }
    
    /// Reset to initial state
    func reset() {
        stateQueue.removeAll()
        currentState = .initial
        currentStateStartTime = nil
        isProcessingQueue = false
    }
}
```

---

## 🔄 Integration with TodayViewModel

### Updated TodayViewModel

```swift
// Key additions to TodayViewModel

@MainActor
class TodayViewModel: ObservableObject {
    // ... existing properties ...
    
    @Published var loadingState: LoadingState = .initial
    private let loadingStateManager = LoadingStateManager()
    
    // MARK: - Startup Flow
    
    func loadInitialData() async {
        // Phase 1: Show cached data immediately (0-200ms)
        loadingStateManager.updateState(.calculatingScores)
        await showCachedScores()
        
        // Phase 2: Calculate scores (200ms-2s)
        await calculateCriticalScores()
        
        // Phase 3: Fetch fresh data (2s-10s)
        loadingStateManager.updateState(.contactingStrava)
        await fetchStravaData()
    }
    
    private func fetchStravaData() async {
        do {
            loadingStateManager.updateState(.contactingStrava)
            
            // Fetch activity count first
            let activities = try await stravaService.fetchActivities()
            
            loadingStateManager.updateState(.downloadingActivities(count: activities.count))
            
            // Download activities
            // ... download logic ...
            
            loadingStateManager.updateState(.processingData)
            
            // Process data
            // ... processing logic ...
            
            loadingStateManager.updateState(.refreshingScores)
            
            // Recalculate scores
            await calculateCriticalScores()
            
            loadingStateManager.updateState(.complete)
            
        } catch {
            handleLoadingError(error)
        }
    }
    
    private func handleLoadingError(_ error: Error) {
        if let urlError = error as? URLError {
            if urlError.code == .notConnectedToInternet {
                loadingStateManager.forceState(.error(.network))
            } else {
                loadingStateManager.forceState(.error(.unknown(urlError.localizedDescription)))
            }
        } else if error.localizedDescription.contains("auth") {
            loadingStateManager.forceState(.error(.stravaAuth))
        } else {
            loadingStateManager.forceState(.error(.stravaAPI))
        }
    }
    
    func retryLoading() {
        loadingStateManager.reset()
        Task {
            await loadInitialData()
        }
    }
}
```

---

## 🎨 UI Integration

### Updated TodayView

```swift
// VeloReady/Views/TodayView.swift

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // Header with loading status
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    VRText(TodayContent.title, style: .largeTitle)
                    
                    // Loading status view
                    LoadingStatusView(
                        state: viewModel.loadingStateManager.currentState,
                        onErrorTap: {
                            viewModel.retryLoading()
                        }
                    )
                }
                .padding(.horizontal, Spacing.xl)
                
                // Compact rings (show grey when loading)
                CompactRingsView(
                    recoveryScore: viewModel.recoveryScore,
                    sleepScore: viewModel.sleepScore,
                    strainScore: viewModel.strainScore,
                    isLoading: viewModel.isLoading
                )
                
                // Rest of content...
            }
        }
        .task {
            await viewModel.loadInitialData()
        }
    }
}
```

### Updated CompactRingsView

```swift
// Show grey rings while loading, no spinners

struct CompactRingsView: View {
    let recoveryScore: RecoveryScore?
    let sleepScore: SleepScore?
    let strainScore: Int?
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Recovery Ring
            VStack(spacing: Spacing.xs) {
                RingView(
                    progress: recoveryScore != nil ? Double(recoveryScore!.score) / 100 : 0,
                    color: recoveryScore != nil ? ColorScale.recoveryColor : ColorScale.textTertiary,
                    isLoading: recoveryScore == nil && isLoading
                )
                .frame(width: 60, height: 60)
                
                if let score = recoveryScore {
                    VRText(score.band.rawValue, style: .caption, color: .secondary)
                }
                // Don't show label if loading or no data
            }
            
            // Similar for Sleep and Strain...
        }
    }
}

struct RingView: View {
    let progress: Double
    let color: Color
    let isLoading: Bool
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    isLoading ? ColorScale.textTertiary.opacity(0.3) : color.opacity(0.3),
                    lineWidth: 8
                )
            
            // Progress ring
            if !isLoading {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, lineWidth: 8)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
            } else {
                // Subtle shimmer effect for loading state
                Circle()
                    .stroke(ColorScale.textTertiary.opacity(0.2), lineWidth: 8)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.clear, ColorScale.textTertiary.opacity(0.3), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 8
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(
                                .linear(duration: 1.5).repeatForever(autoreverses: false),
                                value: isLoading
                            )
                    )
            }
        }
    }
}
```

---

## ⏱️ Timing Strategy

### State Visibility Rules

1. **Minimum Display Duration**
   - Each state shows for at least its `minimumDisplayDuration`
   - Prevents states from flashing by too quickly
   - Users can read and understand what's happening

2. **State Skipping**
   - If operation completes before state displays, show it anyway
   - Exception: `.complete` state can be skipped if next operation starts immediately

3. **Error States**
   - Persist until user dismisses or retries
   - No automatic timeout

### Example Timeline

```
0.0s: App launches (animated rings)
2.0s: Transition to main UI
2.0s: "Calculating scores..." (min 1.0s)
3.0s: "Contacting Strava..." (min 0.8s)
3.8s: "Downloading 12 activities..." (min 1.2s)
5.0s: "Processing data..." (min 1.0s)
6.0s: "Refreshing scores..." (min 0.8s)
6.8s: "Ready" (0.5s)
7.3s: Status fades out
```

Total visible loading: ~5.3 seconds (acceptable for initial load)

---

## 🎨 Design System Usage

### Components
- `VRText` - All text rendering
- `ColorScale` - All colors
- `Spacing` - All spacing values
- `RingView` - Ring visualization
- `LoadingStatusView` - New component following design patterns

### Content Architecture
- `LoadingContent` - All loading-related strings
- Centralized for localization
- Accessibility labels included

### Colors
- `textSecondary` - Loading status text
- `textTertiary` - Grey rings
- `errorColor` - Error states
- Existing ring colors when scores available

---

## 📋 Implementation Checklist

### Phase 1: Core Infrastructure (2 hours)
- [ ] Create `LoadingState.swift` model
- [ ] Create `LoadingContent.swift` strings
- [ ] Create `LoadingStateManager.swift` service
- [ ] Add unit tests for state manager

### Phase 2: UI Components (2 hours)
- [ ] Create `LoadingStatusView.swift` component
- [ ] Update `CompactRingsView.swift` for grey/loading states
- [ ] Update `RingView.swift` with shimmer effect
- [ ] Remove spinners from ring views

### Phase 3: Integration (3 hours)
- [ ] Update `TodayViewModel` with loading states
- [ ] Integrate `LoadingStatusView` in `TodayView`
- [ ] Add error handling and retry logic
- [ ] Test state transitions

### Phase 4: Polish (1 hour)
- [ ] Fine-tune state durations
- [ ] Add haptic feedback for errors
- [ ] Test on device
- [ ] Verify accessibility

### Phase 5: Testing (1 hour)
- [ ] Test slow network conditions
- [ ] Test error scenarios
- [ ] Test rapid state changes
- [ ] Verify readability

**Total Estimate: 9 hours**

---

## 🧪 Testing Scenarios

### Happy Path
1. Normal startup with good network
2. Refresh with cached data
3. Background refresh

### Error Scenarios
1. No network connection
2. Strava auth expired
3. Strava API timeout
4. Partial data load

### Edge Cases
1. Very fast network (states still readable?)
2. Very slow network (user doesn't wait forever?)
3. App backgrounded during load
4. Multiple rapid refreshes

---

## 📊 Success Metrics

### User Experience
- ✅ UI appears in <2 seconds
- ✅ User understands what's happening
- ✅ No mysterious delays
- ✅ Clear error communication
- ✅ Each state readable (>0.8s display)

### Technical
- ✅ No race conditions
- ✅ Smooth state transitions
- ✅ Proper error recovery
- ✅ Memory efficient
- ✅ Accessible

---

## 🚀 Future Enhancements

### Phase 2 (Later)
- Progress percentages for downloads
- Detailed error messages with codes
- Background sync status
- "Pull to refresh" integration
- Offline mode indicator

---

## 📝 Notes

**Design Decisions:**
1. Small grey text matches iOS conventions
2. Minimum durations ensure readability
3. Error states require user action (no auto-retry)
4. Grey rings better than spinners (less distracting)
5. State manager throttles transitions (prevents flashing)

**Why This Works:**
- Progressive disclosure - show immediately, enhance gradually
- Transparency - user sees what's happening
- Apple patterns - familiar to iOS users
- Error resilience - clear communication when things fail
- Performance - doesn't slow down actual operations

**Trade-offs:**
- Slightly longer perceived load time (but better UX)
- More complex state management
- Additional testing surface
- But: Much better user understanding and trust
