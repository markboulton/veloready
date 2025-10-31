import SwiftUI
import Charts

/// Form Chart showing CTL (Chronic Training Load), ATL (Acute Training Load), and TSB (Training Stress Balance)
/// This visualizes training form/fitness over time
struct FormChartCardV2: View {
    let ctlData: [TrendsViewModel.TrendDataPoint]
    let atlData: [TrendsViewModel.TrendDataPoint]
    let tsbData: [TrendsViewModel.TrendDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    private var hasData: Bool {
        !ctlData.isEmpty || !atlData.isEmpty || !tsbData.isEmpty
    }
    
    var body: some View {
        ChartCard(
            title: "Training Form",
            subtitle: "Your fitness (CTL), fatigue (ATL), and form (TSB)"
        ) {
            if hasData {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    chartView
                    legendView
                }
            } else {
                emptyStateView
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                VRText(
                    "Training Form Analysis",
                    style: .body,
                    color: Color.text.secondary
                )
                .multilineTextAlignment(.center)
                
                VRText(
                    "Track your fitness and fatigue balance over time",
                    style: .caption,
                    color: Color.text.tertiary
                )
                .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        VRText("•", style: .caption, color: Color.text.tertiary)
                        VRText("CTL (Chronic Training Load) - Your fitness", style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText("•", style: .caption, color: Color.text.tertiary)
                        VRText("ATL (Acute Training Load) - Your fatigue", style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText("•", style: .caption, color: Color.text.tertiary)
                        VRText("TSB (Training Stress Balance) - Your form", style: .caption, color: Color.text.tertiary)
                    }
                }
                
                VRText(
                    "Complete activities to see your training form",
                    style: .caption,
                    color: Color.chart.primary
                )
                .fontWeight(.medium)
                .padding(.top, Spacing.sm)
            }
        }
        .frame(height: 240)
    }
    
    // MARK: - Chart View
    
    private var chartView: some View {
        Chart {
            // CTL (Fitness) - Blue
            ForEach(ctlData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("CTL", point.value)
                )
                .foregroundStyle(Color.blue)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            
            // ATL (Fatigue) - Red
            ForEach(atlData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("ATL", point.value)
                )
                .foregroundStyle(Color.red)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            
            // TSB (Form) - Green
            ForEach(tsbData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("TSB", point.value)
                )
                .foregroundStyle(Color.green)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
    
    // MARK: - Legend
    
    private var legendView: some View {
        HStack(spacing: Spacing.lg) {
            LegendItem(color: .blue, label: "Fitness (CTL)")
            LegendItem(color: .red, label: "Fatigue (ATL)")
            LegendItem(color: .green, label: "Form (TSB)", isDashed: true)
        }
        .font(.caption)
    }
}

// MARK: - Legend Item

private struct LegendItem: View {
    let color: Color
    let label: String
    var isDashed: Bool = false
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            if isDashed {
                DashedLine()
                    .stroke(color, lineWidth: 2)
                    .frame(width: 16, height: 2)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 2)
            }
            
            Text(label)
                .foregroundStyle(Color.text.secondary)
        }
    }
}

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

#Preview("With Data") {
    let now = Date()
    let calendar = Calendar.current
    
    FormChartCardV2(
        ctlData: (0..<7).map { i in
            TrendsViewModel.TrendDataPoint(
                date: calendar.date(byAdding: .day, value: -6 + i, to: now)!,
                value: 45 + Double(i) * 2
            )
        },
        atlData: (0..<7).map { i in
            TrendsViewModel.TrendDataPoint(
                date: calendar.date(byAdding: .day, value: -6 + i, to: now)!,
                value: 30 + Double(i) * 3
            )
        },
        tsbData: (0..<7).map { i in
            TrendsViewModel.TrendDataPoint(
                date: calendar.date(byAdding: .day, value: -6 + i, to: now)!,
                value: 15 - Double(i) * 1
            )
        },
        timeRange: .days30
    )
    .padding()
}

#Preview("Empty") {
    FormChartCardV2(
        ctlData: [],
        atlData: [],
        tsbData: [],
        timeRange: .days30
    )
    .padding()
}

