import SwiftUI

/// Foundational type scale using t-shirt sizing
/// Base layer for all typography in the app
enum TypeScale {
    
    // MARK: - Font Sizes (T-Shirt Sizing)
    static let xxl: CGFloat = 48  /// Extra extra large (48pt)
    static let xl: CGFloat = 34  /// Extra large (34pt)
    static let lg: CGFloat = 24  /// Large (24pt)
    static let mlg: CGFloat = 22  /// Medium large (22pt)
    static let md: CGFloat = 17  /// Medium (17pt)
    static let sm: CGFloat = 15  /// Small (15pt)
    static let xs: CGFloat = 13  /// Extra small (13pt)
    static let xxs: CGFloat = 11  /// Extra extra small (11pt)
    static let tiny: CGFloat = 10  /// Tiny (10pt)
    
    // MARK: - Font Weights
    
    enum Weight {
        case regular
        case medium
        case semibold
        case bold
        
        var value: Font.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            }
        }
    }
    
    // MARK: - Font Design
    
    enum Design {
        case `default`
        case rounded
        case serif
        case monospaced
        
        var value: Font.Design {
            switch self {
            case .default: return .default
            case .rounded: return .rounded
            case .serif: return .serif
            case .monospaced: return .monospaced
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Create a font with the specified size, weight, and design
    static func font(
        size: CGFloat,
        weight: Weight = .regular,
        design: Design = .default
    ) -> Font {
        return .system(size: size, weight: weight.value, design: design.value)
    }
}
