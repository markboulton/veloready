import SwiftUI

/// NavigationLink wrapper that provides haptic feedback on tap
/// Use this instead of standard NavigationLink for consistent UX
struct HapticNavigationLink<Label: View, Destination: View>: View {
    let destination: Destination
    let label: () -> Label
    
    @State private var isActive = false
    
    init(destination: Destination, @ViewBuilder label: @escaping () -> Label) {
        self.destination = destination
        self.label = label
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            isActive = true
        }) {
            label()
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            NavigationLink(
                destination: destination,
                isActive: $isActive
            ) {
                EmptyView()
            }
            .opacity(0)
        )
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
