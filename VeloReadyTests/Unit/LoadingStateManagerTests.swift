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
        
        manager.forceState(.calculatingScores)
        #expect(manager.currentState == .calculatingScores)
        
        manager.forceState(.contactingStrava)
        #expect(manager.currentState == .contactingStrava)
    }
    
    @Test("State transitions respect minimum duration")
    @MainActor
    func testStateThrottling() async throws {
        let manager = LoadingStateManager()
        
        let startTime = Date()
        manager.updateState(.calculatingScores)
        
        // Wait a bit for async processing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        // Should have transitioned to calculatingScores
        #expect(manager.currentState == .calculatingScores)
        
        // Add next state immediately
        manager.updateState(.contactingStrava)
        
        // Should still be on calculatingScores (minimum 1.0s)
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < 1.0 {
            #expect(manager.currentState == .calculatingScores)
        }
    }
    
    @Test("Reset clears state and queue")
    @MainActor
    func testReset() async throws {
        let manager = LoadingStateManager()
        
        manager.updateState(.calculatingScores)
        manager.updateState(.contactingStrava)
        
        manager.reset()
        
        #expect(manager.currentState == .initial)
    }
    
    @Test("Error states can be forced")
    @MainActor
    func testErrorStateForce() async throws {
        let manager = LoadingStateManager()
        
        manager.updateState(.calculatingScores)
        manager.forceState(.error(.network))
        
        #expect(manager.currentState == .error(.network))
    }
    
    @Test("Multiple state updates are queued")
    @MainActor
    func testStateQueue() async throws {
        let manager = LoadingStateManager()
        
        manager.updateState(.calculatingScores)
        manager.updateState(.contactingStrava)
        manager.updateState(.downloadingActivities(count: 5))
        
        // First state should be active
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        #expect(manager.currentState == .calculatingScores)
        
        // States should eventually process
        // (We won't wait for all durations in test, just verify queue works)
    }
}
