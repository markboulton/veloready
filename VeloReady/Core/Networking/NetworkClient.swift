import Foundation

/// Lightweight network client that integrates with UnifiedCacheManager
/// Provides consistent error handling, retry logic, and auth injection
/// Works WITH existing cache architecture, doesn't replace it
actor NetworkClient {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let retryPolicy: RetryPolicy
    
    // MARK: - Configuration
    
    struct Configuration {
        let retryPolicy: RetryPolicy
        
        static let `default` = Configuration(
            retryPolicy: .default
        )
    }
    
    // MARK: - Initialization
    
    init(
        session: URLSession = .shared,
        configuration: Configuration = .default
    ) {
        self.session = session
        self.retryPolicy = configuration.retryPolicy
    }
    
    // MARK: - Network Status
    
    /// Check if network is available
    /// - Returns: True if online, false if offline
    func isOnline() async -> Bool {
        // Simple reachability check: try to load a lightweight resource
        // This is a basic implementation; production apps should use NWPathMonitor
        guard let url = URL(string: "https://www.apple.com/library/test/success.html") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 3.0 // Quick timeout for reachability check
        
        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return (200...299).contains(httpResponse.statusCode)
            }
            return false
        } catch {
            // Check if error is network-related
            if let urlError = error as? URLError {
                return ![.notConnectedToInternet, .networkConnectionLost, .timedOut].contains(urlError.code)
            }
            return false
        }
    }
    
    // MARK: - Request Methods
    
    /// Execute a request and decode the response
    /// - Parameters:
    ///   - request: The URLRequest to execute
    ///   - type: The type to decode the response into
    /// - Returns: Decoded response
    func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data = try await execute(request)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    /// Execute a request and return raw data
    /// - Parameters:
    ///   - request: The URLRequest to execute
    ///   - provider: Optional provider for rate limiting (e.g., .strava, .intervalsICU)
    /// - Returns: Raw response data
    func execute(_ request: URLRequest, provider: DataSource? = nil) async throws -> Data {
        return try await executeWithRetry(request, provider: provider)
    }
    
    // MARK: - Private Methods
    
    private func executeWithRetry(_ request: URLRequest, provider: DataSource? = nil) async throws -> Data {
        // NEW: Provider-aware rate limiting
        if let provider = provider {
            let throttleResult = await RequestThrottler.shared.shouldAllowRequest(
                provider: provider,
                endpoint: request.url?.lastPathComponent
            )
            
            if !throttleResult.allowed, let retryAfter = throttleResult.retryAfter {
                Logger.warning("⏱️ [NetworkClient] Rate limited for \(provider) - waiting \(Int(retryAfter))s")
                try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
            }
        }
        
        var lastError: Error?
        
        for attempt in 0...retryPolicy.maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // Handle HTTP errors
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
                }
                
                return data
                
            } catch {
                lastError = error
                
                // Check if we should retry
                if attempt < retryPolicy.maxRetries && retryPolicy.shouldRetry(error) {
                    let delay = retryPolicy.delay(for: attempt)
                    Logger.debug("🔄 [NetworkClient] Retry \(attempt + 1)/\(retryPolicy.maxRetries) after \(delay)s")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                
                throw error
            }
        }
        
        throw lastError ?? NetworkError.unknown
    }
}

// MARK: - Retry Policy

struct RetryPolicy {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let shouldRetry: (Error) -> Bool
    
    static let `default` = RetryPolicy(
        maxRetries: 2,
        baseDelay: 0.5,
        shouldRetry: { error in
            // Retry on network errors, not on HTTP errors
            if let urlError = error as? URLError {
                return [.timedOut, .networkConnectionLost, .notConnectedToInternet].contains(urlError.code)
            }
            return false
        }
    )
    
    /// Calculate delay for retry attempt using exponential backoff
    /// - Parameter attempt: The retry attempt number (0-indexed)
    /// - Returns: Delay in seconds
    func delay(for attempt: Int) -> TimeInterval {
        // Exponential backoff: 0.5s, 1s, 2s, 4s...
        return baseDelay * pow(2.0, Double(attempt))
    }
}

// MARK: - Network Error

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case offline
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let statusCode, _):
            return "HTTP error \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .offline:
            return "No internet connection"
        case .unknown:
            return "Unknown network error"
        }
    }
}
