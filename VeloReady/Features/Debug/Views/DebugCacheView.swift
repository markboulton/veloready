import SwiftUI
import CoreData

#if DEBUG
/// Debug view for cache and Core Data management
struct DebugCacheView: View {
    @State private var showingClearCacheAlert = false
    @State private var showingClearCoreDataAlert = false
    @State private var cacheCleared = false
    @State private var coreDataCleared = false
    @State private var isCleaningDuplicates = false
    @State private var duplicatesCleanedCount: Int?
    @State private var isRunningBackfill = false
    @State private var backfillComplete = false
    
    var body: some View {
        Form {
            cacheArchitectureSection
            stravaSection
            intervalsSection
            healthKitSection
            scoresSection
            coreDataSection
            backfillSection
            cleanupSection
        }
        .navigationTitle("Cache")
        .alert("Clear Intervals Cache?", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearIntervalsCache()
            }
        } message: {
            VRText("This will clear all cached Intervals.icu data from UserDefaults.", style: .body)
        }
        .alert("Clear Core Data?", isPresented: $showingClearCoreDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCoreData()
            }
        } message: {
            VRText("This will delete all Core Data records. The app will need to re-fetch all data.", style: .body)
        }
    }
    
    // MARK: - Cache Architecture Section
    
    private var cacheArchitectureSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("3-Layer Cache System")
                    .font(.heading)
                Text("Memory → Disk → Core Data with automatic fallback")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Architecture")
        }
    }
    
    // MARK: - Strava Section
    
    private var stravaSection: some View {
        Section {
            Button(action: {
                Task {
                    await CacheOrchestrator.shared.invalidate(matching: "strava:.*")
                    Logger.debug("🗑️ Cleared Strava cache")
                }
            }) {
                Label("Clear Strava Activities", systemImage: Icons.Document.trash)
            }
            
            Button(action: {
                Task {
                    await CacheOrchestrator.shared.invalidate(matching: "strava_athlete")
                    Logger.debug("🗑️ Cleared Strava athlete data")
                }
            }) {
                Label("Clear Athlete Info", systemImage: Icons.Document.trash)
            }
        } header: {
            Label("Strava", systemImage: "figure.outdoor.cycle")
        } footer: {
            VRText("Activities (90/365 days), streams, athlete profile", style: .caption, color: .secondary)
        }
    }
    
    // MARK: - Intervals Section
    
    private var intervalsSection: some View {
        Section {
            Button(action: {
                Task {
                    await CacheOrchestrator.shared.invalidate(matching: "intervals:.*")
                    Logger.debug("🗑️ Cleared Intervals cache")
                }
            }) {
                Label("Clear Intervals Activities", systemImage: Icons.Document.trash)
            }
            
            Button(action: {
                Task {
                    await CacheOrchestrator.shared.invalidate(matching: "intervals:wellness:.*")
                    Logger.debug("🗑️ Cleared wellness data")
                }
            }) {
                Label("Clear Wellness Data", systemImage: Icons.Document.trash)
            }
        } header: {
            Label("Intervals.icu", systemImage: "chart.line.uptrend.xyaxis")
        } footer: {
            VRText("Activities, wellness, training load (CTL/ATL/TSB)", style: .caption, color: .secondary)
        }
    }
    
    // MARK: - HealthKit Section
    
    private var healthKitSection: some View {
        Section {
            Button(action: {
                Task {
                    await CacheOrchestrator.shared.invalidate(matching: "healthkit:.*")
                    Logger.debug("🗑️ Cleared HealthKit cache")
                }
            }) {
                Label("Clear HealthKit Data", systemImage: Icons.Document.trash)
            }
        } header: {
            Label("HealthKit", systemImage: Icons.Health.heartFill)
        } footer: {
            VRText("HRV, RHR, sleep, steps, calories, respiratory rate", style: .caption, color: .secondary)
        }
    }
    
    // MARK: - Scores Section
    
    private var scoresSection: some View {
        Section {
            Button(action: {
                Task {
                    await CacheOrchestrator.shared.invalidate(matching: "score:.*")
                    Logger.debug("🗑️ Cleared score caches")
                }
            }) {
                Label("Clear All Scores", systemImage: Icons.Document.trash)
            }
            
            Button(action: {
                Task {
                    await CacheOrchestrator.shared.invalidate(matching: "baselines:.*")
                    Logger.debug("🗑️ Cleared baselines")
                }
            }) {
                Label("Clear Baselines", systemImage: Icons.Document.trash)
            }
        } header: {
            Label("Scores & Baselines", systemImage: Icons.System.chart)
        } footer: {
            VRText("Recovery, sleep, strain scores and 7-day baselines", style: .caption, color: .secondary)
        }
    }
    
    // MARK: - Core Data Section
    
    private var coreDataSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Daily scores, baselines, and historical data stored in Core Data")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showingClearCoreDataAlert = true
                }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: Icons.Document.trash)
                        VRText("Clear Core Data", style: .body)
                    }
                }
                .buttonStyle(.bordered)
                .tint(ColorScale.redAccent)
                
                if coreDataCleared {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: Icons.Status.successFill)
                            .foregroundColor(ColorScale.greenAccent)
                        VRText("Core Data cleared successfully", style: .caption, color: ColorScale.greenAccent)
                    }
                }
            }
        } header: {
            Label("Core Data", systemImage: Icons.System.database)
        } footer: {
            VRText(
                "Clear cached data to force a fresh fetch from APIs. Use with caution.",
                style: .caption,
                color: .secondary
            )
        }
    }
    
    // MARK: - Backfill Section
    
    private var backfillSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Fetch historical HealthKit data and recalculate all scores")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    Task {
                        isRunningBackfill = true
                        backfillComplete = false
                        Logger.info("🔄 [DEBUG] Force backfill triggered - fetching HealthKit data + recalculating scores")
                        await BackfillService.shared.backfillAll(days: 60, forceRefresh: true)
                        Logger.info("✅ [DEBUG] Backfill complete")
                        isRunningBackfill = false
                        backfillComplete = true
                    }
                }) {
                    HStack(spacing: Spacing.sm) {
                        if isRunningBackfill {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        VRText(isRunningBackfill ? "Backfilling..." : "Force Backfill (60 days)", style: .body)
                    }
                }
                .buttonStyle(.bordered)
                .tint(ColorScale.blueAccent)
                .disabled(isRunningBackfill)
                
                if backfillComplete {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: Icons.Status.successFill)
                            .foregroundColor(ColorScale.greenAccent)
                        VRText("Backfill complete - check charts", style: .caption, color: ColorScale.greenAccent)
                    }
                    .transition(.opacity)
                }
            }
        } header: {
            Label("Historical Scores", systemImage: "chart.line.uptrend.xyaxis")
        } footer: {
            VRText(
                "Fetches 60 days of HealthKit data (HRV, RHR, sleep), calculates training load, then recalculates all recovery, sleep, and strain scores. Takes ~30 seconds.",
                style: .caption,
                color: .secondary
            )
        }
    }
    
    // MARK: - Cleanup Section
    
    private var cleanupSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Remove duplicate and empty Core Data entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    Task {
                        isCleaningDuplicates = true
                        let cleanup = CoreDataCleanup()
                        await cleanup.runFullCleanup()
                        isCleaningDuplicates = false
                        duplicatesCleanedCount = 42
                    }
                }) {
                    HStack(spacing: Spacing.sm) {
                        if isCleaningDuplicates {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: Icons.System.sparkles)
                        }
                        VRText(isCleaningDuplicates ? "Cleaning..." : "Clean Now", style: .body)
                    }
                }
                .buttonStyle(.bordered)
                .tint(ColorScale.blueAccent)
                .disabled(isCleaningDuplicates)
                
                if let count = duplicatesCleanedCount {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: Icons.Status.successFill)
                            .foregroundColor(ColorScale.greenAccent)
                        VRText("Cleaned \(count) entries", style: .caption, color: ColorScale.greenAccent)
                    }
                }
            }
        } header: {
            Label("Data Cleanup", systemImage: Icons.System.sparkles)
        }
    }
    
    // MARK: - Helper Functions
    
    private func clearIntervalsCache() {
        Task {
            await CacheOrchestrator.shared.invalidate(matching: "intervals:.*")
            Logger.debug("🗑️ Cleared Intervals.icu cache")
        }
        cacheCleared = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            cacheCleared = false
        }
    }
    
    private func clearCoreData() {
        Task {
            // Clear Core Data entities
            let context = PersistenceController.shared.container.viewContext
            let entities = ["DailyScores", "DailyPhysio", "DailyLoad", "MLTrainingData"]
            for entity in entities {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try? context.execute(deleteRequest)
            }
            Logger.debug("🗑️ Cleared Core Data")
        }
        coreDataCleared = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            coreDataCleared = false
        }
    }
}

#Preview {
    NavigationStack {
        DebugCacheView()
    }
}
#endif
