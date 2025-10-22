import SwiftUI

/// Modifier to detect when a view appears above the floating tab bar
struct ScrollPositionModifier: ViewModifier {
    let threshold: CGFloat
    let onAppear: () -> Void
    
    @State private var hasAppeared = false
    @State private var hasRecordedInitialPosition = false
    @State private var initialMinY: CGFloat = 0
    @State private var wasInTriggerZone = false
    
    init(threshold: CGFloat = 200, onAppear: @escaping () -> Void) {
        self.threshold = threshold
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
                // Get screen height and calculate floating tab bar position
                let screenHeight = UIScreen.main.bounds.height
                let tabBarHeight: CGFloat = 60 // Approximate floating tab bar height
                let tabBarTop = screenHeight - tabBarHeight
                let triggerPoint = tabBarTop - threshold
                
                // Record initial position on first frame
                if !hasRecordedInitialPosition {
                    initialMinY = minY
                    hasRecordedInitialPosition = true
                    
                    // Track if we start in trigger zone
                    wasInTriggerZone = minY < triggerPoint
                    
                    Logger.debug("📍 [SCROLL] Initial position recorded - minY: \(Int(minY)), triggerPoint: \(Int(triggerPoint)), startedInZone: \(wasInTriggerZone)")
                    return
                }
                
                // Check if view is in visible viewport (not scrolled off top or bottom)
                let isInViewport = minY > -100 && minY < screenHeight
                
                // Check if view is NOW in trigger zone
                let isNowInTriggerZone = minY < triggerPoint
                
                // Debug logging
                if !hasAppeared && isInViewport {
                    Logger.debug("📍 [SCROLL] minY: \(Int(minY)), trigger: \(Int(triggerPoint)), wasInZone: \(wasInTriggerZone), nowInZone: \(isNowInTriggerZone)")
                }
                
                // Trigger animation when:
                // 1. View crosses INTO trigger zone (wasn't in, now is)
                // 2. View is in visible viewport
                if !hasAppeared && isInViewport && !wasInTriggerZone && isNowInTriggerZone {
                    hasAppeared = true
                    Logger.debug("🎬 [SCROLL] Animation triggered! View entered trigger zone")
                    onAppear()
                }
                
                // Update state for next frame
                wasInTriggerZone = isNowInTriggerZone
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
    func onScrollAppear(threshold: CGFloat = 200, perform action: @escaping () -> Void) -> some View {
        modifier(ScrollPositionModifier(threshold: threshold, onAppear: action))
    }
}
