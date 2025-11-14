import SwiftUI

/// Training Load graph card using FitnessTrajectoryChart
struct TrainingLoadGraphCard: View {
    @StateObject private var viewModel = TrainingLoadGraphCardViewModel()
    
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: "Training Load & Form",
                subtitle: "2 months + projection"
            ),
            style: .standard
        ) {
            if !viewModel.chartData.isEmpty {
                TodayTrainingLoadChart(data: viewModel.chartData)
            } else {
                // Loading state
                VStack {
                    ProgressView()
                        .padding()
                }
                .frame(height: 200)
            }
        }
        .onAppear {
            Task {
                await viewModel.load()
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class TrainingLoadGraphCardViewModel: ObservableObject {
    @Published var chartData: [TrainingLoadDataPoint] = []
    
    func load() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        Logger.debug("📊 [TrainingLoadCard] Loading chart data")

        // Fetch from Core Data - 2 months of history
        // CTL/ATL are calculated via CacheManager.fetchIntervalsData() during refresh
        let context = PersistenceController.shared.container.viewContext
        let request = DailyScores.fetchRequest()
        
        guard let startDate = calendar.date(byAdding: .day, value: -60, to: today) else {
            Logger.debug("   ❌ Could not calculate start date")
            return
        }
        
        Logger.debug("   Fetching data from \(startDate) to \(today)")
        
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startDate as NSDate,
            today as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        let dailyScores = try? context.fetch(request)
        
        Logger.debug("   Fetched \(dailyScores?.count ?? 0) daily scores from Core Data")
        
        // Convert to data points
        var past60Days: [TrainingLoadDataPoint] = []
        
        for score in dailyScores ?? [] {
            guard let date = score.date, let load = score.load else {
                Logger.debug("   ⚠️ Skipping score - missing date or load")
                continue
            }
            
            past60Days.append(TrainingLoadDataPoint(
                date: date,
                ctl: load.ctl,
                atl: load.atl,
                tsb: load.tsb,
                isFuture: false
            ))
        }
        
        Logger.debug("   Created \(past60Days.count) data points")
        
        if !past60Days.isEmpty {
            let first = past60Days.first!
            let last = past60Days.last!
            Logger.debug("   First point: CTL=\(first.ctl), ATL=\(first.atl), TSB=\(first.tsb)")
            Logger.debug("   Last point: CTL=\(last.ctl), ATL=\(last.atl), TSB=\(last.tsb)")
            
            // Calculate ranges
            let ctlValues = past60Days.map { $0.ctl }
            let atlValues = past60Days.map { $0.atl }
            let tsbValues = past60Days.map { $0.tsb }
            
            Logger.debug("   CTL range: \(ctlValues.min() ?? 0) - \(ctlValues.max() ?? 0)")
            Logger.debug("   ATL range: \(atlValues.min() ?? 0) - \(atlValues.max() ?? 0)")
            Logger.debug("   TSB range: \(tsbValues.min() ?? 0) - \(tsbValues.max() ?? 0)")
        }
        
        // Project next 7 days (assuming no training)
        var lastCTL = past60Days.last?.ctl ?? 0
        var lastATL = past60Days.last?.atl ?? 0
        
        Logger.debug("   Starting projection with CTL=\(lastCTL), ATL=\(lastATL)")
        
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
        
        chartData = past60Days + projection
        
        Logger.debug("   ✅ Total chart data points: \(chartData.count)")
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

// MARK: - Preview

#Preview {
    TrainingLoadGraphCard()
        .padding()
        .background(Color.background.primary)
}
