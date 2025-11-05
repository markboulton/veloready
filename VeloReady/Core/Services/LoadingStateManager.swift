import Foundation
import Combine

/// Manages and throttles loading state transitions
@MainActor
class LoadingStateManager: ObservableObject {
    @Published private(set) var currentState: LoadingState = .initial
    
    private var stateQueue: [LoadingState] = []
    private var isProcessingQueue = false
    private var currentStateStartTime: Date?
    
    /// Update to a new loading state (will be throttled for readability)
    func updateState(_ newState: LoadingState) {
        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        Logger.debug("📊 [LoadingState] [\(formatter.string(from: timestamp))] Queue: \(newState)")
        stateQueue.append(newState)
        processQueueIfNeeded()
    }
    
    /// Force immediate state update (bypass throttling)
    func forceState(_ newState: LoadingState) {
        stateQueue = [newState]
        currentState = newState
        currentStateStartTime = Date()
        isProcessingQueue = false
    }
    
    private func processQueueIfNeeded() {
        guard !isProcessingQueue else { return }
        guard !stateQueue.isEmpty else { return }
        
        isProcessingQueue = true
        Task {
            await processNextState()
        }
    }
    
    private func processNextState() async {
        guard let nextState = stateQueue.first else {
            isProcessingQueue = false
            return
        }
        
        // Wait for minimum display duration of current state
        if let startTime = currentStateStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            let minimumDuration = currentState.minimumDisplayDuration
            let remaining = minimumDuration - elapsed
            
            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }
        }
        
        // Transition to next state
        stateQueue.removeFirst()
        currentState = nextState
        currentStateStartTime = Date()
        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        Logger.debug("✅ [LoadingState] [\(formatter.string(from: timestamp))] Now showing: \(nextState)")
        
        // Process next state if queue not empty
        if !stateQueue.isEmpty {
            await processNextState()
        } else {
            isProcessingQueue = false
        }
    }
    
    /// Reset to initial state
    func reset() {
        stateQueue.removeAll()
        currentState = .initial
        currentStateStartTime = nil
        isProcessingQueue = false
    }
}
