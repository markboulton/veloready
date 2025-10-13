import SwiftUI

/// Reusable card container with consistent styling
struct Card<Content: View>: View {
    let style: CardStyle
    let padding: CGFloat
    let content: Content
    
    init(
        style: CardStyle = .elevated,
        padding: CGFloat = Spacing.cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(style.backgroundColor)
            .cornerRadius(Spacing.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .shadow(
                color: style.shadowColor,
                radius: style.shadowRadius,
                x: 0,
                y: style.shadowY
            )
    }
}

// MARK: - Card Style

enum CardStyle {
    case elevated  // White background with shadow
    case flat      // Gray background, no shadow
    case outlined  // Border with transparent background
    
    var backgroundColor: Color {
        switch self {
        case .elevated:
            return Color(.systemBackground).opacity(0.6)
        case .flat:
            return Color(.systemBackground).opacity(0.6)
        case .outlined:
            return Color.clear
        }
    }
    
    var borderColor: Color {
        switch self {
        case .elevated, .flat:
            return Color.primary.opacity(0.1)
        case .outlined:
            return Color.text.tertiary
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .elevated, .flat:
            return 1
        case .outlined:
            return 1
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .elevated:
            return Color.clear  // Removed shadow
        case .flat, .outlined:
            return Color.clear
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .elevated:
            return 0  // Removed shadow
        case .flat, .outlined:
            return 0
        }
    }
    
    var shadowY: CGFloat {
        switch self {
        case .elevated:
            return 0  // Removed shadow
        case .flat, .outlined:
            return 0
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.xl) {
            Card(style: .elevated) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Elevated Card")
                        .font(.system(size: TypeScale.md, weight: .semibold))
                    Text("This card has a white background with a subtle shadow")
                        .font(.system(size: TypeScale.sm))
                        .foregroundColor(Color.text.secondary)
                }
            }
            
            Card(style: .flat) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Flat Card")
                        .font(.system(size: TypeScale.md, weight: .semibold))
                    Text("This card has a gray background with no shadow")
                        .font(.system(size: TypeScale.sm))
                        .foregroundColor(Color.text.secondary)
                }
            }
            
            Card(style: .outlined) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Outlined Card")
                        .font(.system(size: TypeScale.md, weight: .semibold))
                    Text("This card has a border with transparent background")
                        .font(.system(size: TypeScale.sm))
                        .foregroundColor(Color.text.secondary)
                }
            }
            
            Card(style: .elevated, padding: Spacing.md) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Color.health.heartRate)
                    Text("Custom Padding")
                        .font(.system(size: TypeScale.sm))
                }
            }
        }
        .padding(Spacing.cardPadding)
    }
    .background(Color.background.primary)
}
