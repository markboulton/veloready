import SwiftUI

/// Reusable empty state view with icon, title, message, and optional action
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
                .font(.system(size: TypeScale.xxl))
                .foregroundColor(Color.text.tertiary)
            
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.system(size: TypeScale.md, weight: .semibold))
                    .foregroundColor(Color.text.primary)
                
                Text(message)
                    .font(.system(size: TypeScale.sm))
                    .foregroundColor(Color.text.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: TypeScale.sm, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(Color.button.primary)
                        .cornerRadius(Spacing.buttonCornerRadius)
                }
                .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xxl)
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
                    print("Add activity tapped")
                }
            )
            
            Divider()
            
            EmptyStateView(
                icon: "heart.slash",
                title: ComponentContent.EmptyState.healthDataUnavailable,
                message: ComponentContent.EmptyState.healthDataMessage,
                actionTitle: ComponentContent.EmptyState.grantAccess,
                action: {
                    print("Grant access tapped")
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
