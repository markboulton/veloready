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
    /// - Parameter request: The URLRequest to execute
    /// - Returns: Raw response data
    func execute(_ request: URLRequest) async throws -> Data {
        return try await executeWithRetry(request)
    }
    
    // MARK: - Private Methods
    
    private func executeWithRetry(_ request: URLRequest) async throws -> Data {
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
        case .unknown:
            return "Unknown network error"
        }
    }
}
