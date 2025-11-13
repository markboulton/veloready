import Foundation
import HealthKit
import WidgetKit

/// Service for calculating daily strain scores using Whoop-like algorithm
@MainActor
class StrainScoreService: ObservableObject {
    static let shared = StrainScoreService()
    
    @Published var currentStrainScore: StrainScore?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let calculator = StrainDataCalculator()
    private let sleepScoreService = SleepScoreService.shared
    private let athleteZoneService = AthleteZoneService.shared
    private let cache = UnifiedCacheManager.shared
    
    // Algorithm version - increment to invalidate cache when algorithm changes
    private let algorithmVersion = 3 // v3: adjusted band boundaries (Hard: 11-16, Very Hard: 16+)
    
    // Prevent multiple concurrent calculations
    private var calculationTask: Task<Void, Never>?
    
    init() {
        // Load cached strain score synchronously for instant display (prevents empty rings)
        loadCachedStrainScoreSync()

        // Load cached strain score immediately for instant display
        loadCachedStrainScore()
    }

    /// Load cached strain score synchronously from UserDefaults for instant display
    /// This prevents empty rings when view re-renders due to network state changes
    private func loadCachedStrainScoreSync() {
        Logger.debug("🔍 [STRAIN SYNC] Starting synchronous load from UserDefaults")
        Logger.debug("🔍 [STRAIN SYNC] currentStrainScore BEFORE: \(currentStrainScore?.score ?? -1)")

        // Try loading from shared UserDefaults (fastest, always available)
        if let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") {
            if let score = sharedDefaults.value(forKey: "cachedStrainScore") as? Double {
                // Create a placeholder score with cached values
                // Map score to band (0-18 scale)
                let band: StrainScore.StrainBand
                if score < 6 {
                    band = .light
                } else if score < 11 {
                    band = .moderate
                } else if score < 16 {
                    band = .hard
                } else {
                    band = .veryHard
                }

                let strainScore = StrainScore(
                    score: score,
                    band: band,
                    subScores: StrainScore.SubScores(
                        cardioLoad: 0,
                        strengthLoad: 0,
                        nonExerciseLoad: 0,
                        recoveryFactor: 1.0
                    ),
                    inputs: StrainScore.StrainInputs(
                        continuousHRData: nil,
                        dailyTRIMP: nil,
                        cardioDailyTRIMP: nil,
                        cardioDurationMinutes: nil,
                        averageIntensityFactor: nil,
                        workoutTypes: nil,
                        strengthSessionRPE: nil,
                        strengthDurationMinutes: nil,
                        strengthVolume: nil,
                        strengthSets: nil,
                        muscleGroupsTrained: nil,
                        isEccentricFocused: nil,
                        dailySteps: nil,
                        activeEnergyCalories: nil,
                        nonWorkoutMETmin: nil,
                        hrvOvernight: nil,
                        hrvBaseline: nil,
                        rmrToday: nil,
                        rmrBaseline: nil,
                        sleepQuality: nil,
                        userFTP: nil,
                        userMaxHR: nil,
                        userRestingHR: nil,
                        userBodyMass: nil
                    ),
                    calculatedAt: Date()
                )

                currentStrainScore = strainScore
                Logger.debug("⚡💾 [STRAIN SYNC] Loaded cached strain score synchronously: \(score)")
                Logger.debug("🔍 [STRAIN SYNC] currentStrainScore AFTER: \(currentStrainScore?.score ?? -1)")
            } else {
                Logger.debug("⚠️ [STRAIN SYNC] No strain score found in UserDefaults")
            }
        } else {
            Logger.debug("❌ [STRAIN SYNC] Failed to access shared UserDefaults")
        }
    }
    
    /// Calculate today's strain score
    func calculateStrainScore() async {
        // Cancel any existing calculation
        calculationTask?.cancel()
        
        calculationTask = Task {
            await performCalculation()
        }
        
        await calculationTask?.value
    }
    
    private func performCalculation() async {
        print("💪 [STRAIN] Starting strain score calculation")
        Logger.debug("🔄 Starting strain score calculation")
        
        // Check if already loading to prevent multiple concurrent calculations
        guard !isLoading else {
            print("💪 [STRAIN] Already in progress, skipping")
            Logger.warning("️ Strain score calculation already in progress, skipping...")
            return
        }
        
        print("💪 [STRAIN] Setting isLoading = true")
        isLoading = true
        errorMessage = nil
        
        // Add timeout to prevent hanging
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 15_000_000_000) // 15 seconds
            throw CancellationError()
        }
        
        let calculationTask = Task {
            await performActualCalculation()
        }
        
        do {
            _ = try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await timeoutTask.value }
                group.addTask { await calculationTask.value }
                
                // Wait for first task to complete (either timeout or calculation)
                try await group.next()
                
                // Cancel the other task
                timeoutTask.cancel()
                calculationTask.cancel()
            }
            
            Logger.debug("✅ Strain score calculation completed successfully")
        } catch {
            if error is CancellationError {
                Logger.debug("⏰ Strain score calculation timed out after 15 seconds")
                errorMessage = "Calculation timed out. Please try again."
            } else {
                Logger.error("Strain score calculation error: \(error)")
                errorMessage = "Calculation failed: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    private func performActualCalculation() async {
        // CRITICAL CHECK: Don't calculate when HealthKit permissions are denied
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        // iOS 26 WORKAROUND: Use isAuthorized instead of getAuthorizationStatus() which is buggy
        print("💪 [STRAIN] Checking HealthKit authorization: \(HealthKitManager.shared.isAuthorized)")
        if !HealthKitManager.shared.isAuthorized {
            print("💪 [STRAIN] ❌ Not authorized - skipping calculation")
            Logger.error("Strain permissions not granted - skipping calculation")
            await MainActor.run {
                currentStrainScore = nil
                isLoading = false
            }
            return
        }
        
        print("💪 [STRAIN] ✅ Authorized - calculating real score")
        // Use real data
        let realScore = await calculateRealStrainScore()
        print("💪 [STRAIN] Real score calculated: \(realScore?.score ?? -1)")
        currentStrainScore = realScore
        print("💪 [STRAIN] currentStrainScore set to: \(currentStrainScore?.score ?? -1)")
        
        // Save to persistent cache for instant loading next time
        if let score = currentStrainScore {
            print("💪 [STRAIN] Saving score to cache: \(score.score)")
            saveStrainScoreToCache(score)
        }
    }
    
    // MARK: - Real Data Calculation
    
    private func calculateRealStrainScore() async -> StrainScore? {
        // Ensure sleep score is calculated first for recovery modulation
        await sleepScoreService.calculateSleepScore()
        
        // Delegate to calculator (runs on background thread)
        return await calculator.calculateStrainScore(
            sleepScore: sleepScoreService.currentSleepScore,
            ftp: getUserFTP(),
            maxHeartRate: getUserMaxHR(),
            restingHeartRate: getUserRestingHR(),
            bodyMass: getUserBodyMass()
        )
    }
    
    // All calculation logic has been moved to StrainDataCalculator actor
    
    // MARK: - Data Fetching
    // NOTE: fetchDailySteps() and fetchDailyActiveCalories() moved to HealthKitManager with caching
    
    /// Fetch training loads (CTL/ATL) from Intervals.icu or HealthKit
    private func fetchTrainingLoads() async -> (atl: Double?, ctl: Double?) {
        do {
            // Try Intervals.icu first (if available)
            // IntervalsCache deleted - use UnifiedActivityService
            let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 500, daysBack: 90)
            
            if let latestActivity = activities.first {
                Logger.data("Using Intervals.icu training loads: ATL=\(latestActivity.atl?.description ?? "nil"), CTL=\(latestActivity.ctl?.description ?? "nil")")
                return (latestActivity.atl, latestActivity.ctl)
            } else {
                Logger.warning("️ No Intervals.icu data, calculating from HealthKit")
                return await calculateTrainingLoadsFromHealthKit()
            }
        } catch {
            Logger.error("Intervals.icu not available: \(error)")
            Logger.warning("️ Calculating training loads from HealthKit")
            return await calculateTrainingLoadsFromHealthKit()
        }
    }
    
    /// Calculate training loads from HealthKit (fallback)
    private func calculateTrainingLoadsFromHealthKit() async -> (atl: Double?, ctl: Double?) {
        let calculator = TrainingLoadCalculator()
        let (ctl, atl) = await calculator.calculateTrainingLoad()
        return (atl, ctl)
    }
    
    // All data fetching and TRIMP calculation methods moved to StrainDataCalculator actor
    
    /// Calculate average intensity factor (kept for backward compatibility)
    private func calculateAverageIF(workouts: [HKWorkout]) async -> Double {
        let calculator = TRIMPCalculator()
        var totalTRIMP: Double = 0
        
        for workout in workouts {
            let trimp = await calculator.calculateTRIMP(for: workout)
            totalTRIMP += trimp
            
            let activityName: String
            switch workout.workoutActivityType {
            case .cycling: activityName = "Cycling"
            case .running: activityName = "Running"
            case .swimming: activityName = "Swimming"
            case .walking: activityName = "Walking"
            case .functionalStrengthTraining: activityName = "Strength"
            case .rowing: activityName = "Rowing"
            case .hiking: activityName = "Hiking"
            default: activityName = "Other"
            }
            
            Logger.debug("   Workout: \(activityName) - TRIMP: \(String(format: "%.1f", trimp))")
        }
        
        Logger.debug("🔍 Total TRIMP from \(workouts.count) workouts: \(String(format: "%.1f", totalTRIMP))")
        return totalTRIMP
    }
    
    // MARK: - TRIMP Calculation
    
    private func calculateTRIMPFromActivities(activities: [Activity]) -> Double {
        var totalTRIMP: Double = 0
        
        for activity in activities {
            Logger.debug("🔍 Processing activity '\(activity.name ?? "Unknown")' for TRIMP:")
            Logger.debug("   📊 Activity data: duration=\(activity.duration?.description ?? "nil"), avgHR=\(activity.averageHeartRate?.description ?? "nil"), tss=\(activity.tss?.description ?? "nil"), normalizedPower=\(activity.normalizedPower?.description ?? "nil")")
            
            // First try to use TSS (Training Stress Score) if available
            // TSS is a better metric for cycling and is directly comparable to TRIMP
            if let tss = activity.tss, tss > 0 {
                Logger.debug("   ✅ Using TSS: \(tss)")
                totalTRIMP += tss
                continue
            }
            
            // Fall back to HR-based TRIMP if TSS not available
            if let duration = activity.duration,
               let avgHR = activity.averageHeartRate,
               duration > 0 {
                
                // Simple TRIMP calculation based on average HR
                // This is a simplified version - ideally you'd have HR time series data
                let durationMinutes = duration / 60
                let hrReserve = calculateHeartRateReserve(averageHR: avgHR)
                let trimpForActivity = durationMinutes * hrReserve
                
                Logger.debug("   ✅ Using HR-based TRIMP: \(trimpForActivity) (duration: \(durationMinutes)m, avgHR: \(avgHR))")
                totalTRIMP += trimpForActivity
            } else if let duration = activity.duration, duration > 0 {
                // FALLBACK: Estimate TRIMP from duration alone for cycling activities
                // This handles the case where Strava doesn't include HR in summary but streams have it
                // Use a conservative estimate: assume moderate intensity (HR reserve ~0.6)
                let durationMinutes = duration / 60
                let estimatedHRReserve = 0.6  // Moderate intensity assumption
                let estimatedTRIMP = durationMinutes * estimatedHRReserve
                
                Logger.debug("   ⚠️ No HR data in summary - using duration-based estimate")
                Logger.debug("   ✅ Estimated TRIMP: \(estimatedTRIMP) (duration: \(durationMinutes)m, assumed moderate intensity)")
                totalTRIMP += estimatedTRIMP
            } else {
                Logger.debug("   ⚠️ No TSS, HR, or duration data available, skipping activity")
                Logger.debug("   🔍 Missing: duration=\(activity.duration == nil ? "YES" : "NO"), avgHR=\(activity.averageHeartRate == nil ? "YES" : "NO")")
            }
        }
        
        Logger.debug("🔍 Total TRIMP from activities: \(totalTRIMP)")
        return totalTRIMP
    }
    
    private func calculateHeartRateReserve(averageHR: Double) -> Double {
        let restingHR = getUserRestingHR() ?? 60
        let maxHR = getUserMaxHR() ?? 180
        
        guard maxHR > restingHR else { return 0 }
        
        let hrReserve = (averageHR - restingHR) / (maxHR - restingHR)
        return max(0, min(1, hrReserve))
    }
    
    private func calculateAverageIntensityFactor(activities: [Activity]) -> Double? {
        let activitiesWithIF = activities.compactMap { activity in
            activity.intensityFactor
        }
        
        guard !activitiesWithIF.isEmpty else { return nil }
        
        return activitiesWithIF.reduce(0, +) / Double(activitiesWithIF.count)
    }
    
    // MARK: - Helper Methods
    
    private func parseActivityDate(_ dateString: String) -> Date? {
        // Try ISO8601 first (with timezone)
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Try local format without timezone (2025-10-02T06:11:37)
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.timeZone = TimeZone.current
        return localFormatter.date(from: dateString)
    }
    
    // MARK: - User Settings Helpers
    
    private func getUserFTP() -> Double? {
        // Use adaptive FTP from AthleteProfileManager
        // This includes:
        // - Computed FTP from performance data (PRO: 120 days, FREE: 90 days)
        // - Manual FTP override (if user set it in Settings)
        // - Strava FTP fallback (for Strava-only users)
        return AthleteProfileManager.shared.profile.ftp
    }
    
    private func getUserMaxHR() -> Double? {
        // Use adaptive max HR from AthleteProfileManager
        return AthleteProfileManager.shared.profile.maxHR
    }
    
    private func getUserRestingHR() -> Double? {
        // Use resting HR from AthleteProfileManager
        return AthleteProfileManager.shared.profile.restingHR
    }
    
    private func getUserBodyMass() -> Double? {
        // Default body mass for testing - should be configurable
        return 75.0
    }
}

// MARK: - Persistent Caching Extension

extension StrainScoreService {
    
    /// Load cached strain score for instant display
    private func loadCachedStrainScore() {
        Task {
            // Use day-specific cache key for strain scores with algorithm version
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let cacheKey = "strain:v\(algorithmVersion):\(today.timeIntervalSince1970)"
            
            do {
                let cachedScore: StrainScore = try await cache.fetch(key: cacheKey, ttl: 86400) {
                    throw NSError(domain: "StrainScore", code: 404)
                }
                
                await MainActor.run {
                    currentStrainScore = cachedScore
                    Logger.debug("⚡ Loaded cached strain score: \(cachedScore.score)")
                }
            } catch {
                Logger.debug("📦 No cached strain score found")
            }
        }
    }
    
    /// Save strain score to persistent cache
    private func saveStrainScoreToCache(_ score: StrainScore) {
        Task {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let cacheKey = "strain:v\(algorithmVersion):\(today.timeIntervalSince1970)"
            
            do {
                let _ = try await cache.fetch(key: cacheKey, ttl: 86400) {
                    return score
                }
                Logger.debug("💾 Saved strain score to cache: \(score.score)")
            } catch {
                Logger.error("Failed to save strain score to cache: \(error)")
            }
            
            // Also save to shared UserDefaults for widget
            if let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") {
                sharedDefaults.set(score.score, forKey: "cachedStrainScore")
                Logger.debug("⌚ Synced strain score to shared defaults for widget")
                
                // Reload widgets to show new data
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
