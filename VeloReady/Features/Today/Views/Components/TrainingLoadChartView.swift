import SwiftUI
import Charts

/// Reusable Training Load chart component showing CTL/ATL/TSB trend
/// Used in both Today page and Activity detail views
struct TrainingLoadChartView: View {
    let data: [TrainingLoadDataPoint]
    @State private var selectedIndex: Int?

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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Full-width interactive tooltip
            interactiveTooltip
            
            // Chart
            chart

            // Zone Legend
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
        Chart(data) { dataPoint in
            // CTL Line (Fitness) - Purple
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("CTL", dataPoint.ctl),
                series: .value("Metric", "CTL")
            )
            .foregroundStyle(dataPoint.isFuture ? ColorScale.gray400 : ColorScale.purpleAccent)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: dataPoint.isFuture ? [5, 3] : []))
            .interpolationMethod(.linear)

            // ATL Line (Fatigue) - Pink
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("ATL", dataPoint.atl),
                series: .value("Metric", "ATL")
            )
            .foregroundStyle(dataPoint.isFuture ? ColorScale.gray400 : ColorScale.pinkAccent)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: dataPoint.isFuture ? [5, 3] : []))
            .interpolationMethod(.linear)

            // TSB Line (Form) - Gradient colored by zone
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("TSB", dataPoint.tsb),
                series: .value("Metric", "TSB")
            )
            .foregroundStyle(tsbColor(for: dataPoint.tsb, isFuture: dataPoint.isFuture))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: dataPoint.isFuture ? [5, 3] : []))
            .interpolationMethod(.linear)

            // Selected marker - draggable vertical line
            if let selectedPoint = selectedPoint, dataPoint.date == selectedPoint.date {
                RuleMark(x: .value("Selected", dataPoint.date))
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
            AxisMarks(values: .stride(by: .day, count: 4)) { value in
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
        .frame(height: 200)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    updateSelection(at: value.location.x, chartWidth: 350) // Approximate chart width
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

                // TSB (Form)
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

    private var zoneLegend: some View {
        HStack(spacing: 12) {
            legendItem(color: ColorScale.redAccent, label: "High Risk")
            legendItem(color: ColorScale.greenAccent, label: "Optimal")
            legendItem(color: ColorScale.gray500, label: "Grey Zone")
            legendItem(color: ColorScale.cyanAccent, label: "Fresh")
            legendItem(color: ColorScale.yellowAccent, label: "Transition")
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.top, 8)
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

    private func updateSelection(at x: CGFloat, chartWidth: CGFloat) {
        guard !data.isEmpty, chartWidth > 0 else { return }

        // Calculate which data point based on x position
        let index = Int((x / chartWidth) * CGFloat(data.count))
        let clampedIndex = max(0, min(data.count - 1, index))

        selectedIndex = clampedIndex
    }

    /// Get color for TSB (form) based on zone
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
}

struct TrainingLoadDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let ctl: Double
    let atl: Double
    let tsb: Double
    let isFuture: Bool
}
