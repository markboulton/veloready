import Foundation

/// Mock intervals.icu data for development and testing
/// Provides realistic sample data without requiring actual API access
class MockIntervalsData: ObservableObject {
    @Published var activities: [MockIntervalsActivity] = []
    @Published var wellness: [MockIntervalsWellness] = []
    @Published var user: MockIntervalsUser?
    
    init() {
        generateMockData()
    }
    
    private func generateMockData() {
        generateUserData()
        generateActivities()
        generateWellnessData()
    }
    
    private func generateUserData() {
        user = MockIntervalsUser(
            id: 12345,
            name: "John Doe",
            email: "john.doe@example.com",
            username: "johndoe",
            profileImageURL: "https://via.placeholder.com/150",
            timezone: "America/New_York",
            units: "metric",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func generateActivities() {
        let calendar = Calendar.current
        let now = Date()
        
        let activityTypes = ["Cycling", "Running", "Swimming", "Strength Training", "Yoga"]
        let locations = ["Central Park", "Golden Gate Park", "Local Gym", "Home", "Beach"]
        
        for i in 0..<20 {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            let activityType = activityTypes.randomElement()!
            let location = locations.randomElement()!
            
            let activity = MockIntervalsActivity(
                id: "activity_\(i)",
                name: "\(activityType) at \(location)",
                description: "Great workout today!",
                startDateLocal: ISO8601DateFormatter().string(from: date),
                type: activityType,
                duration: TimeInterval.random(in: 30*60...3*3600),
                distance: Double.random(in: 5...100),
                elevationGain: Double.random(in: 0...2000),
                averagePower: Double.random(in: 150...400),
                normalizedPower: Double.random(in: 160...420),
                averageHeartRate: Double.random(in: 120...180),
                maxHeartRate: Double.random(in: 150...200),
                averageCadence: Double.random(in: 80...120),
                averageSpeed: Double.random(in: 15...35),
                maxSpeed: Double.random(in: 25...50),
                calories: Int.random(in: 200...1500),
                fileType: "gpx"
            )
            
            activities.append(activity)
        }
    }
    
    private func generateWellnessData() {
        let calendar = Calendar.current
        let now = Date()
        
        for i in 0..<30 {
            let _ = calendar.date(byAdding: .day, value: -i, to: now)!
            
            let wellnessItem = MockIntervalsWellness(
                id: "wellness_\(i)",
                weight: Double.random(in: 70...90),
                restingHeartRate: Double.random(in: 45...75),
                hrv: Double.random(in: 20...60),
                sleepDuration: TimeInterval.random(in: 6*3600...9*3600),
                sleepQuality: ["Good", "Fair", "Excellent", "Poor"].randomElement()!,
                stress: Double.random(in: 1...10),
                fatigue: Double.random(in: 1...10),
                fitness: Double.random(in: 1...10),
                form: Double.random(in: 1...10),
                steps: Int.random(in: 5000...15000),
                respiration: Double.random(in: 12...20),
                vo2max: Double.random(in: 35...65)
            )
            
            wellness.append(wellnessItem)
        }
    }
}

// MARK: - Mock Data Models

struct MockIntervalsUser: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let username: String
    let profileImageURL: String?
    let timezone: String
    let units: String
    let createdAt: Date
    let updatedAt: Date
}

struct MockIntervalsActivity: Codable, Identifiable {
    let id: String
    let name: String?
    let description: String?
    let startDateLocal: String
    let type: String?
    let duration: TimeInterval?
    let distance: Double?
    let elevationGain: Double?
    let averagePower: Double?
    let normalizedPower: Double?
    let averageHeartRate: Double?
    let maxHeartRate: Double?
    let averageCadence: Double?
    let averageSpeed: Double?
    let maxSpeed: Double?
    let calories: Int?
    let fileType: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, type, duration, distance, calories
        case startDateLocal = "start_date_local"
        case elevationGain = "elevation_gain"
        case averagePower = "avg_power"
        case normalizedPower = "normalized_power"
        case averageHeartRate = "avg_hr"
        case maxHeartRate = "max_hr"
        case averageCadence = "avg_cadence"
        case averageSpeed = "avg_speed"
        case maxSpeed = "max_speed"
        case fileType = "file_type"
    }
}

struct MockIntervalsWellness: Codable, Identifiable {
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
