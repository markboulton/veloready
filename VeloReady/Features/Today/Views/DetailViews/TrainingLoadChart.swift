import SwiftUI
import Charts

/// Training Load chart showing 37-day CTL/ATL/TSB trend (30 days past + 7 days future projection)
/// Shows ACTUAL peaks/troughs from real wellness data
/// PRO Feature
struct TrainingLoadChart: View {
    let activity: IntervalsActivity
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @EnvironmentObject private var apiClient: IntervalsAPIClient
    @State private var historicalActivities: [IntervalsActivity] = []
    
    var body: some View {
        guard proConfig.hasProAccess else {
            return AnyView(EmptyView())
        }
        
        guard let ctlAfter = activity.ctl,
              let atlAfter = activity.atl,
              let tss = activity.tss else {
            return AnyView(EmptyView())
        }
        
        // Parse ride date from startDateLocal string (format: "2025-09-21T07:29:37")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        
        guard let rideDate = dateFormatter.date(from: activity.startDateLocal) else {
            print("❌ TrainingLoadChart: Failed to parse date from '\(activity.startDateLocal)'")
            return AnyView(EmptyView())
        }
        
        let tsbAfter = ctlAfter - atlAfter
        
        // Generate 37-day trend (30 past + 7 future) with REAL historical data
        let chartData = generateThirtySevenDayTrend(
            rideDate: rideDate,
            ctlAfter: ctlAfter,
            atlAfter: atlAfter,
            tss: tss,
            activities: historicalActivities
        )
        
        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                // Header with PRO badge inline
                HStack(spacing: 8) {
                    Text(TrainingLoadContent.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(TrainingLoadContent.proBadge)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ColorScale.purpleAccent)
                        .cornerRadius(4)
                    
                    Spacer()
                }
                
                // 37-day line chart with ride impact zone
                Chart {
                    // Ride impact zone (highlighting this ride)
                    if let ridePoint = chartData.first(where: { $0.isRide }) {
                        RectangleMark(
                            xStart: .value("Start", ridePoint.date.addingTimeInterval(-86400)),
                            xEnd: .value("End", ridePoint.date.addingTimeInterval(86400)),
                            yStart: .value("Min", -50),
                            yEnd: .value("Max", max(ridePoint.ctl, ridePoint.atl) + 20)
                        )
                        .foregroundStyle(Color.button.primary)
                    }
                    
                    // Vertical line marking today
                    if let ridePoint = chartData.first(where: { $0.isRide }) {
                        RuleMark(x: .value("Today", ridePoint.date))
                            .foregroundStyle(Color.text.tertiary)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                    
                    // CTL (Fitness) line
                    ForEach(chartData) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.ctl),
                            series: .value("Metric", "CTL")
                        )
                        .foregroundStyle(Color.button.primary)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .interpolationMethod(.linear)
                        
                        // Dots for each day
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.ctl)
                        )
                        .foregroundStyle(Color.button.primary)
                        .symbolSize(dataPoint.isRide ? 50 : (dataPoint.isFuture ? 0 : 20))
                    }
                    
                    // ATL (Fatigue) line
                    ForEach(chartData) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.atl),
                            series: .value("Metric", "ATL")
                        )
                        .foregroundStyle(Color.semantic.warning)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .interpolationMethod(.linear)
                        
                        // Dots for each day
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.atl)
                        )
                        .foregroundStyle(Color.semantic.warning)
                        .symbolSize(dataPoint.isRide ? 50 : (dataPoint.isFuture ? 0 : 20))
                    }
                    
                    // TSB (Form) line - solid, contrasting color
                    ForEach(chartData) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.tsb),
                            series: .value("Metric", "TSB")
                        )
                        .foregroundStyle(ColorScale.greenAccent)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .interpolationMethod(.linear)
                        
                        // Dots for each day
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.tsb)
                        )
                        .foregroundStyle(ColorScale.greenAccent)
                        .symbolSize(dataPoint.isRide ? 50 : (dataPoint.isFuture ? 0 : 20))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                            }
                            .font(.caption2)
                            .foregroundStyle(Color.text.secondary)
                        }
                        AxisGridLine()
                            .foregroundStyle(Color.text.tertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .frame(height: 200)
                
                // Legend and metrics
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.button.primary)
                                .frame(width: 8, height: 8)
                            Text(TrainingLoadContent.Metrics.ctl)
                                .font(.caption2)
                                .foregroundColor(Color.text.secondary)
                            Text(String(format: "%.1f", ctlAfter))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.semantic.warning)
                                .frame(width: 8, height: 8)
                            Text(TrainingLoadContent.Metrics.atl)
                                .font(.caption2)
                                .foregroundColor(Color.text.secondary)
                            Text(String(format: "%.1f", atlAfter))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(ColorScale.greenAccent)
                                .frame(width: 8, height: 8)
                            Text(TrainingLoadContent.Metrics.tsb)
                                .font(.caption2)
                                .foregroundColor(Color.text.secondary)
                            Text(String(format: "%.1f", tsbAfter))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Divider()
                    
                    // TSB Description
                    HStack {
                        Text(TrainingLoadContent.Metrics.form)
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text(String(format: "%.1f", tsbAfter))
                            .font(.caption)
                            .foregroundColor(tsbColor(tsbAfter))
                            .fontWeight(.semibold)
                    }
                    
                    Text(tsbDescription(tsbAfter))
                        .font(.caption)
                        .foregroundColor(Color.text.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        )
        .task {
            // Fetch historical activities for chart
            await loadHistoricalActivities(rideDate: rideDate)
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadHistoricalActivities(rideDate: Date) async {
        do {
            // Fetch 60 days of activities to ensure full history
            print("📊 TrainingLoadChart: Fetching activities (60 days, limit 300)")
            let activities = try await apiClient.fetchRecentActivities(limit: 300, daysBack: 60)
            print("📊 TrainingLoadChart: Fetched \(activities.count) activities")
            
            // Filter to only activities with CTL/ATL data
            let activitiesWithData = activities.filter { $0.ctl != nil && $0.atl != nil }
            print("📊 TrainingLoadChart: \(activitiesWithData.count) activities have CTL/ATL data")
            
            // Check first few activities
            if activitiesWithData.count > 0 {
                let first = activitiesWithData[0]
                print("📊 TrainingLoadChart: First activity with data:")
                print("  - date: \(first.startDateLocal)")
                print("  - name: \(first.name ?? "Unnamed")")
                print("  - CTL: \(first.ctl ?? -1)")
                print("  - ATL: \(first.atl ?? -1)")
                print("  - TSS: \(first.tss ?? -1)")
            }
            
            await MainActor.run {
                self.historicalActivities = activitiesWithData
            }
        } catch {
            print("❌ TrainingLoadChart: Failed to fetch activities: \(error)")
        }
    }
    
    private func generateThirtySevenDayTrend(
        rideDate: Date,
        ctlAfter: Double,
        atlAfter: Double,
        tss: Double,
        activities: [IntervalsActivity]
    ) -> [LoadDataPoint] {
        var data: [LoadDataPoint] = []
        let calendar = Calendar.current
        let simpleDateFormatter = DateFormatter()
        simpleDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        simpleDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        simpleDateFormatter.timeZone = TimeZone.current
        
        // Parse all activity dates and create a sorted array
        var activitiesWithDates: [(date: Date, ctl: Double, atl: Double)] = []
        for activity in activities {
            guard let activityDate = simpleDateFormatter.date(from: activity.startDateLocal),
                  let ctl = activity.ctl,
                  let atl = activity.atl else { continue }
            activitiesWithDates.append((activityDate, ctl, atl))
        }
        
        // Sort by date (oldest first)
        activitiesWithDates.sort { $0.date < $1.date }
        
        // Silently process activities
        
        // 30 days of historical data
        for dayOffset in -29...0 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: rideDate) else { continue }
            
            let isRide = (dayOffset == 0)
            
            let ctlValue: Double
            let atlValue: Double
            
            if isRide {
                // This is the ride we're viewing - use "after" values
                ctlValue = ctlAfter
                atlValue = atlAfter
                // This is the ride day
            } else {
                // Find the most recent activity on or before this date
                let dayEnd = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: date)!)
                
                if let mostRecent = activitiesWithDates.last(where: { $0.date < dayEnd }) {
                    ctlValue = mostRecent.ctl
                    atlValue = mostRecent.atl
                    // Historical data point
                } else {
                    // No activity data before this date - skip
                    // No data before first activity
                    continue
                }
            }
            
            let tsbValue = ctlValue - atlValue
            
            data.append(LoadDataPoint(
                date: date,
                ctl: ctlValue,
                atl: atlValue,
                tsb: tsbValue,
                isRide: isRide,
                isFuture: false
            ))
        }
        
        print("📊 TrainingLoadChart: Generated \(data.count) historical data points")
        
        // 7 days of future projection (decay without training)
        for dayOffset in 1...7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: rideDate) else { continue }
            
            // Natural decay: CTL decays with 42-day time constant, ATL with 7-day
            let daysOut = Double(dayOffset)
            let ctlDecay = exp(-daysOut / 42.0)
            let atlDecay = exp(-daysOut / 7.0)
            
            let ctlValue = ctlAfter * ctlDecay
            let atlValue = atlAfter * atlDecay
            let tsbValue = ctlValue - atlValue
            
            data.append(LoadDataPoint(
                date: date,
                ctl: ctlValue,
                atl: atlValue,
                tsb: tsbValue,
                isRide: false,
                isFuture: true
            ))
        }
        
        print("📊 TrainingLoadChart: Total data points = \(data.count) (30 past + 7 future)")
        print("📊 TrainingLoadChart: Date range = \(simpleDateFormatter.string(from: data.first?.date ?? Date())) to \(simpleDateFormatter.string(from: data.last?.date ?? Date()))")
        
        return data
    }
    
    private func tsbColor(_ tsb: Double) -> Color {
        if tsb < -30 {
            return ColorScale.redAccent
        } else if tsb < -10 {
            return ColorScale.amberAccent
        } else if tsb > 25 {
            return ColorScale.blueAccent
        } else {
            return ColorScale.greenAccent
        }
    }
    
    private func tsbDescription(_ tsb: Double) -> String {
        if tsb < -30 {
            return TrainingLoadContent.TSBDescriptions.heavilyFatigued
        } else if tsb < -10 {
            return TrainingLoadContent.TSBDescriptions.fatigued
        } else if tsb > 25 {
            return TrainingLoadContent.TSBDescriptions.fresh
        } else {
            return TrainingLoadContent.TSBDescriptions.balanced
        }
    }
}

// MARK: - Data Model

struct LoadDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let ctl: Double
    let atl: Double
    let tsb: Double
    let isRide: Bool
    let isFuture: Bool
}
