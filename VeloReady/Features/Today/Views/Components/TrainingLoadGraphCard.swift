import SwiftUI
import CoreData

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

        // STRATEGY: Try Intervals.icu/Wahoo data from Core Data first, fallback to progressive calculation

        // Step 1: Try to fetch from Core Data (Intervals.icu or Wahoo values)
        guard let displayStartDate = calendar.date(byAdding: .day, value: -13, to: today) else {
            Logger.debug("   ❌ Could not calculate display start date")
            return
        }

        let coreDataPoints = await fetchFromCoreData(from: displayStartDate, to: today)

        // Step 2: Check if we have sufficient Core Data coverage
        let expectedDays = 14 // 14 days including today
        let coreDataCoverage = Double(coreDataPoints.count) / Double(expectedDays)

        Logger.debug("   📊 Core Data coverage: \(coreDataPoints.count)/\(expectedDays) days (\(String(format: "%.0f%%", coreDataCoverage * 100)))")

        var historical: [TrainingLoadDataPoint] = []

        if coreDataCoverage >= 0.5 {
            // Use Core Data values (Intervals.icu or Wahoo)
            Logger.debug("   ✅ Using Intervals.icu/Wahoo values from Core Data")
            historical = coreDataPoints

            // Fill in any missing days with interpolation
            if coreDataPoints.count < expectedDays {
                Logger.debug("   📊 Filling \(expectedDays - coreDataPoints.count) missing days with interpolation")
                historical = fillMissingDays(coreDataPoints, from: displayStartDate, to: today)
            }
        } else {
            // Fallback to progressive calculation with smart baseline seeding
            Logger.debug("   ⚠️ Insufficient Core Data - using progressive calculation with baseline seeding")
            historical = await calculateProgressiveWithBaseline(from: displayStartDate, to: today)
        }

        // Step 3: Generate future projection
        var lastCTL = historical.last?.ctl ?? 0
        var lastATL = historical.last?.atl ?? 0

        Logger.debug("   📊 Starting projection from CTL=\(String(format: "%.1f", lastCTL)), ATL=\(String(format: "%.1f", lastATL))")

        let projection = (1...7).compactMap { offset -> TrainingLoadDataPoint? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }

            // Decay using exponential formula (no training assumed)
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

        chartData = historical + projection

        // Cache the results
        cachedChartData = chartData
        cacheTimestamp = Date()

        Logger.debug("   ✅ Chart ready: \(historical.count) historical + \(projection.count) future = \(chartData.count) total")

        if let first = historical.first, let last = historical.last {
            Logger.debug("   📊 CTL range: \(String(format: "%.1f", first.ctl)) → \(String(format: "%.1f", last.ctl))")
            Logger.debug("   📊 ATL range: \(String(format: "%.1f", first.atl)) → \(String(format: "%.1f", last.atl))")
        }
    }

    // MARK: - Core Data Fetching (Intervals.icu / Wahoo values)

    private func fetchFromCoreData(from startDate: Date, to endDate: Date) async -> [TrainingLoadDataPoint] {
        let context = PersistenceController.shared.container.viewContext
        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        guard let dailyScores = try? context.fetch(request) else {
            Logger.debug("   ❌ Core Data fetch failed")
            return []
        }

        var points: [TrainingLoadDataPoint] = []

        for score in dailyScores {
            guard let date = score.date, let load = score.load else { continue }

            // Only include if we have valid CTL/ATL data
            guard load.ctl > 0 || load.atl > 0 else { continue }

            points.append(TrainingLoadDataPoint(
                date: date,
                ctl: load.ctl,
                atl: load.atl,
                tsb: load.tsb,
                isFuture: false
            ))
        }

        Logger.debug("   📊 Fetched \(points.count) days from Core Data with CTL/ATL")

        return points
    }

    // MARK: - Progressive Calculation with Baseline Seeding

    private func calculateProgressiveWithBaseline(from startDate: Date, to endDate: Date) async -> [TrainingLoadDataPoint] {
        do {
            // Fetch activities for calculation
            let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 200, daysBack: 42)
            Logger.debug("   📊 Fetched \(activities.count) activities for progressive calculation")

            // Get FTP for TSS enrichment
            let profileManager = await MainActor.run { AthleteProfileManager.shared }
            let ftp = profileManager.profile.ftp

            // Enrich activities with TSS
            let enrichedActivities = activities.map { activity in
                ActivityConverter.enrichWithMetrics(activity, ftp: ftp)
            }

            // SMART BASELINE SEEDING: Try to get baseline CTL/ATL from most recent activity or Core Data
            let (baselineCTL, baselineATL) = await getBaselineFromIntervalsOrActivities(enrichedActivities)

            if baselineCTL > 0 || baselineATL > 0 {
                Logger.debug("   🎯 Seeding calculation with baseline: CTL=\(String(format: "%.1f", baselineCTL)), ATL=\(String(format: "%.1f", baselineATL))")
            } else {
                Logger.debug("   ⚠️ No baseline found - starting from zero (Strava-only mode)")
            }

            // Calculate progressive CTL/ATL using seeded baseline
            let calculator = TrainingLoadCalculator()
            let progressiveLoad = await calculator.calculateProgressiveTrainingLoad(
                enrichedActivities,
                startingCTL: baselineCTL,
                startingATL: baselineATL
            )

            // Convert to data points for display window
            var points: [TrainingLoadDataPoint] = []
            let calendar = Calendar.current
            var currentDate = startDate

            while currentDate <= endDate {
                let dayStart = calendar.startOfDay(for: currentDate)

                let load = progressiveLoad[dayStart]
                let ctl = load?.ctl ?? baselineCTL // Use baseline if no activity that day
                let atl = load?.atl ?? baselineATL
                let tsb = ctl - atl

                points.append(TrainingLoadDataPoint(
                    date: dayStart,
                    ctl: ctl,
                    atl: atl,
                    tsb: tsb,
                    isFuture: false
                ))

                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }

            Logger.debug("   ✅ Progressive calculation complete: \(points.count) days")

            return points
        } catch {
            Logger.error("   ❌ Progressive calculation failed: \(error)")
            return []
        }
    }

    // MARK: - Smart Baseline Detection

    private func getBaselineFromIntervalsOrActivities(_ activities: [Activity]) async -> (ctl: Double, atl: Double) {
        // Strategy 1: Try to get baseline from most recent Intervals.icu activity
        let intervalsActivities = activities.filter { $0.ctl != nil && $0.atl != nil }
        if let mostRecent = intervalsActivities.max(by: { $0.startDateLocal < $1.startDateLocal }) {
            Logger.debug("   🎯 Found baseline from Intervals.icu activity: CTL=\(mostRecent.ctl ?? 0), ATL=\(mostRecent.atl ?? 0)")
            return (mostRecent.ctl ?? 0, mostRecent.atl ?? 0)
        }

        // Strategy 2: Try to get baseline from Core Data (most recent day with data)
        let context = PersistenceController.shared.container.viewContext
        let request = DailyScores.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = 1

        if let mostRecentScore = try? context.fetch(request).first,
           let load = mostRecentScore.load,
           (load.ctl > 0 || load.atl > 0) {
            Logger.debug("   🎯 Found baseline from Core Data: CTL=\(load.ctl), ATL=\(load.atl)")
            return (load.ctl, load.atl)
        }

        // Strategy 3: No baseline found - pure Strava mode (start from 0)
        Logger.debug("   ⚠️ No baseline found - using zero (Strava-only fallback)")
        return (0, 0)
    }

    // MARK: - Interpolation Helper

    private func fillMissingDays(_ points: [TrainingLoadDataPoint], from startDate: Date, to endDate: Date) -> [TrainingLoadDataPoint] {
        guard !points.isEmpty else { return [] }

        var filled: [TrainingLoadDataPoint] = []
        let calendar = Calendar.current
        var currentDate = startDate

        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)

            // Check if we have data for this day
            if let existingPoint = points.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) {
                filled.append(existingPoint)
            } else {
                // Interpolate from nearest points
                let before = points.last(where: { $0.date < dayStart })
                let after = points.first(where: { $0.date > dayStart })

                if let before = before, let after = after {
                    // Linear interpolation
                    let totalDays = calendar.dateComponents([.day], from: before.date, to: after.date).day ?? 1
                    let daysFromBefore = calendar.dateComponents([.day], from: before.date, to: dayStart).day ?? 0
                    let ratio = Double(daysFromBefore) / Double(totalDays)

                    let interpolatedCTL = before.ctl + (after.ctl - before.ctl) * ratio
                    let interpolatedATL = before.atl + (after.atl - before.atl) * ratio
                    let interpolatedTSB = interpolatedCTL - interpolatedATL

                    filled.append(TrainingLoadDataPoint(
                        date: dayStart,
                        ctl: interpolatedCTL,
                        atl: interpolatedATL,
                        tsb: interpolatedTSB,
                        isFuture: false
                    ))
                } else if let nearest = before ?? after {
                    // Use nearest point if only one side available
                    filled.append(TrainingLoadDataPoint(
                        date: dayStart,
                        ctl: nearest.ctl,
                        atl: nearest.atl,
                        tsb: nearest.tsb,
                        isFuture: false
                    ))
                }
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return filled
    }
}


// MARK: - Preview

#Preview {
    TrainingLoadGraphCard()
        .padding()
        .background(Color.background.primary)
}
