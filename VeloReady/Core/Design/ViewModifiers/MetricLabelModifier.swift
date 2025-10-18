import SwiftUI

/// Modifier for metric labels - applies caps + grey styling pattern
struct MetricLabelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.text.secondary)
            .textCase(.uppercase)
            .tracking(0.5) // Slight letter spacing for caps
    }
}

extension View {
    /// Apply standard metric label styling (CAPS + GREY)
    /// Use for all metric labels throughout the app
    func metricLabel() -> some View {
        modifier(MetricLabelModifier())
    }
}
