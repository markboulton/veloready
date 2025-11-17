import SwiftUI

/// Steps card using atomic components with MVVM architecture
/// ViewModel handles all business logic and data transformation
struct StepsCardV2: View {
    @StateObject private var viewModel = StepsCardViewModel()
    
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: CommonContent.Metrics.steps,
                subtitle: viewModel.formattedProgress
            ),
            style: .standard
        ) {
            HStack(alignment: .top, spacing: Spacing.lg) {
                // Left 50%: Content
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Main metric
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "figure.walk")
                            .font(.largeTitle)
                            .fontWeight(.thin)
                            .foregroundColor(Color.text.secondary)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            VRText(viewModel.formattedSteps, style: .largeTitle)
                            VRText(viewModel.formattedGoal, style: .body)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Distance
                    if viewModel.hasDistance {
                        VRText(viewModel.formattedDistance, style: .body, color: Color.text.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right 50%: Visualization
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    if viewModel.hasHourlyData {
                        VRText("Today", style: .caption, color: Color.text.secondary)

                        StepsSparkline(hourlySteps: viewModel.hourlySteps)
                            .frame(height: 60)
                    } else {
                        // Placeholder when no data
                        VStack(spacing: Spacing.xs) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title)
                                .foregroundColor(Color.text.secondary.opacity(0.3))
                            VRText("No data", style: .caption, color: Color.text.secondary)
                        }
                        .frame(height: 60)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadHourlySteps()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        StepsCardV2()
    }
    .padding()
    .background(Color.background.primary)
}
