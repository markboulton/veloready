import SwiftUI

/// Modifier to detect when a view appears above the floating tab bar (24px threshold)
struct ScrollPositionModifier: ViewModifier {
    let threshold: CGFloat
    let onAppear: () -> Void
    
    @State private var hasAppeared = false
    
    init(threshold: CGFloat = 24, onAppear: @escaping () -> Void) {
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
                
                // Trigger animation when view is 24px above the tab bar
                if !hasAppeared && minY < (tabBarTop - threshold) {
                    hasAppeared = true
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
    /// Trigger an action when this view scrolls to 24px above the floating tab bar
    func onScrollAppear(threshold: CGFloat = 24, perform action: @escaping () -> Void) -> some View {
        modifier(ScrollPositionModifier(threshold: threshold, onAppear: action))
    }
}
