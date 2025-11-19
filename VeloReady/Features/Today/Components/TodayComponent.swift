import SwiftUI

/// Protocol defining the interface for modular Today view components (Phase 2)
///
/// **Design Goals:**
/// - Components load data from TodayViewState (single source of truth)
/// - Components are independently testable and reusable
/// - Support feature flags for gradual rollout
/// - Maintain visual parity with existing UI
/// - Enable A/B testing for new component implementations
///
/// **Component Lifecycle:**
/// 1. `init()` - Component is created, observes TodayViewState.shared
/// 2. Registry checks `shouldRender()` before adding to view hierarchy
/// 3. `body` - Render component UI (if shouldRender returns true)
/// 4. `onAppear()` - Component appeared on screen
/// 5. `onDisappear()` - Component left screen
///
/// **Data Flow:**
/// TodayViewState → TodayComponent (via @ObservedObject) → SwiftUI View
///
/// **Implementation Example:**
/// ```swift
/// struct RecoveryMetricsComponent: TodayComponent {
///     static let componentID = "recovery_metrics"
///     static let displayName = "Recovery Metrics"
///     static let displayOrder = 0
///
///     @ObservedObject private var state = TodayViewState.shared
///
///     var body: some View {
///         RecoveryMetricsSection(...)
///     }
/// }
/// ```
///
/// Created: 2025-11-19 (Phase 2 - Component Migration)
@MainActor
protocol TodayComponent: View {
    /// Unique identifier for the component (used in registry and feature flags)
    static var componentID: String { get }

    /// Component display name (for debugging/analytics)
    static var displayName: String { get }

    /// Priority/order in which component appears in Today view (0 = top, higher = lower)
    /// Components with same priority are rendered in registration order
    static var displayOrder: Int { get }

    /// Determines if this component should render based on current state
    /// - Returns: true if component should be visible, false to hide
    /// - Note: Components can access TodayViewState.shared to make this determination
    static func shouldRender() -> Bool

    /// Optional: Component-specific feature flag key
    /// If provided, component only renders when feature flag is enabled
    /// Format: "component_{componentID}" (e.g., "component_recovery_metrics")
    static var featureFlagKey: String? { get }

    /// Initializer (must be provided by conforming types)
    init()
}

// MARK: - Default Implementations

extension TodayComponent {
    /// Default: Always render unless feature flag says otherwise
    static func shouldRender() -> Bool {
        // Check feature flag if provided
        if let flagKey = featureFlagKey {
            let isEnabled = FeatureFlags.shared.isEnabled(flagKey)
            Logger.debug("🔌 [Component] \(componentID) feature flag '\(flagKey)': \(isEnabled)")
            return isEnabled
        }
        return true
    }

    /// Default: No feature flag required
    static var featureFlagKey: String? { nil }

    /// Default component ID derived from type name
    static var componentID: String {
        String(describing: Self.self)
    }

    /// Default display name same as component ID
    static var displayName: String {
        componentID
    }
}

// MARK: - Component Categories

/// Category of component for grouping and organization
enum TodayComponentCategory: String, CaseIterable {
    case metrics        // Recovery, Sleep, Strain rings
    case alerts         // Health warnings, wellness, stress alerts
    case activities     // Latest activity, activity history
    case performance    // FTP, VO2Max, training load
    case lifestyle      // Steps, calories, sleep debt
    case insights       // AI brief, trends, recommendations
    case system         // Health Kit enablement, onboarding

    var displayOrder: Int {
        switch self {
        case .metrics: return 0
        case .alerts: return 1
        case .insights: return 2
        case .activities: return 3
        case .performance: return 4
        case .lifestyle: return 5
        case .system: return 999  // Always last
        }
    }
}

/// Extended protocol for components that belong to a category
protocol CategorizedTodayComponent: TodayComponent {
    static var category: TodayComponentCategory { get }
}

extension CategorizedTodayComponent {
    /// Display order defaults to category order + component-specific offset
    static var displayOrder: Int {
        category.displayOrder * 100 + componentSpecificOrder
    }

    /// Component-specific order within its category (0-99)
    /// Override in your component to set relative order within category
    static var componentSpecificOrder: Int { 0 }
}
