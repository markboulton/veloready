import SwiftUI
import Charts

/// Reusable Training Load chart component showing CTL/ATL/TSB trend
/// Used in both Today page and Activity detail views
struct TrainingLoadChartView: View {
    let data: [TrainingLoadDataPoint]
    let caption: String?  // Optional caption to clarify what the values represent

    init(data: [TrainingLoadDataPoint], caption: String? = nil) {
        self.data = data
        self.caption = caption
    }

    // Find today's data point or use most recent
    private var selectedPoint: TrainingLoadDataPoint? {
        let point = data.first { Calendar.current.isDateInToday($0.date) } ?? data.last
        if let p = point {
            print("📊 [CHART VIEW] Selected point: date=\(p.date), CTL=\(String(format: "%.1f", p.ctl)), ATL=\(String(format: "%.1f", p.atl)), TSB=\(String(format: "%.1f", p.tsb)), isFuture=\(p.isFuture)")
        }
        return point
    }

    var body: some View {
        print("📊 [CHART VIEW] Rendering with \(data.count) data points")
        if let first = data.first, let last = data.last {
            print("📊 [CHART VIEW] Date range: \(first.date) to \(last.date)")
            print("📊 [CHART VIEW] First point: CTL=\(String(format: "%.1f", first.ctl)), ATL=\(String(format: "%.1f", first.atl))")
            print("📊 [CHART VIEW] Last point: CTL=\(String(format: "%.1f", last.ctl)), ATL=\(String(format: "%.1f", last.atl))")
        }

        return VStack(alignment: .leading, spacing: 0) {
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
        VStack(alignment: .leading, spacing: 4) {
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

            // Optional caption
            if let caption = caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundColor(Color.text.tertiary)
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
