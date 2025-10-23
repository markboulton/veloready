# Phase 1 Implementation Guide: Unified Networking & Caching

**Goal:** Create a modern, testable, composable networking layer  
**Timeline:** 2 weeks  
**Status:** Ready to implement

---

## Step 1: NetworkClient Foundation

### File: `Core/Networking/NetworkClient.swift`

```swift
import Foundation

// MARK: - Network Client Protocol

protocol NetworkClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func request(_ endpoint: Endpoint) async throws -> Data
}

// MARK: - Endpoint Definition

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let queryItems: [URLQueryItem]?
    let body: Data?
    let cachePolicy: CachePolicy
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    enum CachePolicy {
        case noCache
        case cacheOnly
        case cacheFirst
        case networkFirst
    }
}

// MARK: - Network Client

class NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let baseURL: URL
    private let cache: CacheService
    private let retryPolicy: RetryPolicy
    private let interceptors: [RequestInterceptor]
    
    init(
        baseURL: URL,
        session: URLSession = .shared,
        cache: CacheService = CacheService.shared,
        retryPolicy: RetryPolicy = .default,
        interceptors: [RequestInterceptor] = []
    ) {
        self.baseURL = baseURL
        self.session = session
        self.cache = cache
        self.retryPolicy = retryPolicy
        self.interceptors = interceptors
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await request(endpoint)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func request(_ endpoint: Endpoint) async throws -> Data {
        // Check cache first if policy allows
        if endpoint.cachePolicy == .cacheFirst || endpoint.cachePolicy == .cacheOnly {
            if let cached = try? await cache.get(key: cacheKey(for: endpoint)) {
                Logger.debug("📦 Cache hit: \(endpoint.path)")
                return cached
            }
            
            if endpoint.cachePolicy == .cacheOnly {
                throw NetworkError.cacheNotFound
            }
        }
        
        // Build request
        var request = try buildRequest(endpoint)
        
        // Apply interceptors
        for interceptor in interceptors {
            request = try await interceptor.adapt(request)
        }
        
        // Execute with retry
        let data = try await executeWithRetry(request)
        
        // Cache if policy allows
        if endpoint.cachePolicy != .noCache {
            try? await cache.set(key: cacheKey(for: endpoint), value: data)
        }
        
        return data
    }
    
    private func buildRequest(_ endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
        components?.queryItems = endpoint.queryItems
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        return request
    }
    
    private func executeWithRetry(_ request: URLRequest) async throws -> Data {
        var lastError: Error?
        
        for attempt in 0...retryPolicy.maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
                }
                
                return data
            } catch {
                lastError = error
                
                if attempt < retryPolicy.maxRetries && retryPolicy.shouldRetry(error: error) {
                    let delay = retryPolicy.delay(for: attempt)
                    Logger.debug("🔄 Retry \(attempt + 1)/\(retryPolicy.maxRetries) after \(delay)s")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                
                throw error
            }
        }
        
        throw lastError ?? NetworkError.unknown
    }
    
    private func cacheKey(for endpoint: Endpoint) -> String {
        "\(endpoint.method.rawValue):\(endpoint.path)"
    }
}

// MARK: - Network Error

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case cacheNotFound
    case unknown
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
            if let urlError = error as? URLError {
                return [.timedOut, .networkConnectionLost, .notConnectedToInternet].contains(urlError.code)
            }
            return false
        }
    )
    
    func delay(for attempt: Int) -> TimeInterval {
        // Exponential backoff: 0.5s, 1s, 2s, 4s...
        return baseDelay * pow(2.0, Double(attempt))
    }
}

// MARK: - Request Interceptor

protocol RequestInterceptor {
    func adapt(_ request: URLRequest) async throws -> URLRequest
}

class AuthInterceptor: RequestInterceptor {
    private let tokenProvider: () -> String?
    
    init(tokenProvider: @escaping () -> String?) {
        self.tokenProvider = tokenProvider
    }
    
    func adapt(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
```

---

## Step 2: Cache Service

### File: `Core/Data/CacheService.swift`

```swift
import Foundation

actor CacheService {
    static let shared = CacheService()
    
    private let memory = MemoryCache()
    private let disk = DiskCache()
    
    func get<T: Codable>(key: String) async throws -> T {
        // Try memory first
        if let value: T = memory.get(key: key) {
            return value
        }
        
        // Try disk second
        if let value: T = try await disk.get(key: key) {
            // Promote to memory
            memory.set(key: key, value: value)
            return value
        }
        
        throw CacheError.notFound
    }
    
    func set<T: Codable>(key: String, value: T, ttl: TimeInterval = 3600) async throws {
        // Set in both
        memory.set(key: key, value: value, ttl: ttl)
        try await disk.set(key: key, value: value, ttl: ttl)
    }
    
    func remove(key: String) async {
        memory.remove(key: key)
        await disk.remove(key: key)
    }
    
    func clear() async {
        memory.clear()
        await disk.clear()
    }
}

// MARK: - Memory Cache

class MemoryCache {
    private var cache: [String: CacheEntry] = [:]
    private let lock = NSLock()
    private let maxSize = 50 // Number of entries
    
    struct CacheEntry {
        let value: Any
        let expiry: Date
    }
    
    func get<T>(key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let entry = cache[key], entry.expiry > Date() else {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return entry.value as? T
    }
    
    func set<T>(key: String, value: T, ttl: TimeInterval = 3600) {
        lock.lock()
        defer { lock.unlock() }
        
        // Evict if over capacity
        if cache.count >= maxSize {
            // Remove oldest (simple LRU)
            if let oldest = cache.min(by: { $0.value.expiry < $1.value.expiry }) {
                cache.removeValue(forKey: oldest.key)
            }
        }
        
        cache[key] = CacheEntry(
            value: value,
            expiry: Date().addingTimeInterval(ttl)
        )
    }
    
    func remove(key: String) {
        lock.lock()
        defer { lock.unlock() }
        cache.removeValue(forKey: key)
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }
}

// MARK: - Disk Cache

actor DiskCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("VeloReadyCache", isDirectory: true)
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func get<T: Codable>(key: String) async throws -> T {
        let url = cacheDirectory.appendingPathComponent(key.hash.description)
        
        guard fileManager.fileExists(atPath: url.path) else {
            throw CacheError.notFound
        }
        
        // Check expiry
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        if let modified = attributes[.modificationDate] as? Date {
            if Date().timeIntervalSince(modified) > 3600 { // 1 hour default TTL
                try fileManager.removeItem(at: url)
                throw CacheError.expired
            }
        }
        
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func set<T: Codable>(key: String, value: T, ttl: TimeInterval = 3600) async throws {
        let url = cacheDirectory.appendingPathComponent(key.hash.description)
        let data = try JSONEncoder().encode(value)
        try data.write(to: url)
    }
    
    func remove(key: String) async {
        let url = cacheDirectory.appendingPathComponent(key.hash.description)
        try? fileManager.removeItem(at: url)
    }
    
    func clear() async {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

enum CacheError: Error {
    case notFound
    case expired
}
```

---

## Step 3: Repository Pattern

### File: `Core/Repositories/BaseRepository.swift`

```swift
import Foundation

protocol Repository {
    associatedtype Entity: Codable & Identifiable
    
    func get(id: Entity.ID) async throws -> Entity
    func list() async throws -> [Entity]
    func save(_ entity: Entity) async throws
    func delete(id: Entity.ID) async throws
}

class BaseRepository<Entity: Codable & Identifiable>: Repository {
    let client: NetworkClient
    let cache: CacheService
    
    init(client: NetworkClient, cache: CacheService = .shared) {
        self.client = client
        self.cache = cache
    }
    
    func get(id: Entity.ID) async throws -> Entity {
        fatalError("Subclass must implement")
    }
    
    func list() async throws -> [Entity] {
        fatalError("Subclass must implement")
    }
    
    func save(_ entity: Entity) async throws {
        fatalError("Subclass must implement")
    }
    
    func delete(id: Entity.ID) async throws {
        fatalError("Subclass must implement")
    }
}
```

### File: `Core/Repositories/ActivityRepository.swift`

```swift
import Foundation

class ActivityRepository: BaseRepository<UnifiedActivity> {
    
    override func list() async throws -> [UnifiedActivity] {
        // Try cache first
        do {
            let cached: [UnifiedActivity] = try await cache.get(key: "activities")
            return cached
        } catch {
            // Fetch from network
            let endpoint = Endpoint(
                path: "/activities",
                method: .get,
                headers: [:],
                queryItems: nil,
                body: nil,
                cachePolicy: .cacheFirst
            )
            
            let activities: [UnifiedActivity] = try await client.request(endpoint)
            
            // Cache result
            try await cache.set(key: "activities", value: activities)
            
            return activities
        }
    }
    
    override func get(id: String) async throws -> UnifiedActivity {
        // Try cache first
        do {
            let cached: UnifiedActivity = try await cache.get(key: "activity:\(id)")
            return cached
        } catch {
            // Fetch from network
            let endpoint = Endpoint(
                path: "/activities/\(id)",
                method: .get,
                headers: [:],
                queryItems: nil,
                body: nil,
                cachePolicy: .cacheFirst
            )
            
            let activity: UnifiedActivity = try await client.request(endpoint)
            
            // Cache result
            try await cache.set(key: "activity:\(id)", value: activity)
            
            return activity
        }
    }
}
```

---

## Step 4: Refactor Existing Client

### Before (IntervalsAPIClient.swift - 856 lines):

```swift
class IntervalsAPIClient {
    func fetchActivities() async throws -> [IntervalsActivity] {
        guard let url = URL(string: "https://intervals.icu/api/v1/activities") else {
            throw IntervalsAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntervalsAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw IntervalsAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode([IntervalsActivity].self, from: data)
    }
    
    // ... 800 more lines
}
```

### After (IntervalsRepository.swift - ~100 lines):

```swift
class IntervalsRepository: BaseRepository<IntervalsActivity> {
    
    convenience init(authManager: IntervalsOAuthManager) {
        let client = NetworkClient(
            baseURL: URL(string: "https://intervals.icu/api/v1")!,
            interceptors: [
                AuthInterceptor { authManager.accessToken }
            ]
        )
        self.init(client: client)
    }
    
    override func list() async throws -> [IntervalsActivity] {
        let endpoint = Endpoint(
            path: "/activities",
            method: .get,
            headers: [:],
            queryItems: nil,
            body: nil,
            cachePolicy: .cacheFirst
        )
        
        return try await client.request(endpoint)
    }
    
    func fetchWellness(startDate: Date, endDate: Date) async throws -> [WellnessEntry] {
        let formatter = ISO8601DateFormatter()
        let endpoint = Endpoint(
            path: "/wellness",
            method: .get,
            headers: [:],
            queryItems: [
                URLQueryItem(name: "start", value: formatter.string(from: startDate)),
                URLQueryItem(name: "end", value: formatter.string(from: endDate))
            ],
            body: nil,
            cachePolicy: .networkFirst
        )
        
        return try await client.request(endpoint)
    }
    
    // Clean, simple, testable
}
```

---

## Step 5: Testing

### File: `Tests/NetworkClientTests.swift`

```swift
import XCTest
@testable import VeloReady

class NetworkClientTests: XCTestCase {
    var client: NetworkClient!
    var mockSession: MockURLSession!
    var mockCache: MockCacheService!
    
    override func setUp() {
        mockSession = MockURLSession()
        mockCache = MockCacheService()
        client = NetworkClient(
            baseURL: URL(string: "https://api.test.com")!,
            session: mockSession,
            cache: mockCache
        )
    }
    
    func testSuccessfulRequest() async throws {
        // Given
        let expectedData = """
        {"id": "123", "name": "Test Activity"}
        """.data(using: .utf8)!
        
        mockSession.nextResponse = (expectedData, HTTPURLResponse(
            url: URL(string: "https://api.test.com/activities")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!)
        
        // When
        let endpoint = Endpoint(
            path: "/activities",
            method: .get,
            headers: [:],
            queryItems: nil,
            body: nil,
            cachePolicy: .noCache
        )
        
        let activity: TestActivity = try await client.request(endpoint)
        
        // Then
        XCTAssertEqual(activity.id, "123")
        XCTAssertEqual(activity.name, "Test Activity")
    }
    
    func testCacheHit() async throws {
        // Given
        let cachedActivity = TestActivity(id: "456", name: "Cached")
        mockCache.storage["GET:/activities"] = try! JSONEncoder().encode(cachedActivity)
        
        // When
        let endpoint = Endpoint(
            path: "/activities",
            method: .get,
            headers: [:],
            queryItems: nil,
            body: nil,
            cachePolicy: .cacheFirst
        )
        
        let activity: TestActivity = try await client.request(endpoint)
        
        // Then
        XCTAssertEqual(activity.id, "456")
        XCTAssertEqual(mockSession.requestCount, 0) // No network request
    }
    
    func testRetryOnFailure() async throws {
        // Given
        mockSession.failureCount = 2 // Fail first 2 times
        mockSession.nextResponse = (Data(), HTTPURLResponse(
            url: URL(string: "https://api.test.com/activities")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!)
        
        // When
        let endpoint = Endpoint(
            path: "/activities",
            method: .get,
            headers: [:],
            queryItems: nil,
            body: nil,
            cachePolicy: .noCache
        )
        
        _ = try await client.request(endpoint)
        
        // Then
        XCTAssertEqual(mockSession.requestCount, 3) // 1 original + 2 retries
    }
}

struct TestActivity: Codable {
    let id: String
    let name: String
}
```

---

## Migration Checklist

### Week 1: Setup
- [ ] Create `Core/Networking/NetworkClient.swift`
- [ ] Create `Core/Data/CacheService.swift`
- [ ] Create `Core/Repositories/BaseRepository.swift`
- [ ] Add unit tests for NetworkClient
- [ ] Add unit tests for CacheService

### Week 2: Migration
- [ ] Create `IntervalsRepository` (migrate from IntervalsAPIClient)
- [ ] Create `StravaRepository` (migrate from StravaAPIClient)
- [ ] Create `VeloReadyRepository` (migrate from VeloReadyAPIClient)
- [ ] Update services to use repositories
- [ ] Delete old cache implementations
- [ ] Run full test suite
- [ ] Performance testing

---

## Success Metrics

### Code Quality
- ✅ All API calls use NetworkClient
- ✅ All caching uses CacheService
- ✅ Zero duplicate HTTP logic
- ✅ 80% test coverage on networking layer

### Performance
- ✅ Reduced API calls (better caching)
- ✅ Faster response times (memory cache)
- ✅ Lower data usage (intelligent caching)

### Developer Experience
- ✅ Easy to add new API endpoints
- ✅ Testable without mocking URLSession
- ✅ Clear error handling
- ✅ Self-documenting code

---

## Next Steps

1. **Review this plan**
2. **Create NetworkClient** (start here!)
3. **Add tests**
4. **Migrate one repository** (proof of concept)
5. **Roll out to all APIs**

Ready to start? Let's build NetworkClient first! 🚀
