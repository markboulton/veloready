import SwiftUI

/// Modifier to detect when a view appears above the floating tab bar
struct ScrollPositionModifier: ViewModifier {
    let threshold: CGFloat
    let onAppear: () -> Void
    
    @State private var hasAppeared = false
    
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
                
                // Only trigger if view is in visible viewport (not at top of scroll)
                // minY between 0 and screenHeight means it's visible
                let isInViewport = minY > 0 && minY < screenHeight
                
                // Debug logging
                if !hasAppeared {
                    Logger.debug("📍 [SCROLL] View minY: \(Int(minY)), triggerPoint: \(Int(triggerPoint)), diff: \(Int(minY - triggerPoint)), inViewport: \(isInViewport)")
                }
                
                // Trigger animation when view is:
                // 1. In the visible viewport (scrolled into view)
                // 2. Above the trigger point (threshold distance above tab bar)
                if !hasAppeared && isInViewport && minY < triggerPoint {
                    hasAppeared = true
                    Logger.debug("🎬 [SCROLL] Animation triggered! View reached scroll threshold")
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
