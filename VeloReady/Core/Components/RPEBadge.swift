import SwiftUI

/// Reusable RPE (Rate of Perceived Exertion) badge component
/// Shows either "Add" (when no RPE) or "RPE" (when RPE exists) with checkmark
struct RPEBadge: View {
    let hasRPE: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: hasRPE ? "checkmark.circle.fill" : "plus.circle")
                    .font(.caption)
                Text(hasRPE ? "RPE" : "Add")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(hasRPE ? ColorScale.greenAccent : ColorScale.gray600)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(hasRPE ? ColorScale.greenAccent.opacity(0.1) : ColorScale.gray200)
            .cornerRadius(Spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct RPEBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            // With RPE
            RPEBadge(hasRPE: true) {
                print("RPE tapped")
            }
            
            // Without RPE
            RPEBadge(hasRPE: false) {
                print("Add RPE tapped")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
