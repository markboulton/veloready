import SwiftUI

/// Icon test view for reviewing all SF Symbols and preparing for custom icons
/// Shows SF Symbol on left, name in middle, and placeholder for custom icon on right
struct IconTestView: View {
    var body: some View {
        List {
            // Activity Icons
            IconSection(
                title: "Activity",
                icons: [
                    IconItem(name: "cycling", sfSymbol: Icons.Activity.cycling, enumPath: "Icons.Activity.cycling"),
                    IconItem(name: "running", sfSymbol: Icons.Activity.running, enumPath: "Icons.Activity.running"),
                    IconItem(name: "runningCircle", sfSymbol: Icons.Activity.runningCircle, enumPath: "Icons.Activity.runningCircle"),
                    IconItem(name: "walking", sfSymbol: Icons.Activity.walking, enumPath: "Icons.Activity.walking"),
                    IconItem(name: "hiking", sfSymbol: Icons.Activity.hiking, enumPath: "Icons.Activity.hiking"),
                    IconItem(name: "swimming", sfSymbol: Icons.Activity.swimming, enumPath: "Icons.Activity.swimming"),
                    IconItem(name: "strength", sfSymbol: Icons.Activity.strength, enumPath: "Icons.Activity.strength"),
                    IconItem(name: "yoga", sfSymbol: Icons.Activity.yoga, enumPath: "Icons.Activity.yoga"),
                    IconItem(name: "hiit", sfSymbol: Icons.Activity.hiit, enumPath: "Icons.Activity.hiit"),
                    IconItem(name: "other", sfSymbol: Icons.Activity.other, enumPath: "Icons.Activity.other"),
                ]
            )
            
            // Health & Wellness Icons
            IconSection(
                title: "Health & Wellness",
                icons: [
                    IconItem(name: "heart", sfSymbol: Icons.Health.heart, enumPath: "Icons.Health.heart"),
                    IconItem(name: "heartFill", sfSymbol: Icons.Health.heartFill, enumPath: "Icons.Health.heartFill"),
                    IconItem(name: "heartCircle", sfSymbol: Icons.Health.heartCircle, enumPath: "Icons.Health.heartCircle"),
                    IconItem(name: "heartCircleOutline", sfSymbol: Icons.Health.heartCircleOutline, enumPath: "Icons.Health.heartCircleOutline"),
                    IconItem(name: "heartRate", sfSymbol: Icons.Health.heartRate, enumPath: "Icons.Health.heartRate"),
                    IconItem(name: "hrv", sfSymbol: Icons.Health.hrv, enumPath: "Icons.Health.hrv"),
                    IconItem(name: "sleep", sfSymbol: Icons.Health.sleep, enumPath: "Icons.Health.sleep"),
                    IconItem(name: "sleepFill", sfSymbol: Icons.Health.sleepFill, enumPath: "Icons.Health.sleepFill"),
                    IconItem(name: "sleepZzz", sfSymbol: Icons.Health.sleepZzz, enumPath: "Icons.Health.sleepZzz"),
                    IconItem(name: "sleepZzzFill", sfSymbol: Icons.Health.sleepZzzFill, enumPath: "Icons.Health.sleepZzzFill"),
                    IconItem(name: "respiratory", sfSymbol: Icons.Health.respiratory, enumPath: "Icons.Health.respiratory"),
                    IconItem(name: "steps", sfSymbol: Icons.Health.steps, enumPath: "Icons.Health.steps"),
                    IconItem(name: "calories", sfSymbol: Icons.Health.calories, enumPath: "Icons.Health.calories"),
                    IconItem(name: "caloriesFill", sfSymbol: Icons.Health.caloriesFill, enumPath: "Icons.Health.caloriesFill"),
                    IconItem(name: "recovery", sfSymbol: Icons.Health.recovery, enumPath: "Icons.Health.recovery"),
                    IconItem(name: "leafFill", sfSymbol: Icons.Health.leafFill, enumPath: "Icons.Health.leafFill"),
                    IconItem(name: "bed", sfSymbol: Icons.Health.bed, enumPath: "Icons.Health.bed"),
                    IconItem(name: "moon", sfSymbol: Icons.Health.moon, enumPath: "Icons.Health.moon"),
                    IconItem(name: "bolt", sfSymbol: Icons.Health.bolt, enumPath: "Icons.Health.bolt"),
                    IconItem(name: "boltHeart", sfSymbol: Icons.Health.boltHeart, enumPath: "Icons.Health.boltHeart"),
                    IconItem(name: "boltSlash", sfSymbol: Icons.Health.boltSlash, enumPath: "Icons.Health.boltSlash"),
                    IconItem(name: "drop", sfSymbol: Icons.Health.drop, enumPath: "Icons.Health.drop"),
                ]
            )
            
            // Status & Feedback Icons
            IconSection(
                title: "Status & Feedback",
                icons: [
                    IconItem(name: "success", sfSymbol: Icons.Status.success, enumPath: "Icons.Status.success"),
                    IconItem(name: "successFill", sfSymbol: Icons.Status.successFill, enumPath: "Icons.Status.successFill"),
                    IconItem(name: "error", sfSymbol: Icons.Status.error, enumPath: "Icons.Status.error"),
                    IconItem(name: "errorFill", sfSymbol: Icons.Status.errorFill, enumPath: "Icons.Status.errorFill"),
                    IconItem(name: "warning", sfSymbol: Icons.Status.warning, enumPath: "Icons.Status.warning"),
                    IconItem(name: "warningFill", sfSymbol: Icons.Status.warningFill, enumPath: "Icons.Status.warningFill"),
                    IconItem(name: "info", sfSymbol: Icons.Status.info, enumPath: "Icons.Status.info"),
                    IconItem(name: "infoFill", sfSymbol: Icons.Status.infoFill, enumPath: "Icons.Status.infoFill"),
                    IconItem(name: "alert", sfSymbol: Icons.Status.alert, enumPath: "Icons.Status.alert"),
                    IconItem(name: "checkmark", sfSymbol: Icons.Status.checkmark, enumPath: "Icons.Status.checkmark"),
                ]
            )
            
            // Data Sources Icons
            IconSection(
                title: "Data Sources",
                icons: [
                    IconItem(name: "intervalsICU", sfSymbol: Icons.DataSource.intervalsICU, enumPath: "Icons.DataSource.intervalsICU"),
                    IconItem(name: "strava", sfSymbol: Icons.DataSource.strava, enumPath: "Icons.DataSource.strava"),
                    IconItem(name: "garmin", sfSymbol: Icons.DataSource.garmin, enumPath: "Icons.DataSource.garmin"),
                    IconItem(name: "appleHealth", sfSymbol: Icons.DataSource.appleHealth, enumPath: "Icons.DataSource.appleHealth"),
                ]
            )
            
            // Navigation & Actions Icons
            IconSection(
                title: "Navigation & Actions",
                icons: [
                    IconItem(name: "close", sfSymbol: Icons.Navigation.close, enumPath: "Icons.Navigation.close"),
                    IconItem(name: "back", sfSymbol: Icons.Navigation.back, enumPath: "Icons.Navigation.back"),
                    IconItem(name: "forward", sfSymbol: Icons.Navigation.forward, enumPath: "Icons.Navigation.forward"),
                    IconItem(name: "expand", sfSymbol: Icons.Navigation.expand, enumPath: "Icons.Navigation.expand"),
                    IconItem(name: "collapse", sfSymbol: Icons.Navigation.collapse, enumPath: "Icons.Navigation.collapse"),
                    IconItem(name: "menu", sfSymbol: Icons.Navigation.menu, enumPath: "Icons.Navigation.menu"),
                    IconItem(name: "settings", sfSymbol: Icons.Navigation.settings, enumPath: "Icons.Navigation.settings"),
                    IconItem(name: "settingsFill", sfSymbol: Icons.Navigation.settingsFill, enumPath: "Icons.Navigation.settingsFill"),
                ]
            )
            
            // Training & Performance Icons
            IconSection(
                title: "Training & Performance",
                icons: [
                    IconItem(name: "power", sfSymbol: Icons.Training.power, enumPath: "Icons.Training.power"),
                    IconItem(name: "speed", sfSymbol: Icons.Training.speed, enumPath: "Icons.Training.speed"),
                    IconItem(name: "distance", sfSymbol: Icons.Training.distance, enumPath: "Icons.Training.distance"),
                    IconItem(name: "duration", sfSymbol: Icons.Training.duration, enumPath: "Icons.Training.duration"),
                    IconItem(name: "elevation", sfSymbol: Icons.Training.elevation, enumPath: "Icons.Training.elevation"),
                    IconItem(name: "cadence", sfSymbol: Icons.Training.cadence, enumPath: "Icons.Training.cadence"),
                    IconItem(name: "tss", sfSymbol: Icons.Training.tss, enumPath: "Icons.Training.tss"),
                    IconItem(name: "intensity", sfSymbol: Icons.Training.intensity, enumPath: "Icons.Training.intensity"),
                ]
            )
            
            // User & Profile Icons
            IconSection(
                title: "User & Profile",
                icons: [
                    IconItem(name: "profile", sfSymbol: Icons.User.profile, enumPath: "Icons.User.profile"),
                    IconItem(name: "athlete", sfSymbol: Icons.User.athlete, enumPath: "Icons.User.athlete"),
                    IconItem(name: "preferences", sfSymbol: Icons.User.preferences, enumPath: "Icons.User.preferences"),
                ]
            )
            
            // Features Icons
            IconSection(
                title: "Features",
                icons: [
                    IconItem(name: "ai", sfSymbol: Icons.Feature.ai, enumPath: "Icons.Feature.ai"),
                    IconItem(name: "pro", sfSymbol: Icons.Feature.pro, enumPath: "Icons.Feature.pro"),
                    IconItem(name: "trends", sfSymbol: Icons.Feature.trends, enumPath: "Icons.Feature.trends"),
                    IconItem(name: "calendar", sfSymbol: Icons.Feature.calendar, enumPath: "Icons.Feature.calendar"),
                    IconItem(name: "analytics", sfSymbol: Icons.Feature.analytics, enumPath: "Icons.Feature.analytics"),
                ]
            )
            
            // Visibility Icons
            IconSection(
                title: "Visibility",
                icons: [
                    IconItem(name: "show", sfSymbol: Icons.Visibility.show, enumPath: "Icons.Visibility.show"),
                    IconItem(name: "hide", sfSymbol: Icons.Visibility.hide, enumPath: "Icons.Visibility.hide"),
                ]
            )
            
            // Selection Icons
            IconSection(
                title: "Selection",
                icons: [
                    IconItem(name: "selected", sfSymbol: Icons.Selection.selected, enumPath: "Icons.Selection.selected"),
                    IconItem(name: "unselected", sfSymbol: Icons.Selection.unselected, enumPath: "Icons.Selection.unselected"),
                    IconItem(name: "radio", sfSymbol: Icons.Selection.radio, enumPath: "Icons.Selection.radio"),
                ]
            )
            
            // Document & Data Icons
            IconSection(
                title: "Document & Data",
                icons: [
                    IconItem(name: "file", sfSymbol: Icons.Document.file, enumPath: "Icons.Document.file"),
                    IconItem(name: "download", sfSymbol: Icons.Document.download, enumPath: "Icons.Document.download"),
                    IconItem(name: "upload", sfSymbol: Icons.Document.upload, enumPath: "Icons.Document.upload"),
                    IconItem(name: "refresh", sfSymbol: Icons.Document.refresh, enumPath: "Icons.Document.refresh"),
                    IconItem(name: "copy", sfSymbol: Icons.Document.copy, enumPath: "Icons.Document.copy"),
                    IconItem(name: "trash", sfSymbol: Icons.Document.trash, enumPath: "Icons.Document.trash"),
                    IconItem(name: "key", sfSymbol: Icons.Document.key, enumPath: "Icons.Document.key"),
                ]
            )
            
            // System & Debug Icons
            IconSection(
                title: "System & Debug",
                icons: [
                    IconItem(name: "bug", sfSymbol: Icons.System.bug, enumPath: "Icons.System.bug"),
                    IconItem(name: "database", sfSymbol: Icons.System.database, enumPath: "Icons.System.database"),
                    IconItem(name: "storage", sfSymbol: Icons.System.storage, enumPath: "Icons.System.storage"),
                    IconItem(name: "storageBadge", sfSymbol: Icons.System.storageBadge, enumPath: "Icons.System.storageBadge"),
                    IconItem(name: "chart", sfSymbol: Icons.System.chart, enumPath: "Icons.System.chart"),
                    IconItem(name: "chartDoc", sfSymbol: Icons.System.chartDoc, enumPath: "Icons.System.chartDoc"),
                    IconItem(name: "chartDocHorizontal", sfSymbol: Icons.System.chartDocHorizontal, enumPath: "Icons.System.chartDocHorizontal"),
                    IconItem(name: "chartBarXAxis", sfSymbol: Icons.System.chartBarXAxis, enumPath: "Icons.System.chartBarXAxis"),
                    IconItem(name: "person", sfSymbol: Icons.System.person, enumPath: "Icons.System.person"),
                    IconItem(name: "envelope", sfSymbol: Icons.System.envelope, enumPath: "Icons.System.envelope"),
                    IconItem(name: "map", sfSymbol: Icons.System.map, enumPath: "Icons.System.map"),
                    IconItem(name: "location", sfSymbol: Icons.System.location, enumPath: "Icons.System.location"),
                    IconItem(name: "clock", sfSymbol: Icons.System.clock, enumPath: "Icons.System.clock"),
                    IconItem(name: "star", sfSymbol: Icons.System.star, enumPath: "Icons.System.star"),
                    IconItem(name: "pencil", sfSymbol: Icons.System.pencil, enumPath: "Icons.System.pencil"),
                    IconItem(name: "plus", sfSymbol: Icons.System.plus, enumPath: "Icons.System.plus"),
                    IconItem(name: "minus", sfSymbol: Icons.System.minus, enumPath: "Icons.System.minus"),
                    IconItem(name: "chevronRight", sfSymbol: Icons.System.chevronRight, enumPath: "Icons.System.chevronRight"),
                    IconItem(name: "chevronDown", sfSymbol: Icons.System.chevronDown, enumPath: "Icons.System.chevronDown"),
                    IconItem(name: "chevronUp", sfSymbol: Icons.System.chevronUp, enumPath: "Icons.System.chevronUp"),
                    IconItem(name: "gauge", sfSymbol: Icons.System.gauge, enumPath: "Icons.System.gauge"),
                    IconItem(name: "gaugeBadge", sfSymbol: Icons.System.gaugeBadge, enumPath: "Icons.System.gaugeBadge"),
                    IconItem(name: "calendar", sfSymbol: Icons.System.calendar, enumPath: "Icons.System.calendar"),
                    IconItem(name: "brain", sfSymbol: Icons.System.brain, enumPath: "Icons.System.brain"),
                    IconItem(name: "sparkles", sfSymbol: Icons.System.sparkles, enumPath: "Icons.System.sparkles"),
                    IconItem(name: "waveform", sfSymbol: Icons.System.waveform, enumPath: "Icons.System.waveform"),
                    IconItem(name: "network", sfSymbol: Icons.System.network, enumPath: "Icons.System.network"),
                    IconItem(name: "shield", sfSymbol: Icons.System.shield, enumPath: "Icons.System.shield"),
                    IconItem(name: "hammer", sfSymbol: Icons.System.hammer, enumPath: "Icons.System.hammer"),
                    IconItem(name: "hammerFill", sfSymbol: Icons.System.hammerFill, enumPath: "Icons.System.hammerFill"),
                    IconItem(name: "magnifyingGlass", sfSymbol: Icons.System.magnifyingGlass, enumPath: "Icons.System.magnifyingGlass"),
                    IconItem(name: "keyHorizontal", sfSymbol: Icons.System.keyHorizontal, enumPath: "Icons.System.keyHorizontal"),
                    IconItem(name: "heartTextSquare", sfSymbol: Icons.System.heartTextSquare, enumPath: "Icons.System.heartTextSquare"),
                    IconItem(name: "heartTextSquareOutline", sfSymbol: Icons.System.heartTextSquareOutline, enumPath: "Icons.System.heartTextSquareOutline"),
                    IconItem(name: "grid2x2", sfSymbol: Icons.System.grid2x2, enumPath: "Icons.System.grid2x2"),
                    IconItem(name: "circleArrowPath", sfSymbol: Icons.System.circleArrowPath, enumPath: "Icons.System.circleArrowPath"),
                    IconItem(name: "counterclockwise", sfSymbol: Icons.System.counterclockwise, enumPath: "Icons.System.counterclockwise"),
                    IconItem(name: "arrowRightCircle", sfSymbol: Icons.System.arrowRightCircle, enumPath: "Icons.System.arrowRightCircle"),
                    IconItem(name: "target", sfSymbol: Icons.System.target, enumPath: "Icons.System.target"),
                    IconItem(name: "percent", sfSymbol: Icons.System.percent, enumPath: "Icons.System.percent"),
                    IconItem(name: "lightbulb", sfSymbol: Icons.System.lightbulb, enumPath: "Icons.System.lightbulb"),
                    IconItem(name: "bell", sfSymbol: Icons.System.bell, enumPath: "Icons.System.bell"),
                    IconItem(name: "camera", sfSymbol: Icons.System.camera, enumPath: "Icons.System.camera"),
                    IconItem(name: "docText", sfSymbol: Icons.System.docText, enumPath: "Icons.System.docText"),
                    IconItem(name: "eye", sfSymbol: Icons.System.eye, enumPath: "Icons.System.eye"),
                    IconItem(name: "circle", sfSymbol: Icons.System.circle, enumPath: "Icons.System.circle"),
                    IconItem(name: "lock", sfSymbol: Icons.System.lock, enumPath: "Icons.System.lock"),
                    IconItem(name: "lockShield", sfSymbol: Icons.System.lockShield, enumPath: "Icons.System.lockShield"),
                    IconItem(name: "link", sfSymbol: Icons.System.link, enumPath: "Icons.System.link"),
                    IconItem(name: "linkCircle", sfSymbol: Icons.System.linkCircle, enumPath: "Icons.System.linkCircle"),
                    IconItem(name: "linkCircleFill", sfSymbol: Icons.System.linkCircleFill, enumPath: "Icons.System.linkCircleFill"),
                    IconItem(name: "trophy", sfSymbol: Icons.System.trophy, enumPath: "Icons.System.trophy"),
                    IconItem(name: "icloud", sfSymbol: Icons.System.icloud, enumPath: "Icons.System.icloud"),
                    IconItem(name: "questionCircleFill", sfSymbol: Icons.System.questionCircleFill, enumPath: "Icons.System.questionCircleFill"),
                    IconItem(name: "menuDecrease", sfSymbol: Icons.System.menuDecrease, enumPath: "Icons.System.menuDecrease"),
                ]
            )
            
            // Arrows & Directions Icons
            IconSection(
                title: "Arrows & Directions",
                icons: [
                    IconItem(name: "up", sfSymbol: Icons.Arrow.up, enumPath: "Icons.Arrow.up"),
                    IconItem(name: "down", sfSymbol: Icons.Arrow.down, enumPath: "Icons.Arrow.down"),
                    IconItem(name: "upRight", sfSymbol: Icons.Arrow.upRight, enumPath: "Icons.Arrow.upRight"),
                    IconItem(name: "downRight", sfSymbol: Icons.Arrow.downRight, enumPath: "Icons.Arrow.downRight"),
                    IconItem(name: "clockwise", sfSymbol: Icons.Arrow.clockwise, enumPath: "Icons.Arrow.clockwise"),
                    IconItem(name: "counterclockwise", sfSymbol: Icons.Arrow.counterclockwise, enumPath: "Icons.Arrow.counterclockwise"),
                    IconItem(name: "rectanglePortrait", sfSymbol: Icons.Arrow.rectanglePortrait, enumPath: "Icons.Arrow.rectanglePortrait"),
                    IconItem(name: "rightCircleFill", sfSymbol: Icons.Arrow.rightCircleFill, enumPath: "Icons.Arrow.rightCircleFill"),
                    IconItem(name: "rightCircle", sfSymbol: Icons.Arrow.rightCircle, enumPath: "Icons.Arrow.rightCircle"),
                    IconItem(name: "triangleCirclePath", sfSymbol: Icons.Arrow.triangleCirclePath, enumPath: "Icons.Arrow.triangleCirclePath"),
                ]
            )
        }
        .navigationTitle("Icon Test Sheet")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Views

struct IconSection: View {
    let title: String
    let icons: [IconItem]
    
    var body: some View {
        Section(header: Text(title)) {
            ForEach(icons) { icon in
                IconRow(icon: icon)
            }
        }
    }
}

struct IconRow: View {
    let icon: IconItem
    
    var body: some View {
        HStack(spacing: 16) {
            // SF Symbol (left)
            Image(systemName: icon.sfSymbol)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            // Name and enum path (middle)
            VStack(alignment: .leading, spacing: 2) {
                Text(icon.name)
                    .font(.system(size: 14, weight: .medium))
                Text(icon.enumPath)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(icon.sfSymbol)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .opacity(0.7)
            }
            
            Spacer()
            
            // Custom icon placeholder (right)
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(width: 32, height: 32)
                
                // TODO: Replace with custom icon when available
                // Image("custom-\(icon.name)")
                //     .resizable()
                //     .frame(width: 24, height: 24)
                
                Text("?")
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
    }
}

struct IconItem: Identifiable {
    let id = UUID()
    let name: String
    let sfSymbol: String
    let enumPath: String
}

// MARK: - Preview

#Preview {
    NavigationView {
        IconTestView()
    }
}
