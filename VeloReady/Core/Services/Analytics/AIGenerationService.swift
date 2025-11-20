import Foundation
import CryptoKit

/// Weekly metrics for AI summary generation
struct WeeklyMetricsPayload {
    let weekSummary: String
    let avgRecovery: Int
    let recoveryChange: Int
    let avgSleep: Double
    let sleepConsistency: Int
    let hrvTrend: String
    let weeklyTSS: Int
    let ctlStart: Int
    let ctlEnd: Int
    let weeklyDuration: TimeInterval
}

/// Training zone distribution for AI summary
struct TrainingZoneDistribution {
    let zoneEasyPercent: Double
    let zoneTempoPercent: Double
    let zoneHardPercent: Double
    let optimalDays: Int
    let overreachingDays: Int
    let restoringDays: Int
}

/// AI-generated summary response
struct AISummaryResponse {
    let text: String
    let cached: Bool
}

/// Service for generating AI-powered training summaries
///
/// **Features:**
/// - Generates personalized weekly training reports using AI
/// - Includes wellness scores, training metrics, and zone distribution
/// - HMAC-SHA256 authentication for secure API requests
/// - Automatic caching to reduce API calls
/// - Fallback summaries when API is unavailable
///
/// **Security:**
/// - Uses HMAC-SHA256 to sign requests
/// - HMAC secret stored securely in Keychain
/// - User ID included in request headers for server-side validation
@MainActor
final class AIGenerationService {
    static let shared = AIGenerationService()

    // MARK: - Constants

    private let apiURL = URL(string: "https://veloready.app/.netlify/functions/weekly-report")!
    private let keychainService = "com.veloready.app.secrets"
    private let keychainAccount = "APP_HMAC_SECRET"

    // MARK: - Public API

    /// Generate AI summary from weekly metrics
    /// - Parameters:
    ///   - metrics: Weekly performance metrics
    ///   - zones: Training zone distribution
    ///   - wellnessScore: Optional overall wellness score
    ///   - illnessIndicator: Optional illness detection data
    ///   - userId: User ID for request authentication
    /// - Returns: AI-generated summary text and cache status
    func generateSummary(
        metrics: WeeklyMetricsPayload,
        zones: TrainingZoneDistribution,
        wellnessScore: Int?,
        illnessIndicator: (severity: String, confidence: Double, signals: [String])?,
        userId: String
    ) async throws -> AISummaryResponse {
        Logger.debug("🤖 [AIGenerationService] Generating AI summary...")

        // Build request payload
        var payload: [String: Any] = [
            "weekSummary": metrics.weekSummary,
            "avgRecovery": metrics.avgRecovery,
            "recoveryChange": metrics.recoveryChange,
            "avgSleep": String(format: "%.1f", metrics.avgSleep),
            "sleepConsistency": metrics.sleepConsistency,
            "hrvTrend": metrics.hrvTrend,
            "weeklyTSS": metrics.weeklyTSS,
            "zoneDistribution": [
                "easy": Int(zones.zoneEasyPercent),
                "tempo": Int(zones.zoneTempoPercent),
                "hard": Int(zones.zoneHardPercent)
            ],
            "trainingDays": [
                "optimal": zones.optimalDays,
                "overreach": zones.overreachingDays,
                "rest": zones.restoringDays
            ],
            "ctlStart": metrics.ctlStart,
            "ctlEnd": metrics.ctlEnd,
            "weekOverWeek": [
                "recovery": metrics.recoveryChange >= 0 ? "+\(metrics.recoveryChange)%" : "\(metrics.recoveryChange)%",
                "tss": metrics.weeklyTSS,
                "duration": formatDuration(metrics.weeklyDuration)
            ]
        ]

        // Add illness indicator if present
        if let indicator = illnessIndicator {
            payload["illnessIndicator"] = [
                "severity": indicator.severity,
                "confidence": indicator.confidence,
                "signals": indicator.signals
            ]
            Logger.debug("   ⚠️ [AIGenerationService] Body stress indicator: \(indicator.severity) (\(Int(indicator.confidence * 100))%)")
        }

        // Add wellness score if available
        if let wellness = wellnessScore {
            payload["wellnessScore"] = wellness
            Logger.debug("   💚 [AIGenerationService] Wellness score: \(wellness)/100")
        }

        // Serialize payload to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        // Make API request
        let response = try await fetchFromAPI(body: jsonData, userId: userId)

        Logger.debug("✅ [AIGenerationService] AI summary generated (\(response.cached ? "cached" : "fresh"))")

        return response
    }

    /// Generate fallback summary when API is unavailable
    /// - Parameter metrics: Weekly performance metrics
    /// - Returns: Basic text summary
    func generateFallbackSummary(metrics: WeeklyMetricsPayload) -> String {
        let ctlChange = metrics.ctlEnd - metrics.ctlStart

        return "You averaged \(metrics.avgRecovery)% recovery this week with \(metrics.weeklyTSS) TSS of training. Your fitness trajectory shows a CTL change of \(ctlChange) points. Continue monitoring your recovery trends and training load balance."
    }

    // MARK: - Private Helpers

    /// Fetch AI summary from API with HMAC authentication
    private func fetchFromAPI(body: Data, userId: String) async throws -> AISummaryResponse {
        // Get HMAC secret from Keychain
        guard let secret = KeychainHelper.shared.get(service: keychainService, account: keychainAccount) else {
            throw NSError(domain: "AIGenerationService", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Missing HMAC secret in Keychain"
            ])
        }

        // Calculate HMAC signature
        let signature = computeHMAC(data: body, secret: secret)

        // Build request
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(signature, forHTTPHeaderField: "X-Signature")
        request.setValue(userId, forHTTPHeaderField: "X-User")
        request.httpBody = body

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "AIGenerationService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "API request failed with status \(statusCode)"
            ])
        }

        // Parse JSON response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let text = json?["text"] as? String ?? ""
        let cached = json?["cached"] as? Bool ?? false

        return AISummaryResponse(text: text, cached: cached)
    }

    /// Compute HMAC-SHA256 signature
    /// - Parameters:
    ///   - data: Data to sign
    ///   - secret: HMAC secret key
    /// - Returns: Hex-encoded signature
    private func computeHMAC(data: Data, secret: String) -> String {
        let key = SymmetricKey(data: Data(secret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: key)
        return signature.map { String(format: "%02x", $0) }.joined()
    }

    /// Format duration for display
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "+\(hours)h\(minutes)m"
        } else {
            return "+\(minutes)m"
        }
    }
}
