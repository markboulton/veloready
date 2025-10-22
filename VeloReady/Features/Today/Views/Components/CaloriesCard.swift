import SwiftUI

/// Individual Calories card for Today view
struct CaloriesCard: View {
    @ObservedObject private var liveActivityService: LiveActivityService
    
    init() {
        self.liveActivityService = LiveActivityService(oauthManager: IntervalsOAuthManager.shared)
    }
    
    var body: some View {
        Card {
            HStack(spacing: Spacing.md) {
                // Icon
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: Icons.Health.caloriesFill)
                            .font(.system(size: 22))
                            .foregroundColor(.orange)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Calories")
                        .font(.system(size: TypeScale.sm))
                        .foregroundColor(Color.text.secondary)
                    
                    Text("\(liveActivityService.activeCalories)")
                        .font(.system(size: TypeScale.xl, weight: .bold))
                        .foregroundColor(Color.text.primary)
                }
                
                Spacer()
                
                // Goal indicator
                if liveActivityService.activeCalories > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        let goalProgress = min(Double(liveActivityService.activeCalories) / 500.0, 1.0)
                        Text("\(Int(goalProgress * 100))%")
                            .font(.system(size: TypeScale.xs, weight: .semibold))
                            .foregroundColor(.orange)
                        
                        Text("of 500")
                            .font(.system(size: TypeScale.xxs))
                            .foregroundColor(Color.text.tertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        CaloriesCard()
    }
    .background(Color.background.primary)
}
