import Foundation
import CoreData
@testable import VeloReady

/// Factory for creating mock data objects for testing
struct MockDataFactory {
    
    // Note: RecoveryScore, SleepScore, and IllnessIndicator mocks intentionally omitted
    // These types have complex nested structures and dependencies that are better tested
    // through their actual service classes rather than mocked directly in unit tests
    
    // MARK: - Core Data Mocks
    
    static func createDailyScores(
        context: NSManagedObjectContext,
        date: Date = Date(),
        recoveryScore: Double = 85.0,
        sleepScore: Double = 85.0,
        strainScore: Double = 65.0
    ) -> DailyScores {
        let scores = DailyScores(context: context)
        scores.date = Calendar.current.startOfDay(for: date)
        scores.recoveryScore = recoveryScore
        scores.sleepScore = sleepScore
        scores.strainScore = strainScore
        return scores
    }
    
    static func createDailyPhysio(
        context: NSManagedObjectContext,
        date: Date = Date(),
        hrv: Double = 45.0,
        hrvBaseline: Double = 44.0,
        rhr: Double = 58.0,
        rhrBaseline: Double = 60.0,
        sleepDuration: Double = 7.5,
        sleepBaseline: Double = 7.0
    ) -> DailyPhysio {
        let physio = DailyPhysio(context: context)
        physio.date = Calendar.current.startOfDay(for: date)
        physio.hrv = hrv
        physio.hrvBaseline = hrvBaseline
        physio.rhr = rhr
        physio.rhrBaseline = rhrBaseline
        physio.sleepDuration = sleepDuration
        physio.sleepBaseline = sleepBaseline
        return physio
    }
    
    static func createDailyLoad(
        context: NSManagedObjectContext,
        date: Date = Date(),
        ctl: Double = 85.0,
        atl: Double = 72.0,
        tsb: Double = 13.0,
        tss: Double = 100.0
    ) -> DailyLoad {
        let load = DailyLoad(context: context)
        load.date = Calendar.current.startOfDay(for: date)
        load.ctl = ctl
        load.atl = atl
        load.tsb = tsb
        load.tss = tss
        return load
    }
    
    // MARK: - Historical Data Mocks
    
    static func createHistoricalScores(
        context: NSManagedObjectContext,
        days: Int = 7,
        endDate: Date = Date()
    ) -> [DailyScores] {
        var scores: [DailyScores] = []
        let calendar = Calendar.current
        
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: endDate) else { continue }
            let score = createDailyScores(
                context: context,
                date: date,
                recoveryScore: Double.random(in: 60...90),
                sleepScore: Double.random(in: 60...90),
                strainScore: Double.random(in: 50...80)
            )
            scores.append(score)
        }
        
        return scores
    }
    
    // MARK: - Activity Mocks
    
    static func createIntervalsActivity(
        id: String = "12345",
        name: String = "Morning Ride",
        date: Date = Date(),
        tss: Double? = 100.0,
        duration: TimeInterval = 3600.0,
        distance: Double = 50000.0
    ) -> IntervalsActivity {
        let dateString = ISO8601DateFormatter().string(from: date)
        
        return IntervalsActivity(
            id: id,
            name: name,
            description: "Test activity",
            startDateLocal: dateString,
            type: "Ride",
            source: "STRAVA",
            duration: duration,
            distance: distance,
            elevationGain: 500.0,
            averagePower: 200.0,
            normalizedPower: 210,
            averageHeartRate: 150.0,
            maxHeartRate: 175.0,
            averageCadence: 85.0,
            averageSpeed: 6.94,
            maxSpeed: 12.5,
            calories: 800,
            fileType: "fit",
            tss: tss,
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
    }
}
