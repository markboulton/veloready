import SwiftUI
import Charts

/// Training Load chart showing 21-day CTL/ATL/TSB trend (14 days past + 7 days future projection)
/// Shows ACTUAL peaks/troughs from real wellness data
/// Works with both Strava and Intervals.icu data
/// PRO Feature
struct TrainingLoadChart: View {
    let activity: IntervalsActivity
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @State private var historicalActivities: [IntervalsActivity] = []
    @State private var isLoading = false
    @State private var loadedActivityId: String? = nil // Track which activity we've loaded data for
    
    // Cache metadata (persists across app restarts)
    @AppStorage("trainingLoadLastFetch") private var lastFetchTimestamp: Double = 0
    @AppStorage("trainingLoadActivityCount") private var cachedActivityCount: Int = 0
    private let cacheValidityDuration: TimeInterval = 3600  // 1 hour
    
    // Computed property to parse date once
    private var parsedRideDate: Date? {
        // Parse ride date from startDateLocal string (format: "2025-09-21T07:29:37" or "2025-09-21T07:29:37Z")
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime] // NO .withFractionalSeconds - dates don't have them!
        dateFormatter.timeZone = TimeZone.current
        
        // Try parsing with ISO8601DateFormatter first (handles Z)
        if let date = dateFormatter.date(from: activity.startDateLocal) {
            return date
        }
        
        // Fallback to manual parsing without Z
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
        fallbackFormatter.timeZone = TimeZone.current
        
        if let date = fallbackFormatter.date(from: activity.startDateLocal) {
            return date
        }
        
        Logger.warning("TrainingLoadChart: Failed to parse date: \(activity.startDateLocal)")
        return nil
    }
    
    var body: some View {
        // Only show if user has Pro access AND activity has TSS AND date parses
        guard proConfig.hasProAccess,
              let tss = activity.tss,
              let rideDate = parsedRideDate else {
            return AnyView(EmptyView())
        }
        
        Logger.data("TrainingLoadChart: Rendering chart - TSS: \(tss), CTL: \(activity.ctl?.description ?? "nil"), ATL: \(activity.atl?.description ?? "nil")")
        
        // Find this activity in historicalActivities to get its actual CTL/ATL
        let matchedActivity = historicalActivities.first(where: { $0.id == activity.id })
        let ctlAfter = matchedActivity?.ctl ?? activity.ctl ?? 0
        let atlAfter = matchedActivity?.atl ?? activity.atl ?? 0
        
        Logger.data("TrainingLoadChart: Using CTL=\(String(format: "%.1f", ctlAfter)), ATL=\(String(format: "%.1f", atlAfter)) for legend")
        
        let tsbAfter = ctlAfter - atlAfter
        
        // Generate 21-day trend (14 past + 7 future) with REAL historical data
        let chartData = generateTwentyOneDayTrend(
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
                        .foregroundStyle(dataPoint.isFuture ? ColorScale.blueAccent.opacity(0.5) : Color.text.tertiary)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .interpolationMethod(.linear)
                        
                        // Dots for each day
                        if !dataPoint.isFuture {
                            PointMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Value", dataPoint.ctl)
                            )
                            .foregroundStyle(Color.clear)
                            .symbolSize(dataPoint.isRide ? 100 : 64)
                            .symbol {
                                if dataPoint.isRide {
                                    ZStack {
                                        Circle()
                                            .fill(ColorScale.blueAccent)
                                            .frame(width: 10, height: 10)
                                        Circle()
                                            .stroke(Color.background.primary, lineWidth: 3)
                                            .frame(width: 10, height: 10)
                                    }
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color.background.primary)
                                            .frame(width: 8, height: 8)
                                        Circle()
                                            .stroke(Color.text.tertiary.opacity(0.6), lineWidth: 2)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                        }
                    }
                    
                    // ATL (Fatigue) line
                    ForEach(chartData) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.atl),
                            series: .value("Metric", "ATL")
                        )
                        .foregroundStyle(dataPoint.isFuture ? ColorScale.amberAccent.opacity(0.5) : Color.text.tertiary)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .interpolationMethod(.linear)
                        
                        // Dots for each day
                        if !dataPoint.isFuture {
                            PointMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Value", dataPoint.atl)
                            )
                            .foregroundStyle(Color.clear)
                            .symbolSize(dataPoint.isRide ? 100 : 64)
                            .symbol {
                                if dataPoint.isRide {
                                    ZStack {
                                        Circle()
                                            .fill(ColorScale.amberAccent)
                                            .frame(width: 10, height: 10)
                                        Circle()
                                            .stroke(Color.background.primary, lineWidth: 3)
                                            .frame(width: 10, height: 10)
                                    }
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color.background.primary)
                                            .frame(width: 8, height: 8)
                                        Circle()
                                            .stroke(Color.text.tertiary.opacity(0.6), lineWidth: 2)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                        }
                    }
                    
                    // TSB (Form) line
                    ForEach(chartData) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.tsb),
                            series: .value("Metric", "TSB")
                        )
                        .foregroundStyle(dataPoint.isFuture ? ColorScale.greenAccent.opacity(0.5) : Color.text.tertiary)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .interpolationMethod(.linear)
                        
                        // Dots for each day
                        if !dataPoint.isFuture {
                            PointMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Value", dataPoint.tsb)
                            )
                            .foregroundStyle(Color.clear)
                            .symbolSize(dataPoint.isRide ? 100 : 64)
                            .symbol {
                                if dataPoint.isRide {
                                    ZStack {
                                        Circle()
                                            .fill(ColorScale.greenAccent)
                                            .frame(width: 10, height: 10)
                                        Circle()
                                            .stroke(Color.background.primary, lineWidth: 3)
                                            .frame(width: 10, height: 10)
                                    }
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color.background.primary)
                                            .frame(width: 8, height: 8)
                                        Circle()
                                            .stroke(Color.text.tertiary.opacity(0.6), lineWidth: 2)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 3)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                            }
                            .font(.caption2)
                            .foregroundStyle(Color.text.secondary)
                        }
                        AxisGridLine()
                            .foregroundStyle(Color(.systemGray4))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                            .foregroundStyle(Color(.systemGray4))
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(Color.text.tertiary)
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
            .task(id: activity.id) { // Use activity ID as stable identifier to prevent cancellation
                // Only fetch if we haven't already loaded data for this activity
                guard loadedActivityId != activity.id else {
                    Logger.data("TrainingLoadChart: Data already loaded for activity \(activity.id)")
                    return
                }
                
                // Fetch historical activities for chart
                Logger.data("TrainingLoadChart: .task triggered for NEW activity: \(activity.id)")
                await loadHistoricalActivities(rideDate: rideDate)
                loadedActivityId = activity.id
            }
            .onAppear {
                Logger.data("TrainingLoadChart: onAppear triggered")
            }
        )
    }
    
    // MARK: - Helper Functions
    
    private func loadHistoricalActivities(rideDate: Date) async {
        Logger.data("TrainingLoadChart: loadHistoricalActivities called for date: \(rideDate)")
        
        // Check cache age
        let lastFetch = Date(timeIntervalSince1970: lastFetchTimestamp)
        let cacheAge = Date().timeIntervalSince(lastFetch)
        
        if cacheAge < cacheValidityDuration && !historicalActivities.isEmpty {
            Logger.data("⚡ Training Load: Using cached data (age: \(Int(cacheAge/60))m, \(historicalActivities.count) activities)")
            return
        }
        
        Logger.data("📡 Training Load: Cache expired or empty - fetching fresh data (age: \(Int(cacheAge/60))m)")
        
        do {
            // Fetch activities going back 42 days BEFORE the activity date
            // This ensures we have proper historical context for CTL calculation
            let calendar = Calendar.current
            let earliestDate = calendar.date(byAdding: .day, value: -42, to: rideDate) ?? rideDate
            
            // Calculate days back from ride date to today (to include the ride itself)
            let daysFromRideToToday = calendar.dateComponents([.day], from: rideDate, to: Date()).day ?? 0
            let totalDaysBack = 42 + daysFromRideToToday
            
            Logger.data("TrainingLoadChart: Fetching activities from \(earliestDate) (ride: \(rideDate), total days: \(totalDaysBack))")
            let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 200, daysBack: totalDaysBack)
            Logger.data("TrainingLoadChart: Fetched \(activities.count) activities")
            
            // Get FTP for TSS enrichment
            let profileManager = await MainActor.run { AthleteProfileManager.shared }
            let ftp = profileManager.profile.ftp
            
            // Enrich activities with TSS using unified converter
            let enrichedActivities = activities.map { activity in
                ActivityConverter.enrichWithMetrics(activity, ftp: ftp)
            }
            
            // Calculate progressive CTL/ATL using TrainingLoadCalculator
            let calculator = TrainingLoadCalculator()
            let progressiveLoad = calculator.calculateProgressiveTrainingLoad(enrichedActivities)
            
            // Date formatter for matching activity dates (must match calculator's parser!)
            // NOTE: Intervals.icu returns dates WITHOUT timezone suffix (e.g., "2025-10-16T06:33:05")
            // Strava returns dates WITH timezone suffix (e.g., "2025-10-16T06:33:05Z")
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
            iso8601Formatter.timeZone = TimeZone.current
            
            // Add CTL/ATL to activities that have TSS
            let activitiesWithLoad = enrichedActivities.filter { $0.tss != nil }.map { activity -> IntervalsActivity in
                // Get CTL/ATL for this activity's date
                var activityCTL: Double = 0
                var activityATL: Double = 0
                
                if let activityDate = iso8601Formatter.date(from: activity.startDateLocal) {
                    let day = Calendar.current.startOfDay(for: activityDate)
                    if let load = progressiveLoad[day] {
                        activityCTL = load.ctl
                        activityATL = load.atl
                        Logger.data("  📅 Matched activity \(activity.name ?? "Unknown") (\(activity.startDateLocal)) to CTL=\(String(format: "%.1f", activityCTL)), ATL=\(String(format: "%.1f", activityATL))")
                    } else {
                        Logger.warning("  ⚠️ No CTL/ATL found for date \(day) (activity: \(activity.name ?? "Unknown"))")
                    }
                } else {
                    Logger.error("  ❌ Failed to parse date: \(activity.startDateLocal) for activity: \(activity.name ?? "Unknown")")
                }
                
                return IntervalsActivity(
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
                    atl: activityATL,
                    ctl: activityCTL,
                    icuZoneTimes: activity.icuZoneTimes,
                    icuHrZoneTimes: activity.icuHrZoneTimes
                )
            }
            
            await MainActor.run {
                self.historicalActivities = activitiesWithLoad
                
                // Update cache metadata
                self.lastFetchTimestamp = Date().timeIntervalSince1970
                self.cachedActivityCount = activitiesWithLoad.count
            }
            
            Logger.data("TrainingLoadChart: Processed \(self.historicalActivities.count) activities with TSS")
            Logger.data("💾 Training Load: Cached \(activitiesWithLoad.count) activities (expires in \(Int(self.cacheValidityDuration/60))m)")
            
            // Debug: Log first few activities with their CTL/ATL values
            for (index, activity) in activitiesWithLoad.prefix(5).enumerated() {
                Logger.data("  Activity \(index + 1): \(activity.name) - CTL: \(activity.ctl?.description ?? "nil"), ATL: \(activity.atl?.description ?? "nil")")
            }
        } catch {
            Logger.error("TrainingLoadChart: Failed to fetch activities: \(error)")
        }
    }
    
    // Conversion now handled by unified ActivityConverter utility
    
    private func generateTwentyOneDayTrend(
        rideDate: Date,
        ctlAfter: Double,
        atlAfter: Double,
        tss: Double,
        activities: [IntervalsActivity]
    ) -> [LoadDataPoint] {
        var data: [LoadDataPoint] = []
        let calendar = Calendar.current
        
        // Use ISO8601 formatter to match calculator
        // NOTE: Must handle both Intervals.icu (no timezone) and Strava (with 'Z')
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        iso8601Formatter.timeZone = TimeZone.current
        
        // Parse all activity dates and create a sorted array
        var activitiesWithDates: [(date: Date, ctl: Double, atl: Double)] = []
        for activity in activities {
            guard let activityDate = iso8601Formatter.date(from: activity.startDateLocal),
                  let ctl = activity.ctl,
                  let atl = activity.atl else { continue }
            activitiesWithDates.append((activityDate, ctl, atl))
        }
        
        // Sort by date (oldest first)
        activitiesWithDates.sort { $0.date < $1.date }
        
        // Silently process activities
        
        // 14 days of historical data
        for dayOffset in -13...0 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: rideDate) else { continue }
            
            let isRide = (dayOffset == 0)
            
            let ctlValue: Double
            let atlValue: Double
            
            // Find the most recent activity on or before this date
            let dayEnd = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: date)!)
            
            if let mostRecent = activitiesWithDates.last(where: { $0.date < dayEnd }) {
                ctlValue = mostRecent.ctl
                atlValue = mostRecent.atl
            } else {
                // No historical data yet - start from zero (CTL/ATL build from first activity)
                ctlValue = 0
                atlValue = 0
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
        
        Logger.data("TrainingLoadChart: Total data points = \(data.count) (14 past + 7 future)")
        
        // Format dates for logging
        let logFormatter = DateFormatter()
        logFormatter.dateFormat = "MMM d, yyyy"
        Logger.data("TrainingLoadChart: Date range = \(logFormatter.string(from: data.first?.date ?? Date())) to \(logFormatter.string(from: data.last?.date ?? Date()))")
        
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
