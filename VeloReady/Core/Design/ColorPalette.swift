import SwiftUI

/// Simplified color palette - semantic color assignments
/// Built on top of ColorScale
enum ColorPalette {
    
    // MARK: - Status Colors
    
    static let success = ColorScale.greenAccent
    static let warning = ColorScale.amberAccent
    static let error = ColorScale.redAccent
    
    // MARK: - Team / Route Colors
    
    static let mint = ColorScale.mintAccent
    static let peach = ColorScale.peachAccent
    static let blue = ColorScale.blueAccent
    static let purple = ColorScale.purpleAccent
    static let pink = ColorScale.pinkAccent
    static let cyan = ColorScale.cyanAccent
    static let yellow = ColorScale.yellowAccent
    
    // MARK: - Neutral Colors
    
    static let neutral100 = ColorScale.gray100
    static let neutral200 = ColorScale.gray200
    static let neutral300 = ColorScale.gray300
    static let neutral400 = ColorScale.gray400
    static let neutral500 = ColorScale.gray500
    static let neutral600 = ColorScale.gray600
    static let neutral900 = ColorScale.gray900
    
    // MARK: - Background Colors
    
    static let backgroundPrimary = ColorScale.backgroundPrimary
    static let backgroundSecondary = ColorScale.backgroundSecondary
    static let backgroundTertiary = ColorScale.backgroundTertiary
    
    // MARK: - Label Colors
    
    static let labelPrimary = ColorScale.labelPrimary
    static let labelSecondary = ColorScale.labelSecondary
    static let labelTertiary = ColorScale.labelTertiary
}
