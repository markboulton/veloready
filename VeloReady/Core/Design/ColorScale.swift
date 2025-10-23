import SwiftUI

/// Foundational color scale - primitive color values
/// Now with adaptive light/dark mode support
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
    
    static let backgroundPrimary = Color(.systemBackground)             /// Primary background (white/black)
    static let backgroundSecondary = Color(.secondarySystemBackground)  /// Secondary background (light grey/dark grey)
    static let backgroundTertiary = Color(.tertiarySystemBackground)    /// Tertiary background (white/elevated dark grey)
    
    /// List item background (matches Settings section items: white in light mode, grey in dark mode)
    static var backgroundListItem: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.secondarySystemBackground  // Grey in dark mode
                : UIColor.white  // White in light mode
        })
    }
    
    /// Custom app background: light grey in light mode, BLACK in dark mode
    static var appBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.systemBackground  // Black in dark mode
                : UIColor.secondarySystemBackground  // Light grey in light mode
        })
    }
    
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
    
    // MARK: - Status Colors (Adaptive for Light/Dark Mode)
    // These are the base tokens used throughout the app for status/bands
    
    static let greenAccent  = Color.adaptive(lightHex: "00A378", darkHex: "00D9A3") /// Light: darker mint, Dark: #00D9A3 mint
    static let yellowAccent = Color.adaptive(lightHex: "C5A030", darkHex: "EDCB57") /// Light: darker gold, Dark: #EDCB57 warm gold
    static let amberAccent  = Color.adaptive(lightHex: "CC9500", darkHex: "FFB800") /// Light: darker amber, Dark: #FFB800 warm amber
    static let redAccent    = Color.adaptive(lightHex: "D63939", darkHex: "FF4444") /// Light: darker coral, Dark: #FF4444 coral red
    
    // MARK: - Refined Metric Colors (Adaptive)
    
    /// Recovery scale - adaptive gradient (coral → amber → gold → mint)
    static let recoveryPoor      = Color.adaptive(lightHex: "D63939", darkHex: "FF4444") /// Light: darker coral, Dark: #FF4444
    static let recoveryLow       = Color.adaptive(lightHex: "D97038", darkHex: "FF8844") /// Light: darker orange, Dark: #FF8844
    static let recoveryMedium    = Color.adaptive(lightHex: "CC9500", darkHex: "FFB800") /// Light: darker amber, Dark: #FFB800
    static let recoveryGood      = Color.adaptive(lightHex: "C5A030", darkHex: "EDCB57") /// Light: darker gold, Dark: #EDCB57
    static let recoveryExcellent = Color.adaptive(lightHex: "00A378", darkHex: "00D9A3") /// Light: darker mint, Dark: #00D9A3
    
    /// Metric signature colors (adaptive per metric type)
    static let strainColor       = Color.adaptive(lightHex: "4B7FE5", darkHex: "6B9FFF") /// Light: darker blue, Dark: #6B9FFF soft blue
    static let sleepColor        = Color.adaptive(lightHex: "4B7FE5", darkHex: "6B9FFF") /// Light: darker blue, Dark: #6B9FFF soft blue
    static let hrvColor          = Color.adaptive(lightHex: "00A378", darkHex: "00D9A3") /// Light: darker mint, Dark: #00D9A3 mint
    static let heartRateColor    = Color.adaptive(lightHex: "E85555", darkHex: "FF6B6B") /// Light: darker coral, Dark: #FF6B6B coral
    static let powerColor        = Color.adaptive(lightHex: "3D7FE5", darkHex: "4D9FFF") /// Light: darker electric blue, Dark: #4D9FFF
    static let tssColor          = Color.adaptive(lightHex: "CC9500", darkHex: "FFB800") /// Light: darker amber, Dark: #FFB800 amber
    static let respiratoryColor  = Color.adaptive(lightHex: "7B5FE5", darkHex: "9B7FFF") /// Light: darker purple, Dark: #9B7FFF soft purple
    
    /// Chart styling colors (adaptive)
    static let chartGrid         = Color.adaptive(
        light: Color.black.opacity(0.08),
        dark: Color.white.opacity(0.06)
    ) /// Light: subtle black lines, Dark: subtle white lines
    static let chartAxis         = Color.adaptive(lightHex: "999999", darkHex: "6B6B6B") /// Light: medium gray, Dark: #6B6B6B
    static let textSoftWhite     = Color.adaptive(lightHex: "333333", darkHex: "E8E8E8") /// Light: dark gray, Dark: #E8E8E8 soft white
    
    // MARK: - Sleep Stage Colors (Adaptive Purple Tones)
    
    /// Sleep stage colors - purple gradient from dark (deep) to light (awake)
    static let sleepDeep         = Color.adaptive(lightHex: "4B1F7F", darkHex: "331966") /// Light: medium purple, Dark: #331966 dark purple
    static let sleepREM          = Color.adaptive(lightHex: "6B4F9F", darkHex: "4F6BCC") /// Light: medium purple-blue, Dark: #4F6BCC turquoise
    static let sleepCore         = Color.adaptive(lightHex: "8B7FBF", darkHex: "6680E6") /// Light: light purple, Dark: #6680E6 light blue
    static let sleepAwake        = Color.adaptive(lightHex: "C9B8E8", darkHex: "FFCC66") /// Light: very light lilac, Dark: #FFCC66 yellow/gold
    static let sleepInBed        = Color.adaptive(lightHex: "E8E8E8", darkHex: "3A3A3A") /// Light: very light gray, Dark: #3A3A3A dark gray
}
