import Foundation
import SwiftUI

/// Standard component sizes for consistent UI
/// Part of the VeloReady design system
enum ComponentSizes {
    
    // MARK: - Ring Components
    
    /// Ring width for large recovery/score rings (e.g., RecoveryRingView)
    static let ringWidthLarge: CGFloat = 12
    
    /// Ring width for compact rings (e.g., CompactRingView)
    static let ringWidthSmall: CGFloat = 5
    
    /// Diameter for large recovery/score rings
    static let ringDiameterLarge: CGFloat = 160
    
    /// Diameter for compact rings
    static let ringDiameterSmall: CGFloat = 100
    
    /// Diameter for empty state rings
    static let ringDiameterEmpty: CGFloat = 100
    
    // MARK: - Card Heights
    
    /// Standard skeleton card height
    static let skeletonCardHeight: CGFloat = 120
    
    // MARK: - Icon Sizes
    
    /// Small icon size (for badges, indicators)
    static let iconSmall: CGFloat = 16
    
    /// Medium icon size (for cards)
    static let iconMedium: CGFloat = 24
    
    /// Large icon size (for headers, empty states)
    static let iconLarge: CGFloat = 40
    
    // MARK: - Corner Radius
    
    /// Small corner radius for pills and badges
    static let cornerRadiusSmall: CGFloat = 8
    
    /// Medium corner radius for cards
    static let cornerRadiusMedium: CGFloat = 12
    
    /// Large corner radius for sheets
    static let cornerRadiusLarge: CGFloat = 16
}
