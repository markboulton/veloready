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
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
        .simultaneousGesture(TapGesture().onEnded {
            Logger.debug("🔘 HapticNavigationLink tapped - firing haptic")
            HapticFeedback.light()
        })
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
