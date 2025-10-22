import SwiftUI

/// Modifier to detect when a view appears above the floating tab bar
struct ScrollPositionModifier: ViewModifier {
    let threshold: CGFloat
    let onAppear: () -> Void
    
    @State private var hasAppeared = false
    @State private var hasRecordedInitialPosition = false
    @State private var initialMinY: CGFloat = 0
    
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
                // Record initial position on first frame
                if !hasRecordedInitialPosition {
                    initialMinY = minY
                    hasRecordedInitialPosition = true
                    
                    // Debug: Log initial position
                    let screenHeight = UIScreen.main.bounds.height
                    let tabBarHeight: CGFloat = 60
                    let tabBarTop = screenHeight - tabBarHeight
                    let triggerPoint = tabBarTop - threshold
                    
                    Logger.debug("📍 [SCROLL] Initial position recorded - minY: \(Int(minY)), triggerPoint: \(Int(triggerPoint))")
                    
                    // REMOVED: Auto-animation for views in trigger zone
                    // Issue: Views below fold were animating on load
                    // Solution: Only animate when user actually scrolls
                    return
                }
                
                // Get screen height and calculate floating tab bar position
                let screenHeight = UIScreen.main.bounds.height
                let tabBarHeight: CGFloat = 60 // Approximate floating tab bar height
                let tabBarTop = screenHeight - tabBarHeight
                let triggerPoint = tabBarTop - threshold
                
                // Check if user has scrolled (position changed from initial)
                let hasScrolled = abs(minY - initialMinY) > 10
                
                // Check if view is in visible viewport (not scrolled off top or bottom)
                let isInViewport = minY > -100 && minY < screenHeight
                
                // Check if view is in trigger zone (approaching bottom tab bar)
                let isInTriggerZone = minY < triggerPoint
                
                // Debug logging
                if !hasAppeared {
                    Logger.debug("📍 [SCROLL] minY: \(Int(minY)), trigger: \(Int(triggerPoint)), scrolled: \(hasScrolled), viewport: \(isInViewport), triggerZone: \(isInTriggerZone)")
                }
                
                // Trigger animation when:
                // 1. User has scrolled (not initial render)
                // 2. View is in visible viewport
                // 3. View is in trigger zone (near bottom tab bar)
                if !hasAppeared && hasScrolled && isInViewport && isInTriggerZone {
                    hasAppeared = true
                    Logger.debug("🎬 [SCROLL] Animation triggered! View scrolled into trigger zone")
                    onAppear()
                }
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
