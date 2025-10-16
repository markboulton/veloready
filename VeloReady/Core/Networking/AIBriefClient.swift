import Foundation
import CryptoKit

// MARK: - Models

struct AIBriefRequest: Codable {
    let recovery: Int
    let sleepDelta: Double?
    let hrvDelta: Double?
    let rhrDelta: Double?
    let tsb: Double
    let tssLow: Int
    let tssHigh: Int
    let plan: String?
}

struct AIBriefResponse: Codable {
    let text: String
    let cached: Bool?
}

// MARK: - Errors

enum AIBriefError: LocalizedError {
    case invalidSignature
    case missingSecret
    case networkError(String)
    case invalidResponse
    case serverError(Int)
    case encodingError
    
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
        }
    }
    
    var debugHint: String {
        switch self {
        case .invalidSignature:
            return """
            401 Invalid Signature
            
            The server rejected the HMAC signature. This usually means:
            1. APP_HMAC_SECRET in Keychain doesn't match server
            2. Request body encoding changed
            
            To fix:
            1. Verify APP_HMAC_SECRET matches production value
            2. Check signature is computed over exact JSON bytes sent
            3. Ensure no whitespace/encoding differences
            
            Debug: Check signature in logs (first/last 4 chars only)
            """
        default:
            return errorDescription ?? "Unknown error"
        }
    }
}

// MARK: - Protocol

protocol AIBriefClientProtocol {
    func fetchBrief(request: AIBriefRequest, userId: String, bypassCache: Bool) async throws -> AIBriefResponse
}

// MARK: - Client Implementation

@MainActor
class AIBriefClient: AIBriefClientProtocol {
    static let shared = AIBriefClient()
    
    private let endpoint = "https://veloready.app/ai-brief"
    private let session: URLSession
    let cache: AIBriefCache // Made public for debug access
    private let keychainService = "com.veloready.app.secrets"
    private let secretKey = "APP_HMAC_SECRET"
    
    // Retry configuration
    private let maxRetries = 2
    private let baseRetryDelay: TimeInterval = 0.5 // 500ms
    
    init(session: URLSession = .shared, cache: AIBriefCache = AIBriefCache()) {
        self.session = session
        self.cache = cache
    }
    
    func fetchBrief(request: AIBriefRequest, userId: String, bypassCache: Bool = false) async throws -> AIBriefResponse {
        let startTime = Date()
        
        // Check cache first (unless bypassed)
        if !bypassCache {
            if let cached = cache.get(userId: userId) {
                Logger.debug("📦 Using cached AI brief (age: \(String(format: "%.1f", Date().timeIntervalSince(cached.timestamp) / 60))m)")
                
                // Emit telemetry
                emitTelemetry(
                    result: "success",
                    httpStatus: 200,
                    latencyMs: 0,
                    serverCached: true,
                    userId: userId
                )
                
                return AIBriefResponse(text: cached.text, cached: true)
            }
        }
        
        // Fetch from API with retries
        var lastError: Error?
        for attempt in 0...maxRetries {
            do {
                let response = try await performRequest(request: request, userId: userId)
                
                // Cache successful response
                cache.set(userId: userId, text: response.text)
                
                // Emit telemetry
                let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)
                emitTelemetry(
                    result: "success",
                    httpStatus: 200,
                    latencyMs: latencyMs,
                    serverCached: response.cached ?? false,
                    userId: userId
                )
                
                Logger.debug("✅ AI brief fetched successfully (latency: \(latencyMs)ms, server cached: \(response.cached ?? false))")
                return response
                
            } catch let error as AIBriefError {
                lastError = error
                
                // Don't retry on client errors (4xx)
                switch error {
                case .invalidSignature, .missingSecret, .invalidResponse, .encodingError:
                    Logger.error("AI brief error (non-retryable): \(error.localizedDescription)")
                    emitTelemetry(
                        result: "error",
                        httpStatus: 401,
                        latencyMs: Int(Date().timeIntervalSince(startTime) * 1000),
                        serverCached: false,
                        userId: userId
                    )
                    throw error
                    
                case .serverError(let code):
                    // Retry on 5xx
                    if code >= 500 && attempt < maxRetries {
                        let delay = baseRetryDelay * pow(2.0, Double(attempt))
                        Logger.warning("️ Server error \(code), retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetries + 1))")
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    
                case .networkError:
                    // Retry on network errors
                    if attempt < maxRetries {
                        let delay = baseRetryDelay * pow(2.0, Double(attempt))
                        Logger.warning("️ Network error, retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetries + 1))")
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
                
                // If we get here, we've exhausted retries
                emitTelemetry(
                    result: "error",
                    httpStatus: 0,
                    latencyMs: Int(Date().timeIntervalSince(startTime) * 1000),
                    serverCached: false,
                    userId: userId
                )
                throw error
            }
        }
        
        // Should never reach here, but throw last error if we do
        throw lastError ?? AIBriefError.networkError("Unknown error")
    }
    
    private func performRequest(request: AIBriefRequest, userId: String) async throws -> AIBriefResponse {
        // Get HMAC secret from Keychain
        guard let secret = getHMACSecret() else {
            throw AIBriefError.missingSecret
        }
        
        // Encode request to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [] // No pretty printing - compact JSON
        guard let bodyData = try? encoder.encode(request) else {
            throw AIBriefError.encodingError
        }
        
        // Compute HMAC signature over exact body bytes
        let signature = computeHMAC(data: bodyData, secret: secret)
        
        // Build request
        guard let url = URL(string: endpoint) else {
            throw AIBriefError.networkError("Invalid endpoint URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(userId, forHTTPHeaderField: "X-User")
        urlRequest.setValue(signature, forHTTPHeaderField: "X-Signature")
        urlRequest.httpBody = bodyData
        urlRequest.timeoutInterval = 10
        
        #if DEBUG
        Logger.debug("🌐 AI Brief Request:")
        Logger.debug("   User: \(userId)")
        Logger.debug("   Signature: \(signature.prefix(4))...\(signature.suffix(4))")
        Logger.debug("   Body size: \(bodyData.count) bytes")
        #endif
        
        // Send request
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIBriefError.networkError("Invalid response type")
        }
        
        Logger.data("AI Brief Response: HTTP \(httpResponse.statusCode)")
        
        // Handle HTTP errors
        switch httpResponse.statusCode {
        case 200:
            break // Success
            
        case 401:
            // Check if it's a signature error
            if let errorText = String(data: data, encoding: .utf8),
               errorText.lowercased().contains("signature") {
                throw AIBriefError.invalidSignature
            }
            throw AIBriefError.serverError(401)
            
        case 400...499:
            throw AIBriefError.serverError(httpResponse.statusCode)
            
        case 500...599:
            throw AIBriefError.serverError(httpResponse.statusCode)
            
        default:
            throw AIBriefError.networkError("Unexpected status: \(httpResponse.statusCode)")
        }
        
        // Parse JSON response
        let decoder = JSONDecoder()
        do {
            let briefResponse = try decoder.decode(AIBriefResponse.self, from: data)
            return briefResponse
        } catch {
            // If not JSON, log first 80 chars for debugging
            #if DEBUG
            if let text = String(data: data, encoding: .utf8) {
                let preview = String(text.prefix(80))
                Logger.error("Invalid JSON response (first 80 chars): \(preview)")
            }
            #endif
            throw AIBriefError.invalidResponse
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
    
    func setHMACSecret(_ secret: String) {
        KeychainHelper.shared.set(secret, service: keychainService, account: secretKey)
        Logger.debug("🔐 HMAC secret configured (length: \(secret.count) chars)")
    }
    
    private func emitTelemetry(result: String, httpStatus: Int, latencyMs: Int, serverCached: Bool, userId: String) {
        // Hash user ID for privacy
        let hashedUserId = hashUserId(userId)
        
        #if DEBUG
        Logger.data("AI Brief Telemetry:")
        Logger.debug("   Result: \(result)")
        Logger.debug("   HTTP Status: \(httpStatus)")
        Logger.debug("   Latency: \(latencyMs)ms")
        Logger.debug("   Server Cached: \(serverCached)")
        Logger.debug("   User (hashed): \(hashedUserId)")
        #endif
        
        // TODO: Send to analytics service
        // AnalyticsService.shared.track("ai_brief_fetch", properties: [
        //     "result": result,
        //     "http_status": httpStatus,
        //     "latency_ms": latencyMs,
        //     "server_cached": serverCached,
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
        Logger.debug("🗑️ AI brief cache cleared")
    }
}

// MARK: - Cache

class AIBriefCache {
    struct CachedBrief: Codable {
        let text: String
        let timestamp: Date
        let date: String // UTC calendar date (YYYY-MM-DD)
        let localDate: String // Local calendar date (YYYY-MM-DD) for 6am refresh
    }
    
    private let cacheKey = "ai_brief_cache"
    private var memoryCache: [String: CachedBrief] = [:]
    private let refreshHour = 6 // 6am local time
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    private let localDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    init() {
        // Load from persistent storage on init
        loadFromDisk()
    }
    
    func get(userId: String) -> CachedBrief? {
        let today = dateFormatter.string(from: Date())
        let todayLocal = getLocalDateForRefresh()
        let key = userCacheKey(userId: userId, date: today)
        
        guard let cached = memoryCache[key] else {
            return nil
        }
        
        // Check if still valid:
        // 1. Same UTC day
        // 2. Same local date (for 6am refresh)
        if cached.date == today && cached.localDate == todayLocal {
            return cached
        }
        
        // Expired - remove and trigger refresh
        memoryCache.removeValue(forKey: key)
        saveToDisk()
        Logger.debug("🔄 AI brief cache expired (was: \(cached.localDate), now: \(todayLocal)) - will refresh")
        return nil
    }
    
    func set(userId: String, text: String) {
        let today = dateFormatter.string(from: Date())
        let todayLocal = getLocalDateForRefresh()
        let key = userCacheKey(userId: userId, date: today)
        
        memoryCache[key] = CachedBrief(
            text: text,
            timestamp: Date(),
            date: today,
            localDate: todayLocal
        )
        
        // Persist to disk
        saveToDisk()
        
        Logger.debug("💾 Cached AI brief for user \(userId.prefix(8))... (UTC: \(today), local: \(todayLocal), persisted)")
    }
    
    func clear() {
        memoryCache.removeAll()
        UserDefaults.standard.removeObject(forKey: cacheKey)
        Logger.debug("🗑️ Cleared AI brief cache")
    }
    
    private func userCacheKey(userId: String, date: String) -> String {
        return "\(userId)_\(date)"
    }
    
    /// Get local date for refresh logic
    /// Returns today's date if current time >= 6am, yesterday's date if < 6am
    /// This ensures cache refreshes at 6am local time
    private func getLocalDateForRefresh() -> String {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // If before 6am, use yesterday's date (so cache is still valid)
        // At 6am or after, use today's date (triggers refresh)
        let dateToUse = hour < refreshHour
            ? calendar.date(byAdding: .day, value: -1, to: now) ?? now
            : now
        
        return localDateFormatter.string(from: dateToUse)
    }
    
    // MARK: - Persistence
    
    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(memoryCache) else {
            Logger.warning("⚠️ Failed to encode AI brief cache")
            return
        }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }
    
    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cache = try? JSONDecoder().decode([String: CachedBrief].self, from: data) else {
            return
        }
        memoryCache = cache
        Logger.debug("📦 Loaded \(cache.count) AI briefs from cache")
    }
    
    // Debug helper
    func getCacheInfo() -> String {
        var info = "AI Brief Cache:\n"
        info += "  Entries: \(memoryCache.count)\n"
        info += "  Refresh hour: \(refreshHour):00 local time\n"
        info += "  Current local date: \(getLocalDateForRefresh())\n"
        for (key, cached) in memoryCache {
            let age = Date().timeIntervalSince(cached.timestamp)
            info += "  - \(key): UTC=\(cached.date), Local=\(cached.localDate) (age: \(String(format: "%.1f", age / 60))m)\n"
        }
        return info
    }
}

// MARK: - Keychain Helper

class KeychainHelper {
    static let shared = KeychainHelper()
    
    func set(_ value: String, service: String, account: String) {
        let data = Data(value.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            Logger.debug("✅ Keychain: Saved \(account)")
        } else {
            Logger.error("Keychain: Failed to save \(account) (status: \(status))")
        }
    }
    
    func get(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
