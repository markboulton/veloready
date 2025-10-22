import SwiftUI

/// Reusable card container with 8% opacity background
/// Consistent spacing and padding across the app
struct Card<Content: View>: View {
    let style: CardStyle
    let padding: CGFloat
    let content: Content
    
    @Environment(\.colorScheme) var colorScheme
    
    init(
        style: CardStyle = .elevated,
        padding: CGFloat = Spacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary.opacity(0.08))
            )
            .padding(.horizontal, 8)
            .padding(.vertical, Spacing.md / 2)
    }
}

// MARK: - Card Style

enum CardStyle {
    case elevated  // Standard card
    case flat      // Minimal card
    case outlined  // Outlined card
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 0) {
            Card(style: .elevated) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Card Title")
                        .font(.system(size: TypeScale.md, weight: .semibold))
                    Text("Card content with 5% opacity background, md padding, and md spacing")
                        .font(.system(size: TypeScale.sm))
                        .foregroundColor(Color.text.secondary)
                }
            }
            
            Card(style: .flat) {
                HStack {
                    Image(systemName: Icons.Health.heartFill)
                        .foregroundColor(Color.health.heartRate)
                    Text("Another card with consistent styling")
                        .font(.system(size: TypeScale.sm))
                }
            }
            
            Card(style: .elevated) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Third Card")
                        .font(.system(size: TypeScale.md, weight: .semibold))
                    Text("Notice the consistent md spacing between cards")
                        .font(.system(size: TypeScale.sm))
                        .foregroundColor(Color.text.secondary)
                }
            }
        }
    }
    .background(Color.background.primary)
}
