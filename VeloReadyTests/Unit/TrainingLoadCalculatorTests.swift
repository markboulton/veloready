import Foundation
import Testing
@testable import VeloReady

@Suite("Training Load Calculator")
struct TrainingLoadCalculatorTests {
    
    @Test("Calculate training load from activities")
    func testTrainingLoadFromActivities() async {
        let calculator = TrainingLoadCalculator()
        
        // Create mock activities with TSS values
        let activities = createMockActivities()
        
        let result = await calculator.calculateTrainingLoadFromActivities(activities)
        
        // Should return valid CTL and ATL values
        #expect(result.ctl >= 0.0)
        #expect(result.atl >= 0.0)
        #expect(result.ctl.isFinite)
        #expect(result.atl.isFinite)
    }
    
    @Test("Calculate progressive training load")
    func testProgressiveTrainingLoad() async {
        let calculator = TrainingLoadCalculator()
        
        // Create mock activities with TSS values
        let activities = createMockActivities()
        
        let result = await calculator.calculateProgressiveTrainingLoad(activities)
        
        // Should return a dictionary with dates and CTL/ATL values
        #expect(result.count > 0)
        
        for (date, values) in result {
            #expect(values.ctl >= 0.0)
            #expect(values.atl >= 0.0)
            #expect(values.ctl.isFinite)
            #expect(values.atl.isFinite)
        }
    }
    
    @Test("Get daily TSS from activities")
    func testGetDailyTSSFromActivities() async {
        let calculator = TrainingLoadCalculator()
        
        // Create mock activities with TSS values
        let activities = createMockActivities()
        
        let dailyTSS = await calculator.getDailyTSSFromActivities(activities)
        
        // Should return a dictionary with dates and TSS values
        #expect(dailyTSS.count > 0)
        
        for (date, tss) in dailyTSS {
            #expect(tss >= 0.0)
            #expect(tss.isFinite)
        }
    }
    
    @Test("Handle empty activities list")
    func testEmptyActivitiesHandling() async {
        let calculator = TrainingLoadCalculator()
        
        let emptyActivities: [Activity] = []
        
        let result = await calculator.calculateTrainingLoadFromActivities(emptyActivities)
        
        // Should return zero values for empty input
        #expect(result.ctl == 0.0)
        #expect(result.atl == 0.0)
    }
    
    @Test("Handle activities without TSS")
    func testActivitiesWithoutTSS() async {
        let calculator = TrainingLoadCalculator()
        
        // Create activities without TSS values
        let activities = createMockActivitiesWithoutTSS()
        
        let result = await calculator.calculateTrainingLoadFromActivities(activities)
        
        // Should return zero values when no TSS data
        #expect(result.ctl == 0.0)
        #expect(result.atl == 0.0)
    }
}

// Helper functions to create mock activities
func createMockActivities() -> [Activity] {
    let calendar = Calendar.current
    var activities: [Activity] = []
    
    // Create activities for the last 10 days with varying TSS values
    for i in 0..<10 {
        guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
        let dateString = ISO8601DateFormatter().string(from: date)
        
        let activity = Activity(
            id: "\(1000 + i)",
            name: "Test Ride \(i)",
            description: "Test ride description",
            startDateLocal: dateString,
            type: "Ride",
            source: "TEST",
            duration: 3600,
            distance: 25000.0,
            elevationGain: 300.0,
            averagePower: 200.0,
            normalizedPower: 210,
            averageHeartRate: 150.0,
            maxHeartRate: 175.0,
            averageCadence: 85.0,
            averageSpeed: 6.94,
            maxSpeed: 12.5,
            calories: 500,
            fileType: "fit",
            tss: Double(50 + i * 5), // Varying TSS values
            intensityFactor: 0.8,
            atl: nil,
            ctl: nil,
            icuZoneTimes: nil,
            icuHrZoneTimes: nil,
            icuFtp: 250,
            icuPowerZones: nil,
            icuHrZones: nil,
            lthr: 160,
            icuRestingHr: 55,
            icuWeight: 70,
            athleteMaxHr: 185
        )
        
        activities.append(activity)
    }
    
    return activities
}

func createMockActivitiesWithoutTSS() -> [Activity] {
    let calendar = Calendar.current
    var activities: [Activity] = []
    
    // Create activities without TSS values
    for i in 0..<5 {
        guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
        let dateString = ISO8601DateFormatter().string(from: date)
        
        let activity = Activity(
            id: "\(2000 + i)",
            name: "Test Ride Without TSS \(i)",
            description: "Test ride without TSS",
            startDateLocal: dateString,
            type: "Ride",
            source: "TEST",
            duration: 3600,
            distance: 25000.0,
            elevationGain: 300.0,
            averagePower: 200.0,
            normalizedPower: 210,
            averageHeartRate: 150.0,
            maxHeartRate: 175.0,
            averageCadence: 85.0,
            averageSpeed: 6.94,
            maxSpeed: 12.5,
            calories: 500,
            fileType: "fit",
            tss: nil, // No TSS value
            intensityFactor: nil,
            atl: nil,
            ctl: nil,
            icuZoneTimes: nil,
            icuHrZoneTimes: nil,
            icuFtp: 250,
            icuPowerZones: nil,
            icuHrZones: nil,
            lthr: 160,
            icuRestingHr: 55,
            icuWeight: 70,
            athleteMaxHr: 185
        )
        
        activities.append(activity)
    }
    
    return activities
}
