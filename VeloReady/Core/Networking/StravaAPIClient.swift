import Foundation

/// API client for Strava
@MainActor
class StravaAPIClient: ObservableObject {
    // MARK: - Singleton
    static let shared = StravaAPIClient()
    
    private let baseURL = "https://www.strava.com/api/v3"
    
    // MARK: - Published State
    @Published var isLoading = false
    @Published var lastError: String?
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - API Calls
    
    /// Fetch athlete profile from Strava
    func fetchAthlete() async throws -> StravaAthlete {
        let endpoint = "\(baseURL)/athlete"
        return try await makeRequest(endpoint: endpoint)
    }
    
    /// Fetch activities from Strava
    /// - Parameters:
    ///   - page: Page number (starts at 1)
    ///   - perPage: Number of activities per page (max 200)
    ///   - after: Only return activities after this timestamp
    ///   - before: Only return activities before this timestamp
    func fetchActivities(page: Int = 1, perPage: Int = 50, after: Date? = nil, before: Date? = nil) async throws -> [StravaActivity] {
        var components = URLComponents(string: "\(baseURL)/athlete/activities")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        
        if let after = after {
            queryItems.append(URLQueryItem(name: "after", value: "\(Int(after.timeIntervalSince1970))"))
        }
        
        if let before = before {
            queryItems.append(URLQueryItem(name: "before", value: "\(Int(before.timeIntervalSince1970))"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw StravaAPIError.invalidURL
        }
        
        return try await makeRequest(endpoint: url.absoluteString)
    }
    
    /// Fetch detailed activity data including streams
    func fetchActivityDetail(id: String) async throws -> StravaActivityDetail {
        let endpoint = "\(baseURL)/activities/\(id)"
        return try await makeRequest(endpoint: endpoint)
    }
    
    /// Fetch activity streams (power, HR, cadence, etc.)
    func fetchActivityStreams(id: String, types: [String] = ["time", "watts", "heartrate", "cadence"]) async throws -> [StravaStream] {
        let streamTypes = types.joined(separator: ",")
        let endpoint = "\(baseURL)/activities/\(id)/streams?keys=\(streamTypes)&key_by_type=true"
        
        guard let url = URL(string: endpoint) else {
            throw StravaAPIError.invalidURL
        }
        
        // Get access token from backend
        guard let accessToken = try await getAccessToken() else {
            throw StravaAPIError.notAuthenticated
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        do {
            isLoading = true
            let (data, response) = try await URLSession.shared.data(for: request)
            isLoading = false
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StravaAPIError.invalidResponse
            }
            
            // Handle HTTP errors
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw StravaAPIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Strava returns a dictionary when key_by_type=true
            let streamDict = try decoder.decode([String: StravaStreamData].self, from: data)
            
            // Convert to StravaStream array, adding type from dictionary key
            let streams = streamDict.map { (type, streamData) -> StravaStream in
                let data: StreamData
                switch streamData.data {
                case .simple(let values):
                    data = .simple(values)
                case .latlng(let coords):
                    data = .latlng(coords)
                }
                
                return StravaStream(
                    type: type,
                    data: data,
                    series_type: streamData.series_type,
                    original_size: streamData.original_size,
                    resolution: streamData.resolution
                )
            }
            
            print("✅ [Strava API] Decoded \(streams.count) stream types: \(streams.map { $0.type }.joined(separator: ", "))")
            
            // Log stream details
            for stream in streams {
                let dataCount: Int
                switch stream.data {
                case .simple(let values):
                    dataCount = values.count
                case .latlng(let coords):
                    dataCount = coords.count
                }
                print("  📊 \(stream.type): \(dataCount) samples")
            }
            
            return streams
            
        } catch let error as StravaAPIError {
            isLoading = false
            throw error
        } catch {
            isLoading = false
            print("⚠️ [Strava API] No streams available for activity \(id): \(error)")
            return []
        }
    }
    
    // MARK: - Private Helpers
    
    private func makeRequest<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw StravaAPIError.invalidURL
        }
        
        // Get access token from backend
        guard let accessToken = try await getAccessToken() else {
            throw StravaAPIError.notAuthenticated
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        do {
            isLoading = true
            let (data, response) = try await URLSession.shared.data(for: request)
            isLoading = false
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StravaAPIError.invalidResponse
            }
            
            // Handle HTTP errors
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw StravaAPIError.notAuthenticated
            case 429:
                throw StravaAPIError.rateLimitExceeded
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw StravaAPIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("❌ [Strava API] Decoding error: \(error)")
                print("📄 Response: \(String(data: data, encoding: .utf8) ?? "no data")")
                throw StravaAPIError.decodingError(error)
            }
        } catch let error as StravaAPIError {
            isLoading = false
            lastError = error.localizedDescription
            throw error
        } catch {
            isLoading = false
            lastError = error.localizedDescription
            throw StravaAPIError.networkError(error)
        }
    }
    
    /// Get access token from backend
    private func getAccessToken() async throws -> String? {
        // Query backend for token
        let backendURL = "https://veloready.app/api/me/strava/token"
        
        guard let url = URL(string: backendURL) else {
            throw StravaAPIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        struct TokenResponse: Codable {
            let access_token: String
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return tokenResponse.access_token
    }
}

// MARK: - Models

struct StravaAthlete: Codable {
    let id: Int
    let username: String?
    let firstname: String?
    let lastname: String?
    let city: String?
    let state: String?
    let country: String?
    let sex: String?
    let weight: Double? // kg
    let ftp: Int? // watts
    let profile: String? // Profile picture URL
    let profile_medium: String?
    
    var fullName: String {
        [firstname, lastname].compactMap { $0 }.joined(separator: " ")
    }
}

struct StravaActivity: Codable, Identifiable {
    let id: Int
    let name: String
    let distance: Double // meters
    let moving_time: Int // seconds
    let elapsed_time: Int // seconds
    let total_elevation_gain: Double // meters
    let type: String // "Ride", "Run", "VirtualRide", etc.
    let sport_type: String // "Ride", "MountainBikeRide", etc.
    let start_date: String // ISO8601
    let start_date_local: String // ISO8601
    let timezone: String?
    let average_speed: Double? // m/s
    let max_speed: Double? // m/s
    let average_watts: Double?
    let weighted_average_watts: Int?
    let kilojoules: Double?
    let average_heartrate: Double?
    let max_heartrate: Double?
    let average_cadence: Double?
    let has_heartrate: Bool
    let elev_high: Double?
    let elev_low: Double?
    let calories: Double?
    let start_latlng: [Double]? // [latitude, longitude]
    
    // Strava-specific IDs
    let external_id: String? // Original file ID (for deduplication)
    let upload_id: Int?
    let upload_id_str: String?
}

struct StravaActivityDetail: Codable {
    let id: Int
    let name: String
    let description: String?
    let distance: Double
    let moving_time: Int
    let elapsed_time: Int
    let total_elevation_gain: Double
    let type: String
    let sport_type: String
    let start_date: String
    let start_date_local: String
    let average_speed: Double?
    let max_speed: Double?
    let average_watts: Double?
    let weighted_average_watts: Int?
    let kilojoules: Double?
    let average_heartrate: Double?
    let max_heartrate: Double?
    let average_cadence: Double?
    let calories: Double?
    let device_name: String?
    let gear_id: String?
    let suffer_score: Int? // Strava's own intensity metric
}

// Raw stream data from Strava API (no type field - type is the dictionary key)
struct StravaStreamData: Decodable {
    let data: StreamDataRaw
    let series_type: String
    let original_size: Int
    let resolution: String
    
    enum CodingKeys: String, CodingKey {
        case data, series_type, original_size, resolution
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        series_type = try container.decode(String.self, forKey: .series_type)
        original_size = try container.decode(Int.self, forKey: .original_size)
        resolution = try container.decode(String.self, forKey: .resolution)
        
        // Try to decode different data formats
        if let nestedArray = try? container.decode([[Double]].self, forKey: .data) {
            // latlng stream: [[lat, lng], ...]
            data = .latlng(nestedArray)
        } else if let boolArray = try? container.decode([Bool].self, forKey: .data) {
            // moving stream: [true, false, true, ...]
            // Convert bools to doubles (1.0 for true, 0.0 for false)
            data = .simple(boolArray.map { $0 ? 1.0 : 0.0 })
        } else {
            // Standard numeric streams: [123.4, 567.8, ...]
            let flatArray = try container.decode([Double].self, forKey: .data)
            data = .simple(flatArray)
        }
    }
}

// Stream with type added
struct StravaStream {
    let type: String
    let data: StreamData
    let series_type: String
    let original_size: Int
    let resolution: String
}

enum StreamDataRaw {
    case simple([Double])
    case latlng([[Double]])
}

enum StreamData {
    case simple([Double])
    case latlng([[Double]])
    
    var simpleData: [Double] {
        if case .simple(let values) = self {
            return values
        }
        return []
    }
    
    var latlngData: [[Double]] {
        if case .latlng(let coords) = self {
            return coords
        }
        return []
    }
}

// MARK: - Errors

enum StravaAPIError: LocalizedError {
    case invalidURL
    case notAuthenticated
    case networkError(Error)
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case rateLimitExceeded
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .notAuthenticated:
            return "Not authenticated with Strava. Please connect your account."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Strava API rate limit exceeded. Please try again later."
        case .invalidResponse:
            return "Invalid response from Strava"
        }
    }
}
