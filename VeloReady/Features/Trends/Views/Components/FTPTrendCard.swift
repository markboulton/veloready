import SwiftUI
import Charts

/// Card displaying FTP evolution over time
struct FTPTrendCard: View {
    let data: [TrendsViewModel.TrendDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    var body: some View {
        Card(style: .elevated) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(TrendsContent.Cards.ftpTrend)
                            .font(.heading)
                            .foregroundColor(.text.primary)
                        
                        if let currentFTP = data.last?.value {
                            Text("\(Int(currentFTP))\(TrendsContent.Units.watts)")
                                .font(.title)
                                .foregroundColor(ColorScale.blueAccent)
                        } else {
                            Text(TrendsContent.noDataFound)
                                .font(.body)
                                .foregroundColor(.text.secondary)
                        }
                    }
                    
                    Spacer()
                    
                }
                
                // Chart
                if data.isEmpty {
                    emptyState
                } else if data.count == 1 {
                    singleDataPoint
                } else {
                    chart
                }
                
                // Insight
                if !data.isEmpty {
                    insight
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                Text(TrendsContent.FTP.trackingComingSoon)
                    .font(.body)
                    .foregroundColor(.text.secondary)
                
                Text(TrendsContent.whatYouNeed)
                    .font(.caption)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.FTP.completePowerRides)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.FTP.uploadToIntervals)
                    }
                    HStack {
                        Text(TrendsContent.bulletPoint)
                        Text(TrendsContent.FTP.autoDetected)
                    }
                }
                .font(.caption)
                .foregroundColor(.text.tertiary)
                
                Text(TrendsContent.FTP.checkToday)
                    .font(.caption)
                    .foregroundColor(.chart.primary)
                    .fontWeight(.medium)
                    .padding(.top, Spacing.sm)
            }
            .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    private var singleDataPoint: some View {
        VStack(spacing: Spacing.sm) {
            Text(TrendsContent.FTP.currentFTP)
                .font(.body)
                .foregroundColor(.text.secondary)
            
            if let ftp = data.first?.value {
                Text("\(Int(ftp))\(TrendsContent.Units.watts)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(ColorScale.blueAccent)
            }
            
            Text(TrendsContent.FTP.historicalTracking)
                .font(.caption)
                .foregroundColor(.text.tertiary)
                .padding(.top, Spacing.xs)
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
    }
    
    private var chart: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("FTP", point.value)
            )
            .foregroundStyle(ColorScale.blueAccent)
            .lineStyle(StrokeStyle(lineWidth: 1))
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("FTP", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [ColorScale.blueAccent.opacity(0.3), ColorScale.blueAccent.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                    .font(.caption)
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .frame(height: 180)
    }
    
    private var insight: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider()
            
            Text(TrendsContent.insight)
                .font(.caption)
                .foregroundColor(.text.secondary)
            
            Text(TrendsContent.FTP.trackChanges)
                .font(.body)
                .foregroundColor(.text.secondary)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // With data
            FTPTrendCard(
                data: [
                    TrendsViewModel.TrendDataPoint(date: Date().addingTimeInterval(-60*60*24*60), value: 285),
                    TrendsViewModel.TrendDataPoint(date: Date().addingTimeInterval(-60*60*24*45), value: 288),
                    TrendsViewModel.TrendDataPoint(date: Date().addingTimeInterval(-60*60*24*30), value: 292),
                    TrendsViewModel.TrendDataPoint(date: Date().addingTimeInterval(-60*60*24*15), value: 295),
                    TrendsViewModel.TrendDataPoint(date: Date(), value: 298)
                ],
                timeRange: .days90
            )
            
            // Single point
            FTPTrendCard(
                data: [TrendsViewModel.TrendDataPoint(date: Date(), value: 285)],
                timeRange: .days90
            )
            
            // Empty
            FTPTrendCard(
                data: [],
                timeRange: .days90
            )
        }
        .padding()
    }
    .background(Color.background.primary)
}
