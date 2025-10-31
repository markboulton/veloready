import SwiftUI

/// Card wrapper for Fitness Trajectory chart showing 2 weeks historical + 1 week projection
struct FitnessTrajectoryCardV2: View {
    let data: [FitnessTrajectoryChart.DataPoint]
    
    private var hasData: Bool {
        !data.isEmpty
    }
    
    private var historicalData: [FitnessTrajectoryChart.DataPoint] {
        data.filter { !$0.isFuture }
    }
    
    private var futureData: [FitnessTrajectoryChart.DataPoint] {
        data.filter { $0.isFuture }
    }
    
    var body: some View {
        ChartCard(
            title: "Fitness Trajectory",
            subtitle: "Your fitness trend with 7-day projection"
        ) {
            if hasData {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    FitnessTrajectoryChart(data: data)
                        .frame(height: 200)
                    
                    legendView
                    
                    insightText
                }
            } else {
                emptyStateView
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                VRText(
                    "Fitness Trajectory",
                    style: .body,
                    color: Color.text.secondary
                )
                .multilineTextAlignment(.center)
                
                VRText(
                    "Track your fitness progression and see future projections",
                    style: .caption,
                    color: Color.text.tertiary
                )
                .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        VRText("•", style: .caption, color: Color.text.tertiary)
                        VRText("CTL (Chronic Training Load) - Your fitness level", style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText("•", style: .caption, color: Color.text.tertiary)
                        VRText("ATL (Acute Training Load) - Your current fatigue", style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText("•", style: .caption, color: Color.text.tertiary)
                        VRText("TSB (Training Stress Balance) - Your readiness", style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText("•", style: .caption, color: Color.text.tertiary)
                        VRText("7-day projection shows expected fitness decay", style: .caption, color: Color.text.tertiary)
                    }
                }
                .padding(.top, Spacing.sm)
                
                VRText(
                    "Complete workouts to see your trajectory",
                    style: .caption,
                    color: Color.chart.primary
                )
                .fontWeight(.medium)
                .padding(.top, Spacing.sm)
            }
        }
        .frame(height: 280)
    }
    
    // MARK: - Legend
    
    private var legendView: some View {
        HStack(spacing: Spacing.lg) {
            LegendItem(
                color: ColorScale.blueAccent,
                label: "Fitness (CTL)",
                value: historicalData.last?.ctl
            )
            LegendItem(
                color: ColorScale.amberAccent,
                label: "Fatigue (ATL)",
                value: historicalData.last?.atl
            )
            LegendItem(
                color: ColorScale.greenAccent,
                label: "Form (TSB)",
                value: historicalData.last?.tsb
            )
        }
        .font(.caption)
    }
    
    // MARK: - Insight Text
    
    private var insightText: some View {
        Group {
            if let lastHistorical = historicalData.last, let lastFuture = futureData.last {
                let ctlChange = lastFuture.ctl - lastHistorical.ctl
                let tsbChange = lastFuture.tsb - lastHistorical.tsb
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("7-Day Projection:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.text.secondary)
                    
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: ctlChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text("Fitness \(ctlChange >= 0 ? "+" : "")\(Int(ctlChange)) • Form \(tsbChange >= 0 ? "+" : "")\(Int(tsbChange))")
                            .font(.caption)
                    }
                    .foregroundColor(Color.text.tertiary)
                }
                .padding(Spacing.sm)
                .background(Color.background.secondary)
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Legend Item

private struct LegendItem: View {
    let color: Color
    let label: String
    let value: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .foregroundStyle(Color.text.secondary)
            }
            
            if let value = value {
                Text("\(Int(value))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.text.primary)
            }
        }
    }
}

#Preview("Empty") {
    FitnessTrajectoryCardV2(data: [])
        .padding()
}

