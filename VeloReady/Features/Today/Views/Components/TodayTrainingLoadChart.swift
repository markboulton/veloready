import SwiftUI
import Charts

/// Simplified training load chart with smooth colored lines for Today page
struct TodayTrainingLoadChart: View {
    let data: [TrainingLoadDataPoint]

    // State for interactive tooltip
    @State private var selectedIndex: Int?
    @GestureState private var dragLocation: CGPoint = .zero

    // Find today's index or use most recent as default
    private var defaultSelectedIndex: Int {
        data.firstIndex { Calendar.current.isDateInToday($0.date) } ?? data.count - 1
    }

    private var selectedPoint: TrainingLoadDataPoint? {
        guard let index = selectedIndex, index < data.count else {
            return data.indices.contains(defaultSelectedIndex) ? data[defaultSelectedIndex] : nil
        }
        return data[index]
    }

    // Calculate adaptive Y axis range based on data
    private var yAxisRange: ClosedRange<Double> {
        guard !data.isEmpty else { return 0...100 }

        let allValues = data.flatMap { [$0.ctl, $0.atl, $0.tsb] }
        let minValue = allValues.min() ?? 0
        let maxValue = allValues.max() ?? 100

        // Add 10% padding to top and bottom
        let padding = (maxValue - minValue) * 0.1
        let lower = (minValue - padding).rounded(.down)
        let upper = (maxValue + padding).rounded(.up)

        return lower...upper
    }

    // Get color for TSB (form) based on zone
    private func tsbColor(for value: Double, isFuture: Bool) -> Color {
        if isFuture {
            return ColorScale.gray400
        }

        switch value {
        case 20...: // Transition Zone (>+20)
            return ColorScale.yellowAccent
        case 5..<20: // Fresh Zone (+5 to +20)
            return ColorScale.cyanAccent
        case -10..<5: // Grey Zone (-10 to +5)
            return ColorScale.gray500
        case -30..<(-10): // Optimal (-30 to -10)
            return ColorScale.greenAccent
        default: // High Risk (<-30)
            return ColorScale.redAccent
        }
    }

    var body: some View {
        let _ = Logger.debug("📈 [Chart] Rendering with \(data.count) points")

        VStack(spacing: 0) {
            interactiveTooltip
            chart
            zoneLegend
        }
        .onAppear {
            // Set initial selection to today or most recent
            if selectedIndex == nil {
                selectedIndex = defaultSelectedIndex
            }
        }
    }

    private var chart: some View {
        Chart(data) { point in
            // CTL Line (Fitness) - Purple
            LineMark(
                x: .value("Date", point.date),
                y: .value("CTL", point.ctl),
                series: .value("Metric", "CTL")
            )
            .foregroundStyle(point.isFuture ? ColorScale.gray400 : ColorScale.purpleAccent)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: point.isFuture ? [5, 3] : []))
            .interpolationMethod(.linear)

            // ATL Line (Fatigue) - Pink
            LineMark(
                x: .value("Date", point.date),
                y: .value("ATL", point.atl),
                series: .value("Metric", "ATL")
            )
            .foregroundStyle(point.isFuture ? ColorScale.gray400 : ColorScale.pinkAccent)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: point.isFuture ? [5, 3] : []))
            .interpolationMethod(.linear)

            // TSB Line (Form) - Gradient colored by zone
            LineMark(
                x: .value("Date", point.date),
                y: .value("TSB", point.tsb),
                series: .value("Metric", "TSB")
            )
            .foregroundStyle(tsbColor(for: point.tsb, isFuture: point.isFuture))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: point.isFuture ? [5, 3] : []))
            .interpolationMethod(.linear)
            
            // Selected marker - draggable vertical line
            if let selectedPoint = selectedPoint, point.date == selectedPoint.date {
                RuleMark(x: .value("Selected", point.date))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .annotation(position: .top, spacing: 0) {
                        // Draggable handle
                        VStack(spacing: 0) {
                            Image(systemName: "line.3.horizontal")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.white.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                    }
                    .foregroundStyle(Color.text.secondary)
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.text.tertiary.opacity(0.2))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.text.tertiary.opacity(0.2))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(Color.text.secondary)
            }
        }
        .chartYScale(domain: yAxisRange)
        .frame(height: 200)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    updateSelection(at: value.location.x, chartWidth: UIScreen.main.bounds.width - 40)
                }
        )
    }

    private var interactiveTooltip: some View {
        HStack(spacing: 16) {
            if let point = selectedPoint {
                // Date
                Text(point.date, format: .dateTime.month(.abbreviated).day())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                // CTL
                HStack(spacing: 4) {
                    Circle().fill(ColorScale.purpleAccent).frame(width: 6, height: 6)
                    Text("CTL \(Int(point.ctl))")
                        .font(.caption)
                        .foregroundColor(.white)
                }

                // ATL
                HStack(spacing: 4) {
                    Circle().fill(ColorScale.pinkAccent).frame(width: 6, height: 6)
                    Text("ATL \(Int(point.atl))")
                        .font(.caption)
                        .foregroundColor(.white)
                }

                // TSB
                HStack(spacing: 4) {
                    Circle().fill(tsbColor(for: point.tsb, isFuture: point.isFuture)).frame(width: 6, height: 6)
                    Text("Form \(Int(point.tsb))")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black)
        .cornerRadius(0)
    }

    private func updateSelection(at x: CGFloat, chartWidth: CGFloat) {
        guard !data.isEmpty, chartWidth > 0 else { return }

        // Calculate which data point based on x position
        let index = Int((x / chartWidth) * CGFloat(data.count))
        let clampedIndex = max(0, min(data.count - 1, index))

        selectedIndex = clampedIndex
    }

    private var zoneLegend: some View {
        HStack(spacing: 12) {
            legendItem(color: ColorScale.redAccent, label: "High Risk")
            legendItem(color: ColorScale.greenAccent, label: "Optimal")
            legendItem(color: ColorScale.gray500, label: "Grey Zone")
            legendItem(color: ColorScale.cyanAccent, label: "Fresh")
            legendItem(color: ColorScale.yellowAccent, label: "Transition")
        }
        .font(.caption2)
        .padding(.horizontal, 8)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .foregroundColor(Color.text.secondary)
        }
    }
}

// MARK: - Triangle Shape for Tooltip Arrow

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let today = Date()
    
    let mockData = (-60...7).compactMap { offset -> TrainingLoadDataPoint? in
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
        
        let ctl = 70.0 + Double(offset) * 0.3 + sin(Double(offset) / 7.0) * 5
        let atl = 65.0 + Double(offset) * 0.2 + sin(Double(offset) / 7.0) * 3
        let tsb = ctl - atl
        
        return TrainingLoadDataPoint(
            date: date,
            ctl: ctl,
            atl: atl,
            tsb: tsb,
            isFuture: offset > 0
        )
    }
    
    TodayTrainingLoadChart(data: mockData)
        .padding()
        .background(Color.background.primary)
}
