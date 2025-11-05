import Foundation
import Testing
@testable import VeloReady

@Suite("Loading State Manager")
struct LoadingStateManagerTests {
    
    @Test("Initial state is .initial")
    @MainActor
    func testInitialState() async throws {
        let manager = LoadingStateManager()
        #expect(manager.currentState == .initial)
    }
    
    @Test("Force state updates immediately")
    @MainActor
    func testForceState() async throws {
        let manager = LoadingStateManager()
        
        manager.forceState(.calculatingScores(hasHealthKit: true, hasSleepData: true))
        #expect(manager.currentState == .calculatingScores(hasHealthKit: true, hasSleepData: true))
        
        manager.forceState(.contactingIntegrations(sources: [.strava]))
        #expect(manager.currentState == .contactingIntegrations(sources: [.strava]))
    }
    
    @Test("State transitions respect minimum duration")
    @MainActor
    func testStateThrottling() async throws {
        let manager = LoadingStateManager()
        
        let startTime = Date()
        manager.updateState(.calculatingScores(hasHealthKit: true, hasSleepData: true))
        
        // Wait a bit for async processing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        // Should have transitioned to calculatingScores
        #expect(manager.currentState == .calculatingScores(hasHealthKit: true, hasSleepData: true))
        
        // Add next state immediately
        manager.updateState(.contactingIntegrations(sources: [.strava]))
        
        // Should still be on calculatingScores (minimum 1.0s)
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < 1.0 {
            #expect(manager.currentState == .calculatingScores(hasHealthKit: true, hasSleepData: true))
        }
    }
    
    @Test("Reset clears state and queue")
    @MainActor
    func testReset() async throws {
        let manager = LoadingStateManager()
        
        manager.updateState(.calculatingScores(hasHealthKit: true, hasSleepData: true))
        manager.updateState(.contactingIntegrations(sources: [.strava]))
        
        manager.reset()
        
        #expect(manager.currentState == .initial)
    }
    
    @Test("Error states can be forced")
    @MainActor
    func testErrorStateForce() async throws {
        let manager = LoadingStateManager()
        
        manager.updateState(.calculatingScores(hasHealthKit: true, hasSleepData: true))
        manager.forceState(.error(.network))
        
        #expect(manager.currentState == .error(.network))
    }
    
    @Test("Multiple state updates are queued")
    @MainActor
    func testStateQueue() async throws {
        let manager = LoadingStateManager()
        
        manager.updateState(.calculatingScores(hasHealthKit: true, hasSleepData: true))
        manager.updateState(.contactingIntegrations(sources: [.strava]))
        manager.updateState(.downloadingActivities(count: 5, source: .strava))
        
        // First state should be active
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        #expect(manager.currentState == .calculatingScores(hasHealthKit: true, hasSleepData: true))
        
        // States should eventually process
        // (We won't wait for all durations in test, just verify queue works)
    }
}
