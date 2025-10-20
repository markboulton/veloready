import SwiftUI

/// Icon type - either SF Symbol or custom asset
enum IconType {
    case system(String)  // SF Symbol
    case custom(String)  // Asset catalog name
    
    /// SwiftUI Image for this icon
    var image: Image {
        switch self {
        case .system(let name):
            return Image(systemName: name)
        case .custom(let name):
            return Image(name)
        }
    }
    
    /// String name (for backwards compatibility)
    var name: String {
        switch self {
        case .system(let name), .custom(let name):
            return name
        }
    }
}

/// Centralized icon system using SF Symbols and custom icons
/// All SF Symbols use outlined style for consistency across the app
enum Icons {
    
    // MARK: - Activity Types
    
    enum Activity {
        // Standard SF Symbols
        static let cycling = "bicycle"
        static let running = "figure.run"
        static let runningCircle = "figure.run.circle"
        static let walking = "figure.walk"
        static let hiking = "figure.hiking"
        static let swimming = "figure.pool.swim"
        static let strength = "dumbbell"
        static let yoga = "figure.mind.and.body"
        static let hiit = "flame"
        static let other = "figure.mixed.cardio"
        
        // Custom branded icons (if needed)
        // static let cyclingCustom = IconType.custom("custom-cycling")
        // static let strengthCustom = IconType.custom("custom-strength")
    }
    
    // MARK: - Health & Wellness
    
    enum Health {
        static let heart = "heart"
        static let heartFill = "heart.fill"
        static let heartCircle = "heart.circle.fill"
        static let heartCircleOutline = "heart.circle"
        static let heartRate = "waveform.path.ecg"
        static let hrv = "heart.circle"
        static let sleep = "moon"
        static let sleepFill = "moon.fill"
        static let sleepZzz = "moon.zzz"
        static let sleepZzzFill = "moon.zzz.fill"
        static let respiratory = "lungs"
        static let steps = "figure.walk"
        static let calories = "flame"
        static let caloriesFill = "flame.fill"
        static let recovery = "leaf"
        static let leafFill = "leaf.fill"
        static let bed = "bed.double.fill"
        static let moon = "moon.stars.fill"
        static let bolt = "bolt.fill"
        static let boltHeart = "bolt.heart.fill"
        static let boltSlash = "bolt.slash.fill"
        static let drop = "drop.fill"
    }
    
    // MARK: - Status & Feedback
    
    enum Status {
        static let success = "checkmark.circle"
        static let successFill = "checkmark.circle.fill"
        static let error = "xmark.circle"
        static let errorFill = "xmark.circle.fill"
        static let warning = "exclamationmark.triangle"
        static let warningFill = "exclamationmark.triangle.fill"
        static let info = "info.circle"
        static let infoFill = "info.circle.fill"
        static let alert = "exclamationmark.circle"
        static let checkmark = "checkmark"
    }
    
    // MARK: - Data Sources
    
    enum DataSource {
        static let intervalsICU = "chart.line.uptrend.xyaxis"
        static let strava = "figure.outdoor.cycle"
        static let garmin = "applewatch"
        static let appleHealth = "heart"
    }
    
    // MARK: - Navigation & Actions
    
    enum Navigation {
        static let close = "xmark"
        static let back = "chevron.left"
        static let forward = "chevron.right"
        static let expand = "chevron.down"
        static let collapse = "chevron.up"
        static let menu = "line.3.horizontal"
        static let settings = "gearshape"
        static let settingsFill = "gearshape.fill"
    }
    
    // MARK: - Training & Performance
    
    enum Training {
        static let power = "bolt"
        static let speed = "speedometer"
        static let distance = "location"
        static let duration = "clock"
        static let elevation = "mountain.2"
        static let cadence = "metronome"
        static let tss = "gauge.medium"
        static let intensity = "chart.bar"
    }
    
    // MARK: - User & Profile
    
    enum User {
        static let profile = "person.circle"
        static let athlete = "figure.strengthtraining.traditional"
        static let preferences = "slider.horizontal.3"
    }
    
    // MARK: - Features
    
    enum Feature {
        static let ai = "sparkles"
        static let pro = "crown"
        static let trends = "chart.xyaxis.line"
        static let calendar = "calendar"
        static let analytics = "chart.bar.doc.horizontal"
    }
    
    // MARK: - Visibility
    
    enum Visibility {
        static let show = "eye"
        static let hide = "eye.slash"
    }
    
    // MARK: - Selection
    
    enum Selection {
        static let selected = "checkmark.circle"
        static let unselected = "circle"
        static let radio = "circle"
    }
    
    // MARK: - Document & Data
    
    enum Document {
        static let file = "doc.text"
        static let download = "arrow.down.circle"
        static let upload = "arrow.up.circle"
        static let refresh = "arrow.clockwise"
        static let copy = "doc.on.doc"
        static let trash = "trash"
        static let key = "key.fill"
    }
    
    // MARK: - System & Debug
    
    enum System {
        static let bug = "ladybug.fill"
        static let database = "cylinder"
        static let storage = "externaldrive"
        static let storageBadge = "externaldrive.badge.xmark"
        static let chart = "chart.bar.fill"
        static let chartDoc = "chart.bar.doc.horizontal.fill"
        static let chartDocHorizontal = "chart.bar.doc.horizontal"
        static let chartBarXAxis = "chart.bar.xaxis"
        static let person = "person.crop.circle"
        static let envelope = "envelope.fill"
        static let map = "map"
        static let location = "location.fill"
        static let clock = "clock.fill"
        static let star = "star.fill"
        static let pencil = "pencil"
        static let plus = "plus"
        static let minus = "minus"
        static let chevronRight = "chevron.right"
        static let chevronDown = "chevron.down"
        static let chevronUp = "chevron.up"
        static let gauge = "gauge.medium"
        static let gaugeBadge = "gauge.with.dots.needle.67percent"
        static let calendar = "calendar"
        static let brain = "brain.head.profile"
        static let sparkles = "sparkles"
        static let waveform = "waveform.path.ecg"
        static let network = "network"
        static let shield = "checkmark.shield"
        static let hammer = "hammer"
        static let hammerFill = "hammer.fill"
        static let magnifyingGlass = "doc.text.magnifyingglass"
        static let keyHorizontal = "key.horizontal"
        static let heartTextSquare = "heart.text.square.fill"
        static let heartTextSquareOutline = "heart.text.square"
        static let grid2x2 = "square.grid.2x2"
        static let circleArrowPath = "arrow.triangle.2.circlepath"
        static let counterclockwise = "arrow.counterclockwise"
        static let arrowRightCircle = "arrow.right.circle.fill"
        static let target = "target"
        static let percent = "percent"
        static let lightbulb = "lightbulb.fill"
        static let bell = "bell.fill"
        static let camera = "camera.fill"
        static let docText = "doc.text.fill"
        static let eye = "eye.fill"
        static let circle = "circle.fill"
        static let lock = "lock.fill"
        static let lockShield = "lock.shield.fill"
        static let link = "link"
        static let linkCircle = "link.circle"
        static let linkCircleFill = "link.circle.fill"
        static let trophy = "trophy.fill"
        static let icloud = "icloud.fill"
        static let questionCircleFill = "questionmark.circle.fill"
        static let menuDecrease = "line.3.horizontal.decrease.circle"
    }
    
    // MARK: - Arrows & Directions
    
    enum Arrow {
        static let up = "arrow.up"
        static let down = "arrow.down"
        static let upRight = "arrow.up.right"
        static let downRight = "arrow.down.right"
        static let clockwise = "arrow.clockwise"
        static let counterclockwise = "arrow.counterclockwise"
        static let rectanglePortrait = "rectangle.portrait.and.arrow.right"
        static let rightCircleFill = "arrow.right.circle.fill"
        static let rightCircle = "arrow.right.circle"
        static let triangleCirclePath = "arrow.triangle.2.circlepath"
    }
    
    // MARK: - Custom Icons
    // Add your custom branded/bespoke icons here
    
    enum Custom {
        // Example: Brand-specific icons from Assets.xcassets
        // static let brandedLogo = IconType.custom("veloready-logo")
        // static let customCycling = IconType.custom("custom-cycling-icon")
        // static let customHeart = IconType.custom("custom-heart-icon")
        
        // Usage:
        // Icons.Custom.brandedLogo.image
        //   .resizable()
        //   .frame(width: 24, height: 24)
    }
}
