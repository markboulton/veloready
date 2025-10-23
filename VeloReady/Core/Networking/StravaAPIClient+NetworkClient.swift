import Foundation

/// Refactored Strava API methods using NetworkClient + UnifiedCacheManager
/// Benefits: Automatic retry, request deduplication, caching, cleaner code
extension StravaAPIClient {
    
    // MARK: - Refactored Methods
    
    /// Fetch athlete profile from Strava (with caching)
    func fetchAthleteNew() async throws -> StravaAthlete {
        let endpoint = "\(baseURL)/athlete"
        
        guard let url = URL(string: endpoint) else {
            throw StravaAPIError.invalidURL
        }
        
        // Get access token
        guard let accessToken = try await getAccessToken() else {
            throw StravaAPIError.notAuthenticated
        }
        
        // Build request
        let request = NetworkClient.buildGETRequest(url: url, authToken: accessToken)
        
        // Execute with caching (24h TTL for athlete profile)
        let networkClient = await NetworkClient()
        
        do {
            isLoading = true
            let athlete: StravaAthlete = try await networkClient.executeWithCache(
                request,
                cacheKey: "strava_athlete",
                ttl: 86400 // 24 hours
            )
            isLoading = false
            
            Logger.debug("✅ [NetworkClient] Fetched Strava athlete: \(athlete.fullName)")
            return athlete
            
        } catch {
            isLoading = false
            lastError = error.localizedDescription
            throw mapError(error)
        }
    }
    
    /// Fetch activities from Strava (with caching)
    func fetchActivitiesNew(
        page: Int = 1,
        perPage: Int = 50,
        after: Date? = nil,
        before: Date? = nil
    ) async throws -> [StravaActivity] {
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
        
        // Get access token
        guard let accessToken = try await getAccessToken() else {
            throw StravaAPIError.notAuthenticated
        }
        
        // Build request
        let request = NetworkClient.buildGETRequest(url: url, authToken: accessToken)
        
        // Cache key includes page and filters for uniqueness
        let cacheKey = "strava_activities_p\(page)_\(perPage)_\(after?.timeIntervalSince1970 ?? 0)"
        
        // Execute with caching (1h TTL for activities)
        let networkClient = await NetworkClient()
        
        do {
            isLoading = true
            let activities: [StravaActivity] = try await networkClient.executeWithCache(
                request,
                cacheKey: cacheKey,
                ttl: UnifiedCacheManager.CacheTTL.activities // 1 hour
            )
            isLoading = false
            
            Logger.debug("✅ [NetworkClient] Fetched \(activities.count) Strava activities")
            return activities
            
        } catch {
            isLoading = false
            lastError = error.localizedDescription
            throw mapError(error)
        }
    }
    
    /// Fetch detailed activity data (with caching)
    func fetchActivityDetailNew(id: String) async throws -> StravaActivityDetail {
        let endpoint = "\(baseURL)/activities/\(id)"
        
        guard let url = URL(string: endpoint) else {
            throw StravaAPIError.invalidURL
        }
        
        // Get access token
        guard let accessToken = try await getAccessToken() else {
            throw StravaAPIError.notAuthenticated
        }
        
        // Build request
        let request = NetworkClient.buildGETRequest(url: url, authToken: accessToken)
        
        // Execute with caching (24h TTL for activity details - they don't change)
        let networkClient = await NetworkClient()
        
        do {
            isLoading = true
            let detail: StravaActivityDetail = try await networkClient.executeWithCache(
                request,
                cacheKey: "strava_activity_\(id)",
                ttl: 86400 // 24 hours - activity details are immutable
            )
            isLoading = false
            
            Logger.debug("✅ [NetworkClient] Fetched Strava activity detail: \(id)")
            return detail
            
        } catch {
            isLoading = false
            lastError = error.localizedDescription
            throw mapError(error)
        }
    }
    
    /// Fetch activity streams with NetworkClient (cached for 7 days)
    func fetchActivityStreamsNew(
        id: String,
        types: [String] = ["time", "watts", "heartrate", "cadence"]
    ) async throws -> [StravaStream] {
        let streamTypes = types.joined(separator: ",")
        let endpoint = "\(baseURL)/activities/\(id)/streams?keys=\(streamTypes)&key_by_type=true"
        
        guard let url = URL(string: endpoint) else {
            throw StravaAPIError.invalidURL
        }
        
        // Get access token
        guard let accessToken = try await getAccessToken() else {
            throw StravaAPIError.notAuthenticated
        }
        
        // Build request
        var request = NetworkClient.buildGETRequest(url: url, authToken: accessToken)
        request.timeoutInterval = 30 // Streams can be large
        
        // Cache key includes stream types
        let cacheKey = "strava_streams_\(id)_\(streamTypes)"
        
        // Execute with caching (7 days TTL - streams never change)
        let networkClient = await NetworkClient()
        
        do {
            isLoading = true
            
            // Custom decoder for ISO8601 dates
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Fetch raw data with caching
            let data = try await networkClient.executeWithCacheRaw(
                request,
                cacheKey: cacheKey,
                ttl: UnifiedCacheManager.CacheTTL.streams // 7 days
            )
            
            // Strava returns a dictionary when key_by_type=true
            let streamDict = try decoder.decode([String: StravaStreamData].self, from: data)
            
            // Convert to StravaStream array
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
            
            isLoading = false
            
            Logger.debug("✅ [NetworkClient] Fetched \(streams.count) Strava stream types: \(streams.map { $0.type }.joined(separator: ", "))")
            
            return streams
            
        } catch {
            isLoading = false
            lastError = error.localizedDescription
            Logger.warning("️ [NetworkClient] No streams available for activity \(id): \(error)")
            return [] // Return empty array if no streams
        }
    }
    
    // MARK: - Helper Methods
    
    /// Map NetworkError to StravaAPIError
    private func mapError(_ error: Error) -> StravaAPIError {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                return .invalidURL
            case .invalidResponse:
                return .invalidResponse
            case .httpError(let statusCode, _):
                switch statusCode {
                case 401:
                    return .notAuthenticated
                case 429:
                    return .rateLimitExceeded
                default:
                    return .httpError(statusCode: statusCode, message: "HTTP \(statusCode)")
                }
            case .decodingError(let err):
                return .decodingError(err)
            case .unknown:
                return .networkError(error)
            }
        }
        
        if let stravaError = error as? StravaAPIError {
            return stravaError
        }
        
        return .networkError(error)
    }
}
