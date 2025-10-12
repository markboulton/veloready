import SwiftUI

/// Reusable loading spinner with consistent sizing and optional message
struct LoadingSpinner: View {
    let size: SpinnerSize
    let tint: Color?
    let message: String?
    
    init(
        size: SpinnerSize = .medium,
        tint: Color? = nil,
        message: String? = nil
    ) {
        self.size = size
        self.tint = tint
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            ProgressView()
                .scaleEffect(size.scale)
                .progressViewStyle(CircularProgressViewStyle(tint: tint ?? Color.button.primary))
            
            if let message = message {
                Text(message)
                    .font(.system(size: TypeScale.xs))
                    .foregroundColor(Color.text.secondary)
            }
        }
    }
}

// MARK: - Spinner Size

enum SpinnerSize {
    case small
    case medium
    case large
    case xlarge
    
    var scale: CGFloat {
        switch self {
        case .small: return 0.6
        case .medium: return 0.8
        case .large: return 1.2
        case .xlarge: return 1.5
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.xxl) {
        LoadingSpinner(size: .small)
        LoadingSpinner(size: .medium)
        LoadingSpinner(size: .large)
        LoadingSpinner(size: .xlarge)
        
        Divider()
        
        LoadingSpinner(size: .medium, message: ComponentContent.Loading.defaultMessage)
        LoadingSpinner(size: .large, message: ComponentContent.Loading.loadingData)
        
        Divider()
        
        LoadingSpinner(size: .medium, tint: ColorPalette.error)
        LoadingSpinner(size: .medium, tint: ColorPalette.success)
    }
    .padding(Spacing.cardPadding)
}
