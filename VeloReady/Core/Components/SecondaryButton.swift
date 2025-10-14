import SwiftUI

/// Secondary button style - small blue outlined rounded rectangle
/// Part of the design system for secondary actions
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.blue, lineWidth: 1)
                )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SecondaryButton(title: "Edit RPE", action: {})
        SecondaryButton(title: "Cancel", action: {})
        SecondaryButton(title: "More", action: {})
    }
    .padding()
}
