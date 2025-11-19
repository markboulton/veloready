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
            HStack(alignment: .top, spacing: Spacing.lg) {
                // Left 50%: Content
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Main metric - Total calories
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "flame")
                            .font(.largeTitle)
                            .fontWeight(.thin)
                            .foregroundColor(Color.text.secondary)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            VRText(viewModel.formattedTotal, style: .largeTitle)
                            VRText("Total burned", style: .body)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Goal
                    VRText("Goal: \(viewModel.formattedGoal)", style: .body, color: Color.text.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right 50%: Visualization
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    VRText("Breakdown", style: .caption, color: Color.text.secondary)

                    CaloriesBreakdownChart(
                        activeCalories: viewModel.activeCalories,
                        bmrCalories: viewModel.bmrCalories
                    )
                    .frame(height: 60)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

// MARK: - Calories Breakdown Chart

struct CaloriesBreakdownChart: View {
    let activeCalories: Double
    let bmrCalories: Double

    var body: some View {
        GeometryReader { geometry in
            let total = activeCalories + bmrCalories
            let activeHeight = total > 0 ? (activeCalories / total) * geometry.size.height : 0
            let bmrHeight = total > 0 ? (bmrCalories / total) * geometry.size.height : 0

            HStack(alignment: .bottom, spacing: Spacing.sm) {
                // Stacked bar showing active + BMR
                VStack(spacing: 0) {
                    // Active calories (top, amber)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ColorScale.amberAccent)
                        .frame(height: activeHeight)

                    // BMR calories (bottom, gray)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ColorPalette.neutral300)
                        .frame(height: bmrHeight)
                }
                .frame(width: 40)

                // Labels
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Spacer()

                    // Active
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(ColorScale.amberAccent)
                            .frame(width: 6, height: 6)
                        VRText("\(Int(activeCalories))", style: .caption2, color: Color.text.primary)
                        VRText("Active", style: .caption2, color: Color.text.secondary)
                    }

                    // BMR
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(ColorPalette.neutral300)
                            .frame(width: 6, height: 6)
                        VRText("\(Int(bmrCalories))", style: .caption2, color: Color.text.primary)
                        VRText("BMR", style: .caption2, color: Color.text.secondary)
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
