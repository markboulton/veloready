import Foundation

/// Extension to integrate NetworkClient with UnifiedCacheManager
/// Provides cached request methods that automatically handle cache/network coordination
extension NetworkClient {
    
    /// Execute a request with automatic caching via UnifiedCacheManager
    /// - Parameters:
    ///   - request: The URLRequest to execute
    ///   - cacheKey: Unique cache key for this request
    ///   - ttl: Time-to-live for cache (from UnifiedCacheManager.CacheTTL)
    ///   - provider: Optional provider for rate limiting (e.g., .strava, .intervalsICU)
    /// - Returns: Decoded response (from cache or network)
    func executeWithCache<T: Decodable>(
        _ request: URLRequest,
        cacheKey: String,
        ttl: TimeInterval,
        provider: DataSource? = nil
    ) async throws -> T {
        let cache = await UnifiedCacheManager.shared
        
        return try await cache.fetch(key: cacheKey, ttl: ttl) {
            let data: Data = try await self.execute(request, provider: provider)
            return try JSONDecoder().decode(T.self, from: data)
        }
    }
    
    /// Execute a request with automatic caching, returning raw data
    /// - Parameters:
    ///   - request: The URLRequest to execute
    ///   - cacheKey: Unique cache key for this request
    ///   - ttl: Time-to-live for cache (from UnifiedCacheManager.CacheTTL)
    ///   - provider: Optional provider for rate limiting (e.g., .strava, .intervalsICU)
    /// - Returns: Raw data (from cache or network)
    func executeWithCacheRaw(
        _ request: URLRequest,
        cacheKey: String,
        ttl: TimeInterval,
        provider: DataSource? = nil
    ) async throws -> Data {
        let cache = await UnifiedCacheManager.shared
        
        return try await cache.fetch(key: cacheKey, ttl: ttl) {
            try await self.execute(request, provider: provider)
        }
    }
}

// MARK: - Request Builder Helpers

extension NetworkClient {
    
    /// Build a GET request with auth token
    /// - Parameters:
    ///   - url: The URL to request
    ///   - authToken: Optional Bearer token
    /// - Returns: Configured URLRequest
    static func buildGETRequest(
        url: URL,
        authToken: String? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    /// Build a POST request with JSON body and auth token
    /// - Parameters:
    ///   - url: The URL to request
    ///   - body: Encodable body to send as JSON
    ///   - authToken: Optional Bearer token
    /// - Returns: Configured URLRequest
    static func buildPOSTRequest<T: Encodable>(
        url: URL,
        body: T,
        authToken: String? = nil
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return request
    }
}
