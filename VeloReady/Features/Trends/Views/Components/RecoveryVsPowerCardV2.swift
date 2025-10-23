import SwiftUI
import Charts

/// Recovery vs Power card using atomic ChartCard wrapper  
struct RecoveryVsPowerCardV2: View {
    let data: [(recovery: Double, power: Double, date: Date)]
    let timeRange: TrendsViewModel.TimeRange
    
    private var badge: CardHeader.Badge? {
        guard !data.isEmpty else { return nil }
        let avgRecovery = data.map(\.recovery).reduce(0, +) / Double(data.count)
        let avgPower = data.map(\.power).reduce(0, +) / Double(data.count)
        
        if avgRecovery > 70 && avgPower > 250 {
            return .init(text: "OPTIMAL", style: .success)
        } else if avgRecovery < 50 && avgPower > 250 {
            return .init(text: "OVERREACHING", style: .warning)
        } else {
            return .init(text: "BALANCED", style: .info)
        }
    }
    
    var body: some View {
        ChartCard(
            title: TrendsContent.Cards.recoveryVsPower,
            subtitle: data.isEmpty ? TrendsContent.noDataFound : "Training balance analysis",
            badge: badge,
            footerText: data.isEmpty ? nil : "High power with low recovery may indicate overtraining"
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
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VRText("No correlation data", style: .body, color: Color.text.secondary)
            VRText("Requires both recovery scores and power data", style: .caption, color: Color.text.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
    
    private var chartView: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                PointMark(
                    x: .value("Recovery", point.recovery),
                    y: .value("Power", point.power)
                )
                .foregroundStyle(pointColor(recovery: point.recovery, power: point.power))
                .symbolSize(60)
            }
        }
        .chartXScale(domain: 0...100)
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)%")
                            .font(.caption)
                            .foregroundStyle(Color.text.tertiary)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)W")
                            .font(.caption)
                            .foregroundStyle(Color.text.tertiary)
                    }
                }
                AxisGridLine()
            }
        }
        .frame(height: 180)
    }
    
    private func pointColor(recovery: Double, power: Double) -> Color {
        if recovery > 70 && power > 250 {
            return ColorScale.greenAccent
        } else if recovery < 50 && power > 250 {
            return ColorScale.redAccent
        } else if power > 250 {
            return ColorScale.amberAccent
        } else {
            return ColorScale.blueAccent
        }
    }
}

#Preview {
    RecoveryVsPowerCardV2(
        data: (0..<30).map { _ in
            (
                recovery: Double.random(in: 30...95),
                power: Double.random(in: 180...320),
                date: Date()
            )
        },
        timeRange: .days30
    )
    .padding()
}
