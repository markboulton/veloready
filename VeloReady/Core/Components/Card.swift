import SwiftUI

/// Reusable card container with liquid glass styling
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
            .glassCard(material: style.glassMaterial, elevation: style.glassElevation)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Card Style

enum CardStyle {
    case elevated  // Prominent glass card with depth
    case flat      // Subtle glass card, minimal shadow
    case outlined  // Ultra-thin glass, maximum transparency
    
    var glassMaterial: GlassMaterial {
        switch self {
        case .elevated:
            return .regular
        case .flat:
            return .thin
        case .outlined:
            return .ultraThin
        }
    }
    
    var glassElevation: GlassElevation {
        switch self {
        case .elevated:
            return .medium
        case .flat:
            return .low
        case .outlined:
            return .flat
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.xl) {
            Card(style: .elevated) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(CommonContent.Preview.elevatedCard)
                        .font(.system(size: TypeScale.md, weight: .semibold))
                    Text(CommonContent.Preview.elevatedCardDesc)
                        .font(.system(size: TypeScale.sm))
                        .foregroundColor(Color.text.secondary)
                }
            }
            
            Card(style: .flat) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(CommonContent.Preview.flatCard)
                        .font(.system(size: TypeScale.md, weight: .semibold))
                    Text(CommonContent.Preview.flatCardDesc)
                        .font(.system(size: TypeScale.sm))
                        .foregroundColor(Color.text.secondary)
                }
            }
            
            Card(style: .outlined) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(CommonContent.Preview.outlinedCard)
                        .font(.system(size: TypeScale.md, weight: .semibold))
                    Text(CommonContent.Preview.outlinedCardDesc)
                        .font(.system(size: TypeScale.sm))
                        .foregroundColor(Color.text.secondary)
                }
            }
            
            Card(style: .elevated, padding: Spacing.md) {
                HStack {
                    Image(systemName: Icons.Health.heartFill)
                        .foregroundColor(Color.health.heartRate)
                    Text(CommonContent.Preview.customPadding)
                        .font(.system(size: TypeScale.sm))
                }
            }
        }
        .padding(Spacing.cardPadding)
    }
    .background(Color.background.primary)
}
