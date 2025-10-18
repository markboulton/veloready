import SwiftUI

/// Foundational color scale - primitive color values
/// Simplified system with system grays and custom accent colors
enum ColorScale {
    
    // MARK: - System Grays (iOS Native)
    
    static let gray100 = Color(.systemGray6)    /// Lightest gray
    static let gray200 = Color(.systemGray5)    /// Very light gray
    static let gray300 = Color(.systemGray4)    /// Light gray (dividers)
    static let gray400 = Color(.systemGray3)    /// Medium light gray
    static let gray500 = Color(.systemGray2)    /// Medium gray
    static let gray600 = Color(.systemGray)     /// Dark gray
    static let gray900 = Color(.label)          /// Darkest gray
    
    // MARK: - Divider Colors (Adaptive)
    
    static let divider = Color(.separator)      /// Standard divider (lighter, adaptive)
    
    // MARK: - Background Colors (Adaptive)
    
    static let backgroundPrimary = Color(.systemBackground)             /// Primary background
    static let backgroundSecondary = Color(.secondarySystemBackground)  /// Secondary background
    static let backgroundTertiary = Color(.tertiarySystemBackground)    /// Tertiary background
    
    // MARK: - Label Colors (Adaptive)
    
    static let labelPrimary = Color.primary         /// Primary label
    static let labelSecondary = Color(.secondaryLabel)     /// Secondary label (better contrast)
    static let labelTertiary = Color(.tertiaryLabel)    /// Tertiary label
    
    // MARK: - Black & White
    
    static let black = Color.black
    static let white = Color.white
    
    // MARK: - Team / Route Accents
    
    static let mintAccent   = Color(.sRGB, red: 0.663, green: 0.984, blue: 0.780, opacity: 1.0) /// #A9FBC7 
    static let peachAccent  = Color(.sRGB, red: 0.961, green: 0.800, blue: 0.533, opacity: 1.0) /// #F5CC88 
    static let blueAccent   = Color(.sRGB, red: 0.000, green: 0.580, blue: 1.000, opacity: 1.0) /// #0094ff 
    static let purpleAccent = Color(.sRGB, red: 0.765, green: 0.302, blue: 1.000, opacity: 1.0) /// #c34dff 
    static let pinkAccent   = Color(.sRGB, red: 0.980, green: 0.318, blue: 0.408, opacity: 1.0) /// #fa5168 
    static let cyanAccent   = Color(.sRGB, red: 0.275, green: 0.808, blue: 0.745, opacity: 1.0) /// #46cebe 
    
    // MARK: - Status Colors (Green → Yellow → Amber → Red)
    
    static let greenAccent  = Color(.sRGB, red: 0.251, green: 0.886, blue: 0.443, opacity: 1.0) /// #40E271 - Excellent
    static let yellowAccent = Color(.sRGB, red: 0.961, green: 0.831, blue: 0.278, opacity: 1.0) /// #F5D447 - Good (was duplicate)
    static let amberAccent  = Color(.sRGB, red: 0.988, green: 0.612, blue: 0.251, opacity: 1.0) /// #FC9C40 - Fair (orange)
    static let redAccent    = Color(.sRGB, red: 0.980, green: 0.318, blue: 0.408, opacity: 1.0) /// #FA5168 - Poor
    
    // MARK: - Refined Metric Colors (Muted, Sophisticated)
    
    /// Recovery scale - muted gradient (coral → amber → mint)
    static let recoveryPoor      = Color(.sRGB, red: 1.000, green: 0.267, blue: 0.267, opacity: 1.0) /// #FF4444
    static let recoveryLow       = Color(.sRGB, red: 1.000, green: 0.533, blue: 0.267, opacity: 1.0) /// #FF8844
    static let recoveryMedium    = Color(.sRGB, red: 1.000, green: 0.722, blue: 0.000, opacity: 1.0) /// #FFB800
    static let recoveryGood      = Color(.sRGB, red: 0.722, green: 0.851, blue: 0.275, opacity: 1.0) /// #B8D946
    static let recoveryExcellent = Color(.sRGB, red: 0.000, green: 0.851, blue: 0.639, opacity: 1.0) /// #00D9A3
    
    /// Metric signature colors (one per metric type)
    static let strainColor       = Color(.sRGB, red: 0.420, green: 0.624, blue: 1.000, opacity: 1.0) /// #6B9FFF - Soft blue
    static let sleepColor        = Color(.sRGB, red: 0.420, green: 0.624, blue: 1.000, opacity: 1.0) /// #6B9FFF - Soft blue
    static let hrvColor          = Color(.sRGB, red: 0.000, green: 0.851, blue: 0.639, opacity: 1.0) /// #00D9A3 - Mint
    static let heartRateColor    = Color(.sRGB, red: 1.000, green: 0.420, blue: 0.420, opacity: 1.0) /// #FF6B6B - Coral
    static let powerColor        = Color(.sRGB, red: 0.302, green: 0.624, blue: 1.000, opacity: 1.0) /// #4D9FFF - Electric blue
    static let tssColor          = Color(.sRGB, red: 1.000, green: 0.722, blue: 0.000, opacity: 1.0) /// #FFB800 - Amber
    static let respiratoryColor  = Color(.sRGB, red: 0.608, green: 0.498, blue: 1.000, opacity: 1.0) /// #9B7FFF - Soft purple
    
    /// Chart styling colors
    static let chartGrid         = Color.white.opacity(0.06)  /// Very subtle grid lines
    static let chartAxis         = Color(.sRGB, red: 0.420, green: 0.420, blue: 0.420, opacity: 1.0) /// #6B6B6B
    static let textSoftWhite     = Color(.sRGB, red: 0.910, green: 0.910, blue: 0.910, opacity: 1.0) /// #E8E8E8
}
