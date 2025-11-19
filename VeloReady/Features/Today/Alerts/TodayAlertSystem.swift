import SwiftUI

// MARK: - Alert Protocol

/// Protocol for composable alerts in Today view (Phase 1 - V2 Architecture)
/// Meets user requirements:
/// - Control content & colors
/// - Parameters to turn on/off cards and/or components
/// - Time-limited (e.g., 7 days)
/// - Sensor-limited (conditional logic)
protocol TodayAlert: Identifiable {
    var id: String { get }
    var priority: Int { get }

    // MARK: - Content (YOU CONTROL)

    var title: String { get }
    var message: String { get }
    var severity: AlertSeverity { get }
    var icon: String? { get }
    var accentColor: Color { get }

    // MARK: - Behavior

    var isDismissible: Bool { get }
    var dismissalConfig: AlertDismissalConfig? { get }

    /// Components to hide when this alert is shown
    /// Example: ["TrainingLoadCard", "LatestActivityCard"]
    var affectedComponents: Set<String> { get }

    /// Cards to show when this alert is active
    /// Example: ["SleepDetailCard", "RecoveryTipsCard"]
    var additionalCards: [String] { get }

    // MARK: - Activation Conditions

    /// Conditions that must be met for alert to activate
    /// Example: [.healthKitAuthorized, .sleepDataAvailable, .sleepBelowThreshold(6.0)]
    var activationConditions: [AlertCondition] { get }

    /// Custom conditional logic (sensor-limited)
    /// Example: Check if HRV is 20% below baseline for 3+ days
    @MainActor func shouldActivate(state: TodayViewState) -> Bool

    // MARK: - Actions

    var primaryAction: AlertAction? { get }
    var secondaryAction: AlertAction? { get }
}

// MARK: - Alert Severity

enum AlertSeverity {
    case info       // Blue
    case warning    // Yellow
    case critical   // Red
    case success    // Green

    var color: Color {
        switch self {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .critical:
            return .red
        case .success:
            return .green
        }
    }
}

// MARK: - Dismissal Configuration

struct AlertDismissalConfig {
    /// How long before alert can reappear (time-limited)
    /// Example: 7 days = 604800 seconds
    var reappearAfter: TimeInterval?

    /// Custom logic for when alert should reappear (sensor-limited)
    /// Example: Reappear only if HRV drops again
    var conditionalReappear: (@MainActor (TodayViewState) -> Bool)?

    /// Date when user dismissed this alert
    var dismissedAt: Date?

    /// Should this alert be shown again?
    @MainActor func shouldReappear(state: TodayViewState) -> Bool {
        // Check if time-limited period has passed
        if let dismissedAt = dismissedAt, let reappearAfter = reappearAfter {
            let timeSinceDismissal = Date().timeIntervalSince(dismissedAt)
            if timeSinceDismissal < reappearAfter {
                return false // Still within dismissal period
            }
        }

        // Check conditional logic (sensor-limited)
        if let conditionalReappear = conditionalReappear {
            return conditionalReappear(state)
        }

        return true // Default: can reappear
    }
}

// MARK: - Alert Conditions

indirect enum AlertCondition {
    case healthKitAuthorized
    case sleepDataAvailable
    case hrvDataAvailable
    case activitiesAvailable
    case sleepBelowThreshold(hours: Double)
    case hrvBelowBaseline(percentage: Double)
    case rhrAboveBaseline(percentage: Double)
    case tsbBelowThreshold(value: Double)
    case consecutiveDays(condition: AlertCondition, days: Int)
    case custom(@MainActor (TodayViewState) -> Bool)

    @MainActor func evaluate(state: TodayViewState) -> Bool {
        switch self {
        case .healthKitAuthorized:
            return state.isHealthKitAuthorized

        case .sleepDataAvailable:
            return state.sleepDuration != nil

        case .hrvDataAvailable:
            return state.hrv != nil

        case .activitiesAvailable:
            return !state.recentActivities.isEmpty

        case .sleepBelowThreshold(let hours):
            guard let duration = state.sleepDuration else { return false }
            return duration < (hours * 3600) // Convert hours to seconds

        case .hrvBelowBaseline(let percentage):
            guard let hrv = state.hrv, let baseline = state.hrvBaseline else { return false }
            let threshold = baseline * (1.0 - percentage / 100.0)
            return hrv < threshold

        case .rhrAboveBaseline(let percentage):
            guard let rhr = state.rhr, let baseline = state.rhrBaseline else { return false }
            let threshold = baseline * (1.0 + percentage / 100.0)
            return rhr > threshold

        case .tsbBelowThreshold(let value):
            guard let tsb = state.tsb else { return false }
            return tsb < value

        case .consecutiveDays(let condition, let days):
            // TODO: Implement historical checking
            // For now, just evaluate the condition for today
            return condition.evaluate(state: state)

        case .custom(let evaluator):
            return evaluator(state)
        }
    }
}

// MARK: - Alert Actions

struct AlertAction {
    let title: String
    let action: @MainActor () -> Void
}

// MARK: - Alert Manager

/// Manages active alerts and their lifecycle (Phase 1 - V2 Architecture)
@MainActor
final class TodayAlertManager {
    static let shared = TodayAlertManager()

    // MARK: - Alert Registry

    private var registeredAlerts: [any TodayAlert] = []
    private var dismissedAlerts: [String: Date] = [:] // alertId -> dismissedAt

    // MARK: - Persistence Keys

    private let dismissedAlertsKey = "today_dismissed_alerts"

    // MARK: - Initialization

    private init() {
        loadDismissedAlerts()
        registerDefaultAlerts()
    }

    // MARK: - Registration

    func register(alert: any TodayAlert) {
        registeredAlerts.append(alert)
        registeredAlerts.sort { $0.priority > $1.priority } // Higher priority first
        Logger.debug("📢 Registered alert: \(alert.id) (priority: \(alert.priority))")
    }

    private func registerDefaultAlerts() {
        // Register built-in alerts
        register(alert: SleepDataMissingAlert())
        register(alert: OvertrainingAlert())
        register(alert: LowHRVAlert())
        register(alert: ElevatedRHRAlert())
        // More alerts can be registered here
    }

    // MARK: - Evaluation

    func evaluateAlerts(state: TodayViewState) -> [any TodayAlert] {
        var activeAlerts: [any TodayAlert] = []

        for alert in registeredAlerts {
            // Check if alert was dismissed
            if !alert.isDismissible {
                // Non-dismissible alerts always evaluate
            } else if let dismissedAt = dismissedAlerts[alert.id] {
                // Check if alert should reappear
                var config = alert.dismissalConfig ?? AlertDismissalConfig()
                config.dismissedAt = dismissedAt

                if !config.shouldReappear(state: state) {
                    continue // Still dismissed
                }
            }

            // Evaluate activation conditions
            let conditionsMet = alert.activationConditions.allSatisfy { $0.evaluate(state: state) }
            guard conditionsMet else { continue }

            // Evaluate custom logic
            guard alert.shouldActivate(state: state) else { continue }

            activeAlerts.append(alert)
        }

        Logger.debug("📢 Active alerts: \(activeAlerts.map { $0.id })")
        return activeAlerts
    }

    // MARK: - Dismissal

    func dismiss(alertId: String) {
        dismissedAlerts[alertId] = Date()
        saveDismissedAlerts()
        Logger.debug("🔕 Dismissed alert: \(alertId)")
    }

    func clearDismissal(alertId: String) {
        dismissedAlerts.removeValue(forKey: alertId)
        saveDismissedAlerts()
        Logger.debug("🔔 Cleared dismissal for alert: \(alertId)")
    }

    // MARK: - Persistence

    private func loadDismissedAlerts() {
        if let data = UserDefaults.standard.data(forKey: dismissedAlertsKey),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            dismissedAlerts = decoded
            Logger.debug("💾 Loaded \(dismissedAlerts.count) dismissed alerts")
        }
    }

    private func saveDismissedAlerts() {
        if let encoded = try? JSONEncoder().encode(dismissedAlerts) {
            UserDefaults.standard.set(encoded, forKey: dismissedAlertsKey)
        }
    }
}

// MARK: - Default Alert Implementations

/// Example: Sleep Data Missing Alert
struct SleepDataMissingAlert: TodayAlert {
    let id = "sleep_data_missing"
    let priority = 80 // High priority

    // Content (YOU CONTROL)
    let title = "Missing Sleep Data"
    let message = "We haven't detected sleep data for today. Make sure your device is tracking sleep correctly."
    let severity = AlertSeverity.warning
    var icon: String? { "moon.zzz" }
    var accentColor: Color { severity.color }

    // Behavior
    let isDismissible = true
    var dismissalConfig: AlertDismissalConfig? { AlertDismissalConfig(reappearAfter: 86400) } // 1 day

    // Parameters to turn on/off components
    let affectedComponents: Set<String> = [] // Don't hide anything
    let additionalCards: [String] = ["SleepSetupCard"] // Show setup help

    // Activation Conditions
    let activationConditions: [AlertCondition] = [
        .healthKitAuthorized,
        .custom({ @MainActor state in
            // Only show if we had sleep data yesterday but not today
            // (indicates tracking stopped)
            return state.sleepDuration == nil
        })
    ]

    @MainActor func shouldActivate(state: TodayViewState) -> Bool {
        // Additional logic: Only show after 10am (give time for sync)
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 10
    }

    var primaryAction: AlertAction? {
        AlertAction(title: "Check Settings") {
            // Open HealthKit settings
            Logger.debug("Opening HealthKit settings...")
        }
    }

    let secondaryAction: AlertAction? = nil
}

/// Example: Overtraining Alert
struct OvertrainingAlert: TodayAlert {
    let id = "overtraining_warning"
    let priority = 90 // Very high priority

    // Content (YOU CONTROL)
    let title = "Overtraining Risk Detected"
    let message = "Your TSB is critically low and recovery markers are declining. Consider taking a rest day."
    let severity = AlertSeverity.critical
    var icon: String? { "exclamationmark.triangle.fill" }
    var accentColor: Color { severity.color }

    // Behavior
    let isDismissible = true
    var dismissalConfig: AlertDismissalConfig? {
        AlertDismissalConfig(
            reappearAfter: 172800, // 2 days
            conditionalReappear: { @MainActor state in
                // Reappear if TSB drops even further
                guard let tsb = state.tsb else { return false }
                return tsb < -30 // Very fatigued
            }
        )
    }

    // Parameters to turn on/off components
    let affectedComponents: Set<String> = ["LatestActivityCard"] // Hide activity temptation
    let additionalCards: [String] = ["RecoveryTipsCard", "RestDayPlanCard"]

    // Activation Conditions (sensor-limited)
    let activationConditions: [AlertCondition] = [
        .healthKitAuthorized,
        .tsbBelowThreshold(value: -20), // Fatigued
        .hrvBelowBaseline(percentage: 15), // HRV down 15%
        .rhrAboveBaseline(percentage: 10) // RHR up 10%
    ]

    @MainActor func shouldActivate(state: TodayViewState) -> Bool {
        // All conditions must be met for 2+ days
        // (for Phase 1, we'll just return true if conditions are met)
        return true
    }

    var primaryAction: AlertAction? {
        AlertAction(title: "View Recovery Plan") {
            Logger.debug("Opening recovery plan...")
        }
    }

    var secondaryAction: AlertAction? {
        AlertAction(title: "Ignore") {
            TodayAlertManager.shared.dismiss(alertId: "overtraining_warning")
        }
    }
}

/// Example: Low HRV Alert
struct LowHRVAlert: TodayAlert {
    let id = "low_hrv"
    let priority = 70

    let title = "HRV Below Baseline"
    let message = "Your HRV is 20% below your baseline. Your body may need extra recovery today."
    let severity = AlertSeverity.info
    var icon: String? { "heart.text.square" }
    var accentColor: Color { severity.color }

    let isDismissible = true
    var dismissalConfig: AlertDismissalConfig? { AlertDismissalConfig(reappearAfter: 86400) } // 1 day

    let affectedComponents: Set<String> = []
    let additionalCards: [String] = []

    let activationConditions: [AlertCondition] = [
        .healthKitAuthorized,
        .hrvDataAvailable,
        .hrvBelowBaseline(percentage: 20)
    ]

    @MainActor func shouldActivate(state: TodayViewState) -> Bool {
        return true
    }

    let primaryAction: AlertAction? = nil
    let secondaryAction: AlertAction? = nil
}

/// Example: Elevated RHR Alert
struct ElevatedRHRAlert: TodayAlert {
    let id = "elevated_rhr"
    let priority = 70

    let title = "Elevated Resting Heart Rate"
    let message = "Your RHR is higher than usual. This could indicate stress, illness, or insufficient recovery."
    let severity = AlertSeverity.warning
    var icon: String? { "heart.circle" }
    var accentColor: Color { severity.color }

    let isDismissible = true
    var dismissalConfig: AlertDismissalConfig? { AlertDismissalConfig(reappearAfter: 86400) } // 1 day

    let affectedComponents: Set<String> = []
    let additionalCards: [String] = []

    let activationConditions: [AlertCondition] = [
        .healthKitAuthorized,
        .rhrAboveBaseline(percentage: 15)
    ]

    @MainActor func shouldActivate(state: TodayViewState) -> Bool {
        return true
    }

    let primaryAction: AlertAction? = nil
    let secondaryAction: AlertAction? = nil
}
