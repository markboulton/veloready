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
                
                // Sparkline (if data available)
                if viewModel.hasHourlyData {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        VRText("Today's Activity", style: .caption, color: Color.text.secondary)
                        
                        StepsSparkline(hourlySteps: viewModel.hourlySteps)
                            .frame(height: 32)
                    }
                }
                
                // Distance
                if viewModel.hasDistance {
                    HStack {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(Color.text.secondary)
                        VRText(viewModel.formattedDistance, style: .caption, color: Color.text.secondary)
                    }
                }
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
