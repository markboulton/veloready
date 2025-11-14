import SwiftUI
import Charts

/// Training Load chart showing 21-day CTL/ATL/TSB trend (14 days past + 7 days future projection)
/// Shows ACTUAL peaks/troughs from real wellness data
/// Works with both Strava and Intervals.icu data
/// PRO Feature
struct TrainingLoadChart: View {
    let activity: Activity
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @State private var historicalActivities: [Activity] = []
    @State private var isLoading = false
    @State private var loadedActivityId: String? = nil // Track which activity we've loaded data for
    @State private var loadingState: LoadingState = .initial // Track CTL/ATL loading state
    
    // Cache metadata (persists across app restarts)
    @AppStorage("trainingLoadLastFetch") private var lastFetchTimestamp: Double = 0
    @AppStorage("trainingLoadActivityCount") private var cachedActivityCount: Int = 0
    private let cacheValidityDuration: TimeInterval = 3600  // 1 hour
    
    enum LoadingState {
        case initial
        case loading
        case loaded
    }
    
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
        
        // Find this activity in historicalActivities to get its actual CTL/ATL
        let matchedActivity = historicalActivities.first(where: { $0.id == activity.id })
        let ctlAfter = matchedActivity?.ctl ?? activity.ctl ?? 0
        let atlAfter = matchedActivity?.atl ?? activity.atl ?? 0
        
        // Only log when state actually changes
        if loadingState == .loaded {
            Logger.data("TrainingLoadChart: Rendering chart - TSS: \(tss), CTL: \(String(format: "%.1f", ctlAfter)), ATL: \(String(format: "%.1f", atlAfter))")
        } else if loadingState == .loading {
            Logger.data("TrainingLoadChart: Loading training load data...")
        }
        
        let tsbAfter = ctlAfter - atlAfter
        
        // Generate 21-day trend (14 past + 7 future) with REAL historical data
        let chartData = generateTwentyOneDayTrend(
            rideDate: rideDate,
            ctlAfter: ctlAfter,
            atlAfter: atlAfter,
            tss: tss,
            activities: historicalActivities
        )
        
        // Convert LoadDataPoint to TrainingLoadDataPoint for the unified component
        let chartViewData = chartData.map { point in
            TrainingLoadDataPoint(
                date: point.date,
                ctl: point.ctl,
                atl: point.atl,
                tsb: point.tsb,
                isFuture: point.isFuture
            )
        }
        
        return AnyView(
            ChartCard(
                title: TrainingLoadContent.title,
                subtitle: "21-day CTL/ATL/TSB trend"
            ) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Use unified chart component
                    TrainingLoadChartView(data: chartViewData)
                    
                    Divider()
                    
                    // Current metrics
                    HStack(spacing: Spacing.sm) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(ColorScale.blueAccent)
                                .frame(width: 7, height: 7)
                            Text(TrainingLoadContent.Metrics.ctl)
                                .font(.system(size: 10))
                                .foregroundColor(Color.text.secondary)
                            Text(String(format: "%.0f", ctlAfter))
                                .font(.system(size: 10))
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(ColorScale.amberAccent)
                                .frame(width: 7, height: 7)
                            Text(TrainingLoadContent.Metrics.atl)
                                .font(.system(size: 10))
                                .foregroundColor(Color.text.secondary)
                            Text(String(format: "%.0f", atlAfter))
                                .font(.system(size: 10))
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(tsbGradientColor(tsbAfter))
                                .frame(width: 7, height: 7)
                            Text(TrainingLoadContent.Metrics.tsb)
                                .font(.system(size: 10))
                                .foregroundColor(Color.text.secondary)
                            Text(String(format: "%.0f", tsbAfter))
                                .font(.system(size: 10))
                                .fontWeight(.semibold)
                        }
                    }
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
                loadingState = .loading
                await loadHistoricalActivities(rideDate: rideDate)
                loadingState = .loaded
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
            
            // For historical rides beyond 120 days, fetch directly from backend to bypass the cap
            // UnifiedActivityService has a 120-day cap, but we need more for old rides
            let activities: [Activity]
            if totalDaysBack > 120 {
                Logger.data("TrainingLoadChart: Historical ride detected - fetching \(totalDaysBack) days directly from backend")
                // Request more activities (500 instead of 200) to ensure we get older rides
                // Backend may have its own daysBack cap, but we can get more activities per request
                let stravaActivities = try await VeloReadyAPIClient.shared.fetchActivities(daysBack: totalDaysBack, limit: 500)
                activities = ActivityConverter.stravaToActivity(stravaActivities)
            } else {
                activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 200, daysBack: totalDaysBack)
            }
            
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
            let progressiveLoad = await calculator.calculateProgressiveTrainingLoad(enrichedActivities)
            
            // Date formatter for matching activity dates (must match calculator's parser!)
            // NOTE: Intervals.icu returns dates WITHOUT timezone suffix (e.g., "2025-10-16T06:33:05")
            // Strava returns dates WITH timezone suffix (e.g., "2025-10-16T06:33:05Z")
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
            iso8601Formatter.timeZone = TimeZone.current
            
            // Add CTL/ATL to activities that have TSS
            let activitiesWithLoad = enrichedActivities.filter { $0.tss != nil }.map { activity -> Activity in
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
                
                return Activity(
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
            
            // OFFLINE FALLBACK: Load from Core Data instead
            if let networkError = error as? NetworkError {
                switch networkError {
                case .offline:
                    Logger.debug("📱 [OFFLINE] TrainingLoadChart: Falling back to Core Data cached training load")
                    await loadFromCoreData(rideDate: rideDate)
                default:
                    break
                }
            }
        }
    }
    
    // Conversion now handled by unified ActivityConverter utility
    
    private func generateTwentyOneDayTrend(
        rideDate: Date,
        ctlAfter: Double,
        atlAfter: Double,
        tss: Double,
        activities: [Activity]
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
    
    /// Load training load data from Core Data (offline fallback)
    private func loadFromCoreData(rideDate: Date) async {
        let calendar = Calendar.current
        let earliestDate = calendar.date(byAdding: .day, value: -42, to: rideDate) ?? rideDate
        
        // Fetch from Core Data (DailyScores with DailyLoad relationship)
        let context = PersistenceController.shared.container.viewContext
        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            earliestDate as NSDate,
            rideDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        guard let dailyScores = try? context.fetch(request) else {
            Logger.error("📱 [OFFLINE] Failed to fetch from Core Data")
            return
        }
        
        Logger.debug("📱 [OFFLINE] Loaded \(dailyScores.count) days from Core Data")
        
        // Convert to activities with CTL/ATL
        var activitiesWithLoad: [Activity] = []
        
        for score in dailyScores {
            guard let date = score.date,
                  let load = score.load,
                  load.ctl > 0 || load.atl > 0 else { continue }
            
            // Create a synthetic activity for this day
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
            dateFormatter.timeZone = TimeZone.current
            let dateString = dateFormatter.string(from: date)
            
            let syntheticActivity = Activity(
                id: "core-data-\(dateString)",
                name: "Training Load",
                description: nil,
                startDateLocal: dateString,
                type: "Ride",
                duration: nil,
                distance: nil,
                elevationGain: nil,
                averagePower: nil,
                normalizedPower: nil,
                averageHeartRate: nil,
                maxHeartRate: nil,
                averageCadence: nil,
                averageSpeed: nil,
                maxSpeed: nil,
                calories: nil,
                fileType: nil,
                tss: load.tss > 0 ? load.tss : nil,
                intensityFactor: nil,
                atl: load.atl,
                ctl: load.ctl,
                icuZoneTimes: nil,
                icuHrZoneTimes: nil
            )
            
            activitiesWithLoad.append(syntheticActivity)
        }
        
        await MainActor.run {
            self.historicalActivities = activitiesWithLoad
            Logger.debug("📱 [OFFLINE] Loaded \(activitiesWithLoad.count) activities from Core Data")
        }
    }
    
    /// TSB gradient color based on training zones
    /// High Risk (<-30): Red, Optimal (-30 to -10): Green, Grey Zone (-10 to +5): Grey,
    /// Fresh (+5 to +20): Blue, Transition (>+20): Yellow
    private func tsbGradientColor(_ tsb: Double) -> Color {
        if tsb < -30 {
            return ColorScale.redAccent  // High Risk
        } else if tsb < -10 {
            return ColorScale.greenAccent  // Optimal
        } else if tsb < 5 {
            return Color.text.tertiary  // Grey Zone
        } else if tsb < 20 {
            return ColorScale.blueAccent  // Fresh
        } else {
            return ColorScale.amberAccent  // Transition
        }
    }
    
    private func tsbColor(_ tsb: Double) -> Color {
        // Keep old function for backwards compatibility
        return tsbGradientColor(tsb)
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
