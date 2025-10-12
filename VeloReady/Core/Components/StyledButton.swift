import SwiftUI

/// Reusable styled button with variants, sizes, and loading state
struct StyledButton: View {
    let title: String
    let icon: String?
    let variant: ButtonVariant
    let size: ButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        variant: ButtonVariant = .primary,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: variant.foregroundColor))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize))
                    }
                    
                    Text(title)
                        .font(.system(size: size.fontSize, weight: .semibold))
                }
            }
            .foregroundColor(variant.foregroundColor)
            .frame(maxWidth: size.fullWidth ? .infinity : nil)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(variant.backgroundColor)
            .cornerRadius(Spacing.buttonCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.buttonCornerRadius)
                    .stroke(variant.borderColor, lineWidth: variant.borderWidth)
            )
        }
        .disabled(isDisabled || isLoading)
        // Disabled state handled by SwiftUI
    }
}

// MARK: - Button Variant

enum ButtonVariant {
    case primary
    case secondary
    case success
    case warning
    case danger
    case ghost
    case outline
    
    var backgroundColor: Color {
        switch self {
        case .primary:
            return Color.button.primary
        case .secondary:
            return Color.button.secondary
        case .success:
            return Color.button.success
        case .warning:
            return Color.button.warning
        case .danger:
            return Color.button.danger
        case .ghost, .outline:
            return Color.clear
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary, .success, .danger:
            return .white
        case .secondary:
            return Color.text.primary
        case .warning:
            return Color.text.primary
        case .ghost:
            return Color.button.primary
        case .outline:
            return Color.button.primary
        }
    }
    
    var borderColor: Color {
        switch self {
        case .outline:
            return Color.button.primary
        default:
            return Color.clear
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .outline:
            return 1.5
        default:
            return 0
        }
    }
}

// MARK: - Button Size

enum ButtonSize {
    case small
    case medium
    case large
    
    var fontSize: CGFloat {
        switch self {
        case .small: return TypeScale.xs
        case .medium: return TypeScale.sm
        case .large: return TypeScale.md
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return TypeScale.xs
        case .medium: return TypeScale.sm
        case .large: return TypeScale.md
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return Spacing.md
        case .medium: return Spacing.lg
        case .large: return Spacing.xl
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return Spacing.sm
        case .medium: return Spacing.md
        case .large: return Spacing.lg
        }
    }
    
    var fullWidth: Bool {
        switch self {
        case .large: return true
        default: return false
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.xl) {
            // Variants
            VStack(spacing: Spacing.md) {
                Text("Button Variants")
                    .font(.system(size: TypeScale.md, weight: .semibold))
                
                StyledButton("Primary Button", variant: .primary) { }
                StyledButton("Secondary Button", variant: .secondary) { }
                StyledButton("Success Button", variant: .success) { }
                StyledButton("Warning Button", variant: .warning) { }
                StyledButton("Danger Button", variant: .danger) { }
                StyledButton("Ghost Button", variant: .ghost) { }
                StyledButton("Outline Button", variant: .outline) { }
            }
            
            Divider()
            
            // Sizes
            VStack(spacing: Spacing.md) {
                Text("Button Sizes")
                    .font(.system(size: TypeScale.md, weight: .semibold))
                
                StyledButton("Small Button", size: .small) { }
                StyledButton("Medium Button", size: .medium) { }
                StyledButton("Large Button", size: .large) { }
            }
            
            Divider()
            
            // With Icons
            VStack(spacing: Spacing.md) {
                Text("Buttons with Icons")
                    .font(.system(size: TypeScale.md, weight: .semibold))
                
                StyledButton("Add Activity", icon: "plus", variant: .primary) { }
                StyledButton("Grant Access", icon: "heart.fill", variant: .success) { }
                StyledButton("Delete", icon: "trash", variant: .danger) { }
            }
            
            Divider()
            
            // States
            VStack(spacing: Spacing.md) {
                Text("Button States")
                    .font(.system(size: TypeScale.md, weight: .semibold))
                
                StyledButton("Loading", variant: .primary, isLoading: true) { }
                StyledButton("Disabled", variant: .primary, isDisabled: true) { }
                StyledButton("Normal", variant: .primary) { }
            }
        }
        .padding(Spacing.cardPadding)
    }
    .background(Color.background.primary)
}
