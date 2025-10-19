import Foundation
import WatchConnectivity

/// Manages communication between iPhone and Apple Watch
/// Syncs recovery score, HRV, RHR, and other metrics to watch
@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    
    static let shared = WatchConnectivityManager()
    
    @Published var isWatchPaired = false
    @Published var isWatchAppInstalled = false
    @Published var isReachable = false
    @Published var lastSyncDate: Date?
    
    private var session: WCSession?
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Public API
    
    /// Send recovery score to watch
    func sendRecoveryScore(_ score: RecoveryScore) {
        guard let session = session, session.isReachable else {
            Logger.debug("⌚ Watch not reachable - queueing data")
            queueRecoveryScore(score)
            return
        }
        
        let message: [String: Any] = [
            "type": "recoveryScore",
            "score": score.score,
            "band": score.band.rawValue,
            "isPersonalized": score.isPersonalized,
            "timestamp": score.calculatedAt.timeIntervalSince1970
        ]
        
        session.sendMessage(message, replyHandler: { reply in
            Logger.info("⌚ Recovery score sent to watch: \(score.score)")
            Task { @MainActor in
                self.lastSyncDate = Date()
            }
        }, errorHandler: { error in
            Logger.error("⌚ Failed to send recovery score to watch: \(error)")
        })
    }
    
    /// Send HRV data to watch (prefer watch-collected data)
    func sendHRVData(hrv: Double, baseline: Double?) {
        guard let session = session else { return }
        
        let context: [String: Any] = [
            "type": "hrv",
            "value": hrv,
            "baseline": baseline ?? 0,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            try session.updateApplicationContext(context)
            Logger.debug("⌚ HRV data sent to watch: \(hrv)ms")
        } catch {
            Logger.error("⌚ Failed to send HRV to watch: \(error)")
        }
    }
    
    /// Send RHR data to watch (prefer watch-collected data)
    func sendRHRData(rhr: Double, baseline: Double?) {
        guard let session = session else { return }
        
        let context: [String: Any] = [
            "type": "rhr",
            "value": rhr,
            "baseline": baseline ?? 0,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            try session.updateApplicationContext(context)
            Logger.debug("⌚ RHR data sent to watch: \(rhr)bpm")
        } catch {
            Logger.error("⌚ Failed to send RHR to watch: \(error)")
        }
    }
    
    /// Send strain score to watch
    func sendStrainScore(_ score: StrainScore) {
        guard let session = session else { return }
        
        let context: [String: Any] = [
            "type": "strain",
            "score": score.score,
            "band": score.band.rawValue,
            "timestamp": score.calculatedAt.timeIntervalSince1970
        ]
        
        do {
            try session.updateApplicationContext(context)
            Logger.debug("⌚ Strain score sent to watch: \(score.score)")
        } catch {
            Logger.error("⌚ Failed to send strain to watch: \(error)")
        }
    }
    
    /// Request HRV/RHR data from watch (watch data is more accurate)
    func requestHealthDataFromWatch() {
        guard let session = session, session.isReachable else {
            Logger.debug("⌚ Watch not reachable - cannot request data")
            return
        }
        
        let message = ["type": "requestHealthData"]
        
        session.sendMessage(message, replyHandler: { reply in
            Logger.info("⌚ Received health data from watch")
            Task { @MainActor in
                self.handleHealthDataFromWatch(reply)
            }
        }, errorHandler: { error in
            Logger.error("⌚ Failed to request health data from watch: \(error)")
        })
    }
    
    // MARK: - Private Methods
    
    /// Queue recovery score for later delivery
    private func queueRecoveryScore(_ score: RecoveryScore) {
        guard let session = session else { return }
        
        let userInfo: [String: Any] = [
            "type": "recoveryScore",
            "score": score.score,
            "band": score.band.rawValue,
            "isPersonalized": score.isPersonalized,
            "timestamp": score.calculatedAt.timeIntervalSince1970
        ]
        
        session.transferUserInfo(userInfo)
        Logger.debug("⌚ Recovery score queued for watch delivery")
    }
    
    /// Handle health data received from watch
    private func handleHealthDataFromWatch(_ data: [String: Any]) {
        // Extract HRV if available
        if let hrv = data["hrv"] as? Double,
           let hrvTimestamp = data["hrvTimestamp"] as? TimeInterval {
            Logger.info("⌚ Received HRV from watch: \(hrv)ms")
            // TODO: Update HealthKit with watch data (preferred source)
        }
        
        // Extract RHR if available
        if let rhr = data["rhr"] as? Double,
           let rhrTimestamp = data["rhrTimestamp"] as? TimeInterval {
            Logger.info("⌚ Received RHR from watch: \(rhr)bpm")
            // TODO: Update HealthKit with watch data (preferred source)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                Logger.error("⌚ Watch session activation failed: \(error)")
                return
            }
            
            switch activationState {
            case .activated:
                Logger.info("⌚ Watch session activated")
                isWatchPaired = session.isPaired
                isWatchAppInstalled = session.isWatchAppInstalled
                isReachable = session.isReachable
            case .inactive:
                Logger.warning("⌚ Watch session inactive")
            case .notActivated:
                Logger.warning("⌚ Watch session not activated")
            @unknown default:
                Logger.warning("⌚ Watch session unknown state")
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            Logger.debug("⌚ Watch session became inactive")
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            Logger.debug("⌚ Watch session deactivated")
            // Reactivate session
            session.activate()
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            Logger.debug("⌚ Watch reachability changed: \(session.isReachable)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            Logger.debug("⌚ Received message from watch: \(message)")
            
            // Handle different message types
            if let type = message["type"] as? String {
                switch type {
                case "requestRecoveryScore":
                    // Watch is requesting latest recovery score
                    if let score = RecoveryScoreService.shared.currentRecoveryScore {
                        sendRecoveryScore(score)
                    }
                case "healthData":
                    // Watch is sending health data
                    handleHealthDataFromWatch(message)
                default:
                    Logger.debug("⌚ Unknown message type: \(type)")
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            Logger.debug("⌚ Received message from watch (with reply): \(message)")
            
            // Handle request for recovery score
            if let type = message["type"] as? String, type == "requestRecoveryScore" {
                if let score = RecoveryScoreService.shared.currentRecoveryScore {
                    let reply: [String: Any] = [
                        "score": score.score,
                        "band": score.band.rawValue,
                        "isPersonalized": score.isPersonalized,
                        "timestamp": score.calculatedAt.timeIntervalSince1970
                    ]
                    replyHandler(reply)
                } else {
                    replyHandler(["error": "No recovery score available"])
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            Logger.debug("⌚ Received application context from watch")
            handleHealthDataFromWatch(applicationContext)
        }
    }
}
