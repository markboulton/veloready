import Foundation

/// API client for intervals.icu
@MainActor
class IntervalsAPIClient: ObservableObject {
    // MARK: - Singleton
    static let shared: IntervalsAPIClient = {
        let instance = IntervalsAPIClient(oauthManager: IntervalsOAuthManager.shared)
        return instance
    }()
    
    // MARK: - Properties
    private let baseURL = "https://intervals.icu"
    private let oauthManager: IntervalsOAuthManager
    
    // MARK: - Initialization
    // Network optimization
    private let urlSession: URLSession
    private let requestQueue = DispatchQueue(label: "com.veloready.api.requests", qos: .userInitiated)
    private var pendingRequests: [String: Task<Data, Error>] = [:]
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 1.0 // 1 second between requests
    
    init(oauthManager: IntervalsOAuthManager) {
        self.oauthManager = oauthManager
        
        // Configure URLSession for optimal performance
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpMaximumConnectionsPerHost = 6
        config.requestCachePolicy = .useProtocolCachePolicy
        config.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024) // 10MB memory, 50MB disk
        
        self.urlSession = URLSession(configuration: config)
    }
    
    // MARK: - Network Optimization
    
    /// Make a request with deduplication to prevent duplicate calls
    private func makeRequest(url: URL, authHeader: String? = nil) async throws -> Data {
        let requestKey = url.absoluteString
        
        // NEW: Provider-aware rate limiting
        let throttleResult = await RequestThrottler.shared.shouldAllowRequest(
            provider: .intervalsICU,
            endpoint: url.lastPathComponent
        )
        
        if !throttleResult.allowed, let retryAfter = throttleResult.retryAfter {
            Logger.warning("⏱️ [Intervals] Rate limited - waiting \(Int(retryAfter))s")
            Logger.debug("⏱️ [Intervals] Reason: \(throttleResult.reason ?? "Rate limit exceeded")")
            try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
        }
        
        // Legacy: Minimum interval between requests (for backwards compatibility)
        if let lastRequest = lastRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
            if timeSinceLastRequest < minimumRequestInterval {
                let delay = minimumRequestInterval - timeSinceLastRequest
                Logger.debug("⏱️ [Intervals] Minimum interval: waiting \(String(format: "%.1f", delay))s")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        // Check if request is already in progress
        if let existingTask = pendingRequests[requestKey] {
            Logger.debug("🔄 Reusing existing request for: \(url.lastPathComponent)")
            return try await existingTask.value
        }
        
        // Create new request task
        let task = Task<Data, Error> {
            defer {
                // Remove from pending requests when done
                pendingRequests.removeValue(forKey: requestKey)
                lastRequestTime = Date()
            }
            
            Logger.debug("🌐 Making request to: \(url.lastPathComponent)")
            
            var request = URLRequest(url: url)
            if let authHeader = authHeader {
                request.setValue(authHeader, forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw IntervalsAPIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw IntervalsAPIError.httpError(httpResponse.statusCode)
            }
            
            return data
        }
        
        // Store the task for deduplication
        pendingRequests[requestKey] = task
        
        return try await task.value
    }
    
    // MARK: - Authentication
    
    /// Check if we have a valid access token
    private func ensureAuthenticated() async -> Bool {
        guard oauthManager.isAuthenticated else {
            return false
        }
        
        // If we have a refresh token, try to refresh if needed
        if oauthManager.refreshToken != nil {
            await oauthManager.refreshAccessToken()
        }
        
        return oauthManager.isAuthenticated
    }
    
    /// Get authorization header
    func getAuthHeader() -> String? {
        guard let accessToken = oauthManager.accessToken else { return nil }
        return "Bearer \(accessToken)"
    }
    
    // MARK: - Activities API
    
    /// Fetch recent activities
    /// Based on official intervals.icu documentation
    func fetchRecentActivities(limit: Int = 10, daysBack: Int = 30) async throws -> [Activity] {
        guard await ensureAuthenticated() else {
            throw IntervalsAPIError.notAuthenticated
        }
        
        // Use the correct endpoint format from documentation
        // Add required 'oldest' parameter
        let oldestDay = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        
        // Use a simpler date format that the API expects (YYYY-MM-DD)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let oldestDate = formatter.string(from: oldestDay)
        
        // Use URLComponents for proper URL encoding
        var components = URLComponents(string: "\(baseURL)/api/v1/athlete/0/activities")
        components?.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "oldest", value: oldestDate)
        ]
        
        guard let url = components?.url else {
            throw IntervalsAPIError.invalidURL
        }
        
        // Add auth header to URL for optimized request
        var request = URLRequest(url: url)
        request.setValue(getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        Logger.debug("📡 Fetching activities from: \(url.absoluteString)")
        
        // Use optimized request method with deduplication
        let data = try await makeRequest(url: url, authHeader: getAuthHeader())
        
        // Debug: Print raw JSON to see all available fields (only when needed)
        if let jsonString = String(data: data, encoding: .utf8) {
            Logger.debug("🔍 Raw API Response (first 200 chars): \(String(jsonString.prefix(200)))")
        }
        
        let activities = try JSONDecoder().decode([Activity].self, from: data)
        Logger.debug("✅ Fetched \(activities.count) activities")
        
        // Debug: Show what fields we actually parsed
        if let first = activities.first {
            Logger.debug("🔍 Parsed activity '\(first.name ?? "Unknown")':")
            Logger.debug("   - tss: \(first.tss?.description ?? "nil")")
            Logger.debug("   - atl: \(first.atl?.description ?? "nil")")
            Logger.debug("   - ctl: \(first.ctl?.description ?? "nil")")
            Logger.debug("   - avg_power: \(first.averagePower?.description ?? "nil")")
            Logger.debug("   - type: \(first.type ?? "nil")")
        }
        
        return activities
    }
    
    /// Fetch a specific activity by ID
    func fetchActivity(id: Int) async throws -> Activity {
        guard await ensureAuthenticated() else {
            throw IntervalsAPIError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/api/v1/athlete/activities/\(id)") else {
            throw IntervalsAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntervalsAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw IntervalsAPIError.httpError(httpResponse.statusCode)
        }
        
        let activity = try JSONDecoder().decode(Activity.self, from: data)
        return activity
    }
    
    // MARK: - Wellness API
    
    /// Fetch wellness data
    /// Based on official intervals.icu documentation
    func fetchWellnessData() async throws -> [IntervalsWellness] {
        guard await ensureAuthenticated() else {
            throw IntervalsAPIError.notAuthenticated
        }
        
        // Only fetch last 30 days of wellness data to avoid downloading thousands of records
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Use a simple date format that the API expects (YYYY-MM-DD)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let oldestDate = formatter.string(from: thirtyDaysAgo)
        
        // Use URLComponents for proper URL encoding with date parameter
        var components = URLComponents(string: "\(baseURL)/api/v1/athlete/0/wellness")
        components?.queryItems = [
            URLQueryItem(name: "oldest", value: oldestDate)
        ]
        
        guard let url = components?.url else {
            throw IntervalsAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        Logger.debug("📡 Fetching wellness from: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntervalsAPIError.invalidResponse
        }
        
        Logger.data("Wellness API Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.error("Wellness API Error: \(errorString)")
            throw IntervalsAPIError.httpError(httpResponse.statusCode)
        }
        
        let wellness = try JSONDecoder().decode([IntervalsWellness].self, from: data)
        Logger.debug("✅ Fetched \(wellness.count) wellness records (last 30 days only)")
        return wellness
    }
    
    /// Fetch wellness data for a specific date range (for development mode)
    func fetchWellnessData(from startDate: Date, to endDate: Date) async throws -> [IntervalsWellness] {
        guard await ensureAuthenticated() else {
            throw IntervalsAPIError.notAuthenticated
        }
        
        // Use a simple date format that the API expects (YYYY-MM-DD)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let oldestDate = formatter.string(from: startDate)
        let newestDate = formatter.string(from: endDate)
        
        // Use URLComponents for proper URL encoding with date parameters
        var components = URLComponents(string: "\(baseURL)/api/v1/athlete/0/wellness")
        components?.queryItems = [
            URLQueryItem(name: "oldest", value: oldestDate),
            URLQueryItem(name: "newest", value: newestDate)
        ]
        
        guard let url = components?.url else {
            throw IntervalsAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        Logger.debug("📡 Fetching wellness from: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntervalsAPIError.invalidResponse
        }
        
        Logger.data("Wellness API Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.error("Wellness API Error: \(errorString)")
            throw IntervalsAPIError.httpError(httpResponse.statusCode)
        }
        
        let wellnessData = try JSONDecoder().decode([IntervalsWellness].self, from: data)
        Logger.debug("✅ Fetched \(wellnessData.count) wellness records for date range")
        
        return wellnessData
    }
    
    /// Fetch recent activities for strain calculation (last 7 days)
    func fetchRecentActivitiesForStrain() async throws -> [Activity] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let oldestDate = dateFormatter.string(from: startDate)
        
        return try await fetchRecentActivities(limit: 50, oldest: oldestDate)
    }
    
    /// Enhanced fetch recent activities with oldest parameter
    private func fetchRecentActivities(limit: Int, oldest: String) async throws -> [Activity] {
        guard await ensureAuthenticated() else {
            throw IntervalsAPIError.notAuthenticated
        }
        
        // Build URL with query parameters
        var components = URLComponents(string: "\(baseURL)/api/v1/athlete/0/activities")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "oldest", value: oldest)
        ]
        
        guard let url = components.url else {
            throw IntervalsAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        Logger.debug("📡 Fetching strain activities from: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntervalsAPIError.invalidResponse
        }
        
        Logger.data("Strain Activities API Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.error("Strain Activities API Error: \(errorString)")
            throw IntervalsAPIError.httpError(httpResponse.statusCode)
        }
        
        let activities = try JSONDecoder().decode([Activity].self, from: data)
        Logger.debug("✅ Fetched \(activities.count) activities for strain calculation")
        return activities
    }
    
    // MARK: - Athlete Data
    
    /// Fetch athlete information including zone definitions and sportsSettings
    /// Cached for 24 hours via UnifiedCacheManager
    func fetchAthleteData() async throws -> IntervalsAthlete {
        // Use NetworkClient with UnifiedCacheManager for consistent caching
        return try await fetchAthleteDataNew()
    }
    
    /// NEW: Refactored version using NetworkClient + UnifiedCacheManager
    /// Benefits: Automatic request deduplication, memory management, metrics
    private func fetchAthleteDataNew() async throws -> IntervalsAthlete {
        guard await ensureAuthenticated() else {
            throw IntervalsAPIError.notAuthenticated
        }
        
        let athleteId = oauthManager.user?.id ?? "0"
        let cacheKey = "intervals_athlete_\(athleteId)"
        let endpoint = "\(baseURL)/api/v1/athlete/\(athleteId)/profile"
        
        guard let url = URL(string: endpoint) else {
            throw IntervalsAPIError.invalidURL
        }
        
        // Build request with auth
        let request = NetworkClient.buildGETRequest(
            url: url,
            authToken: await getAuthToken()
        )
        
        // Use NetworkClient with automatic caching
        let networkClient = await NetworkClient()
        
        do {
            // UnifiedCacheManager handles all caching logic
            let profile: IntervalsAthleteProfile = try await networkClient.executeWithCache(
                request,
                cacheKey: cacheKey,
                ttl: 86400 // 24 hours
            )
            
            let athlete = profile.athlete
            
            Logger.debug("✅ [NetworkClient] Fetched athlete: \(athlete.name ?? "Unknown")")
            Logger.debug("🔍 Power Zones: \(athlete.powerZones != nil ? "Present (FTP: \(athlete.powerZones?.ftp ?? 0)W)" : "NIL")")
            Logger.debug("🔍 HR Zones: \(athlete.heartRateZones != nil ? "Present (Max HR: \(athlete.heartRateZones?.maxHr ?? 0)bpm)" : "NIL")")
            
            return athlete
            
        } catch {
            Logger.error("Failed to fetch athlete data: \(error)")
            
            // Return mock data as fallback
            Logger.debug("ℹ️ Using mock athlete data (ID: \(athleteId))")
            return IntervalsAthlete(
                id: athleteId,
                name: oauthManager.user?.name ?? "Athlete",
                email: oauthManager.user?.email,
                profileMedium: nil,
                sex: nil,
                city: nil,
                state: nil,
                country: nil,
                timezone: nil,
                bio: nil,
                website: nil,
                powerZones: PowerZoneSettings(ftp: 250, zones: [0, 150, 200, 250, 300, 350]),
                heartRateZones: HeartRateZoneSettings(maxHr: 180, zones: [0, 120, 140, 160, 180, 200])
            )
        }
    }
    
    /// Helper to get auth token safely
    private func getAuthToken() async -> String? {
        return await oauthManager.accessToken
    }
    
    // MARK: - Calendar API
    
    /// Fetch calendar events
    func fetchCalendarEvents(startDate: Date, endDate: Date) async throws -> [IntervalsCalendarEvent] {
        guard await ensureAuthenticated() else {
            throw IntervalsAPIError.notAuthenticated
        }
        
        let formatter = ISO8601DateFormatter()
        let startDateString = formatter.string(from: startDate)
        let endDateString = formatter.string(from: endDate)
        
        guard let url = URL(string: "\(baseURL)/api/v1/athlete/calendar?start=\(startDateString)&end=\(endDateString)") else {
            throw IntervalsAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntervalsAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw IntervalsAPIError.httpError(httpResponse.statusCode)
        }
        
        let events = try JSONDecoder().decode([IntervalsCalendarEvent].self, from: data)
        return events
    }
}

// MARK: - Data Models

// MARK: - Intervals Athlete Profile Wrapper (for /profile endpoint)

struct IntervalsAthleteProfile: Codable {
    let athlete: IntervalsAthlete
}

// MARK: - Intervals Athlete Model

struct IntervalsAthlete: Codable, Identifiable {
    let id: String  // Changed to String to support intervals.icu format (e.g., "i397833")
    let name: String?
    let email: String?
    let profileMedium: String?  // Profile picture URL
    let sex: String?
    let city: String?
    let state: String?
    let country: String?
    let timezone: String?
    let bio: String?
    let website: String?
    let powerZones: PowerZoneSettings?
    let heartRateZones: HeartRateZoneSettings?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, sex, city, state, country, timezone, bio, website
        case profileMedium = "profile_medium"
        case powerZones = "power_zones"
        case heartRateZones = "heart_rate_zones"
    }
}

struct PowerZoneSettings: Codable {
    let ftp: Double?
    let zones: [Double]? // Zone boundaries
    
    enum CodingKeys: String, CodingKey {
        case ftp
        case zones
    }
}

struct HeartRateZoneSettings: Codable {
    let maxHr: Double?
    let zones: [Double]? // Zone boundaries
    
    enum CodingKeys: String, CodingKey {
        case maxHr = "max_hr"
        case zones
    }
}

// MARK: - Activity Model (Universal Format)

/// Universal activity model that represents workouts from any source
/// Previously named Activity - renamed to be source-agnostic
/// All external formats (Strava, Wahoo, Intervals.icu, etc.) convert to this
struct Activity: Codable, Identifiable {
    let id: String
    let name: String?
    let description: String?
    let startDateLocal: String
    let type: String?
    let source: String? // Activity source (e.g., "STRAVA", "GARMIN", etc.)
    var duration: TimeInterval?
    let distance: Double?
    var elevationGain: Double?
    var averagePower: Double?
    let normalizedPower: Double?
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var averageCadence: Double?
    var averageSpeed: Double?
    var maxSpeed: Double?
    let calories: Int?
    let fileType: String?
    let tss: Double? // Training Stress Score
    let intensityFactor: Double? // IF (Intensity Factor)
    let atl: Double? // Acute Training Load (7-day)
    let ctl: Double? // Chronic Training Load (42-day)
    var icuZoneTimes: [Double]? // Power zone times in seconds (mutable for local computation)
    var icuHrZoneTimes: [Double]? // Heart rate zone times in seconds (mutable for local computation)
    
    // Athlete-level data included in each activity
    let icuFtp: Double? // FTP at time of activity
    let icuPowerZones: [Double]? // Power zone boundaries at time of activity
    let icuHrZones: [Double]? // HR zone boundaries at time of activity
    let lthr: Double? // Lactate Threshold Heart Rate
    let icuRestingHr: Double? // Resting HR at time of activity
    let icuWeight: Double? // Weight at time of activity
    let athleteMaxHr: Double? // Max HR at time of activity
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, type, source, distance, calories
        case startDateLocal = "start_date_local"
        case duration = "moving_time"  // API uses moving_time, not duration
        case elevationGain = "total_elevation_gain"  // API uses total_elevation_gain
        case averagePower = "icu_average_watts"  // API uses icu_average_watts
        case normalizedPower = "icu_weighted_avg_watts"  // API uses icu_weighted_avg_watts
        case averageHeartRate = "average_heartrate"  // API uses average_heartrate (no underscore)
        case maxHeartRate = "max_heartrate"  // API uses max_heartrate (no underscore)
        case averageCadence = "average_cadence"  // API uses average_cadence (full word)
        case averageSpeed = "average_speed"  // API uses average_speed (full word)
        case maxSpeed = "max_speed"  // API uses max_speed (full word)
        case fileType = "file_type"
        case tss = "icu_training_load"  // API uses icu_training_load for TSS
        case intensityFactor = "icu_intensity"  // API uses icu_intensity
        case atl = "icu_atl"  // API uses icu_atl
        case ctl = "icu_ctl"  // API uses icu_ctl
        case icuZoneTimes = "icu_zone_times"
        case icuHrZoneTimes = "icu_hr_zone_times"
        // Athlete-level data
        case icuFtp = "icu_ftp"
        case icuPowerZones = "icu_power_zones"
        case icuHrZones = "icu_hr_zones"
        case lthr
        case icuRestingHr = "icu_resting_hr"
        case icuWeight = "icu_weight"
        case athleteMaxHr = "athlete_max_hr"
    }
    
    // Manual initializer for creating instances programmatically
    init(id: String, name: String?, description: String?, startDateLocal: String, type: String?, 
         source: String? = nil, duration: TimeInterval?, distance: Double?, elevationGain: Double?, averagePower: Double?, 
         normalizedPower: Double?, averageHeartRate: Double?, maxHeartRate: Double?, 
         averageCadence: Double?, averageSpeed: Double?, maxSpeed: Double?, calories: Int?, 
         fileType: String?, tss: Double?, intensityFactor: Double?, atl: Double?, ctl: Double?,
         icuZoneTimes: [Double]?, icuHrZoneTimes: [Double]?,
         icuFtp: Double? = nil, icuPowerZones: [Double]? = nil, icuHrZones: [Double]? = nil,
         lthr: Double? = nil, icuRestingHr: Double? = nil, icuWeight: Double? = nil, athleteMaxHr: Double? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.startDateLocal = startDateLocal
        self.type = type
        self.source = source
        self.duration = duration
        self.distance = distance
        self.elevationGain = elevationGain
        self.averagePower = averagePower
        self.normalizedPower = normalizedPower
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.averageCadence = averageCadence
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.calories = calories
        self.fileType = fileType
        self.tss = tss
        self.intensityFactor = intensityFactor
        self.atl = atl
        self.ctl = ctl
        self.icuZoneTimes = icuZoneTimes
        self.icuHrZoneTimes = icuHrZoneTimes
        self.icuFtp = icuFtp
        self.icuPowerZones = icuPowerZones
        self.icuHrZones = icuHrZones
        self.lthr = lthr
        self.icuRestingHr = icuRestingHr
        self.icuWeight = icuWeight
        self.athleteMaxHr = athleteMaxHr
    }
    
    // Custom decoder to try multiple field names for TSS, ATL, CTL
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        
        // Standard fields
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        startDateLocal = try container.decode(String.self, forKey: .startDateLocal)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        elevationGain = try container.decodeIfPresent(Double.self, forKey: .elevationGain)
        averagePower = try container.decodeIfPresent(Double.self, forKey: .averagePower)
        normalizedPower = try container.decodeIfPresent(Double.self, forKey: .normalizedPower)
        averageHeartRate = try container.decodeIfPresent(Double.self, forKey: .averageHeartRate)
        maxHeartRate = try container.decodeIfPresent(Double.self, forKey: .maxHeartRate)
        averageCadence = try container.decodeIfPresent(Double.self, forKey: .averageCadence)
        averageSpeed = try container.decodeIfPresent(Double.self, forKey: .averageSpeed)
        maxSpeed = try container.decodeIfPresent(Double.self, forKey: .maxSpeed)
        calories = try container.decodeIfPresent(Int.self, forKey: .calories)
        fileType = try container.decodeIfPresent(String.self, forKey: .fileType)
        intensityFactor = try container.decodeIfPresent(Double.self, forKey: .intensityFactor)
        
        // Try multiple possible field names for TSS
        let tssFieldNames = ["training_load", "tss", "icu_training_load", "load", "stress_score"]
        var foundTss: Double? = nil
        for fieldName in tssFieldNames {
            if let key = DynamicCodingKey(stringValue: fieldName),
               let value = try? dynamicContainer.decodeIfPresent(Double.self, forKey: key) {
                foundTss = value
                // Removed verbose logging
                break
            }
        }
        tss = foundTss
        
        // Try multiple possible field names for ATL
        let atlFieldNames = ["atl", "icu_atl", "acute_training_load", "fatigue"]
        var foundAtl: Double? = nil
        for fieldName in atlFieldNames {
            if let key = DynamicCodingKey(stringValue: fieldName),
               let value = try? dynamicContainer.decodeIfPresent(Double.self, forKey: key) {
                foundAtl = value
                // Removed verbose logging
                break
            }
        }
        atl = foundAtl
        
        // Try multiple possible field names for CTL
        let ctlFieldNames = ["ctl", "icu_ctl", "chronic_training_load", "fitness"]
        var foundCtl: Double? = nil
        for fieldName in ctlFieldNames {
            if let key = DynamicCodingKey(stringValue: fieldName),
               let value = try? dynamicContainer.decodeIfPresent(Double.self, forKey: key) {
                foundCtl = value
                // Removed verbose logging
                break
            }
        }
        ctl = foundCtl
        
        // Decode zone data - handle both array and dictionary formats
        // Intervals.icu sometimes returns zones as an array [Double], sometimes as a dictionary
        if let zonesArray = try? container.decodeIfPresent([Double].self, forKey: .icuZoneTimes) {
            icuZoneTimes = zonesArray
        } else if let zonesDict = try? container.decodeIfPresent([String: Double].self, forKey: .icuZoneTimes) {
            // Convert dictionary to array (assuming keys are zone numbers like "Z1", "Z2", etc.)
            icuZoneTimes = zonesDict.values.sorted()
        } else {
            icuZoneTimes = nil
        }
        
        if let hrZonesArray = try? container.decodeIfPresent([Double].self, forKey: .icuHrZoneTimes) {
            icuHrZoneTimes = hrZonesArray
        } else if let hrZonesDict = try? container.decodeIfPresent([String: Double].self, forKey: .icuHrZoneTimes) {
            // Convert dictionary to array
            icuHrZoneTimes = hrZonesDict.values.sorted()
        } else {
            icuHrZoneTimes = nil
        }
        
        // Decode athlete-level data included in each activity
        icuFtp = try container.decodeIfPresent(Double.self, forKey: .icuFtp)
        icuPowerZones = try container.decodeIfPresent([Double].self, forKey: .icuPowerZones)
        icuHrZones = try container.decodeIfPresent([Double].self, forKey: .icuHrZones)
        lthr = try container.decodeIfPresent(Double.self, forKey: .lthr)
        icuRestingHr = try container.decodeIfPresent(Double.self, forKey: .icuRestingHr)
        icuWeight = try container.decodeIfPresent(Double.self, forKey: .icuWeight)
        athleteMaxHr = try container.decodeIfPresent(Double.self, forKey: .athleteMaxHr)
    }
    
    // Custom encoder - use the same field names that the decoder looks for
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(startDateLocal, forKey: .startDateLocal)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encodeIfPresent(elevationGain, forKey: .elevationGain)
        try container.encodeIfPresent(averagePower, forKey: .averagePower)
        try container.encodeIfPresent(normalizedPower, forKey: .normalizedPower)
        try container.encodeIfPresent(averageHeartRate, forKey: .averageHeartRate)
        try container.encodeIfPresent(maxHeartRate, forKey: .maxHeartRate)
        try container.encodeIfPresent(averageCadence, forKey: .averageCadence)
        try container.encodeIfPresent(averageSpeed, forKey: .averageSpeed)
        try container.encodeIfPresent(maxSpeed, forKey: .maxSpeed)
        try container.encodeIfPresent(calories, forKey: .calories)
        try container.encodeIfPresent(fileType, forKey: .fileType)
        try container.encodeIfPresent(intensityFactor, forKey: .intensityFactor)
        
        // Use the FIRST field name from our decoder lists so the decoder can find them
        var dynamicContainer = encoder.container(keyedBy: DynamicCodingKey.self)
        if let tss = tss, let key = DynamicCodingKey(stringValue: "training_load") {
            try dynamicContainer.encode(tss, forKey: key)
        }
        if let atl = atl, let key = DynamicCodingKey(stringValue: "atl") {
            try dynamicContainer.encode(atl, forKey: key)
        }
        if let ctl = ctl, let key = DynamicCodingKey(stringValue: "ctl") {
            try dynamicContainer.encode(ctl, forKey: key)
        }
        
        // Encode zone data
        try container.encodeIfPresent(icuZoneTimes, forKey: .icuZoneTimes)
        try container.encodeIfPresent(icuHrZoneTimes, forKey: .icuHrZoneTimes)
        
        // Encode athlete-level data
        try container.encodeIfPresent(icuFtp, forKey: .icuFtp)
        try container.encodeIfPresent(icuPowerZones, forKey: .icuPowerZones)
        try container.encodeIfPresent(icuHrZones, forKey: .icuHrZones)
        try container.encodeIfPresent(lthr, forKey: .lthr)
        try container.encodeIfPresent(icuRestingHr, forKey: .icuRestingHr)
        try container.encodeIfPresent(icuWeight, forKey: .icuWeight)
        try container.encodeIfPresent(athleteMaxHr, forKey: .athleteMaxHr)
    }
}

// Helper for dynamic field names
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

struct IntervalsWeather: Codable {
    let temperature: Double?
    let humidity: Double?
    let windSpeed: Double?
    let windDirection: Double?
    let conditions: String?
    
    enum CodingKeys: String, CodingKey {
        case temperature, humidity
        case windSpeed = "wind_speed"
        case windDirection = "wind_direction"
        case conditions
    }
}

// MARK: - Activity Stream Data

struct ActivityStreamData: Codable {
    let time: [TimeInterval]
    let power: [Double]?
    let heartrate: [Double]?
    let cadence: [Double]?
    let velocity: [Double]? // meters/second
    let altitude: [Double]? // meters
    
    enum CodingKeys: String, CodingKey {
        case time, power, heartrate, cadence, velocity, altitude
    }
}

// Alternative format for array-based responses
struct ActivityStreamItem: Codable {
    let type: String
    let data: [Double?]  // Changed to allow null values
    let data2: [Double?]? // For longitude data in latlng streams
    
    enum CodingKeys: String, CodingKey {
        case type, data, data2
    }
}

// Safe array access extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension IntervalsAPIClient {
    /// Fetch detailed time-series data for an activity
    /// - Parameter activityId: The ID of the activity to fetch data for
    /// - Returns: Array of WorkoutSample data points
    func fetchActivityStreams(activityId: String) async throws -> [WorkoutSample] {
        Logger.debug("🗺️ ========== FETCHING ACTIVITY STREAMS ==========")
        Logger.debug("🗺️ Activity ID: \(activityId)")
        
        guard await ensureAuthenticated() else {
            throw IntervalsAPIError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/api/v1/activity/\(activityId)/streams")!
        Logger.debug("🗺️ API URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.setValue(getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        Logger.debug("📡 Fetching activity streams from: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntervalsAPIError.invalidResponse
        }
        
        Logger.data("Activity Streams API Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.error("Activity Streams API Error: \(errorString)")
            throw IntervalsAPIError.httpError(httpResponse.statusCode)
        }
        
        // Debug: Print raw response to understand the structure
        if let jsonString = String(data: data, encoding: .utf8) {
            Logger.debug("🔍 Raw Activity Streams Response: \(String(jsonString.prefix(500)))")
        }
        
        // Try to decode as different possible formats
        do {
            let streamData = try JSONDecoder().decode(ActivityStreamData.self, from: data)
            return convertStreamDataToSamples(streamData)
        } catch {
            Logger.error("Failed to decode as ActivityStreamData: \(error)")
            
            // Try to decode as array format (common in some APIs)
            do {
                let arrayData = try JSONDecoder().decode([ActivityStreamItem].self, from: data)
                return convertArrayDataToSamples(arrayData)
            } catch {
                Logger.error("Failed to decode as array format: \(error)")
                
                // Fall back to generated data
                Logger.warning("️ Using generated data as fallback")
                return []
            }
        }
    }
    
    // MARK: - Helper Functions for Stream Data Conversion
    
    private func convertStreamDataToSamples(_ streamData: ActivityStreamData) -> [WorkoutSample] {
        var samples: [WorkoutSample] = []
        
        for (index, time) in streamData.time.enumerated() {
            let sample = WorkoutSample(
                time: time,
                power: streamData.power?[index] ?? 0,
                heartRate: streamData.heartrate?[index] ?? 0,
                speed: (streamData.velocity?[index] ?? 0) * 3.6, // Convert m/s to km/h
                cadence: streamData.cadence?[index] ?? 0,
                elevation: streamData.altitude?[index] ?? 0
            )
            samples.append(sample)
        }
        
        return samples
    }
    
    private func convertArrayDataToSamples(_ arrayData: [ActivityStreamItem]) -> [WorkoutSample] {
        var timeData: [Double?] = []
        var powerData: [Double?] = []
        var heartrateData: [Double?] = []
        var cadenceData: [Double?] = []
        var velocityData: [Double?] = []
        var altitudeData: [Double?] = []
        var latlngData: [Double?] = []
        var longitudeData: [Double?] = [] // Separate longitude array
        
        // Parse array format where each item has type and data
        Logger.debug("🗺️ ========== PARSING STREAM DATA ==========")
        Logger.debug("🗺️ Total stream types in response: \(arrayData.count)")
        for item in arrayData {
            let itemType = item.type.lowercased()
            Logger.debug("🗺️ Stream type: '\(item.type)' | Data points: \(item.data.count) | Has data2: \(item.data2 != nil)")
            
            switch itemType {
            case "time":
                timeData = item.data
            case "watts", "power":
                powerData = item.data
                Logger.debug("✅ Found power data: \(item.data.count) samples")
            case "heartrate", "heart_rate":
                heartrateData = item.data
            case "cadence":
                cadenceData = item.data
            case "velocity", "velocity_smooth", "speed":
                velocityData = item.data
            case "altitude", "elevation":
                altitudeData = item.data
            case "latlng":
                latlngData = item.data
                longitudeData = item.data2 ?? []
                Logger.debug("🗺️ ========== GPS DATA FOUND ==========")
                Logger.debug("🗺️ Latitude values: \(item.data.count)")
                Logger.debug("🗺️ Longitude values: \(item.data2?.count ?? 0)")
                Logger.debug("🗺️ data2 is nil: \(item.data2 == nil)")
                
                // Debug: Print first few GPS values to understand structure
                let sampleCount = min(5, item.data.count)
                Logger.debug("🗺️ First \(sampleCount) GPS coordinates:")
                for i in 0..<sampleCount {
                    let lat = item.data[safe: i] ?? nil
                    let lng = (item.data2 ?? [])[safe: i] ?? nil
                    Logger.debug("🗺️   GPS[\(i)]: lat=\(lat?.description ?? "nil"), lng=\(lng?.description ?? "nil")")
                }
                
                // Check if any coordinates are non-zero
                let nonZeroLats = item.data.compactMap { $0 }.filter { $0 != 0 }
                let nonZeroLngs = (item.data2 ?? []).compactMap { $0 }.filter { $0 != 0 }
                Logger.debug("🗺️ Non-zero latitudes: \(nonZeroLats.count)")
                Logger.debug("🗺️ Non-zero longitudes: \(nonZeroLngs.count)")
            default:
                Logger.debug("🔍 Unknown stream type: \(item.type)")
            }
        }
        
        Logger.debug("🗺️ ========== CREATING WORKOUT SAMPLES ==========")
        Logger.debug("🗺️ Time data points: \(timeData.count)")
        Logger.debug("🗺️ Latitude data points: \(latlngData.count)")
        Logger.debug("🗺️ Longitude data points: \(longitudeData.count)")
        
        var samples: [WorkoutSample] = []
        var gpsCoordinatesFound = 0
        var gpsCoordinatesFiltered = 0
        
        // Use time data as the primary index, filtering out null values
        for (index, timeValue) in timeData.enumerated() {
            guard let time = timeValue else { continue } // Skip null time values
            
            // Parse GPS coordinates from separate lat/lng arrays
            var latitude: Double? = nil
            var longitude: Double? = nil
            if !latlngData.isEmpty && !longitudeData.isEmpty && index < latlngData.count && index < longitudeData.count {
                if let lat = latlngData[index], let lng = longitudeData[index] {
                    gpsCoordinatesFound += 1
                    // Only filter if both are exactly 0 (invalid GPS)
                    if !(lat == 0 && lng == 0) {
                        latitude = lat
                        longitude = lng
                        
                        // Log first few valid coordinates
                        if samples.count < 3 {
                            Logger.debug("🗺️ Sample \(samples.count) GPS: lat=\(lat), lng=\(lng)")
                        }
                    } else {
                        gpsCoordinatesFiltered += 1
                    }
                }
            }
            
            let sample = WorkoutSample(
                time: time,
                power: index < powerData.count ? (powerData[index] ?? 0) : 0,
                heartRate: index < heartrateData.count ? (heartrateData[index] ?? 0) : 0,
                speed: index < velocityData.count ? ((velocityData[index] ?? 0) * 3.6) : 0, // Convert m/s to km/h
                cadence: index < cadenceData.count ? (cadenceData[index] ?? 0) : 0,
                elevation: index < altitudeData.count ? (altitudeData[index] ?? 0) : 0,
                latitude: latitude,
                longitude: longitude
            )
            
            samples.append(sample)
        }
        
        Logger.debug("🗺️ ========== SAMPLE CREATION COMPLETE ==========")
        Logger.debug("🗺️ Total samples created: \(samples.count)")
        Logger.debug("🗺️ GPS coordinates found in data: \(gpsCoordinatesFound)")
        Logger.debug("🗺️ GPS coordinates filtered (0,0): \(gpsCoordinatesFiltered)")
        Logger.debug("🗺️ Samples with valid GPS: \(samples.filter { $0.latitude != nil && $0.longitude != nil }.count)")
        Logger.debug("🗺️ ===============================================")
        
        return samples
    }
}

struct IntervalsWellness: Codable, Identifiable {
    let id: String
    let weight: Double?
    let restingHeartRate: Double?
    let hrv: Double?
    let sleepDuration: TimeInterval?
    let sleepQuality: String?
    let stress: Double?
    let fatigue: Double?
    let fitness: Double?
    let form: Double?
    let steps: Int?
    let respiration: Double?
    let vo2max: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, weight, hrv, stress, fatigue, fitness, form, steps, respiration, vo2max
        case restingHeartRate = "resting_hr"
        case sleepDuration = "sleep_duration"
        case sleepQuality = "sleep_quality"
    }
}

struct IntervalsCalendarEvent: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let startDate: String
    let endDate: String?
    let type: String?
    let location: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description
        case startDate = "start_date"
        case endDate = "end_date"
        case type, location
    }
}

// MARK: - Error Types

enum IntervalsAPIError: Error, LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with intervals.icu"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

