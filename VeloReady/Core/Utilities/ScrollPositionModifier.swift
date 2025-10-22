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
                    return
                }
                
                // Get screen height and calculate floating tab bar position
                let screenHeight = UIScreen.main.bounds.height
                let tabBarHeight: CGFloat = 60 // Approximate floating tab bar height
                let tabBarTop = screenHeight - tabBarHeight
                let triggerPoint = tabBarTop - threshold
                
                // Only trigger if user has scrolled (minY changed from initial)
                let hasScrolled = abs(minY - initialMinY) > 10
                
                // Debug logging
                if !hasAppeared {
                    Logger.debug("📍 [SCROLL] View minY: \(Int(minY)), triggerPoint: \(Int(triggerPoint)), hasScrolled: \(hasScrolled)")
                }
                
                // Trigger animation when:
                // 1. User has scrolled (not initial render)
                // 2. View is within trigger zone
                if !hasAppeared && hasScrolled && minY < triggerPoint && minY > 0 {
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
