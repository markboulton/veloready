import SwiftUI

/// Native iOS navigation bar styling
/// Matches system apps like Mail, Messages, etc.
struct NativeNavigationStyle: ViewModifier {
    let title: String
    let displayMode: NavigationBarItem.TitleDisplayMode
    
    init(title: String, displayMode: NavigationBarItem.TitleDisplayMode = .large) {
        self.title = title
        self.displayMode = displayMode
    }
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension View {
    /// Apply native iOS navigation bar styling
    /// - Parameters:
    ///   - title: Navigation title
    ///   - displayMode: Title display mode (.large or .inline)
    func nativeNavigationBar(title: String, displayMode: NavigationBarItem.TitleDisplayMode = .large) -> some View {
        self.modifier(NativeNavigationStyle(title: title, displayMode: displayMode))
    }
}
