import Foundation

/// Singleton to persist scroll animation state across view recreations
class ScrollStateManager {
    static let shared = ScrollStateManager()
    
    private init() {}
    
    /// Stores scroll state for each view (keyed by view ID)
    private var scrollStates: [String: ScrollState] = [:]
    
    struct ScrollState {
        var hasAppeared: Bool = false
        var wasInTriggerZone: Bool = false
        var hasRecordedInitialPosition: Bool = false
        var initialMinY: CGFloat = 0
    }
    
    func getState(for id: String) -> ScrollState {
        return scrollStates[id] ?? ScrollState()
    }
    
    func setState(_ state: ScrollState, for id: String) {
        scrollStates[id] = state
    }
    
    func reset() {
        scrollStates.removeAll()
    }
}
