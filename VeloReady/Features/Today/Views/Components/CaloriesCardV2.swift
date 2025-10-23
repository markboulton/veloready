import SwiftUI

/// Calories card using atomic components
/// Shows goal, active energy, and total with clear breakdown
struct CaloriesCardV2: View {
    @ObservedObject private var liveActivityService = LiveActivityService.shared
    @StateObject private var userSettings = UserSettings.shared
    
    private var effectiveGoal: Double {
        if userSettings.useBMRAsGoal {
            return liveActivityService.bmrCalories
        } else {
            return userSettings.calorieGoal
        }
    }
    
    private var totalCalories: Double {
        return liveActivityService.bmrCalories + Double(liveActivityService.activeCalories)
    }
    
    private var progress: Double {
        guard effectiveGoal > 0 else { return 0 }
        return min(totalCalories / effectiveGoal, 1.0)
    }
    
    private var badge: CardHeader.Badge? {
        if totalCalories >= effectiveGoal {
            return .init(text: "GOAL MET", style: .success)
        } else if progress >= 0.8 {
            return .init(text: "CLOSE", style: .info)
        }
        return nil
    }
    
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: "Calories",
                subtitle: String(format: "%.0f%% of goal", progress * 100),
                badge: badge
            ),
            style: .standard
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Main metric - Total calories
                HStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.Health.caloriesFill)
                        .font(.title)
                        .foregroundColor(Color.text.secondary)
                    
                    CardMetric(
                        value: "\(Int(totalCalories))",
                        label: "Total burned",
                        size: .large
                    )
                }
                
                Divider()
                    .padding(.vertical, Spacing.xs)
                
                // Breakdown
                VStack(spacing: Spacing.sm) {
                    // Goal
                    HStack {
                        VRText("Goal", style: .body, color: Color.text.secondary)
                        Spacer()
                        VRText("\(Int(effectiveGoal))", style: .headline)
                    }
                    
                    // Active Energy
                    HStack {
                        VRText("Active Energy", style: .body, color: Color.text.secondary)
                        Spacer()
                        VRText("\(Int(liveActivityService.activeCalories))", style: .headline, color: ColorScale.amberAccent)
                    }
                    
                    // BMR/Resting
                    HStack {
                        VRText("Resting (BMR)", style: .body, color: Color.text.secondary)
                        Spacer()
                        VRText("\(Int(liveActivityService.bmrCalories))", style: .caption, color: Color.text.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        CaloriesCardV2()
    }
    .padding()
    .background(Color.background.primary)
}
