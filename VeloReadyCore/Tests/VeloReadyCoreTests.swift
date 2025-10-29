import Foundation
import VeloReadyCore

// Simple test runner without XCTest dependency
func runTests() {
    print("🧪 Running VeloReadyCore tests...")
    
    // Test 1: TrainingLoadCalculator
    let activities = [
        ActivityData(tss: 100, date: Date()),
        ActivityData(tss: 150, date: Date()),
        ActivityData(tss: 200, date: Date())
    ]
    
    let ctl = TrainingLoadCalculator.calculateCTL(activities: activities)
    if ctl == 450.0 {
        print("✅ TrainingLoadCalculator test passed")
    } else {
        print("❌ TrainingLoadCalculator test failed: expected 450.0, got \(ctl)")
        exit(1)
    }
    
    // Test 2: ActivityData
    let date = Date()
    let activity = ActivityData(tss: 100, date: date)
    
    if activity.tss == 100 && activity.date == date {
        print("✅ ActivityData test passed")
    } else {
        print("❌ ActivityData test failed")
        exit(1)
    }
    
    print("🎉 All tests passed!")
}

runTests()
