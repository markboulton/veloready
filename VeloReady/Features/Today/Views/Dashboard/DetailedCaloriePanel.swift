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
                .font(.cardTitle)
            
            // Goal (BMR or user-set)
            HStack {
                Text("Goal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(effectiveGoal))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ColorPalette.peach)
            }
            
            // Active Energy
            HStack {
                Text("Active Energy")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if liveActivityService.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .progressViewStyle(CircularProgressViewStyle(tint: ColorPalette.neutral400))
                } else {
                    Text("\(Int(liveActivityService.activeCalories))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.semantic.success)
                }
            }
            
            // Divider
            Divider()
                .background(Color.secondary.opacity(0.3))
            
            // Total
            HStack {
                Text("Total")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if liveActivityService.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle(tint: ColorPalette.neutral400))
                } else {
                    Text("\(Int(totalCalories))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(totalCalories > effectiveGoal ? .white : .primary)
                }
            }
            
            // Last updated
            if let lastUpdated = liveActivityService.lastUpdated {
                Text("Updated \(formatLastUpdated(lastUpdated))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
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
