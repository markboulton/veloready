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

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.xxl) {
            EmptyStateView(
                icon: "chart.line.uptrend.xyaxis",
                title: CommonContent.EmptyStates.notEnoughTrendData,
                message: CommonContent.EmptyStates.notEnoughTrendDataMessage
            )
            
            Divider()
            
            EmptyStateView(
                icon: "figure.run",
                title: CommonContent.EmptyStates.noActivities,
                message: CommonContent.EmptyStates.noActivitiesMessage,
                actionTitle: CommonContent.EmptyStates.addActivity,
                action: {
                    Logger.debug("Add activity tapped")
                }
            )
            
            Divider()
            
            EmptyStateView(
                icon: "heart.slash",
                title: CommonContent.EmptyStates.healthDataUnavailable,
                message: CommonContent.EmptyStates.healthDataMessage,
                actionTitle: CommonContent.EmptyStates.grantAccess,
                action: {
                    Logger.debug("Grant access tapped")
                }
            )
            
            Divider()
            
            Card {
                EmptyStateView(
                    icon: "moon.zzz",
                    title: CommonContent.EmptyStates.noSleepData,
                    message: CommonContent.EmptyStates.noSleepDataMessage
                )
            }
        }
        .padding(Spacing.cardPadding)
    }
    .background(Color.background.primary)
}
