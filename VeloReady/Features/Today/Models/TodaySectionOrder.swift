import Foundation

/// Configuration for Today page section ordering
/// Allows users to customize the order of movable sections
struct TodaySectionOrder: Codable {
    var movableSections: [TodaySection]
    
    /// Default section order
    static let defaultOrder = TodaySectionOrder(
        movableSections: [
            .veloAI,
            .latestActivity,
            .stepsAndCalories,
            .recentActivities
        ]
    )
    
    /// UserDefaults key for persistence
    private static let userDefaultsKey = "todaySectionOrder"
    
    /// Load saved order from UserDefaults
    static func load() -> TodaySectionOrder {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let order = try? JSONDecoder().decode(TodaySectionOrder.self, from: data) else {
            return defaultOrder
        }
        return order
    }
    
    /// Save order to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
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
    case stepsAndCalories = "Steps & Calories"
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
        case .dailyBrief, .latestActivity, .stepsAndCalories, .recentActivities:
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
