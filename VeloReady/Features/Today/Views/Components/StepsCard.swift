import SwiftUI

/// Individual Steps card for Today view
struct StepsCard: View {
    @ObservedObject private var liveActivityService: LiveActivityService
    
    init() {
        self.liveActivityService = LiveActivityService(oauthManager: IntervalsOAuthManager.shared)
    }
    
    var body: some View {
        Card {
            HStack(spacing: Spacing.md) {
                // Icon
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: Icons.Health.steps)
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Steps")
                        .font(.system(size: TypeScale.sm))
                        .foregroundColor(Color.text.secondary)
                    
                    Text("\(liveActivityService.dailySteps)")
                        .font(.system(size: TypeScale.xl, weight: .bold))
                        .foregroundColor(Color.text.primary)
                }
                
                Spacer()
                
                // Goal indicator
                if liveActivityService.dailySteps > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        let goalProgress = min(Double(liveActivityService.dailySteps) / 10000.0, 1.0)
                        Text("\(Int(goalProgress * 100))%")
                            .font(.system(size: TypeScale.xs, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Text("of 10k")
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
        StepsCard()
    }
    .background(Color.background.primary)
}
