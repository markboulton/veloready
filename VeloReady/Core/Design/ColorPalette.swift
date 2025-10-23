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
    static let appBackground = ColorScale.appBackground
    
    // MARK: - Label Colors
    
    static let labelPrimary = ColorScale.labelPrimary
    static let labelSecondary = ColorScale.labelSecondary
    static let labelTertiary = ColorScale.labelTertiary
    
    // MARK: - AI Feature Gradients
    
    /// Gradient colors for AI-powered features (Daily Brief, Ride Summary)
    /// Order: Pink → Purple → Blue → Cyan
    static let aiGradientColors: [Color] = [
        pink,
        purple,
        blue,
        cyan
    ]
    
    /// Starting color for AI feature icons (solid fill)
    static let aiIconColor = pink
    
    /// Gradient angle for AI features (30 degrees)
    static let aiGradientAngle: (start: UnitPoint, end: UnitPoint) = (
        start: UnitPoint(x: 0, y: 0),
        end: UnitPoint(x: 1, y: 0.577) // tan(30°) ≈ 0.577
    )
    
    // MARK: - Refined Metric Colors
    
    /// Recovery scale colors (use for recovery score visualization)
    static let recoveryPoor = ColorScale.recoveryPoor
    static let recoveryLow = ColorScale.recoveryLow
    static let recoveryMedium = ColorScale.recoveryMedium
    static let recoveryGood = ColorScale.recoveryGood
    static let recoveryExcellent = ColorScale.recoveryExcellent
    
    /// Metric signature colors (one color per metric type)
    static let strainMetric = ColorScale.strainColor
    static let sleepMetric = ColorScale.sleepColor
    static let hrvMetric = ColorScale.hrvColor
    static let heartRateMetric = ColorScale.heartRateColor
    static let powerMetric = ColorScale.powerColor
    static let tssMetric = ColorScale.tssColor
    static let respiratoryMetric = ColorScale.respiratoryColor
    
    /// Chart styling
    static let chartGridLine = ColorScale.chartGrid
    static let chartAxisLabel = ColorScale.chartAxis
    static let textPrimarySoft = ColorScale.textSoftWhite
    
    /// Helper function for recovery gradient
    static func recoveryColor(for score: Double) -> Color {
        switch score {
        case 0..<30: return recoveryPoor
        case 30..<50: return recoveryLow
        case 50..<70: return recoveryMedium
        case 70..<85: return recoveryGood
        default: return recoveryExcellent
        }
    }
}
