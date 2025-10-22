import SwiftUI

/// NavigationLink wrapper that provides haptic feedback on tap
/// Use this instead of standard NavigationLink for consistent UX
struct HapticNavigationLink<Label: View, Destination: View>: View {
    let destination: Destination
    let label: () -> Label
    
    init(destination: Destination, @ViewBuilder label: @escaping () -> Label) {
        self.destination = destination
        self.label = label
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            label()
        }
        .buttonStyle(HapticButtonStyle())
    }
}

/// Button style that provides haptic feedback without interfering with navigation
private struct HapticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    HapticFeedback.light()
                }
            }
    }
}

// MARK: - Convenience Extension

extension View {
    /// Wrap this view in a HapticNavigationLink
    func hapticNavigationLink<Destination: View>(to destination: Destination) -> some View {
        HapticNavigationLink(destination: destination) {
            self
        }
    }
}
