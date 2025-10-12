import Foundation

/// Connection state for Strava OAuth flow
enum StravaConnectionState: Equatable {
    case disconnected
    case connecting(state: String)
    case pending(status: String)
    case connected(athleteId: String?)
    case error(message: String)
    
    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
    
    var isLoading: Bool {
        switch self {
        case .connecting, .pending:
            return true
        default:
            return false
        }
    }
}
