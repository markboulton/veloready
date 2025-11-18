import SwiftUI
import Charts

/// Reusable Training Load chart component showing CTL/ATL/TSB trend
/// Used in both Today page and Activity detail views
struct TrainingLoadChartView: View {
    let data: [TrainingLoadDataPoint]

    // Find today's data point or use most recent
    private var selectedPoint: TrainingLoadDataPoint? {
        data.first { Calendar.current.isDateInToday($0.date) } ?? data.last
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Chart
            chart

            // Metrics Legend
            metricsLegend
        }
    }

    private var chart: some View {
        Chart {
            ForEach(data) { dataPoint in
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
            }

            // Vertical line for today
            if let todayPoint = data.first(where: { Calendar.current.isDateInToday($0.date) }) {
                RuleMark(
                    x: .value("Today", todayPoint.date)
                )
                .foregroundStyle(Color.text.secondary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
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
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.text.tertiary.opacity(0.2))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(Color.text.secondary)
            }
        }
        .frame(height: 200)
    }

    private var metricsLegend: some View {
        HStack(spacing: 16) {
            // CTL
            HStack(spacing: 4) {
                Circle().fill(ColorScale.purpleAccent).frame(width: 6, height: 6)
                Text("CTL")
                    .font(.caption)
                    .foregroundColor(Color.text.secondary)
                if let point = selectedPoint {
                    Text("\(Int(point.ctl))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.text.primary)
                }
            }

            // ATL
            HStack(spacing: 4) {
                Circle().fill(ColorScale.pinkAccent).frame(width: 6, height: 6)
                Text("ATL")
                    .font(.caption)
                    .foregroundColor(Color.text.secondary)
                if let point = selectedPoint {
                    Text("\(Int(point.atl))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.text.primary)
                }
            }

            // Form (TSB)
            HStack(spacing: 4) {
                Circle().fill(ColorScale.blueAccent).frame(width: 6, height: 6)
                Text("Form")
                    .font(.caption)
                    .foregroundColor(Color.text.secondary)
                if let point = selectedPoint {
                    Text("\(Int(point.tsb))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.text.primary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    /// Get color for TSB (form) line
    private func tsbColor(for value: Double, isFuture: Bool) -> Color {
        return isFuture ? ColorScale.gray400 : ColorScale.blueAccent
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
