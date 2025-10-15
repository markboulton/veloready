import Foundation

/// Lightweight telemetry for tracking component usage
/// Helps identify which components are used and how often
@MainActor
final class ComponentTelemetry {
    static let shared = ComponentTelemetry()
    
    private var usageCounts: [String: Int] = [:]
    private var firstUsed: [String: Date] = [:]
    private var lastUsed: [String: Date] = [:]
    
    private init() {}
    
    // MARK: - Tracking
    
    /// Track usage of a component
    func track(_ component: Component) {
        let key = component.rawValue
        
        // Increment count
        usageCounts[key, default: 0] += 1
        
        // Track first use
        if firstUsed[key] == nil {
            firstUsed[key] = Date()
        }
        
        // Track last use
        lastUsed[key] = Date()
        
        #if DEBUG
        Logger.data("Telemetry: \(key) used \(usageCounts[key] ?? 0) times")
        #endif
    }
    
    // MARK: - Reporting
    
    /// Get usage statistics for a component
    func stats(for component: Component) -> ComponentStats? {
        let key = component.rawValue
        
        guard let count = usageCounts[key] else { return nil }
        
        return ComponentStats(
            component: component,
            usageCount: count,
            firstUsed: firstUsed[key],
            lastUsed: lastUsed[key]
        )
    }
    
    /// Get all component stats
    func allStats() -> [ComponentStats] {
        usageCounts.keys.compactMap { key in
            guard let component = Component(rawValue: key) else { return nil }
            return stats(for: component)
        }.sorted { $0.usageCount > $1.usageCount }
    }
    
    /// Get top N most used components
    func topComponents(_ count: Int = 10) -> [ComponentStats] {
        Array(allStats().prefix(count))
    }
    
    /// Reset all telemetry data
    func reset() {
        usageCounts.removeAll()
        firstUsed.removeAll()
        lastUsed.removeAll()
        Logger.data("Telemetry: Reset all data")
    }
}

// MARK: - Component Enum

extension ComponentTelemetry {
    enum Component: String, CaseIterable {
        // Layout Components
        case sectionHeader = "SectionHeader"
        case sectionDivider = "SectionDivider"
        
        // Data Display
        case metricDisplay = "MetricDisplay"
        case statRow = "StatRow"
        
        // State Components
        case loadingStateView = "LoadingStateView"
        case emptyStateCard = "EmptyStateCard"
        case emptyStateView = "EmptyStateView"
        
        // Feedback Components
        case infoBanner = "InfoBanner"
        
        // Chart Components
        case baseChartView = "BaseChartView"
        case chartLegend = "ChartLegend"
    }
}

// MARK: - Statistics

struct ComponentStats: Identifiable {
    let id = UUID()
    let component: ComponentTelemetry.Component
    let usageCount: Int
    let firstUsed: Date?
    let lastUsed: Date?
    
    var daysSinceFirstUse: Int? {
        guard let firstUsed = firstUsed else { return nil }
        return Calendar.current.dateComponents([.day], from: firstUsed, to: Date()).day
    }
    
    var averageUsagePerDay: Double? {
        guard let days = daysSinceFirstUse, days > 0 else { return nil }
        return Double(usageCount) / Double(days)
    }
}

// MARK: - View Extension for Easy Tracking

import SwiftUI

extension View {
    /// Track component usage when view appears
    func trackComponent(_ component: ComponentTelemetry.Component) -> some View {
        self.onAppear {
            ComponentTelemetry.shared.track(component)
        }
    }
}
