import Foundation
import HealthKit

#if DEBUG
/// Extension to create HKWorkout instances for previews and testing
/// Uses deprecated initializer as HKWorkoutBuilder requires HealthKit store access
extension HKWorkout {
    /// Creates a mock workout for preview/testing purposes
    /// - Warning: This method uses the deprecated HKWorkout initializer.
    ///   It is intended for preview/test use only. Production code should use HKWorkoutBuilder.
    /// - Parameters:
    ///   - activityType: The type of workout activity
    ///   - start: Start date of the workout
    ///   - end: End date of the workout
    ///   - duration: Duration in seconds (optional, calculated from start/end if nil)
    ///   - totalEnergyBurned: Energy burned during workout (optional)
    ///   - totalDistance: Distance covered during workout (optional)
    ///   - metadata: Additional workout metadata (optional)
    /// - Returns: A mock HKWorkout instance suitable for previews
    static func mockWorkout(
        activityType: HKWorkoutActivityType,
        start: Date,
        end: Date,
        duration: TimeInterval? = nil,
        totalEnergyBurned: HKQuantity? = nil,
        totalDistance: HKQuantity? = nil,
        metadata: [String: Any]? = nil
    ) -> HKWorkout {
        let workoutDuration = duration ?? end.timeIntervalSince(start)
        #warning("Using deprecated HKWorkout initializer for preview/test code. Production code should use HKWorkoutBuilder.")
        return HKWorkout(
            activityType: activityType,
            start: start,
            end: end,
            duration: workoutDuration,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            metadata: metadata
        )
    }
}
#endif

/// Mock health data for development and testing
/// Provides realistic sample data without requiring actual HealthKit access
class MockHealthData: ObservableObject {
    @Published var sleepData: [SleepData] = []
    @Published var hrvData: [HRVData] = []
    @Published var restingHeartRate: [HeartRateData] = []
    @Published var activities: [ActivityData] = []
    
    init() {
        generateMockData()
    }
    
    private func generateMockData() {
        generateSleepData()
        generateHRVData()
        generateHeartRateData()
        generateActivityData()
    }
    
    private func generateSleepData() {
        let calendar = Calendar.current
        let now = Date()
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            
            // Generate realistic sleep patterns
            let sleepDuration = TimeInterval.random(in: 6*3600...9*3600) // 6-9 hours
            let sleepEfficiency = Double.random(in: 0.75...0.95)
            let deepSleep = sleepDuration * 0.2 * sleepEfficiency
            let lightSleep = sleepDuration * 0.5 * sleepEfficiency
            let remSleep = sleepDuration * 0.3 * sleepEfficiency
            
            let sleepData = SleepData(
                id: UUID(),
                date: date,
                duration: sleepDuration,
                deepSleep: deepSleep,
                lightSleep: lightSleep,
                remSleep: remSleep,
                efficiency: sleepEfficiency,
                bedTime: calendar.date(byAdding: .hour, value: -Int(sleepDuration/3600), to: date)!,
                wakeTime: date
            )
            
            self.sleepData.append(sleepData)
        }
    }
    
    private func generateHRVData() {
        let calendar = Calendar.current
        let now = Date()
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            
            // Generate realistic HRV values (20-60ms is typical range)
            let hrvValue = Double.random(in: 20...60)
            let hrvData = HRVData(
                id: UUID(),
                date: date,
                value: hrvValue,
                unit: "ms"
            )
            
            self.hrvData.append(hrvData)
        }
    }
    
    private func generateHeartRateData() {
        let calendar = Calendar.current
        let now = Date()
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            
            // Generate realistic resting heart rate (45-75 bpm)
            let restingHR = Int.random(in: 45...75)
            let heartRateData = HeartRateData(
                id: UUID(),
                date: date,
                value: Double(restingHR),
                unit: "bpm",
                type: .resting
            )
            
            self.restingHeartRate.append(heartRateData)
        }
    }
    
    private func generateActivityData() {
        let calendar = Calendar.current
        let now = Date()
        
        let activityTypes = ["Cycling", "Running", "Walking", "Swimming", "Strength Training"]
        
        for i in 0..<14 {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            
            // Generate 1-3 activities per day
            let activityCount = Int.random(in: 1...3)
            
            for _ in 0..<activityCount {
                let activityType = activityTypes.randomElement()!
                let duration = TimeInterval.random(in: 30*60...3*3600) // 30 min to 3 hours
                let distance = Double.random(in: 5...100) // 5-100 km
                let calories = Int.random(in: 200...1500)
                
                let activity = ActivityData(
                    id: UUID(),
                    name: "\(activityType) Workout",
                    type: activityType,
                    date: date,
                    duration: duration,
                    distance: distance,
                    calories: calories,
                    averageHeartRate: Double.random(in: 120...180),
                    maxHeartRate: Double.random(in: 150...200)
                )
                
                self.activities.append(activity)
            }
        }
    }
}

// MARK: - Data Models

struct SleepData: Identifiable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let deepSleep: TimeInterval
    let lightSleep: TimeInterval
    let remSleep: TimeInterval
    let efficiency: Double
    let bedTime: Date
    let wakeTime: Date
}

struct HRVData: Identifiable {
    let id: UUID
    let date: Date
    let value: Double
    let unit: String
}

struct HeartRateData: Identifiable {
    let id: UUID
    let date: Date
    let value: Double
    let unit: String
    let type: HeartRateType
    
    enum HeartRateType {
        case resting
        case active
        case recovery
    }
}

struct ActivityData: Identifiable {
    let id: UUID
    let name: String
    let type: String
    let date: Date
    let duration: TimeInterval
    let distance: Double
    let calories: Int
    let averageHeartRate: Double
    let maxHeartRate: Double
}
