import SwiftUI

/// Detailed calorie panel showing Goal, Active Energy, and Total
struct DetailedCaloriePanel: View {
    @ObservedObject private var liveActivityService: LiveActivityService
    @StateObject private var userSettings = UserSettings.shared
    
    init(liveActivityService: LiveActivityService) {
        self.liveActivityService = liveActivityService
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.cardContentSpacing) {
            // Header
            Text("Calories")
                .font(.heading)
            
            // Goal (BMR or user-set)
            HStack {
                Text("Goal")
                    .captionStyle()
                
                Spacer()
                
                Text("\(Int(effectiveGoal))")
                    .font(.body)
                    .foregroundColor(ColorPalette.peach)
            }
            
            // Active Energy
            HStack {
                Text("Active Energy")
                    .captionStyle()
                
                Spacer()
                
                if liveActivityService.isLoading {
                    LoadingStateView(size: .small)
                } else {
                    Text("\(Int(liveActivityService.activeCalories))")
                        .font(.body)
                        .foregroundColor(Color.semantic.success)
                }
            }
            
            // Divider
            Divider()
                .background(Color.secondary.opacity(0.3))
            
            // Total
            HStack {
                Text("Total")
                    .font(.heading)
                
                Spacer()
                
                if liveActivityService.isLoading {
                    LoadingStateView(size: .small)
                } else {
                    Text("\(Int(totalCalories))")
                        .font(.heading)
                        .foregroundColor(totalCalories > effectiveGoal ? .white : .primary)
                }
            }
            
            // Last updated
            if let lastUpdated = liveActivityService.lastUpdated {
                Text("Updated \(formatLastUpdated(lastUpdated))")
                    .captionStyle()
            }
        }
        .cardStyle()
    }
    
    private var effectiveGoal: Double {
        if userSettings.useBMRAsGoal {
            return liveActivityService.bmrCalories
        } else {
            return userSettings.calorieGoal
        }
    }
    
    private var totalCalories: Double {
        return effectiveGoal + liveActivityService.activeCalories
    }
    
    private func formatLastUpdated(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    let service = LiveActivityService(oauthManager: IntervalsOAuthManager())
    service.bmrCalories = 1200
    service.activeCalories = 350
    service.dailyCalories = 1550
    service.lastUpdated = Date()
    
    return DetailedCaloriePanel(liveActivityService: service)
        .padding()
}
