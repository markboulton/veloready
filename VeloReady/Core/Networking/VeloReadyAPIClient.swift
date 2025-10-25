import Foundation

/// Centralized API client for VeloReady backend
/// Routes all Strava API calls through backend for:
/// - Better caching (5min for activities, 24h for streams)
/// - Rate limiting & monitoring
/// - Security (tokens never leave backend)
/// - Scalability (backend can handle 100K+ users)
@MainActor
class VeloReadyAPIClient: ObservableObject {
    // MARK: - Singleton
    static let shared = VeloReadyAPIClient()
    
    private let baseURL = "https://api.veloready.app"
    
    // MARK: - Published State
    @Published var isLoading = false
    @Published var lastError: String?
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - API Calls
    
    /// Fetch activities from backend (cached for 5 minutes)
    /// - Parameters:
    ///   - daysBack: Number of days to fetch (default: 30, backend may cap at 90-365)
    ///   - limit: Maximum activities to return (default: 50, can request up to 500)
    /// - Returns: Array of Strava activities
    func fetchActivities(daysBack: Int = 30, limit: Int = 50) async throws -> [StravaActivity] {
        let endpoint = "\(baseURL)/api/activities?daysBack=\(daysBack)&limit=\(limit)"
        
        guard let url = URL(string: endpoint) else {
            throw VeloReadyAPIError.invalidURL
        }
        
        Logger.debug("🌐 [VeloReady API] Fetching activities (daysBack: \(daysBack), limit: \(limit))")
        
        let response: ActivitiesResponse = try await makeRequest(url: url)
        
        Logger.debug("✅ [VeloReady API] Received \(response.activities.count) activities (cached until: \(response.metadata.cachedUntil))")
        
        return response.activities
    }
    
    /// Fetch activity streams from backend (cached for 24 hours)
    /// - Parameters:
    ///   - activityId: The activity ID (Strava or Intervals)
    ///   - source: Data source ("strava" or "intervals")
    /// - Returns: Dictionary of stream types to stream data
    func fetchActivityStreams(activityId: String, source: APIDataSource = .strava) async throws -> [String: StravaStreamData] {
        let endpoint: String
        switch source {
        case .strava:
            endpoint = "\(baseURL)/api/streams/\(activityId)"
        case .intervals:
            endpoint = "\(baseURL)/api/intervals/streams/\(activityId)"
        }
        
        guard let url = URL(string: endpoint) else {
            throw VeloReadyAPIError.invalidURL
        }
        
        Logger.debug("🌐 [VeloReady API] Fetching streams for activity: \(activityId) (source: \(source))")
        
        let streams: [String: StravaStreamData] = try await makeRequest(url: url)
        
        Logger.debug("✅ [VeloReady API] Received \(streams.count) stream types for activity \(activityId)")
        
        return streams
    }
    
    // MARK: - Intervals.icu Methods
    
    /// Fetch activities from Intervals.icu (cached for 5 minutes)
    /// - Parameters:
    ///   - daysBack: Number of days to fetch (default: 30, max: 120)
    ///   - limit: Maximum activities to return (default: 50, max: 200)
    /// - Returns: Array of Intervals activities
    func fetchIntervalsActivities(daysBack: Int = 30, limit: Int = 50) async throws -> [IntervalsActivity] {
        let endpoint = "\(baseURL)/api/intervals/activities?daysBack=\(daysBack)&limit=\(limit)"
        
        guard let url = URL(string: endpoint) else {
            throw VeloReadyAPIError.invalidURL
        }
        
        Logger.debug("🌐 [VeloReady API] Fetching Intervals activities (daysBack: \(daysBack), limit: \(limit))")
        
        let response: IntervalsActivitiesResponse = try await makeRequest(url: url)
        
        Logger.debug("✅ [VeloReady API] Received \(response.activities.count) Intervals activities")
        
        return response.activities
    }
    
    /// Fetch wellness data from Intervals.icu (cached for 5 minutes)
    /// - Parameter days: Number of days to fetch (default: 30, max: 90)
    /// - Returns: Array of wellness data
    func fetchIntervalsWellness(days: Int = 30) async throws -> [IntervalsWellness] {
        let endpoint = "\(baseURL)/api/intervals/wellness?days=\(days)"
        
        guard let url = URL(string: endpoint) else {
            throw VeloReadyAPIError.invalidURL
        }
        
        Logger.debug("🌐 [VeloReady API] Fetching Intervals wellness (days: \(days))")
        
        let response: IntervalsWellnessResponse = try await makeRequest(url: url)
        
        Logger.debug("✅ [VeloReady API] Received \(response.wellness.count) wellness entries")
        
        return response.wellness
    }
    
    // MARK: - Private Helpers
    
    private func makeRequest<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        // Add Supabase authentication header
        if let accessToken = SupabaseClient.shared.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            Logger.debug("🔐 [VeloReady API] Added auth header")
        } else {
            Logger.warning("⚠️ [VeloReady API] No auth token available - request may fail")
        }
        
        do {
            isLoading = true
            let (data, response) = try await URLSession.shared.data(for: request)
            isLoading = false
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeloReadyAPIError.invalidResponse
            }
            
            // Log cache status
            if let cacheStatus = httpResponse.allHeaderFields["X-Cache"] as? String {
                Logger.debug("📦 Cache status: \(cacheStatus)")
            }
            
            // Handle HTTP errors
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw VeloReadyAPIError.notAuthenticated
            case 404:
                throw VeloReadyAPIError.notFound
            case 429:
                throw VeloReadyAPIError.rateLimitExceeded
            case 500...599:
                throw VeloReadyAPIError.serverError
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw VeloReadyAPIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                Logger.error("[VeloReady API] Decoding error: \(error)")
                Logger.debug("📄 Response: \(String(data: data, encoding: .utf8) ?? "no data")")
                throw VeloReadyAPIError.decodingError(error)
            }
        } catch let error as VeloReadyAPIError {
            isLoading = false
            lastError = error.localizedDescription
            throw error
        } catch {
            isLoading = false
            lastError = error.localizedDescription
            throw VeloReadyAPIError.networkError(error)
        }
    }
}

// MARK: - Data Source

enum APIDataSource: String {
    case strava
    case intervals
}

// MARK: - Response Models

struct ActivitiesResponse: Codable {
    let activities: [StravaActivity]
    let metadata: ActivitiesMetadata
}

struct ActivitiesMetadata: Codable {
    let athleteId: Int
    let daysBack: Int
    let limit: Int
    let count: Int
    let cachedUntil: String
}

struct IntervalsActivitiesResponse: Codable {
    let activities: [IntervalsActivity]
    let metadata: IntervalsMetadata
}

struct IntervalsMetadata: Codable {
    let athleteId: String
    let daysBack: Int
    let limit: Int
    let count: Int
    let source: String
    let cachedUntil: String
}

struct IntervalsWellnessResponse: Codable {
    let wellness: [IntervalsWellness]
    let metadata: IntervalsWellnessMetadata
}

struct IntervalsWellnessMetadata: Codable {
    let athleteId: String
    let days: Int
    let count: Int
    let source: String
    let cachedUntil: String
}

// MARK: - Errors

enum VeloReadyAPIError: LocalizedError {
    case invalidURL
    case notAuthenticated
    case notFound
    case networkError(Error)
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case rateLimitExceeded
    case serverError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .notAuthenticated:
            return "Not authenticated. Please connect your account."
        case .notFound:
            return "Resource not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again later."
        case .serverError:
            return "Server error. Please try again later."
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}
