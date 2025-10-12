import Foundation
import CryptoKit

// MARK: - Models

struct RideSummaryRequest: Codable {
    let rideId: String
    let title: String
    let startTimeUtc: String?
    let durationSec: Int?
    let distanceKm: Double?
    let elevationGainM: Double?
    let tss: Double?
    let `if`: Double?  // Intensity Factor
    let np: Double?    // Normalized Power
    let avgPower: Double?
    let powerVariabilityPct: Double?  // (VI - 1) * 100, indicates pacing smoothness
    let ftp: Double?
    let hr: HRData?
    let cadence: CadenceData?
    let timeInZonesSec: [Double]?
    let intervals: [IntervalData]?
    let fueling: FuelingData?
    let rpe: Int?
    let notes: String?
    let context: ContextData?
    let goal: String?
    
    struct HRData: Codable {
        let avg: Double?
        let max: Double?
        let lfhddriftPct: Double?
    }
    
    struct CadenceData: Codable {
        let avg: Double?
    }
    
    struct FuelingData: Codable {
        let carb_g_per_h: Double?
    }
    
    struct ContextData: Codable {
        let recoveryPct: Int?
        let tsb: Double?
    }
    
    struct IntervalData: Codable {
        let label: String?
        let durSec: Int?
        let avgP: Double?
        let avgHR: Double?
        let cad: Double?
    }
}

struct RideSummaryResponse: Codable {
    let headline: String
    let coachBrief: String
    let executionScore: Int
    let strengths: [String]
    let limiters: [String]
    let nextHint: String
    let tags: [String]
    let version: String?
    let cached: Bool?
    
    enum CodingKeys: String, CodingKey {
        case headline
        case coachBrief  // Server uses camelCase
        case executionScore  // Server uses camelCase
        case strengths
        case limiters
        case nextHint  // Server uses camelCase
        case tags
        case version
        case cached
    }
}

// MARK: - Errors

enum RideSummaryError: LocalizedError {
    case invalidSignature
    case missingSecret
    case networkError(String)
    case invalidResponse
    case serverError(Int)
    case encodingError
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidSignature:
            return "Invalid signature. Check APP_HMAC_SECRET in Keychain."
        case .missingSecret:
            return "Missing HMAC secret. Please configure APP_HMAC_SECRET."
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .encodingError:
            return "Failed to encode request"
        case .timeout:
            return "Request timed out"
        }
    }
}

// MARK: - Protocol

protocol RideSummaryClientProtocol {
    func fetchSummary(request: RideSummaryRequest, userId: String, bypassCache: Bool) async throws -> RideSummaryResponse
}

// MARK: - Client Implementation

@MainActor
class RideSummaryClient: RideSummaryClientProtocol {
    static let shared = RideSummaryClient()
    
    private let endpoint = "https://api.rideready.icu/ai-ride-summary"
    private let session: URLSession
    let cache: RideSummaryCache
    private let keychainService = "com.markboulton.rideready.secrets"
    private let secretKey = "APP_HMAC_SECRET"
    
    // Retry configuration
    private let maxRetries = 2
    private let baseRetryDelay: TimeInterval = 0.5 // 500ms
    private let timeoutInterval: TimeInterval = 15.0
    
    init(session: URLSession = .shared, cache: RideSummaryCache = RideSummaryCache()) {
        self.session = session
        self.cache = cache
    }
    
    func fetchSummary(request: RideSummaryRequest, userId: String, bypassCache: Bool = false) async throws -> RideSummaryResponse {
        let startTime = Date()
        
        // Check cache first (unless bypassed)
        if !bypassCache {
            if let cached = cache.get(rideId: request.rideId) {
                print("📦 Using cached ride summary (age: \(String(format: "%.1f", Date().timeIntervalSince(cached.timestamp) / 60))m)")
                
                // Emit telemetry
                emitTelemetry(
                    result: "success",
                    httpStatus: 200,
                    latencyMs: 0,
                    rideId: request.rideId,
                    userId: userId
                )
                
                return cached.summary
            }
        }
        
        // Fetch from API with retries
        var lastError: Error?
        for attempt in 0...maxRetries {
            do {
                let response = try await performRequest(request: request, userId: userId)
                
                // Cache successful response
                cache.set(rideId: request.rideId, summary: response)
                
                // Emit telemetry
                let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)
                emitTelemetry(
                    result: "success",
                    httpStatus: 200,
                    latencyMs: latencyMs,
                    rideId: request.rideId,
                    userId: userId
                )
                
                print("✅ Ride summary fetched successfully (latency: \(latencyMs)ms, cached: \(response.cached ?? false))")
                return response
                
            } catch let error as RideSummaryError {
                lastError = error
                
                // Don't retry on client errors (4xx)
                switch error {
                case .invalidSignature, .missingSecret, .invalidResponse, .encodingError:
                    print("❌ Ride summary error (non-retryable): \(error.localizedDescription)")
                    emitTelemetry(
                        result: "error_\(error)",
                        httpStatus: 401,
                        latencyMs: Int(Date().timeIntervalSince(startTime) * 1000),
                        rideId: request.rideId,
                        userId: userId
                    )
                    throw error
                    
                case .serverError(let code):
                    // Retry on 5xx
                    if code >= 500 && attempt < maxRetries {
                        let delay = baseRetryDelay * pow(2.0, Double(attempt))
                        print("⚠️ Server error \(code), retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetries + 1))")
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    
                case .networkError, .timeout:
                    // Retry on network errors
                    if attempt < maxRetries {
                        let delay = baseRetryDelay * pow(2.0, Double(attempt))
                        print("⚠️ Network error, retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetries + 1))")
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
                
                // If we get here, we've exhausted retries
                emitTelemetry(
                    result: "error_exhausted",
                    httpStatus: 0,
                    latencyMs: Int(Date().timeIntervalSince(startTime) * 1000),
                    rideId: request.rideId,
                    userId: userId
                )
                throw error
            }
        }
        
        // Should never reach here, but throw last error if we do
        throw lastError ?? RideSummaryError.networkError("Unknown error")
    }
    
    private func performRequest(request: RideSummaryRequest, userId: String) async throws -> RideSummaryResponse {
        // Get HMAC secret from Keychain
        guard let secret = getHMACSecret() else {
            throw RideSummaryError.missingSecret
        }
        
        // Encode request to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [] // No pretty printing - compact JSON
        guard let bodyData = try? encoder.encode(request) else {
            throw RideSummaryError.encodingError
        }
        
        // Compute HMAC signature over exact body bytes
        let signature = computeHMAC(data: bodyData, secret: secret)
        
        // Build request
        guard let url = URL(string: endpoint) else {
            throw RideSummaryError.networkError("Invalid endpoint URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(userId, forHTTPHeaderField: "X-User")
        urlRequest.setValue(signature, forHTTPHeaderField: "X-Signature")
        urlRequest.httpBody = bodyData
        urlRequest.timeoutInterval = timeoutInterval
        
        #if DEBUG
        print("🌐 Ride Summary Request:")
        print("   Ride ID: \(request.rideId)")
        print("   User: \(userId.prefix(8))...")
        print("   Signature: \(signature.prefix(4))...\(signature.suffix(4))")
        print("   Body size: \(bodyData.count) bytes")
        #endif
        
        // Redact body in release logs (just show size)
        #if !DEBUG
        print("🌐 Ride Summary Request: ride=\(request.rideId), user=\(userId.prefix(4))..., size=\(bodyData.count)B")
        #endif
        
        // Send request
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RideSummaryError.networkError("Invalid response type")
        }
        
        print("📊 Ride Summary Response: HTTP \(httpResponse.statusCode)")
        
        // Handle HTTP errors
        switch httpResponse.statusCode {
        case 200:
            break // Success
            
        case 401:
            // Check if it's a signature error
            if let errorText = String(data: data, encoding: .utf8),
               errorText.lowercased().contains("signature") {
                throw RideSummaryError.invalidSignature
            }
            throw RideSummaryError.serverError(401)
            
        case 400...499:
            throw RideSummaryError.serverError(httpResponse.statusCode)
            
        case 500...599:
            throw RideSummaryError.serverError(httpResponse.statusCode)
            
        default:
            throw RideSummaryError.networkError("Unexpected status: \(httpResponse.statusCode)")
        }
        
        // Parse JSON response
        let decoder = JSONDecoder()
        do {
            let summaryResponse = try decoder.decode(RideSummaryResponse.self, from: data)
            
            #if DEBUG
            // Store last response for debug access
            cache.lastResponseJSON = String(data: data, encoding: .utf8)
            #endif
            
            return summaryResponse
        } catch {
            // If not JSON, log full response and error for debugging
            #if DEBUG
            if let text = String(data: data, encoding: .utf8) {
                print("❌ JSON Decoding Error: \(error)")
                print("❌ Full Response (\(data.count) bytes):")
                print(text)
            }
            #endif
            
            #if !DEBUG
            // In release, just log preview
            if let text = String(data: data, encoding: .utf8) {
                let preview = String(text.prefix(80))
                print("❌ Invalid JSON response (first 80 chars): \(preview)")
            }
            #endif
            
            throw RideSummaryError.invalidResponse
        }
    }
    
    private func computeHMAC(data: Data, secret: String) -> String {
        let key = SymmetricKey(data: Data(secret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: key)
        return signature.map { String(format: "%02x", $0) }.joined()
    }
    
    func getHMACSecret() -> String? {
        return KeychainHelper.shared.get(service: keychainService, account: secretKey)
    }
    
    private func emitTelemetry(result: String, httpStatus: Int, latencyMs: Int, rideId: String, userId: String) {
        // Hash user ID for privacy
        let hashedUserId = hashUserId(userId)
        
        #if DEBUG
        print("📊 Ride Summary Telemetry:")
        print("   Result: \(result)")
        print("   HTTP Status: \(httpStatus)")
        print("   Latency: \(latencyMs)ms")
        print("   Ride ID: \(rideId)")
        print("   User (hashed): \(hashedUserId)")
        #endif
        
        // TODO: Send to analytics service
        // AnalyticsService.shared.track("ride_summary_fetch", properties: [
        //     "result": result,
        //     "http_status": httpStatus,
        //     "latency_ms": latencyMs,
        //     "ride_id": rideId,
        //     "user_id_hash": hashedUserId
        // ])
    }
    
    private func hashUserId(_ userId: String) -> String {
        let data = Data(userId.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined().prefix(16).description
    }
    
    // Debug helper
    func clearCache() {
        cache.clear()
        print("🗑️ Ride summary cache cleared")
    }
}

// MARK: - Cache

class RideSummaryCache {
    struct CachedSummary {
        let summary: RideSummaryResponse
        let timestamp: Date
    }
    
    private var cache: [String: CachedSummary] = [:]
    var lastResponseJSON: String? // For debug copying
    
    func get(rideId: String) -> CachedSummary? {
        return cache[rideId]
    }
    
    func set(rideId: String, summary: RideSummaryResponse) {
        cache[rideId] = CachedSummary(
            summary: summary,
            timestamp: Date()
        )
        
        print("💾 Cached ride summary for ride \(rideId)")
    }
    
    func clear() {
        cache.removeAll()
        lastResponseJSON = nil
    }
    
    // Debug helper
    func getCacheInfo() -> String {
        var info = "Ride Summary Cache:\n"
        info += "  Entries: \(cache.count)\n"
        for (key, cached) in cache {
            let age = Date().timeIntervalSince(cached.timestamp)
            info += "  - \(key): (age: \(String(format: "%.1f", age / 60))m)\n"
        }
        return info
    }
}
