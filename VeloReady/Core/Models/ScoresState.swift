import Foundation

/// Unified state for all three scores (Recovery, Sleep, Strain)
/// 
/// This struct replaces 10+ loading booleans and 3 separate @Published properties
/// spread across TodayViewModel and RecoveryMetricsSectionViewModel.
///
/// Design principles:
/// - Value type (struct) for predictable behavior
/// - Equatable for change detection
/// - Immutable (only internal mutation through coordinator)
/// - Single source of truth for all score-related state
///
/// Created: 2025-11-10
/// Part of: Today View Refactoring Plan - Week 1
struct ScoresState {
    var recovery: RecoveryScore?
    var sleep: SleepScore?
    var strain: StrainScore?
    var phase: Phase
    
    /// Loading phase for score calculation
    enum Phase: Equatable {
        case initial         // Never loaded (app just launched)
        case loading         // Initial calculation in progress
        case ready           // Scores available and ready
        case refreshing      // Recalculating with new data
        case error(String)   // Error occurred during calculation
        
        var description: String {
            switch self {
            case .initial: return "initial"
            case .loading: return "loading"
            case .ready: return "ready"
            case .refreshing: return "refreshing"
            case .error(let message): return "error(\(message))"
            }
        }
    }
    
    init(
        recovery: RecoveryScore? = nil,
        sleep: SleepScore? = nil,
        strain: StrainScore? = nil,
        phase: Phase = .initial
    ) {
        self.recovery = recovery
        self.sleep = sleep
        self.strain = strain
        self.phase = phase
    }
    
    // MARK: - Computed Properties (replaces complex logic)
    
    /// All core scores (recovery + strain) are available
    /// Sleep is optional as user may not have sleep data
    var allCoreScoresAvailable: Bool {
        recovery != nil && strain != nil
    }
    
    /// Currently loading or refreshing
    var isLoading: Bool {
        phase == .loading || phase == .refreshing
    }
    
    /// Should show grey rings with shimmer effect
    /// Only during loading when NO cached scores are available
    /// If we have cached scores, show them immediately (no grey rings)
    var shouldShowGreyRings: Bool {
        // Show grey rings ONLY if:
        // 1. We're loading AND
        // 2. We don't have ANY cached scores to display
        return (phase == .loading) && !allCoreScoresAvailable
    }
    
    /// Should show "Calculating" status text
    /// During both initial load and refresh
    var shouldShowCalculatingStatus: Bool {
        phase == .loading || phase == .refreshing
    }
    
    /// Has any error
    var hasError: Bool {
        if case .error = phase {
            return true
        }
        return false
    }
    
    /// Get error message if in error state
    var errorMessage: String? {
        if case .error(let message) = phase {
            return message
        }
        return nil
    }
    
    // MARK: - Animation Logic
    
    /// Determines if ring animation should be triggered based on state transition
    /// 
    /// Rules:
    /// 1. Animate all rings together when transitioning from loading to ready
    /// 2. Animate individual rings when scores change during refresh
    /// 3. Don't animate if scores haven't changed
    ///
    /// - Parameter oldState: Previous state to compare against
    /// - Returns: True if animation should trigger
    func shouldTriggerAnimation(from oldState: ScoresState) -> Bool {
        // Rule 1: Trigger when transitioning from loading to ready (all rings animate together)
        if oldState.phase == .loading && phase == .ready {
            Logger.debug("🎬 [ScoresState] Animation trigger: loading → ready transition")
            return true
        }
        
        // Rule 2: Trigger when any score changes during refresh (individual ring animates)
        if phase == .refreshing || oldState.phase == .refreshing {
            let recoveryChanged = recovery?.score != oldState.recovery?.score
            let sleepChanged = sleep?.score != oldState.sleep?.score
            let strainChanged = strain?.score != oldState.strain?.score
            
            let anyChanged = recoveryChanged || sleepChanged || strainChanged
            
            if anyChanged {
                Logger.debug("🎬 [ScoresState] Animation trigger: score changed during refresh - R:\(recoveryChanged) S:\(sleepChanged) St:\(strainChanged)")
            }
            
            return anyChanged
        }
        
        // Rule 3: No animation needed
        return false
    }
    
    // MARK: - Debugging
    
    /// Detailed description for debugging
    var debugDescription: String {
        """
        ScoresState {
            phase: \(phase.description)
            recovery: \(recovery?.score ?? -1)
            sleep: \(sleep?.score ?? -1)
            strain: \(strain?.score ?? -1)
            allCoreScoresAvailable: \(allCoreScoresAvailable)
            isLoading: \(isLoading)
            shouldShowGreyRings: \(shouldShowGreyRings)
            shouldShowCalculatingStatus: \(shouldShowCalculatingStatus)
        }
        """
    }
}

// MARK: - Mock Data for Testing

#if DEBUG
extension ScoresState {
    /// Mock state for testing - all scores ready
    static var mockReady: ScoresState {
        ScoresState(
            recovery: .mock(score: 78),
            sleep: .mock(score: 85),
            strain: .mock(score: 120),
            phase: .ready
        )
    }
    
    /// Mock state for testing - initial load
    static var mockInitial: ScoresState {
        ScoresState(phase: .initial)
    }
    
    /// Mock state for testing - loading
    static var mockLoading: ScoresState {
        ScoresState(phase: .loading)
    }
    
    /// Mock state for testing - refreshing with existing scores
    static var mockRefreshing: ScoresState {
        ScoresState(
            recovery: .mock(score: 70),
            sleep: .mock(score: 80),
            strain: .mock(score: 100),
            phase: .refreshing
        )
    }
    
    /// Mock state for testing - error
    static var mockError: ScoresState {
        ScoresState(phase: .error("Network unavailable"))
    }
}
#endif

