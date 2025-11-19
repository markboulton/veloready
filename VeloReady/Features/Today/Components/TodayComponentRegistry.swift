import SwiftUI

/// Registry for managing all Today view components (Phase 2)
///
/// **Purpose:**
/// - Central registration point for all components
/// - Provides sorted, filtered list of components to render
/// - Enables feature flag control and A/B testing
/// - Supports gradual migration from monolithic to modular architecture
///
/// **Usage:**
/// ```swift
/// // Register component (typically in app startup)
/// TodayComponentRegistry.shared.register(RecoveryMetricsComponent.self)
///
/// // Get components to render in TodayView
/// let components = TodayComponentRegistry.shared.componentsToRender(state: todayState)
/// ```
///
/// Created: 2025-11-19 (Phase 2 - Component Migration)
@MainActor
final class TodayComponentRegistry: ObservableObject {
    static let shared = TodayComponentRegistry()

    // MARK: - Types

    /// Metadata about a registered component
    struct ComponentMetadata {
        let componentID: String
        let displayName: String
        let displayOrder: Int
        let featureFlagKey: String?
        let shouldRender: () -> Bool
        let createView: () -> AnyView
    }

    // MARK: - Properties

    @Published private(set) var registeredComponents: [ComponentMetadata] = []
    private var componentTypes: [String: Any.Type] = [:]  // For debugging/analytics

    private init() {
        Logger.info("📦 [ComponentRegistry] Initialized")
    }

    // MARK: - Registration

    /// Register a component type
    /// - Parameter componentType: The component type conforming to TodayComponent
    func register<T: TodayComponent>(_ componentType: T.Type) {
        let componentID = T.componentID
        let displayName = T.displayName
        let displayOrder = T.displayOrder
        let featureFlagKey = T.featureFlagKey

        // Check if already registered
        guard !registeredComponents.contains(where: { $0.componentID == componentID }) else {
            Logger.warning("⚠️ [ComponentRegistry] Component '\(componentID)' already registered - skipping")
            return
        }

        let metadata = ComponentMetadata(
            componentID: componentID,
            displayName: displayName,
            displayOrder: displayOrder,
            featureFlagKey: featureFlagKey,
            shouldRender: T.shouldRender,
            createView: { AnyView(T()) }
        )

        registeredComponents.append(metadata)
        componentTypes[componentID] = componentType

        // Sort by display order after registration
        registeredComponents.sort { $0.displayOrder < $1.displayOrder }

        Logger.info("✅ [ComponentRegistry] Registered '\(displayName)' (ID: \(componentID), Order: \(displayOrder))")
        if let flagKey = featureFlagKey {
            Logger.info("   Feature flag: \(flagKey)")
        }
    }

    /// Register multiple components at once
    /// - Parameter components: Array of component types to register
    func registerAll(_ components: [Any.Type]) {
        Logger.info("📦 [ComponentRegistry] Registering \(components.count) components...")
        for componentType in components {
            if let todayComponent = componentType as? any TodayComponent.Type {
                // Use type-erased registration
                _registerTypeErased(todayComponent)
            } else {
                Logger.warning("⚠️ [ComponentRegistry] Type '\(componentType)' does not conform to TodayComponent - skipping")
            }
        }
        Logger.info("✅ [ComponentRegistry] Registration complete - \(registeredComponents.count) components registered")
    }

    /// Internal type-erased registration helper
    private func _registerTypeErased(_ componentType: any TodayComponent.Type) {
        let componentID = componentType.componentID
        let displayName = componentType.displayName
        let displayOrder = componentType.displayOrder
        let featureFlagKey = componentType.featureFlagKey

        // Check if already registered
        guard !registeredComponents.contains(where: { $0.componentID == componentID }) else {
            Logger.warning("⚠️ [ComponentRegistry] Component '\(componentID)' already registered - skipping")
            return
        }

        let metadata = ComponentMetadata(
            componentID: componentID,
            displayName: displayName,
            displayOrder: displayOrder,
            featureFlagKey: featureFlagKey,
            shouldRender: componentType.shouldRender,
            createView: {
                // This will be implemented per-component
                AnyView(Text("Component: \(displayName)"))
            }
        )

        registeredComponents.append(metadata)
        componentTypes[componentID] = componentType

        // Sort by display order after registration
        registeredComponents.sort { $0.displayOrder < $1.displayOrder }

        Logger.info("✅ [ComponentRegistry] Registered '\(displayName)' (ID: \(componentID), Order: \(displayOrder))")
        if let flagKey = featureFlagKey {
            Logger.info("   Feature flag: \(flagKey)")
        }
    }

    // MARK: - Component Retrieval

    /// Get list of components that should render
    /// - Returns: Array of components to render, sorted by displayOrder
    func componentsToRender() -> [ComponentMetadata] {
        let renderableComponents = registeredComponents.filter { component in
            component.shouldRender()
        }

        Logger.debug("📦 [ComponentRegistry] Components to render: \(renderableComponents.count)/\(registeredComponents.count)")
        return renderableComponents
    }

    /// Get component metadata by ID
    /// - Parameter componentID: The component identifier
    /// - Returns: Component metadata if found
    func component(withID componentID: String) -> ComponentMetadata? {
        registeredComponents.first { $0.componentID == componentID }
    }

    // MARK: - Debugging & Analytics

    /// Print current registry state for debugging
    func logRegistryState() {
        Logger.info("📊 [ComponentRegistry] Registry State:")
        Logger.info("   Total components: \(registeredComponents.count)")
        for (index, component) in registeredComponents.enumerated() {
            let flagInfo = component.featureFlagKey.map { " [Flag: \($0)]" } ?? ""
            Logger.info("   \(index + 1). \(component.displayName) (Order: \(component.displayOrder))\(flagInfo)")
        }
    }

    /// Get statistics about component usage
    func getStatistics() -> RegistryStatistics {
        let total = registeredComponents.count
        let rendered = componentsToRender().count
        let flagControlled = registeredComponents.filter { $0.featureFlagKey != nil }.count

        return RegistryStatistics(
            totalRegistered: total,
            currentlyRendered: rendered,
            featureFlagControlled: flagControlled
        )
    }

    struct RegistryStatistics {
        let totalRegistered: Int
        let currentlyRendered: Int
        let featureFlagControlled: Int

        var renderPercentage: Double {
            guard totalRegistered > 0 else { return 0 }
            return Double(currentlyRendered) / Double(totalRegistered) * 100
        }
    }

    // MARK: - Reset (for testing)

    #if DEBUG
    /// Clear all registered components (for testing only)
    func reset() {
        registeredComponents.removeAll()
        componentTypes.removeAll()
        Logger.debug("🗑️ [ComponentRegistry] Registry reset")
    }
    #endif
}
