import SwiftUI

/// Reusable empty state view with icon, title, message, and optional action
/// Updated to use new design system typography
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
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
        VStack(spacing: 16) {
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

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.xxl) {
            EmptyStateView(
                icon: "chart.line.uptrend.xyaxis",
                title: ComponentContent.EmptyState.notEnoughTrendData,
                message: ComponentContent.EmptyState.notEnoughTrendDataMessage
            )
            
            Divider()
            
            EmptyStateView(
                icon: "figure.run",
                title: ComponentContent.EmptyState.noActivities,
                message: ComponentContent.EmptyState.noActivitiesMessage,
                actionTitle: ComponentContent.EmptyState.addActivity,
                action: {
                    Logger.debug("Add activity tapped")
                }
            )
            
            Divider()
            
            EmptyStateView(
                icon: "heart.slash",
                title: ComponentContent.EmptyState.healthDataUnavailable,
                message: ComponentContent.EmptyState.healthDataMessage,
                actionTitle: ComponentContent.EmptyState.grantAccess,
                action: {
                    Logger.debug("Grant access tapped")
                }
            )
            
            Divider()
            
            Card {
                EmptyStateView(
                    icon: "moon.zzz",
                    title: ComponentContent.EmptyState.noSleepData,
                    message: ComponentContent.EmptyState.noSleepDataMessage
                )
            }
        }
        .padding(Spacing.cardPadding)
    }
    .background(Color.background.primary)
}
