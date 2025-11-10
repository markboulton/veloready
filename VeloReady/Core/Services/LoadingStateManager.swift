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
        Logger.debug("📊 [LoadingState] Queue depth BEFORE: \(stateQueue.count), isProcessing: \(isProcessingQueue), current: \(currentState)")
        
        // CRITICAL FIX: When work completes, append to queue (don't skip pending states!)
        if case .complete = newState {
            Logger.debug("⚡ [LoadingState] Work complete - appending to queue (will show pending states first)")
            Logger.debug("⚡ [LoadingState] Queue currently has \(stateQueue.count) pending states: \(stateQueue.map { String(describing: $0) }.joined(separator: ", "))")
            stateQueue.append(newState)
            processQueueIfNeeded()
            return
        }
        
        if case .updated = newState {
            Logger.debug("⚡ [LoadingState] Updated state - appending to queue")
            Logger.debug("⚡ [LoadingState] Queue currently has \(stateQueue.count) pending states: \(stateQueue.map { String(describing: $0) }.joined(separator: ", "))")
            stateQueue.append(newState)
            processQueueIfNeeded()
            return
        }
        
        // PERFORMANCE FIX: Limit queue depth to prevent massive backlogs
        // If queue is getting too long, skip intermediate states
        // Increased from 3 to 8 to show full loading cycle
        if stateQueue.count > 8 {
            Logger.debug("⚠️ [LoadingState] Queue too long (\(stateQueue.count)), skipping intermediate states")
            // Keep only the most recent states
            stateQueue = Array(stateQueue.suffix(6))
        }
        
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
        guard !isProcessingQueue else {
            Logger.debug("📊 [LoadingState] processQueueIfNeeded: Already processing, skipping")
            return
        }
        guard !stateQueue.isEmpty else {
            Logger.debug("📊 [LoadingState] processQueueIfNeeded: Queue empty, nothing to process")
            return
        }
        
        Logger.debug("📊 [LoadingState] processQueueIfNeeded: Starting to process \(stateQueue.count) queued states")
        isProcessingQueue = true
        Task {
            await processNextState()
        }
    }
    
    private func processNextState() async {
        guard let nextState = stateQueue.first else {
            Logger.debug("📊 [LoadingState] processNextState: Queue empty, marking done")
            isProcessingQueue = false
            return
        }
        
        Logger.debug("📊 [LoadingState] processNextState: Processing state \(nextState), queue has \(stateQueue.count) items")
        
        // Wait for minimum display duration of current state
        if let startTime = currentStateStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            let minimumDuration = currentState.minimumDisplayDuration
            let remaining = minimumDuration - elapsed
            
            Logger.debug("📊 [LoadingState] Current state '\(currentState)' elapsed: \(String(format: "%.2f", elapsed))s, min: \(String(format: "%.2f", minimumDuration))s, remaining: \(String(format: "%.2f", remaining))s")
            
            if remaining > 0 {
                Logger.debug("📊 [LoadingState] Waiting \(String(format: "%.2f", remaining))s before transition")
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
        Logger.debug("📊 [LoadingState] Queue now has \(stateQueue.count) remaining states")
        
        // Process next state if queue not empty
        if !stateQueue.isEmpty {
            Logger.debug("📊 [LoadingState] Recursing to process next state...")
            await processNextState()
        } else {
            Logger.debug("📊 [LoadingState] Queue empty, marking processing complete")
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
