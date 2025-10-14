import SwiftUI

/// Scroll view with custom pull-to-refresh
struct RefreshableScrollView<Content: View>: View {
    let content: Content
    let onRefresh: () async -> Void
    
    @State private var state: PullToRefreshState = .idle
    @State private var scrollOffset: CGFloat = 0
    @State private var lastHapticState: PullToRefreshState = .idle
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private let config = PullToRefreshConfig()
    private let haptics = UIImpactFeedbackGenerator(style: .light)
    
    init(onRefresh: @escaping () async -> Void, @ViewBuilder content: () -> Content) {
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Refresh indicator background
            if state != .idle {
                Color.clear
                    .frame(height: indicatorHeight)
                    .background(ColorScale.divider.opacity(0.1))
            }
            
            ScrollView {
                VStack(spacing: 0) {
                    // Refresh indicator area
                    if state != .idle {
                        PullToRefreshIndicator(
                            state: state,
                            progress: config.progress(for: -scrollOffset)
                        )
                        .frame(height: indicatorHeight)
                        .opacity(indicatorOpacity)
                    }
                    
                    // Main content
                    content
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geometry.frame(in: .named("scroll")).minY
                                )
                            }
                        )
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                handleScrollOffsetChange(value)
            }
        }
        .onChange(of: state) { newState in
            handleStateChange(newState)
        }
    }
    
    // MARK: - Computed Properties
    
    private var indicatorHeight: CGFloat {
        switch state {
        case .idle:
            return 0
        case .pulling, .armed:
            return max(0, config.elasticOffset(for: -scrollOffset))
        case .refreshing:
            return config.triggerThreshold
        case .completed:
            return config.triggerThreshold
        }
    }
    
    private var indicatorOpacity: Double {
        switch state {
        case .idle:
            return 0
        case .pulling(let progress):
            return min(1.0, progress * 2)
        case .armed, .refreshing, .completed:
            return 1.0
        }
    }
    
    // MARK: - Scroll Handlers
    
    private func handleScrollOffsetChange(_ offset: CGFloat) {
        guard !state.isRefreshing else { return }
        
        scrollOffset = offset
        
        // Only respond to pulls from the top
        guard offset > 0 else {
            if state.isPulling {
                // User released or scrolled back up
                let progress = config.progress(for: offset)
                if progress >= 1.0 {
                    triggerRefresh()
                } else {
                    resetToIdle()
                }
            }
            return
        }
        
        // Update state based on pull distance
        let progress = config.progress(for: offset)
        
        if progress >= 1.0 {
            if case .armed = state {
                // Already armed
            } else {
                state = .armed
            }
        } else {
            state = .pulling(progress: progress)
        }
    }
    
    // MARK: - State Transitions
    
    private func triggerRefresh() {
        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : config.snapBackSpring) {
            state = .refreshing
        }
        
        // Execute refresh action
        Task {
            await onRefresh()
            await MainActor.run {
                completeRefresh()
            }
        }
    }
    
    private func completeRefresh() {
        // Show completion state briefly
        withAnimation(.easeInOut(duration: 0.2)) {
            state = .completed
        }
        
        // Return to idle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(reduceMotion ? .easeOut(duration: 0.3) : config.completionSpring) {
                resetToIdle()
            }
        }
    }
    
    private func resetToIdle() {
        scrollOffset = 0
        state = .idle
    }
    
    // MARK: - Haptics
    
    private func handleStateChange(_ newState: PullToRefreshState) {
        // Trigger haptic when crossing threshold
        if case .armed = newState, case .pulling = lastHapticState {
            haptics.impactOccurred(intensity: 0.5)
        } else if case .pulling = newState, case .armed = lastHapticState {
            haptics.impactOccurred(intensity: 0.3)
        } else if case .completed = newState {
            let success = UINotificationFeedbackGenerator()
            success.notificationOccurred(.success)
        }
        
        lastHapticState = newState
    }
}
