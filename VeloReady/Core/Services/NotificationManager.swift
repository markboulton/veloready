import Foundation
@preconcurrency import UserNotifications
import UIKit

/// Manages local notifications for sleep reminders and recovery alerts
@MainActor
class NotificationManager: NSObject, ObservableObject {

    static let shared = NotificationManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isAuthorized: Bool = false

    private let center = UNUserNotificationCenter.current()
    
    // Notification identifiers
    private enum NotificationID {
        static let sleepReminder = "com.veloready.sleep.reminder"
        static let recoveryAlert = "com.veloready.recovery.alert"
    }
    
    private override init() {
        super.init()
        center.delegate = self
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            
            if granted {
                Logger.info("✅ Notification permission granted", category: .ui)
            } else {
                Logger.warning("⚠️ Notification permission denied", category: .ui)
            }
            
            return granted
        } catch {
            Logger.error("Failed to request notification authorization", error: error, category: .ui)
            return false
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
        
        Logger.debug("📱 Notification authorization: \(settings.authorizationStatus.description)", category: .ui)
    }
    
    // MARK: - Sleep Reminders

    /// Schedule sleep reminder notification
    func scheduleSleepReminder(enabled: Bool, reminderTime: Date, targetHours: Double, targetMinutes: Int) async {
        // Remove existing reminder first
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.sleepReminder])

        guard enabled else {
            Logger.debug("Sleep reminders disabled - skipping schedule", category: .ui)
            return
        }

        // Check authorization
        if !isAuthorized {
            Logger.warning("Not authorized for notifications - requesting permission", category: .ui)
            let granted = await requestAuthorization()
            guard granted else { return }
        }

        // Format sleep target
        let formattedTarget = targetMinutes == 0 ? "\(Int(targetHours))h" : "\(Int(targetHours))h \(targetMinutes)m"

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Wind Down"
        content.body = "Your sleep target is \(formattedTarget). Start your bedtime routine for optimal recovery."
        content.sound = .default
        content.categoryIdentifier = "SLEEP_REMINDER"

        // Create trigger from reminder time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: NotificationID.sleepReminder,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            Logger.info("✅ Sleep reminder scheduled for \(components.hour ?? 0):\(String(format: "%02d", components.minute ?? 0))", category: .ui)
        } catch {
            Logger.error("Failed to schedule sleep reminder", error: error, category: .ui)
        }
    }
    
    /// Cancel sleep reminder
    func cancelSleepReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.sleepReminder])
        Logger.debug("🗑️ Sleep reminder cancelled", category: .ui)
    }
    
    // MARK: - Recovery Alerts

    /// Send recovery alert if score is low
    func sendRecoveryAlert(score: Double, band: String, enabled: Bool) async {
        guard enabled else {
            return
        }

        // Only alert if recovery is low (< 60)
        guard score < 60 else {
            return
        }
        
        // Check authorization
        guard isAuthorized else {
            Logger.warning("Not authorized for notifications", category: .ui)
            return
        }
        
        // Check if we already sent an alert today
        let lastAlertKey = "lastRecoveryAlertDate"
        let lastAlertDate = UserDefaults.standard.object(forKey: lastAlertKey) as? Date
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastAlert = lastAlertDate, Calendar.current.isDate(lastAlert, inSameDayAs: today) {
            Logger.debug("Already sent recovery alert today - skipping", category: .ui)
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Low Recovery Detected"
        content.body = "Your recovery score is \(Int(score)) (\(band)). Consider taking it easy today or prioritizing rest."
        content.sound = .default
        content.categoryIdentifier = "RECOVERY_ALERT"
        
        // Send immediately
        let request = UNNotificationRequest(
            identifier: NotificationID.recoveryAlert + "_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Send immediately
        )
        
        do {
            try await center.add(request)
            UserDefaults.standard.set(Date(), forKey: lastAlertKey)
            Logger.info("✅ Recovery alert sent (score: \(Int(score)))", category: .ui)
        } catch {
            Logger.error("Failed to send recovery alert", error: error, category: .ui)
        }
    }
    
    // MARK: - Management

    /// Update all scheduled notifications based on current settings
    func updateScheduledNotifications(sleepSettings: SleepSettings) async {
        await scheduleSleepReminder(
            enabled: sleepSettings.reminders,
            reminderTime: sleepSettings.reminderTime,
            targetHours: sleepSettings.targetHours,
            targetMinutes: sleepSettings.targetMinutes
        )
    }
    
    /// Cancel all notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        Logger.debug("🗑️ All notifications cancelled", category: .ui)
    }
    
    /// Get pending notifications count
    func getPendingNotificationsCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier

        if identifier.starts(with: NotificationID.sleepReminder) {
            Logger.debug("User tapped sleep reminder notification", category: .ui)
            // Could navigate to sleep tracking or today view
        } else if identifier.starts(with: NotificationID.recoveryAlert) {
            Logger.debug("User tapped recovery alert notification", category: .ui)
            // Could navigate to recovery view
        }

        completionHandler()
    }
}

// MARK: - Authorization Status Extension

extension UNAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
}
