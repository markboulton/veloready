import SwiftUI

/// Modifier to detect when a view appears above the floating tab bar
struct ScrollPositionModifier: ViewModifier {
    let threshold: CGFloat
    let onAppear: () -> Void
    let viewId: String
    
    private let stateManager = ScrollStateManager.shared
    
    init(threshold: CGFloat = 200, viewId: String = UUID().uuidString, onAppear: @escaping () -> Void) {
        self.threshold = threshold
        self.viewId = viewId
        self.onAppear = onAppear
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollPositionPreferenceKey.self,
                            value: geometry.frame(in: .global).minY
                        )
                }
            )
            .onPreferenceChange(ScrollPositionPreferenceKey.self) { minY in
                var state = stateManager.getState(for: viewId)
                
                // Get screen height and calculate floating tab bar position
                let screenHeight = UIScreen.main.bounds.height
                let tabBarHeight: CGFloat = 60 // Approximate floating tab bar height
                let tabBarTop = screenHeight - tabBarHeight
                let triggerPoint = tabBarTop - threshold
                
                // Check if view is NOW in trigger zone
                let isNowInTriggerZone = minY < triggerPoint
                
                // Record initial position on first frame
                if !state.hasRecordedInitialPosition {
                    state.initialMinY = minY
                    state.hasRecordedInitialPosition = true
                    state.wasInTriggerZone = isNowInTriggerZone
                    stateManager.setState(state, for: viewId)
                    
                    Logger.debug("📍 [SCROLL] Initial position recorded - minY: \(Int(minY)), triggerPoint: \(Int(triggerPoint)), startedInZone: \(state.wasInTriggerZone), id: \(viewId.prefix(8))")
                    return
                }
                
                // Check if view is in visible viewport (not scrolled off top or bottom)
                let isInViewport = minY > -100 && minY < screenHeight
                
                // Debug logging
                if !state.hasAppeared && isInViewport {
                    Logger.debug("📍 [SCROLL] minY: \(Int(minY)), trigger: \(Int(triggerPoint)), wasInZone: \(state.wasInTriggerZone), nowInZone: \(isNowInTriggerZone), id: \(viewId.prefix(8))")
                }
                
                // Trigger animation when:
                // 1. View crosses INTO trigger zone (wasn't in, now is)
                // 2. View is in visible viewport
                if !state.hasAppeared && isInViewport && !state.wasInTriggerZone && isNowInTriggerZone {
                    state.hasAppeared = true
                    stateManager.setState(state, for: viewId)
                    Logger.debug("🎬 [SCROLL] Animation triggered! View entered trigger zone, id: \(viewId.prefix(8))")
                    onAppear()
                    return
                }
                
                // Update state for next frame
                state.wasInTriggerZone = isNowInTriggerZone
                stateManager.setState(state, for: viewId)
            }
    }
}

private struct ScrollPositionPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    /// Trigger an action when this view scrolls into view (200px above the floating tab bar by default)
    /// - Parameters:
    ///   - id: Stable identifier for this view to persist state across recreations
    ///   - threshold: Distance above tab bar to trigger (default 200px)
    ///   - action: Action to perform when view enters trigger zone
    func onScrollAppear(id: String = UUID().uuidString, threshold: CGFloat = 200, perform action: @escaping () -> Void) -> some View {
        modifier(ScrollPositionModifier(threshold: threshold, viewId: id, onAppear: action))
    }
}
