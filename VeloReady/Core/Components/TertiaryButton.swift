import SwiftUI

/// Tertiary button style - small grey outlined rounded rectangle
/// Part of the design system for tertiary/subtle actions
struct TertiaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.text.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.text.secondary.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        TertiaryButton(title: "Edit details", action: {})
        TertiaryButton(title: "More info", action: {})
        TertiaryButton(title: "Cancel", action: {})
    }
    .padding()
}
