import Foundation

/// Configuration for Today page section ordering
/// Allows users to customize the order of movable sections
struct TodaySectionOrder: Codable {
    var movableSections: [TodaySection]
    
    /// Default section order
    static let defaultOrder = TodaySectionOrder(
        movableSections: [
            .veloAI,
            .dailyBrief,
            .latestActivity,
            .steps,
            .calories,
            .recentActivities
        ]
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
        var needsSave = false
        
        // Check if dailyBrief is missing (old version)
        if !sections.contains(.dailyBrief) {
            // Add dailyBrief after veloAI (or at the beginning if veloAI not found)
            if let veloAIIndex = sections.firstIndex(of: .veloAI) {
                sections.insert(.dailyBrief, at: veloAIIndex + 1)
            } else {
                sections.insert(.dailyBrief, at: 0)
            }
            
            Logger.debug("☁️ Migrated section order to include Daily Brief")
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
        
        if needsSave {
            // Save the migrated order
            let migratedOrder = TodaySectionOrder(movableSections: sections)
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
        case .recentActivities:
            return "List of your recent workouts"
        }
    }
    
    /// Whether this section requires PRO access
    var requiresPro: Bool {
        switch self {
        case .veloAI:
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
