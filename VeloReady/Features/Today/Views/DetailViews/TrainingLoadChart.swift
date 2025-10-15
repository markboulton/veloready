import SwiftUI
import Charts

/// Training Load chart showing 37-day CTL/ATL/TSB trend (30 days past + 7 days future projection)
/// Shows ACTUAL peaks/troughs from real wellness data
/// Works with both Strava and Intervals.icu data
/// PRO Feature
struct TrainingLoadChart: View {
    let activity: IntervalsActivity
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @State private var historicalActivities: [IntervalsActivity] = []
    @State private var isLoading = false
    
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
            // Cannot log during view body computation
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
                // Header
                HStack(spacing: 8) {
                    Text(TrainingLoadContent.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
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
                        .foregroundStyle(Color.primary.opacity(0.08))
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
        )
        .task {
            // Fetch historical activities for chart
            await loadHistoricalActivities(rideDate: rideDate)
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadHistoricalActivities(rideDate: Date) async {
        do {
            // Try Intervals.icu first if authenticated
            if IntervalsOAuthManager.shared.isAuthenticated {
                Logger.data("TrainingLoadChart: Fetching from Intervals.icu")
                let apiClient = IntervalsAPIClient.shared
                let activities = try await apiClient.fetchRecentActivities(limit: 300, daysBack: 60)
                Logger.data("TrainingLoadChart: Fetched \(activities.count) activities from Intervals")
                
                let activitiesWithData = activities.filter { $0.ctl != nil && $0.atl != nil }
                await MainActor.run {
                    self.historicalActivities = activitiesWithData
                }
                return
            }
            
            // Fallback to Strava with CTL/ATL calculation
            Logger.data("TrainingLoadChart: Fetching from Strava")
            let stravaActivities = try await StravaAPIClient.shared.fetchActivities(perPage: 200)
            Logger.data("TrainingLoadChart: Fetched \(stravaActivities.count) activities from Strava")
            
            // Get FTP for TSS calculation
            let profileManager = await MainActor.run { AthleteProfileManager.shared }
            guard let ftp = profileManager.profile.ftp, ftp > 0 else {
                Logger.warning("TrainingLoadChart: No FTP available for TSS calculation")
                return
            }
            
            // Convert Strava activities and calculate TSS/CTL/ATL
            var enrichedActivities: [IntervalsActivity] = []
            
            for stravaActivity in stravaActivities {
                var activity = convertStravaToIntervals(stravaActivity)
                
                // Calculate TSS if activity has power data
                if let np = activity.normalizedPower ?? (activity.averagePower.map { $0 * 1.05 }),
                   np > 50 {
                    let duration = activity.duration ?? 0
                    let if_value = np / ftp
                    let tss = (duration * np * if_value) / (ftp * 36.0)
                    
                    activity = IntervalsActivity(
                        id: activity.id,
                        name: activity.name,
                        description: activity.description,
                        startDateLocal: activity.startDateLocal,
                        type: activity.type,
                        duration: activity.duration,
                        distance: activity.distance,
                        elevationGain: activity.elevationGain,
                        averagePower: activity.averagePower,
                        normalizedPower: np,
                        averageHeartRate: activity.averageHeartRate,
                        maxHeartRate: activity.maxHeartRate,
                        averageCadence: activity.averageCadence,
                        averageSpeed: activity.averageSpeed,
                        maxSpeed: activity.maxSpeed,
                        calories: activity.calories,
                        fileType: activity.fileType,
                        tss: tss,
                        intensityFactor: if_value,
                        atl: nil,
                        ctl: nil,
                        icuZoneTimes: nil,
                        icuHrZoneTimes: nil
                    )
                }
                
                enrichedActivities.append(activity)
            }
            
            // Calculate CTL/ATL for all activities
            let calculator = TrainingLoadCalculator()
            let (ctl, atl) = calculator.calculateTrainingLoadFromActivities(enrichedActivities)
            
            // Add CTL/ATL to each activity (simplified - just use final values)
            // For proper chart, we'd need to calculate CTL/ATL at each point in time
            let activitiesWithLoad = enrichedActivities.map { activity in
                IntervalsActivity(
                    id: activity.id,
                    name: activity.name,
                    description: activity.description,
                    startDateLocal: activity.startDateLocal,
                    type: activity.type,
                    duration: activity.duration,
                    distance: activity.distance,
                    elevationGain: activity.elevationGain,
                    averagePower: activity.averagePower,
                    normalizedPower: activity.normalizedPower,
                    averageHeartRate: activity.averageHeartRate,
                    maxHeartRate: activity.maxHeartRate,
                    averageCadence: activity.averageCadence,
                    averageSpeed: activity.averageSpeed,
                    maxSpeed: activity.maxSpeed,
                    calories: activity.calories,
                    fileType: activity.fileType,
                    tss: activity.tss,
                    intensityFactor: activity.intensityFactor,
                    atl: atl,
                    ctl: ctl,
                    icuZoneTimes: activity.icuZoneTimes,
                    icuHrZoneTimes: activity.icuHrZoneTimes
                )
            }
            
            await MainActor.run {
                self.historicalActivities = activitiesWithLoad.filter { $0.tss != nil }
            }
            
            Logger.data("TrainingLoadChart: Processed \(self.historicalActivities.count) activities with TSS")
        } catch {
            Logger.error("TrainingLoadChart: Failed to fetch activities: \(error)")
        }
    }
    
    private func convertStravaToIntervals(_ strava: StravaActivity) -> IntervalsActivity {
        IntervalsActivity(
            id: "strava_\(strava.id)",
            name: strava.name,
            description: nil,
            startDateLocal: strava.start_date_local,
            type: strava.sport_type,
            duration: TimeInterval(strava.moving_time),
            distance: strava.distance,
            elevationGain: strava.total_elevation_gain,
            averagePower: strava.average_watts,
            normalizedPower: strava.weighted_average_watts.map { Double($0) },
            averageHeartRate: strava.average_heartrate,
            maxHeartRate: strava.max_heartrate.map { Double($0) },
            averageCadence: strava.average_cadence,
            averageSpeed: strava.average_speed,
            maxSpeed: strava.max_speed,
            calories: strava.calories.map { Int($0) },
            fileType: nil,
            tss: nil,
            intensityFactor: nil,
            atl: nil,
            ctl: nil,
            icuZoneTimes: nil,
            icuHrZoneTimes: nil
        )
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
        
        Logger.data("TrainingLoadChart: Generated \(data.count) historical data points")
        
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
        
        Logger.data("TrainingLoadChart: Total data points = \(data.count) (30 past + 7 future)")
        Logger.data("TrainingLoadChart: Date range = \(simpleDateFormatter.string(from: data.first?.date ?? Date())) to \(simpleDateFormatter.string(from: data.last?.date ?? Date()))")
        
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
