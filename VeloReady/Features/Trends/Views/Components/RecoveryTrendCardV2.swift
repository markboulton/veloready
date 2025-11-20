import SwiftUI
import Charts

/// Recovery Trend card using atomic ChartCard wrapper
struct RecoveryTrendCardV2: View {
    let data: [TrendDataPoint]
    let timeRange: TrendsViewState.TimeRange
    
    @State private var viewModel = RecoveryTrendCardViewModel()
    
    private var averageRecovery: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }
    
    private var badge: CardHeader.Badge? {
        guard !data.isEmpty else { return nil }
        let avg = averageRecovery
        
        if avg >= 75 {
            return .init(text: "EXCELLENT", style: .success)
        } else if avg >= 60 {
            return .init(text: "GOOD", style: .info)
        } else if avg >= 50 {
            return .init(text: "MODERATE", style: .warning)
        } else {
            return .init(text: "LOW", style: .error)
        }
    }
    
    private var subtitleText: String {
        guard !data.isEmpty else { return TrendsContent.noDataFound }
        return "\(Int(averageRecovery))% avg"
    }
    
    private var footerText: String? {
        guard !data.isEmpty else { return nil }
        return viewModel.generateInsight(data: data)
    }
    
    var body: some View {
        ChartCard(
            title: TrendsContent.RecoveryTrend.trackDays,
            subtitle: subtitleText,
            badge: badge,
            footerText: footerText
        ) {
            if data.isEmpty {
                emptyStateView
            } else {
                chartView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: Icons.DataSource.intervalsICU)
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                VRText(TrendsContent.RecoveryTrend.notEnoughHistory, style: .body, color: Color.text.secondary)
                
                VRText(TrendsContent.RecoveryTrend.toTrackRecovery, style: .caption, color: Color.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(TrendsContent.bulletPoint)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.text.tertiary)
                        VRText(TrendsContent.RecoveryTrend.wearWatch, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        Text(TrendsContent.RecoveryTrend.stepTwo)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.text.tertiary)
                        VRText(TrendsContent.RecoveryTrend.enableHealthKit, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        Text(TrendsContent.RecoveryTrend.stepThree)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.text.tertiary)
                        VRText(TrendsContent.RecoveryTrend.firstScoreAppears, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        Text(TrendsContent.RecoveryTrend.stepFour)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.text.tertiary)
                        VRText(TrendsContent.RecoveryTrend.recoveryKey, style: .caption, color: Color.text.tertiary)
                    }
                }
                
                Text(TrendsContent.RecoveryTrend.noData)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(ColorScale.blueAccent)
                    .padding(.top, Spacing.sm)
            }
            .multilineTextAlignment(.center)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }
    
    private var chartView: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Recovery", point.value)
            )
            .foregroundStyle(recoveryColor(point.value))
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Recovery", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        recoveryColor(point.value).opacity(0.3),
                        recoveryColor(point.value).opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)%")
                            .font(.caption)
                            .foregroundStyle(Color.text.tertiary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .frame(height: 180)
    }
    
    
    private func recoveryColor(_ value: Double) -> Color {
        if value >= 70 {
            return ColorScale.greenAccent
        } else if value >= 50 {
            return ColorScale.amberAccent
        } else {
            return ColorScale.redAccent
        }
    }
}

#Preview("With Data") {
    RecoveryTrendCardV2(
        data: (0..<90).map { day in
            let base = 72.0
            let variation = Double.random(in: -10...10)
            return TrendDataPoint(
                date: Date().addingTimeInterval(Double(-day) * 24 * 60 * 60),
                value: max(45, min(95, base + variation))
            )
        }.reversed(),
        timeRange: .days90
    )
    .padding()
}

#Preview("Empty") {
    RecoveryTrendCardV2(
        data: [],
        timeRange: .days90
    )
    .padding()
}
