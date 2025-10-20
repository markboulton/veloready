import SwiftUI

/// Reusable badge component for status indicators and labels
struct Badge: View {
    let text: String
    let variant: BadgeVariant
    let icon: String?
    let size: BadgeSize
    
    init(
        _ text: String,
        variant: BadgeVariant = .neutral,
        icon: String? = nil,
        size: BadgeSize = .medium
    ) {
        self.text = text
        self.variant = variant
        self.icon = icon
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: Spacing.xs / 2) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: size.iconSize))
            }
            
            Text(text)
                .font(.system(size: size.fontSize, weight: .semibold))
        }
        .foregroundColor(variant.foregroundColor)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            Group {
                if variant == .pro {
                    ColorScale.purpleAccent
                } else {
                    variant.backgroundColor
                }
            }
        )
    }
}

// MARK: - Badge Variant

enum BadgeVariant: Equatable {
    case success
    case warning
    case error
    case info
    case neutral
    case pro
    
    var backgroundColor: Color {
        switch self {
        case .success:
            return Color.status.authenticated.opacity(0.15)
        case .warning:
            return Color.status.warning.opacity(0.15)
        case .error:
            return Color.button.danger.opacity(0.15)
        case .info:
            return Color.status.info.opacity(0.15)
        case .neutral:
            return Color.text.tertiary.opacity(0.15)
        case .pro:
            return Color.button.primary.opacity(0.15)
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .success:
            return Color.status.authenticated
        case .warning:
            return Color.status.warning
        case .error:
            return Color.button.danger
        case .info:
            return Color.status.info
        case .neutral:
            return Color.text.secondary
        case .pro:
            return .white
        }
    }
}

// MARK: - Badge Size

enum BadgeSize {
    case small
    case medium
    case large
    
    var fontSize: CGFloat {
        switch self {
        case .small: return TypeScale.xxs
        case .medium: return TypeScale.xs
        case .large: return TypeScale.sm
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return TypeScale.xxs
        case .medium: return TypeScale.xs
        case .large: return TypeScale.sm
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return Spacing.xs
        case .medium: return Spacing.sm
        case .large: return Spacing.md
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return Spacing.xs / 2
        case .medium: return Spacing.xs
        case .large: return Spacing.sm
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 3
        case .medium: return 4
        case .large: return 6
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.xl) {
            // Variants
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Badge Variants")  // Preview only
                    .font(.system(size: TypeScale.md, weight: .semibold))
                
                HStack(spacing: Spacing.sm) {
                    Badge(CommonContent.Badges.excellent, variant: .success)
                    Badge(CommonContent.Badges.fair, variant: .warning)
                    Badge(CommonContent.Badges.poor, variant: .error)
                }
                
                HStack(spacing: Spacing.sm) {
                    Badge(CommonContent.Badges.new, variant: .info)
                    Badge(CommonContent.Badges.beta, variant: .neutral)
                    Badge(CommonContent.Badges.pro, variant: .pro)
                }
            }
            
            Divider()
            
            // Sizes
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Badge Sizes")  // Preview only
                    .font(.system(size: TypeScale.md, weight: .semibold))
                
                HStack(spacing: Spacing.sm) {
                    Badge(CommonContent.Badges.small, variant: .info, size: .small)
                    Badge(CommonContent.Badges.mediumSize, variant: .info, size: .medium)
                    Badge(CommonContent.Badges.large, variant: .info, size: .large)
                }
            }
            
            Divider()
            
            // With Icons
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Badges with Icons")  // Preview only
                    .font(.system(size: TypeScale.md, weight: .semibold))
                
                HStack(spacing: Spacing.sm) {
                    Badge(CommonContent.Badges.ready, variant: .success, icon: "checkmark.circle.fill")
                    Badge(CommonContent.Badges.warning, variant: .warning, icon: "exclamationmark.triangle.fill")
                    Badge(CommonContent.Badges.error, variant: .error, icon: "xmark.circle.fill")
                }
                
                HStack(spacing: Spacing.sm) {
                    Badge(CommonContent.Badges.pro, variant: .pro, icon: "star.fill")
                    Badge(CommonContent.Badges.new, variant: .info, icon: "sparkles")
                    Badge(CommonContent.Badges.beta, variant: .neutral, icon: "hammer.fill")
                }
            }
            
            Divider()
            
            // Use Cases
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Use Cases")  // Preview only
                    .font(.system(size: TypeScale.md, weight: .semibold))
                
                Card {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("Recovery Score")  // Preview only
                                .font(.system(size: TypeScale.sm, weight: .semibold))
                            Spacer()
                            Badge(CommonContent.Badges.excellent, variant: .success, icon: "checkmark.circle.fill", size: .small)
                        }
                        
                        HStack {
                            Text("Sleep Quality")  // Preview only
                                .font(.system(size: TypeScale.sm, weight: .semibold))
                            Spacer()
                            Badge(CommonContent.Badges.fair, variant: .warning, size: .small)
                        }
                        
                        HStack {
                            Text("Training Load")  // Preview only
                                .font(.system(size: TypeScale.sm, weight: .semibold))
                            Spacer()
                            Badge(CommonContent.Badges.high, variant: .error, size: .small)
                        }
                    }
                }
                
                Card {
                    HStack {
                        Text("Weekly Trends")  // Preview only
                            .font(.system(size: TypeScale.md, weight: .semibold))
                        Spacer()
                        Badge(CommonContent.Badges.pro, variant: .pro, icon: "star.fill", size: .small)
                    }
                }
            }
        }
        .padding(Spacing.cardPadding)
    }
    .background(Color.background.primary)
}
