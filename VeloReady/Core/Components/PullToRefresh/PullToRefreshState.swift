import SwiftUI

/// Pull-to-refresh state machine
enum PullToRefreshState: Equatable {
    case idle
    case pulling(progress: Double) // 0.0 to 1.0
    case armed // At/over threshold, ready to trigger
    case refreshing
    case completed
    
    var isRefreshing: Bool {
        if case .refreshing = self { return true }
        return false
    }
    
    var isPulling: Bool {
        switch self {
        case .pulling, .armed:
            return true
        default:
            return false
        }
    }
}

/// Configuration for pull-to-refresh behavior
struct PullToRefreshConfig {
    /// Distance to pull before triggering refresh (default ~90pts)
    let triggerThreshold: CGFloat = 90
    
    /// Maximum visual stretch with resistance (default ~150pts)
    let maxStretch: CGFloat = 150
    
    /// Point where resistance starts increasing
    let resistanceStart: CGFloat = 60
    
    /// Overshoot distance on successful trigger
    let overshootDistance: CGFloat = 12
    
    /// Spring animation for snap-back
    let snapBackSpring = Animation.spring(response: 0.35, dampingFraction: 0.75)
    
    /// Spring animation for overshoot
    let overshootSpring = Animation.spring(response: 0.25, dampingFraction: 0.6)
    
    /// Spring animation for completion
    let completionSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    /// Calculate elastic offset from raw pull distance
    func elasticOffset(for pullDistance: CGFloat) -> CGFloat {
        guard pullDistance > 0 else { return 0 }
        
        if pullDistance <= resistanceStart {
            // Linear tracking for initial pull
            return pullDistance
        } else {
            // Apply increasing resistance beyond threshold
            let excess = pullDistance - resistanceStart
            let maxExcess = maxStretch - resistanceStart
            let ratio = excess / maxExcess
            
            // Ease-out curve for resistance
            let resistance = 1 - pow(ratio, 2)
            let elasticExcess = excess * resistance
            
            return resistanceStart + elasticExcess
        }
    }
    
    /// Calculate progress (0.0 to 1.0) based on pull distance
    func progress(for pullDistance: CGFloat) -> Double {
        let offset = elasticOffset(for: pullDistance)
        return min(1.0, Double(offset / triggerThreshold))
    }
}
