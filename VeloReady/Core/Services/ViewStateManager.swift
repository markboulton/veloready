import Foundation

/// Singleton to track view state across TabView navigation
/// TabView recreates views when switching tabs, so @State doesn't persist
class ViewStateManager {
    static let shared = ViewStateManager()
    
    private init() {}
    
    /// Tracks if Today view has completed initial data load in this app session
    var hasCompletedTodayInitialLoad = false
    
    /// Reset on app termination (automatically happens since it's not persisted)
    func reset() {
        hasCompletedTodayInitialLoad = false
    }
}
