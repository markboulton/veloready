import SwiftUI

/// Calories card using atomic components with MVVM architecture
/// ViewModel handles all business logic and calculations
struct CaloriesCardV2: View {
    @StateObject private var viewModel = CaloriesCardViewModel()
    
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: "Calories",
                subtitle: viewModel.progressPercentage,
                badge: viewModel.badge
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
                        value: viewModel.formattedTotal,
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
                        VRText(viewModel.formattedGoal, style: .headline)
                    }
                    
                    // Active Energy
                    HStack {
                        VRText("Active Energy", style: .body, color: Color.text.secondary)
                        Spacer()
                        VRText(viewModel.formattedActive, style: .headline, color: ColorScale.amberAccent)
                    }
                    
                    // BMR/Resting
                    HStack {
                        VRText("Resting (BMR)", style: .body, color: Color.text.secondary)
                        Spacer()
                        VRText(viewModel.formattedBMR, style: .caption, color: Color.text.secondary)
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
