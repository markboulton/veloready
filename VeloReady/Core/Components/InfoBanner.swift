import SwiftUI

/// Reusable info/warning/error banner component
/// Consistent messaging banners across the app
struct InfoBanner: View {
    let type: BannerType
    let title: String
    let message: String?
    let action: (() -> Void)?
    let actionTitle: String?
    let dismissAction: (() -> Void)?
    
    init(
        type: BannerType = .info,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        dismissAction: (() -> Void)? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.heading)
                    .foregroundColor(.primary)
                
                if let message = message {
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.caption)
                            .foregroundColor(ColorPalette.blue)
                    }
                }
            }
            
            Spacer()
            
            if let dismissAction = dismissAction {
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(type.backgroundColor)
    }
}

enum BannerType {
    case info
    case warning
    case error
    case success
    
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return ColorPalette.warning
        case .error: return ColorPalette.error
        case .success: return ColorPalette.success
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .info: return Color.blue.opacity(0.1)
        case .warning: return ColorPalette.warning.opacity(0.1)
        case .error: return ColorPalette.error.opacity(0.1)
        case .success: return ColorPalette.success.opacity(0.1)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        InfoBanner(
            type: .info,
            title: "Tip",
            message: "Connect more data sources for better insights."
        )
        
        InfoBanner(
            type: .warning,
            title: "Missing Sleep Data",
            message: "Your recovery score may be less accurate.",
            actionTitle: "Grant Access",
            action: {},
            dismissAction: {}
        )
        
        InfoBanner(
            type: .error,
            title: "Connection Failed",
            message: "Could not connect to Intervals.icu"
        )
        
        InfoBanner(
            type: .success,
            title: "Successfully Connected",
            message: "Your Strava data is now syncing."
        )
    }
    .padding()
}
