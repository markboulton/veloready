import Foundation

/// Configuration for Today page section ordering
/// Allows users to customize the order of movable sections
struct TodaySectionOrder: Codable {
    var movableSections: [TodaySection]
    var hiddenSections: [TodaySection]
    
    /// Default section order
    static let defaultOrder = TodaySectionOrder(
        movableSections: [
            .veloAI,
            .latestActivity,
            .steps,
            .calories,
            .performanceChart,
            .fitnessTrajectory,
            .recentActivities
        ],
        hiddenSections: []
    )
    
    /// UserDefaults key for persistence
    private static let userDefaultsKey = "todaySectionOrder"
    
    /// Load saved order from iCloud (if available) or UserDefaults
    static func load() -> TodaySectionOrder {
        // Try iCloud first
        if let iCloudOrder = loadFromiCloud() {
            return migrateIfNeeded(iCloudOrder)
        }
        
        // Fall back to UserDefaults
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let order = try? JSONDecoder().decode(TodaySectionOrder.self, from: data) else {
            return defaultOrder
        }
        return migrateIfNeeded(order)
    }
    
    /// Migrate old section orders to include new sections
    private static func migrateIfNeeded(_ order: TodaySectionOrder) -> TodaySectionOrder {
        var sections = order.movableSections
        var hidden = order.hiddenSections
        var needsSave = false
        
        // Remove dailyBrief if present (now unified with veloAI)
        if let dailyBriefIndex = sections.firstIndex(of: .dailyBrief) {
            sections.remove(at: dailyBriefIndex)
            Logger.debug("☁️ Migrated section order - removed duplicate Daily Brief (unified with VeloAI)")
            needsSave = true
        }
        
        // Migrate stepsAndCalories to separate steps and calories
        if let stepsAndCaloriesIndex = sections.firstIndex(of: .stepsAndCalories) {
            sections.remove(at: stepsAndCaloriesIndex)
            sections.insert(.calories, at: stepsAndCaloriesIndex)
            sections.insert(.steps, at: stepsAndCaloriesIndex)
            
            Logger.debug("☁️ Migrated stepsAndCalories to separate sections")
            needsSave = true
        }
        
        // Add new chart sections if not present (performanceChart, fitnessTrajectory)
        let allSections = sections + hidden
        if !allSections.contains(.performanceChart) {
            // Insert after calories or at end
            if let caloriesIndex = sections.firstIndex(of: .calories) {
                sections.insert(.performanceChart, at: caloriesIndex + 1)
            } else {
                sections.append(.performanceChart)
            }
            Logger.debug("☁️ Added performanceChart to section order")
            needsSave = true
        }
        
        if !allSections.contains(.fitnessTrajectory) {
            // Insert after performanceChart or at end
            if let perfIndex = sections.firstIndex(of: .performanceChart) {
                sections.insert(.fitnessTrajectory, at: perfIndex + 1)
            } else {
                sections.append(.fitnessTrajectory)
            }
            Logger.debug("☁️ Added fitnessTrajectory to section order")
            needsSave = true
        }
        
        if !allSections.contains(.formChart) {
            // FormChart can stay hidden by default or be added - let's add it hidden
            if !hidden.contains(.formChart) {
                hidden.append(.formChart)
                Logger.debug("☁️ Added formChart to hidden sections")
                needsSave = true
            }
        }
        
        if needsSave {
            // Save the migrated order
            let migratedOrder = TodaySectionOrder(movableSections: sections, hiddenSections: hidden)
            migratedOrder.save()
            return migratedOrder
        }
        
        return order
    }
    
    /// Save order to UserDefaults and sync to iCloud
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
            
            // Sync to iCloud if available
            Task {
                await syncToiCloud(data: data)
            }
        }
    }
    
    /// Sync section order to iCloud
    private func syncToiCloud(data: Data) async {
        // Check if iCloud is available (synchronous check)
        guard FileManager.default.ubiquityIdentityToken != nil else { return }
        
        let store = NSUbiquitousKeyValueStore.default
        store.set(data, forKey: "todaySectionOrder")
        store.synchronize()
        
        Logger.debug("☁️ Today section order synced to iCloud")
    }
    
    /// Load section order from iCloud (if available)
    static func loadFromiCloud() -> TodaySectionOrder? {
        // Check if iCloud is available (synchronous check)
        guard FileManager.default.ubiquityIdentityToken != nil else { return nil }
        
        let store = NSUbiquitousKeyValueStore.default
        guard let data = store.data(forKey: "todaySectionOrder"),
              let order = try? JSONDecoder().decode(TodaySectionOrder.self, from: data) else {
            return nil
        }
        
        Logger.debug("☁️ Today section order loaded from iCloud")
        return order
    }
    
    /// Reset to default order
    static func reset() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

/// Represents a section on the Today page
enum TodaySection: String, Codable, CaseIterable, Identifiable {
    case veloAI = "VeloAI"
    case dailyBrief = "Daily Brief"
    case latestActivity = "Latest Activity"
    case steps = "Steps"
    case calories = "Calories"
    case stepsAndCalories = "Steps & Calories" // Legacy - kept for migration
    case performanceChart = "Performance Chart"
    case formChart = "Training Form (CTL/ATL)"
    case fitnessTrajectory = "Fitness Trajectory"
    case recentActivities = "Recent Activities"
    
    var id: String { rawValue }
    
    /// Display name for the section
    var displayName: String {
        switch self {
        case .veloAI:
            return TodayContent.AIBrief.title
        case .dailyBrief:
            return "Daily Brief"
        case .latestActivity:
            return TodayContent.latestActivity
        case .steps:
            return "Steps"
        case .calories:
            return "Calories"
        case .stepsAndCalories:
            return "Steps & Calories"
        case .performanceChart:
            return "Performance Overview"
        case .formChart:
            return "Training Form"
        case .fitnessTrajectory:
            return "Fitness Trajectory"
        case .recentActivities:
            return TodayContent.activitiesSection
        }
    }
    
    /// Icon for the section
    var icon: String {
        switch self {
        case .veloAI:
            return Icons.System.sparkles
        case .dailyBrief:
            return Icons.System.docText
        case .latestActivity:
            return Icons.Activity.cycling
        case .steps:
            return Icons.Health.steps
        case .calories:
            return Icons.Health.caloriesFill
        case .stepsAndCalories:
            return Icons.Activity.walking
        case .performanceChart:
            return "chart.xyaxis.line"
        case .formChart:
            return "chart.line.uptrend.xyaxis"
        case .fitnessTrajectory:
            return "chart.line.uptrend.xyaxis.circle"
        case .recentActivities:
            return Icons.System.chartDoc
        }
    }
    
    /// Description for the section
    var description: String {
        switch self {
        case .veloAI:
            return "AI-powered daily insights and recommendations"
        case .dailyBrief:
            return "Your daily training summary and targets"
        case .latestActivity:
            return "Your most recent workout or ride"
        case .steps:
            return "Daily step count"
        case .calories:
            return "Active calories burned"
        case .stepsAndCalories:
            return "Daily step count and calorie tracking"
        case .performanceChart:
            return "2-week performance overlay: recovery, load & sleep"
        case .formChart:
            return "Training load balance (CTL, ATL & TSB)"
        case .fitnessTrajectory:
            return "2-week history + 1-week projection of fitness"
        case .recentActivities:
            return "List of your recent workouts"
        }
    }
    
    /// Whether this section requires PRO access
    var requiresPro: Bool {
        switch self {
        case .veloAI:
            return true
        case .performanceChart, .formChart, .fitnessTrajectory:
            return true
        case .dailyBrief, .latestActivity, .steps, .calories, .stepsAndCalories, .recentActivities:
            return false
        }
    }
    
    /// Whether this section is movable (can be reordered)
    var isMovable: Bool {
        return true // All sections in this enum are movable
    }
}

/// Fixed sections that cannot be reordered
enum TodayFixedSection {
    case compactRings
    case missingSleepBanner
    case healthKitEnablement
    
    var displayName: String {
        switch self {
        case .compactRings:
            return "Recovery Metrics"
        case .missingSleepBanner:
            return "Sleep Data Warning"
        case .healthKitEnablement:
            return "Health Data Setup"
        }
    }
}
