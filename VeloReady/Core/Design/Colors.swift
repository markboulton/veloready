import SwiftUI

/// Semantic color tokens for the app
/// Built on top of ColorPalette for consistent theming
extension Color {
    
    // MARK: - Recovery Colors
    
    struct recovery {
        static let green = ColorPalette.success  /// Green recovery band
        static let amber = ColorPalette.warning  /// Amber recovery band
        static let red = ColorPalette.error  /// Red recovery band
        static let sectionBackground = ColorPalette.neutral100  /// Section background
    }
    
    // MARK: - Sleep Colors
    
    struct sleep {
        static let excellent = ColorPalette.success  /// Excellent sleep
        static let good = ColorPalette.blue  /// Good sleep
        static let fair = ColorPalette.warning  /// Fair sleep
        static let poor = ColorPalette.error  /// Poor sleep
        static let sectionBackground = ColorPalette.neutral100  /// Section background
    }
    
    // MARK: - Strain Colors
    
    struct strain {
        static let low = ColorPalette.success  /// Low strain
        static let moderate = ColorPalette.blue  /// Moderate strain
        static let high = ColorPalette.warning  /// High strain
        static let extreme = ColorPalette.error  /// Extreme strain
        static let sectionBackground = ColorPalette.neutral100  /// Section background
    }
    
    // MARK: - Status Colors
    
    struct status {
        static let authenticated = ColorPalette.success  /// Authenticated/connected
        static let notAuthenticated = ColorPalette.error  /// Not authenticated/disconnected
        static let warning = ColorPalette.warning  /// Warning state
        static let info = ColorPalette.blue  /// Info state
    }
    
    // MARK: - Button Colors
    
    struct button {
        static let primary = ColorPalette.blue  /// Primary button
        static let secondary = ColorPalette.neutral600  /// Secondary button
        static let success = ColorPalette.success  /// Success button
        static let warning = ColorPalette.warning  /// Warning button
        static let danger = ColorPalette.error  /// Danger button
        static let destructive = ColorPalette.error  /// Destructive button
    }
    
    // MARK: - Background Colors
    
    struct background {
        static let primary = ColorPalette.backgroundPrimary  /// Primary background (WHITE in light, BLACK in dark)
        static let secondary = ColorPalette.backgroundSecondary  /// Secondary background (light grey in light, dark grey in dark)
        static let tertiary = ColorPalette.backgroundTertiary  /// Tertiary background (white in light, elevated dark grey in dark)
        static let card = ColorPalette.backgroundTertiary  /// Card background (WHITE in light, ELEVATED DARK GREY in dark - matches Settings)
        static let elevated = ColorPalette.backgroundTertiary  /// Elevated background (matches Settings cards)
        static let app = ColorPalette.appBackground  /// App background (light grey in light, BLACK in dark)
    }
    
    // MARK: - Text Colors
    
    struct text {
        static let primary = ColorPalette.labelPrimary  /// Primary text
        static let secondary = ColorPalette.labelSecondary  /// Secondary text
        static let tertiary = ColorPalette.labelTertiary  /// Tertiary text
        static let success = ColorPalette.success  /// Success text
        static let warning = ColorPalette.warning  /// Warning text
        static let error = ColorPalette.error  /// Error text
        static let info = ColorPalette.blue  /// Info text
    }
    
    // MARK: - Health Data Colors
    
    struct health {
        static let sleep = ColorPalette.purple  /// Sleep tracking
        static let hrv = ColorPalette.success  /// HRV data (green)
        static let heartRate = ColorPalette.pink  /// Heart rate
        static let respiratory = ColorPalette.cyan  /// Respiratory rate
        static let activity = ColorPalette.peach  /// Activity data
    }
    
    // MARK: - Development Colors
    
    struct development {
        static let mockDataIndicator = ColorPalette.warning  /// Mock data indicator
        static let debugBackground = ColorPalette.neutral100  /// Debug background
        static let debugBorder = ColorPalette.neutral200  /// Debug border
    }
    
    // MARK: - Chart Colors
    
    struct chart {
        /// Primary chart color
        static let primary = ColorPalette.blue
        
        /// Secondary chart color
        static let secondary = ColorPalette.peach
        
        /// Tertiary chart color
        static let tertiary = ColorPalette.success
        
        /// Quaternary chart color
        static let quaternary = ColorPalette.purple
        
        /// Ring green
        static let ringGreen = ColorPalette.success
        
        /// Ring amber
        static let ringAmber = ColorPalette.warning
        
        /// Ring red
        static let ringRed = ColorPalette.error
    }
    
    // MARK: - Activity Type Colors
    
    struct activityType {
        /// Cycling/Ride
        static let cycling = ColorPalette.blue
        
        /// Running
        static let running = ColorPalette.mint
        
        /// Walking
        static let walking = ColorPalette.neutral500
        
        /// Swimming
        static let swimming = ColorPalette.cyan
        
        /// Strength
        static let strength = ColorPalette.pink
        
        /// Yoga
        static let yoga = ColorPalette.purple
        
        /// HIIT
        static let hiit = ColorPalette.error
        
        /// Hiking
        static let hiking = ColorPalette.yellow
        
        /// Default
        static let other = ColorPalette.neutral400
    }
    
    // MARK: - Workout Colors
    
    struct workout {
        /// Duration
        static let duration = ColorPalette.blue
        
        /// Distance
        static let distance = ColorPalette.mint
        
        /// Elevation
        static let elevation = ColorPalette.neutral600
        
        /// Power
        static let power = ColorPalette.purple
        
        /// Heart rate
        static let heartRate = ColorPalette.pink
        
        /// Speed
        static let speed = ColorPalette.cyan
        
        /// Cadence
        static let cadence = ColorPalette.blue
        
        /// TSS
        static let tss = ColorPalette.purple
        
        /// Intensity factor
        static let intensityFactor = ColorPalette.warning
        
        /// Calories
        static let calories = ColorPalette.error
        
        /// Device
        static let device = ColorPalette.neutral600
        
        /// Route
        static let route = ColorPalette.blue
        
        /// Start marker
        static let startMarker = ColorPalette.success
        
        /// End marker
        static let endMarker = ColorPalette.error
        
        /// Map background
        static let mapBackground = ColorPalette.neutral100
    }
    
    // MARK: - Semantic Colors
    
    struct semantic {
        /// Success state
        static let success = ColorPalette.success
        
        /// Connected state
        static let connected = ColorPalette.success
        
        /// Active state
        static let active = ColorPalette.success
        
        /// Healthy state
        static let healthy = ColorPalette.success
        
        /// Warning state
        static let warning = ColorPalette.warning
        
        /// Caution state
        static let caution = ColorPalette.warning
        
        /// Moderate state
        static let moderate = ColorPalette.warning
        
        /// Error state
        static let error = ColorPalette.error
        
        /// Disconnected state
        static let disconnected = ColorPalette.error
        
        /// Inactive state
        static let inactive = ColorPalette.error
        
        /// Unhealthy state
        static let unhealthy = ColorPalette.error
        
        /// Neutral state
        static let neutral = ColorPalette.neutral600
        
        /// Unknown state
        static let unknown = ColorPalette.neutral300
        
        /// Disabled state
        static let disabled = ColorPalette.neutral300
    }
    
    // MARK: - Interactive Colors
    
    struct interactive {
        /// Pressed state
        static let pressed = ColorPalette.neutral500
        
        /// Hover state
        static let hover = ColorPalette.neutral100
        
        /// Selected state
        static let selected = ColorPalette.blue
        
        /// Unselected state
        static let unselected = ColorPalette.neutral200
    }
    
    // MARK: - Gradient Colors
    
    struct gradient {
        /// Pro badge gradient (blue to purple)
        static let pro = LinearGradient(
            colors: [ColorPalette.blue, ColorPalette.purple],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        /// Pro feature icon gradient (peach to pink)
        static let proIcon = LinearGradient(
            colors: [ColorPalette.peach, ColorPalette.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Success gradient (green to cyan)
        static let success = LinearGradient(
            colors: [ColorPalette.success, ColorPalette.cyan],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
