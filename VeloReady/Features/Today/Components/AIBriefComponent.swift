import SwiftUI

/// AI Brief Component (Phase 2 - Component Migration)
///
/// **Component:** AI-generated daily brief or computed brief (free tier)
///
/// **What it displays:**
/// - Pro: AI-generated personalized brief with insights and recommendations
/// - Free: Computed brief based on recovery, strain, and training data
/// - ML personalization info sheet
/// - Upgrade prompt for free users
///
/// **Data Source:** AIBriefService, MLTrainingDataService, multiple score services
///
/// **Feature Flag:** `component_ai_brief`
/// - When enabled: Uses this component-based implementation
/// - When disabled: Falls back to monolithic TodayView implementation
///
/// **A/B Testing:**
/// - Start: 10% of users
/// - Target: 100% after stability validation
/// - Metrics: Crash rate, AI response time, user engagement
///
/// Created: 2025-11-19 (Phase 2 - Week 1)
@MainActor
struct AIBriefComponent: TodayComponent {
    // MARK: - TodayComponent Protocol Requirements

    static let componentID = "ai_brief"
    static let displayName = "AI Brief"
    static let displayOrder = 200 // In insights category
    static let featureFlagKey: String? = nil  // Feature flag removed - always enabled

    // MARK: - Body

    var body: some View {
        let _ = Logger.trace("📦 [AIBriefComponent] body evaluated")

        // Wrap existing AIBriefView
        return AIBriefView()
    }

    // MARK: - TodayComponent Protocol Methods

    /// Only render when HealthKit is authorized
    /// AI Brief requires health data for generating insights
    static func shouldRender() -> Bool {
        // Only show when HealthKit is authorized (component needs health data)
        let isAuthorized = HealthKitManager.shared.isAuthorized
        Logger.debug("📦 [AIBriefComponent] shouldRender - isAuthorized: \(isAuthorized)")
        return isAuthorized
    }
}

// MARK: - Preview

#if DEBUG
struct AIBriefComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AIBriefComponent()
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("AI Brief Component")
    }
}
#endif
