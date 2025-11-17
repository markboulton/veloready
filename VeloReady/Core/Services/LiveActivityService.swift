import Foundation
import HealthKit

/// Service for managing live activity data (calories and steps)
@MainActor
class LiveActivityService: ObservableObject {
    static let shared = LiveActivityService()
    
    @Published var dailySteps: Int = 0
    @Published var walkingDistance: Double = 0  // in kilometers
    @Published var dailyCalories: Double = 0
    @Published var activeCalories: Double = 0
    @Published var bmrCalories: Double = 0
    @Published var intervalsCalories: Double = 0
    @Published var isLoading = false
    var lastUpdated: Date?
    
    private let healthKitManager = HealthKitManager.shared
    private let userSettings = UserSettings.shared

    // Prevent multiple concurrent updates
    private var updateTask: Task<Void, Never>?
    private var updateTimer: Timer?

    private init() {
        // Load cached data immediately on init
        loadCachedDataSync()
        
        Logger.debug("🎯 LiveActivityService singleton initialized with cached data")
    }
    
    /// Load cached data synchronously during initialization
    private func loadCachedDataSync() {
        // Check if cached data is from today
        let cachedDate = UserDefaults.standard.object(forKey: "cached_date") as? Date
        let calendar = Calendar.current
        let isToday = cachedDate.map { calendar.isDateInToday($0) } ?? false
        
        if !isToday {
            // Cached data is stale (from yesterday or earlier) - clear it
            Logger.debug("🗑️ Cached data is stale (last cached: \(cachedDate?.description ?? "never")) - skipping cache load")
            // Leave values at 0, fresh data will load shortly
            bmrCalories = calculateTodayBMR()
            dailyCalories = bmrCalories
            return
        }
        
        // Load cached HealthKit data (only if from today)
        let cachedSteps = UserDefaults.standard.integer(forKey: "cached_steps")
        let cachedWalkingDistance = UserDefaults.standard.double(forKey: "cached_walking_distance")
        let cachedActiveCalories = UserDefaults.standard.double(forKey: "cached_active_calories")
        
        // Load cached values even if 0 (user might have 0 steps early in the day)
        dailySteps = cachedSteps
        walkingDistance = cachedWalkingDistance
        activeCalories = cachedActiveCalories
        
        // Calculate BMR (this is fast)
        let bmrCaloriesValue = calculateTodayBMR()
        bmrCalories = bmrCaloriesValue
        
        // Calculate total calories
        let intervalsCaloriesValue = UserDefaults.standard.double(forKey: "cached_intervals_calories")
        let activeCaloriesValue = activeCalories + intervalsCaloriesValue
        dailyCalories = activeCaloriesValue + bmrCaloriesValue
        
        Logger.debug("📱 Loaded cached data during init (from today) - Steps: \(dailySteps), Active: \(activeCalories), Total: \(dailyCalories)")
    }
    
    /// Clear cached data to force fresh loading
    func clearCachedData() {
        Logger.debug("🗑️ Clearing cached live activity data to force fresh loading")
        Logger.debug("🎯 DEBUG: Setting isLoading = true to show spinners immediately")
        isLoading = true // Set loading state FIRST to show spinners immediately
        dailySteps = 0
        dailyCalories = 0
        activeCalories = 0
        bmrCalories = 0
        intervalsCalories = 0
        lastUpdated = Date.distantPast
        Logger.debug("🎯 DEBUG: Cached data cleared, isLoading = \(isLoading)")
    }
    
    /// Update live activity data immediately (for app foreground events)
    func updateLiveDataImmediately() async {
        // Cancel any existing update
        updateTask?.cancel()
        
        updateTask = Task {
            await performUpdate()
        }
        
        await updateTask?.value
    }
    
    /// Start automatic updates every 1 minute
    func startAutoUpdates() {
        // Prevent starting multiple update cycles
        guard updateTimer == nil else {
            Logger.warning("️ LiveActivityService auto-updates already running, skipping duplicate call")
            return
        }
        
        // Cancel any existing task
        updateTask?.cancel()
        updateTask = nil
        
        // Update immediately first
        Task {
            await updateLiveDataImmediately()
        }
        
        // Then update every 1 minute (reduced from 5 minutes for better responsiveness)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                await self.updateLiveDataImmediately()
            }
        }
        
        Logger.debug("🔄 LiveActivityService auto-updates started (60s intervals)")
    }
    
    /// Stop automatic updates
    func stopAutoUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
        updateTask?.cancel()
        updateTask = nil
    }
    
    private func performUpdate() async {
        // If already loading, just continue (don't skip)
        if isLoading {
            Logger.debug("🔄 LiveActivityService already loading - continuing with update")
        } else {
            Logger.debug("🔄 LiveActivityService starting update - setting isLoading = true")
            isLoading = true
        }
        
        // PHASE 1: Load cached data for immediate display (no delay)
        await loadCachedData()
        
        // PHASE 2: Update with fresh data from HealthKit
        await updateWithFreshData()
        
        Logger.debug("✅ LiveActivityService update completed - setting isLoading = false")
        isLoading = false
    }
    
    private func loadCachedData() async {
        Logger.debug("📱 Loading cached live activity data for immediate display")
        
        // Check if cached data is from today
        let cachedDate = UserDefaults.standard.object(forKey: "cached_date") as? Date
        let calendar = Calendar.current
        let isToday = cachedDate.map { calendar.isDateInToday($0) } ?? false
        
        if !isToday {
            // Cached data is stale - skip loading
            Logger.debug("🗑️ Cached data is stale (last cached: \(cachedDate?.description ?? "never")) - will fetch fresh")
            return
        }
        
        // Load cached HealthKit data (only if from today)
        let cachedSteps = UserDefaults.standard.integer(forKey: "cached_steps")
        let cachedWalkingDistance = UserDefaults.standard.double(forKey: "cached_walking_distance")
        let cachedActiveCalories = UserDefaults.standard.double(forKey: "cached_active_calories")
        
        // Load cached values even if 0
        dailySteps = cachedSteps
        walkingDistance = cachedWalkingDistance
        activeCalories = cachedActiveCalories
        Logger.debug("📱 Loaded cached steps: \(cachedSteps)")
        Logger.debug("📱 Loaded cached walking distance: \(cachedWalkingDistance)km")
        Logger.debug("📱 Loaded cached active calories: \(cachedActiveCalories)")
        
        // Calculate BMR (this is fast)
        let bmrCaloriesValue = calculateTodayBMR()
        bmrCalories = bmrCaloriesValue
        
        // Calculate total calories
        let intervalsCaloriesValue = UserDefaults.standard.double(forKey: "cached_intervals_calories")
        let activeCaloriesValue = activeCalories + intervalsCaloriesValue
        _ = userSettings.useBMRAsGoal ? bmrCaloriesValue : userSettings.calorieGoal
        dailyCalories = activeCaloriesValue + bmrCaloriesValue
        
        Logger.debug("📱 Cached data loaded - Steps: \(dailySteps), Active: \(activeCalories), Total: \(dailyCalories)")
    }
    
    private func updateWithFreshData() async {
        Logger.debug("🔄 Updating with fresh data from HealthKit and Intervals.icu")
        
        // Fetch HealthKit data
        let healthData = await healthKitManager.fetchTodayActivity()
        
        // Check if HealthKit data is valid (device might be locked)
        // If steps and activeCalories are both 0, and we have cached values > 0, device is likely locked
        let deviceLikelyLocked = (healthData.steps == 0 && healthData.activeCalories == 0) && 
                                 (dailySteps > 0 || activeCalories > 0)
        
        if deviceLikelyLocked {
            Logger.warning("⚠️ HealthKit returned 0 steps/calories - device may be locked - keeping cached values")
            // Keep existing values, don't overwrite with zeros
            // But still update BMR and Intervals data
            let intervalsCaloriesValue = await fetchTodayIntervalsCalories()
            let bmrCaloriesValue = calculateTodayBMR()
            
            bmrCalories = bmrCaloriesValue
            intervalsCalories = intervalsCaloriesValue
            dailyCalories = activeCalories + intervalsCaloriesValue + bmrCaloriesValue
            
            Logger.debug("📱 Preserved cached values - Steps: \(dailySteps), Active: \(activeCalories)")
            return
        }
        
        // Fetch Intervals.icu calories for today's rides
        let intervalsCaloriesValue = await fetchTodayIntervalsCalories()
        
        // Calculate BMR (Basal Metabolic Rate) for today
        let bmrCaloriesValue = calculateTodayBMR()
        
        // Calculate active calories (HealthKit + Intervals)
        let activeCaloriesValue = healthData.activeCalories + intervalsCaloriesValue
        
        // Get effective calorie goal (BMR or user-set)
        _ = userSettings.useBMRAsGoal ? bmrCaloriesValue : userSettings.calorieGoal
        
        // Update published properties with fresh data
        dailySteps = healthData.steps
        walkingDistance = healthData.walkingDistance
        activeCalories = activeCaloriesValue
        bmrCalories = bmrCaloriesValue
        intervalsCalories = intervalsCaloriesValue
        dailyCalories = activeCaloriesValue + bmrCaloriesValue
        lastUpdated = Date()
        
        // Cache the fresh data for next time with today's date
        UserDefaults.standard.set(healthData.steps, forKey: "cached_steps")
        UserDefaults.standard.set(healthData.walkingDistance, forKey: "cached_walking_distance")
        UserDefaults.standard.set(activeCaloriesValue, forKey: "cached_active_calories")
        UserDefaults.standard.set(intervalsCaloriesValue, forKey: "cached_intervals_calories")
        UserDefaults.standard.set(Date(), forKey: "cached_date") // Store timestamp to detect stale cache
        
        Logger.data("Live Activity Update:")
        Logger.debug("   Steps: \(dailySteps)")
        Logger.debug("   Active Calories: \(activeCaloriesValue)")
        Logger.debug("   Intervals Calories: \(intervalsCaloriesValue)")
        Logger.debug("   BMR Calories: \(bmrCaloriesValue)")
        Logger.debug("   Total Calories: \(dailyCalories)")
    }
    
    /// Fetch calories from today's Intervals.icu rides
    private func fetchTodayIntervalsCalories() async -> Double {
        do {
            // Fetch today's activities - USE CACHE to avoid unnecessary API calls
            let calendar = Calendar.current
            let today = Date()
            let startOfDay = calendar.startOfDay(for: today)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
            
            // Get activities from cache (prevents rate limiting)
            // IntervalsCache deleted - use UnifiedActivityService
            let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 100, daysBack: 7)
            
            // Filter for today's rides and sum calories
            let todayActivities = activities.filter { activity in
                guard let startDate = parseIntervalsDate(activity.startDateLocal) else { return false }
                return startDate >= startOfDay && startDate < endOfDay
            }
            
            let totalCalories = todayActivities.compactMap { $0.calories }.reduce(0, +)
            
            Logger.debug("🚴 Today's Intervals rides: \(todayActivities.count), Total calories: \(totalCalories)")
            
            return Double(totalCalories)
            
        } catch {
            Logger.error("Failed to fetch Intervals calories: \(error)")
            return 0.0
        }
    }
    
    /// Parse Intervals.icu date string to Date
    private func parseIntervalsDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone.current
        
        return formatter.date(from: dateString)
    }
    
    /// Calculate today's BMR (Basal Metabolic Rate) calories
    private func calculateTodayBMR() -> Double {
        // For now, use a simplified BMR calculation
        // In a real app, you'd want to get user's height, weight, age, and gender from HealthKit
        
        // Default values (you can make these configurable later)
        let weight: Double = 75.0 // kg (165 lbs)
        let height: Double = 175.0 // cm (5'9")
        let age: Int = 35 // years
        let isMale: Bool = true
        
        // Calculate BMR using Mifflin-St Jeor Equation
        let bmr: Double
        if isMale {
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        } else {
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        }
        
        // Calculate how much of the day has passed to estimate today's BMR
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let timeElapsed = now.timeIntervalSince(startOfDay)
        let totalDaySeconds: TimeInterval = 24 * 60 * 60 // 24 hours
        let dayProgress = timeElapsed / totalDaySeconds
        
        // Return BMR calories for the portion of the day that has passed
        let todayBMR = bmr * dayProgress
        
        Logger.debug("🧮 BMR Calculation:")
        Logger.debug("   Weight: \(weight) kg, Height: \(height) cm, Age: \(age), Male: \(isMale)")
        Logger.debug("   Daily BMR: \(bmr) kcal")
        Logger.debug("   Day Progress: \(String(format: "%.1f", dayProgress * 100))%")
        Logger.debug("   Today's BMR: \(String(format: "%.1f", todayBMR)) kcal")
        
        return todayBMR
    }
}
