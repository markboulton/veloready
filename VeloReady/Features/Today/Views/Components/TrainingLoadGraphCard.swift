import SwiftUI

/// Training Load graph card using FitnessTrajectoryChart
struct TrainingLoadGraphCard: View {
    @StateObject private var viewModel = TrainingLoadGraphCardViewModel()
    @State private var hasLoadedData = false
    
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: "Training Load & Form",
                subtitle: "21 days + projection"
            ),
            style: .standard
        ) {
            if !viewModel.chartData.isEmpty {
                TrainingLoadChartView(data: viewModel.chartData)
            } else {
                // Loading state
                VStack {
                    ProgressView()
                        .padding()
                }
                .frame(height: 200)
            }
        }
        .task {
            guard !hasLoadedData else {
                Logger.debug("⏭️ [TrainingLoadCard] Data already loaded, skipping")
                return
            }
            
            await viewModel.load()
            hasLoadedData = true
        }
        .onDisappear {
            hasLoadedData = false
        }
    }
}

// MARK: - ViewModel

@MainActor
class TrainingLoadGraphCardViewModel: ObservableObject {
    @Published var chartData: [TrainingLoadDataPoint] = []
    
    // In-memory cache with 5-minute TTL
    private var cachedChartData: [TrainingLoadDataPoint]?
    private var cacheTimestamp: Date?
    private let cacheTTL: TimeInterval = 300 // 5 minutes
    
    func load() async {
        // Check in-memory cache first
        if let cached = cachedChartData,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheTTL {
            Logger.debug("⚡ [TrainingLoadCard] Using in-memory cache")
            chartData = cached
            return
        }
        
        Logger.debug("🔄 [TrainingLoadCard] Fetching fresh data")
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        Logger.debug("📊 [TrainingLoadCard] Loading chart data using progressive calculation")

        // Fetch 42 days back to get proper CTL context, but only show last 14 days
        guard let startDate = calendar.date(byAdding: .day, value: -42, to: today) else {
            Logger.debug("   ❌ Could not calculate start date")
            return
        }

        Logger.debug("   Calculating training load from \(startDate) to \(today)")

        do {
            // Fetch activities for the past 42 days for proper CTL calculation
            let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 200, daysBack: 42)
            Logger.debug("   Fetched \(activities.count) activities")
            
            // Get FTP for TSS enrichment
            let profileManager = await MainActor.run { AthleteProfileManager.shared }
            let ftp = profileManager.profile.ftp
            
            // Enrich activities with TSS
            Logger.debug("   📊 FTP: \(ftp?.description ?? "nil")")
            let enrichedActivities = activities.map { activity in
                ActivityConverter.enrichWithMetrics(activity, ftp: ftp)
            }

            // Log TSS values for debugging
            let activitiesWithTSS = enrichedActivities.filter { $0.tss != nil && $0.tss! > 0 }
            Logger.debug("   📊 Activities with TSS: \(activitiesWithTSS.count)/\(enrichedActivities.count)")
            if !activitiesWithTSS.isEmpty {
                let tssValues = activitiesWithTSS.prefix(5).compactMap { $0.tss }.map { String(format: "%.0f", $0) }
                Logger.debug("   📊 First 5 TSS values: \(tssValues.joined(separator: ", "))")
            }

            // Calculate progressive CTL/ATL using TrainingLoadCalculator
            let calculator = TrainingLoadCalculator()
            let progressiveLoad = await calculator.calculateProgressiveTrainingLoad(enrichedActivities)

            Logger.debug("   Calculated progressive load for \(progressiveLoad.count) days")

            // Convert to data points - only show last 14 days
            var past14Days: [TrainingLoadDataPoint] = []

            // Start from 13 days ago (14 days including today)
            guard let displayStartDate = calendar.date(byAdding: .day, value: -13, to: today) else {
                Logger.debug("   ❌ Could not calculate display start date")
                return
            }

            // Generate data points for the last 14 days
            var currentDate = displayStartDate
            while currentDate <= today {
                let dayStart = calendar.startOfDay(for: currentDate)

                // Get load for this day (defaults to 0 if no activities)
                let load = progressiveLoad[dayStart]
                let ctl = load?.ctl ?? 0
                let atl = load?.atl ?? 0
                let tsb = ctl - atl

                past14Days.append(TrainingLoadDataPoint(
                    date: dayStart,
                    ctl: ctl,
                    atl: atl,
                    tsb: tsb,
                    isFuture: false
                ))

                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }

            Logger.debug("   Created \(past14Days.count) historical data points")

            if !past14Days.isEmpty {
                let first = past14Days.first!
                let last = past14Days.last!
                Logger.debug("   First point: CTL=\(first.ctl), ATL=\(first.atl), TSB=\(first.tsb)")
                Logger.debug("   Last point: CTL=\(last.ctl), ATL=\(last.atl), TSB=\(last.tsb)")
                
                // Calculate ranges
                let ctlValues = past14Days.map { $0.ctl }
                let atlValues = past14Days.map { $0.atl }
                let tsbValues = past14Days.map { $0.tsb }

                Logger.debug("   CTL range: \(String(format: "%.1f", ctlValues.min() ?? 0)) - \(String(format: "%.1f", ctlValues.max() ?? 0))")
                Logger.debug("   ATL range: \(String(format: "%.1f", atlValues.min() ?? 0)) - \(String(format: "%.1f", atlValues.max() ?? 0))")
                Logger.debug("   TSB range: \(String(format: "%.1f", tsbValues.min() ?? 0)) - \(String(format: "%.1f", tsbValues.max() ?? 0))")
            }

            // Project next 7 days (assuming no training)
            var lastCTL = past14Days.last?.ctl ?? 0
            var lastATL = past14Days.last?.atl ?? 0
            
            Logger.debug("   Starting projection with CTL=\(String(format: "%.1f", lastCTL)), ATL=\(String(format: "%.1f", lastATL))")
            
            let projection = (1...7).compactMap { offset -> TrainingLoadDataPoint? in
                guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
                
                // CTL decays with time constant of 42 days (6 weeks)
                // ATL decays with time constant of 7 days (1 week)
                lastCTL = lastCTL * exp(-1.0 / 42.0)
                lastATL = lastATL * exp(-1.0 / 7.0)
                
                let tsb = lastCTL - lastATL
                
                return TrainingLoadDataPoint(
                    date: date,
                    ctl: lastCTL,
                    atl: lastATL,
                    tsb: tsb,
                    isFuture: true
                )
            }
            
            Logger.debug("   Added \(projection.count) projection points")

            chartData = past14Days + projection
            
            // Cache the results
            cachedChartData = chartData
            cacheTimestamp = Date()

            Logger.debug("   ✅ Total chart data points: \(chartData.count) (14 historical + 7 future)")
        } catch {
            Logger.error("   ❌ Failed to load training load data: \(error)")
            chartData = []
        }
    }
}


// MARK: - Preview

#Preview {
    TrainingLoadGraphCard()
        .padding()
        .background(Color.background.primary)
}
