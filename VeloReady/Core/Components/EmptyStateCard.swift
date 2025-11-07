import SwiftUI

/// Reusable empty state component for when there's no data
/// Consistent messaging across the app
struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String = "tray",
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.heading)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.button)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(ColorPalette.blue)
                }
            }
        }
        .padding(32)
    }
}

#Preview {
    VStack(spacing: 40) {
        EmptyStateCard(
            icon: "figure.walk",
            title: "No Activities",
            message: "Your activities will appear here once you start tracking workouts."
        )
        
        EmptyStateCard(
            icon: "chart.line.uptrend.xyaxis",
            title: "No Data Available",
            message: "Connect your accounts to start seeing trends and insights.",
            actionTitle: "Connect Now",
            action: {}
        )
    }
}
